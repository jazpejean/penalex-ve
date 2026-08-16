import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Script para poblar la colección de glosario en Firebase
class PopulateGlosario {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Lista completa de términos del glosario jurídico venezolano
  static const List<Map<String, String>> terminos = [
    {'termino': 'Abogado', 'definicion': 'Profesional del derecho que asesora, representa y defiende a las partes en un proceso judicial.'},
    {'termino': 'Absolución', 'definicion': 'Declaración judicial que libera a una persona de la responsabilidad penal por el hecho imputado.'},
    {'termino': 'Acción penal', 'definicion': 'Facultad del Estado o de la víctima para promover la persecución penal y solicitar el castigo del culpable.'},
    {'termino': 'Acusado', 'definicion': 'Persona contra quien se ha presentado formalmente acusación en el proceso penal.'},
    {'termino': 'Admisión de hechos', 'definicion': 'Procedimiento especial en el que el imputado admite los hechos objeto de la acusación, obteniendo rebaja de pena (Art. 375 COPP).'},
    {'termino': 'Agravante', 'definicion': 'Circunstancia que aumenta la responsabilidad penal y, en consecuencia, la pena a imponer (Art. 77 CP).'},
    {'termino': 'Apelación', 'definicion': 'Recurso mediante el cual se solicita la revisión de una sentencia ante un tribunal superior.'},
    {'termino': 'Arresto domiciliario', 'definicion': 'Medida cautelar que obliga al imputado a permanecer en su domicilio durante el proceso penal.'},
    {'termino': 'Atenuante', 'definicion': 'Circunstancia que disminuye la responsabilidad penal y permite rebajar la pena (Art. 74 CP).'},
    {'termino': 'Audiencia', 'definicion': 'Acto procesal en el que las partes comparecen ante el juez para exponer sus alegatos y pruebas.'},
    {'termino': 'Casación', 'definicion': 'Recurso extraordinario que se interpone ante la Sala de Casación Penal del TSJ para impugnar sentencias por vicios de derecho.'},
    {'termino': 'Causa probable', 'definicion': 'Fundamento razonable que permite creer que se ha cometido un delito y que determinada persona es el autor.'},
    {'termino': 'Coautor', 'definicion': 'Persona que participa directamente en la ejecución del delito junto con otros (Art. 83 CP).'},
    {'termino': 'Cómplice', 'definicion': 'Persona que coopera en la ejecución del delito sin ser autor directo (Art. 84 CP).'},
    {'termino': 'Concurso ideal', 'definicion': 'Situación en la que una sola acción constituye varios delitos. Se aplica la pena del delito más grave (Art. 98 CP).'},
    {'termino': 'Concurso real', 'definicion': 'Situación en la que una persona comete varios delitos independientes. La pena es la del delito más grave aumentada con parte de las demás (Art. 88 CP).'},
    {'termino': 'Condena', 'definicion': 'Pronunciamiento judicial que declara culpable a una persona e impone una pena.'},
    {'termino': 'COPP', 'definicion': 'Código Orgánico Procesal Penal venezolano, ley que regula el procedimiento en materia penal.'},
    {'termino': 'Culpa', 'definicion': 'Forma de responsabilidad en que el resultado dañoso se produce por imprudencia, negligencia o impericia, sin intención de causarlo.'},
    {'termino': 'Defensor público', 'definicion': 'Abogado designado por el Estado para representar a quienes no pueden pagar defensa privada.'},
    {'termino': 'Delito', 'definicion': 'Conducta típica, antijurídica y culpable sancionada con una pena.'},
    {'termino': 'Delito continuado', 'definicion': 'Varias violaciones de la misma disposición legal bajo una misma resolución criminal, consideradas un solo delito (Art. 99 CP).'},
    {'termino': 'Derecho a la defensa', 'definicion': 'Garantía constitucional que asegura que toda persona pueda ser asistida por un abogado durante el proceso.'},
    {'termino': 'Desistimiento', 'definicion': 'Abandono voluntario de la ejecución del delito antes de su consumación.'},
    {'termino': 'Detención', 'definicion': 'Privación de libertad de una persona por orden judicial o en flagrancia.'},
    {'termino': 'Dolo', 'definicion': 'Intención deliberada de cometer un delito con conocimiento de su ilicitud.'},
    {'termino': 'Dosimetría penal', 'definicion': 'Proceso técnico-jurídico de individualización judicial de la pena, determinando su quantum exacto.'},
    {'termino': 'Debido proceso', 'definicion': 'Conjunto de garantías procesales que aseguran un juicio justo y equitativo.'},
    {'termino': 'Estado de necesidad', 'definicion': 'Causa de justificación cuando se lesiona un bien jurídico para salvar otro de mayor o igual valor ante peligro inminente.'},
    {'termino': 'Excusa absolutoria', 'definicion': 'Circunstancia que, sin excluir la antijuridicidad, exime de pena al autor del delito.'},
    {'termino': 'Expediente', 'definicion': 'Conjunto de actuaciones y documentos que conforman un proceso judicial.'},
    {'termino': 'Fiscal del Ministerio Público', 'definicion': 'Autoridad encargada de dirigir la investigación penal y ejercer la acción penal pública.'},
    {'termino': 'Flagrancia', 'definicion': 'Situación en la que el autor es sorprendido en el momento de cometer el delito o inmediatamente después.'},
    {'termino': 'Frustración', 'definicion': 'El delito se realiza pero no produce el resultado por causas ajenas al autor (Art. 80 CP).'},
    {'termino': 'Homicidio', 'definicion': 'Delito que consiste en causar la muerte de otra persona (Arts. 405-422 CP).'},
    {'termino': 'Imputabilidad', 'definicion': 'Capacidad de una persona para comprender la ilicitud de su acto y actuar conforme a esa comprensión.'},
    {'termino': 'Imputado', 'definicion': 'Persona a quien se atribuye la comisión de un delito durante la fase de investigación.'},
    {'termino': 'In dubio pro reo', 'definicion': 'Principio según el cual la duda favorece al acusado.'},
    {'termino': 'Inhabilitación', 'definicion': 'Pena accesoria que priva al condenado del ejercicio de ciertos derechos o funciones públicas.'},
    {'termino': 'Juicio oral', 'definicion': 'Fase del proceso penal donde se practican las pruebas y se debate ante el juez de forma pública y oral.'},
    {'termino': 'Jurisprudencia', 'definicion': 'Conjunto de sentencias que crean doctrina judicial y orientan la interpretación de la ley.'},
    {'termino': 'Legítima defensa', 'definicion': 'Causa de justificación que exime de responsabilidad a quien repele una agresión ilegítima, actual o inminente (Art. 65 CP).'},
    {'termino': 'Libertad condicional', 'definicion': 'Beneficio que permite al condenado cumplir parte de su pena en libertad bajo ciertas condiciones.'},
    {'termino': 'Medida cautelar', 'definicion': 'Restricción provisional impuesta al imputado para asegurar su comparecencia al juicio.'},
    {'termino': 'Ministerio Público', 'definicion': 'Órgano del Estado encargado de la acción penal y defensa de la legalidad.'},
    {'termino': 'Non bis in idem', 'definicion': 'Principio que prohíbe juzgar dos veces a una persona por el mismo hecho.'},
    {'termino': 'Pena', 'definicion': 'Sanción jurídica impuesta por el Estado al autor de un delito.'},
    {'termino': 'Pena accesoria', 'definicion': 'Sanción adicional que acompaña a la pena principal (inhabilitaciones, sujeciones, etc.).'},
    {'termino': 'Prescripción', 'definicion': 'Extinción de la acción penal o de la pena por el transcurso del tiempo.'},
    {'termino': 'Presidio', 'definicion': 'Pena privativa de libertad que se cumple en penitenciaría (Arts. 9-10 CP).'},
    {'termino': 'Presunción de inocencia', 'definicion': 'Principio fundamental que obliga a tratar al imputado como inocente hasta que se pruebe su culpabilidad.'},
    {'termino': 'Prisión', 'definicion': 'Pena privativa de libertad que se cumple en establecimiento penitenciario (Arts. 9-10 CP).'},
    {'termino': 'Prisión preventiva', 'definicion': 'Medida cautelar excepcional que priva de libertad al imputado durante el proceso.'},
    {'termino': 'Prueba', 'definicion': 'Medio utilizado para demostrar la verdad de los hechos en el proceso penal.'},
    {'termino': 'Querella', 'definicion': 'Acto mediante el cual la víctima ejerce la acción penal en delitos de acción dependiente de instancia de parte.'},
    {'termino': 'Reincidencia', 'definicion': 'Circunstancia agravante que se configura cuando el condenado comete un nuevo delito después de cumplir condena anterior.'},
    {'termino': 'Sentencia', 'definicion': 'Decisión definitiva del tribunal que resuelve el fondo del asunto penal.'},
    {'termino': 'Sobreseimiento', 'definicion': 'Resolución judicial que pone fin al proceso sin condena, por causas legales específicas.'},
    {'termino': 'Suspensión condicional de la ejecución de la pena', 'definicion': 'Beneficio que permite al condenado no cumplir la pena en establecimiento carcelario bajo ciertas condiciones.'},
    {'termino': 'Tentativa', 'definicion': 'Comienzo de ejecución del delito que no llega a consumarse por causas ajenas a la voluntad del autor (Art. 82 CP).'},
    {'termino': 'Término medio', 'definicion': 'Punto de partida para la individualización de la pena, calculado como la semisuma entre el mínimo y máximo del marco penal (Art. 37 CP).'},
    {'termino': 'Testigo', 'definicion': 'Persona que declara sobre hechos que ha percibido directamente y que son relevantes para el proceso.'},
    {'termino': 'Tipo penal', 'definicion': 'Descripción legal y abstracta de una conducta prohibida y sancionada por la ley penal.'},
    {'termino': 'Tribunal de Control', 'definicion': 'Órgano judicial que controla la fase preparatoria y decide sobre medidas cautelares.'},
    {'termino': 'Tribunal de Juicio', 'definicion': 'Órgano judicial encargado de realizar el juicio oral y dictar sentencia.'},
    {'termino': 'TSJ', 'definicion': 'Tribunal Supremo de Justicia, máxima instancia del Poder Judicial venezolano.'},
    {'termino': 'Víctima', 'definicion': 'Persona directamente ofendida por el delito o sus familiares en caso de muerte.'},
  ];

  /// Pobla la colección de glosario en Firebase
  static Future<void> populate() async {
    try {
      debugPrint('🔄 Iniciando población del glosario...');
      
      int exitosos = 0;
      int fallidos = 0;

      for (final termino in terminos) {
        try {
          await _firestore.collection('glosario').add({
            'termino': termino['termino'],
            'definicion': termino['definicion'],
            'createdAt': FieldValue.serverTimestamp(),
          });
          exitosos++;
          debugPrint('✅ Agregado: ${termino['termino']}');
        } catch (e) {
          fallidos++;
          debugPrint('❌ Error con ${termino['termino']}: $e');
        }
      }

      debugPrint('');
      debugPrint('========================================');
      debugPrint('📊 RESUMEN DE POBLACIÓN');
      debugPrint('========================================');
      debugPrint('✅ Términos agregados: $exitosos');
      debugPrint('❌ Errores: $fallidos');
      debugPrint('📝 Total procesados: ${terminos.length}');
      debugPrint('========================================');
      
    } catch (e, stack) {
      debugPrint('❌ Error fatal poblando glosario: $e');
      debugPrint('Stack: $stack');
      rethrow;
    }
  }

  /// Limpia la colección de glosario (usar con precaución)
  static Future<void> clear() async {
    try {
      debugPrint('🗑️ Limpiando colección de glosario...');
      
      final snapshot = await _firestore.collection('glosario').get();
      
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
      
      debugPrint('✅ Glosario limpiado. ${snapshot.docs.length} documentos eliminados.');
    } catch (e) {
      debugPrint('❌ Error limpiando glosario: $e');
      rethrow;
    }
  }
}
