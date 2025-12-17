import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TranscriptionService {
  // Your Modal deployment endpoint
  static const String _baseUrl = 'https://geminiai340--whisper-medium-backend-fastapi-app.modal.run';
  
  /// Transcribe an audio file to text
  /// 
  /// [audioFile] - The audio file to transcribe (supports .ogg, .mp3, .wav, .m4a, .flac)
  /// [token] - Optional authentication token
  /// 
  /// Returns the transcribed text or throws an exception on error
  static Future<String> transcribeAudio(File audioFile, {String? token}) async {
    try {
      var uri = Uri.parse('$_baseUrl/transcribe');
      var request = http.MultipartRequest('POST', uri);
      
      // Add the audio file
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          audioFile.path,
        ),
      );
      
      // Add authorization header if token is provided
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      
      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        return data['text'] as String;
      } else {
        var errorData = json.decode(response.body);
        throw Exception('Transcription failed: ${errorData['detail'] ?? response.body}');
      }
    } catch (e) {
      throw Exception('Failed to transcribe audio: $e');
    }
  }
  
  /// Check if the service is available
  static Future<bool> checkHealth() async {
    try {
      var response = await http.get(Uri.parse('$_baseUrl/'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
