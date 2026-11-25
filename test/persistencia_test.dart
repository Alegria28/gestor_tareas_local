import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_local/data/app_database.dart';
import 'package:gestor_tareas_local/data/tareas_repository.dart';

/// Comprueba la persistencia real: los datos deben sobrevivir a cerrar y
/// volver a abrir la base de datos (equivalente a reiniciar la aplicación).
void main() {
  late Directory directorio;
  late File archivo;

  setUp(() async {
    directorio = await Directory.systemTemp.createTemp('gestor_tareas_test_');
    archivo = File('${directorio.path}/gestor_tareas.sqlite');
  });

  tearDown(() async {
    if (await directorio.exists()) {
      await directorio.delete(recursive: true);
    }
  });

  test('las tareas siguen ahí al reabrir la base de datos', () async {
    var db = AppDatabase(NativeDatabase(archivo));
    var repositorio = TareasRepository(db);

    final id = await repositorio.agregarTarea('Sobrevivir al cierre');
    await repositorio.cambiarEstado(id, true);
    await db.close();

    expect(archivo.existsSync(), isTrue);

    db = AppDatabase(NativeDatabase(archivo));
    repositorio = TareasRepository(db);
    final tareas = await repositorio.listarTareas();

    expect(tareas, hasLength(1));
    expect(tareas.single.titulo, 'Sobrevivir al cierre');
    expect(tareas.single.completada, isTrue);

    await db.close();
  });

  test('una eliminación no reaparece al reabrir', () async {
    var db = AppDatabase(NativeDatabase(archivo));
    var repositorio = TareasRepository(db);

    final id = await repositorio.agregarTarea('Efímera');
    await repositorio.eliminarTarea(id);
    await db.close();

    db = AppDatabase(NativeDatabase(archivo));
    repositorio = TareasRepository(db);

    expect(await repositorio.listarTareas(), isEmpty);
    await db.close();
  });
}
