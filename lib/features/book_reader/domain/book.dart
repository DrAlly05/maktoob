import 'chapter_text.dart';

/// One part of a book: a chapter, a page, or a run of paragraphs.
class BookSection {
  final String title;
  final List<String> paragraphs;
  final BookLanguage language;

  BookSection(this.title, this.paragraphs)
      : language = ChapterText.detectLanguage(paragraphs.take(8).join(' '));
}

/// A book ready for the reader, whatever kind of file it came from.
class Book {
  final String title;
  final List<BookSection> sections;

  /// A short technical line shown when the book has no readable text,
  /// so the cause can be found from a screenshot.
  final String note;

  const Book({required this.title, required this.sections, this.note = ''});
}
