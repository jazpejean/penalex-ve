# Penalex VE — Registro de pendientes

Documento vivo con todo lo que hay que arreglar o mejorar, expuesto por el usuario y detectado en la auditoría. No se cierra un ítem sin verificarlo en el dispositivo real.

**Leyenda de estado:** `abierto` · `en curso` · `hecho` · `descartado`
**Prioridad:** `P0` bloquea demo o concurso · `P1` importante · `P2` mejora

---

## P0 — Bloqueantes para la demo y los concursos

| ID | Área | Problema | Propuesta | Estado |
|---|---|---|---|---|
| APP-01 | Diseño | Cada pantalla usa radios, márgenes y títulos distintos | Tokens `AppTokens` (radio 20 tarjeta / 12 control, margen 20) aplicados a todas | en curso |
| APP-02 | Diseño | Textos invisibles en Prescripción ("Inicio del cómputo", "Interrupción", aviso legal) | Contraste AA sobre `TemaGlobal.texto` | abierto |
| APP-03 | Navegación | "Inicio" y "Buscar" muestran la misma pantalla | Dar a "Buscar" su propio buscador global o fusionar pestañas | abierto |
| APP-04 | Navegación | "Más" abre un drawer lateral, no una pantalla de ajustes | Pantalla "Más" con ajustes, cuenta, ayuda y sistema de diseño | abierto |
| ESC-01 | Escáner | Detector de bordes tosco (`edge_detection` + Canny casero sin perspectiva real) | ML Kit Document Scanner o OpenCV con `warpPerspective` | abierto |
| ESC-02 | Escáner | Solo captura de a una imagen, sin flujo multipágina | Captura consecutiva + galería con selección múltiple | abierto |
| ESC-03 | Escáner | No se pueden reordenar páginas | Arrastrar y soltar en la tira de miniaturas | abierto |
| ESC-04 | Escáner | `CropAdjustScreen` existe pero no se abre desde ningún flujo | Conectarlo después de cada captura | abierto |
| WEB-01 | Web | Iconos emoji y tipografía serif en la UI | Iconos lineales y sans en toda la interfaz | abierto |
| WEB-02 | Web | Diseño distinto a la app | Componentes espejo: ToolCard, SectionTitle, Badge, EmptyState | abierto |
| CON-01 | Concurso | Falta demo grabada del dispositivo real | Video de 2 min con los 9 flujos | abierto |
| CON-02 | Concurso | Faltan métricas y tracción | 10 usuarios, 20 escritos, 3 testimonios | abierto |

---

## App Flutter

### Diseño y consistencia

| ID | Problema | Propuesta | Estado |
|---|---|---|---|
| APP-10 | Iconos de Inicio en gris claro sobre gris claro | Contraste AA en iconos y contenedores | abierto |
| APP-11 | Leyenda del calendario con "Hoy" casi invisible | Color con contraste suficiente | abierto |
| APP-12 | Botón primario dorado en unas pantallas y navy en otras | Un solo color de acción primaria | abierto |
| APP-13 | Títulos de sección en dorado, negro y serif según pantalla | `AppTokens.tituloSeccion` en todas | en curso |
| APP-14 | Drawer con sección "Recursos legales" incompleta | Ordenar y completar el menú | abierto |
| APP-15 | Avatar con inicial gigante y botón de cámara desalineado | Avatar consistente con `photoUrl` | abierto |
| APP-16 | Asistente con guion largo y badge que compite con el título | Microcopy limpio | abierto |
| APP-17 | Versión del drawer dice v1.0 y el paquete es 1.0.0+1 | Unificar versión | abierto |
| APP-18 | Estados vacíos distintos en cada pantalla | Componente `EmptyState` único | abierto |
| APP-19 | Sin modo oscuro coherente | Paleta oscura con los mismos tokens | abierto |
| APP-20 | Sin accesibilidad: escalado de texto, `Semantics`, 48 dp | Auditoría de accesibilidad | abierto |

### Flujos y producto

| ID | Problema | Propuesta | Estado |
|---|---|---|---|
| APP-30 | Sin búsqueda global (sentencias, leyes, glosario) | Un buscador único en la barra inferior | abierto |
| APP-31 | Sin modo offline para leyes y sentencias | Caché local y descarga por ley | abierto |
| APP-32 | Historial y favoritos no se sincronizan con la web | Tabla única y sincronización | abierto |
| APP-33 | Sin notificaciones de audiencias y lapsos | Push con FCM y recordatorios | abierto |
| APP-34 | Escritos no se exportan desde el portafolio | Exportar DOCX y PDF desde el expediente | abierto |
| APP-35 | Sin multi-expediente con pestañas | Cambio rápido de causa activa | abierto |
| APP-36 | Sin roles y permisos | Abogado, juez, administrador | abierto |
| APP-37 | Sin firma electrónica ni sello de tiempo | Firma y sello en documentos | abierto |
| APP-38 | Sin respaldo ni restauración | Backup de expedientes | abierto |

### Portafolio por expediente

| ID | Problema | Propuesta | Estado |
|---|---|---|---|
| POR-01 | El documento no se abría al tocar | Abrir PDF con `PdfExportService` | hecho |
| POR-02 | Sin miniatura real | Mostrar `thumbnail_url` | hecho |
| POR-03 | Sin eliminar documento | Confirmación y borrado | hecho |
| POR-04 | El escáner no quedaba vinculado al expediente | Activar `ExpedienteActivoProvider` antes de abrir | hecho |
| POR-05 | Sin tipos de documento (auto, providencia, prueba, escrito) | Requiere columna `tipo` en `documentos_escaneados` | abierto |
| POR-06 | Sin buscador dentro del portafolio | Filtro por título y fecha | abierto |
| POR-07 | Sin contadores por tipo | Resumen en la cabecera del portafolio | abierto |
| POR-08 | Los escritos del redactor no se asocian al expediente | Falta `expediente_id` en `redactor_conversaciones` | abierto |

---

## Escáner

| ID | Problema | Propuesta | Estado |
|---|---|---|---|
| ESC-10 | Sin captura consecutiva | Flujo "página 1, 2, 3" sin salir | abierto |
| ESC-11 | Sin galería múltiple | `pickMultiImage` | abierto |
| ESC-12 | Sin mejora de imagen (contraste, binarización) | Filtros suaves por página | abierto |
| ESC-13 | Sin tira de miniaturas | Estados por página: pendiente, lista, error | abierto |
| ESC-14 | PDF se arma descargando de Storage | Generar PDF local al instante | abierto |
| ESC-15 | Sin firma y sello | Sello Penalex y firma | abierto |
| ESC-16 | Lectura con visión solo de la página actual | Procesar todas las páginas en cola | abierto |
| ESC-17 | Sin límites de tamaño ni compresión configurable | Calidad y tamaño por página | abierto |
| ESC-18 | Sin cifrado local de documentos sensibles | SQLCipher y borrado seguro | abierto |

---

## Editor de documentos

| ID | Problema | Propuesta | Estado |
|---|---|---|---|
| EDI-01 | Verificado: exporta Word real (.docx) con membrete | Mantener y probar en dispositivo | hecho |
| EDI-02 | Verificado: exporta PDF con membrete | Mantener y probar en dispositivo | hecho |
| EDI-03 | Falta insertar imágenes y páginas escaneadas en el escrito | Insertar desde el portafolio | abierto |
| EDI-04 | Falta plantilla por tipo de escrito | Plantillas de demanda, recurso, solicitud | abierto |
| EDI-05 | Falta autoguardado y versiones | Historial de versiones | abierto |

---

## Web

| ID | Problema | Propuesta | Estado |
|---|---|---|---|
| WEB-10 | Emojis en el dashboard | Iconos lineales (`Icono.tsx`) | en curso |
| WEB-11 | Títulos en serif en la UI | Sans en toda la interfaz | abierto |
| WEB-12 | Radios y botones distintos a la app | Tokens CSS y componentes espejo | abierto |
| WEB-13 | Herramientas IA solo en la app | Marcar claramente o portar Ulpiano | abierto |
| WEB-14 | Falta PWA instalable y offline | Service worker | abierto |
| WEB-15 | Sin deep links a la app | App Links para `/sentencias` | abierto |

---

## Backend y seguridad

| ID | Problema | Propuesta | Estado |
|---|---|---|---|
| BE-01 | Firestore sigue en quiz, glosario, cálculo y roles | Migrar todo a Supabase | abierto |
| BE-02 | Sin rate limiting en el worker | Límite por IP y uid | abierto |
| BE-03 | Sin CORS restringido | Solo `penalexve.com` | abierto |
| BE-04 | Sin CSP ni cabeceras de seguridad | CSP, HSTS, X-Frame-Options | abierto |
| BE-05 | API key web revocada, se usa la de Android | Crear key web restringida por dominio | abierto |
| BE-06 | Sin contratos compartidos | OpenAPI y clientes generados | abierto |
| BE-07 | Sin observabilidad | Sentry en app y web, alertas 5xx | abierto |
| BE-08 | Sin tests E2E de los flujos críticos | Playwright y widget tests | abierto |
| BE-09 | Quiz con banco incompleto y uid de pendientes mal | Completar 3.000 y unificar ruta | abierto |
| BE-10 | RLS no auditada tabla por tabla | Revisión y pruebas de acceso | abierto |

---

## Concursos

| ID | Problema | Propuesta | Estado |
|---|---|---|---|
| CON-10 | Sin pitch de 10 slides | Problema, mercado, producto, demo, tracción, modelo, equipo | abierto |
| CON-11 | Sin métricas reales en el pitch | 55.208 sentencias, 53 leyes, 6.416 artículos, 867 tribunales | abierto |
| CON-12 | Sin roadmap de 6 meses | Alineado a The Next Gen | abierto |
| CON-13 | Sin testimonios de uso | 3 videos de abogados | abierto |

---

## Corregido (para no repetirlo)

| Fecha | Qué | Commit |
|---|---|---|
| 2026-11-20 | Ruta única `/sentencias` con 301 desde `/jurisprudencia` | `42abf79` |
| 2026-11-20 | Subdominio `nulidadabsoluta` eliminado | `42abf79` |
| 2026-11-21 | Firebase inyectado en la web y tolerante a fallos | `8a34be8` |
| 2026-11-21 | Dashboard web con datos reales (Supabase) | `08c4c88` |
| 2026-11-22 | Firestore fuera del perfil, foto y login | `065d013` |
| 2026-11-22 | Tokens de diseño en 34 pantallas | `42abf79` |
| 2026-11-22 | Buscador con título, subtítulo y botón "Buscar" | `250e59d` |
| 2026-11-22 | Filtros visibles TIPO, SALA y PERÍODO | `0d02346` |
| 2026-11-22 | Chat IA estilo DeepSeek | `0d02346` |
| 2026-11-23 | Portafolio: abrir, miniatura, eliminar y vincular escáner | `f79abee` |

---

## Orden de trabajo acordado

1. **P0 de diseño y navegación** (APP-01 a APP-04) porque es lo que ve el jurado.
2. **Escáner** (ESC-01 a ESC-04, ESC-10, ESC-11) para que se sienta CamScanner.
3. **Portafolio** (POR-05 a POR-08) con tipos, búsqueda y escritos asociados.
4. **Web sincronizada** (WEB-01, WEB-02, WEB-10, WEB-12).
5. **Backend y seguridad** (BE-01 a BE-05).
6. **Concursos** (CON-01, CON-02, CON-10).
