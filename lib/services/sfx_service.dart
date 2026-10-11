import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Micro-interacciones de audio del quiz.
///
/// Un solo player reutilizable (evita solapamiento y saturación).
/// Los assets son WAV cortos sintetizados (assets/audio/*.wav).
class SfxService {
  SfxService._();
  static final SfxService instance = SfxService._();

  final AudioPlayer _player = AudioPlayer();
  bool _habilitado = true;

  /// Silenciar/activar todo (ajuste de usuario).
  set habilitado(bool v) => _habilitado = v;

  Future<void> play(String asset, {double volumen = 1}) async {
    if (!_habilitado) return;
    try {
      await _player.stop();
      await _player.setVolume(volumen);
      await _player.play(AssetSource('audio/$asset'));
    } catch (_) {
      // asset ausente o plataforma sin audio: silencioso, nunca rompe el quiz
    }
  }

  Future<void> correcta() async {
    await play('quiz_correct.wav', volumen: 0.7);
    HapticFeedback.lightImpact();
  }

  Future<void> incorrecta() async {
    await play('quiz_wrong.wav', volumen: 0.6);
    HapticFeedback.mediumImpact();
  }

  Future<void> tap() async {
    await play('tap_pop.wav', volumen: 0.3);
  }

  Future<void> victoria() async {
    await play('victory.wav', volumen: 0.8);
    HapticFeedback.heavyImpact();
  }

  Future<void> dispose() => _player.dispose();
}