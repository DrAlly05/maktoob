import 'package:flutter_tts/flutter_tts.dart';

/// Reads Swahili text aloud with the phone's own voice.
class AudioController {
  /// Google's voice engine. It has Swahili. Samsung's own engine does not.
  static const String _googleEngine = 'com.google.android.tts';

  final FlutterTts _tts = FlutterTts();
  bool _configured = false;
  bool _voiceAvailable = false;
  String _engineNote = '';
  double _rate = 0.5;

  /// A short technical line about the voice engines on this phone,
  /// shown when no Swahili voice is found.
  String get engineNote => _engineNote;

  /// Gets the voice ready.
  ///
  /// Returns false when the phone has no Swahili voice. The check is
  /// repeated on every call until a voice is found, so a reader who
  /// installs one does not have to restart the app.
  Future<bool> prepare() async {
    if (_voiceAvailable) return true;

    if (!_configured) {
      // Makes speak() finish only when the voice has finished the passage.
      await _tts.awaitSpeakCompletion(true);
      _configured = true;
    }

    await _preferGoogleEngine();
    await _tts.setSpeechRate(_rate);
    await _tts.setPitch(1.0);

    for (final code in const ['sw-TZ', 'sw-KE', 'sw']) {
      final available = await _tts.isLanguageAvailable(code);
      if (available == true) {
        await _tts.setLanguage(code);
        _voiceAvailable = true;
        break;
      }
    }
    return _voiceAvailable;
  }

  /// Switches to Google's engine when the phone has it, whatever the
  /// phone's default engine is.
  Future<void> _preferGoogleEngine() async {
    try {
      final engines = await _tts.getEngines;
      final names = engines is List
          ? engines.map((engine) => engine.toString()).toList()
          : <String>[];
      _engineNote = names.isEmpty
          ? 'Voice engines found: none.'
          : 'Voice engines found: ${names.join(', ')}.';
      if (names.contains(_googleEngine)) {
        await _tts.setEngine(_googleEngine);
      }
    } catch (_) {
      // Only Android has selectable engines. Other systems use their own voice.
      _engineNote = '';
    }
  }

  /// Speaks one passage and completes when the voice has finished it.
  Future<void> speak(String text) async {
    if (!_voiceAvailable || text.trim().isEmpty) return;
    await _tts.speak(text);
  }

  /// Changes how fast the voice speaks. 0.5 is the normal pace.
  /// The change is heard from the next paragraph.
  Future<void> setRate(double rate) async {
    _rate = rate;
    try {
      await _tts.setSpeechRate(rate);
    } catch (_) {
      // No voice engine yet. The rate is applied when one is prepared.
    }
  }

  /// Stops the voice at once.
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {
      // Nothing was speaking, or there is no voice engine.
    }
  }
}
