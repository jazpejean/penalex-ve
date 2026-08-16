/// Servicio de búsqueda semántica con embeddings y similitud coseno
library;

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/sentencia.dart';
import '../models/ley.dart';
import 'auth_service.dart';

class BusquedaSemanticaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  /// Genera un embedding (vector) para un texto usando IA
  /// En producción esto debería usar OpenAI Embeddings API o similar
  Future<List<double>> _generarEmbedding(String texto) async {
    // SIMULACIÓN: En producción usar OpenAI Embeddings API
    // https://platform.openai.com/docs/guides/embeddings
    //
    // final response = await http.post(
    //   Uri.parse('https://api.openai.com/v1/embeddings'),
    //   headers: {
    //     'Content-Type': 'application/json',
    //     'Authorization': 'Bearer $apiKey',
    //   },
    //   body: jsonEncode({
    //     'input': texto,
    //     'model': 'text-embedding-3-small', // 1536 dimensiones, $0.02/1M tokens
    //   }),
    // );
    //
    // return List<double>.from(jsonDecode(response.body)['data'][0]['embedding']);

    // Por ahora, generamos embedding simple basado en keywords (fallback)
    return _generarEmbeddingSimple(texto);
  }

  /// Genera embedding simple basado en keywords (fallback sin API)
  List<double> _generarEmbeddingSimple(String texto) {
    // Dimensiones: 100 (pequeño para demo, producción usa 1536)
    const dimensiones = 100;
    final vector = List<double>.filled(dimensiones, 0.0);

    // Keywords legales venezolanas importantes
    final keywords = {
      // Delitos graves
      'homicidio': [0, 5, 10],
      'robo': [1, 6, 11],
      'secuestro': [2, 7, 12],
      'violación': [3, 8, 13],
      'fraude': [4, 9, 14],
      'corrupción': [5, 10, 15],
      'narcotráfico': [6, 11, 16],
      'lavado': [7, 12, 17],
      
      // Procedimiento
      'apelación': [20, 25, 30],
      'casación': [21, 26, 31],
      'amparo': [22, 27, 32],
      'habeas': [23, 28, 33],
      'tutela': [24, 29, 34],
      
      // Derechos
      'defensa': [40, 45, 50],
      'debido proceso': [41, 46, 51],
      'presunción inocencia': [42, 47, 52],
      'libertad': [43, 48, 53],
      'garantía': [44, 49, 54],
      
      // Penas
      'prisión': [60, 65, 70],
      'multa': [61, 66, 71],
      'inhabilitación': [62, 67, 72],
      'suspensión': [63, 68, 73],
      'atenuante': [64, 69, 74],
      'agravante': [65, 70, 75],
      
      // Pruebas
      'testimonio': [80, 85, 90],
      'pericia': [81, 86, 91],
      'documental': [82, 87, 92],
      'inspección': [83, 88, 93],
      'confesión': [84, 89, 94],
    };

    final textoLower = texto.toLowerCase();

    // Asignar pesos según keywords encontradas
    keywords.forEach((keyword, indices) {
      if (textoLower.contains(keyword)) {
        for (var i in indices) {
          if (i < dimensiones) {
            vector[i] += 1.0;
          }
        }
      }
    });

    // Normalizar vector (hacerlo unitario)
    final magnitud = sqrt(vector.fold<double>(0.0, (acc, val) => acc + val * val));
    if (magnitud > 0) {
      for (var i = 0; i < vector.length; i++) {
        vector[i] /= magnitud;
      }
    }

    return vector;
  }

  /// Calcula similitud coseno entre dos vectores
  double _similitudCoseno(List<double> vec1, List<double> vec2) {
    if (vec1.length != vec2.length) return 0.0;

    double dotProduct = 0.0;
    double mag1 = 0.0;
    double mag2 = 0.0;

    for (var i = 0; i < vec1.length; i++) {
      dotProduct += vec1[i] * vec2[i];
      mag1 += vec1[i] * vec1[i];
      mag2 += vec2[i] * vec2[i];
    }

    if (mag1 == 0 || mag2 == 0) return 0.0;

    return dotProduct / (sqrt(mag1) * sqrt(mag2));
  }

  /// Busca sentencias por similitud semántica
  Future<List<ResultadoBusqueda<Sentencia>>> buscarSentencias({
    required String consulta,
    int limite = 10,
    double umbralSimilitud = 0.3,
  }) async {
    try {
      // Generar embedding de la consulta
      final consultaEmbedding = await _generarEmbedding(consulta);

      // Obtener todas las sentencias (en producción usar Firestore Vector Search o Pinecone)
      final snapshot = await _firestore.collection('sentencias').limit(100).get();

      final resultados = <ResultadoBusqueda<Sentencia>>[];

      for (var doc in snapshot.docs) {
        final sentencia = Sentencia.fromMap(doc.data(), doc.id);

        // Generar embedding del contenido de la sentencia
        final textoSentencia = '${sentencia.resumen} ${sentencia.doctrina}';
        final sentenciaEmbedding = await _generarEmbedding(textoSentencia);

        // Calcular similitud
        final similitud = _similitudCoseno(consultaEmbedding, sentenciaEmbedding);

        if (similitud >= umbralSimilitud) {
          resultados.add(ResultadoBusqueda(
            item: sentencia,
            similitud: similitud,
            extractoRelevante: _extraerExtracto(textoSentencia, consulta),
          ));
        }
      }

      // Ordenar por similitud descendente
      resultados.sort((a, b) => b.similitud.compareTo(a.similitud));

      // Limitar resultados
      return resultados.take(limite).toList();
    } catch (e) {
      debugPrint('Error en búsqueda semántica de sentencias: $e');
      return [];
    }
  }

  /// Busca leyes por similitud semántica
  Future<List<ResultadoBusqueda<Ley>>> buscarLeyes({
    required String consulta,
    int limite = 10,
    double umbralSimilitud = 0.3,
  }) async {
    try {
      final consultaEmbedding = await _generarEmbedding(consulta);

      final snapshot = await _firestore.collection('leyes').limit(50).get();

      final resultados = <ResultadoBusqueda<Ley>>[];

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          // Crear Ley mínima manualmente para evitar fromMap
          final ley = Ley(
            id: doc.id,
            titulo: data['titulo'] ?? '',
            nombreCorto: data['nombreCorto'] ?? '',
            descripcion: data['descripcion'] ?? '',
            gaceta: data['gaceta'] ?? '',
            fechaPublicacion: (data['fechaPublicacion'] as Timestamp?)?.toDate() ?? DateTime.now(),
            capitulos: [], // Simplificado
            createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          );

          // Buscar en el texto general de la ley
          final textoLey = '${ley.titulo} ${ley.descripcion}';
          final leyEmbedding = await _generarEmbedding(textoLey);
          final similitud = _similitudCoseno(consultaEmbedding, leyEmbedding);

          if (similitud >= umbralSimilitud) {
            resultados.add(ResultadoBusqueda(
              item: ley,
              similitud: similitud,
              extractoRelevante: _extraerExtracto(textoLey, consulta),
            ));
          }
        } catch (e) {
          // Ignorar leyes con errores de parsing
          continue;
        }
      }

      resultados.sort((a, b) => b.similitud.compareTo(a.similitud));
      return resultados.take(limite).toList();
    } catch (e) {
      debugPrint('Error en búsqueda semántica de leyes: $e');
      return [];
    }
  }

  /// Busca en múltiples fuentes simultáneamente
  Future<ResultadosBusquedaUnificados> buscarUnificado({
    required String consulta,
    int limitePorFuente = 5,
    double umbralSimilitud = 0.3,
  }) async {
    try {
      final sentencias = await buscarSentencias(
        consulta: consulta,
        limite: limitePorFuente,
        umbralSimilitud: umbralSimilitud,
      );
      
      final leyes = await buscarLeyes(
        consulta: consulta,
        limite: limitePorFuente,
        umbralSimilitud: umbralSimilitud,
      );

      return ResultadosBusquedaUnificados(
        sentencias: sentencias,
        leyes: leyes,
        consulta: consulta,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error en búsqueda unificada: $e');
      return ResultadosBusquedaUnificados(
        sentencias: [],
        leyes: [],
        consulta: consulta,
        timestamp: DateTime.now(),
      );
    }
  }

  /// Guarda una búsqueda en el historial del usuario
  Future<void> guardarEnHistorial({
    required String consulta,
    required ResultadosBusquedaUnificados resultados,
  }) async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('historial_busquedas')
        .add({
      'consulta': consulta,
      'timestamp': FieldValue.serverTimestamp(),
      'cantidadSentencias': resultados.sentencias.length,
      'cantidadLeyes': resultados.leyes.length,
    });
  }

  /// Obtiene historial de búsquedas del usuario
  Stream<List<HistorialBusqueda>> obtenerHistorial({int limite = 20}) {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('historial_busquedas')
        .orderBy('timestamp', descending: true)
        .limit(limite)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => HistorialBusqueda.fromMap(doc.data()))
            .toList());
  }

  /// Extrae un fragmento relevante del texto que contiene la consulta
  String _extraerExtracto(String texto, String consulta, {int maxCaracteres = 200}) {
    final palabrasConsulta = consulta.toLowerCase().split(' ');
    final textoLower = texto.toLowerCase();

    // Buscar la primera palabra de la consulta
    int posicion = -1;
    for (var palabra in palabrasConsulta) {
      posicion = textoLower.indexOf(palabra);
      if (posicion != -1) break;
    }

    if (posicion == -1) {
      // Si no se encuentra, retornar el inicio
      return texto.length > maxCaracteres
          ? '${texto.substring(0, maxCaracteres)}...'
          : texto;
    }

    // Extraer contexto alrededor de la palabra encontrada
    final inicio = max(0, posicion - maxCaracteres ~/ 2);
    final fin = min(texto.length, posicion + maxCaracteres ~/ 2);

    String extracto = texto.substring(inicio, fin);

    if (inicio > 0) extracto = '...$extracto';
    if (fin < texto.length) extracto = '$extracto...';

    return extracto;
  }

  /// Sugiere consultas relacionadas basadas en historial y contexto
  Future<List<String>> sugerirConsultas(String consultaParcial) async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('historial_busquedas')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      final consultas = <String>{};
      for (var doc in snapshot.docs) {
        final consulta = doc.data()['consulta'] as String?;
        if (consulta != null &&
            consulta.toLowerCase().contains(consultaParcial.toLowerCase())) {
          consultas.add(consulta);
        }
      }

      return consultas.take(5).toList();
    } catch (e) {
      return [];
    }
  }
}

/// Resultado de búsqueda con similitud
class ResultadoBusqueda<T> {
  final T item;
  final double similitud; // 0.0 a 1.0
  final String extractoRelevante;

  const ResultadoBusqueda({
    required this.item,
    required this.similitud,
    required this.extractoRelevante,
  });
}

/// Resultados unificados de múltiples fuentes
class ResultadosBusquedaUnificados {
  final List<ResultadoBusqueda<Sentencia>> sentencias;
  final List<ResultadoBusqueda<Ley>> leyes;
  final String consulta;
  final DateTime timestamp;

  const ResultadosBusquedaUnificados({
    required this.sentencias,
    required this.leyes,
    required this.consulta,
    required this.timestamp,
  });

  int get totalResultados => sentencias.length + leyes.length;

  bool get hayResultados => totalResultados > 0;
}

/// Historial de búsqueda
class HistorialBusqueda {
  final String consulta;
  final DateTime timestamp;
  final int cantidadSentencias;
  final int cantidadLeyes;

  const HistorialBusqueda({
    required this.consulta,
    required this.timestamp,
    required this.cantidadSentencias,
    required this.cantidadLeyes,
  });

  Map<String, dynamic> toMap() {
    return {
      'consulta': consulta,
      'timestamp': Timestamp.fromDate(timestamp),
      'cantidadSentencias': cantidadSentencias,
      'cantidadLeyes': cantidadLeyes,
    };
  }

  factory HistorialBusqueda.fromMap(Map<String, dynamic> map) {
    return HistorialBusqueda(
      consulta: map['consulta'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      cantidadSentencias: map['cantidadSentencias'] ?? 0,
      cantidadLeyes: map['cantidadLeyes'] ?? 0,
    );
  }
}
