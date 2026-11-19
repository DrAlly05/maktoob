import 'chapter_text.dart';

/// Reads the text of a Word document from its `word/document.xml` part.
///
/// Pure text work, no plugins, so it can be unit tested.
class DocxText {
  DocxText._();

  static final RegExp _paragraph = RegExp(r'<w:p[ >][\s\S]*?</w:p>');
  static final RegExp _run = RegExp(
    r'<w:t(?: [^>]*)?>([\s\S]*?)</w:t>|<w:tab/>|<w:br[^>]*/>',
  );
  static final RegExp _style = RegExp(r'<w:pStyle w:val="([^"]+)"');
  static final RegExp _space = RegExp(r'\s+');

  /// Splits the document into sections. A heading starts a new section.
  /// A document with no headings is cut every [sectionSize] paragraphs.
  static List<({String title, List<String> paragraphs})> sections(
    String xml, {
    int sectionSize = 30,
  }) {
    final result = <({String title, List<String> paragraphs})>[];
    var title = '';
    var current = <String>[];
    var sawHeading = false;

    void close() {
      if (current.isNotEmpty) {
        result.add((title: title, paragraphs: current));
      }
      current = <String>[];
    }

    for (final match in _paragraph.allMatches(xml)) {
      final block = match.group(0)!;
      final buffer = StringBuffer();
      for (final run in _run.allMatches(block)) {
        buffer.write(run.group(1) ?? ' ');
      }
      final text = ChapterText.decodeEntities(buffer.toString())
          .replaceAll(_space, ' ')
          .trim();
      if (text.isEmpty) continue;

      final style = _style.firstMatch(block)?.group(1)?.toLowerCase() ?? '';
      if (style == 'title' || style == 'heading1' || style == 'heading2') {
        close();
        title = text;
        sawHeading = true;
        continue;
      }

      current.addAll(ChapterText.splitLong(text, maxLength: 700));
      if (!sawHeading && current.length >= sectionSize) close();
    }
    close();
    return result;
  }
}
