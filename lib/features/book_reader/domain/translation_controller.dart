import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class TranslationController {
  // Configures a free local translator pipeline from Arabic to Swahili
  final OnDeviceTranslator _translator = OnDeviceTranslator(
    sourceLanguage: TranslateLanguage.arabic,
    targetLanguage: TranslateLanguage.swahili,
  );

  bool _isModelDownloaded = false;

  // Verifies that the language translation files exist on the phone storage
  Future<void> ensureModelDownloaded() async {
    if (_isModelDownloaded) return;

    final modelManager = OnDeviceTranslatorModelManager();
    
    // Natively download language packages using official string tags
    await modelManager.downloadModel('ar');
    await modelManager.downloadModel('sw');
    
    _isModelDownloaded = true;
  }

  // Translates a block of text text completely for free on-device
  Future<String> translateArabicToSwahili(String rawText) async {
    if (rawText.isEmpty) return "";
    try {
      await ensureModelDownloaded();
      return await _translator.translateText(rawText);
    } catch (e) {
      return "Translation Error: Ensure storage space is available for local packages.";
    }
  }

  // Safely close local engine processes when leaving the screen
  void close() {
    _translator.close();
  }
}
