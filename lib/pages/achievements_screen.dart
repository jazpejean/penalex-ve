import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_colors.dart';
import '../models/certificate.dart';
import "../models/user.dart";
import '../providers/user_provider.dart';
import '../services/certificate_service.dart';
import '../widgets/app_drawer.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final UserState userState = Provider.of<UserState>(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        drawer: const AppDrawer(currentRoute: '/achievements'),
        appBar: AppBar(
          title: const Text('Mis Logros'),
          backgroundColor: AppColors.primary,
          bottom: const TabBar(
            tabs: <Widget>[
              Tab(text: 'Certificados'),
              Tab(text: 'Estadísticas'),
            ],
            indicatorColor: AppColors.secondary,
            labelColor: AppColors.secondary,
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[AppColors.background, AppColors.surface],
            ),
          ),
          child: TabBarView(
            children: <Widget>[
              _buildCertificatesTab(userState.certificates),
              _buildStatisticsTab(userState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCertificatesTab(List<Certificate> certificates) {
    if (certificates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.emoji_events_outlined,
              size: 80,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 20),
            const Text(
              'Aún no has obtenido certificados',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Completa niveles en el Desafío Penal para obtener tu primer certificado',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: certificates.length,
      itemBuilder: (BuildContext context, int index) {
        final Certificate certificate = certificates[index];
        return Card(
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: const Icon(
              Icons.workspace_premium,
              color: AppColors.secondary,
              size: 40,
            ),
            title: Text(
              certificate.titulo,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Fecha: ${certificate.fecha.day}/${certificate.fecha.month}/${certificate.fecha.year}'),
                Text('Nivel alcanzado: ${certificate.nivelAlcanzado}'),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.download),
              onPressed: () => _downloadCertificate(context, certificate),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatisticsTab(UserState userState) {
    final UserModel? user = userState.user;
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: <Widget>[
                  Text(
                    'Rango Actual',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    user.rangoActual,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Nivel ${user.nivelActual}',
                    style: const TextStyle(
                      fontSize: 18,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Estadísticas Generales',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: <Widget>[
              _buildStatCard('Puntuación Máxima', '${user.puntuacionMaxima}'),
              _buildStatCard('Racha Máxima', '${user.rachaMaxima}'),
              _buildStatCard('Preguntas Respondidas', '${user.preguntasRespondidas}'),
              _buildStatCard('Preguntas Correctas', '${user.preguntasCorrectas}'),
              _buildStatCard('Tasa de Acierto', user.preguntasRespondidas > 0 ? (user.preguntasCorrectas / user.preguntasRespondidas * 100).toStringAsFixed(1) : '0%'),
              _buildStatCard('Tiempo Promedio', '${user.tiempoPromedioRespuesta}s'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value) => Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

  Future<void> _downloadCertificate(BuildContext context, Certificate certificate) async {
    try {
      await CertificateService.generateAndDownloadCertificate(certificate);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Certificado descargado exitosamente')),
        );
      }
    } on Exception catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al descargar certificado: $e')),
        );
      }
    }
  }
}