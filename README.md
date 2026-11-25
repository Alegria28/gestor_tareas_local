# Gestor de tareas local con SQLite (Flutter + Drift)

Aplicación Flutter de tareas con persistencia **local** en SQLite. No usa
servidor, API REST ni MySQL: los datos viven en la base de cada instalación.

Práctica de *Programación de Dispositivos Móviles* — UAA.

## Funcionalidades

- Alta de tareas con validación: se rechazan títulos vacíos o solo con espacios.
- Listado reactivo: la lista se actualiza sola después de cada escritura.
- Edición del título conservando el `id`.
- Marcar como completada / pendiente.
- Eliminación por `id`, con confirmación.
- Persistencia tras cerrar y volver a abrir la aplicación.

## Stack

| Componente | Versión |
|---|---|
| Flutter | 3.50.1 (Dart 3.14) |
| `drift` | 2.35.4 |
| `drift_flutter` | 0.3.1 |
| `sqlite3` | 3.9.2 |

`drift_dev` y `build_runner` solo se usan en desarrollo para generar
`lib/data/app_database.g.dart`.

## Arquitectura

```
lib/
├── main.dart                    # inyecta AppDatabase y cierra la base al salir
├── data/
│   ├── app_database.dart        # tabla Tareas + apertura multiplataforma
│   ├── app_database.g.dart      # generado con build_runner (no editar a mano)
│   ├── tareas_repository.dart   # CRUD y stream reactivo
│   └── validacion_titulo.dart   # validación compartida UI / repositorio
└── screens/tareas_page.dart     # StreamBuilder + diálogos
```

Toda consulta pasa por `TareasRepository`. No hay SQL dentro de `build()`.
La pantalla consume `observarTareas()` (`watch()`) mediante `StreamBuilder`, así
que cada `INSERT`, `UPDATE` o `DELETE` refresca la lista sin `setState` manual.

### Tabla `tareas`

Esquema real generado por Drift:

```sql
CREATE TABLE "tareas" (
  "id"         INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  "titulo"     TEXT NOT NULL,
  "completada" INTEGER NOT NULL DEFAULT 0 CHECK ("completada" IN (0, 1)),
  "creada_en"  INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER))
);
```

SQLite no tiene booleano nativo: `completada` es un entero 0/1. El `id` es la
clave que se usa para editar y eliminar.

## Requisitos

- Flutter 3.47 o superior (Dart 3.13+). Verificado con Flutter 3.50.1.
- Para escritorio Linux: `clang`, `cmake`, `ninja-build`, `pkg-config` y las
  librerías de desarrollo de GTK 3.

## Ejecución

```bash
flutter pub get
dart run build_runner build
flutter analyze
flutter test

flutter run -d chrome    # web
flutter run -d linux     # escritorio Linux
```

En Android/iOS basta con `flutter run` sobre un dispositivo o emulador; el
código de persistencia es el mismo.

### Recursos para web

El navegador no puede abrir archivos SQLite del sistema. Drift ejecuta SQLite
compilado a WebAssembly y coordina el acceso con un worker. Por eso `web/`
contiene:

- `sqlite3.wasm` — motor SQLite compilado a wasm.
- `drift_worker.js` — worker de Drift (OPFS/IndexedDB).

Ambos corresponden a la versión 2.35.4 de Drift y se descargaron de
<https://github.com/simolus3/drift/releases/tag/drift-2.35.4>. Al actualizar
`drift` hay que reemplazarlos por los de la versión correspondiente.

El servidor de evidencias envía `Cross-Origin-Opener-Policy: same-origin` y
`Cross-Origin-Embedder-Policy: require-corp` para habilitar OPFS. Sin esas
cabeceras Drift usa IndexedDB como respaldo y la persistencia sigue funcionando.

### ¿Dónde se guardan los datos?

- Android: directorio privado de la app (`/data/data/<paquete>/app_flutter/`).
- iOS/macOS: sandbox de la aplicación.
- Windows/Linux: directorio de documentos del usuario. En Linux, verificado en
  `~/Documents/gestor_tareas.sqlite`.
- Web: almacenamiento del origen (OPFS o IndexedDB). Si se borran los datos del
  sitio o se usa modo incógnito, la base se pierde; `localhost:PUERTO` distinto
  implica otra base.

## Pruebas

```bash
flutter test
```

17 pruebas, todas en verde:

| Archivo | Qué cubre |
|---|---|
| `test/validacion_test.dart` | título vacío, solo espacios, longitud máxima, normalización (5) |
| `test/tareas_repository_test.dart` | alta, cambio de estado, edición, borrado por id y stream reactivo (7) |
| `test/persistencia_test.dart` | los datos sobreviven a cerrar y reabrir el archivo SQLite; una tarea eliminada no reaparece (2) |
| `test/widget_test.dart` | arranque de la interfaz, alta desde la UI y rechazo de título vacío (3) |

Las pruebas usan `NativeDatabase.memory()` o un archivo temporal, nunca la base
real del usuario.

## Comprobación manual (P1–P6)

| ID | Prueba | Web (Chromium) | Linux |
|---|---|---|---|
| P1 | Agregar 3 tareas, cerrar y abrir | pasa | pasa |
| P2 | Marcar completada y reiniciar | pasa | pasa |
| P3 | Editar título y reiniciar | pasa | pasa |
| P4 | Eliminar y reiniciar (no reaparece) | pasa | pasa |
| P5 | Título vacío / solo espacios | pasa | pasa |
| P6 | Recargar y cerrar/abrir pestaña | pasa | n/a |

En web la persistencia se comprobó cerrando la pestaña y abriendo una nueva en
el mismo origen y perfil. En Linux se terminó el proceso y se volvió a lanzar.

## Plataformas

| Plataforma | Estado |
|---|---|
| Web (Chromium 157) | verificada |
| Linux (escritorio) | verificada |
| Android / iOS | previstas: mismo código, requieren SDK/dispositivo |
| Windows / macOS | previstas: mismo código, requieren compilar en su SO |

## Reporte

El reporte de dos páginas está en
[`reporte/reporte.pdf`](reporte/reporte.pdf); su fuente Typst está en
[`reporte/reporte.typ`](reporte/reporte.typ).

## Uso de IA

Se usó un asistente de IA (OpenCode con DeepSeek V4.1 Flash) como apoyo para
implementar el código, diagnosticar errores de dependencias y redactar un
borrador del reporte. El resultado se verificó ejecutando `flutter analyze`,
`flutter test` y las pruebas P1–P6 en web y Linux; los errores encontrados y
corregidos se describen en el reporte.
