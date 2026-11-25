import 'package:drift/drift.dart';

import 'app_database.dart';
import 'validacion_titulo.dart';

/// Acceso a la tabla `tareas`. Toda la interfaz pasa por aquí: no hay SQL
/// dentro de los widgets ni dentro de `build()`.
class TareasRepository {
  TareasRepository(this._db);

  final AppDatabase _db;

  /// Emite la lista cada vez que cambia la tabla. Al ser un `Stream`, la
  /// interfaz se actualiza sola después de cada escritura.
  Stream<List<Tarea>> observarTareas() {
    final consulta = _db.select(_db.tareas)
      ..orderBy([
        (t) => OrderingTerm(expression: t.creadaEn),
        (t) => OrderingTerm(expression: t.id),
      ]);
    return consulta.watch();
  }

  Future<List<Tarea>> listarTareas() {
    final consulta = _db.select(_db.tareas)
      ..orderBy([
        (t) => OrderingTerm(expression: t.creadaEn),
        (t) => OrderingTerm(expression: t.id),
      ]);
    return consulta.get();
  }

  /// Inserta una tarea y devuelve el id generado por SQLite.
  ///
  /// Lanza [TituloInvalido] si el título está vacío o solo tiene espacios.
  Future<int> agregarTarea(String titulo) {
    final limpio = normalizarTitulo(titulo);
    final error = validarTitulo(limpio);
    if (error != null) {
      throw TituloInvalido(error);
    }
    return _db.into(_db.tareas).insert(
          TareasCompanion.insert(titulo: limpio),
        );
  }

  /// Cambia el estado completada/pendiente.
  Future<bool> cambiarEstado(int id, bool completada) async {
    final filas = await (_db.update(_db.tareas)
          ..where((t) => t.id.equals(id)))
        .write(TareasCompanion(completada: Value(completada)));
    return filas > 0;
  }

  /// Modifica el título conservando el id. Devuelve `false` si la tarea ya no
  /// existe.
  Future<bool> editarTitulo(int id, String nuevoTitulo) {
    final limpio = normalizarTitulo(nuevoTitulo);
    final error = validarTitulo(limpio);
    if (error != null) {
      throw TituloInvalido(error);
    }
    return _editar(id, limpio);
  }

  Future<bool> _editar(int id, String titulo) async {
    final filas = await (_db.update(_db.tareas)
          ..where((t) => t.id.equals(id)))
        .write(TareasCompanion(titulo: Value(titulo)));
    return filas > 0;
  }

  /// Elimina por id. Devuelve cuántas filas se borraron.
  Future<int> eliminarTarea(int id) {
    return (_db.delete(_db.tareas)..where((t) => t.id.equals(id))).go();
  }

  Future<void> cerrar() => _db.close();
}

/// Error de validación que la interfaz puede mostrar al usuario.
class TituloInvalido implements Exception {
  const TituloInvalido(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}
