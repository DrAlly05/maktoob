import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../data/mock_translation_service.dart';

class BookReaderScreen extends StatefulWidget {
  const BookReaderScreen({super.key});

  @override
  State<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends State<BookReaderScreen> {
  final MockTranslationService _translationService = MockTranslationService();
  bool _isLoading = false;
  String? _translatedText;

  Future<void> _translateText() async {
    setState(() {
      _isLoading = true;
      _translatedText = null;
    });

    try {
      final translation = await _translationService
          .translateToSwahili("Welcome to a world without language barriers.");
      if (translation.trim().isEmpty) {
        throw Exception("Empty translation");
      }
      setState(() {
        _translatedText = translation;
      });
    } catch (e) {
      setState(() {
        _translatedText = "Translation failed. Please try again.";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maktoob Reader 📖'),
      ),
      body: Stack(
        children: [
          SfPdfViewer.asset('assets/sample.pdf'),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  ElevatedButton(
                    onPressed: _translateText,
                    child: const Text('Translate to Swahili'),
                  ),
                if (_translatedText != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.black54,
                    child: Text(
                      _translatedText!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
