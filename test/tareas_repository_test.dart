import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_local/data/app_database.dart';
import 'package:gestor_tareas_local/data/tareas_repository.dart';

void main() {
  late AppDatabase db;
  late TareasRepository repositorio;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repositorio = TareasRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('agregar guarda el título sin espacios y asigna un id', () async {
    final id = await repositorio.agregarTarea('  Comprar leche  ');

    final tareas = await repositorio.listarTareas();
    expect(tareas, hasLength(1));
    expect(tareas.single.id, id);
    expect(tareas.single.titulo, 'Comprar leche');
    expect(tareas.single.completada, isFalse);
  });

  test('agregar rechaza títulos vacíos y no escribe en la base', () async {
    expect(
      () => repositorio.agregarTarea('   '),
      throwsA(isA<TituloInvalido>()),
    );

    expect(await repositorio.listarTareas(), isEmpty);
  });

  test('cambiarEstado actualiza solo la tarea indicada', () async {
    final primera = await repositorio.agregarTarea('Primera');
    await repositorio.agregarTarea('Segunda');

    final actualizada = await repositorio.cambiarEstado(primera, true);
    expect(actualizada, isTrue);

    final tareas = await repositorio.listarTareas();
    expect(tareas.firstWhere((t) => t.id == primera).completada, isTrue);
    expect(tareas.firstWhere((t) => t.id != primera).completada, isFalse);
  });

  test('editarTitulo conserva el id y el estado', () async {
    final id = await repositorio.agregarTarea('Título viejo');
    await repositorio.cambiarEstado(id, true);

    final actualizada = await repositorio.editarTitulo(id, ' Título nuevo ');
    expect(actualizada, isTrue);

    final tarea = (await repositorio.listarTareas()).single;
    expect(tarea.id, id);
    expect(tarea.titulo, 'Título nuevo');
    expect(tarea.completada, isTrue);
  });

  test('editarTitulo rechaza títulos vacíos', () async {
    final id = await repositorio.agregarTarea('Original');

    expect(
      () => repositorio.editarTitulo(id, '  '),
      throwsA(isA<TituloInvalido>()),
    );
    expect((await repositorio.listarTareas()).single.titulo, 'Original');
  });

  test('eliminarTarea borra por id y devuelve las filas afectadas', () async {
    final id = await repositorio.agregarTarea('Se va');
    await repositorio.agregarTarea('Se queda');

    expect(await repositorio.eliminarTarea(id), 1);
    expect(await repositorio.eliminarTarea(id), 0);

    final tareas = await repositorio.listarTareas();
    expect(tareas.map((t) => t.titulo), ['Se queda']);
  });

  test('observarTareas emite la lista actualizada tras una escritura', () async {
    final emisiones = <List<Tarea>>[];
    final suscripcion = repositorio.observarTareas().listen(emisiones.add);

    await repositorio.agregarTarea('Reactiva');
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(emisiones, isNotEmpty);
    expect(emisiones.last.single.titulo, 'Reactiva');

    await suscripcion.cancel();
  });
}
