// Calibración: imprime los tokens distintivos de artículos clave del CP
// para ajustar los umbrales del validador con datos reales.
// Uso: dart tool/calibrar_tokens.dart
import 'dart:convert';
import 'dart:io';

import '../lib/services/quiz_validador_service.dart';

void main() {
  final ley = QuizValidadorService.cargarLey(
    jsonDecode(File('tool/corpus/codigo-penal.json').readAsStringSync())
        as Map<String, dynamic>,
    'codigo-penal.json',
  );
  print('CP: ${ley.articulos.length} artículos\n');

  for (final num in ['1', '37', '74', '84', '405', '453', '454', '457', '88']) {
    final arts = ley.articulos.where((a) => a.numero == num).toList();
    if (arts.isEmpty) {
      print('Art. $num: NO EXISTE');
      continue;
    }
    final a = arts.first;
    final d = QuizValidadorService.tokensDistintivos(ley, a);
    print('Art. $num (${d.length} distintivos): ${d.take(12).join(', ')}');
    print('   texto: ${a.texto.substring(0, a.texto.length > 110 ? 110 : a.texto.length)}...');
    print('');
  }
}