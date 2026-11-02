import 'package:supabase_flutter/supabase_flutter.dart';

/// Una condición del Modo Avanzado del Super Buscador (estilo TSJ):
/// "Muestra las sentencias donde [campo] [operador] [valor/es]".
///
/// Replica la referencia del TSJ (online viewer):
///  - El campo es un select con badge "lista" y descripción.
///  - El operador cambia solo según cuántos valores haya:
///      • 1 valor  → "es" / "no es"
///      • 2+ valores → "es cualquiera de" / "no es ninguno de"
///  - El valor es una lista buscable con conteos y casillas (multiselección).
///
/// Es mutable porque el panel edita las condiciones en vivo.
class CondicionBusqueda {
  /// Nombre de la columna en Supabase (ponente, procedimiento, decision…).
  String campo;

  /// 'es' | 'no es' | 'contiene' | 'no contiene'. Para los campos con
  /// lista (ponente, materia, decisión…) solo se usan es/no es; la etiqueta
  /// mostrada cambia sola según la cantidad de valores.
  String operador;

  /// Valores seleccionados (1..n). Para campos de lista es la multiselección;
  /// para Nº de sentencia es un único valor de texto.
  List<String> valores;

  CondicionBusqueda({
    required this.campo,
    required this.operador,
    List<String>? valores,
  }) : valores = valores ?? [];

  /// Etiqueta legible del operador según la cantidad de valores (TSJ:
  /// "La etiqueta del operador cambia sola…").
  String get etiquetaOperador {
    if (valores.length > 1) {
      return operador == 'no es' ? 'no es ninguno de' : 'es cualquiera de';
    }
    return operador;
  }

  bool get esNegacion => operador == 'no es' || operador == 'no contiene';

  /// Construye el filtro PostgREST correspondiente (genérico para
  /// conservar el tipo del builder de la consulta).
  PostgrestFilterBuilder<T> aplicar<T>(PostgrestFilterBuilder<T> query) {
    final vivos = valores.map((v) => v.trim()).where((v) => v.isNotEmpty).toList();
    if (vivos.isEmpty) return query;

    switch (operador) {
      case 'es':
        // 1 valor → eq; varios → "es cualquiera de" (IN).
        return vivos.length == 1 ? query.eq(campo, vivos.first) : query.inFilter(campo, vivos);
      case 'no es':
        // 1 valor → neq; varios → "no es ninguno de" (NOT IN).
        return vivos.length == 1
            ? query.neq(campo, vivos.first)
            : query.not(campo, 'in', '(${vivos.join(',')})');
      case 'contiene':
        return query.ilike(campo, '%${vivos.first}%');
      case 'no contiene':
        return query.not(campo, 'ilike', '%${vivos.first}%');
      default:
        return query.ilike(campo, '%${vivos.first}%');
    }
  }
}