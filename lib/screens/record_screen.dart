import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../services/api_service.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> with SingleTickerProviderStateMixin {
  bool _isRecording = false;
  bool _isAnalyzing = false;
  bool _hasRecording = false;
  String? _recordingPath;
  TranscriptionResult? _analysisResult;
  String? _errorMessage;
  
  late AnimationController _pulseController;
  Timer? _recordingTimer;
  int _recordingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  void _startRecording() async {
    // TODO: Implement actual audio recording using record package
    // For now, this is a placeholder that simulates recording
    setState(() {
      _isRecording = true;
      _recordingSeconds = 0;
      _analysisResult = null;
      _errorMessage = null;
    });
    
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordingSeconds++;
      });
    });
    
    // Show instructions for actual implementation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recording started... (Add record package for actual recording)'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _stopRecording() async {
    _recordingTimer?.cancel();
    
    setState(() {
      _isRecording = false;
      _hasRecording = true;
    });
    
    // TODO: Get actual recording file path from recorder
    // For demonstration, we'll use a placeholder
    final directory = await getTemporaryDirectory();
    _recordingPath = '${directory.path}/recording.wav';
  }

  Future<void> _analyzeRecording() async {
    if (_recordingPath == null) {
      setState(() {
        _errorMessage = 'No recording available';
      });
      return;
    }
    
    final file = File(_recordingPath!);
    if (!await file.exists()) {
      setState(() {
        _errorMessage = 'Recording file not found. Please use file picker to select an audio file.';
      });
      // For testing, show file picker option
      _showFilePickerDialog();
      return;
    }
    
    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
    });
    
    try {
      final result = await ApiService.transcribeAndAnalyze(file);
      setState(() {
        _analysisResult = result;
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isAnalyzing = false;
      });
    }
  }

  void _showFilePickerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Audio File'),
        content: const Text(
          'To test the API, please add the file_picker package and select an audio file, '
          'or implement actual recording with the record package.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Color _getRiskColor(String risk) {
    switch (risk) {
      case 'safe':
        return AppTheme.emerald500;
      case 'suspicious':
        return AppTheme.yellow600;
      case 'warning':
        return Colors.orange;
      case 'danger':
        return AppTheme.red600;
      default:
        return AppTheme.slate500;
    }
  }

  IconData _getRiskIcon(String risk) {
    switch (risk) {
      case 'safe':
        return Icons.check_circle;
      case 'suspicious':
        return Icons.info;
      case 'warning':
        return Icons.warning;
      case 'danger':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.indigo100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.mic,
                        color: AppTheme.indigo600,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Voice Analysis',
                            style: AppTheme.headingMedium,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Record audio for AI threat detection',
                            style: AppTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Recording Section
          GlassCard(
            child: Column(
              children: [
                // Recording indicator
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isRecording
                            ? AppTheme.red600.withOpacity(0.1 + _pulseController.value * 0.2)
                            : AppTheme.slate100,
                        border: Border.all(
                          color: _isRecording ? AppTheme.red600 : AppTheme.slate300,
                          width: 3,
                        ),
                      ),
                      child: Icon(
                        _isRecording ? Icons.stop : Icons.mic,
                        size: 48,
                        color: _isRecording ? AppTheme.red600 : AppTheme.slate600,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                
                // Recording time
                if (_isRecording)
                  Text(
                    _formatDuration(_recordingSeconds),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.red600,
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                // Recording buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isAnalyzing
                          ? null
                          : (_isRecording ? _stopRecording : _startRecording),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isRecording ? AppTheme.red600 : AppTheme.indigo600,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: Icon(_isRecording ? Icons.stop : Icons.mic, color: Colors.white),
                      label: Text(
                        _isRecording ? 'Stop Recording' : 'Start Recording',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    if (_hasRecording && !_isRecording) ...[
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _isAnalyzing ? null : _analyzeRecording,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.emerald500,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: _isAnalyzing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.analytics, color: Colors.white),
                        label: Text(
                          _isAnalyzing ? 'Analyzing...' : 'Analyze Record',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Error Message
          if (_errorMessage != null)
            GlassCard(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.red600.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.red600.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppTheme.red600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppTheme.red600),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Analysis Results
          if (_analysisResult != null) ...[
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Risk Level Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getRiskColor(_analysisResult!.analysis.risk).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getRiskIcon(_analysisResult!.analysis.risk),
                          color: _getRiskColor(_analysisResult!.analysis.risk),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Threat Level', style: AppTheme.headingSmall),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getRiskColor(_analysisResult!.analysis.risk).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _analysisResult!.analysis.risk.toUpperCase(),
                                style: TextStyle(
                                  color: _getRiskColor(_analysisResult!.analysis.risk),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Danger Score
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Danger Score', style: AppTheme.labelMedium),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _analysisResult!.analysis.dangerScore,
                          minHeight: 12,
                          backgroundColor: AppTheme.slate200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getRiskColor(_analysisResult!.analysis.risk),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(_analysisResult!.analysis.dangerScore * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _getRiskColor(_analysisResult!.analysis.risk),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Transcription
                  const Text('Transcription', style: AppTheme.labelMedium),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.slate100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _analysisResult!.transcription.isEmpty
                          ? 'No speech detected'
                          : _analysisResult!.transcription,
                      style: AppTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Detected Words
                  if (_analysisResult!.analysis.detectedWords.isNotEmpty) ...[
                    const Text('Detected Threat Words', style: AppTheme.labelMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _analysisResult!.analysis.detectedWords.map((word) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getRiskColor(
                              word.level == 'critical' ? 'danger' :
                              word.level == 'warning' ? 'warning' : 'suspicious'
                            ).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _getRiskColor(
                                word.level == 'critical' ? 'danger' :
                                word.level == 'warning' ? 'warning' : 'suspicious'
                              ),
                            ),
                          ),
                          child: Text(
                            '${word.word} (${word.level})',
                            style: TextStyle(
                              color: _getRiskColor(
                                word.level == 'critical' ? 'danger' :
                                word.level == 'warning' ? 'warning' : 'suspicious'
                              ),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 16),
                  
                  // Word Counts
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildCountBadge('Critical', _analysisResult!.analysis.criticalCount, AppTheme.red600),
                      _buildCountBadge('Warning', _analysisResult!.analysis.warningCount, Colors.orange),
                      _buildCountBadge('Suspicious', _analysisResult!.analysis.suspiciousCount, AppTheme.yellow600),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCountBadge(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
