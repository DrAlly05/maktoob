import 'package:epubx/epubx.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/audio_controller.dart';
import '../domain/chapter_text.dart';
import '../domain/translation_controller.dart';
import 'reader_widgets.dart';

/// Shows a book chapter by chapter. Each paragraph is translated into
/// Swahili and read aloud one at a time, with the original kept above it.
class ReaderScreen extends StatefulWidget {
  final EpubBook book;

  const ReaderScreen({super.key, required this.book});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _Chapter {
  final String title;
  final List<String> paragraphs;
  final BookLanguage language;

  const _Chapter(this.title, this.paragraphs, this.language);
}

class _ReaderScreenState extends State<ReaderScreen> {
  final AudioController _audio = AudioController();
  final TranslationController _translator = TranslationController();
  final PageController _pageController = PageController();

  late final List<_Chapter> _chapters;
  final Map<String, String> _translations = {};
  final Map<String, GlobalKey> _paragraphKeys = {};

  int _chapterIndex = 0;
  int? _activeParagraph;
  int _resumeParagraph = 0;
  bool _playing = false;
  String? _status;
  double _fontSize = 18.0;
  bool _showOriginal = true;
  int _speedIndex = 1;

  /// Voice pace and the label shown for it.
  static const List<(double, String)> _speeds = [
    (0.42, '0.8x'),
    (0.5, '1.0x'),
    (0.6, '1.2x'),
  ];

  /// Raised every time listening starts or stops, so an older run
  /// that is still waiting on the voice knows it has been replaced.
  int _runToken = 0;

  @override
  void initState() {
    super.initState();
    _chapters = _readChapters(widget.book);
  }

  @override
  void dispose() {
    _runToken++;
    _audio.stop();
    _translator.close();
    _pageController.dispose();
    super.dispose();
  }

  /// Turns the book into sections of readable paragraphs.
  ///
  /// The book's own text files are read in reading order. The table of
  /// contents is used only when that gives nothing, because many books
  /// carry a table of contents this reader cannot follow.
  static List<_Chapter> _readChapters(EpubBook book) {
    final fromFiles = _chaptersFromFiles(book);
    if (fromFiles.isNotEmpty) return fromFiles;
    return _chaptersFromContents(book);
  }

  static List<_Chapter> _chaptersFromFiles(EpubBook book) {
    final htmlFiles = book.Content?.Html ?? const {};
    if (htmlFiles.isEmpty) return const [];

    // Reading order: the spine lists item ids, the manifest maps ids to files.
    final fileNameById = <String, String>{};
    for (final item in book.Schema?.Package?.Manifest?.Items ?? const []) {
      final id = item.Id;
      final href = item.Href;
      if (id != null && href != null) fileNameById[id] = href;
    }

    final pages = <String>[];
    final seen = <String>{};
    for (final entry in book.Schema?.Package?.Spine?.Items ?? const []) {
      final fileName = fileNameById[entry.IdRef];
      if (fileName == null || !seen.add(fileName)) continue;
      final content = htmlFiles[fileName]?.Content;
      if (content != null) pages.add(content);
    }

    // A book with a broken reading order is still read, in file order.
    if (pages.isEmpty) {
      for (final file in htmlFiles.values) {
        final content = file.Content;
        if (content != null) pages.add(content);
      }
    }

    final chapters = <_Chapter>[];
    for (final html in pages) {
      final paragraphs = ChapterText.paragraphsFromHtml(html);
      if (paragraphs.isEmpty) continue;

      final title = ChapterText.headingFromHtml(html);
      if (title.isNotEmpty && paragraphs.first == title) {
        paragraphs.removeAt(0);
      }
      if (paragraphs.isEmpty) continue;

      chapters.add(
        _Chapter(
          title,
          paragraphs,
          ChapterText.detectLanguage(paragraphs.take(8).join(' ')),
        ),
      );
    }
    return chapters;
  }

  static List<_Chapter> _chaptersFromContents(EpubBook book) {
    final chapters = <_Chapter>[];

    void visit(List<EpubChapter>? nodes) {
      for (final node in nodes ?? const <EpubChapter>[]) {
        final paragraphs =
            ChapterText.paragraphsFromHtml(node.HtmlContent ?? '');
        if (paragraphs.isNotEmpty) {
          chapters.add(
            _Chapter(
              (node.Title ?? '').trim(),
              paragraphs,
              ChapterText.detectLanguage(paragraphs.take(8).join(' ')),
            ),
          );
        }
        visit(node.SubChapters);
      }
    }

    visit(book.Chapters);
    return chapters;
  }

  /// A short technical line shown when a book cannot be read, so the
  /// cause can be found from a screenshot.
  static String _describeBook(EpubBook book) {
    final files = book.Content?.Html?.length ?? 0;
    final order = book.Schema?.Package?.Spine?.Items?.length ?? 0;
    final contents = book.Chapters?.length ?? 0;
    return 'Text files: $files. Reading order: $order. Contents: $contents.';
  }

  String _key(int chapter, int paragraph) => '$chapter:$paragraph';

  GlobalKey _paragraphKey(int chapter, int paragraph) {
    return _paragraphKeys.putIfAbsent(_key(chapter, paragraph), () => GlobalKey());
  }

  void _scrollTo(int chapter, int paragraph) {
    final target = _paragraphKeys[_key(chapter, paragraph)]?.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      alignment: 0.15,
    );
  }

  Future<void> _stop() async {
    _runToken++;
    await _audio.stop();
    if (!mounted) return;
    setState(() {
      _playing = false;
      _activeParagraph = null;
      _status = null;
    });
  }

  /// Translates and reads the current chapter, starting at [fromParagraph].
  Future<void> _play(int fromParagraph) async {
    if (_chapters.isEmpty) return;

    final token = ++_runToken;
    final chapterIndex = _chapterIndex;
    final chapter = _chapters[chapterIndex];

    HapticFeedback.mediumImpact();
    setState(() {
      _playing = true;
      _activeParagraph = fromParagraph;
      _status = 'Inaandaa Kiswahili. Mara ya kwanza inahitaji intaneti '
          'ili kupakua kifurushi cha lugha.';
    });

    var reachedEnd = false;
    try {
      await _audio.stop();
      await _translator.prepare(chapter.language);
      final hasVoice = await _audio.prepare();
      if (!mounted || token != _runToken) return;
      setState(() {
        _status = hasVoice
            ? null
            : 'Simu hii bado haina sauti ya Kiswahili, kwa hiyo '
                'maandishi tu yanaonyeshwa. Ili kusikia, weka '
                '"Speech Recognition & Synthesis" ya Google kutoka '
                'Play Store, kisha pakua Kiswahili ndani yake.\n'
                '${_audio.engineNote}';
      });

      for (var i = fromParagraph; i < chapter.paragraphs.length; i++) {
        if (!mounted || token != _runToken) return;
        _resumeParagraph = i;
        if (hasVoice) {
          setState(() => _activeParagraph = i);
          _scrollTo(chapterIndex, i);
        }

        final key = _key(chapterIndex, i);
        var swahili = _translations[key];
        if (swahili == null) {
          final translated = await _translator.translateToSwahili(
            chapter.paragraphs[i],
            chapter.language,
          );
          if (!mounted || token != _runToken) return;
          setState(() => _translations[key] = translated);
          swahili = translated;
        }

        await _audio.speak(swahili);
      }
      reachedEnd = true;
    } catch (_) {
      if (mounted && token == _runToken) {
        setState(() {
          _status = 'Kiswahili hakikuweza kuanza. Kagua intaneti na nafasi '
              'ya simu, kisha jaribu tena.';
        });
      }
    } finally {
      if (mounted && token == _runToken) {
        setState(() {
          _playing = false;
          _activeParagraph = null;
          if (reachedEnd) _resumeParagraph = 0;
        });
      }
    }
  }

  void _onChapterChanged(int index) {
    _runToken++;
    _audio.stop();
    setState(() {
      _chapterIndex = index;
      _playing = false;
      _activeParagraph = null;
      _resumeParagraph = 0;
      _status = null;
    });
  }

  void _cycleSpeed() {
    setState(() => _speedIndex = (_speedIndex + 1) % _speeds.length);
    _audio.setRate(_speeds[_speedIndex].$1);
  }

  /// Moves one paragraph back or forward and reads from there.
  void _skip(int by) {
    final last = _chapters[_chapterIndex].paragraphs.length - 1;
    var target = (_activeParagraph ?? _resumeParagraph) + by;
    if (target < 0) target = 0;
    if (target > last) target = last;
    _play(target);
  }

  @override
  Widget build(BuildContext context) {
    if (_chapters.isEmpty) {
      return Scaffold(
        appBar: AppBar(backgroundColor: AppColors.night),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Hakuna maandishi yanayosomeka yaliyopatikana kwenye '
              'kitabu hiki.\n\n${_describeBook(widget.book)}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: AppColors.mist,
              ),
            ),
          ),
        ),
      );
    }

    final chapter = _chapters[_chapterIndex];
    final count = chapter.paragraphs.length;
    final shown = (_activeParagraph ?? _resumeParagraph) + 1;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(),
            if (_status != null) StatusBanner(text: _status!),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _chapters.length,
                onPageChanged: _onChapterChanged,
                itemBuilder: (context, index) => _buildChapter(index),
              ),
            ),
            PlayerBar(
              playing: _playing,
              section: _chapterIndex + 1,
              sectionCount: _chapters.length,
              paragraph: shown,
              paragraphCount: count,
              speedLabel: _speeds[_speedIndex].$2,
              onPlayPause: () {
                if (_playing) {
                  _stop();
                } else {
                  _play(_resumeParagraph);
                }
              },
              onPrevious: shown > 1 ? () => _skip(-1) : null,
              onNext: shown < count ? () => _skip(1) : null,
              onSpeed: _cycleSpeed,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    ButtonStyle pill({required bool filled}) {
      return OutlinedButton.styleFrom(
        foregroundColor: filled ? AppColors.night : AppColors.ivory,
        backgroundColor: filled ? AppColors.lamp : Colors.transparent,
        side: BorderSide(color: filled ? AppColors.lamp : AppColors.line),
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        textStyle: const TextStyle(
          fontFamily: AppTheme.body,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Rudi',
            color: AppColors.ivory,
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          ),
          const Spacer(),
          Tooltip(
            message: 'Onyesha au ficha maandishi ya asili',
            child: OutlinedButton(
              style: pill(filled: _showOriginal),
              onPressed: () => setState(() => _showOriginal = !_showOriginal),
              child: const Text('Asili'),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Ukubwa wa maandishi',
            child: OutlinedButton(
              style: pill(filled: false),
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _fontSize = _fontSize >= 26.0 ? 16.0 : _fontSize + 2.0;
                });
              },
              child: const Text('Aa'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChapter(int chapterIndex) {
    final chapter = _chapters[chapterIndex];
    final bookTitle = (widget.book.Title ?? '').trim();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (bookTitle.isNotEmpty)
                  Text(
                    bookTitle,
                    style: const TextStyle(
                      fontFamily: AppTheme.display,
                      fontStyle: FontStyle.italic,
                      fontSize: 15,
                      color: AppColors.mist,
                    ),
                  ),
                if (chapter.title.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    chapter.title,
                    style: const TextStyle(
                      fontFamily: AppTheme.display,
                      fontWeight: FontWeight.w600,
                      fontSize: 28,
                      height: 1.15,
                      color: AppColors.lamp,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 28),
          for (var i = 0; i < chapter.paragraphs.length; i++)
            PassageCard(
              key: _paragraphKey(chapterIndex, i),
              original: chapter.paragraphs[i],
              swahili: _translations[_key(chapterIndex, i)],
              active: _playing &&
                  chapterIndex == _chapterIndex &&
                  _activeParagraph == i,
              showOriginal: _showOriginal,
              originalRightToLeft: chapter.language == BookLanguage.arabic,
              fontSize: _fontSize,
              onTap: () => _play(i),
            ),
        ],
      ),
    );
  }
}
