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

## Dosimetría

| ID | Problema | Propuesta | Estado |
|---|---|---|---|
| DOS-01 | No existía la complicidad correspectiva del art. 424 | Grado "Complicidad Correspectiva", renombrado y con el mismo patrón de cálculo que los demás grados | hecho |
| DOS-02 | El rango del art. 424 no se mostraba completo | Slider de 1/3 a 1/2 que fija la fracción aplicada | hecho |
| DOS-09 | El slider del delito continuado tenía puntos desigualmente espaciados | Slider por índices: paradas equiespaciadas y valores intactos (1/6, 1/4, 1/3, 1/2) | hecho |
| DOS-08 | Texto del art. 424 verificado en la web | Dos apartes completos, sin punto inicial, con el segundo aparte sobre el cooperador inmediato | hecho |
| DOS-03 | Sin prueba del cálculo con un caso real | Caso de prueba: homicidio con dos intervinientes no identificados | abierto |
| DOS-05 | Orden de aplicación del art. 424 | Se mantiene el mismo orden que el resto de los grados (paso de participación) | hecho |
| DOS-06 | El art. 424 se podía elegir en cualquier delito | Advertencia visible cuando el delito no es de muerte o lesiones (implementada) | hecho |
| DOS-07 | El art. 424 excluye al cooperador inmediato | Verificar que el selector no permita combinarlos (hoy son excluyentes) | hecho |
| DOS-04 | Sin exportar el cálculo a PDF | Exportar la dosimetría con el detalle de pasos | abierto |

---

## Leyes y contenido legal

| ID | Problema | Propuesta | Estado |
|---|---|---|---|
| LEY-01 | En la web los artículos salían en un solo párrafo | `white-space: pre-line` en el cuerpo, verificado en producción | hecho |
| LEY-02 | El art. 424 empezaba con un punto suelto | Limpieza de puntuación inicial en el render, verificada | hecho |
| LEY-09 | Espacios antes de coma y dobles espacios | 25 leyes corregidas en los datos de R2, con verificación de conteo y de la web | hecho |
| LEY-10 | El dato del art. 424 empezaba con punto | Corregido en el JSON de R2, no solo en el render | hecho |
| LEY-11 | Quedan 36 puntos sin espacio y 29 minúsculas tras punto | Reporte con texto completo y casilla para validar | abierto |
| LEY-03 | Sin auditoría ortográfica del corpus (53 leyes) | Auditoría completa ejecutada con texto y error marcado | hecho |
| LEY-04 | Sin revisión de artículos con texto vacío o truncado | Detectados artículos cortos y dos leyes que no cargan | abierto |
| LEY-06 | Se creyó que dos leyes no cargaban | **Descartado**: las leyes cargan bien en la web y en la app. Fue una descarga incompleta del script de auditoría | descartado |
| LEY-07 | 43 minúsculas tras punto y 46 puntos sin espacio | Revisión manual asistida (pueden ser abreviaturas legítimas) | abierto |
| LEY-08 | 8 comillas y 14 paréntesis sin cerrar | Revisión manual artículo por artículo | abierto |
| LEY-05 | Sin control de versiones de la ley (reformas) | Campo de vigencia y fecha de reforma | abierto |

---

## Roles y adaptación de la IA

La idea es que el usuario declare su rol y que la IA, las herramientas y el tono se adapten a su función.

| ID | Problema | Propuesta | Estado |
|---|---|---|---|
| ROL-01 | La IA responde igual a un fiscal, un defensor, un juez y un estudiante | Perfil profesional del usuario | abierto |
| ROL-02 | Sin rol declarado, el resultado es genérico | Selección de rol en el registro y en ajustes | abierto |
| ROL-03 | El detector no distingue la posición procesal | El rol define qué vicios son útiles (defensa vs fiscalía) | abierto |
| ROL-04 | El redactor no cambia el enfoque | Plantillas y prompts por rol | abierto |
| ROL-05 | Sin pruebas de rol en la base | Columna `perfil_profesional` en `user_profiles` (DDL) | abierto |
| ROL-06 | El estudiante necesita explicación, no estrategia | Modo "académico" con fundamento y citas | abierto |
| ROL-07 | El juez necesita neutralidad | Modo "análisis neutral" sin estrategia de parte | abierto |

**Roles propuestos y efecto en la IA:**

| Rol | Enfoque | Herramientas destacadas |
|---|---|---|
| Abogado defensor | Estrategia de defensa, garantías, vicios | Detector de vicios, redactor, prescripción |
| Fiscal | Tipicidad, elementos del delito, prueba | Dosimetría, jurisprudencia, análisis de prueba |
| Juez | Neutralidad, motivación, congruencia | Análisis neutral, dosimetría, nulidades |
| Estudiante | Explicación, fundamento, citas | Glosario, jurisprudencia, quiz |
| Asistente judicial | Gestión de causas y lapsos | Agenda, lapsos, portafolio |

**Implementación sin fricción:**
1. El rol se elige una vez y se puede cambiar.
2. El rol se envía en cada consulta a Ulpiano y al detector.
3. El prompt del sistema cambia según el rol.
4. Las herramientas en el panel se reordenan por rol.
5. Todo queda guardado en el perfil y se sincroniza con la web.

---

## Colecciones de sentencias (favoritos del usuario)

El usuario crea sus propias colecciones, con el nombre que quiera: "Homicidio", "Tráfico", "Nulidades", "Para el caso Pérez". Se comporta como guardar en una colección en redes sociales, no como una lista fija de temas.

| ID | Problema | Propuesta | Estado |
|---|---|---|---|
| COL-01 | Los favoritos son una lista plana sin organización | Colecciones creadas por el usuario, con nombre y color | abierto |
| COL-02 | No se puede guardar una sentencia en una colección | Hoja "Guardar en..." con colecciones y opción "Nueva colección" | abierto |
| COL-03 | Sin botón de guardar en el resumen y en el detalle | Marcador en la tarjeta y en la vista de la sentencia | abierto |
| COL-04 | Sin vista de colecciones con portada y contador | Tarjetas de colección con nombre, número y miniaturas | abierto |
| COL-05 | Sin renombrar, eliminar ni cambiar color | Menú de la colección | abierto |
| COL-06 | Sin mover una sentencia de una colección a otra | Acción "Mover a..." | abierto |
| COL-07 | Sin sincronización entre app y web | Mismas tablas y RLS | abierto |
| COL-08 | Una sentencia puede estar en varias colecciones | Tabla puente, sin duplicados | abierto |
| COL-09 | Riesgo de filtrar colecciones entre usuarios | RLS por `user_id = auth.uid()` | abierto |
| COL-10 | Los favoritos actuales quedarían huérfanos | Migrar a una colección "Favoritos" por defecto | abierto |

**Experiencia propuesta:**
1. En el detalle o en el resumen, tocar el marcador.
2. Se abre una hoja con las colecciones del usuario, su contador y "Nueva colección".
3. Escribir el nombre, elegir color y guardar.
4. En el perfil, sección "Mis colecciones" con portada, contador y filtro.

---

## Caché y ahorro de IA

| ID | Problema | Propuesta | Estado |
|---|---|---|---|
| CAC-01 | Cada resumen de sentencia vuelve a llamar a la IA | Respuesta precalculada por `documento_id` + tipo de resumen | abierto |
| CAC-02 | Sin caché de respuestas de texto | Tabla `ia_cache` con hash del prompt, modelo y versión | abierto |
| CAC-03 | Sin caché en el borde | Cloudflare KV para lecturas instantáneas | abierto |
| CAC-04 | Sin precalentado de lo más consultado | CRON que genera resúmenes de las sentencias top | abierto |
| CAC-05 | Sin caché local en la app | Hive o SQLite para leyes y sentencias descargadas | abierto |
| CAC-06 | Sin caché HTTP/CDN por ruta | ETag y `cache-control` por tipo de contenido | abierto |
| CAC-07 | Sin caché de imágenes | Miniaturas y fotos de tribunales con CDN | abierto |
| CAC-08 | Sin métricas de acierto | Hit rate y ahorro estimado en el panel | abierto |
| CAC-09 | Sin invalidación por versión de prompt | `version_prompt` en la clave | abierto |
| CAC-10 | Animación de "pensando" sin criterio | Latencia simulada breve (300 a 700 ms) y texto honesto | abierto |
| CAC-11 | Riesgo de devolver caché de un usuario a otro | Las respuestas con datos del expediente se cachean por uid; solo las públicas se comparten | abierto |

### Diseño de la caché de IA

**Clave:** `sha256(prompt_normalizado + modelo + version_prompt + idioma + longitud)`

**Flujo:**
1. El worker normaliza el prompt y calcula la clave.
2. Consulta KV (milisegundos). Si hay acierto, devuelve.
3. Si no, consulta `ia_cache` en Supabase.
4. Si no, llama a DeepSeek, guarda en `ia_cache` y en KV.
5. Devuelve con la animación de carga breve.

**Precalculado:** al indexar una sentencia se genera su resumen y se guarda con clave `resumen:{documento_id}:v1`. La primera consulta del usuario ya es instantánea.

**Latencia simulada:** 300 a 700 ms con el texto "Recuperando análisis" en lugar de "Calculando desde cero". Se siente ágil y no miente al usuario.

---

## Anexo SQL propuesto

```sql
-- Colecciones del usuario
create table if not exists public.colecciones (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  nombre text not null,
  descripcion text,
  color text not null default '#C5A059',
  creado_en timestamptz not null default now(),
  unique (user_id, nombre)
);

-- Sentencias dentro de cada colección
create table if not exists public.coleccion_sentencias (
  coleccion_id uuid not null references public.colecciones(id) on delete cascade,
  documento_id text not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  agregado_en timestamptz not null default now(),
  primary key (coleccion_id, documento_id)
);

create index if not exists coleccion_sentencias_user_idx
  on public.coleccion_sentencias (user_id);

alter table public.colecciones enable row level security;
alter table public.coleccion_sentencias enable row level security;

create policy "colecciones_propias" on public.colecciones
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "coleccion_sentencias_propias" on public.coleccion_sentencias
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Migración de los favoritos actuales a una colección "Favoritos"
insert into public.colecciones (user_id, nombre)
select distinct user_id, 'Favoritos' from public.sentencias_favoritas
on conflict do nothing;
```

---

## Auditoría del corpus

Reporte completo con el texto de cada artículo y el error marcado: [docs/auditoria-leyes.md](auditoria-leyes.md)

| Tipo de hallazgo | Casos |
|---|---|
| Empieza con signo de puntuación | 0 (corregido en datos) |
| Espacio antes de coma o punto | 0 (corregido en datos) |
| Doble espacio | 0 (corregido en datos) |
| Punto seguido de mayúscula sin espacio | 36 (revisión manual) |
| Minúscula después de punto | 29 (revisión manual) |

El detector excluye abreviaturas conocidas (Dr., Sr., art., Nº, etc.) y números.

Corregidos automáticamente en el render: puntuación inicial, espacio antes de puntuación, doble espacio y saltos excesivos.

Pendientes de validación del usuario: los 196 casos del reporte, con casilla para marcar si es correcto o error.

---

## Banco de estilos y modelos de escritos

| ID | Problema | Propuesta | Estado |
|---|---|---|---|
| EST-01 | Hay 124 modelos convertidos a texto en `ejemplos_estilos/` (14 categorías) | Inventariados y sanitizados | hecho |
| EST-02 | Hay 241 documentos originales en `ejemplos/` (12 MB) | Fuente de los modelos | hecho |
| EST-03 | La app **no usa** los modelos: `assets/estilos/` solo tiene el manifest y `pubspec.yaml` no declara la carpeta | Empaquetarlos o descargarlos de Storage | abierto |
| EST-04 | Supabase Storage `estilos` solo tiene 13 objetos, no los 124 | Subir los 124 con la estructura del manifest | abierto |
| EST-05 | R2 no tiene estilos | Decidir si van a R2 o a Supabase Storage | abierto |
| EST-06 | El manifest no lleva tipo de escrito ni metadatos | Añadir categoría, tipo y etiquetas por modelo | abierto |
| EST-07 | El redactor no ofrece "usar plantilla" | Selector de categoría y modelo dentro del redactor | abierto |
| EST-08 | Sin prueba de que el modelo se use para el estilo | Generar un escrito con y sin modelo y comparar | abierto |

**Inventario verificado:**

| Categoría | Modelos |
|---|---|
| ARCHIVOS IMPORTANTES | 39 |
| PODER PENAL REVOCATORIO | 20 |
| nuevos formato | 15 |
| ACUERDO REPARATORIO | 11 |
| SOLICITUDES DE ACUERDO REPARATORIO | 9 |
| Raíz (sentencias reales) | 7 |
| CONTESTACIONES PENALES | 4 |
| CAUCIÓN JURATORIA | 4 |
| SOLICITUD DE DECAIMIENTO | 4 |
| INSPECCIÓN JUDICIAL | 3 |
| MEDIDA CAUTELAR SUSTITUTIVA | 3 |
| CONSIGNACIÓN DE FIADORES | 2 |
| SOLICITUD DE TRASLADO MÉDICO | 2 |
| ARCHIVO JUDICIAL | 1 |
| **Total** | **124** |

**Dónde están hoy:**
- Local: `ejemplos_estilos/` (2 MB) y `ejemplos/` (12 MB)
- Supabase Storage `estilos`: 13 objetos
- R2: ninguno
- App: solo `assets/estilos/manifest.json`, sin los textos

---

## Producto de primer nivel

Lo que falta y no está en las secciones anteriores. Son las cosas que un abogado espera de una herramienta que usa todos los días y por las que paga.

### Confianza y cumplimiento

| ID | Problema | Propuesta | Prioridad |
|---|---|---|---|
| PROD-01 | Sin términos, privacidad ni consentimiento de datos | Páginas legales y aceptación en el registro | P0 |
| PROD-02 | Sin registro de accesos | Auditoría de quién abrió, exportó o compartió un expediente | P0 |
| PROD-03 | Sin PIN ni biometría para datos sensibles | Bloqueo de la app y de los expedientes | P1 |
| PROD-04 | Sin política de retención ni borrado | Borrado de cuenta y de datos con confirmación | P1 |

### Productividad jurídica

| ID | Problema | Propuesta | Prioridad |
|---|---|---|---|
| PROD-10 | Sin plantillas de escritos | Plantillas por tipo: demanda, recurso, solicitud, amparo | P0 |
| PROD-11 | Sin versiones de documentos | Historial de versiones y comparación lado a lado | P1 |
| PROD-12 | Sin colaboración | Compartir expediente con un colega con permisos (ver, editar) | P1 |
| PROD-13 | Sin notas internas | Notas por documento y por expediente, visibles solo para el equipo | P1 |
| PROD-14 | Sin cronología del caso | Línea de tiempo de actuaciones y documentos | P2 |
| PROD-15 | Sin exportar el expediente completo | PDF con índice, documentos y membrete | P0 |
| PROD-16 | Sin alertas de lapsos | Notificación push y evento de calendario | P1 |

### IA de primer nivel

| ID | Problema | Propuesta | Prioridad |
|---|---|---|---|
| PROD-20 | Las respuestas no siempre enlazan la fuente | Cada cita con enlace al artículo o a la sentencia | P0 |
| PROD-21 | Sin política de "no encontrado" | Si no hay fuente, la IA lo dice y no inventa | P0 |
| PROD-22 | Sin feedback de calidad | Pulgar arriba/abajo por respuesta y reporte de error | P1 |
| PROD-23 | Sin historial de conversaciones | Historial buscable por fecha y tema | P1 |
| PROD-24 | Sin evaluación de calidad | Conjunto de preguntas de prueba y medición de acierto | P2 |

### Operación y negocio

| ID | Problema | Propuesta | Prioridad |
|---|---|---|---|
| PROD-30 | Sin analytics de producto | Eventos de uso con privacidad (Plausible o Umami) | P1 |
| PROD-31 | Sin monitoreo de errores | Sentry en app y web, alertas de latencia y 5xx | P0 |
| PROD-32 | Sin panel de administración | Usuarios, uso, límites y reportes | P2 |
| PROD-33 | Sin planes ni límites | Free, Pro y Estudio con límites de IA | P1 |
| PROD-34 | Sin facturación | Pasarela de pago y recibos | P2 |
| PROD-35 | Sin onboarding | Tres pasos: rol, expediente y primera consulta | P0 |
| PROD-36 | Sin soporte | Ayuda in-app y base de conocimiento | P1 |
| PROD-37 | Sin backups probados | Respaldo automático y restauración verificada | P0 |
| PROD-38 | Sin entorno de pruebas | Staging separado de producción | P1 |
| PROD-39 | Sin pruebas E2E | Los 9 flujos críticos automatizados | P1 |

### Plataforma

| ID | Problema | Propuesta | Prioridad |
|---|---|---|---|
| PROD-40 | Sin diseño para tablet y escritorio | Diseño adaptativo en la app | P2 |
| PROD-41 | Solo en español y solo Venezuela | Internacionalización y adaptación a otros códigos penales | P2 |

---

## Las que haría primero

| Orden | Qué | Por qué |
|---|---|---|
| 1 | Citas verificables y política de "no encontrado" (PROD-20, PROD-21) | Es la diferencia entre una IA confiable y una que inventa |
| 2 | Plantillas de escritos (PROD-10) | Es el uso diario del abogado |
| 3 | Exportar el expediente completo (PROD-15) | Es lo que el cliente final entrega al tribunal |
| 4 | Auditoría de accesos (PROD-02) | Confianza y cumplimiento |
| 5 | Onboarding de tres pasos (PROD-35) | La primera impresión decide el uso |

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
