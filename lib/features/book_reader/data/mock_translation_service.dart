class MockTranslationService {
  Future<String> translateToSwahili(String text) async {
    // Simulate on-device processing delay
    await Future.delayed(const Duration(milliseconds: 500));
    return 'Mambo vipi? (Translated: $text)';
  }
}
