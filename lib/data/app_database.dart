import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Tabla de tareas.
///
/// SQLite no tiene un tipo booleano nativo: Drift guarda `completada` como
/// INTEGER (0/1). El id es INTEGER PRIMARY KEY AUTOINCREMENT, por lo que es
/// único y estable durante toda la vida del registro.
@DataClassName('Tarea')
class Tareas extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get titulo => text().withLength(min: 1, max: 120)();

  BoolColumn get completada => boolean().withDefault(const Constant(false))();

  DateTimeColumn get creadaEn => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Tareas])
class AppDatabase extends _$AppDatabase {
  /// Permite inyectar un ejecutor distinto en pruebas (por ejemplo
  /// `NativeDatabase.memory()`); en producción se usa el archivo persistente.
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _abrirBase());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _abrirBase() {
    return driftDatabase(
      name: 'gestor_tareas',
      // En web no hay sistema de archivos: SQLite se ejecuta como
      // WebAssembly y el worker coordina el acceso desde el navegador.
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  }
}
