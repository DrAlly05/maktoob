import 'package:epubx/epubx.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/audio_controller.dart';
import '../domain/chapter_text.dart';
import '../domain/translation_controller.dart';

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
      _status = 'Preparing Swahili. The first time needs internet '
          'to download the language pack.';
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
            : 'No Swahili voice on this phone yet, so only the text is shown. '
                'To hear it, install "Speech Recognition & Synthesis" by '
                'Google from the Play Store and download Swahili inside it.\n'
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
          _status = 'Swahili could not start. Check the internet connection '
              'and the free storage on this phone, then try again.';
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

  @override
  Widget build(BuildContext context) {
    final bookTitle = (widget.book.Title ?? '').trim();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          bookTitle.isEmpty ? 'Maktoob' : bookTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            tooltip: 'Text size',
            icon: const Icon(Icons.text_fields_rounded),
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() {
                _fontSize = _fontSize >= 26.0 ? 16.0 : _fontSize + 2.0;
              });
            },
          ),
        ],
      ),
      floatingActionButton: _chapters.isEmpty
          ? null
          : FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              onPressed: () {
                if (_playing) {
                  _stop();
                } else {
                  _play(_resumeParagraph);
                }
              },
              icon: Icon(
                _playing ? Icons.stop_rounded : Icons.play_arrow_rounded,
              ),
              label: Text(
                _playing
                    ? 'Stop'
                    : (_resumeParagraph > 0
                        ? 'Continue in Swahili'
                        : 'Listen in Swahili'),
              ),
            ),
      body: _chapters.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No readable text was found in this book.\n\n'
                  '${_describeBook(widget.book)}',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : Column(
              children: [
                if (_status != null) _StatusBanner(text: _status!),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _chapters.length,
                    onPageChanged: _onChapterChanged,
                    itemBuilder: (context, index) => _buildChapter(index),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildChapter(int chapterIndex) {
    final chapter = _chapters[chapterIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'SECTION ${chapterIndex + 1} OF ${_chapters.length}',
              style: const TextStyle(
                fontSize: 11,
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          if (chapter.title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
              child: Text(
                chapter.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          const SizedBox(height: 16),
          for (var i = 0; i < chapter.paragraphs.length; i++)
            _buildParagraph(chapterIndex, i, chapter),
        ],
      ),
    );
  }

  Widget _buildParagraph(int chapterIndex, int index, _Chapter chapter) {
    final isActive =
        _playing && chapterIndex == _chapterIndex && _activeParagraph == index;
    final swahili = _translations[_key(chapterIndex, index)];
    final isRightToLeft = chapter.language == BookLanguage.arabic;

    return Padding(
      key: _paragraphKey(chapterIndex, index),
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _play(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppColors.card : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive ? AppColors.accent : Colors.transparent,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                chapter.paragraphs[index],
                textDirection:
                    isRightToLeft ? TextDirection.rtl : TextDirection.ltr,
                style: TextStyle(
                  fontSize: _fontSize,
                  height: 1.7,
                  color: AppColors.textPrimary,
                ),
              ),
              if (swahili != null && swahili.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  swahili,
                  style: TextStyle(
                    fontSize: _fontSize - 1,
                    height: 1.6,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final String text;

  const _StatusBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.card,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
      ),
    );
  }
}
