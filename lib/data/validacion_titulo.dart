/// Longitud máxima permitida para el título de una tarea.
const int maxLongitudTitulo = 120;

/// Valida el título de una tarea.
///
/// Devuelve `null` si es válido o un mensaje comprensible para el usuario.
/// Se usa tanto en la interfaz (validación inmediata) como en el repositorio
/// (defensa en la capa de datos).
String? validarTitulo(String? valor) {
  final limpio = (valor ?? '').trim();
  if (limpio.isEmpty) {
    return 'El título no puede estar vacío';
  }
  if (limpio.length > maxLongitudTitulo) {
    return 'El título no puede superar $maxLongitudTitulo caracteres';
  }
  return null;
}

/// Devuelve el título normalizado (sin espacios al inicio ni al final).
String normalizarTitulo(String valor) => valor.trim();
