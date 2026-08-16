import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/escrito_legal.dart';
import 'ai_service.dart';

class EscritosService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Genera un escrito legal con IA
  static Future<EscritoLegal> generarEscrito({
    required TipoEscrito tipo,
    required Map<String, dynamic> datos,
  }) async {
    try {
      debugPrint('📝 Generando escrito: ${tipo.nombre}');

      final prompt = _construirPrompt(tipo, datos);
      final response = await AIService.generarEscritoLegal(
        tipo: tipo.name,
        prompt: prompt,
      );

      final escrito = EscritoLegal(
        id: '',
        tipo: tipo,
        titulo: datos['titulo'] as String? ?? tipo.nombre,
        contenido: response.interpretacion,
        createdAt: DateTime.now(),
        numeroCaso: datos['numeroCaso'] as String?,
        tribunal: datos['tribunal'] as String?,
        juez: datos['juez'] as String?,
        imputado: datos['imputado'] as String?,
        delitos: (datos['delitos'] as List<dynamic>?)?.cast<String>() ?? [],
        generadoPorIA: true,
        modeloIA: AIService.getModeloActivo().nombre,
        prompt: prompt,
      );

      debugPrint('✅ Escrito generado exitosamente');
      return escrito;
    } catch (e) {
      debugPrint('❌ Error generando escrito: $e');
      rethrow;
    }
  }

  /// Guarda un escrito en Firestore
  static Future<EscritoLegal> guardarEscrito(EscritoLegal escrito) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Usuario no autenticado');

      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('escritos')
          .add(escrito.toMap());

      debugPrint('✅ Escrito guardado: ${docRef.id}');
      return escrito.copyWith(id: docRef.id);
    } catch (e) {
      debugPrint('❌ Error guardando escrito: $e');
      rethrow;
    }
  }

  /// Obtiene todos los escritos del usuario
  static Future<List<EscritoLegal>> obtenerEscritos() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('escritos')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => EscritoLegal.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('❌ Error obteniendo escritos: $e');
      return [];
    }
  }

  /// Stream de escritos
  static Stream<List<EscritoLegal>> streamEscritos() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('escritos')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => EscritoLegal.fromFirestore(doc)).toList());
  }

  /// Actualiza un escrito
  static Future<void> actualizarEscrito(EscritoLegal escrito) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('escritos')
          .doc(escrito.id)
          .update({
        ...escrito.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Escrito actualizado');
    } catch (e) {
      debugPrint('❌ Error actualizando escrito: $e');
      rethrow;
    }
  }

  /// Elimina un escrito
  static Future<void> eliminarEscrito(String escritoId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('escritos')
          .doc(escritoId)
          .delete();

      debugPrint('✅ Escrito eliminado');
    } catch (e) {
      debugPrint('❌ Error eliminando escrito: $e');
      rethrow;
    }
  }

  /// Construye el prompt para cada tipo de escrito
  static String _construirPrompt(TipoEscrito tipo, Map<String, dynamic> datos) {
    switch (tipo) {
      case TipoEscrito.recursoApelacion:
        return _promptRecursoApelacion(datos);
      case TipoEscrito.escritoDefensa:
        return _promptEscritoDefensa(datos);
      case TipoEscrito.solicitudLibertad:
        return _promptSolicitudLibertad(datos);
      case TipoEscrito.oposicionMedidas:
        return _promptOposicionMedidas(datos);
      case TipoEscrito.demanda:
        return _promptDemanda(datos);
      default:
        return _promptGenerico(tipo, datos);
    }
  }

  static String _promptRecursoApelacion(Map<String, dynamic> datos) {
    return '''
Genera un RECURSO DE APELACIÓN formal y completo para un caso penal en Venezuela.

DATOS DEL CASO:
- Número de caso: ${datos['numeroCaso'] ?? 'Por asignar'}
- Tribunal: ${datos['tribunal'] ?? 'Tribunal de Control'}
- Juez: ${datos['juez'] ?? 'Juez de Control'}
- Imputado: ${datos['imputado'] ?? '[NOMBRE DEL IMPUTADO]'}
- Delito(s): ${datos['delitos'] is List ? (datos['delitos'] as List).join(', ') : datos['delitos'] ?? '[DELITOS]'}
- Decisión apelada: ${datos['decisionApelada'] ?? '[DECISIÓN]'}
- Fecha de la decisión: ${datos['fechaDecision'] ?? '[FECHA]'}
- Motivos de apelación: ${datos['motivosApelacion'] ?? '[MOTIVOS]'}

ESTRUCTURA REQUERIDA:
1. ENCABEZAMIENTO (Tribunal superior, identificación partes)
2. IDENTIFICACIÓN DEL RECURRENTE Y REPRESENTACIÓN
3. OBJETO DEL RECURSO (Decisión que se apela)
4. FUNDAMENTOS DE HECHO (Narrativa del caso)
5. FUNDAMENTOS DE DERECHO (Artículos COPP y CP aplicables)
6. DENUNCIAS (Vicios de la decisión):
   - Violación de derechos constitucionales si aplica
   - Errores en la valoración de pruebas
   - Violación del debido proceso
   - Falta de motivación
7. PETITORIO (Lo que se solicita)
8. ANEXOS (Listar documentos)

INSTRUCCIONES:
- Usa lenguaje jurídico formal venezolano
- Cita artículos específicos del COPP (Código Orgánico Procesal Penal)
- Fundamenta en jurisprudencia del TSJ si es relevante
- Estructura clara con secciones numeradas
- Argumentación sólida y convincente
- Máximo 8-10 páginas

GENERA EL RECURSO COMPLETO:''';
  }

  static String _promptEscritoDefensa(Map<String, dynamic> datos) {
    return '''
Genera un ESCRITO DE DEFENSA formal para audiencia preliminar en Venezuela.

DATOS DEL CASO:
- Número de causa: ${datos['numeroCaso'] ?? 'Por asignar'}
- Tribunal: ${datos['tribunal'] ?? 'Tribunal de Control'}
- Juez: ${datos['juez'] ?? 'Juez de Control'}
- Imputado: ${datos['imputado'] ?? '[NOMBRE DEL IMPUTADO]'}
- Delito(s) imputado(s): ${datos['delitos'] is List ? (datos['delitos'] as List).join(', ') : datos['delitos'] ?? '[DELITOS]'}
- Hechos del MP: ${datos['hechos'] ?? '[DESCRIPCIÓN DE LOS HECHOS]'}
- Línea de defensa: ${datos['lineaDefensa'] ?? '[ESTRATEGIA DE DEFENSA]'}

ESTRUCTURA REQUERIDA:
1. ENCABEZAMIENTO
2. IDENTIFICACIÓN DEL IMPUTADO Y DEFENSOR
3. EXPOSICIÓN DE HECHOS (Versión de la defensa)
4. FUNDAMENTACIÓN JURÍDICA:
   - Presunción de inocencia (Art. 49.2 CRBV)
   - Análisis de elementos del delito
   - Vicios en la investigación fiscal
   - Excluyentes de responsabilidad si aplica
5. ANÁLISIS DE PRUEBAS:
   - Pruebas de cargo (debilidades)
   - Pruebas de descargo
6. SOLICITUDES:
   - Desestimación/Sobreseimiento
   - O medida cautelar menos gravosa
7. PETITORIO CONCRETO

INSTRUCCIONES:
- Lenguaje jurídico formal pero persuasivo
- Citar COPP, CP y CRBV específicamente
- Cuestionar pruebas del MP fundamentadamente
- Proponer medidas cautelares alternativas
- Demostrar arraigo y no peligro de fuga
- Máximo 6-8 páginas

GENERA EL ESCRITO COMPLETO:''';
  }

  static String _promptSolicitudLibertad(Map<String, dynamic> datos) {
    return '''
Genera una SOLICITUD DE LIBERTAD O MEDIDA CAUTELAR MENOS GRAVOSA para Venezuela.

DATOS DEL CASO:
- Número de causa: ${datos['numeroCaso'] ?? 'Por asignar'}
- Tribunal: ${datos['tribunal'] ?? 'Tribunal de Control'}
- Imputado: ${datos['imputado'] ?? '[NOMBRE DEL IMPUTADO]'}
- Delito(s): ${datos['delitos'] is List ? (datos['delitos'] as List).join(', ') : datos['delitos'] ?? '[DELITOS]'}
- Tiempo privado de libertad: ${datos['tiempoPrivacion'] ?? '[TIEMPO]'}
- Medida actual: ${datos['medidaActual'] ?? 'Privación judicial preventiva de libertad'}
- Fundamentación: ${datos['fundamentacion'] ?? '[RAZONES PARA SOLICITAR LIBERTAD]'}

ESTRUCTURA REQUERIDA:
1. ENCABEZAMIENTO
2. IDENTIFICACIÓN Y REPRESENTACIÓN
3. FUNDAMENTOS DE HECHO:
   - Situación actual del imputado
   - Condiciones de detención
   - Arraigo familiar, laboral y social
4. FUNDAMENTOS DE DERECHO:
   - Art. 44 CRBV (Libertad personal)
   - Art. 49.2 CRBV (Presunción de inocencia)
   - Arts. 229-242 COPP (Medidas cautelares)
   - Proporcionalidad de la medida
5. DEMOSTRACIÓN DE:
   - Arraigo en la comunidad
   - No peligro de fuga
   - No obstaculización de la investigación
   - Colaboración con la justicia
6. PROPUESTA DE MEDIDAS ALTERNATIVAS:
   - Presentaciones periódicas
   - Prohibición de salida del país
   - Cauciones económicas si aplica
7. PETITORIO ESPECÍFICO

INSTRUCCIONES:
- Énfasis en derechos humanos y constitucionales
- Argumentar presunción de inocencia
- Demostrar que no hay riesgo procesal
- Citar jurisprudencia del TSJ sobre libertad
- Proponer medidas menos gravosas específicas
- Máximo 5-6 páginas

GENERA LA SOLICITUD COMPLETA:''';
  }

  static String _promptOposicionMedidas(Map<String, dynamic> datos) {
    return '''
Genera una OPOSICIÓN A MEDIDAS CAUTELARES solicitadas por el Ministerio Público.

DATOS DEL CASO:
- Número de causa: ${datos['numeroCaso'] ?? 'Por asignar'}
- Tribunal: ${datos['tribunal'] ?? 'Tribunal de Control'}
- Imputado: ${datos['imputado'] ?? '[NOMBRE DEL IMPUTADO]'}
- Delito(s) imputado(s): ${datos['delitos'] is List ? (datos['delitos'] as List).join(', ') : datos['delitos'] ?? '[DELITOS]'}
- Medida solicitada por MP: ${datos['medidaSolicitada'] ?? 'Privación judicial preventiva de libertad'}
- Fundamentación del MP: ${datos['fundamentacionMP'] ?? '[ARGUMENTOS DEL FISCAL]'}

ESTRUCTURA REQUERIDA:
1. ENCABEZAMIENTO
2. OPOSICIÓN EXPRESA a la medida solicitada
3. FUNDAMENTOS DE HECHO:
   - Análisis de los hechos narrados por MP
   - Inconsistencias o debilidades
4. FUNDAMENTOS DE DERECHO:
   - Art. 49.2 CRBV (Presunción de inocencia)
   - Art. 229 COPP (Principio de excepcionalidad)
   - Art. 236-237 COPP (Presupuestos de medidas)
   - Proporcionalidad (Art. 230 COPP)
5. ANÁLISIS DE PRESUPUESTOS:
   - NO existe peligro de fuga porque...
   - NO hay riesgo de obstaculización porque...
   - NO se cumple proporcionalidad porque...
6. DEMOSTRACIÓN:
   - Arraigo sólido (familia, trabajo, vivienda)
   - Voluntad de someterse al proceso
   - Colaboración con investigación
7. PROPUESTA ALTERNATIVA:
   - Medidas cautelares menos gravosas (Art. 242 COPP)
8. PETITORIO

INSTRUCCIONES:
- Argumentar fuertemente contra necesidad de privación
- Cuestionar fundamentación fiscal
- Demostrar que se puede garantizar proceso sin privación
- Citar jurisprudencia sobre excepcionalidad
- Proponer alternativas concretas y viables
- Máximo 5-7 páginas

GENERA LA OPOSICIÓN COMPLETA:''';
  }

  static String _promptDemanda(Map<String, dynamic> datos) {
    return '''
Genera una DEMANDA O ACUSACIÓN PENAL formal para Venezuela.

DATOS DEL CASO:
- Demandante/Víctima: ${datos['demandante'] ?? '[NOMBRE DEL DEMANDANTE]'}
- Demandado/Imputado: ${datos['demandado'] ?? '[NOMBRE DEL DEMANDADO]'}
- Delito(s): ${datos['delitos'] is List ? (datos['delitos'] as List).join(', ') : datos['delitos'] ?? '[DELITOS]'}
- Hechos: ${datos['hechos'] ?? '[DESCRIPCIÓN DETALLADA DE LOS HECHOS]'}
- Pruebas disponibles: ${datos['pruebas'] ?? '[LISTADO DE PRUEBAS]'}

ESTRUCTURA REQUERIDA:
1. ENCABEZAMIENTO
2. IDENTIFICACIÓN DE LAS PARTES
3. OBJETO DE LA DEMANDA
4. EXPOSICIÓN DE HECHOS:
   - Narrativa cronológica clara
   - Detalle de circunstancias relevantes
5. FUNDAMENTACIÓN JURÍDICA:
   - Tipificación del delito (artículos CP)
   - Elementos del tipo penal demostrados
   - Responsabilidad del imputado
6. ANÁLISIS DE PRUEBAS:
   - Pruebas testimoniales
   - Pruebas documentales
   - Pruebas periciales
   - Pruebas materiales
7. DAÑOS Y PERJUICIOS (si aplica)
8. PETITORIO:
   - Declaratoria de responsabilidad penal
   - Pena solicitada
   - Reparación del daño
9. ANEXOS

INSTRUCCIONES:
- Narrativa clara y cronológica de hechos
- Fundamentación legal sólida en CP y COPP
- Relacionar cada prueba con elementos del delito
- Lenguaje formal y técnico
- Argumentación persuasiva y coherente
- Máximo 10-12 páginas

GENERA LA DEMANDA COMPLETA:''';
  }

  static String _promptGenerico(TipoEscrito tipo, Map<String, dynamic> datos) {
    return '''
Genera un ${tipo.nombre.toUpperCase()} formal y completo para un caso penal en Venezuela.

DATOS PROPORCIONADOS:
${datos.entries.map((e) => '- ${e.key}: ${e.value}').join('\n')}

INSTRUCCIONES:
- Usa lenguaje jurídico formal venezolano
- Estructura profesional con secciones claras
- Cita artículos del COPP y CP según corresponda
- Argumentación sólida y fundamentada
- Formato de escrito forense estándar

GENERA EL ESCRITO COMPLETO:''';
  }
}
