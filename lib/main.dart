import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/theme.dart';
import 'config/app_theme.dart';
import 'models/delito.dart';
import 'pages/agenda_screen.dart';
import 'pages/admin_glosario_screen.dart';
import 'pages/admin_ia_config_screen.dart';
import 'pages/admin_users_screen.dart';
import 'pages/asistente_legal_screen.dart';
import 'pages/asistente_legal_hub_screen.dart';
import 'pages/mapa_tribunales_screen.dart';
import 'pages/redactor_documentos_screen.dart';
import 'pages/busqueda_semantica_screen.dart';
import 'pages/calculos_guardados_page.dart';
import 'pages/chat_legal_screen.dart';
import 'pages/computo_page.dart';
import 'pages/dashboard_screen.dart';
import 'pages/dosimetria_page.dart';

import 'pages/glosario_screen.dart';
import 'pages/main_screen.dart';
import 'pages/login_page.dart'; // FIREBASE LOGIN
import 'pages/splash_screen.dart';
import 'pages/quiz_lobby_screen.dart';
import 'pages/quiz_logros_screen.dart';
import 'pages/buscador_juridico_screen.dart';

import 'pages/reportes_guardados_page.dart';
import 'pages/reset_password_page.dart';
import 'pages/verify_email_page.dart';
import 'providers/game_provider.dart';
import 'providers/user_provider.dart';
import 'services/auth_service.dart'; // FIREBASE AUTH SERVICE
import 'firebase_options.dart'; // Asegúrate de tener este archivo

/// Bandera global de arranque en frío.
///
/// El SplashScreen animado se muestra SOLO cuando se abre la app (proceso
/// nuevo). Vive fuera del árbol de widgets: sobrevive a los remontes por
/// cambio de tema (MaterialApp con ValueKey) y a la reanudación desde
/// segundo plano, de modo que ahí NUNCA vuelve a aparecer.
bool _splashArranquePendiente = true;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // CRÍTICO antes de runApp: sin esto, la app no funciona.
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // NO CRÍTICO: se ejecuta en paralelo, no bloquea el arranque.
  unawaited(initializeDateFormatting('es_ES', null));
  unawaited(TemaGlobal.cargar());
  // Precarga el glosario desde Supabase (tabla glosario_terminos) para que
  // la pantalla, el buscador y el RAG tengan siempre los términos aprobados.
  unawaited(GlosarioScreen.precargarDesdeSupabase());

  runApp(const DosimetriaPenalApp());
}

class DosimetriaPenalApp extends StatelessWidget {
  const DosimetriaPenalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Firebase Auth Service (para login/registro)
        Provider<AuthService>(create: (_) => AuthService()),
        
        // Providers de estado
        ChangeNotifierProvider<GameState>(create: (_) => GameState()),
        ChangeNotifierProvider<UserState>(create: (_) => UserState()),
      ],
      child: ValueListenableBuilder<bool>(
        valueListenable: TemaGlobal.oscuro,
        builder: (context, oscuro, _) => MaterialApp(
        // key: al alternar el modo se remonta TODO el árbol — cada widget
        // re-evalúa los getters de TemaGlobal (evita modo a medias).
        key: ValueKey('tema_${oscuro}'),
        title: 'Dosimetría Penal Venezolana',
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('es', 'ES'),
        ],
        locale: const Locale('es', 'ES'),
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: oscuro ? ThemeMode.dark : ThemeMode.light,
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthWrapper(),
          '/login': (context) => const LoginPage(), // FIREBASE
          '/main': (context) => const MainScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/asistente_legal': (context) => const AsistenteLegalHubScreen(),
          '/asistente_legal_chat': (context) => const AsistenteLegalScreen(),
          '/redactor_documentos': (context) => const RedactorDocumentosScreen(),
          '/chat_legal': (context) => const ChatLegalScreen(),
          '/busqueda_semantica': (context) => const BusquedaSemanticaScreen(),
          '/admin_ia_config': (context) => const AdminIAConfigScreen(),
          '/admin_glosario': (context) => const AdminGlosarioScreen(),
          '/admin_users': (context) => const AdminUsersScreen(),
          '/calculadora': (context) => const DosimetriaPage(),
          '/calculos': (context) => const CalculosGuardadosPage(),
          '/agenda': (context) => const AgendaScreen(),
          '/reportes': (context) => const ReportesGuardadosPage(),
          '/glosario': (context) =>
              const BuscadorJuridicoScreen(alcanceInicial: AlcanceBusqueda.glosario),
          '/repositorio_jurisprudencia': (context) =>
              const BuscadorJuridicoScreen(alcanceInicial: AlcanceBusqueda.sentencias),
          '/repositorio_leyes': (context) =>
              const BuscadorJuridicoScreen(alcanceInicial: AlcanceBusqueda.leyes),
          '/mapa_tribunales': (context) => const MapaTribunalesScreen(),
          '/quiz': (context) => const QuizLobbyScreen(),
          '/quiz_lobby': (context) => const QuizLobbyScreen(),
          '/quiz_logros': (context) => const QuizLogrosScreen(),
          '/lapsos': (context) => const AgendaScreen(), // Lapsos integrados en Agenda (por expediente)
          '/verify-email': (context) => const VerifyEmailPage(),
          '/reset-password': (context) => const ResetPasswordPage(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/computo' && settings.arguments != null) {
            final args = settings.arguments as Map<String, dynamic>;
            final delitos = (args['delitos'] as List)
                .map((e) => Delito.fromMap(e as Map<String, dynamic>))
                .toList();
            final concurso = args['concurso'] as TipoConcurso;
            final admisionHechos = args['admisionHechos'] as bool;
            final fraccionAdmision = args['fraccionAdmision'] as double;
            final penaTotal = args['penaTotal'] as double;
            return MaterialPageRoute(
              builder: (context) => ComputoPage(
                delitos: delitos,
                concurso: concurso,
                admisionHechos: admisionHechos,
                fraccionAdmision: fraccionAdmision,
                penaTotal: penaTotal,
              ),
            );
          }
          return null;
        },
      ),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  Timer? _timerSplash;

  @override
  void initState() {
    super.initState();
    // Duración mínima del splash (deja terminar la intro de 900ms) SOLO
    // en el arranque en frío. Al reanudar desde segundo plano o al cambiar
    // de tema la bandera global ya es false y no se vuelve a programar.
    if (_splashArranquePendiente) {
      _timerSplash = Timer(const Duration(milliseconds: 1300), () {
        _splashArranquePendiente = false;
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _timerSplash?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return StreamBuilder<firebase_auth.User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Arranque en frío (o mientras Firebase resuelve en ms): splash.
        // Al reanudar desde segundo plano el árbol persiste y este branch
        // nunca se cumple, así que el usuario vuelve directo a su pantalla.
        if (_splashArranquePendiente ||
            snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        final user = snapshot.data;
        if (user == null) return const LoginPage();
        if (!user.emailVerified) return const VerifyEmailPage();
        return const MainScreen();
      },
    );
  }
}