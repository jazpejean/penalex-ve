# Integración app y web

Regla del proyecto: **toda funcionalidad y todo dato deben estar accesibles desde la app y desde la web**. No hay funciones de una sola plataforma salvo las que dependen del hardware (cámara, escáner, notificaciones locales).

## Dónde vive cada cosa

| Capa | Responsabilidad |
|---|---|
| Supabase | Datos: sentencias, leyes, doctrinas, expedientes, perfiles |
| Qdrant | Vectores: sentencias, artículos, doctrinas |
| Worker | Único lugar con la clave de IA. La app y la web llaman al mismo endpoint |
| App Flutter | Consumo, cámara, escáner, notificaciones locales |
| Web Next.js | Consumo, SEO, lectura y escritura |

La clave de DeepSeek **nunca** va al cliente. Toda función de IA pasa por el worker.

## Brechas actuales

| Función de la app | En la web | Estado |
|---|---|---|
| Buscador de jurisprudencia con filtros | Solo búsqueda semántica | pendiente |
| Orden recientes y antiguas | No existe | pendiente |
| Fecha exacta | No existe | pendiente |
| Distintivo de jurisprudencia | No se muestra | pendiente |
| Buscador por idea (IA) | No existe | pendiente |
| Resumen completo en ventana | No existe | pendiente |
| Copiar, compartir y guardar artículo | No existe | pendiente |
| Guardados del usuario | No existe | pendiente |
| Escáner y cámara | No aplica (hardware) | excluido |
| Notificaciones locales | No aplica (se usan push web) | excluido |

## Regla para nuevas funciones

1. Si toca datos, va por Supabase o por el worker. Nunca lógica duplicada.
2. Si usa IA, el prompt vive en el worker y ambas plataformas lo consumen.
3. Si el usuario guarda algo (favoritos, notas), se guarda en Supabase con su `uid` para que se vea en las dos.
4. Si es hardware (cámara, escáner), solo app, y la web ofrece subir el archivo ya escaneado.
