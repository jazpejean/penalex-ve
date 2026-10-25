import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_colors.dart';
import '../config/app_theme.dart';
import '../services/tribunales_service.dart';

/// Ficha y geolocalización de un tribunal penal venezolano.
///
/// Dependencias (pubspec.yaml):
///  - `flutter_map` + `latlong2` : mapa interactivo (tiles de OpenStreetMap).
///  - `url_launcher`             : botón "Cómo llegar" (Waze → Google Maps).
///  - `cached_network_image`     : foto con caché local (evita recargar
///    la imagen del R2 en cada visita y aguanta caídas del servidor).
///
/// Estado de la imagen: `CachedNetworkImage` maneja la carga asíncrona con
/// sus propios callbacks (placeholder → error → éxito); nunca bloquea el
/// build. Si `url_foto` es nula/vacía se muestra un contenedor gris con el
/// ícono de edificio.
class TribunalDetailScreen extends StatelessWidget {
  final Tribunal tribunal;

  const TribunalDetailScreen({super.key, required this.tribunal});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaGlobal.superficie,
      body: CustomScrollView(
        slivers: [
          _cabecera(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _titulo(),
                  const SizedBox(height: 8),
                  _direccion(),
                  const SizedBox(height: 20),
                  _mapa(),
                  const SizedBox(height: 20),
                  _botonRuta(context),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Cabecera: foto del tribunal (R2) con caché, más la barra superior.
  // -------------------------------------------------------------------------
  Widget _cabecera(BuildContext context) {
    final azulMarino = TemaGlobal.azulMarino;
    final foto = tribunal.urlFoto;
    return SliverAppBar(
      pinned: true,
      expandedHeight: 230,
      backgroundColor: azulMarino,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: foto == null || foto.isEmpty
            ? _placeholderFoto()
            : CachedNetworkImage(
                imageUrl: foto,
                fit: BoxFit.cover,
                // --- Estado de carga de la imagen ---
                placeholder: (context, _) => Container(
                  color: const Color(0xFFD9DCE5),
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
                errorWidget: (context, _, __) => _placeholderFoto(),
              ),
      ),
    );
  }

  Widget _placeholderFoto() {
    return Container(
      color: const Color(0xFFD9DCE5),
      alignment: Alignment.center,
      child: const Icon(
        Icons.account_balance,
        size: 72,
        color: Color(0xFF8A90A0),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Título: nombre limpio en negrita, azul marino.
  // -------------------------------------------------------------------------
  Widget _titulo() {
    return Text(
      tribunal.nombreLimpio,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: TemaGlobal.texto,
        height: 1.3,
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Dirección: sede / municipio / estado con ícono de ubicación.
  // -------------------------------------------------------------------------
  Widget _direccion() {
    final partes = [
      if ((tribunal.sede ?? '').isNotEmpty) tribunal.sede!,
      if ((tribunal.municipio ?? '').isNotEmpty) tribunal.municipio!,
      tribunal.estado,
    ];
    final texto = partes.join(', ');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.location_on_outlined,
            size: 20, color: TemaGlobal.textoSecundario),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            texto,
            style: TextStyle(fontSize: 14, color: TemaGlobal.textoSecundario),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Mapa interactivo: OpenStreetMap + marcador en las coordenadas.
  // -------------------------------------------------------------------------
  Widget _mapa() {
    final lat = tribunal.latitud;
    final lng = tribunal.longitud;
    if (lat == null || lng == null) {
      // Sin coordenadas: no hay mapa, solo un aviso discreto.
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: TemaGlobal.capa,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text('Ubicación no disponible',
            style: TextStyle(color: TemaGlobal.textoTenue)),
      );
    }
    final punto = LatLng(lat, lng);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 200,
        width: double.infinity,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: punto,
            initialZoom: 15,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 've.com.penalex',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: punto,
                  width: 40,
                  height: 40,
                  child: const Icon(
                    Icons.location_pin,
                    size: 40,
                    color: Color(0xFF0B132B),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Botón "Cómo llegar": abre Google Maps; si falla, Waze como respaldo.
  // -------------------------------------------------------------------------
  Widget _botonRuta(BuildContext context) {
    final lat = tribunal.latitud;
    final lng = tribunal.longitud;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: (lat == null || lng == null)
            ? null
            : () => _abrirRuta(context, lat, lng),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: const Icon(Icons.navigation),
        label: const Text('Cómo llegar',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Future<void> _abrirRuta(BuildContext context, double lat, double lng) async {
    // 1) Google Maps (navegación solicitada por el usuario).
    final maps = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    // 2) Waze como respaldo si Maps no está disponible.
    final waze = Uri.parse(
        'https://waze.com/ul?ll=$lat,$lng&navigate=yes');

    var abierto = false;
    try {
      abierto = await launchUrl(maps, mode: LaunchMode.externalApplication);
    } catch (_) {
      abierto = false;
    }
    if (!abierto) {
      try {
        await launchUrl(waze, mode: LaunchMode.externalApplication);
      } catch (_) {
        // ni Maps ni Waze: se muestra un aviso sin romper la UI
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo abrir la ruta')),
          );
        }
      }
    }
  }
}