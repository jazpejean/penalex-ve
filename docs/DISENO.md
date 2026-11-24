# Patrón de diseño único de Penalex VE

Todas las secciones deben verse idénticas. Este documento es la regla; si una pantalla se desvía, se corrige.

## Header

Todas las pantallas usan `AppScreenHeader`:

```dart
AppScreenHeader(
  titulo: 'Agenda',
  subtitulo: 'Audiencias, lapsos y días sin despacho',
)
```

| Elemento | Valor |
|---|---|
| Título | 28 px, w700, navy |
| Subtítulo | 13 px, gris secundario |
| Separación | 4 px entre título y subtítulo |
| Acciones | A la derecha, 12 px de separación |
| Padding lateral | 20 px |

## Fondo y márgenes

| Elemento | Valor |
|---|---|
| Fondo | `TemaGlobal.superficie` |
| Padding de pantalla | 20 px laterales |
| Separación entre secciones | 24 px |

## Tarjetas

| Elemento | Valor |
|---|---|
| Radio | 20 (tarjeta) y 12 (control) |
| Borde | 1 px `TemaGlobal.capa` |
| Sombra | Ninguna |
| Padding interno | 16 a 18 px |

## Iconos

| Elemento | Valor |
|---|---|
| Tamaño | 22 a 24 px |
| Color normal | `TemaGlobal.textoSecundario` |
| Color activo | `AppColors.azulMarino` |
| Contenedor | 46 x 46, radio 12, fondo `TemaGlobal.campoTexto` |

## Tipografía

| Nivel | Valor |
|---|---|
| Título de pantalla | 28 / 700 |
| Título de sección | 18 / 700 |
| Título de tarjeta | 17 / 700 |
| Cuerpo | 13.5 a 15 / 400 |
| Texto auxiliar | 11.5 a 13 / 500 a 600 |

## Barra inferior

| Elemento | Valor |
|---|---|
| Fondo | `TemaGlobal.tarjeta` |
| Borde superior | 1 px `TemaGlobal.capa` |
| Altura | 62 |
| Ítems | Inicio, Agenda, Asistente, Buscar, Más |
| Activo | Fondo tenue detrás del icono y texto navy |
| Sombra | Ninguna |

## Reglas que no se rompen

1. Ninguna pantalla sin título visible.
2. Ningún texto blanco sobre fondo claro.
3. Ningún menú hamburguesa duplicado con la barra inferior.
4. Ningún emoji en la interfaz.
5. Ninguna sombra en tarjetas de contenido.
6. Ningún color fuera de `AppColors` y `TemaGlobal`.

## Estado de aplicación

| Sección | Header | Tarjetas | Barra | Estado |
|---|---|---|---|---|
| Inicio | `AppScreenHeader` | Sí | Sí | hecho |
| Agenda | `AppScreenHeader` | Sí | Sí | hecho |
| Consulta | `AppScreenHeader` | Sí | Sí | hecho |
| Dosimetría | Propio | Sí | Sí | pendiente |
| Concurso | Propio | Sí | Sí | pendiente |
| Cómputo | Propio | Sí | Sí | pendiente |
| Asistente | Propio | Sí | Sí | pendiente |
| Buscar | Propio | Sí | Sí | pendiente |
| Prescripción | `AppBarInstitucional` | Sí | Sí | pendiente de alinear |
