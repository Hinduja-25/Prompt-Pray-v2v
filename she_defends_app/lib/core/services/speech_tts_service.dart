import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

class SpeechTtsService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _speechAvailable = false;

  Future<void> init() async {
    try {
      _speechAvailable = await _speech.initialize(
        onError: (val) => debugPrint('Speech recognize error: $val'),
        onStatus: (val) => debugPrint('Speech recognize status: $val'),
      );
      
      // Setup TTS parameters
      await _tts.setLanguage("en-US");
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
    } catch (e) {
      debugPrint("Error initializing Speech or TTS service: $e");
    }
  }

  // --- Speech To Text Methods ---
  Future<void> startListening(Function(String) onResult) async {
    if (!_speechAvailable) {
      await init();
    }
    
    if (_speechAvailable) {
      _speech.listen(
        onResult: (result) => onResult(result.recognizedWords),
      );
    } else {
      debugPrint("Speech recognition is unavailable on this device.");
    }
  }

  Future<void> stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  bool get isListening => _speech.isListening;

  // --- Text To Speech Methods ---
  Future<void> speak(String text) async {
    try {
      await _tts.speak(text);
    } catch (e) {
      debugPrint("Error outputting TTS: $e");
    }
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
  }
}
