import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../models/user.dart';
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
        future: _loadRanking(),
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

  Future<List<UserModel>> _loadRanking() async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
        .collection('users')
        .orderBy('puntuacionMaxima', descending: true)
        .limit(100)
        .get();
    return snapshot.docs.map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
      final Map<String, dynamic> data = doc.data();
      return UserModel(
        uid: doc.id,
        nombre: data['nombre'] ?? 'Anónimo',
        nivelActual: (data['nivelActual'] as num?)?.toInt() ?? 1,
        puntosTotales: (data['puntosTotales'] as num?)?.toInt() ?? 0,
        rangoActual: data['rangoActual'] ?? 'Alguacil',
        fechaRegistro: (data['fechaRegistro'] as Timestamp?)?.toDate() ?? DateTime.now(),
        puntuacionMaxima: (data['puntuacionMaxima'] as num?)?.toInt() ?? 0,
        rachaMaxima: (data['rachaMaxima'] as num?)?.toInt() ?? 0,
        preguntasRespondidas: (data['preguntasRespondidas'] as num?)?.toInt() ?? 0,
        preguntasCorrectas: (data['preguntasCorrectas'] as num?)?.toInt() ?? 0,
        tiempoPromedioRespuesta: (data['tiempoPromedioRespuesta'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();
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