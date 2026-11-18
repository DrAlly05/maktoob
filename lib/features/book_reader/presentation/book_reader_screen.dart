import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:maktoob/features/book_reader/data/mock_translation_service.dart';

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
      final translation = await _translationService.translateToSwahili(
        "Welcome to a world without language barriers.",
      );

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
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Stack(
        children: [
          // Underlay PDF Reader layer
          SfPdfViewer.asset('assets/sample.pdf'),

          // Overlay Control and Translation Panel positioned at the bottom
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Card(
              color: Colors.black87,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: CircularProgressIndicator(color: Colors.tealAccent),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: _translateText,
                        icon: const Icon(Icons.g_translate),
                        label: const Text('Translate to Swahili'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                    if (_translatedText != null) ...[
                      const Divider(color: Colors.white24, height: 24),
                      Text(
                        _translatedText!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}