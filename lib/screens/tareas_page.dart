import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../data/tareas_repository.dart';
import '../data/validacion_titulo.dart';

class TareasPage extends StatefulWidget {
  const TareasPage({super.key, required this.repositorio});

  final TareasRepository repositorio;

  @override
  State<TareasPage> createState() => _TareasPageState();
}

class _TareasPageState extends State<TareasPage> {
  final TextEditingController _tituloController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  /// El stream se crea una sola vez; crearlo en `build()` abriría una consulta
  /// nueva por cada reconstrucción de la interfaz.
  late final Stream<List<Tarea>> _tareas = widget.repositorio.observarTareas();

  bool _guardando = false;

  @override
  void dispose() {
    _tituloController.dispose();
    super.dispose();
  }

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Future<void> _agregarTarea() async {
    if (_guardando) return;
    final error = validarTitulo(_tituloController.text);
    if (error != null) {
      _mostrarMensaje(error);
      return;
    }

    setState(() => _guardando = true);
    try {
      await widget.repositorio.agregarTarea(_tituloController.text);
      _tituloController.clear();
      _mostrarMensaje('Tarea guardada');
    } on TituloInvalido catch (e) {
      _mostrarMensaje(e.mensaje);
    } catch (e) {
      _mostrarMensaje('No se pudo guardar la tarea: $e');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _alternarCompletada(Tarea tarea, bool completada) async {
    try {
      final actualizada = await widget.repositorio.cambiarEstado(
        tarea.id,
        completada,
      );
      if (!actualizada) {
        _mostrarMensaje('La tarea ya no existe');
      }
    } catch (e) {
      _mostrarMensaje('No se pudo actualizar el estado: $e');
    }
  }

  Future<void> _editarTarea(Tarea tarea) async {
    final nuevoTitulo = await showDialog<String>(
      context: context,
      builder: (context) => _EditarTareaDialog(tituloActual: tarea.titulo),
    );
    if (nuevoTitulo == null) return;

    try {
      final actualizada = await widget.repositorio.editarTitulo(
        tarea.id,
        nuevoTitulo,
      );
      _mostrarMensaje(
        actualizada ? 'Título actualizado' : 'La tarea ya no existe',
      );
    } on TituloInvalido catch (e) {
      _mostrarMensaje(e.mensaje);
    } catch (e) {
      _mostrarMensaje('No se pudo editar la tarea: $e');
    }
  }

  Future<void> _eliminarTarea(Tarea tarea) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar tarea'),
        content: Text('¿Eliminar «${tarea.titulo}»? Esta acción no se puede '
            'deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    try {
      final filas = await widget.repositorio.eliminarTarea(tarea.id);
      _mostrarMensaje(
        filas > 0 ? 'Tarea eliminada' : 'La tarea ya no existe',
      );
    } catch (e) {
      _mostrarMensaje('No se pudo eliminar la tarea: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestor de tareas')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _tituloController,
                maxLength: maxLongitudTitulo,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _agregarTarea(),
                validator: validarTitulo,
                decoration: const InputDecoration(
                  labelText: 'Nueva tarea',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _guardando ? null : _agregarTarea,
              icon: const Icon(Icons.add),
              label: const Text('Agregar tarea'),
            ),
            const SizedBox(height: 12),
            const Text('Mis tareas', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<List<Tarea>>(
                stream: _tareas,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'No se pudieron leer las tareas: ${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final tareas = snapshot.data!;
                  if (tareas.isEmpty) {
                    return const Center(
                      child: Text('Todavía no hay tareas guardadas'),
                    );
                  }

                  return ListView.builder(
                    itemCount: tareas.length,
                    itemBuilder: (context, index) {
                      final tarea = tareas[index];
                      return Card(
                        child: ListTile(
                          leading: Checkbox(
                            value: tarea.completada,
                            onChanged: (valor) {
                              if (valor != null) {
                                _alternarCompletada(tarea, valor);
                              }
                            },
                          ),
                          title: Text(
                            tarea.titulo,
                            style: tarea.completada
                                ? const TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                  )
                                : null,
                          ),
                          subtitle: Text(
                            'ID: ${tarea.id} · '
                            '${tarea.completada ? 'Completada' : 'Pendiente'}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Editar',
                                icon: const Icon(Icons.edit),
                                onPressed: () => _editarTarea(tarea),
                              ),
                              IconButton(
                                tooltip: 'Eliminar',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _eliminarTarea(tarea),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditarTareaDialog extends StatefulWidget {
  const _EditarTareaDialog({required this.tituloActual});

  final String tituloActual;

  @override
  State<_EditarTareaDialog> createState() => _EditarTareaDialogState();
}

class _EditarTareaDialogState extends State<_EditarTareaDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.tituloActual);
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _guardar() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(_controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar título'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          maxLength: maxLongitudTitulo,
          validator: validarTitulo,
          onFieldSubmitted: (_) => _guardar(),
          decoration: const InputDecoration(
            labelText: 'Título',
            border: OutlineInputBorder(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _guardar,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
