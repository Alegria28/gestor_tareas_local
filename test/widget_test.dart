import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_local/data/app_database.dart';
import 'package:gestor_tareas_local/data/tareas_repository.dart';
import 'package:gestor_tareas_local/main.dart';

/// Drift programa un `Timer` de duración cero al cancelar un stream. Si el
/// árbol se desmonta automáticamente al terminar el test, ese timer queda
/// pendiente y `flutter_test` falla. Desmontamos y avanzamos el reloj aquí.
Future<void> _desmontar(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 5));
}

void main() {
  testWidgets('La pantalla inicial se muestra sin errores', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(GestorTareasApp(database: db));
    await tester.pumpAndSettle();

    expect(find.text('Gestor de tareas'), findsOneWidget);
    expect(find.text('Agregar tarea'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('Todavía no hay tareas guardadas'), findsOneWidget);

    await _desmontar(tester);
  });

  testWidgets('agrega una tarea desde la interfaz y la muestra en la lista',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final repositorio = TareasRepository(db);
    await tester.pumpWidget(GestorTareasApp(database: db));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'Regar las plantas');
    await tester.tap(find.text('Agregar tarea'));
    await tester.pumpAndSettle();

    expect(find.text('Regar las plantas'), findsOneWidget);
    expect(await repositorio.listarTareas(), hasLength(1));

    await _desmontar(tester);
  });

  testWidgets('no registra un título vacío', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final repositorio = TareasRepository(db);
    await tester.pumpWidget(GestorTareasApp(database: db));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), '   ');
    await tester.tap(find.text('Agregar tarea'));
    await tester.pumpAndSettle();

    expect(find.text('El título no puede estar vacío'), findsOneWidget);
    expect(await repositorio.listarTareas(), isEmpty);

    await _desmontar(tester);
  });
}
