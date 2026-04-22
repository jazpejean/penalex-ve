import 'package:flutter/foundation.dart';

import '../models/certificate.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class UserState extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  final List<Certificate> _certificates = <Certificate>[];

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Certificate> get certificates => _certificates;

  void setLoading({required bool loading}) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  Future<void> loadUserData() async {
    setLoading(loading: true);
    setError(null);
    try {
      final UserModel? user = await FirestoreService.loadUser();
      _user = user;
      setLoading(loading: false);
    } on Exception catch (e) {
      _error = e.toString();
      setLoading(loading: false);
    }
  }

  Future<void> signInAnonymously() async {
    setLoading(loading: true);
    setError(null);
    try {
      await AuthService().signInAnonymously();
    } on Exception catch (e) {
      _error = e.toString();
      setLoading(loading: false);
    }
  }

  void updateUserName(String name) {
    if (_user != null) {
      _user = _user!.copyWith(nombre: name);
      notifyListeners();
      FirestoreService.saveUser(_user!);
    }
  }

  void updateRank(String rank) {
    if (_user != null) {
      _user = _user!.copyWith(rangoActual: rank);
      notifyListeners();
      FirestoreService.saveUser(_user!);
    }
  }

  Future<void> saveProgress(int nivelActual, int puntuacion, {int racha = 0, int correctas = 0, int respondidas = 0}) async {
    final UserModel? currentUser = _user;
    if (currentUser == null) return;

    final UserModel updatedUser = currentUser.copyWith(
      nivelActual: nivelActual,
      puntosTotales: puntuacion,
      puntuacionMaxima: puntuacion > currentUser.puntuacionMaxima ? puntuacion : currentUser.puntuacionMaxima,
      rachaMaxima: racha > currentUser.rachaMaxima ? racha : currentUser.rachaMaxima,
      preguntasCorrectas: currentUser.preguntasCorrectas + correctas,
      preguntasRespondidas: currentUser.preguntasRespondidas + respondidas,
    );
    _user = updatedUser;
    notifyListeners();
    await FirestoreService.saveUser(updatedUser);
  }

  void setUser(UserModel? user) {
    _user = user;
    notifyListeners();
  }
}