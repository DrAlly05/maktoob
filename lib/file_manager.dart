import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:epubx/epubx.dart';

class FileManager {
  // Opens the local system explorer securely using stable API layers
  static Future<File?> pickEpubFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['epub'],
      );

      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
    } catch (e) {
      // Production fail-safe logging sandbox
    }
    return null;
  }

  // Decodes book bytes into clean interface layout objects safely
  static Future<EpubBook?> parseEpub(File file) async {
    try {
      List<int> bytes = await file.readAsBytes();
      return await EpubReader.readBook(bytes);
    } catch (e) {
      return null;
    }
  }
}
