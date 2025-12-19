import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../services/api_service.dart';
import 'package:path_provider/path_provider.dart';

class AIAnalysisScreen extends StatefulWidget {
  const AIAnalysisScreen({super.key});

  @override
  State<AIAnalysisScreen> createState() => _AIAnalysisScreenState();
}

class _AIAnalysisScreenState extends State<AIAnalysisScreen> {
  final TextEditingController _textController = TextEditingController();
  TextAnalysisResult? _analysisResult;
  bool _isLoading = false;
  String? _errorMessage;

  // Recording (simulated) state
  bool _isRecording = false;
  bool _isAnalyzingAudio = false;
  TranscriptionResult? _audioAnalysisResult;
  Timer? _recordingTimer;
  int _recordingSeconds = 0;

  @override
  void dispose() {
    _textController.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  Future<void> _analyzeText() async {
    final textValue = _textController.text.trim();
    if (textValue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter text to analyze')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _analysisResult = null;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.analyzeText(textValue);
      setState(() {
        _analysisResult = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _recordingSeconds = 0;
      _audioAnalysisResult = null;
      _errorMessage = null;
    });

    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordingSeconds++;
      });
    });
  }

  void _stopRecording() {
    _recordingTimer?.cancel();
    setState(() {
      _isRecording = false;
    });
  }

  Future<void> _analyzeRecording() async {
    setState(() {
      _isAnalyzingAudio = true;
      _audioAnalysisResult = null;
      _errorMessage = null;
    });

    // Simulate saving to a temp path and performing analysis
    await getTemporaryDirectory();

    try {
      await Future.delayed(const Duration(seconds: 1));
      _audioAnalysisResult = TranscriptionResult(
        transcription: 'Simulated transcription of recorded audio.',
        audioBase64: '',
        audioFormat: 'wav',
        analysis: AnalysisResult(
          detectedWords: [],
          dangerScore: 0.0,
          risk: 'safe',
          message: '',
          wordCount: 0,
          criticalCount: 0,
          warningCount: 0,
          suspiciousCount: 0,
        ),
      );
    } catch (e) {
      _errorMessage = 'Audio analysis failed: $e';
    } finally {
      setState(() {
        _isAnalyzingAudio = false;
      });
    }
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Color _getRiskColor(String? risk) {
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

  String _getRiskLabel(String? risk) {
    switch (risk) {
      case 'safe':
        return 'Safe';
      case 'suspicious':
        return 'Suspicious';
      case 'warning':
        return 'Warning';
      case 'danger':
        return 'Danger';
      default:
        return 'Pending';
    }
  }

  IconData _getRiskIcon(String? risk) {
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
                        Icons.psychology,
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
                            'Threat Analysis Tester',
                            style: AppTheme.headingMedium,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Test text for potential threats and dangers',
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

          // Voice Analysis (merged record UI)
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text('Voice Analysis', style: AppTheme.headingSmall),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _isAnalyzingAudio
                      ? null
                      : () {
                          if (_isRecording) {
                            _stopRecording();
                          } else {
                            _startRecording();
                          }
                        },
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isRecording ? AppTheme.red600.withOpacity(0.15) : AppTheme.slate100,
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
                  ),
                ),
                const SizedBox(height: 12),
                if (_isRecording)
                  Text(
                    _formatDuration(_recordingSeconds),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                if (!_isRecording && _recordingSeconds > 0)
                  Text(
                    'Recording: ${_formatDuration(_recordingSeconds)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.slate600,
                    ),
                  ),
                const SizedBox(height: 16),
                if (!_isRecording && _recordingSeconds > 0)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isAnalyzingAudio ? null : _analyzeRecording,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.emerald500,
                        disabledBackgroundColor: AppTheme.slate500,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isAnalyzingAudio
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Analyze Record',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                if (_recordingSeconds > 0)
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _recordingSeconds = 0;
                          _audioAnalysisResult = null;
                        });
                      },
                      child: const Text('Clear'),
                    ),
                  ),
                const SizedBox(height: 12),
                if (_audioAnalysisResult != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Transcription', style: AppTheme.labelMedium),
                      const SizedBox(height: 8),
                      Text(_audioAnalysisResult!.transcription),
                    ],
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Input Section
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter Text to Analyze',
                  style: AppTheme.headingSmall,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _textController,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText: 'Enter the text you want to analyze...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppTheme.slate200.withOpacity(0.5),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppTheme.slate200.withOpacity(0.5),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppTheme.indigo600,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.5),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  style: AppTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _analyzeText,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.indigo600,
                      disabledBackgroundColor: AppTheme.slate500,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Analyze Text',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
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

          // Result Section
          if (_analysisResult != null)
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
                          color: _getRiskColor(_analysisResult!.risk).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getRiskIcon(_analysisResult!.risk),
                          color: _getRiskColor(_analysisResult!.risk),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Analysis Result',
                              style: AppTheme.headingSmall,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getRiskColor(_analysisResult!.risk).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _getRiskLabel(_analysisResult!.risk),
                                style: TextStyle(
                                  color: _getRiskColor(_analysisResult!.risk),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
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
                          value: _analysisResult!.dangerScore,
                          minHeight: 12,
                          backgroundColor: AppTheme.slate200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getRiskColor(_analysisResult!.risk),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(_analysisResult!.dangerScore * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _getRiskColor(_analysisResult!.risk),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Message
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getRiskColor(_analysisResult!.risk).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getRiskColor(_analysisResult!.risk).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _analysisResult!.message,
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.slate900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Detected Words
                  if (_analysisResult!.detectedWords.isNotEmpty) ...[
                    const Text('Detected Threat Words', style: AppTheme.labelMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _analysisResult!.detectedWords.map((word) {
                        final wordRisk = word.level == 'critical' ? 'danger' :
                                         word.level == 'warning' ? 'warning' : 'suspicious';
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getRiskColor(wordRisk).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _getRiskColor(wordRisk)),
                          ),
                          child: Text(
                            '${word.word} (${word.level})',
                            style: TextStyle(
                              color: _getRiskColor(wordRisk),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Word Counts
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildCountBadge('Critical', _analysisResult!.criticalCount, AppTheme.red600),
                      _buildCountBadge('Warning', _analysisResult!.warningCount, Colors.orange),
                      _buildCountBadge('Suspicious', _analysisResult!.suspiciousCount, AppTheme.yellow600),
                    ],
                  ),
                ],
              ),
            ),
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

