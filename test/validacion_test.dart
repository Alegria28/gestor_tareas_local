import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_local/data/validacion_titulo.dart';

void main() {
  group('validarTitulo', () {
    test('acepta un título normal', () {
      expect(validarTitulo('Estudiar para el examen'), isNull);
    });

    test('rechaza cadena vacía', () {
      expect(validarTitulo(''), 'El título no puede estar vacío');
    });

    test('rechaza títulos compuestos solo por espacios', () {
      expect(validarTitulo('    '), 'El título no puede estar vacío');
    });

    test('rechaza títulos demasiado largos', () {
      final largo = 'a' * (maxLongitudTitulo + 1);
      expect(
        validarTitulo(largo),
        'El título no puede superar $maxLongitudTitulo caracteres',
      );
    });
  });

  test('normalizarTitulo elimina espacios de los extremos', () {
    expect(normalizarTitulo('  Comprar leche  '), 'Comprar leche');
  });
}
