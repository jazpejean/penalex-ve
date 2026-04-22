import 'package:flutter/foundation.dart';
import '../services/audio_service.dart';

class AudioProvider extends ChangeNotifier {

  AudioProvider() {
    _audioService.init();
  }
  final AudioService _audioService = AudioService();

  void toggleMusic() {
    _audioService.toggleMusic();
    notifyListeners();
  }

  void playCorrectSound() {
    _audioService.playCorrectSound();
  }

  void playWrongSound() {
    _audioService.playWrongSound();
  }

  void playAscensionSound() {
    _audioService.playAscensionSound();
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
}