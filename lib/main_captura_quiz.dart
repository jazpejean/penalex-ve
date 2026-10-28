// TEMP-CAPTURA-QUIZ: entrada temporal para capturar el lobby rediseñado
// en Linux desktop (el dispositivo USB está en modo MIDI). NO forma parte
// del flujo normal de la app. Se elimina tras la verificación visual.
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'pages/quiz_lobby_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: dotenv.env['FIREBASE_API_KEY_ANDROID'] ?? '',
      appId: dotenv.env['FIREBASE_APP_ID_ANDROID'] ?? '',
      messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
      projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? '',
      storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '',
    ),
  );
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  runApp(const CapturaQuizApp());
}

class CapturaQuizApp extends StatelessWidget {
  const CapturaQuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Captura Quiz',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Rubik',
        textTheme: GoogleFonts.rubikTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFF7F6FF),
      ),
      home: const QuizLobbyScreen(),
    );
  }
}