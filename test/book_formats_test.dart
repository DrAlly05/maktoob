import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maktoob/features/book_reader/domain/book_loader.dart';
import 'package:maktoob/features/book_reader/domain/chapter_text.dart';
import 'package:maktoob/features/book_reader/domain/docx_text.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

void main() {
  group('paragraphsFromPlainText', () {
    test('a blank line ends a paragraph, a single break does not', () {
      final result = ChapterText.paragraphsFromPlainText(
        'First line\nstill first.\n\nSecond one.\r\n\r\nThird.',
      );
      expect(result, ['First line still first.', 'Second one.', 'Third.']);
    });

    test('joins a word cut by a hyphen at the end of a line', () {
      expect(
        ChapterText.paragraphsFromPlainText('An exam-\nple here.'),
        ['An example here.'],
      );
    });
  });

  group('text file', () {
    test('becomes a book with sections of at most 30 paragraphs', () {
      final text = List.generate(65, (i) => 'Aya namba $i.').join('\n\n');
      final book = BookLoader.fromText(utf8.encode('﻿$text'), 'Kitabu');
      expect(book.title, 'Kitabu');
      expect(book.sections.map((s) => s.paragraphs.length), [30, 30, 5]);
      expect(book.sections.first.paragraphs.first, 'Aya namba 0.');
    });
  });

  group('Word document', () {
    const xml = '<w:document><w:body>'
        '<w:p><w:pPr><w:pStyle w:val="Heading1"/></w:pPr>'
        '<w:r><w:t>Sura ya Kwanza</w:t></w:r></w:p>'
        '<w:p><w:r><w:t xml:space="preserve">Tom &amp; </w:t></w:r>'
        '<w:r><w:t>Jerry.</w:t></w:r></w:p>'
        '<w:p><w:pPr/></w:p>'
        '<w:p><w:pPr><w:pStyle w:val="Heading1"/></w:pPr>'
        '<w:r><w:t>Sura ya Pili</w:t></w:r></w:p>'
        '<w:p><w:r><w:t>Mwisho.</w:t></w:r></w:p>'
        '</w:body></w:document>';

    test('headings start sections and runs are joined', () {
      final parts = DocxText.sections(xml);
      expect(parts.length, 2);
      expect(parts[0].title, 'Sura ya Kwanza');
      expect(parts[0].paragraphs, ['Tom & Jerry.']);
      expect(parts[1].title, 'Sura ya Pili');
      expect(parts[1].paragraphs, ['Mwisho.']);
    });

    test('is read from a real .docx archive', () {
      final data = utf8.encode(xml);
      final archive = Archive()
        ..addFile(ArchiveFile('word/document.xml', data.length, data));
      final bytes = ZipEncoder().encode(archive)!;
      final book = BookLoader.fromDocx(bytes, 'Hati');
      expect(book.sections.length, 2);
      expect(book.sections.first.title, 'Sura ya Kwanza');
    });
  });

  group('PDF', () {
    test('text is read back from each page', () async {
      final document = PdfDocument();
      final font = PdfStandardFont(PdfFontFamily.helvetica, 14);
      document.pages.add().graphics.drawString('Ukurasa wa kwanza.', font);
      document.pages.add().graphics.drawString('Ukurasa wa pili.', font);
      final bytes = Uint8List.fromList(await document.save());
      document.dispose();

      final pages = BookLoader.pdfPageTexts(bytes);
      expect(pages.length, 2);
      expect(pages[0], contains('Ukurasa wa kwanza.'));
      expect(pages[1], contains('Ukurasa wa pili.'));
    });
  });
}
