import 'package:flutter_tts/flutter_tts.dart';

class AudioController {
  final FlutterTts _tts = FlutterTts();
  bool isSpeaking = false;

  AudioController() {
    _initializeTts();
  }

  void _initializeTts() async {
    // Set baseline audio parameters matching standard narration pacing
    await _tts.setSpeechRate(0.5); // Elegant, steady narrative flow
    await _tts.setPitch(1.0);      // Well-balanced vocal depth tone
    
    _tts.setStartHandler(() => isSpeaking = true);
    _tts.setCompletionHandler(() => isSpeaking = false);
    _tts.setErrorHandler((msg) => isSpeaking = false);
  }

  // Dictates chapter content strings on-device instantly
  Future<void> speak(String text, String languageCode) async {
    if (text.isEmpty) return;
    await _tts.setLanguage(languageCode);
    await _tts.speak(text);
  }

  // Halts active vocal rendering playback instantly
  Future<void> stop() async {
    await _tts.stop();
    isSpeaking = false;
  }
}
