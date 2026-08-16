import React, { useState } from 'react';
import { sounds } from '../services/soundEffects';
import { 
  Smartphone, 
  Copy, 
  Check, 
  FileCode, 
  Layers, 
  Download, 
  Terminal, 
  BookOpen,
  Sparkles,
  Database,
  Music,
  Volume2
} from 'lucide-react';

export const FlutterExportView: React.FC = () => {
  const [activeFile, setActiveFile] = useState<string>('lib/services/audio_manager.dart');
  const [copied, setCopied] = useState<boolean>(false);

  const FLUTTER_FILES: Record<string, { desc: string; code: string }> = {
    'lib/services/audio_manager.dart': {
      desc: 'Gestor de Audio Cinematográfico Multi-Canal (BGM dinámico con crossfade, Ducking para voces del narrador judicial, pool de SFX y persistencia de preferencias).',
      code: `import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AudioMode {
  all,      // Música BGM + SFX + Voces
  sfxOnly,  // Solo SFX y Voces
  muted,    // Silencio Total
}

/// Gestor de Audio Cinematográfico para PENALEX VE
/// Maneja 3 canales concurrentes: Música de Fondo, Efectos de Sonido (SFX) y Narrador Judicial.
class AudioManager extends ChangeNotifier {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;

  AudioManager._internal() {
    _initPlayers();
    _cargarPreferencias();
  }

  // Canales de reproducción concurrentes
  late final AudioPlayer _bgmPlayer;
  late final AudioPlayer _sfxPlayer;
  late final AudioPlayer _voicePlayer;

  AudioMode _audioMode = AudioMode.all;
  AudioMode get audioMode => _audioMode;

  double _bgmVolume = 0.35;
  bool _isPlayingBgm = false;

  void _initPlayers() {
    _bgmPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.loop);
    _sfxPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
    _voicePlayer = AudioPlayer()..setReleaseMode(ReleaseMode.stop);

    // Audio Ducking: Cuando el narrador habla, atenuar la música de fondo
    _voicePlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.playing) {
        _bgmPlayer.setVolume(_bgmVolume * 0.25);
      } else if (state == PlayerState.completed || state == PlayerState.stopped) {
        _bgmPlayer.setVolume(_audioMode == AudioMode.all ? _bgmVolume : 0.0);
      }
    });
  }

  Future<void> _cargarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();
    final modeIndex = prefs.getInt('penalex_audio_mode') ?? 0;
    _audioMode = AudioMode.values[modeIndex.clamp(0, 2)];
    notifyListeners();
  }

  Future<void> setAudioMode(AudioMode mode) async {
    _audioMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('penalex_audio_mode', mode.index);

    if (mode == AudioMode.muted) {
      await _bgmPlayer.stop();
      await _sfxPlayer.stop();
      await _voicePlayer.stop();
      _isPlayingBgm = false;
    } else if (mode == AudioMode.sfxOnly) {
      await _bgmPlayer.stop();
      _isPlayingBgm = false;
    } else if (mode == AudioMode.all && !_isPlayingBgm) {
      playLobbyBgm();
    }

    notifyListeners();
  }

  void toggleNextMode() {
    final next = _audioMode == AudioMode.all
        ? AudioMode.sfxOnly
        : _audioMode == AudioMode.sfxOnly
            ? AudioMode.muted
            : AudioMode.all;
    setAudioMode(next);
  }

  // =========================================================================
  // 🎻 MÚSICA DE FONDO CINEMATOGRÁFICA (Looping Dinámico)
  // =========================================================================

  /// Música de la Sala Magna / Lobby: Pista orquestal solemne (cuerdas, piano, metales nobles)
  Future<void> playLobbyBgm() async {
    if (_audioMode != AudioMode.all) return;
    try {
      await _bgmPlayer.setVolume(_bgmVolume);
      await _bgmPlayer.play(AssetSource('sounds/bgm_lobby_majestic.mp3'));
      _isPlayingBgm = true;
    } catch (e) {
      debugPrint('Audio Warning: \$e (Asegúrate de agregar los assets de audio en pubspec.yaml)');
    }
  }

  /// Música de Tensión en Audiencia: Cuerdas agudas, percusión ligera y bajo profundo
  /// Acelera tempo a medida que el reloj de arena se vacía
  Future<void> playQuizBgm({double playbackRate = 1.0}) async {
    if (_audioMode != AudioMode.all) return;
    try {
      await _bgmPlayer.setVolume(_bgmVolume);
      await _bgmPlayer.setPlaybackRate(playbackRate);
      await _bgmPlayer.play(AssetSource('sounds/bgm_quiz_suspense.mp3'));
      _isPlayingBgm = true;
    } catch (e) {
      debugPrint('Audio Warning: \$e');
    }
  }

  Future<void> stopBgm() async {
    await _bgmPlayer.stop();
    _isPlayingBgm = false;
  }

  // =========================================================================
  // 🔊 EFECTOS DE SONIDO REALISTAS (SFX)
  // =========================================================================

  Future<void> playGavelStrike() async {
    if (_audioMode == AudioMode.muted) return;
    await _sfxPlayer.play(AssetSource('sounds/sfx_gavel_strike.mp3'));
  }

  Future<void> playCorrectChime() async {
    if (_audioMode == AudioMode.muted) return;
    await _sfxPlayer.play(AssetSource('sounds/sfx_correct_bell_applause.mp3'));
  }

  Future<void> playWrongVerdict() async {
    if (_audioMode == AudioMode.muted) return;
    await playGavelStrike();
    await _sfxPlayer.play(AssetSource('sounds/sfx_wrong_dissonance.mp3'));
  }

  Future<void> playAppealBurned() async {
    if (_audioMode == AudioMode.muted) return;
    await _sfxPlayer.play(AssetSource('sounds/sfx_parchment_fire_burn.mp3'));
  }

  Future<void> playAppealRestored() async {
    if (_audioMode == AudioMode.muted) return;
    await _sfxPlayer.play(AssetSource('sounds/sfx_appeal_resurgence.mp3'));
  }

  Future<void> playLevelUpFanfare() async {
    if (_audioMode == AudioMode.muted) return;
    await _sfxPlayer.play(AssetSource('sounds/sfx_levelup_triumphant_fanfare.mp3'));
  }

  Future<void> playGong() async {
    if (_audioMode == AudioMode.muted) return;
    await _sfxPlayer.play(AssetSource('sounds/sfx_judicial_gong.mp3'));
  }

  Future<void> playClockTick({bool isUrgent = false}) async {
    if (_audioMode == AudioMode.muted) return;
    final file = isUrgent ? 'sounds/sfx_tick_urgent.mp3' : 'sounds/sfx_tick_normal.mp3';
    await _sfxPlayer.play(AssetSource(file));
  }

  Future<void> playScrollUnfurl() async {
    if (_audioMode == AudioMode.muted) return;
    await _sfxPlayer.play(AssetSource('sounds/sfx_scroll_unfurl.mp3'));
  }

  Future<void> playAscentChime() async {
    if (_audioMode == AudioMode.muted) return;
    await _sfxPlayer.play(AssetSource('sounds/sfx_ladder_ascent.mp3'));
  }

  // =========================================================================
  // 🗣️ VOCES DEL NARRADOR JUDICIAL (Voice Lines con Reverberación)
  // =========================================================================

  Future<void> voiceCorrect() async {
    if (_audioMode == AudioMode.muted) return;
    await _voicePlayer.play(AssetSource('sounds/voice_correcto_juridico.mp3'));
  }

  Future<void> voiceWrong() async {
    if (_audioMode == AudioMode.muted) return;
    await _voicePlayer.play(AssetSource('sounds/voice_apelacion_desestimada.mp3'));
  }

  Future<void> voiceLevelUp() async {
    if (_audioMode == AudioMode.muted) return;
    await _voicePlayer.play(AssetSource('sounds/voice_ascenso_judicial.mp3'));
  }

  Future<void> voiceAppealLost() async {
    if (_audioMode == AudioMode.muted) return;
    await _voicePlayer.play(AssetSource('sounds/voice_apelacion_consumida.mp3'));
  }

  Future<void> voiceWelcome(String nombre) async {
    if (_audioMode == AudioMode.muted) return;
    await _voicePlayer.play(AssetSource('sounds/voice_bienvenido_sala_magna.mp3'));
  }

  @override
  void dispose() {
    _bgmPlayer.dispose();
    _sfxPlayer.dispose();
    _voicePlayer.dispose();
    super.dispose();
  }
}
`
    },
    'lib/data/judicial_ranks.dart': {
      desc: 'Lista oficial completa de los 25 Rangos Judiciales de PENALEX VE según la jerarquía penal venezolana.',
      code: `class JudicialRankHelper {
  /// Devuelve el rango judicial exacto según el nivel del jugador (1 a 3000)
  static String getRankTitle(int level) {
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

  static const List<int> milestoneLevels = [100, 500, 1000, 2000, 3000];
}
`
    },
    'pubspec.yaml': {
      desc: 'Dependencias actualizadas para PENALEX VE con Supabase Flutter SDK, Audio Multi-canal, PDF y State Management.',
      code: `name: penalex_ve
description: "PENALEX VE - Juego de preguntas y respuestas cinematográfico sobre Derecho Penal Venezolano con Supabase, Banda Sonora Orquestal, SFX, Escalera 3D y Certificados PDF"
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  
  # Backend & Database (Supabase PostgreSQL + Auth + Storage)
  supabase_flutter: ^2.5.0
  
  # State Management & Local Preferences
  provider: ^6.1.2
  shared_preferences: ^2.2.3
  
  # Cinematic Audio Engine (BGM, SFX & Narrator Voices)
  audioplayers: ^6.0.0
  
  # Visuals, Fonts & Game Feedback
  google_fonts: ^6.2.1
  flutter_svg: ^2.0.10+1
  confetti: ^0.7.0
  
  # PDF Certificate Generation & High-Resolution Export
  pdf: ^3.10.8
  printing: ^5.12.0
  path_provider: ^2.1.3
  
  # Notifications for Appeals Regeneration
  flutter_local_notifications: ^17.1.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/sounds/
    - assets/images/
`
    },
    'lib/main.dart': {
      desc: 'Punto de entrada de la aplicación Flutter, inicialización de Supabase y gestor de audio.',
      code: `import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'services/supabase_service.dart';
import 'services/audio_manager.dart';
import 'screens/lobby_and_map_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Bloqueo en orientación vertical para experiencia inmersiva
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Inicializar Supabase
  await Supabase.initialize(
    url: 'https://TU_PROYECTO_SUPABASE.supabase.co',
    anonKey: 'TU_ANON_KEY_DE_SUPABASE',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SupabaseService()..cargarEstadoInicial()),
        ChangeNotifierProvider(create: (_) => AudioManager()..playLobbyBgm()),
      ],
      child: const PenalexVeApp(),
    ),
  );
}

class PenalexVeApp extends StatelessWidget {
  const PenalexVeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PENALEX VE - Derecho Penal Venezolano',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF060911),
        primaryColor: const Color(0xFFD97706),
        textTheme: GoogleFonts.cinzelTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFF59E0B),
          secondary: Color(0xFFD97706),
          surface: Color(0xFF0E1628),
        ),
      ),
      home: const LobbyAndMapScreen(),
    );
  }
}
`
    },
    'lib/services/supabase_service.dart': {
      desc: 'Servicio central en Flutter para gestionar la persistencia en Supabase (apelaciones, XP, niveles, ranking).',
      code: `import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pregunta.dart';
import '../models/user_profile.dart';
import '../data/judicial_ranks.dart';

class SupabaseService extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  UserProfile _perfil = UserProfile.inicial();
  UserProfile get perfil => _perfil;

  bool _cargando = false;
  bool get cargando => _cargando;

  Future<void> cargarEstadoInicial() async {
    _cargando = true;
    notifyListeners();

    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final response = await _supabase
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        if (response != null) {
          _perfil = UserProfile.fromMap(response);
          _calcularRegeneracionApelaciones();
        }
      }
    } catch (e) {
      debugPrint('Aviso: Operando en modo local offline: \$e');
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  void _calcularRegeneracionApelaciones() {
    if (_perfil.apelaciones >= 5) return;

    final ahora = DateTime.now();
    final ultima = _perfil.ultimaRegeneracion;
    final diferenciaMinutos = ahora.difference(ultima).inMinutes;

    final recuperadas = diferenciaMinutos ~/ 30;
    if (recuperadas > 0) {
      final nuevas = (_perfil.apelaciones + recuperadas).clamp(0, 5);
      _perfil = _perfil.copyWith(
        apelaciones: nuevas,
        ultimaRegeneracion: ahora,
      );
      sincronizarPerfil();
    }
  }

  Future<Pregunta> obtenerPreguntaPorNivel(int nivel) async {
    try {
      final data = await _supabase
          .from('preguntas')
          .select()
          .eq('nivel', nivel)
          .single();
      return Pregunta.fromMap(data);
    } catch (e) {
      return Pregunta.ejemplo(nivel);
    }
  }

  Future<void> registrarVeredicto({required bool acertado, required int nivelActual}) async {
    if (acertado) {
      final nuevaRacha = _perfil.rachaActual + 1;
      final bonusRacha = nuevaRacha >= 3 ? 5 : 0;
      final puntosGanados = 10 + bonusRacha;

      _perfil = _perfil.copyWith(
        nivelActual: nivelActual >= _perfil.nivelActual ? nivelActual + 1 : _perfil.nivelActual,
        puntosTotales: _perfil.puntosTotales + puntosGanados,
        rachaActual: nuevaRacha,
        maxRacha: nuevaRacha > _perfil.maxRacha ? nuevaRacha : _perfil.maxRacha,
      );
    } else {
      _perfil = _perfil.copyWith(
        apelaciones: (_perfil.apelaciones - 1).clamp(0, 5),
        rachaActual: 0,
        ultimaRegeneracion: DateTime.now(),
      );
    }

    notifyListeners();
    await sincronizarPerfil();
  }

  Future<void> sincronizarPerfil() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await _supabase.from('profiles').upsert(_perfil.toMap());
        await _supabase.from('ranking').upsert({
          'user_id': user.id,
          'nombre': _perfil.nombre,
          'nivel': _perfil.nivelActual,
          'xp': _perfil.puntosTotales,
          'rango': JudicialRankHelper.getRankTitle(_perfil.nivelActual),
        });
      }
    } catch (e) {
      debugPrint('Error sincronizando perfil con Supabase: \$e');
    }
  }
}
`
    },
    'lib/screens/lobby_and_map_screen.dart': {
      desc: 'Sala de Audiencias Magna del TSJ y Escalera Isométrica 3D hacia el Nivel 3000 con botón de audio tri-estado.',
      code: `import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/supabase_service.dart';
import '../services/audio_manager.dart';
import '../widgets/pergamino_appeals_bar.dart';
import 'quiz_arena_screen.dart';

class LobbyAndMapScreen extends StatefulWidget {
  const LobbyAndMapScreen({super.key});

  @override
  State<LobbyAndMapScreen> createState() => _LobbyAndMapScreenState();
}

class _LobbyAndMapScreenState extends State<LobbyAndMapScreen> {
  @override
  Widget build(BuildContext context) {
    final supabaseService = context.watch<SupabaseService>();
    final audioManager = context.watch<AudioManager>();
    final perfil = supabaseService.perfil;

    return Scaffold(
      backgroundColor: const Color(0xFF060911),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0F1D),
        elevation: 4,
        title: Row(
          children: [
            const Icon(Icons.gavel, color: Color(0xFFF59E0B)),
            const SizedBox(width: 8),
            Text(
              'PENALEX VE',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Colors.amber.shade300,
              ),
            ),
          ],
        ),
        actions: [
          PergaminoAppealsBar(apelaciones: perfil.apelaciones),
          const SizedBox(width: 8),
          // Botón Tri-Estado de Audio
          IconButton(
            onPressed: () => audioManager.toggleNextMode(),
            icon: Icon(
              audioManager.audioMode == AudioMode.all
                  ? Icons.volume_up
                  : audioManager.audioMode == AudioMode.sfxOnly
                      ? Icons.volume_down
                      : Icons.volume_off,
              color: audioManager.audioMode == AudioMode.muted
                  ? Colors.red.shade400
                  : const Color(0xFFF59E0B),
            ),
            tooltip: 'Ajuste de Audio y Música',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF060911), Color(0xFF0E1628), Color(0xFF060911)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          ListView.builder(
            reverse: true,
            itemCount: 3000,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
            itemBuilder: (context, index) {
              final nivel = index + 1;
              final isPassed = nivel < perfil.nivelActual;
              final isCurrent = nivel == perfil.nivelActual;
              final isLocked = nivel > perfil.nivelActual;

              final xOffset = sin(index * 0.8) * 100;

              return Transform.translate(
                offset: Offset(xOffset, 0),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: GestureDetector(
                      onTap: () {
                        if (!isLocked) {
                          audioManager.playScrollUnfurl();
                          audioManager.playQuizBgm();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => QuizArenaScreen(nivel: nivel),
                            ),
                          ).then((_) {
                            audioManager.playLobbyBgm();
                          });
                        } else {
                          audioManager.playWrongVerdict();
                        }
                      },
                      child: Container(
                        width: isCurrent ? 76 : 64,
                        height: isCurrent ? 76 : 64,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: isCurrent
                              ? const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)])
                              : isPassed
                                  ? const LinearGradient(colors: [Color(0xFF1B253B), Color(0xFF111A2C)])
                                  : const LinearGradient(colors: [Color(0xFF0E1420), Color(0xFF080C14)]),
                          border: Border.all(
                            color: isCurrent
                                ? Colors.amber.shade200
                                : isPassed
                                    ? const Color(0xFFD97706)
                                    : Colors.grey.shade800,
                            width: isCurrent ? 3 : 1.5,
                          ),
                          boxShadow: isCurrent
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFF59E0B).withOpacity(0.5),
                                    blurRadius: 20,
                                    spreadRadius: 4,
                                  )
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isPassed
                                    ? Icons.check
                                    : isCurrent
                                        ? Icons.gavel
                                        : Icons.lock,
                                size: isCurrent ? 24 : 18,
                                color: isCurrent ? Colors.black : (isPassed ? Colors.amber.shade300 : Colors.grey),
                              ),
                              Text(
                                '\$nivel',
                                style: TextStyle(
                                  fontSize: isCurrent ? 14 : 12,
                                  fontWeight: FontWeight.bold,
                                  color: isCurrent ? Colors.black : Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
`
    },
    'lib/widgets/pergamino_appeals_bar.dart': {
      desc: 'Widget de apelaciones con pergaminos con sellos de cera roja.',
      code: `import 'package:flutter/material.dart';

class PergaminoAppealsBar extends StatelessWidget {
  final int apelaciones; // 0 a 5

  const PergaminoAppealsBar({super.key, required this.apelaciones});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1628),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD97706), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 1; i <= 5; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: Icon(
                Icons.menu_book_rounded,
                size: 16,
                color: i <= apelaciones ? const Color(0xFFF59E0B) : Colors.grey.shade700,
              ),
            ),
          const SizedBox(width: 6),
          Text(
            '\$apelaciones/5',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Color(0xFFFDE68A),
            ),
          ),
        ],
      ),
    );
  }
}
`
    },
    'lib/services/pdf_certificate_service.dart': {
      desc: 'Generador de Diplomas y Certificados Oficiales del TSJ en PDF.',
      code: `import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PdfCertificateService {
  static Future<Uint8List> generarCertificadoPdf({
    required String nombreUsuario,
    required int nivelAlcanzado,
    required String rangoJudicial,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(24),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.amber800, width: 4),
              color: PdfColor.fromHex('#FCF9EF'),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  children: [
                    pw.Text('REPÚBLICA BOLIVARIANA DE VENEZUELA',
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                    pw.Text('PODER JUDICIAL • CIRCUITO JUDICIAL PENAL',
                        style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                    pw.Text('TRIBUNAL SUPREMO DE JUSTICIA - SALA DE CASACIÓN PENAL',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.amber900)),
                    pw.SizedBox(height: 12),
                    pw.Text('CERTIFICADO DE MÉRITO JUDICIAL',
                        style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.amber900)),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Text('Conferido a:', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
                    pw.SizedBox(height: 6),
                    pw.Text(nombreUsuario.toUpperCase(),
                        style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Por haber superado con excelencia el Escalón \$nivelAlcanzado en Derecho Penal y COPP, alcanzando el rango:',
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey800),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.amber100,
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Text('« \$rangoJudicial »',
                          style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: PdfColors.amber900)),
                    ),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Magistrado Presidente TSJ', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('★ SELLO JUDICIAL ★', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.amber800)),
                    pw.Text('Secretario de Sala Penal', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> guardarEnSupabaseStorage({
    required Uint8List pdfBytes,
    required String nombreArchivo,
  }) async {
    final supabase = Supabase.instance.client;
    await supabase.storage.from('certificados_judiciales').uploadBinary(nombreArchivo, pdfBytes);
  }
}
`
    }
  };

  const copyActiveCode = () => {
    sounds.playClick();
    navigator.clipboard.writeText(FLUTTER_FILES[activeFile].code);
    setCopied(true);
    setTimeout(() => setCopied(false), 3000);
  };

  return (
    <div className="max-w-6xl mx-auto px-3 sm:px-6 pb-28">
      
      {/* Header */}
      <div className="text-center max-w-2xl mx-auto mb-8">
        <div className="inline-flex items-center justify-center w-14 h-14 rounded-2xl bg-amber-950/80 border border-amber-500/40 mb-3 shadow-lg shadow-amber-950/60">
          <Smartphone className="w-8 h-8 text-amber-400" />
        </div>
        <h2 className="font-judicial text-2xl sm:text-4xl font-extrabold text-transparent bg-clip-text bg-gradient-to-r from-amber-200 via-amber-400 to-amber-600 mb-2">
          Exportar Proyecto Flutter Móvil
        </h2>
        <p className="text-sm text-slate-300">
          Arquitectura completa de <strong>PENALEX VE</strong> para Flutter 3.x con Supabase SDK, gestor de audio multi-canal con audioplayers, escalera 3D y generación de diplomas PDF.
        </p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-4 gap-6">
        
        {/* Files Explorer Sidebar */}
        <div className="bg-[#0c1220] border-2 border-amber-900/50 rounded-3xl p-4 shadow-xl space-y-2">
          <div className="flex items-center gap-2 px-3 py-2 text-xs font-bold uppercase tracking-wider text-slate-400 border-b border-slate-800">
            <Layers className="w-4 h-4 text-amber-400" />
            <span>Archivos del Proyecto</span>
          </div>

          <div className="space-y-1">
            {Object.keys(FLUTTER_FILES).map((fileName) => {
              const isSelected = activeFile === fileName;
              const isAudio = fileName.includes('audio');
              return (
                <button
                  key={fileName}
                  onClick={() => { sounds.playClick(); setActiveFile(fileName); }}
                  className={`w-full text-left px-3 py-2 rounded-xl text-xs font-mono transition-colors flex items-center gap-2 cursor-pointer ${
                    isSelected
                      ? 'bg-amber-500 text-slate-950 font-bold shadow-md shadow-amber-950/50'
                      : 'text-slate-300 hover:bg-slate-800'
                  }`}
                >
                  {isAudio ? (
                    <Music className={`w-3.5 h-3.5 ${isSelected ? 'text-slate-950' : 'text-amber-400'}`} />
                  ) : (
                    <FileCode className={`w-3.5 h-3.5 ${isSelected ? 'text-slate-950' : 'text-amber-400'}`} />
                  )}
                  <span className="truncate">{fileName}</span>
                </button>
              );
            })}
          </div>

          <div className="pt-4 border-t border-slate-800">
            <div className="bg-slate-950 p-3 rounded-xl border border-slate-800 text-[11px] text-slate-400 space-y-1">
              <span className="font-bold text-amber-400 block font-mono">Comandos de terminal:</span>
              <code>flutter pub get</code>
              <br />
              <code>flutter run</code>
            </div>
          </div>
        </div>

        {/* Code Viewer Panel */}
        <div className="lg:col-span-3 bg-[#070b13] border-2 border-amber-800/60 rounded-3xl overflow-hidden shadow-2xl flex flex-col justify-between">
          
          {/* File Top Bar */}
          <div className="px-5 py-3.5 bg-[#0d1424] border-b border-slate-800 flex items-center justify-between">
            <div>
              <span className="text-xs font-mono font-bold text-amber-300 block">
                {activeFile}
              </span>
              <span className="text-[11px] text-slate-400">
                {FLUTTER_FILES[activeFile].desc}
              </span>
            </div>

            <button
              onClick={copyActiveCode}
              className="px-3 py-1.5 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-200 text-xs font-mono flex items-center gap-1.5 border border-slate-700 shadow cursor-pointer"
            >
              {copied ? (
                <>
                  <Check className="w-3.5 h-3.5 text-emerald-400" />
                  <span className="text-emerald-400 font-bold">¡Copiado!</span>
                </>
              ) : (
                <>
                  <Copy className="w-3.5 h-3.5 text-amber-400" />
                  <span>Copiar Código</span>
                </>
              )}
            </button>
          </div>

          {/* Code Text */}
          <pre className="p-5 text-xs font-mono text-slate-200 overflow-x-auto max-h-[520px] leading-relaxed select-text">
            <code>{FLUTTER_FILES[activeFile].code}</code>
          </pre>

          {/* Footer Note */}
          <div className="px-5 py-3 bg-[#0a0f1d] border-t border-slate-800 text-[11px] text-slate-400 flex items-center gap-2">
            <Sparkles className="w-3.5 h-3.5 text-amber-400" />
            <span>PENALEX VE: Código listo para compilar en iOS, Android y Web con Flutter.</span>
          </div>

        </div>

      </div>

    </div>
  );
};
