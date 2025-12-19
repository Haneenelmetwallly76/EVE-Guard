import 'dart:io';
import 'package:flutter/material.dart';
// Note: `file_picker` removed to avoid platform plugin build issues.
// This screen provides a simple path-input fallback for selecting a file.
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
      // Simple fallback: ask user to enter a local file path to an audio file.
      String? path = await showDialog<String>(
        context: context,
        builder: (context) {
          final controller = TextEditingController();
          return AlertDialog(
            title: const Text('Enter audio file path'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: '/path/to/file.wav'),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('OK')),
            ],
          );
        },
      );

      if (path != null && path.isNotEmpty) {
        File audioFile = File(path);
        if (!await audioFile.exists()) {
          setState(() {
            _errorMessage = 'File not found: $path';
            _isLoading = false;
          });
          return;
        }

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
