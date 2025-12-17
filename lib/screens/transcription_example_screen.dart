import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/transcription_service.dart';

/// Example screen showing how to use the transcription service
class TranscriptionExampleScreen extends StatefulWidget {
  const TranscriptionExampleScreen({super.key});

  @override
  State<TranscriptionExampleScreen> createState() => _TranscriptionExampleScreenState();
}

class _TranscriptionExampleScreenState extends State<TranscriptionExampleScreen> {
  String _transcriptionResult = '';
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _pickAndTranscribeAudio() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _transcriptionResult = '';
    });

    try {
      // Pick audio file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowedExtensions: ['ogg', 'mp3', 'wav', 'm4a', 'flac'],
      );

      if (result != null && result.files.single.path != null) {
        File audioFile = File(result.files.single.path!);
        
        // Call transcription service
        String transcription = await TranscriptionService.transcribeAudio(
          audioFile,
          // token: 'your-optional-token', // Add if authentication is needed
        );

        setState(() {
          _transcriptionResult = transcription;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Transcription'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _pickAndTranscribeAudio,
              icon: const Icon(Icons.mic),
              label: const Text('Pick Audio File & Transcribe'),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 10),
                    Text('Transcribing audio...'),
                  ],
                ),
              ),
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Text(
                  'Error: $_errorMessage',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            if (_transcriptionResult.isNotEmpty)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Transcription Result:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(_transcriptionResult),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
