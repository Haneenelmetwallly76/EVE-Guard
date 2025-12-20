import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// API Service for The Guard backend
class ApiService {
  // Modal deployment endpoint - UPDATE THIS AFTER DEPLOYMENT
  static const String baseUrl = 'https://geminiai340--eveguard-backend-fastapi-app.modal.run';
  
  /// Transcribe audio and analyze for threats
  /// Returns full analysis including transcription, danger score, and detected words
  /// Automatically warms up the server before making the request
  static Future<TranscriptionResult> transcribeAndAnalyze(File audioFile) async {
    // First, warm up the server (wake up Modal if cold)
    bool serverReady = await warmupServer();
    if (!serverReady) {
      throw Exception(
        'Server is not responding. The Modal function may be starting up. '
        'Please try again in a few seconds. If the problem persists, check your internet connection.'
      );
    }
    
    try {
      // Ensure baseUrl doesn't have trailing slash
      String cleanBaseUrl = baseUrl.endsWith('/') 
          ? baseUrl.substring(0, baseUrl.length - 1) 
          : baseUrl;
      var uri = Uri.parse('$cleanBaseUrl/transcribe');
      var request = http.MultipartRequest('POST', uri);
      
      request.files.add(
        await http.MultipartFile.fromPath('file', audioFile.path),
      );
      
      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 180), // Increased timeout for cold starts + transcription
      );
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        return TranscriptionResult.fromJson(data);
      } else {
        throw Exception('Transcription failed (${response.statusCode}): ${response.body}');
      }
    } on http.ClientException catch (e) {
      throw Exception('Network error: ${e.message}. Please check your internet connection.');
    } on FormatException catch (e) {
      throw Exception('Invalid response from server: $e');
    } catch (e) {
      if (e.toString().contains('TimeoutException') || e.toString().contains('timeout')) {
        throw Exception(
          'Request timed out. The server may be starting up (cold start) or processing the audio. '
          'Please try again - subsequent requests should be faster.'
        );
      }
      throw Exception('Failed to transcribe audio: $e');
    }
  }
  
  /// Warm up the server (wake up Modal function if cold)
  /// Returns true if server is ready, false otherwise
  static Future<bool> warmupServer({int maxRetries = 3}) async {
    // Ensure baseUrl doesn't have trailing slash
    String cleanBaseUrl = baseUrl.endsWith('/') 
        ? baseUrl.substring(0, baseUrl.length - 1) 
        : baseUrl;
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        var response = await http.get(Uri.parse('$cleanBaseUrl/')).timeout(
          const Duration(seconds: 30), // Longer timeout for cold starts
        );
        if (response.statusCode == 200) {
          return true;
        }
      } catch (e) {
        if (attempt < maxRetries) {
          // Wait a bit before retrying
          await Future.delayed(Duration(seconds: attempt * 2));
          continue;
        }
        return false;
      }
    }
    return false;
  }
  
  /// Analyze text for threats (no audio)
  /// Automatically warms up the server before making the request
  static Future<TextAnalysisResult> analyzeText(String text) async {
    // First, warm up the server (wake up Modal if cold)
    bool serverReady = await warmupServer();
    if (!serverReady) {
      throw Exception(
        'Server is not responding. The Modal function may be starting up. '
        'Please try again in a few seconds. If the problem persists, check your internet connection.'
      );
    }
    
    try {
      // Ensure baseUrl doesn't have trailing slash
      String cleanBaseUrl = baseUrl.endsWith('/') 
          ? baseUrl.substring(0, baseUrl.length - 1) 
          : baseUrl;
      var uri = Uri.parse('$cleanBaseUrl/analyze-text');
      
      var response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'text': text}),
      ).timeout(const Duration(seconds: 60)); // Increased timeout for cold starts
      
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        return TextAnalysisResult.fromJson(data);
      } else if (response.statusCode == 405) {
        // Method Not Allowed - try to parse error message
        try {
          var errorData = json.decode(response.body);
          String errorMsg = errorData['error']?['message'] ?? errorData['message'] ?? response.body;
          throw Exception('Method Not Allowed: $errorMsg. Please check the API endpoint configuration.');
        } catch (_) {
          throw Exception('Method Not Allowed (405): The server rejected the request. Please check the API endpoint.');
        }
      } else {
        // Try to parse error response
        try {
          var errorData = json.decode(response.body);
          String errorMsg = errorData['error']?['message'] ?? errorData['message'] ?? response.body;
          throw Exception('Analysis failed (${response.statusCode}): $errorMsg');
        } catch (_) {
          throw Exception('Analysis failed (${response.statusCode}): ${response.body}');
        }
      }
    } on http.ClientException catch (e) {
      throw Exception('Network error: ${e.message}. Please check your internet connection.');
    } on FormatException catch (e) {
      throw Exception('Invalid response from server: $e');
    } catch (e) {
      if (e.toString().contains('TimeoutException') || e.toString().contains('timeout')) {
        throw Exception(
          'Request timed out. The server may be starting up (cold start). '
          'Please try again - subsequent requests should be faster.'
        );
      }
      // Re-throw if it's already our formatted exception
      if (e.toString().startsWith('Exception: ')) {
        rethrow;
      }
      throw Exception('Failed to analyze text: $e');
    }
  }
  
  /// Check if the API is available
  static Future<bool> checkHealth() async {
    try {
      // Ensure baseUrl doesn't have trailing slash
      String cleanBaseUrl = baseUrl.endsWith('/') 
          ? baseUrl.substring(0, baseUrl.length - 1) 
          : baseUrl;
      var response = await http.get(Uri.parse('$cleanBaseUrl/')).timeout(
        const Duration(seconds: 30), // Increased timeout for cold starts
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
