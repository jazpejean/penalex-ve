import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

import '../config/app_colors.dart';
import '../config/app_tokens.dart';
import '../services/edge_detector.dart';
import 'crop_adjust_screen.dart';

/// Cámara propia con detección de bordes en vivo.
///
/// Corre el detector sobre el plano de luminancia del fotograma (YUV420),
/// dibuja el cuadrilátero sobre el visor y entrega las esquinas al recorte.
class CameraScannerScreen extends StatefulWidget {
  const CameraScannerScreen({super.key});

  @override
  State<CameraScannerScreen> createState() => _CameraScannerScreenState();
}

class _CameraScannerScreenState extends State<CameraScannerScreen> {
  CameraController? _controller;
  final ValueNotifier<List<Offset>?> _esquinas = ValueNotifier<List<Offset>?>(null);
  int _streamAncho = 1;
  int _streamAlto = 1;
  DateTime _ultimoFrame = DateTime.fromMillisecondsSinceEpoch(0);
  bool _analizando = false;
  bool _capturando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  Future<void> _iniciar() async {
    try {
      final List<CameraDescription> camaras = await availableCameras();
      if (camaras.isEmpty) {
        setState(() => _error = 'No hay cámara disponible.');
        return;
      }
      final CameraDescription trasera = camaras.firstWhere(
        (CameraDescription c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => camaras.first,
      );
      final CameraController c = CameraController(
        trasera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await c.initialize();
      if (!mounted) return;
      setState(() => _controller = c);
      await c.startImageStream(_procesarFrame);
    } catch (e) {
      if (mounted) setState(() => _error = 'No se pudo abrir la cámara: $e');
    }
  }

  void _procesarFrame(CameraImage frame) {
    // Se analiza cada 300 ms para no saturar la interfaz.
    final DateTime ahora = DateTime.now();
    if (_analizando ||
        ahora.difference(_ultimoFrame) < const Duration(milliseconds: 300)) {
      return;
    }
    _ultimoFrame = ahora;
    _analizando = true;
    try {
      final Plane plano = frame.planes.first;
      _streamAncho = frame.width;
      _streamAlto = frame.height;
      final List<Offset>? detectadas =
          EdgeDetector.detectarDesdeGris(plano.bytes, frame.width, frame.height);
      if (mounted) _esquinas.value = detectadas;
    } catch (_) {
      // Un fotograma ilegible no debe romper el visor.
    } finally {
      _analizando = false;
    }
  }

  Future<void> _capturar() async {
    final CameraController? c = _controller;
    if (c == null || _capturando) return;
    setState(() => _capturando = true);
    try {
      await c.stopImageStream();
      final XFile foto = await c.takePicture();
      final Uint8List bytes = await File(foto.path).readAsBytes();
      final img.Image? im = img.decodeImage(bytes);
      final double factor = im != null && _streamAncho > 0
          ? im.width / _streamAncho
          : 1.0;
      final List<Offset>? esquinas = _esquinas.value
          ?.map((Offset e) => Offset(e.dx * factor, e.dy * factor))
          .toList();

      if (!mounted) return;
      final File? recortada = await Navigator.push<File>(
        context,
        MaterialPageRoute<File>(
          builder: (_) => CropAdjustScreen(
            imagePath: foto.path,
            detectedCorners: esquinas,
          ),
        ),
      );
      if (!mounted) return;
      if (recortada != null) {
        Navigator.pop(context, <String>[recortada.path]);
        return;
      }
      await c.startImageStream(_procesarFrame);
    } catch (e) {
      if (mounted) {
        setState(() => _capturando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al capturar: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _esquinas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CameraController? c = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Escanear documento',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTokens.margen),
                child: Text(_error!, textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white)),
              ),
            )
          : c == null
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.dorado))
              : Column(
                  children: <Widget>[
                    Expanded(
                      child: LayoutBuilder(
                        builder: (BuildContext ctx, BoxConstraints box) {
                          return Stack(
                            fit: StackFit.expand,
                            children: <Widget>[
                              Center(child: CameraPreview(c)),
                              ValueListenableBuilder<List<Offset>?>(
                                valueListenable: _esquinas,
                                builder: (_, List<Offset>? e, __) {
                                  return CustomPaint(
                                    painter: _CuadrilateroPainter(
                                      esquinas: e,
                                      anchoFuente: _streamAncho.toDouble(),
                                      altoFuente: _streamAlto.toDouble(),
                                      anchoDestino: box.maxWidth,
                                      altoDestino: box.maxHeight,
                                    ),
                                  );
                                },
                              ),
                              Positioned(
                                left: 16,
                                right: 16,
                                top: 16,
                                child: Text(
                                  'Encuadra el documento. El borde se detecta solo.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    shadows: <Shadow>[
                                      Shadow(blurRadius: 4, color: Colors.black54)
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    Container(
                      color: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          IconButton(
                            tooltip: 'Cancelar',
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close,
                                color: Colors.white, size: 28),
                          ),
                          GestureDetector(
                            onTap: _capturar,
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 4),
                              ),
                              child: _capturando
                                  ? const Padding(
                                      padding: EdgeInsets.all(18),
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: AppColors.dorado),
                                    )
                                  : const Center(
                                      child: Icon(Icons.camera,
                                          color: Colors.white, size: 32),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 28),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _CuadrilateroPainter extends CustomPainter {
  _CuadrilateroPainter({
    required this.esquinas,
    required this.anchoFuente,
    required this.altoFuente,
    required this.anchoDestino,
    required this.altoDestino,
  });

  final List<Offset>? esquinas;
  final double anchoFuente;
  final double altoFuente;
  final double anchoDestino;
  final double altoDestino;

  @override
  void paint(Canvas canvas, Size size) {
    final List<Offset>? e = esquinas;
    if (e == null || e.length != 4) return;
    final double sx = anchoDestino / anchoFuente;
    final double sy = altoDestino / altoFuente;
    final Path camino = Path()
      ..moveTo(e[0].dx * sx, e[0].dy * sy)
      ..lineTo(e[1].dx * sx, e[1].dy * sy)
      ..lineTo(e[2].dx * sx, e[2].dy * sy)
      ..lineTo(e[3].dx * sx, e[3].dy * sy)
      ..close();
    canvas.drawPath(
      camino,
      Paint()
        ..color = AppColors.dorado
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    for (final Offset punto in e) {
      canvas.drawCircle(
        Offset(punto.dx * sx, punto.dy * sy),
        5,
        Paint()..color = AppColors.dorado,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CuadrilateroPainter old) =>
      old.esquinas != esquinas ||
      old.anchoDestino != anchoDestino ||
      old.altoDestino != altoDestino;
}
