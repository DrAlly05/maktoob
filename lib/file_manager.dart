import 'package:epubx/epubx.dart';
import 'package:file_picker/file_picker.dart';

/// Lets the reader choose a book file and turns it into a book object.
class FileManager {
  /// Opens the phone's file chooser for one EPUB file.
  /// Returns null when the reader cancels or the chooser fails.
  static Future<PlatformFile?> pickEpubFile() async {
    try {
      return await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['epub'],
      );
    } catch (_) {
      return null;
    }
  }

  /// Reads the chosen file and parses it as an EPUB book.
  /// Returns null when the file is not a readable EPUB.
  static Future<EpubBook?> parseEpub(PlatformFile file) async {
    try {
      final bytes = await file.readAsBytes();
      return await EpubReader.readBook(bytes);
    } catch (_) {
      return null;
    }
  }
}
