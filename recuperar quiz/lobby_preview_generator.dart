import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../data/venezuela_regions.dart';

/// Generador de previews del lobby para visualización
class LobbyPreviewGenerator extends StatefulWidget {
  const LobbyPreviewGenerator({super.key});

  @override
  State<LobbyPreviewGenerator> createState() => _LobbyPreviewGeneratorState();
}

class _LobbyPreviewGeneratorState extends State<LobbyPreviewGenerator> {
  int _selectedLevel = 1;
  final GlobalKey _repaintKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final region = getRegionForLevel(_selectedLevel);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview Generator - Lobby'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _captureAndSave,
          ),
        ],
      ),
      body: Column(
        children: [
          // Controles
          _buildControls(),
          
          // Preview del lobby
          Expanded(
            child: RepaintBoundary(
              key: _repaintKey,
              child: _buildLobbyPreview(region),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade200,
      child: Column(
        children: [
          Row(
            children: [
              const Text('Nivel: ', style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: Slider(
                  value: _selectedLevel.toDouble(),
                  min: 1,
                  max: 3000,
                  divisions: 300,
                  label: '$_selectedLevel',
                  onChanged: (value) {
                    setState(() {
                      _selectedLevel = value.toInt();
                    });
                  },
                ),
              ),
              Text('$_selectedLevel', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => setState(() => _selectedLevel = 1),
                child: const Text('Nivel 1'),
              ),
              ElevatedButton(
                onPressed: () => setState(() => _selectedLevel = 100),
                child: const Text('Nivel 100'),
              ),
              ElevatedButton(
                onPressed: () => setState(() => _selectedLevel = 500),
                child: const Text('Nivel 500'),
              ),
              ElevatedButton(
                onPressed: () => setState(() => _selectedLevel = 1000),
                child: const Text('Nivel 1000'),
              ),
              ElevatedButton(
                onPressed: () => setState(() => _selectedLevel = 3000),
                child: const Text('Nivel 3000'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLobbyPreview(RegionVenezuela? region) {
    if (region == null) {
      return const Center(child: Text('No hay región para este nivel'));
    }

    // Calcular qué monumentos están en el rango visible (nivel actual ± 50)
    final startLevel = (_selectedLevel - 50).clamp(1, 3000);
    final endLevel = (_selectedLevel + 50).clamp(1, 3000);
    final visibleMonuments = getMonumentosInRange(startLevel, endLevel);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            region.colorPrincipal.withOpacity(0.3),
            Colors.white,
            region.colorPrincipal.withOpacity(0.1),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Banner de región
          _buildRegionBanner(region),
          
          // Camino vertical
          _buildPath(),
          
          // Monumentos
          ..._buildMonuments(visibleMonuments),
          
          // Nivel actual (medallón grande)
          _buildCurrentLevelNode(),
          
          // Niveles cercanos
          ..._buildNearbyLevels(),
        ],
      ),
    );
  }

  Widget _buildRegionBanner(RegionVenezuela region) {
    return Positioned(
      top: 20,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: region.colorPrincipal, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: region.colorPrincipal, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        region.estado,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: region.colorPrincipal,
                        ),
                      ),
                      Text(
                        'Capital: ${region.capital}',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              region.descripcion,
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Niveles ${region.nivelInicio} - ${region.nivelFin}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: region.colorPrincipal.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Nivel Actual: $_selectedLevel',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: region.colorPrincipal,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPath() {
    return Positioned.fill(
      child: CustomPaint(
        painter: PathPainter(currentLevel: _selectedLevel),
      ),
    );
  }

  List<Widget> _buildMonuments(List<MonumentoRegional> monuments) {
    return monuments.map((monument) {
      // Posición vertical basada en el nivel
      final offsetFromCurrent = monument.nivel - _selectedLevel;
      final y = 250.0 + (offsetFromCurrent * 30); // 30px por nivel

      // Si está muy lejos, no lo mostramos
      if (y < 150 || y > 550) return const SizedBox.shrink();

      return Positioned(
        left: monument.nivel % 2 == 0 ? 50 : null,
        right: monument.nivel % 2 == 0 ? null : 50,
        top: y,
        child: _buildMonumentCard(monument),
      );
    }).toList();
  }

  Widget _buildMonumentCard(MonumentoRegional monument) {
    Color typeColor;
    switch (monument.tipo) {
      case 'tribunal':
        typeColor = const Color(0xFF003893);
        break;
      case 'colonial':
        typeColor = const Color(0xFFD4AF37);
        break;
      case 'iglesia':
        typeColor = const Color(0xFFCF142B);
        break;
      case 'plaza':
        typeColor = const Color(0xFF228B22);
        break;
      default:
        typeColor = Colors.grey;
    }

    return Container(
      width: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: typeColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(monument.icono, color: typeColor, size: 20),
              const SizedBox(width: 6),
              if (monument.esHistorico)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'HISTÓRICO',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD4AF37),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            monument.nombre,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'Nivel ${monument.nivel}',
            style: TextStyle(
              fontSize: 10,
              color: typeColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentLevelNode() {
    return Positioned(
      left: 0,
      right: 0,
      top: 250,
      child: Center(
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFFCDD09), Color(0xFFFFD700)],
            ),
            border: Border.all(color: const Color(0xFF003893), width: 4),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFCDD09).withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$_selectedLevel',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF003893),
                  ),
                ),
                const Text(
                  'ACTUAL',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF003893),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildNearbyLevels() {
    final List<Widget> nodes = [];
    
    for (int i = -3; i <= 3; i++) {
      if (i == 0) continue; // El nivel actual ya está dibujado
      
      final level = _selectedLevel + i;
      if (level < 1 || level > 3000) continue;
      
      final y = 250.0 + (i * 30);
      final isCompleted = level < _selectedLevel;
      final isLocked = level > _selectedLevel;
      
      nodes.add(
        Positioned(
          left: 0,
          right: 0,
          top: y,
          child: Center(
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted 
                    ? const Color(0xFF003893)
                    : isLocked
                        ? Colors.grey
                        : Colors.white,
                border: Border.all(
                  color: isCompleted
                      ? const Color(0xFFFCDD09)
                      : Colors.grey,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  isCompleted ? '✓' : '$level',
                  style: TextStyle(
                    fontSize: isCompleted ? 24 : 16,
                    fontWeight: FontWeight.bold,
                    color: isCompleted || isLocked ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    
    return nodes;
  }

  Future<void> _captureAndSave() async {
    try {
      final RenderRepaintBoundary boundary = _repaintKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      
      // Aquí guardarías la imagen
      // Por ahora solo mostramos un mensaje
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Preview del nivel $_selectedLevel capturado'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Painter del camino vertical
class PathPainter extends CustomPainter {
  final int currentLevel;

  PathPainter({required this.currentLevel});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF5F5DC)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFFD4AF37)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Camino vertical simple
    final pathRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 100,
      height: size.height,
    );

    canvas.drawRect(pathRect, paint);
    canvas.drawRect(pathRect, borderPaint);
    
    // Líneas divisorias
    for (int i = 0; i < 20; i++) {
      final y = i * 30.0;
      canvas.drawLine(
        Offset(size.width / 2 - 50, y),
        Offset(size.width / 2 + 50, y),
        Paint()
          ..color = const Color(0xFFD4AF37).withOpacity(0.3)
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(PathPainter oldDelegate) {
    return currentLevel != oldDelegate.currentLevel;
  }
}
