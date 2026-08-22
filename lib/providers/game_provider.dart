import 'package:flutter/foundation.dart';
import '../models/question.dart';
import '../models/user.dart';
import '../models/user_progress.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../data/venezuela_regions.dart';

class GameState extends ChangeNotifier {
  int _currentLevel = 1;
  int _apelaciones = 5;
  int _score = 0;
  int _streak = 0;
  bool _isLoading = false;
  DateTime? _lastApelacionRegeneration;
  Question? _currentQuestion;

  int get currentLevel => _currentLevel;
  int get apelaciones => _apelaciones;
  int get apelacionesDisponibles => _apelaciones; // Alias para compatibilidad
  int get score => _score;
  int get xp => _score; // Alias para compatibilidad
  int get xpToNextLevel => 100; // XP necesario para siguiente nivel
  int get streak => _streak;
  bool get isLoading => _isLoading;
  DateTime? get lastApelacionRegeneration => _lastApelacionRegeneration;
  Question? get currentQuestion => _currentQuestion;

  void setCurrentQuestion(Question? question) {
    _currentQuestion = question;
    notifyListeners();
  }

  void setLoading({required bool loading}) {
    _isLoading = loading;
    notifyListeners();
  }

  DateTime _calculateApelacionesFullTime() {
    final DateTime now = DateTime.now();
    if (_apelaciones >= 5) return now;
    final DateTime lastRegen = _lastApelacionRegeneration ?? now;
    final DateTime baseTime = lastRegen.isBefore(now.subtract(Duration(minutes: 30 * (5 - _apelaciones)))) ? now : lastRegen;
    final int missingApelaciones = 5 - _apelaciones;
    final Duration duration = Duration(minutes: 30 * missingApelaciones);
    return baseTime.add(duration);
  }

  Future<void> _scheduleApelacionesNotificationIfNeeded() async {
    final NotificationService notificationService = NotificationService();
    await notificationService.cancelLivesReminder();
    if (_apelaciones < 5) {
      final DateTime targetTime = _calculateApelacionesFullTime();
      if (targetTime.isAfter(DateTime.now())) {
        await notificationService.scheduleLivesFullReminder(scheduledTime: targetTime);
      }
    }
  }

  Future<void> loadGameState() async {
    setLoading(loading: true);
    final UserModel? user = await FirestoreService.loadUser();
    final UserProgress? progress = await FirestoreService.loadUserProgress();
    if (user != null) {
      _currentLevel = user.nivelActual;
      _score = user.puntosTotales;
    }
    if (progress != null) {
      _apelaciones = progress.apelaciones;
      _lastApelacionRegeneration = progress.ultimaRegeneracion;
    }
    setLoading(loading: false);
    await _scheduleApelacionesNotificationIfNeeded();
  }

  void startNewGame() {
    _currentLevel = 1;
    _apelaciones = 5;
    _score = 0;
    _streak = 0;
    _lastApelacionRegeneration = null;
    notifyListeners();
    NotificationService().cancelLivesReminder();
  }

  void answerCorrect() {
    final int newStreak = _streak + 1;
    final int totalPoints = 10 + (newStreak >= 3 ? 5 : 0);
    _score += totalPoints;
    _streak = newStreak;
    final int newLevel = 1 + (_score ~/ 10);
    if (newLevel > _currentLevel) _currentLevel = newLevel;
    notifyListeners();
  }

  /// Completa el nivel actual y avanza al siguiente
  void completeLevel() {
    _currentLevel++;
    _score += 100;
    _streak++;
    notifyListeners();
  }

  void answerWrong() {
    _apelaciones--;
    _streak = 0;
    notifyListeners();
    _scheduleApelacionesNotificationIfNeeded();
  }

  void timeUp() => answerWrong();

  void regenerateApelacion() {
    if (_apelaciones < 5) {
      _apelaciones++;
      _lastApelacionRegeneration = DateTime.now();
      notifyListeners();
      _scheduleApelacionesNotificationIfNeeded();
    } else {
      NotificationService().cancelLivesReminder();
    }
  }

  Future<void> saveProgress() async {
    final UserModel user = UserModel(
      uid: '',
      nombre: '',
      nivelActual: _currentLevel,
      puntosTotales: _score,
      rangoActual: getRankForLevel(_currentLevel),
      fechaRegistro: DateTime.now(),
    );
    await FirestoreService.saveUser(user);
    final UserProgress progress = UserProgress(
      apelaciones: _apelaciones, 
      ultimaRegeneracion: _lastApelacionRegeneration ?? DateTime.now(),
    );
    await FirestoreService.saveUserProgress(progress);
  }

  String getRankForLevel(int level) {
    if (level >= 3000) return 'Presidente Emérito';
    if (level >= 2800) return 'Presidente del Tribunal Supremo de Justicia';
    if (level >= 2600) return 'Presidente de la Sala de Casación Penal';
    if (level >= 2400) return 'Vicepresidente de la Sala de Casación Penal';
    if (level >= 2200) return 'Magistrado Principal de la Sala de Casación Penal';
    if (level >= 2000) return 'Secretario de la Sala de Casación Penal';
    if (level >= 1800) return 'Magistrado Suplente de la Sala de Casación Penal';
    if (level >= 1600) return 'Juez Presidente del Circuito Judicial Penal';
    if (level >= 1400) return 'Juez Titular de Corte de Apelaciones';
    if (level >= 1200) return 'Juez Provisorio de Corte de Apelaciones';
    if (level >= 1050) return 'Juez de Primera Instancia con Competencia Nacional';
    if (level >= 900) return 'Juez de Primera Instancia con Competencia Especial';
    if (level >= 750) return 'Juez Titular de Primera Instancia';
    if (level >= 600) return 'Juez Provisorio de Primera Instancia';
    if (level >= 450) return 'Juez Suplente de Primera Instancia';
    if (level >= 300) return 'Juez Accidental de Primera Instancia';
    if (level >= 200) return 'Juez Titular de Municipio';
    if (level >= 130) return 'Juez Provisorio de Municipio';
    if (level >= 70) return 'Juez Suplente de Municipio';
    if (level >= 30) return 'Juez Accidental de Municipio';
    if (level >= 15) return 'Secretario de Tribunal de Primera Instancia';
    if (level >= 8) return 'Secretario de Tribunal de Municipio';
    if (level >= 4) return 'Escribiente';
    if (level >= 2) return 'Asistente Jurídico';
    return 'Alguacil de Sala';
  }

  /// Obtener la región actual de Venezuela según el nivel
  RegionVenezuela? getCurrentRegion() {
    return getRegionForLevel(_currentLevel);
  }
}