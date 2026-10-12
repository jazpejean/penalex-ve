import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Micro-interacciones de audio del quiz.
///
/// API del rediseño (Fase 3): un player para efectos cortos y otro dedicado al
/// ambiente en loop. Assets esperados en `assets/audio/` (el usuario debe
/// añadirlos):
///   tap.mp3, correct.mp3, wrong.mp3, streak_5.mp3, streak_10.mp3,
///   streak_15.mp3, streak_20.mp3, victoria.mp3, ambient_loop.mp3
///
/// Mientras los MP3 nuevos no existan, [tap]/[correcta]/[incorrecta]/[victoria]
/// caen a los WAV sintéticos ya incluidos (tap_pop/quiz_correct/quiz_wrong/
/// victory). Los streak y el ambiente se omiten en silencio si faltan:
/// nunca rompen el quiz.
class SfxService {
  SfxService._();
  static final SfxService instance = SfxService._();

  static const _claveMute = 'quiz_sfx_muted';

  final AudioPlayer _player = AudioPlayer();
  final AudioPlayer _ambiente = AudioPlayer();
  bool _habilitado = true;
  bool _iniciado = false;

  /// Estado de silencio persistido en [SharedPreferences].
  bool get muted => !_habilitado;

  /// Carga la preferencia de mute y calienta la caché de los 9 assets.
  Future<void> init() async {
    if (_iniciado) return;
    _iniciado = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      _habilitado = !(prefs.getBool(_claveMute) ?? false);
    } catch (_) {
      // Sin storage: se mantiene el sonido activo.
    }
    // Precarga (fire-and-forget): si un asset falta, se ignora en silencio.
    for (final asset in const [
      'tap.mp3', 'correct.mp3', 'wrong.mp3',
      'streak_5.mp3', 'streak_10.mp3', 'streak_15.mp3', 'streak_20.mp3',
      'victoria.mp3', 'ambient_loop.mp3',
    ]) {
      try {
        await _player.setSource(AssetSource('audio/$asset'));
      } catch (_) {}
    }
  }

  /// Silenciar/activar todo; persiste la decisión.
  Future<void> mute(bool m) async {
    _habilitado = !m;
    if (m) await _ambiente.stop();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_claveMute, m);
    } catch (_) {}
  }

  /// Silenciar/activar sin persistir (compatibilidad con usos previos).
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

  /// Intenta el MP3 nuevo; si no existe, usa el WAV sintético equivalente.
  Future<void> _playConFallback(String mp3, String wav, {double volumen = 1}) async {
    if (!_habilitado) return;
    try {
      await _player.stop();
      await _player.setVolume(volumen);
      await _player.play(AssetSource('audio/$mp3'));
    } catch (_) {
      try {
        await _player.stop();
        await _player.setVolume(volumen);
        await _player.play(AssetSource('audio/$wav'));
      } catch (_) {}
    }
  }

  Future<void> tap() async {
    await _playConFallback('tap.mp3', 'tap_pop.wav', volumen: 0.3);
  }

  Future<void> correcta() async {
    await _playConFallback('correct.mp3', 'quiz_correct.wav', volumen: 0.7);
    HapticFeedback.lightImpact();
  }

  Future<void> incorrecta() async {
    await _playConFallback('wrong.mp3', 'quiz_wrong.wav', volumen: 0.6);
    HapticFeedback.mediumImpact();
  }

  Future<void> victoria() async {
    await _playConFallback('victoria.mp3', 'victory.wav', volumen: 0.8);
    HapticFeedback.heavyImpact();
  }

  /// Fanfarria para ascensos de rango.
  Future<void> ascenso() => victoria();

  /// Arpegio según la racha: 5, 10, 15 o 20 (el mayor múltiplo alcanzado).
  Future<void> racha(int racha) async {
    if (!_habilitado || racha < 5) return;
    final nivel = racha >= 20
        ? 20
        : racha >= 15
            ? 15
            : racha >= 10
                ? 10
                : 5;
    await play('streak_$nivel.mp3', volumen: 0.7);
  }

  /// Pad ambiental en loop (volumen bajo). Omite si el asset no existe.
  Future<void> ambienteStart() async {
    if (!_habilitado) return;
    try {
      await _ambiente.stop();
      await _ambiente.setReleaseMode(ReleaseMode.loop);
      await _ambiente.setVolume(0.15);
      await _ambiente.play(AssetSource('audio/ambient_loop.mp3'));
    } catch (_) {
      // asset ausente: silencioso
    }
  }

  Future<void> ambienteStop() async {
    try {
      await _ambiente.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _player.dispose();
    await _ambiente.dispose();
  }
}