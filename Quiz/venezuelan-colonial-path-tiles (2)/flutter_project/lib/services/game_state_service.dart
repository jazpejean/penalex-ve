import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_state_model.dart';

class GameStateService extends ChangeNotifier {
  static const int MAX_APELACIONES = 5;
  static const int REGENERATION_MINUTES = 30;

  late SharedPreferences _prefs;
  GameState _state = const GameState(
    nivelActual: 1,
    xp: 0,
    apelaciones: 5,
    racha: 0,
    ultimoGastoApelacion: null,
    fallosPorNivel: {},
    nivelesCompletados: {},
  );

  Timer? _regenTimer;

  GameState get state => _state;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadState();
    _checkRegeneration();
    _startRegenTimer();
  }

  void _loadState() {
    final nivel = _prefs.getInt('nivelActual') ?? 1;
    final xp = _prefs.getInt('xp') ?? 0;
    final apelaciones = _prefs.getInt('apelaciones') ?? 5;
    final racha = _prefs.getInt('racha') ?? 0;
    final lastSpendStr = _prefs.getString('ultimoGastoApelacion');
    final DateTime? lastSpend = lastSpendStr != null ? DateTime.tryParse(lastSpendStr) : null;

    final fallosKeys = _prefs.getStringList('fallosNiveles') ?? [];
    final Map<int, int> fallosMap = {};
    for (var entry in fallosKeys) {
      final parts = entry.split(':');
      if (parts.length == 2) {
        final lvl = int.tryParse(parts[0]);
        final count = int.tryParse(parts[1]);
        if (lvl != null && count != null) {
          fallosMap[lvl] = count;
        }
      }
    }

    final completedList = _prefs.getStringList('nivelesCompletados') ?? [];
    final Set<int> completedSet = completedList.map((e) => int.tryParse(e) ?? 0).where((e) => e > 0).toSet();

    _state = GameState(
      nivelActual: nivel,
      xp: xp,
      apelaciones: apelaciones,
      racha: racha,
      ultimoGastoApelacion: lastSpend,
      fallosPorNivel: fallosMap,
      nivelesCompletados: completedSet,
    );
    notifyListeners();
  }

  Future<void> _saveState() async {
    await _prefs.setInt('nivelActual', _state.nivelActual);
    await _prefs.setInt('xp', _state.xp);
    await _prefs.setInt('apelaciones', _state.apelaciones);
    await _prefs.setInt('racha', _state.racha);
    if (_state.ultimoGastoApelacion != null) {
      await _prefs.setString('ultimoGastoApelacion', _state.ultimoGastoApelacion!.toIso8601String());
    }

    final fallosList = _state.fallosPorNivel.entries.map((e) => "${e.key}:${e.value}").toList();
    await _prefs.setStringList('fallosNiveles', fallosList);

    final completedList = _state.nivelesCompletados.map((e) => e.toString()).toList();
    await _prefs.setStringList('nivelesCompletados', completedList);
  }

  void _startRegenTimer() {
    _regenTimer?.cancel();
    _regenTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkRegeneration();
    });
  }

  void _checkRegeneration() {
    if (_state.apelaciones >= MAX_APELACIONES) return;
    if (_state.ultimoGastoApelacion == null) return;

    final now = DateTime.now();
    final difference = now.difference(_state.ultimoGastoApelacion!);
    final intervalsPassed = difference.inMinutes ~/ REGENERATION_MINUTES;

    if (intervalsPassed > 0) {
      final newApelaciones = (_state.apelaciones + intervalsPassed).clamp(0, MAX_APELACIONES);
      DateTime? nextLastSpend;
      if (newApelaciones < MAX_APELACIONES) {
        nextLastSpend = _state.ultimoGastoApelacion!.add(Duration(minutes: intervalsPassed * REGENERATION_MINUTES));
      } else {
        nextLastSpend = null;
      }

      _state = _state.copyWith(
        apelaciones: newApelaciones,
        ultimoGastoApelacion: nextLastSpend,
      );
      _saveState();
      notifyListeners();
    }
  }

  Duration? getTimeUntilNextRegen() {
    if (_state.apelaciones >= MAX_APELACIONES || _state.ultimoGastoApelacion == null) return null;
    final now = DateTime.now();
    final nextRegenTime = _state.ultimoGastoApelacion!.add(const Duration(minutes: REGENERATION_MINUTES));
    final diff = nextRegenTime.difference(now);
    return diff.isNegative ? Duration.zero : diff;
  }

  /// Process Correct Answer
  Future<int> onAnswerCorrect(int level) async {
    final earnedXp = (_state.racha >= 2) ? 15 : 10;
    final newXp = _state.xp + earnedXp;
    final newRacha = _state.racha + 1;
    final newCompleted = Set<int>.from(_state.nivelesCompletados)..add(level);
    
    // Clear failure counter for this level
    final updatedFailures = Map<int, int>.from(_state.fallosPorNivel);
    updatedFailures.remove(level);

    int newLevel = _state.nivelActual;
    if (level == _state.nivelActual && newLevel < 3000) {
      newLevel++;
    }

    _state = _state.copyWith(
      nivelActual: newLevel,
      xp: newXp,
      racha: newRacha,
      fallosPorNivel: updatedFailures,
      nivelesCompletados: newCompleted,
    );
    await _saveState();
    notifyListeners();
    return earnedXp;
  }

  /// Process Failure or Anti-cheat penalty (costs 1 appeal immediately)
  Future<bool> onAnswerFailed(int level, {bool isAntiCheat = false}) async {
    final currentAppeals = _state.apelaciones;
    final newAppeals = (currentAppeals - 1).clamp(0, MAX_APELACIONES);
    final now = DateTime.now();
    final lastSpend = _state.ultimoGastoApelacion ?? now;

    final updatedFailures = Map<int, int>.from(_state.fallosPorNivel);
    updatedFailures[level] = (updatedFailures[level] ?? 0) + 1;

    _state = _state.copyWith(
      apelaciones: newAppeals,
      racha: 0, // resets streak
      ultimoGastoApelacion: (newAppeals < MAX_APELACIONES) ? lastSpend : null,
      fallosPorNivel: updatedFailures,
    );
    await _saveState();
    notifyListeners();

    // Returns true if player still has appeals left to play
    return newAppeals > 0;
  }

  /// Unlock a locked level (costs 1 extra appeal)
  Future<bool> unlockLevel(int level) async {
    if (_state.apelaciones < 1) return false;

    final newAppeals = (_state.apelaciones - 1).clamp(0, MAX_APELACIONES);
    final updatedFailures = Map<int, int>.from(_state.fallosPorNivel);
    updatedFailures[level] = 0; // reset lock

    _state = _state.copyWith(
      apelaciones: newAppeals,
      fallosPorNivel: updatedFailures,
      ultimoGastoApelacion: _state.ultimoGastoApelacion ?? DateTime.now(),
    );
    await _saveState();
    notifyListeners();
    return true;
  }

  @override
  void dispose() {
    _regenTimer?.cancel();
    super.dispose();
  }
}
