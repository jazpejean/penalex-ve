import 'package:supabase_flutter/supabase_flutter.dart';

/// Una condición del Modo Avanzado del Super Buscador (estilo TSJ):
/// "Muestra las sentencias donde [campo] [operador] [valor]".
///
/// Es mutable porque el panel de filtros edita las condiciones en vivo
/// (dropdowns de campo/operador y selector de valor) antes de aplicarlas.
class CondicionBusqueda {
  /// Nombre de la columna en Supabase (ponente, procedimiento, decision…).
  String campo;
  /// 'contiene' | 'no contiene' | 'es' | 'no es'
  String operador;
  String valor;

  CondicionBusqueda({
    required this.campo,
    required this.operador,
    required this.valor,
  });

  /// Copia editable.
  CondicionBusqueda copy() =>
      CondicionBusqueda(campo: campo, operador: operador, valor: valor);

  /// Construye el filtro PostgREST correspondiente (genérico para
  /// conservar el tipo del builder de la consulta).
  PostgrestFilterBuilder<T> aplicar<T>(PostgrestFilterBuilder<T> query) {
    final v = valor.trim();
    switch (operador) {
      case 'contiene':
        return query.ilike(campo, '%$v%');
      case 'no contiene':
        return query.not(campo, 'ilike', '%$v%');
      case 'es':
        return query.eq(campo, v);
      case 'no es':
        return query.neq(campo, v);
      default:
        return query.ilike(campo, '%$v%');
    }
  }
}