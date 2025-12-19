import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// API Service for The Guard backend
class ApiService {
  // Modal deployment endpoint - UPDATE THIS AFTER DEPLOYMENT
  static const String baseUrl = 'https://modal.com/apps/yousef-ahmed9904/main/deployed/eveguard-backend';
  
  /// Transcribe audio and analyze for threats
  /// Returns full analysis including transcription, danger score, and detected words
  static Future<TranscriptionResult> transcribeAndAnalyze(File audioFile) async {
    try {
      var uri = Uri.parse('$baseUrl/transcribe');
      var request = http.MultipartRequest('POST', uri);
      
      request.files.add(
        await http.MultipartFile.fromPath('file', audioFile.path),
      );
      
      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 120),
      );
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        return TranscriptionResult.fromJson(data);
      } else {
        throw Exception('Transcription failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to transcribe audio: $e');
    }
  }
  
  /// Analyze text for threats (no audio)
  static Future<TextAnalysisResult> analyzeText(String text) async {
    try {
      var uri = Uri.parse('$baseUrl/analyze-text');
      var response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'text': text}),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        return TextAnalysisResult.fromJson(data);
      } else {
        throw Exception('Analysis failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to analyze text: $e');
    }
  }
  
  /// Check if the API is available
  static Future<bool> checkHealth() async {
    try {
      var response = await http.get(Uri.parse('$baseUrl/')).timeout(
        const Duration(seconds: 10),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

/// Result from transcription + analysis endpoint
class TranscriptionResult {
  final String transcription;
  final String audioBase64;
  final String audioFormat;
  final AnalysisResult analysis;
  
  TranscriptionResult({
    required this.transcription,
    required this.audioBase64,
    required this.audioFormat,
    required this.analysis,
  });
  
  factory TranscriptionResult.fromJson(Map<String, dynamic> json) {
    return TranscriptionResult(
      transcription: json['transcription'] ?? '',
      audioBase64: json['audio_base64'] ?? '',
      audioFormat: json['audio_format'] ?? '',
      analysis: AnalysisResult.fromJson(json['analysis'] ?? {}),
    );
  }
}

/// Analysis result structure
class AnalysisResult {
  final List<DetectedWord> detectedWords;
  final double dangerScore;
  final String risk;
  final String message;
  final int wordCount;
  final int criticalCount;
  final int warningCount;
  final int suspiciousCount;
  
  AnalysisResult({
    required this.detectedWords,
    required this.dangerScore,
    required this.risk,
    required this.message,
    required this.wordCount,
    required this.criticalCount,
    required this.warningCount,
    required this.suspiciousCount,
  });
  
  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    var wordsList = (json['detected_words'] as List<dynamic>?)
        ?.map((w) => DetectedWord.fromJson(w))
        .toList() ?? [];
    
    return AnalysisResult(
      detectedWords: wordsList,
      dangerScore: (json['danger_score'] ?? 0.0).toDouble(),
      risk: json['risk'] ?? 'safe',
      message: json['message'] ?? '',
      wordCount: json['word_count'] ?? 0,
      criticalCount: json['critical_count'] ?? 0,
      warningCount: json['warning_count'] ?? 0,
      suspiciousCount: json['suspicious_count'] ?? 0,
    );
  }
}

/// Text analysis result (from /analyze-text endpoint)
class TextAnalysisResult {
  final String text;
  final double dangerScore;
  final String risk;
  final String message;
  final List<DetectedWord> detectedWords;
  final int wordCount;
  final int criticalCount;
  final int warningCount;
  final int suspiciousCount;
  
  TextAnalysisResult({
    required this.text,
    required this.dangerScore,
    required this.risk,
    required this.message,
    required this.detectedWords,
    required this.wordCount,
    required this.criticalCount,
    required this.warningCount,
    required this.suspiciousCount,
  });
  
  factory TextAnalysisResult.fromJson(Map<String, dynamic> json) {
    var wordsList = (json['detected_words'] as List<dynamic>?)
        ?.map((w) => DetectedWord.fromJson(w))
        .toList() ?? [];
    
    return TextAnalysisResult(
      text: json['text'] ?? '',
      dangerScore: (json['danger_score'] ?? 0.0).toDouble(),
      risk: json['risk'] ?? 'safe',
      message: json['message'] ?? '',
      detectedWords: wordsList,
      wordCount: json['word_count'] ?? 0,
      criticalCount: json['critical_count'] ?? 0,
      warningCount: json['warning_count'] ?? 0,
      suspiciousCount: json['suspicious_count'] ?? 0,
    );
  }
}

/// Detected bad word with its severity level
class DetectedWord {
  final String word;
  final String level;
  final double weight;
  
  DetectedWord({
    required this.word,
    required this.level,
    required this.weight,
  });
  
  factory DetectedWord.fromJson(Map<String, dynamic> json) {
    return DetectedWord(
      word: json['word'] ?? '',
      level: json['level'] ?? 'suspicious',
      weight: (json['weight'] ?? 0.0).toDouble(),
    );
  }
}
