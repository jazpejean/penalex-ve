import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:nested/nested.dart';
import 'package:provider/provider.dart';

import 'config/app_colors.dart';
import 'firebase_options.dart';
import 'pages/agenda_screen.dart';
import 'pages/dashboard_screen.dart';
import 'pages/dosimetria_page.dart';
import 'pages/login_page.dart';
import 'pages/quiz_lobby_screen.dart';
import 'pages/splash_screen.dart';
import 'pages/verify_email_page.dart';
import 'providers/auth_provider.dart';
import 'providers/game_provider.dart';
import 'providers/user_provider.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cargar variables de entorno con manejo de errores
  try {
    await dotenv.load();
  } on Exception catch (e) {
    debugPrint("Error cargando .env: $e. La aplicación continuará con valores por defecto.");
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final NotificationService notificationService = NotificationService();
  await notificationService.initialize();

  runApp(const PenalexApp());
}

class PenalexApp extends StatelessWidget {
  const PenalexApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Crear una única instancia de AuthService para toda la app
    final authService = AuthService();

    return MultiProvider(
      providers: <SingleChildWidget>[
        ChangeNotifierProvider<GameState>(create: (_) => GameState()),
        ChangeNotifierProvider<UserState>(create: (_) => UserState()),
        Provider<AuthService>.value(value: authService),
        ChangeNotifierProvider<AppAuthProvider>(
          create: (_) => AppAuthProvider(authService: authService),
        ),
      ],
      child: MaterialApp(
        title: "Penalex VE",
        locale: const Locale("es", "VE"),
        supportedLocales: const <Locale>[Locale("es", "VE"), Locale("es")],
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(
          primaryColor: AppColors.primary,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            secondary: AppColors.secondary,
            error: AppColors.error,
          ),
          scaffoldBackgroundColor: AppColors.background,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.secondary,
            elevation: 0,
            centerTitle: true,
            iconTheme: IconThemeData(color: AppColors.secondary),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.secondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.black.withValues(alpha: 0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.secondary,
                width: 1.5,
              ),
            ),
            labelStyle: const TextStyle(color: AppColors.primary),
            prefixIconColor: AppColors.primary,
          ),
        ),
        routes: <String, WidgetBuilder>{
          "/": (BuildContext context) => const AuthWrapper(),
          "/login": (BuildContext context) => const LoginPage(),
          "/verify-email": (BuildContext context) => const VerifyEmailPage(),
          "/dashboard": (BuildContext context) => const DashboardScreen(),
          "/agenda": (BuildContext context) => const AgendaScreen(),
          "/calculadora": (BuildContext context) => const DosimetriaPage(),
          "/quiz": (BuildContext context) => const QuizLobbyScreen(),
        },
      ),
    );
  }
}

/// Widget que decide qué pantalla mostrar según el estado de autenticación
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final authProvider = Provider.of<AppAuthProvider>(context);

    return StreamBuilder<firebase_auth.User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        final user = snapshot.data;

        // No hay usuario autenticado
        if (user == null) return const LoginPage();

        // Dispositivo no válido (cuenta abierta en otro lado)
        if (!authProvider.isDeviceValid) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tu cuenta se ha abierto en otro dispositivo. Se cerró esta sesión.'),
                backgroundColor: Colors.orange,
              ),
            );
            await authService.signOut();
          });
          return const LoginPage();
        }

        // Email no verificado
        if (!user.emailVerified) {
          return const VerifyEmailPage();
        }

        // todo correcto: ir al dashboard
        return const DashboardScreen();
      },
    );
  }
}