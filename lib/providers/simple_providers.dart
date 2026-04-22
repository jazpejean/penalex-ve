import 'package:flutter/foundation.dart';

class GameLevelProvider extends ChangeNotifier {
  int _value = 1;
  int get value => _value;
  void setValue(int newValue) {
    _value = newValue;
    notifyListeners();
  }
}

class GameLivesProvider extends ChangeNotifier {
  int _value = 5;
  int get value => _value;
  void setValue(int newValue) {
    _value = newValue;
    notifyListeners();
  }
}

class GameScoreProvider extends ChangeNotifier {
  int _value = 0;
  int get value => _value;
  void setValue(int newValue) {
    _value = newValue;
    notifyListeners();
  }
}

class GameStreakProvider extends ChangeNotifier {
  int _value = 0;
  int get value => _value;
  void setValue(int newValue) {
    _value = newValue;
    notifyListeners();
  }
}

class UserDataProvider extends ChangeNotifier {
  Map<String, dynamic> _data = <String, dynamic>{};
  Map<String, dynamic> get data => _data;
  void setData(Map<String, dynamic> newData) {
    _data = newData;
    notifyListeners();
  }
}