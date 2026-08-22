import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  bool _soundEnabled = true;
  bool get soundEnabled => _soundEnabled;

  void toggleSound() {
    _soundEnabled = !_soundEnabled;
  }

  Future<void> playCorrect() async {
    if (!_soundEnabled) return;
    try {
      HapticFeedback.lightImpact();
      // Plays system feedback or loads wav
    } catch (_) {}
  }

  Future<void> playError() async {
    if (!_soundEnabled) return;
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  Future<void> playFanfare() async {
    if (!_soundEnabled) return;
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  Future<void> playGavel() async {
    if (!_soundEnabled) return;
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}
  }
}
