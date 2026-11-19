import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:epubx/epubx.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'book.dart';
import 'chapter_text.dart';
import 'docx_text.dart';

/// Lets the reader choose a book file and turns it into a [Book].
class BookLoader {
  BookLoader._();

  /// The kinds of file the app can open.
  static const List<String> extensions = ['epub', 'pdf', 'docx', 'txt'];

  /// Opens the phone's file chooser for one book.
  /// Returns null when the reader cancels or the chooser fails.
  static Future<PlatformFile?> pick() async {
    try {
      return await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: extensions,
      );
    } catch (_) {
      return null;
    }
  }

  /// Reads the chosen file. Returns null when it cannot be opened at all.
  static Future<Book?> load(PlatformFile file) async {
    try {
      final bytes = await file.readAsBytes();
      final name = file.name;
      final dot = name.lastIndexOf('.');
      final extension = dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
      final title = dot <= 0 ? name : name.substring(0, dot);

      switch (extension) {
        case 'epub':
          return fromEpub(await EpubReader.readBook(bytes), title);
        case 'pdf':
          return await fromPdf(bytes, title);
        case 'docx':
          return fromDocx(bytes, title);
        case 'txt':
          return fromText(bytes, title);
        default:
          return null;
      }
    } catch (_) {
      return null;
    }
  }

  // Plain text ---------------------------------------------------------

  @visibleForTesting
  static Book fromText(List<int> bytes, String title) {
    var text = utf8.decode(bytes, allowMalformed: true);
    if (text.startsWith('﻿')) text = text.substring(1);
    final paragraphs = ChapterText.paragraphsFromPlainText(text);
    return Book(
      title: title,
      sections: _inGroups(paragraphs, 30),
      note: 'TXT. Aya: ${paragraphs.length}.',
    );
  }

  static List<BookSection> _inGroups(List<String> paragraphs, int size) {
    final sections = <BookSection>[];
    for (var start = 0; start < paragraphs.length; start += size) {
      final end =
          start + size > paragraphs.length ? paragraphs.length : start + size;
      sections.add(BookSection('', paragraphs.sublist(start, end)));
    }
    return sections;
  }

  // Word ---------------------------------------------------------------

  @visibleForTesting
  static Book fromDocx(List<int> bytes, String title) {
    final archive = ZipDecoder().decodeBytes(bytes);
    final file = archive.findFile('word/document.xml');
    if (file == null) {
      return Book(
        title: title,
        sections: const [],
        note: 'Word. Sehemu ya maandishi haikupatikana ndani ya faili.',
      );
    }
    final xml = utf8.decode(file.content as List<int>, allowMalformed: true);
    final parts = DocxText.sections(xml);
    return Book(
      title: title,
      sections: [
        for (final part in parts) BookSection(part.title, part.paragraphs),
      ],
      note: 'Word. Sehemu: ${parts.length}.',
    );
  }

  // PDF ----------------------------------------------------------------

  @visibleForTesting
  static Future<Book> fromPdf(Uint8List bytes, String title) async {
    // A long PDF takes seconds to read, so the work leaves the screen's thread.
    final pages = await Isolate.run(() => pdfPageTexts(bytes));

    final sections = <BookSection>[];
    for (var i = 0; i < pages.length; i++) {
      final paragraphs = ChapterText.paragraphsFromPlainText(pages[i]);
      if (paragraphs.isNotEmpty) {
        sections.add(BookSection('Ukurasa ${i + 1}', paragraphs));
      }
    }
    return Book(
      title: title,
      sections: sections,
      note: 'PDF. Kurasa: ${pages.length}. Kurasa zenye maandishi: '
          '${sections.length}. PDF ya picha zilizopigwa (scan) haina '
          'maandishi ya kusoma.',
    );
  }

  /// The text of every page of a PDF, in order.
  @visibleForTesting
  static List<String> pdfPageTexts(Uint8List bytes) {
    final document = PdfDocument(inputBytes: bytes);
    try {
      final extractor = PdfTextExtractor(document);
      return [
        for (var i = 0; i < document.pages.count; i++)
          extractor.extractText(startPageIndex: i, endPageIndex: i),
      ];
    } finally {
      document.dispose();
    }
  }

  // EPUB ---------------------------------------------------------------

  /// The book's own text files are read in reading order. The table of
  /// contents is used only when that gives nothing, because many books
  /// carry a table of contents this reader cannot follow.
  @visibleForTesting
  static Book fromEpub(EpubBook epub, String fallbackTitle) {
    var sections = _epubSectionsFromFiles(epub);
    if (sections.isEmpty) sections = _epubSectionsFromContents(epub);

    final ownTitle = (epub.Title ?? '').trim();
    final files = epub.Content?.Html?.length ?? 0;
    final order = epub.Schema?.Package?.Spine?.Items?.length ?? 0;
    final contents = epub.Chapters?.length ?? 0;
    return Book(
      title: ownTitle.isEmpty ? fallbackTitle : ownTitle,
      sections: sections,
      note: 'EPUB. Text files: $files. Reading order: $order. '
          'Contents: $contents.',
    );
  }

  static List<BookSection> _epubSectionsFromFiles(EpubBook epub) {
    final htmlFiles = epub.Content?.Html ?? const {};
    if (htmlFiles.isEmpty) return [];

    // Reading order: the spine lists item ids, the manifest maps ids to files.
    final fileNameById = <String, String>{};
    for (final item in epub.Schema?.Package?.Manifest?.Items ?? const []) {
      final id = item.Id;
      final href = item.Href;
      if (id != null && href != null) fileNameById[id] = href;
    }

    final pages = <String>[];
    final seen = <String>{};
    for (final entry in epub.Schema?.Package?.Spine?.Items ?? const []) {
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

    final sections = <BookSection>[];
    for (final html in pages) {
      final paragraphs = ChapterText.paragraphsFromHtml(html);
      if (paragraphs.isEmpty) continue;

      final title = ChapterText.headingFromHtml(html);
      if (title.isNotEmpty && paragraphs.first == title) {
        paragraphs.removeAt(0);
      }
      if (paragraphs.isEmpty) continue;

      sections.add(BookSection(title, paragraphs));
    }
    return sections;
  }

  static List<BookSection> _epubSectionsFromContents(EpubBook epub) {
    final sections = <BookSection>[];

    void visit(List<EpubChapter>? nodes) {
      for (final node in nodes ?? const <EpubChapter>[]) {
        final paragraphs =
            ChapterText.paragraphsFromHtml(node.HtmlContent ?? '');
        if (paragraphs.isNotEmpty) {
          sections.add(BookSection((node.Title ?? '').trim(), paragraphs));
        }
        visit(node.SubChapters);
      }
    }

    visit(epub.Chapters);
    return sections;
  }
}
