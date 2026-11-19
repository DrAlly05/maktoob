/// Pure text helpers for the reader.
///
/// No Flutter or plugin imports, so every function here can be unit tested.
library;

/// The languages a book can be written in, as far as the reader can tell.
enum BookLanguage { arabic, english }

class ChapterText {
  ChapterText._();

  static final RegExp _hiddenBlocks = RegExp(
    r'<(script|style|head)\b[^>]*>.*?</\1\s*>',
    caseSensitive: false,
    dotAll: true,
  );
  static final RegExp _blockBreaks = RegExp(
    r'</(p|div|h[1-6]|li|blockquote|tr|section|article)\s*>|<br\s*/?>|<hr\s*/?>',
    caseSensitive: false,
  );
  static final RegExp _anyTag = RegExp(r'<[^>]*>');
  static final RegExp _lineBreakTag = RegExp(r'<br\s*/?>', caseSensitive: false);
  static final RegExp _heading = RegExp(
    r'<h([1-3])\b[^>]*>(.*?)</h\1\s*>',
    caseSensitive: false,
    dotAll: true,
  );
  static final RegExp _inlineSpace = RegExp(r'[ \t\r\f ]+');
  static final RegExp _numericEntity = RegExp(r'&#(x?)([0-9a-fA-F]+);');
  static final RegExp _sentenceEnd = RegExp(r'(?<=[.!?…؟۔])\s+');
  static final RegExp _arabicLetter = RegExp(r'[؀-ۿ]');
  static final RegExp _latinLetter = RegExp(r'[A-Za-z]');

  static const Map<String, String> _namedEntities = {
    '&nbsp;': ' ',
    '&quot;': '"',
    '&apos;': "'",
    '&lsquo;': '‘',
    '&rsquo;': '’',
    '&ldquo;': '“',
    '&rdquo;': '”',
    '&mdash;': '—',
    '&ndash;': '–',
    '&hellip;': '…',
    '&lt;': '<',
    '&gt;': '>',
  };

  /// Turns one chapter of EPUB HTML into a list of readable paragraphs.
  ///
  /// Each paragraph is short enough to translate and speak in one piece.
  static List<String> paragraphsFromHtml(String html, {int maxLength = 1200}) {
    var text = html.replaceAll(_hiddenBlocks, ' ');
    // Line breaks in the source are layout, not paragraph breaks.
    text = text.replaceAll('\n', ' ');
    text = text.replaceAll(_blockBreaks, '\n');
    text = text.replaceAll(_anyTag, '');
    text = decodeEntities(text);

    final paragraphs = <String>[];
    for (final line in text.split('\n')) {
      final clean = line.replaceAll(_inlineSpace, ' ').trim();
      if (clean.isEmpty) continue;
      paragraphs.addAll(splitLong(clean, maxLength: maxLength));
    }
    return paragraphs;
  }

  /// Returns the first heading of a chapter file, or an empty string.
  static String headingFromHtml(String html) {
    final body = html.replaceAll(_hiddenBlocks, ' ');
    final match = _heading.firstMatch(body);
    if (match == null) return '';
    final text = match
        .group(2)!
        .replaceAll('\n', ' ')
        .replaceAll(_lineBreakTag, ' ')
        .replaceAll(_anyTag, '');
    return decodeEntities(text).replaceAll(_inlineSpace, ' ').trim();
  }

  /// Replaces HTML entities such as `&amp;` and `&#8220;` with real characters.
  static String decodeEntities(String text) {
    var out = text;
    _namedEntities.forEach((entity, value) {
      out = out.replaceAll(entity, value);
    });
    out = out.replaceAllMapped(_numericEntity, (match) {
      final isHex = match.group(1)!.isNotEmpty;
      final code = int.tryParse(match.group(2)!, radix: isHex ? 16 : 10);
      if (code == null || code <= 0 || code > 0x10FFFF) return match.group(0)!;
      return String.fromCharCode(code);
    });
    return out.replaceAll('&amp;', '&');
  }

  /// Cuts a long paragraph into pieces no longer than [maxLength],
  /// breaking at the end of a sentence wherever possible.
  static List<String> splitLong(String paragraph, {int maxLength = 1200}) {
    if (paragraph.length <= maxLength) return [paragraph];

    final pieces = <String>[];
    var current = '';
    for (final sentence in paragraph.split(_sentenceEnd)) {
      var rest = sentence.trim();
      if (rest.isEmpty) continue;

      // One sentence longer than the limit is cut at a space.
      while (rest.length > maxLength) {
        if (current.isNotEmpty) {
          pieces.add(current);
          current = '';
        }
        var cut = rest.lastIndexOf(' ', maxLength);
        if (cut <= 0) cut = maxLength;
        pieces.add(rest.substring(0, cut).trim());
        rest = rest.substring(cut).trim();
      }
      if (rest.isEmpty) continue;

      if (current.isEmpty) {
        current = rest;
      } else if (current.length + 1 + rest.length <= maxLength) {
        current = '$current $rest';
      } else {
        pieces.add(current);
        current = rest;
      }
    }
    if (current.isNotEmpty) pieces.add(current);
    return pieces;
  }

  /// Guesses the language of a passage from its script.
  ///
  /// Arabic script means Arabic. Anything else is treated as English for now.
  static BookLanguage detectLanguage(String text) {
    final sample = text.length > 2000 ? text.substring(0, 2000) : text;
    final arabic = _arabicLetter.allMatches(sample).length;
    final latin = _latinLetter.allMatches(sample).length;
    return arabic > latin ? BookLanguage.arabic : BookLanguage.english;
  }
}
