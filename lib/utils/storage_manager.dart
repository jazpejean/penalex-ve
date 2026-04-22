import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/calculation_model.dart';

class StorageManager {
  static const String _calculationsKey = 'saved_calculations_v1';

  Future<List<CalculationModel>> getSavedCalculations() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> calculationsJson = prefs.getStringList(_calculationsKey) ?? <String>[];

      final List<CalculationModel> calculations = calculationsJson.map((String jsonString) {
        try {
          final Map<String, dynamic> map = jsonDecode(jsonString) as Map<String, dynamic>;
          return CalculationModel.fromMap(map);
        } on Exception catch (_) {
          return null;
        }
      }).whereType<CalculationModel>().toList();

      calculations.sort((CalculationModel a, CalculationModel b) => b.fecha.compareTo(a.fecha));
      return calculations;
    } on Exception catch (_) {
      return <CalculationModel>[];
    }
  }

  Future<void> saveCalculation(CalculationModel calculation) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<CalculationModel> existingCalculations = await getSavedCalculations();

      if (existingCalculations.length >= 50) {
        existingCalculations.removeLast();
      }

      existingCalculations.insert(0, calculation);

      final List<String> calculationsJson = existingCalculations
          .map((CalculationModel calc) => jsonEncode(calc.toMap()))
          .toList();

      await prefs.setStringList(_calculationsKey, calculationsJson);
    } on Exception catch (e) {
      throw Exception('Error al guardar el cálculo: $e');
    }
  }

  Future<void> deleteCalculation(String id) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<CalculationModel> existingCalculations = await getSavedCalculations();

      final List<CalculationModel> updatedCalculations = existingCalculations
          .where((CalculationModel calc) => calc.id != id)
          .toList();

      final List<String> calculationsJson = updatedCalculations
          .map((CalculationModel calc) => jsonEncode(calc.toMap()))
          .toList();

      await prefs.setStringList(_calculationsKey, calculationsJson);
    } on Exception catch (e) {
      throw Exception('Error al eliminar el cálculo: $e');
    }
  }

  Future<void> clearAllCalculations() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_calculationsKey);
    } on Exception catch (e) {
      throw Exception('Error al vaciar cálculos: $e');
    }
  }
}