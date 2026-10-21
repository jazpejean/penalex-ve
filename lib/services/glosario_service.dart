import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GlosarioService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Carga los términos aprobados desde Supabase (tabla `glosario_terminos`).
  ///
  /// Devuelve lista con 'term', 'definition' y, si existe, 'reference'
  /// (ley — artículo de la definición legal). Ante cualquier error devuelve []
  /// (los llamadores usan la lista local como respaldo).
  static Future<List<Map<String, String>>> cargarDesdeSupabase() async {
    try {
      final supabase = Supabase.instance.client;
      final res = await supabase
          .from('glosario_terminos')
          .select('termino, definicion, referencias')
          .eq('aprobado', true)
          .order('termino', ascending: true);
      final rows = (res as List<dynamic>).cast<Map<String, dynamic>>();
      final out = <Map<String, String>>[];
      for (final row in rows) {
        final termino = (row['termino'] ?? '').toString().trim();
        final definicion = (row['definicion'] ?? '').toString().trim();
        if (termino.isEmpty || definicion.isEmpty) continue;
        final refs = (row['referencias'] as List<dynamic>?) ?? const [];
        final ref = refs.isNotEmpty ? refs.first.toString() : '';
        out.add({
          'term': termino,
          'definition': definicion,
          if (ref.isNotEmpty) 'reference': ref,
        });
      }
      debugPrint('📚 Glosario cargado desde Supabase: ${out.length} términos');
      return out;
    } catch (e) {
      debugPrint('❌ Error cargando glosario desde Supabase: $e');
      return [];
    }
  }

  /// Obtiene todos los términos del glosario desde Firebase
  static Future<List<Map<String, String>>> getTerminos() async {
    try {
      debugPrint('📚 Cargando términos del glosario desde Firebase...');
      
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection('glosario')
          .orderBy('termino', descending: false)
          .get();

      if (snapshot.docs.isEmpty) {
        debugPrint('⚠️ No se encontraron términos en la colección "glosario"');
        return [];
      }

      final List<Map<String, String>> terminos = snapshot.docs.map((doc) {
        final data = doc.data();
        return <String, String>{
          'term': data['termino'] as String? ?? '',
          'definition': data['definicion'] as String? ?? '',
        };
      }).toList();

      debugPrint('✅ ${terminos.length} términos cargados exitosamente');
      return terminos;
      
    } on FirebaseException catch (e) {
      debugPrint('❌ FirebaseException al cargar glosario: ${e.code} - ${e.message}');
      return [];
    } catch (e, stack) {
      debugPrint('❌ Error al cargar glosario: $e');
      debugPrint('Stack: $stack');
      return [];
    }
  }

  /// Stream de términos en tiempo real
  static Stream<List<Map<String, String>>> getTerminosStream() {
    try {
      return _firestore
          .collection('glosario')
          .orderBy('termino', descending: false)
          .snapshots()
          .map((snapshot) {
            if (snapshot.docs.isEmpty) {
              debugPrint('⚠️ Stream vacío: No hay términos en glosario');
              return <Map<String, String>>[];
            }
            
            return snapshot.docs.map((doc) {
              final data = doc.data();
              return <String, String>{
                'term': data['termino'] as String? ?? '',
                'definition': data['definicion'] as String? ?? '',
              };
            }).toList();
          });
    } catch (e) {
      debugPrint('❌ Error creando stream de glosario: $e');
      return Stream.value([]);
    }
  }

  /// Agrega un término al glosario (para uso administrativo)
  static Future<void> agregarTermino(String termino, String definicion) async {
    try {
      await _firestore.collection('glosario').add({
        'termino': termino,
        'definicion': definicion,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Término "$termino" agregado al glosario');
    } catch (e) {
      debugPrint('❌ Error agregando término: $e');
      rethrow;
    }
  }

  /// Carga términos de respaldo (si Firebase falla)
  static List<Map<String, String>> getTerminosRespaldo() {
    return const <Map<String, String>>[
      <String, String>{'term': 'Abogado', 'definition': 'Profesional del derecho que asesora, representa y defiende a las partes en un proceso judicial.'},
      <String, String>{'term': 'Absolución', 'definition': 'Declaración judicial que libera a una persona de la responsabilidad penal por el hecho imputado.'},
      <String, String>{'term': 'Acción penal', 'definition': 'Facultad del Estado o de la víctima para promover la persecución penal y solicitar el castigo del culpable.'},
      <String, String>{'term': 'Agravante', 'definition': 'Circunstancia que aumenta la responsabilidad penal y, en consecuencia, la pena a imponer.'},
      <String, String>{'term': 'Atenuante', 'definition': 'Circunstancia que disminuye la responsabilidad penal y permite rebajar la pena.'},
      <String, String>{'term': 'Delito', 'definition': 'Conducta típica, antijurídica y culpable sancionada con una pena.'},
      <String, String>{'term': 'Dolo', 'definition': 'Intención deliberada de cometer un delito con conocimiento de su ilicitud.'},
      <String, String>{'term': 'Culpa', 'definition': 'Forma de responsabilidad en que el resultado dañoso se produce por imprudencia, negligencia o impericia, sin intención de causarlo.'},
      <String, String>{'term': 'Imputado', 'definition': 'Persona a quien se atribuye la comisión de un delito durante la fase de investigación.'},
      <String, String>{'term': 'Juicio oral', 'definition': 'Fase del proceso penal donde se practican las pruebas y se debate ante el juez de forma pública y oral.'},
      <String, String>{'term': 'Legítima defensa', 'definition': 'Causa de justificación que exime de responsabilidad a quien repele una agresión ilegítima, actual o inminente.'},
      <String, String>{'term': 'Pena', 'definition': 'Sanción jurídica impuesta por el Estado al autor de un delito.'},
      <String, String>{'term': 'Presidio', 'definition': 'Pena privativa de libertad que se cumple en penitenciaría con obligación de trabajos forzados.'},
      <String, String>{'term': 'Prisión', 'definition': 'Pena privativa de libertad que se cumple en establecimiento penitenciario, sin obligación de trabajos forzados.'},
      <String, String>{'term': 'Presunción de inocencia', 'definition': 'Principio fundamental que obliga a tratar al imputado como inocente hasta que se pruebe su culpabilidad.'},
      <String, String>{'term': 'Sentencia', 'definition': 'Decisión definitiva del tribunal que resuelve el fondo del asunto penal.'},
      <String, String>{'term': 'Tentativa', 'definition': 'Comienzo de ejecución del delito que no llega a consumarse por causas ajenas a la voluntad del autor.'},
      <String, String>{'term': 'Víctima', 'definition': 'Persona directamente ofendida por el delito o sus familiares en caso de muerte.'},
    ];
  }
}
