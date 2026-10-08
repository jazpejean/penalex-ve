import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/theme.dart';
import 'models/delito.dart';
import 'pages/agenda_screen.dart';
import 'pages/admin_glosario_screen.dart';
import 'pages/admin_ia_config_screen.dart';
import 'pages/admin_users_screen.dart';
import 'pages/ai_analytics_screen.dart';
import 'pages/asistente_legal_screen.dart';
import 'pages/asistente_legal_hub_screen.dart';
import 'pages/redactor_documentos_screen.dart';
import 'pages/busqueda_semantica_screen.dart';
import 'pages/calculos_guardados_page.dart';
import 'pages/chat_legal_screen.dart';
import 'pages/computo_page.dart';
import 'pages/dashboard_screen.dart';
import 'pages/dosimetria_page.dart';
import 'pages/glosario_screen.dart';
import 'pages/leyes_screen.dart';
import 'pages/main_screen.dart';
import 'pages/login_page.dart'; // FIREBASE LOGIN
import 'pages/quiz_lobby_screen.dart';
import 'pages/quiz_logros_screen.dart';
import 'pages/repositorio_jurisprudencia_screen.dart';
import 'pages/repositorio_leyes_screen.dart';
import 'pages/reportes_guardados_page.dart';
import 'pages/reset_password_page.dart';
import 'pages/splash_screen.dart';
import 'pages/verify_email_page.dart';
import 'providers/game_provider.dart';
import 'providers/user_provider.dart';
import 'services/auth_service.dart'; // FIREBASE AUTH SERVICE
import 'firebase_options.dart'; // Asegúrate de tener este archivo

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Cargar variables de entorno
  await dotenv.load(fileName: ".env");
  
  // Inicializar datos de localización para español
  await initializeDateFormatting('es_ES', null);
  
  // Inicializar Firebase (para autenticación)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Inicializar Supabase (para datos: jurisprudencias, documentos, etc.)
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  
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
      child: MaterialApp(
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
          '/leyes': (context) => const LeyesScreen(),
          '/glosario': (context) => const GlosarioScreen(),
          '/repositorio_jurisprudencia': (context) => const RepositorioJurisprudenciaScreen(),
          '/repositorio_leyes': (context) => const RepositorioLeyesScreen(),
          '/ai_analytics': (context) => const AIAnalyticsScreen(),
          '/quiz': (context) => const QuizLobbyScreen(),
          '/quiz_lobby': (context) => const QuizLobbyScreen(),
          '/quiz_logros': (context) => const QuizLogrosScreen(),
          '/lapsos': (context) => const AgendaScreen(), // Lapsos integrados en Agenda
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
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return StreamBuilder<firebase_auth.User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        
        final user = snapshot.data;
        
        // Si no hay usuario, mostrar login
        if (user == null) return const LoginPage();

        // Si el email no está verificado, mostrar pantalla de verificación
        if (!user.emailVerified) {
          return const VerifyEmailPage();
        }

        // Usuario autenticado y verificado, ir a MainScreen
        return const MainScreen();
      },
    );
  }
}