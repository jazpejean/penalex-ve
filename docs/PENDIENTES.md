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
| ESC-01 | Escáner | Detector de bordes tosco | Cámara propia con overlay del cuadrilátero en vivo, detector en Dart puro y captura con recorte de perspectiva | hecho |
| ESC-02 | Escáner | Solo captura de a una imagen | Captura de hasta 30 páginas y galería múltiple | hecho |
| ESC-03 | Escáner | No se pueden reordenar páginas | Hoja "Páginas" con arrastrar y soltar | hecho |
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
| APP-11 | Leyenda del calendario con "Hoy" casi invisible | "Hoy" en azul marino con contraste | hecho |
| APP-24 | El buscador de jurisprudencia tenía colores discordantes, filtros apretados y no mostraba resultados al entrar | Header único, buscador con botón navy, filtros en hoja aparte con chips navy y carga automática al entrar | hecho |
| APP-12 | Botón primario dorado en unas pantallas y navy en otras | Botones principales de leyes, prescripción y redactor en navy con texto blanco | hecho |
| APP-13 | Títulos de sección en dorado, negro y serif según pantalla | `AppTokens.tituloSeccion` en todas | en curso |
| APP-14 | Drawer con sección "Recursos legales" incompleta | Ordenar y completar el menú | abierto |
| APP-15 | Avatar con inicial gigante y botón de cámara desalineado | Avatar consistente con `photoUrl` | abierto |
| APP-16 | Asistente con guion largo y badge que compite con el título | Microcopy limpio | abierto |
| APP-17 | Versión del drawer dice v1.0 | Ahora dice v1.0.0+1 | hecho |
| APP-18 | Estados vacíos distintos en cada pantalla | Componente `EmptyState` creado y aplicado en Agenda | hecho |
| APP-19 | Sin modo oscuro coherente | Modo oscuro conectado con `TemaGlobal.oscuro` y `AppTheme.darkTheme`; coherencia visual pendiente de revisar en dispositivo | parcial |
| APP-20 | Sin accesibilidad: escalado de texto, `Semantics`, 48 dp | Escalado 2x con tests; Semantics en barra inferior, buscador y acciones rápidas del Inicio | parcial |
| APP-21 | El Inicio no muestra el potencial de las herramientas | Buscador global arriba y acciones rápidas Consultar, Redactar y Escanear bajo el hero | hecho |
| APP-23 | El header de Concurso queda fijo y el de Dosimetría se desplaza con el scroll | El header de Dosimetría ahora está fuera del scroll, fijo como el de Concurso y Cómputo | hecho |
| APP-22 | La barra inferior aparecía en Dosimetría pero no en Concurso ni en Cómputo | Barra añadida a las tres pantallas del flujo | hecho |

### Flujos y producto

| ID | Problema | Propuesta | Estado |
|---|---|---|---|
| APP-30 | Sin búsqueda global | El buscador jurídico ya tiene alcance sentencias, leyes y glosario, y el Inicio lo abre | hecho |
| APP-31 | Sin modo offline para leyes y sentencias | Cada ley descargada se guarda y se lee sin conexión; sentencias y glosario pendientes | parcial |
| APP-32 | Historial y favoritos no se sincronizan con la web | Tabla única y sincronización | abierto |
| APP-33 | Sin notificaciones de audiencias y lapsos | Audiencias y prescripción con recordatorio el día anterior; lapsos procesales del expediente pendientes | parcial |
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
| POR-05 | Sin tipos de documento (auto, providencia, prueba, escrito) | Tipo inferido por el nombre del documento, sin columna nueva. Se muestra en cada tarjeta | hecho |
| POR-06 | Sin buscador dentro del portafolio | Buscador por título y chips de filtro por tipo | hecho |
| POR-07 | Sin contadores por tipo | Conteo en cada chip de filtro | hecho |
| POR-08 | Los escritos del redactor no se asocian al expediente | Falta `expediente_id` en `redactor_conversaciones` | abierto |

---

## Escáner

| ID | Problema | Propuesta | Estado |
|---|---|---|---|
| ESC-10 | Sin captura consecutiva | El escáner ya permite hasta 30 páginas por sesión | hecho |
| ESC-11 | Sin galería múltiple | Botón de galería con selección múltiple en el editor | hecho |
| ESC-12 | Sin mejora de imagen (contraste, binarización) | Binarización adaptativa Sauvola por página, con test, corre en isolate | hecho |
| ESC-13 | Sin tira de miniaturas | Estados por página: pendiente, lista, error | abierto |
| ESC-14 | PDF se arma descargando de Storage | El editor ya arma el PDF en local con las páginas procesadas | hecho |
| ESC-15 | Sin firma y sello | Pie con sello Penalex y fecha en cada página, y línea de firma en la última | hecho |
| ESC-16 | Lectura con visión solo de la página actual | Botón "Transcribir todas" que procesa las páginas por lotes de cinco | hecho |
| ESC-17 | Sin límites de tamaño ni compresión configurable | Calidad y tamaño por página | abierto |
| ESC-18 | Sin cifrado local de documentos sensibles | Borrado seguro con sobrescritura de los temporales; cifrado en reposo pendiente | parcial |

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
| WEB-10 | Emojis en el dashboard | Iconos lineales del set existente en dashboard, mapa y tribunales | hecho |
| WEB-11 | Títulos en serif en la UI | h1, h2, h3 y .serif pasan a Inter | hecho |
| WEB-12 | Radios y botones distintos a la app | Tokens CSS --radio-tarjeta, --radio-control y --margen | hecho |
| WEB-13 | Herramientas IA solo en la app | Marcar claramente o portar Ulpiano | abierto |
| WEB-14 | Falta PWA instalable y offline | Manifest instalable y theme-color; service worker offline pendiente | abierto |
| WEB-15 | Sin deep links a la app | App Links para `/sentencias` | abierto |

---

## Protección del código y del conocimiento

### La verdad técnica

No existe forma de encriptar el cliente. El JavaScript de la web siempre se puede descargar y el APK siempre se puede descompilar. Cualquier esquema que prometa "código imposible de replicar" en el cliente es falso.

Lo que sí protege:

| Activo | Dónde debe vivir | Por qué |
|---|---|---|
| Prompts de IA | **Worker (servidor)** | El cliente nunca los ve; solo recibe la respuesta |
| Reglas de negocio sensibles | **Worker** | Se ejecutan y no se descargan |
| Calculadoras (dosimetría, prescripción) | Cliente, ofuscado | La ley es pública; el valor es la exactitud, no el secreto |
| Corpus y pipeline | Backend con autenticación | Es el foso real |
| Claves de IA | Solo secretos del worker | Nunca en el cliente |

### Medidas concretas

| ID | Medida | Efecto | Estado |
|---|---|---|---|
| SEC-01 | Mover todos los prompts al worker | El cliente no puede copiarlos | abierto |
| SEC-02 | Mover al worker toda lógica que use IA | No se puede replicar sin el backend | abierto |
| SEC-03 | Ofuscar el APK (`--obfuscate --split-debug-info`) | Dificulta leer el Dart compilado | abierto |
| SEC-04 | R8 y ProGuard activos en Android | Reduce nombres y elimina código muerto | abierto |
| SEC-05 | Minificar y dividir el bundle web | No protege, pero encarece copiar | abierto |
| SEC-06 | Autenticación obligatoria en el worker | Sin token no hay respuestas | abierto |
| SEC-07 | Rate limiting por usuario | Evita extracción masiva de respuestas | abierto |
| SEC-08 | Marca de agua por usuario en respuestas | Permite detectar filtraciones | abierto |
| SEC-09 | No exponer URLs de R2 sin control | El corpus no se descarga completo | abierto |
| SEC-10 | Términos, licencia y aviso de propiedad | Protección legal | abierto |

### Lo que sí es defendible

1. **El corpus curado**: replicarlo toma años, no un fin de semana.
2. **El pipeline**: la capacidad de mantenerlo actualizado.
3. **La verificación de vigencia**: saber qué está superado.
4. **El worker**: la lógica de IA vive ahí y se puede cambiar sin publicar app.

La estrategia correcta no es esconder más, es **depender del servidor para lo valioso**. Así, aunque copien la interfaz, no tienen el producto.

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
| DOS-10 | **No se reproduce en la versión actual.** Reproducido en el dispositivo con pena 12-18: agravante 2 años da 17, atenuante 2 años da 13, agravante 2 meses da 15a 2m. Todos correctos | Pendiente: confirmar con el usuario si el fallo persiste en el APK instalado. El caso de 2 días quedó sin verificar por el foco del campo | abierto |
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
| LEY-12 | Los títulos V y VI del Reglamento de Abogados incluían la nota derogatoria en el título | Título limpio y nota en campo aparte, corregido en Supabase y R2 | hecho |
| LEY-13 | La app lee las leyes de Supabase Storage, no de R2 | Documentar la arquitectura: Supabase para la app, R2 para la web. Cualquier corrección de datos debe ir a los dos | hecho |
| LEY-14 | 18 leyes no penales estaban en el bucket de Supabase sin uso | Descargadas a backups, eliminadas del bucket y del manifest (71 → 53) | hecho |
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
| EST-09 | 17 teléfonos y 1 correo sin sanear en los modelos | Copia saneada con [TELÉFONO] y [CORREO] | hecho |
| EST-10 | Las citas no se validan por pertinencia, solo por existencia | Revisión de un abogado sobre los 124 modelos | abierto |
| EST-11 | Los modelos revisados no citan artículos derogados ni inexistentes | Auditoría de 1.131 citas contra 6.406 artículos | hecho |

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

## Prescripción de la acción penal (rediseño)

La calculadora actual solo maneja la prescripción ordinaria con una tabla simplificada. Debe cubrir ordinaria, extraordinaria, interrupción, suspensión e imprescriptibilidad.

### Contraste: PDF adjunto vs Código Penal (texto del corpus)

| Tema | PDF | Código Penal real | Veredicto |
|---|---|---|---|
| Plazo 1 | "Hasta 30 años → 15 años" | Art. 108.1: prisión **mayor de 10 años** → 15 años | El PDF agrega un tope de 30 que no existe |
| Plazo 2 | "Más de 10 → 10 años" | Art. 108.2: **más de 7 y hasta 10** → 10 años | PDF desplaza el rango |
| Plazo 3 | "10 o menos → 7 años" | Art. 108.3: **más de 3 y hasta 7** → 7 años | PDF desplaza el rango |
| Plazo 4 y 5 | Multa → 1 año; instancia de parte → 1 año | Art. 108.6: multa mayor de 150 UT → 1 año; art. 108.7: multa menor → 3 meses | PDF omite numerales y confunde |
| Faltas | Art. 109 → 6 meses | No hay plazo de 6 meses en el art. 108; el art. 109 regula el **inicio del cómputo** | Referencia legal equivocada |
| Inicio del cómputo | "Art. 111" | Es el **art. 109** (el 111 trata de condenado en nuevo juicio) | Referencia equivocada |
| Interrupción | Orden de comparecencia, imputación, aprehensión, acusación | Art. 110: sentencia condenatoria, requisitoria por fuga, citación como imputado, querella, diligencias | El PDF describe otra norma |
| Imprescriptibles | Corrupción "cuando el investigado esté prófugo" | CRBV 271: no prescriben las acciones contra derechos humanos, patrimonio público y tráfico de estupefacientes, sin condicionar a fuga | El PDF agrega una condición inexistente |

**Conclusión:** el PDF sirve como guía conceptual, pero **no como fuente de plazos ni de referencias**. La calculadora debe regirse por el texto del Código Penal y de la Constitución.

### Error detectado en el corpus

El art. 108 del corpus tiene los numerales 3 y 4 inconsistentes: el 3 dice "prisión de siete años o menos" y el 4 "más de tres años", con rangos que se solapan. La escala correcta es:

| Pena de prisión | Prescripción ordinaria |
|---|---|
| Más de 10 años | 15 años |
| Más de 7 y hasta 10 | 10 años |
| Más de 3 y hasta 7 | 7 años |
| Más de 1 y hasta 3 | 5 años |
| 1 año o menos, arresto mayor a 6 meses, relegación, confinamiento o expulsión | 3 años |
| Arresto de 1 a 6 meses, multa mayor a 150 UT, suspensión de profesión | 1 año |
| Multa menor a 150 UT o arresto menor a 1 mes | 3 meses |

### Rediseño de la calculadora

| ID | Requisito | Estado |
|---|---|---|
| PRE-01 | Prescripción ordinaria con los siete supuestos del art. 108 | abierto |
| PRE-02 | Prescripción extraordinaria: ordinaria más su mitad (art. 110) | abierto |
| PRE-03 | Inicio del cómputo según art. 109: consumado, tentativa, continuado o permanente | abierto |
| PRE-04 | Interrupción con los actos del art. 110 y reinicio del cómputo | abierto |
| PRE-05 | Suspensión por autorización especial, cuestión prejudicial, acuerdo reparatorio y suspensión condicional | abierto |
| PRE-06 | Excluir del cálculo los delitos imprescriptibles (CRBV 29 y 271) | abierto |
| PRE-07 | Notificar cuando el delito no prescribe, con el fundamento constitucional | abierto |
| PRE-08 | Mostrar el rango completo: fecha de ordinaria, de extraordinaria y estado actual | abierto |
| PRE-09 | Corregir los numerales 3 y 4 del art. 108 en el corpus | abierto |
| PRE-10 | Advertir que la interrupción no opera en delitos imprescriptibles | abierto |

### Cómo debe responder

- Si el delito es imprescriptible: "No prescribe. Fundamento: artículo 29 o 271 de la Constitución" y no calcula fecha.
- Si prescribe: muestra fecha de ordinaria, fecha de extraordinaria y cuántos actos interruptores se registraron.
- Si hubo interrupción: explica que el cómputo se reinició y que la extraordinaria es el límite absoluto.

---

## Criterios sostenidos y abandonados (jurisprudencia viva)

Archivo de referencia: `penalex-scraper/criterios_sostenidos_y_abandonados.json`. **Es la versión vieja, sin curar.** El pipeline nuevo la reemplazará. Se registra aquí como muestra de la idea y de lo que hay que corregir.

**Por qué es valioso:** evita citar jurisprudencia superada, que es uno de los errores más graves en un escrito. Ningún competidor lo tiene resuelto a este nivel.

### Calidad de la versión vieja (referencia para el pipeline nuevo)

| Dato | Resultado |
|---|---|
| Sostenidos | 25 |
| Abandonados | 25 |
| Con `superado_por` | 25 de 25 |
| `n_precedentes` en sostenidos | entre 47 y 248 |
| `sala` vacía | 25 de 25 (100%) |
| `materia` vacía | 25 de 25 (100%) |
| Instrumento y artículo | completos |
| Fechas invertidas (`primera_fecha` mayor que `ultima_fecha`) | 12 de 25 |
| Cita literal | en reproceso (el enunciado es una síntesis) |

### Reglas para el RAG

| ID | Regla | Estado |
|---|---|---|
| JUR-01 | Un criterio `superado` nunca se cita como vigente | propuesta |
| JUR-02 | Si el usuario pregunta por un criterio superado, se responde con el que lo sustituye | propuesta |
| JUR-03 | Los criterios con más precedentes se priorizan en el contexto | propuesta |
| JUR-04 | Completar `sala` y `materia` en los 50 | abierto |
| JUR-05 | Corregir las 12 fechas invertidas | abierto |
| JUR-06 | No citar textualmente el enunciado hasta que la cita literal esté lista | abierto |
| JUR-07 | Mostrar en el chat "criterio vigente" o "criterio superado" junto a la cita | abierto |
| JUR-08 | Registrar la trazabilidad con `sentencias_que_lo_sostienen` | abierto |

### Lo que debe mostrar al abogado

> Criterio vigente, sostenido en 248 sentencias, desde 2005 hasta 2024.
> O bien: criterio superado, sustituido por el criterio X en 2025.

Eso es lo que separa una respuesta útil de una que hace perder un caso.

---

## RAG y doctrinas académicas

El RAG ya incluye tres fuentes: sentencias, criterios de la Sala y doctrinas académicas. La auditoría de la tabla `doctrinas_academicas` (11.133 filas) encontró los problemas que degradan la fundamentación.

### Calidad de los datos

| Hallazgo | Filas | % | Efecto |
|---|---|---|---|
| Sin página | 8.648 | 78% | La cita no es verificable |
| Sin obra | 6.206 | 56% | No se puede citar la fuente |
| Sin autor | 169 | 1,5% | Cita incompleta |
| Autor es una sala o tribunal | ~1.421 | 13% | Se presenta un criterio de sala como doctrina académica |
| Autor es "tribunal" o "corte" | 817 | 7% | Igual problema |
| Evidencias duplicadas | 1.514 | 14% | Contexto repetido, más tokens y confusión |

### Reglas de curaduría propuestas

| ID | Regla | Estado |
|---|---|---|
| RAG-01 | Autor + obra + página son obligatorios para citar como doctrina académica | propuesta |
| RAG-02 | Si el autor es una sala, tribunal o corte, la fila pasa a criterios de la Sala, no a doctrina | propuesta |
| RAG-03 | Si falta obra o página, la fila se marca `incompleta` y el RAG no la cita como fuente formal | propuesta |
| RAG-04 | Deduplicar por autor + obra + página + evidencia | propuesta |
| RAG-05 | Normalizar nombres de autores (mayúsculas, acentos, abreviaturas) | propuesta |
| RAG-06 | Las obras que en realidad son leyes se excluyen del banco doctrinal | propuesta |
| RAG-07 | El contexto debe llevar presupuesto de tamaño y orden por relevancia, no por tipo | abierto |
| RAG-08 | Medir precisión y recall del RAG con un conjunto de preguntas de prueba | abierto |
| RAG-09 | Las citas académicas deben mostrar autor, obra, página y la sentencia que las recoge | abierto |
| RAG-10 | Sincronizar la base local con Supabase y registrar la versión del corpus | abierto |
| RAG-11 | La curaduría se hace con búsquedas web, sin registro de la fuente | Guardar URL, título de la fuente y fecha de consulta por cada dato completado | propuesta |
| RAG-12 | Sin estados de curaduría | `pendiente`, `propuesta`, `verificada`, `dudosa`, `sin_fuente` por fila | propuesta |
| RAG-13 | Riesgo de completar con datos inventados o de otra obra | Solo se aprueba con una fuente que muestre autor, obra y página | propuesta |
| RAG-14 | Sin trazabilidad de quién aprobó | Campo de aprobación con fecha y usuario | propuesta |
| RAG-15 | Sin métrica de avance de curaduría | Panel con total, completas, incompletas, dudosas y sin fuente | propuesta |

### Estado de la curaduría

La curaduría la ejecuta el usuario con un pipeline de IA y búsqueda web. **No se toca la base hasta que él indique que culminó.** Al terminar hay que pedirle:

- El esquema final de `doctrinas_academicas` (columnas de estado, fuente, URL, fecha y aprobación).
- El conteo por estado: verificadas, dudosas y sin fuente.
- La versión del corpus curado para registrarla.

**Muestra recibida el 2026-11-23:** `doctrinas_academicas_perfectas.json` con 1.007 registros (9% del total). La curaduría sigue en curso con el pipeline del usuario y no se cierra hasta su aviso. Calidad de la muestra:

| Dato | Resultado |
|---|---|
| Autor, obra, año y página | 100% completos |
| Editorial | 95% (58 vacíos) |
| Ciudad | 99% (18 vacíos) |
| Tomo | 100% vacío (no aplica) |
| `verificado_web` | 1.007 de 1.007 |
| `referencia_completa` | 1.007 de 1.007 |
| `referencia_legible` | 949 completas |
| Duplicados | 200 (20%) |
| `fuente_verificacion` | "catalogo_biblioteca", sin URL |

Recomendaciones sobre la muestra:
1. **Deduplicar los 200** antes de subir.
2. **Guardar la URL** del catálogo en `fuente_verificacion`, no solo el tipo, para poder auditar cada dato.
3. `cita_textual` está vacío al 100%: la cita real es `parrafo_evidencia`. Conviene renombrar o eliminar el campo para no confundir.
4. `referencia_legible` es exactamente lo que el RAG debe mostrar al abogado.

Cuando avise, se hace:
1. Adaptar el RAG para citar solo las filas `verificada`.
2. Medir cuántas citas quedan completas (autor, obra, página).
3. Revisar duplicados y autores que son salas.
4. Actualizar la auditoría del corpus.

### Curaduría asistida por búsqueda web

Cada fila incompleta pasa por este flujo:

1. **Extraer** autor y obra tal como vienen en la fila.
2. **Buscar** en fuentes verificables: Google Books, WorldCat, Dialnet, Google Scholar, catálogos de universidades venezolanas y revistas jurídicas.
3. **Proponer** el dato encontrado con su evidencia: URL, título de la página, texto donde aparece la página del libro.
4. **Comparar** con la evidencia de la sentencia: el párrafo citado debe coincidir con la obra y el autor.
5. **Aprobar o descartar** con revisión humana.
6. **Guardar** el estado y la fuente.

Reglas estrictas:
- Sin URL y texto de respaldo, el dato no se completa.
- Si la búsqueda arroja dos obras distintas para el mismo autor, la fila se marca `dudosa`.
- Si no hay coincidencia, se marca `sin_fuente` y el RAG no la cita como doctrina formal.
- La página solo se completa cuando la fuente la muestra. No se infiere por cercanía.

Lo que el RAG debe responder

- Si no hay doctrina académica verificable, lo dice y fundamenta con jurisprudencia y ley.
- Nunca presenta un criterio de sala como si fuera un autor académico.
- Cada doctrina citada lleva autor, obra y página.

---

## Pipelines como activo

El corpus es un dato y se puede copiar. Los pipelines son la capacidad de generar y mantener ese dato, y eso no se copia. Hoy hay **48 scripts** en `penalex-scraper/`, muchos con nombres ad hoc (`fix_*`, `tmp_*`, `audit_cloud_v2`). Funcionan, pero no están presentados como activo.

### Los cinco pipelines que hay que consolidar

| # | Pipeline | Entrada | Salida | Métrica |
|---|---|---|---|---|
| 1 | Ingesta de sentencias | Portal del TSJ y R2 | `sentencias` + HTML en R2 | Sentencias nuevas por día y cobertura |
| 2 | Extracción de criterios | Texto de la sentencia | `doctrinas` con ratio y evidencia | Criterios por sentencia y % con cita literal |
| 3 | Curaduría académica | Citas de las sentencias | `doctrinas_academicas` verificadas | % con autor, obra, año y página |
| 4 | Indexación | Textos y artículos | Vectores en Qdrant | Chunks indexados y latencia de búsqueda |
| 5 | Auditoría y calidad | Corpus completo | Reportes de citas, duplicados y derogados | Errores detectados por corrida |

### Lo que convierte un script en activo

| Propiedad | Estado actual | Qué falta |
|---|---|---|
| Reproducibilidad | Scripts sueltos | Un comando por pipeline con parámetros |
| Idempotencia | Riesgo de duplicar | Clave única y modo "upsert" |
| Verificación con fuente | Sí en académicas | Guardar URL y fecha en todas |
| Métricas de calidad | Reportes parciales | Tablero único por corrida |
| Control de costo | Sin registro | Llamadas de IA y costo por registro |
| Versionado del corpus | Sin versión | `corpus_version` en cada fila |
| Documentación | Comentarios dispersos | Un documento por pipeline |
| Supervisión humana | Aprobar a mano | Cola de revisión con estados |

### Por qué importa para el concurso

Un jurado compra la capacidad de producir y mantener el dato, no el archivo. Si el pipeline se presenta como un sistema de cinco etapas con métricas, el proyecto deja de ser "una app con datos" y pasa a ser "infraestructura de conocimiento legal".

### La tesis del negocio

La dificultad está en construir una base sólida. Una vez construida, el pipeline la mantiene actualizada sola y el costo marginal de producción es mínimo. Ese es el valor real: no el corpus, sino la capacidad de mantenerlo vivo a costo casi cero.

**Los cuatro números que lo demuestran:**

| Métrica | Qué prueba |
|---|---|
| Costo por sentencia procesada | El dato cuesta centavos, no horas |
| Costo por doctrina verificada | La curaduría no depende de personas |
| Tiempo desde que sale una sentencia hasta que está indexada | La base está viva |
| % de campos completos por corrida | La calidad se mantiene sin intervención |

**Los tres riesgos que hay que blindar antes de decirlo en público:**

1. **Detección de cambios en la fuente.** Si el portal del TSJ cambia, el pipeline puede devolver cero y nadie se entera. Hace falta una alerta cuando el volumen diario cae por debajo de lo esperado.
2. **Cola de revisión humana.** La verificación web acierta la mayoría de las veces, pero no siempre. Sin una cola de `dudosa` y `sin_fuente`, los errores se acumulan en silencio.
3. **Reformas y derogatorias.** Una ley reformada cambia el corpus. Hay que detectar la reforma y marcar los artículos afectados, no solo agregar texto nuevo.

**Forma del pipeline único:**

``` 
penalex-pipeline run --desde 2026-11-01
  ├── ingesta       (portal, R2, Supabase)
  ├── extraccion    (criterios y citas)
  ├── curaduria     (verificacion web)
  ├── indexacion    (vectores)
  └── auditoria     (calidad y alertas)
```

Cada etapa es idempotente y deja un registro en `pipeline_runs` con fecha, registros, costo y errores. Un solo comando, cinco etapas, métricas en cada una.

### Tareas

| ID | Tarea | Estado |
|---|---|---|
| PIPE-08 | Medir costo por sentencia y por doctrina | abierto |
| PIPE-09 | Alerta cuando el volumen diario cae (posible cambio de portal) | abierto |
| PIPE-10 | Cola de revisión humana con estados | abierto |
| PIPE-11 | Detección de reformas y derogatorias de leyes | abierto |
| PIPE-12 | Tabla `pipeline_runs` con registros, costo y errores | abierto |
| PIPE-01 | Consolidar los 48 scripts en cinco pipelines con nombre y comando único | abierto |
| PIPE-02 | Añadir idempotencia (upsert por clave) a los cinco | abierto |
| PIPE-03 | Registrar costo de IA por corrida y por registro | abierto |
| PIPE-04 | Guardar URL y fecha de verificación en cada fila curada | abierto |
| PIPE-05 | Un tablero de calidad por corrida (completas, dudosas, sin fuente, duplicados) | abierto |
| PIPE-06 | Documento de arquitectura de los pipelines para el pitch | abierto |
| PIPE-07 | Versionar el corpus y registrar cada corrida | abierto |

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
