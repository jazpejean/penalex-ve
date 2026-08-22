import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_colors.dart';
import '../models/user.dart';
import '../providers/game_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/app_drawer.dart';

class GlobalRankingScreen extends StatelessWidget {
  const GlobalRankingScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
      drawer: const AppDrawer(currentRoute: "/ranking"),
      appBar: AppBar(
        title: const Text("Ranking Global"),
        backgroundColor: AppColors.primary,
      ),
      body: FutureBuilder<List<UserModel>>(
        future: _loadRanking(context),
        builder: (BuildContext context, AsyncSnapshot<List<UserModel>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    "Error al cargar el ranking",
                    style: TextStyle(fontSize: 18, color: Colors.red[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          final List<UserModel> ranking = snapshot.data ?? <UserModel>[];
          return _buildRankingList(ranking);
        },
      ),
    );

  Future<List<UserModel>> _loadRanking(BuildContext context) async {
    // Obtener usuario actual
    final userState = Provider.of<UserState>(context, listen: false);
    final gameState = Provider.of<GameState>(context, listen: false);
    
    // Por ahora, crear ranking simulado con usuario actual
    // TODO: Integrar con Supabase cuando esté listo
    final ranking = <UserModel>[];
    
    // Agregar usuario actual si existe
    if (userState.user != null) {
      ranking.add(userState.user!.copyWith(
        nivelActual: gameState.currentLevel,
        puntosTotales: gameState.score,
        puntuacionMaxima: gameState.score,
      ));
    }
    
    // Agregar usuarios simulados para demostración
    ranking.addAll(_getUsersSimulados());
    
    // Ordenar por puntuación
    ranking.sort((a, b) => b.puntuacionMaxima.compareTo(a.puntuacionMaxima));
    
    return ranking.take(100).toList();
  }

  List<UserModel> _getUsersSimulados() {
    final nombres = [
      'María González', 'Carlos Pérez', 'Ana Rodríguez', 'Luis Martínez',
      'Carmen Silva', 'José Hernández', 'Laura Díaz', 'Pedro Ramírez',
      'Isabel Torres', 'Miguel Flores', 'Sofía Castro', 'Andrés Morales',
      'Valentina Ruiz', 'Diego Ortiz', 'Camila Gómez', 'Javier Vargas',
      'Paula Sánchez', 'Roberto Mendoza', 'Daniela Rojas', 'Fernando López',
    ];
    
    final rangos = [
      'Magistrado Supremo', 'Juez Superior', 'Fiscal', 'Defensor',
      'Abogado Senior', 'Abogado Junior', 'Pasante', 'Alguacil',
    ];
    
    return List.generate(20, (i) {
      final baseScore = 5000 - (i * 200);
      final nivel = 50 - (i * 2);
      return UserModel(
        uid: 'sim_$i',
        nombre: nombres[i % nombres.length],
        nivelActual: nivel.clamp(1, 3000),
        puntosTotales: baseScore,
        rangoActual: rangos[i ~/ 3 % rangos.length],
        fechaRegistro: DateTime.now().subtract(Duration(days: i * 7)),
        puntuacionMaxima: baseScore,
        rachaMaxima: 10 - (i ~/ 2),
        preguntasRespondidas: (nivel * 5),
        preguntasCorrectas: (nivel * 4),
        tiempoPromedioRespuesta: 15.0 + (i * 0.5),
      );
    });
  }

  Widget _buildRankingList(List<UserModel> ranking) {
    if (ranking.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.leaderboard_outlined,
              size: 80,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 20),
            const Text(
              'Aún no hay jugadores en el ranking',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: ranking.length,
      itemBuilder: (BuildContext context, int index) {
        final UserModel user = ranking[index];
        final bool isTopThree = index < 3;

        return Card(
          elevation: isTopThree ? 6 : 2,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: isTopThree
                  ? LinearGradient(
                      colors: <Color>[
                        _getRankColor(index).withValues(alpha: 0.1),
                        _getRankColor(index).withValues(alpha: 0.05),
                      ],
                    )
                  : null,
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getRankColor(index),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              title: Text(
                user.nombre,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isTopThree ? _getRankColor(index) : AppColors.primary,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    user.rangoActual,
                    style: const TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text('Nivel ${user.nivelActual}'),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    user.puntuacionMaxima.toString(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                  const Text(
                    'puntos',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber;
      case 1:
        return Colors.grey[400]!;
      case 2:
        return Colors.brown[400]!;
      default:
        return AppColors.primary;
    }
  }
}