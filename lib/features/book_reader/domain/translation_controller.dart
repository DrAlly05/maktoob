import 'package:google_mlkit_translation/google_mlkit_translation.dart';

import 'chapter_text.dart';

/// Translates book text into Swahili on the phone itself.
///
/// Internet is needed only once, to download each language pack.
class TranslationController {
  final OnDeviceTranslatorModelManager _modelManager =
      OnDeviceTranslatorModelManager();
  final Map<BookLanguage, OnDeviceTranslator> _translators = {};
  final Set<String> _readyModels = {};

  static TranslateLanguage _mlKitLanguage(BookLanguage language) {
    return switch (language) {
      BookLanguage.arabic => TranslateLanguage.arabic,
      BookLanguage.english => TranslateLanguage.english,
    };
  }

  static String _modelCode(BookLanguage language) {
    return switch (language) {
      BookLanguage.arabic => 'ar',
      BookLanguage.english => 'en',
    };
  }

  Future<void> _ensureModel(String code) async {
    if (_readyModels.contains(code)) return;
    final alreadyOnPhone = await _modelManager.isModelDownloaded(code);
    if (!alreadyOnPhone) {
      // Mobile data is allowed: many readers have no Wi-Fi.
      await _modelManager.downloadModel(code, isWifiRequired: false);
    }
    _readyModels.add(code);
  }

  /// Makes sure the language packs for [source] and Swahili are on the phone.
  Future<void> prepare(BookLanguage source) async {
    await _ensureModel(_modelCode(source));
    await _ensureModel('sw');
  }

  /// Translates one passage into Swahili.
  Future<String> translateToSwahili(String text, BookLanguage source) async {
    if (text.trim().isEmpty) return '';
    await prepare(source);
    final translator = _translators.putIfAbsent(
      source,
      () => OnDeviceTranslator(
        sourceLanguage: _mlKitLanguage(source),
        targetLanguage: TranslateLanguage.swahili,
      ),
    );
    return translator.translateText(text);
  }

  /// Releases the translation engines when the reader closes.
  void close() {
    for (final translator in _translators.values) {
      translator.close();
    }
    _translators.clear();
  }
}
