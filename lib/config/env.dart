import 'package:flutter_dotenv/flutter_dotenv.dart';

// ignore: avoid_classes_with_only_static_members
class Env {
  static String get apiKey => dotenv.env['API_KEY'] ?? '';
  static String get baseUrl => dotenv.env['BASE_URL']?.trim() ?? '';
  
  static Future<void> init() async {
    await dotenv.load();
  }
}