import 'package:flutter/material.dart';

import 'data/app_database.dart';
import 'data/tareas_repository.dart';
import 'screens/tareas_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(GestorTareasApp(database: AppDatabase()));
}

/// Punto de entrada de la aplicación.
///
/// La base se crea aquí y se inyecta en la pantalla: así las pruebas pueden
/// usar una base en memoria sin tocar el archivo real del usuario.
class GestorTareasApp extends StatefulWidget {
  const GestorTareasApp({super.key, required this.database});

  final AppDatabase database;

  @override
  State<GestorTareasApp> createState() => _GestorTareasAppState();
}

class _GestorTareasAppState extends State<GestorTareasApp> {
  late final TareasRepository _repositorio =
      TareasRepository(widget.database);

  @override
  void dispose() {
    widget.database.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestor de tareas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: TareasPage(repositorio: _repositorio),
    );
  }
}
