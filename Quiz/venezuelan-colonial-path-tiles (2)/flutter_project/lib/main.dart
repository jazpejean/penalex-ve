import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/game_state_service.dart';
import 'ui/screens/dashboard_screen.dart';
import 'ui/screens/lobby_game_screen.dart';
import 'ui/screens/ranking_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final stateService = GameStateService();
  await stateService.init();

  runApp(PenalexApp(stateService: stateService));
}

class PenalexApp extends StatelessWidget {
  final GameStateService stateService;

  const PenalexApp({super.key, required this.stateService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Penalex VE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B1528),
        primaryColor: const Color(0xFF003893),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF003893),
          secondary: Color(0xFFD4AF37),
          surface: Color(0xFF14213D),
          background: Color(0xFF0B1528),
        ),
        fontFamily: 'serif',
      ),
      home: MainNavigator(stateService: stateService),
    );
  }
}

class MainNavigator extends StatefulWidget {
  final GameStateService stateService;

  const MainNavigator({super.key, required this.stateService});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  String _currentRoute = "dashboard"; // dashboard, game, ranking

  @override
  Widget build(BuildContext context) {
    switch (_currentRoute) {
      case "game":
        return LobbyGameScreen(
          stateService: widget.stateService,
          onBackToDashboard: () {
            setState(() {
              _currentRoute = "dashboard";
            });
          },
        );
      case "ranking":
        return RankingScreen(
          stateService: widget.stateService,
          onBack: () {
            setState(() {
              _currentRoute = "dashboard";
            });
          },
        );
      case "dashboard":
      default:
        return DashboardScreen(
          stateService: widget.stateService,
          onPlayClick: () {
            setState(() {
              _currentRoute = "game";
            });
          },
          onRankingClick: () {
            setState(() {
              _currentRoute = "ranking";
            });
          },
        );
    }
  }
}
