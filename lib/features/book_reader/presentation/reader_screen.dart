import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:epubx/epubx.dart';
import '../domain/audio_controller.dart';
import '../domain/translation_controller.dart';

class ReaderScreen extends StatefulWidget {
  final EpubBook book;

  const ReaderScreen({super.key, required this.book});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final AudioController _audioController = AudioController();
  final TranslationController _translationController = TranslationController();
  final PageController _pageController = PageController();

  int _activeChapterPointer = 0;
  String _swahiliTranslationBlock = "";
  bool _translationEngineBusy = false;
  double _customReaderFontSize = 18.0; // Interactive font adjustment mechanics

  @override
  void dispose() {
    _audioController.stop();
    _translationController.close();
    _pageController.dispose();
    super.dispose();
  }

  String _cleanHTMLMetadataContents(String rawHtml) {
    return rawHtml
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .trim();
  }

  void _runAITranslationPipeline() async {
    final chapters = widget.book.Chapters ?? [];
    if (chapters.isEmpty) return;

    if (_audioController.isSpeaking) {
      HapticFeedback.lightImpact();
      setState(() => _audioController.stop());
      return;
    }

    final cleanedArabicText = _cleanHTMLMetadataContents(
        chapters[_activeChapterPointer].HtmlContent ?? '');
    if (cleanedArabicText.isEmpty) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _translationEngineBusy = true;
      _swahiliTranslationBlock =
          "TRANSLATING VIA SECURE ON-DEVICE NEURAL MODELS...";
    });

    final outputSwahiliText = await _translationController
        .translateArabicToSwahili(cleanedArabicText);

    setState(() {
      _translationEngineBusy = false;
      _swahiliTranslationBlock = outputSwahiliText;
    });

    _audioController.speak(outputSwahiliText, "sw-TZ");
  }

  @override
  Widget build(BuildContext context) {
    final chapters = widget.book.Chapters ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: Text(widget.book.Title?.toUpperCase() ?? 'CANVAS LAYER',
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2)),
        backgroundColor: const Color(0xFF0F0F0F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Dynamic Typography Controller
          IconButton(
            icon: const Icon(Icons.text_fields_rounded, size: 20),
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() {
                _customReaderFontSize = _customReaderFontSize >= 26.0
                    ? 16.0
                    : _customReaderFontSize + 2.0;
              });
            },
          ),
          IconButton(
            icon: Icon(_translationEngineBusy
                ? Icons.hourglass_empty_rounded
                : (_audioController.isSpeaking
                    ? Icons.stop_circle_outlined
                    : Icons.translate_rounded)),
            color: Colors.tealAccent,
            onPressed: _runAITranslationPipeline,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: chapters.isEmpty
          ? const Center(child: Text('Empty book node configuration detected.'))
          : PageView.builder(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              itemCount: chapters.length,
              onPageChanged: (index) {
                _audioController.stop();
                setState(() {
                  _activeChapterPointer = index;
                  _swahiliTranslationBlock = "";
                });
              },
              itemBuilder: (context, index) {
                final textString = _cleanHTMLMetadataContents(
                    chapters[index].HtmlContent ?? '');

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28.0, vertical: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                                color: const Color(0xFF1C1C1E),
                                borderRadius: BorderRadius.circular(6)),
                            child: Text("CHAPTER ${index + 1}",
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        textString,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontSize: _customReaderFontSize,
                          height: 1.8,
                          color: const Color(0xFFE5E5E7),
                          letterSpacing: 0.2,
                        ),
                      ),
                      if (_swahiliTranslationBlock.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32.0),
                          child:
                              Divider(color: Color(0xFF222222), thickness: 1),
                        ),
                        const Text(
                          "SWAHILI NEURAL DICTATION STREAM",
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.tealAccent,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _swahiliTranslationBlock,
                          style: TextStyle(
                            fontSize: _customReaderFontSize - 1.0,
                            height: 1.6,
                            color: Colors.white70,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }
}
