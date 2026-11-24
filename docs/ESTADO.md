# Estado de Penalex VE

Resumen de lo implementado en las sesiones automáticas. Lo que falta depende de ver la app en el teléfono o de una decisión de producto.

## Verificación

| Prueba | Resultado |
|---|---|
| `flutter analyze lib/` | sin issues |
| Tests de diseño | 11 de 11 |
| Tests del escáner | 3 de 3 (detector 2, binarización 1) |

## Escáner

| Ítem | Estado |
|---|---|
| Cámara propia con detección de bordes en vivo | hecho |
| Detector de bordes en Dart puro | hecho, con tests |
| Binarización adaptativa Sauvola por página | hecho, con test |
| Captura multipágina y galería múltiple | hecho |
| Reordenar páginas | hecho |
| Tira de miniaturas | hecho |
| Recorte con corrección de perspectiva y botón de aplicar | hecho |
| Filtros por página: original, gris, documento | hecho |
| Compresión al importar | hecho |
| PDF local con sello y línea de firma | hecho |
| Transcripción de todas las páginas | hecho |
| Borrado seguro de temporales | hecho |
| Cifrado en reposo | pendiente, requiere clave del usuario |

## Interfaz

| Ítem | Estado |
|---|---|
| Header único en secciones principales | hecho |
| AppBar secundarias alineado | hecho |
| Márgenes de 20 y radios de 20 | hecho |
| Barra inferior clara | hecho |
| Buscador global en el Inicio | hecho |
| Acciones rápidas Consultar, Redactar, Escanear | hecho |
| Estado vacío único | hecho |
| Botón primario unificado en navy | hecho |
| Versión del drawer unificada | hecho |
| Modo oscuro | conectado, coherencia pendiente en pantalla |

## Leyes

| Ítem | Estado |
|---|---|
| Nombre completo en lista y buscador | hecho |
| Títulos de libro y capítulo completos | hecho |
| Lectura sin conexión | hecho |
| Títulos con notas derogatorias corregidos | hecho |
| 18 leyes no penales eliminadas de Supabase | hecho |

## Notificaciones

| Ítem | Estado |
|---|---|
| Recordatorio de audiencia el día anterior | hecho |
| Recordatorio de prescripción | hecho |
| Lapsos del expediente | pendiente |

## Pendiente por dispositivo

- Ver en pantalla la cámara con overlay, el modo oscuro y la uniformidad final.
- Instalar el APK y capturar cada sección.

## Pendiente por decisión

- Cifrado en reposo de los documentos. Necesita definir dónde vive la clave del usuario.
- Provider de detección de bordes si se quiere cubrir dispositivos sin Google Play Services.
