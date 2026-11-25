#set page(
  paper: "a4",
  margin: (x: 1.7cm, y: 1.35cm),
  numbering: "1/2",
)
#set text(font: "DejaVu Serif", size: 9.3pt, lang: "es")
#set par(justify: true, leading: 0.48em)
#set heading(numbering: "1.")
#show heading: set text(size: 11pt)
#show link: set text(fill: rgb("#1a3d7c"))
#set table(stroke: 0.4pt + luma(170), inset: 3pt)

#align(center)[
  #text(size: 13.5pt, weight: "bold")[Práctica: gestor de tareas con SQLite local]
  #linebreak()
  #text(size: 8.8pt)[Eduardo Alegria · Programación de Dispositivos Móviles · UAA · 24/11/2026]
  #linebreak()
  #text(size: 8.3pt)[Repositorio: #link("https://github.com/Alegria28/gestor_tareas_local")[github.com/Alegria28/gestor_tareas_local]]
]

= Implementación y capa de persistencia

La aplicación usa *Flutter* con *Drift* sobre SQLite. Elegí Drift porque una sola
API cubre Android, iOS, escritorio y web mediante `drift_flutter`, genera
consultas tipadas en tiempo de compilación y ofrece consultas reactivas; con
`sqlite3` puro habría que escribir y mantener el SQL y el mapeo a mano. No hay
servidor, API REST ni MySQL: la base es local a cada instalación.

La persistencia está aislada en `lib/data/`:

- `AppDatabase` declara la tabla y abre la base con `driftDatabase(name:
  'gestor_tareas')`: en nativo resuelve la ruta con `path_provider`; en web usa
  `DriftWebOptions` con `sqlite3.wasm` y `drift_worker.js`.
- `TareasRepository` concentra el CRUD y la validación (títulos vacíos o solo
  con espacios se rechazan antes de escribir). Devuelve `Future` para las
  escrituras y un `Stream` con `watch()` para la lectura.
- `TareasPage` consume ese stream con `StreamBuilder`, así que cada `INSERT`,
  `UPDATE` o `DELETE` refresca la lista sin `setState` manual. No hay SQL dentro
  de `build()`. Los errores se capturan y se muestran en un `SnackBar`; la base
  se cierra en `dispose()`.

#table(
  columns: (auto, 1fr, 1fr),
  align: (left, left, left),
  [*Columna*], [*Tipo SQLite*], [*Restricción*],
  [`id`], [INTEGER], [PRIMARY KEY AUTOINCREMENT],
  [`titulo`], [TEXT], [NOT NULL (validación de 1–120 caracteres en la app)],
  [`completada`], [INTEGER], [NOT NULL DEFAULT 0, CHECK (0, 1)],
  [`creada_en`], [INTEGER], [NOT NULL, fecha actual por defecto],
)

SQLite no tiene booleano: `completada` se guarda como 0/1 y Drift lo expone como
`bool`. El `id` es la clave que usan la edición y la eliminación. La app cumple
las funciones F1–F8: alta, consulta persistente, edición, cambio de estado,
borrado por id, funcionamiento sin conexión, diseño multiplataforma y manejo de
errores/recursos.

= Dificultad técnica

La dificultad principal apareció en las pruebas de widget. Los tres tests
fallaban con `A Timer is still pending even after the widget tree was
disposed`, aunque la interfaz funcionaba. Al ejecutar un solo test con
`flutter test test/widget_test.dart --plain-name ...`, la traza apuntaba a
`StreamQueryStore.markAsClosed` de Drift: al cancelar la suscripción de
`watch()` durante el desmontaje, Drift programa un `Timer` de duración cero para
cerrar el store, y el binding de pruebas verifica que no queden timers antes de
que ese callback se ejecute. La hipótesis fue que no era un fallo de la app sino
del ciclo de vida del test.

Para verificarlo desmonté el árbol dentro del propio test
(`pumpWidget(SizedBox())`) y avancé el reloj con `pump(Duration(seconds: 5))`
antes de que el framework hiciera su limpieza; el error desapareció. Dejé ese
desmontaje explícito en los tres tests y documenté el motivo. Resultado:
`flutter test` con 17/17 pruebas en verde y `flutter analyze` sin issues.

También fue necesario resolver una incompatibilidad de dependencias: Flutter
3.41.9 fija `meta 1.17.0`, mientras que el `drift_dev` actual exige `meta
^1.18` a través del analyzer. En vez de forzar un `dependency_overrides`,
actualicé la SDK a Flutter 3.50.1 (Dart 3.14), que es la versión con la que se
verificó todo el proyecto.

= Plataformas y resultados P1–P6

#table(
  columns: (auto, 1fr, auto, auto),
  align: (center, left, center, center),
  [*ID*], [*Acción*], [*Web*], [*Linux*],
  [P1], [Agregar 3 tareas y cerrar/abrir], [Pasa], [Pasa],
  [P2], [Marcar completada y reiniciar], [Pasa], [Pasa],
  [P3], [Editar título y reiniciar], [Pasa], [Pasa],
  [P4], [Eliminar y reiniciar], [Pasa], [Pasa],
  [P5], [Intentar título vacío], [Pasa], [Pasa],
  [P6], [Recargar y cerrar/abrir pestaña], [Pasa], [No aplica],
)

*Web:* compilación release servida con `Cross-Origin-Opener-Policy:
same-origin` y `Cross-Origin-Embedder-Policy: require-corp` en Chromium 157.
Se cerró la pestaña y se abrió una nueva en el mismo origen y perfil; las tareas
siguieron ahí. *Linux:* binario release, se terminó el proceso y se lanzó de
nuevo; la base quedó en `~/Documents/gestor_tareas.sqlite` y se comprobó con
`sqlite3` que las filas y el estado eran los esperados.

#figure(
  image("evidencia-linux.png", width: 62%),
  caption: [Linux: las tres tareas siguen ahí después de terminar el proceso y volver a abrir la app.],
)

*Limitaciones:* no ejecuté Android, iOS, Windows ni macOS porque no hay SDK de
Android, Mac ni Windows en el equipo; el código está diseñado para esas
plataformas con `drift_flutter`, pero solo verifico web y Linux. La interfaz es
sencilla a propósito: la aclaración de la práctica indica que no se califica el
diseño visual.

= Fuentes consultadas

- Drift, documentación general: #link("https://drift.simonbinder.eu/")[drift.simonbinder.eu] — aprendí a declarar tablas en Dart, generar el esquema y usar `watch()` para consultas reactivas.
- Drift en web: #link("https://drift.simonbinder.eu/platforms/web/")[drift.simonbinder.eu/platforms/web] — confirmé que `sqlite3.wasm` y `drift_worker.js` deben bajarse de la *misma* release de Drift y que OPFS requiere cabeceras COOP/COEP.
- `drift_flutter`: #link("https://pub.dev/packages/drift_flutter")[pub.dev/packages/drift_flutter] — verifiqué que `driftDatabase` elige la ruta nativa y permite configurar los recursos web.
- Releases de Drift 2.35.4: #link("https://github.com/simolus3/drift/releases/tag/drift-2.35.4")[github.com/simolus3/drift/releases] — de aquí descargué los binarios compatibles con el `pubspec.lock`.
- Releases de sqlite3.dart: #link("https://github.com/simolus3/sqlite3.dart/releases")[github.com/simolus3/sqlite3.dart/releases] — comprobé que el wasm se publica por versión de `sqlite3`.
- Flutter, SQLite local: #link("https://docs.flutter.dev/cookbook/persistence/sqlite")[docs.flutter.dev/cookbook/persistence/sqlite] — repasé el flujo mínimo de apertura y consulta sin servidor.
- Flutter, testing: #link("https://docs.flutter.dev/testing/overview")[docs.flutter.dev/testing/overview] — ubiqué el alcance de las pruebas de widget y el uso de bases en memoria.
- SQLite, tipos de datos: #link("https://www.sqlite.org/datatype3.html")[sqlite.org/datatype3.html] — confirmé que no existe un tipo booleano nativo.

= Uso de inteligencia artificial

Utilicé OpenCode con el modelo DeepSeek V4.1 Flash como apoyo para implementar el
código, diagnosticar los errores de dependencias y de pruebas, y redactar un
borrador de este reporte. Verifiqué el resultado ejecutando `flutter analyze`,
`flutter test` y las pruebas P1–P6 en web y Linux, revisando además la base con
`sqlite3`. Los errores que la IA introdujo o no previó fueron el conflicto
`meta`/`analyzer` y el timer de Drift en los tests; ambos se corrigieron y se
explican arriba. El código y las decisiones se revisaron antes de entregar.
