import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'ai_service.dart';

/// Interpretación de una idea en lenguaje natural.
class InterpretacionBusqueda {
  const InterpretacionBusqueda({
    required this.consulta,
    required this.categoria,
    required this.interpretacion,
    this.sala,
    this.anio,
  });

  final String consulta;
  final String categoria;
  final String interpretacion;
  final String? sala;
  final int? anio;
}

/// Convierte una idea vaga en una búsqueda real.
///
/// El modelo NO responde con sentencias: solo devuelve palabras clave y
/// filtros. La búsqueda la hace el servicio de siempre, sobre datos reales.
class BuscadorIaService {
  BuscadorIaService._();

  static const String _prompt = '''
Eres el buscador de jurisprudencia penal de Venezuela.

El usuario describe con lenguaje informal lo que necesita. Tu única tarea es
convertir esa idea en una búsqueda.

Devuelve SOLO un objeto JSON, sin markdown ni texto extra, con estas claves:
- "consulta": de 3 a 8 palabras clave jurídicas para buscar en el texto.
  Sin conectores ni frases vacías. Si la idea es general, deja "".
- "categoria": "Sentencias", "Jurisprudencias", "Resoluciones" o "Doctrinas".
- "sala": "scp" (penal), "scc" (casación civil), "sca" (casación social),
  "sccon" (constitucional), "sr" (sala de receso) o null.
- "anio": año entre 2000 y el actual, o null.
- "interpretacion": una frase corta, en español, que explique qué entendiste.

Reglas:
- No inventes números de sentencia ni ponentes.
- Si no hay año claro, "anio": null.
- Si la idea es amplia, "categoria": "Sentencias" y año null.
- Si piden "criterio", "tendencia" o "doctrina", usa "Jurisprudencias".
- Responde únicamente el JSON.

Idea del usuario:
''';

  static Future<InterpretacionBusqueda?> interpretar(String idea) async {
    final String limpia = idea.trim();
    if (limpia.isEmpty) return null;
    try {
      final String respuesta =
          await AIService.procesarConsultaGeneral('$_prompt"$limpia"');
      final int inicio = respuesta.indexOf('{');
      final int fin = respuesta.lastIndexOf('}');
      if (inicio < 0 || fin <= inicio) return null;

      final Map<String, dynamic> mapa =
          jsonDecode(respuesta.substring(inicio, fin + 1))
              as Map<String, dynamic>;

      final dynamic anioCrudo = mapa['anio'];
      final int? anio = anioCrudo is int
          ? anioCrudo
          : int.tryParse('${anioCrudo ?? ''}');

      return InterpretacionBusqueda(
        consulta: (mapa['consulta'] ?? limpia).toString().trim(),
        categoria: (mapa['categoria'] ?? 'Sentencias').toString(),
        interpretacion: (mapa['interpretacion'] ?? '').toString(),
        sala: mapa['sala']?.toString(),
        anio: anio,
      );
    } catch (e) {
      debugPrint('No se pudo interpretar la idea: $e');
      return null;
    }
  }
}
