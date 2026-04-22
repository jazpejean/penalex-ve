import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioService {
  factory AudioService() => _instance;
  AudioService._internal();
  static final AudioService _instance = AudioService._internal();

  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  bool _isMusicMuted = false;
  double _musicVolume = 0.3;

  Future<void> init() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _isMusicMuted = prefs.getBool('music_muted') ?? false;
    _musicVolume = prefs.getDouble('music_volume') ?? 0.3;

    if (!_isMusicMuted) {
      await _playBackgroundMusic();
    }
  }

  Future<void> _playBackgroundMusic() async {
    try {
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.setVolume(_musicVolume);
      await _musicPlayer.setSource(AssetSource('audio/ambient.mp3'));
      await _musicPlayer.resume();
    } on Exception catch (e) {
      debugPrint('Error playing background music: $e');
    }
  }

  Future<void> toggleMusic() async {
    _isMusicMuted = !_isMusicMuted;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('music_muted', _isMusicMuted);

    if (_isMusicMuted) {
      await _musicPlayer.pause();
    } else {
      await _playBackgroundMusic();
    }
  }

  Future<void> playCorrectSound() async {
    try {
      await _sfxPlayer.setVolume(0.7);
      await _sfxPlayer.setSource(AssetSource('audio/correct.mp3'));
      await _sfxPlayer.resume();
    } on Exception catch (e) {
      debugPrint('Error playing correct sound: $e');
    }
  }

  Future<void> playWrongSound() async {
    try {
      await _sfxPlayer.setVolume(0.7);
      await _sfxPlayer.setSource(AssetSource('audio/wrong.mp3'));
      await _sfxPlayer.resume();
    } on Exception catch (e) {
      debugPrint('Error playing wrong sound: $e');
    }
  }

  Future<void> playAscensionSound() async {
    try {
      await _sfxPlayer.setVolume(0.8);
      await _sfxPlayer.setSource(AssetSource('audio/ascenso.mp3'));
      await _sfxPlayer.resume();
    } on Exception catch (e) {
      debugPrint('Error playing ascension sound: $e');
    }
  }

  void dispose() {
    _musicPlayer.dispose();
    _sfxPlayer.dispose();
  }
}