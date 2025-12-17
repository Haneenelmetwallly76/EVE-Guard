import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class AIAnalysisScreen extends StatefulWidget {
  const AIAnalysisScreen({super.key});

  @override
  State<AIAnalysisScreen> createState() => _AIAnalysisScreenState();
}

class _AIAnalysisScreenState extends State<AIAnalysisScreen> {
  final TextEditingController _textController = TextEditingController();
  String? _analysisResult;
  bool _isLoading = false;
  String? _riskLevel; // 'safe', 'warning', 'danger'

  @override
  void dispose() {
    _textController.dispose();
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
      _riskLevel = null;
    });

    try {
      final uri = Uri.parse('http://10.20.0.97:8000/analyze-text');
      final body = json.encode({'text': textValue});

      final response = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final String risk = (data['risk'] ?? 'safe').toString();
        final String message = (data['message'] ?? 'No message').toString();

        setState(() {
          _riskLevel = risk;
          _analysisResult = message;
        });
      } else {
        setState(() {
          _analysisResult = 'Server error: ${response.statusCode}';
          _riskLevel = 'error';
        });
      }
    } on http.ClientException catch (e) {
      setState(() {
        _analysisResult = 'Network error: ${e.message}';
        _riskLevel = 'error';
      });
    } on Exception catch (e) {
      setState(() {
        _analysisResult = 'Error: $e';
        _riskLevel = 'error';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color _getRiskColor() {
    switch (_riskLevel) {
      case 'safe':
        return AppTheme.emerald500;
      case 'warning':
        return AppTheme.yellow600;
      case 'danger':
        return AppTheme.red600;
      default:
        return AppTheme.slate500;
    }
  }

  String _getRiskLabel() {
    switch (_riskLevel) {
      case 'safe':
        return 'Safe';
      case 'warning':
        return 'Warning';
      case 'danger':
        return 'Danger';
      default:
        return 'Pending';
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

          // Result Section
          if (_analysisResult != null)
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getRiskColor().withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _riskLevel == 'safe'
                              ? Icons.check_circle
                              : _riskLevel == 'warning'
                                  ? Icons.warning
                                  : _riskLevel == 'danger'
                                      ? Icons.error
                                      : Icons.info,
                          color: _getRiskColor(),
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
                                color: _getRiskColor().withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _getRiskLabel(),
                                style: TextStyle(
                                  color: _getRiskColor(),
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
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getRiskColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getRiskColor().withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _analysisResult!,
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.slate900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}