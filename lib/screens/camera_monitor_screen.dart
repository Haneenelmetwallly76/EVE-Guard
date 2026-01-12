import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';
import '../theme/app_theme.dart';

class CameraMonitorScreen extends StatefulWidget {
  const CameraMonitorScreen({super.key});

  @override
  State<CameraMonitorScreen> createState() => _CameraMonitorScreenState();
}

class _CameraMonitorScreenState extends State<CameraMonitorScreen> {
  late TextEditingController _cameraUrlController;
  VideoPlayerController? _videoController;
  bool _isConnected = false;
  bool _isLoading = false;
  String _status = 'Disconnected';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _cameraUrlController = TextEditingController(
      text: 'rtsp://192.168.1.100:554/stream', // Default ESP32 cam RTSP address
    );
  }

  @override
  void dispose() {
    _cameraUrlController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _connectToCamera() async {
    final url = _cameraUrlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter camera URL')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Connecting...';
      _errorMessage = null;
    });

    try {
      // Dispose old controller if exists
      _videoController?.dispose();

      // Create new video player controller
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(url),
      );

      // Initialize and play
      await _videoController!.initialize();
      await _videoController!.play();

      if (mounted) {
        setState(() {
          _isConnected = true;
          _isLoading = false;
          _status = 'Connected';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera connected successfully'),
            backgroundColor: AppTheme.emerald500,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _status = 'Connection Failed';
          _errorMessage = 'Error: ${e.toString()}';
          _isConnected = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _disconnect() async {
    await _videoController?.dispose();
    setState(() {
      _videoController = null;
      _isConnected = false;
      _status = 'Disconnected';
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFf8fafc),
              Color(0x4deff6ff),
              Color(0x33eef2ff),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.blue100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.videocam,
                        color: AppTheme.blue600,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Camera Monitor',
                          style: AppTheme.headingMedium,
                        ),
                        Text(
                          _status,
                          style: TextStyle(
                            color: _isConnected
                                ? AppTheme.emerald500
                                : AppTheme.slate500,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _isConnected
                            ? AppTheme.emerald500
                            : AppTheme.slate300,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Camera Stream Display
                Container(
                  height: 300,
                  decoration: AppTheme.glassMorphismDecoration(),
                  child: _isConnected && _videoController != null
                      ? Stack(
                          children: [
                            // Video player
                            VideoPlayer(_videoController!),
                            // Play/Pause overlay
                            Center(
                              child: FloatingActionButton(
                                mini: true,
                                onPressed: () {
                                  setState(() {
                                    _videoController!.value.isPlaying
                                        ? _videoController!.pause()
                                        : _videoController!.play();
                                  });
                                },
                                child: Icon(
                                  _videoController!.value.isPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _errorMessage != null
                                  ? Icons.error_outline
                                  : Icons.videocam_off_outlined,
                              size: 80,
                              color: _errorMessage != null
                                  ? Colors.red
                                  : AppTheme.slate300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _isLoading
                                  ? 'Connecting...'
                                  : _errorMessage != null
                                      ? 'Connection Error'
                                      : 'No camera connected',
                              style: AppTheme.bodyMedium,
                            ),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ],
                        ),
                ),
                const SizedBox(height: 24),

                // Camera URL Input
                TextField(
                  controller: _cameraUrlController,
                  decoration: AppTheme.inputDecoration(
                    hintText: 'Camera URL (e.g., http://192.168.1.100:81)',
                    prefixIcon: const Icon(
                      Icons.link_outlined,
                      color: AppTheme.slate500,
                    ),
                  ),
                  enabled: !_isConnected,
                ),
                const SizedBox(height: 16),

                // Connect/Disconnect Button
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : (_isConnected ? _disconnect : _connectToCamera),
                  style: AppTheme.primaryButtonStyle.copyWith(
                    minimumSize: WidgetStateProperty.all(
                      const Size(double.infinity, 48),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          _isConnected ? 'Disconnect' : 'Connect to Camera',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
                const SizedBox(height: 24),

                // Camera Info Panel
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.glassMorphismDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Camera Settings',
                        style: AppTheme.headingSmall,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Resolution:',
                            style: AppTheme.bodyMedium,
                          ),
                          Text(
                            '1280x720',
                            style: AppTheme.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Frame Rate:',
                            style: AppTheme.bodyMedium,
                          ),
                          Text(
                            '30 FPS',
                            style: AppTheme.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Protocol:',
                            style: AppTheme.bodyMedium,
                          ),
                          Text(
                            'RTSP/HTTP',
                            style: AppTheme.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Quick Setup Guide
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.indigo50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.indigo100,
                      width: 1,
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ESP32 Setup Guide',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.indigo600,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '1. Connect ESP32 to WiFi\n'
                        '2. Note the IP address (e.g., 192.168.1.100)\n'
                        '3. Use port 81 for RTSP stream\n'
                        '4. Enter URL above and tap Connect\n'
                        '5. Stream will appear in camera view',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.slate600,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
