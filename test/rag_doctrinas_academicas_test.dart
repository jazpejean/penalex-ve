import 'package:flutter_test/flutter_test.dart';
import 'package:penalex_ve/services/rag_service.dart';

void main() {
  group('RAGService · doctrina académica', () {
    test('construirContextoDoctrinasAcademicas formatea autor, obra y página', () {
      final contexto = RAGService.construirContextoDoctrinasAcademicas([
        {
          'autor': 'Eugenio Zaffaroni',
          'obra': 'Tratado de Derecho Penal',
          'pagina': 'p. 452',
          'parrafo_evidencia':
              'La culpabilidad exige un juicio de reproche dirigido al autor.',
          'sentencia_id': 'ABC-123',
        },
      ]);

      expect(contexto, contains('DOCTRINA ACADÉMICA 1'));
      expect(contexto, contains('Autor: Eugenio Zaffaroni'));
      expect(contexto, contains('Obra: Tratado de Derecho Penal'));
      expect(contexto, contains('Página: p. 452'));
      expect(contexto, contains('La culpabilidad exige un juicio de reproche'));
      expect(contexto, contains('Sentencia origen: ABC-123'));
    });

    test('no inventa ni autor ni obra cuando faltan (marca "(no indicado)")', () {
      final contexto = RAGService.construirContextoDoctrinasAcademicas([
        {'autor': '', 'obra': '', 'pagina': '', 'parrafo_evidencia': ''},
      ]);

      expect(contexto, contains('Autor: (no indicado)'));
      expect(contexto, contains('Obra: (no indicada)'));
      // Sin página ni evidencia: no debe emitir "Página:" vacío.
      expect(contexto.contains('Página: '), isFalse);
    });

    test('lista vacía → contexto vacío (no rompe el RAG)', () {
      expect(RAGService.construirContextoDoctrinasAcademicas([]), isEmpty);
    });

    test('recorta la evidencia larga a 700 caracteres', () {
      final largo = 'x' * 900;
      final contexto = RAGService.construirContextoDoctrinasAcademicas([
        {'parrafo_evidencia': largo},
      ]);
      // La evidencia se corta a 700 + '...' (el bloque cierra con comillas).
      expect(contexto.contains('x' * 900), isFalse);
      expect(contexto.trim(), endsWith('..."'));
      // El bloque completo (etiquetas + evidencia recortada) queda por debajo
      // de la evidencia original en longitud.
      expect(contexto.length, lessThan(900));
    });

    test('construirFuentesDoctrinasAcademicas genera fuentes citables', () {
      final fuentes = RAGService.construirFuentesDoctrinasAcademicas([
        {
          'autor': 'Luis Cova S.',
          'obra': 'Derecho Procesal Penal',
          'pagina': 'p. 210',
          'parrafo_evidencia': 'El imputado tiene derecho a defensa.',
          'sentencia_id': 'XYZ-456',
        },
      ]);

      expect(fuentes, hasLength(1));
      expect(fuentes.first.title, 'Luis Cova S. — Derecho Procesal Penal');
      expect(fuentes.first.reference, contains('p. 210'));
      expect(fuentes.first.reference, contains('XYZ-456'));
      expect(fuentes.first.excerpt, contains('derecho a defensa'));
    });
  });
}