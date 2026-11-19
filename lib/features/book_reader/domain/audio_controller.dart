import 'package:flutter_tts/flutter_tts.dart';

/// Reads Swahili text aloud with the phone's own voice.
class AudioController {
  final FlutterTts _tts = FlutterTts();
  bool _ready = false;
  bool _voiceAvailable = false;

  /// Sets the voice up once.
  ///
  /// Returns false when the phone has no Swahili voice installed.
  Future<bool> prepare() async {
    if (_ready) return _voiceAvailable;

    // Makes speak() finish only when the voice has finished the passage.
    await _tts.awaitSpeakCompletion(true);
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);

    for (final code in const ['sw-TZ', 'sw-KE', 'sw']) {
      final available = await _tts.isLanguageAvailable(code);
      if (available == true) {
        await _tts.setLanguage(code);
        _voiceAvailable = true;
        break;
      }
    }

    _ready = true;
    return _voiceAvailable;
  }

  /// Speaks one passage and completes when the voice has finished it.
  Future<void> speak(String text) async {
    if (!_voiceAvailable || text.trim().isEmpty) return;
    await _tts.speak(text);
  }

  /// Stops the voice at once.
  Future<void> stop() async {
    await _tts.stop();
  }
}
