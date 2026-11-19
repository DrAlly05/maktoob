import 'package:flutter_test/flutter_test.dart';
import 'package:maktoob/features/book_reader/domain/chapter_text.dart';

void main() {
  group('paragraphsFromHtml', () {
    test('turns block tags into separate paragraphs and drops the head', () {
      final result = ChapterText.paragraphsFromHtml(
        '<html><head><title>T</title><style>p{}</style></head>'
        '<body><h1>One</h1><p>First   para.</p>\n<p>Second<br/>line</p>'
        '</body></html>',
      );
      expect(result, ['One', 'First para.', 'Second', 'line']);
    });

    test('decodes entities', () {
      final result = ChapterText.paragraphsFromHtml(
        '<p>Tom &amp; Jerry&nbsp;said &#8220;hi&#8221; &#x41;</p>',
      );
      expect(result, ['Tom & Jerry said “hi” A']);
    });

    test('returns nothing for markup with no text', () {
      expect(ChapterText.paragraphsFromHtml('<div><p> </p><br/></div>'), isEmpty);
    });
  });

  group('splitLong', () {
    test('leaves a short paragraph whole', () {
      expect(ChapterText.splitLong('Short one.', maxLength: 100), ['Short one.']);
    });

    test('breaks at sentence ends and respects the limit', () {
      final sentence = '${'a' * 49}.';
      final pieces = ChapterText.splitLong(
        '$sentence $sentence $sentence',
        maxLength: 110,
      );
      expect(pieces, ['$sentence $sentence', sentence]);
    });

    test('cuts a sentence that is longer than the limit', () {
      final pieces = ChapterText.splitLong('x' * 250, maxLength: 100);
      expect(pieces.map((p) => p.length), [100, 100, 50]);
    });

    test('never returns a piece above the limit', () {
      final text = List.filled(60, 'Maneno machache ya kujaribu hapa.').join(' ');
      final pieces = ChapterText.splitLong(text, maxLength: 120);
      expect(pieces.every((p) => p.length <= 120), isTrue);
      expect(pieces.join(' '), text);
    });
  });

  group('detectLanguage', () {
    test('Latin script is treated as English', () {
      expect(ChapterText.detectLanguage('Hello world'), BookLanguage.english);
    });

    test('Arabic script is Arabic', () {
      expect(
        ChapterText.detectLanguage('مرحبا بالعالم'),
        BookLanguage.arabic,
      );
    });
  });
}
