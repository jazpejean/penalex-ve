# Guía de Arquitectura — Penalex VE

> **Propósito:** fijar las reglas de navegación, visual y modo claro/oscuro de Penalex VE
> para que cada pantalla nueva o modificada siga las mismas convenciones — sin improvisar.
>
> Esta guía es la fuente de verdad para decisiones de UI/UX. Si un cambio contradice
> estas reglas, primero se cambia la guía (con aprobación) y después el código.
>
> **Origen:** los principios de estructuración se estudiaron de la documentación
> oficial de Nylo v7 (directorio, temas, router) y se **adaptaron** — no se implementó
> Nylo en el proyecto. Los valores de color, la API de `AppBarInstitucional` y las
> carpetas están verificados contra el código real de Penalex (verificado: `app_colors.dart`,
> `app_theme.dart`, `app_bar_institucional.dart`, `lib/` al momento de escribirla).

---

## 1. Paleta y tokens (AppColors)

Fuente única: `lib/config/app_colors.dart`. **Nunca** se usan `Color(0xFF…)` ni
`Colors.*` directamente en las pantallas; siempre a través de tokens.

### 1.1 Tokens de marca (constantes, iguales en ambos modos)

| Token | Valor | Uso |
|---|---|---|
| `AppColors.azulMarino` | `0xFF0F172A` | Fondo de marca, AppBars, botones primarios, texto fuerte |
| `AppColors.dorado` | `0xFFC5A059` | Acento institucional, títulos de AppBar, premios |
| `AppColors.acentoDorado` | = `dorado` | Acento visual sobre superficies claras (iconos, bordes, indicadores) — **independiente del modo** |
| `AppColors.oroBrillante` | `0xFFE9C86A` | Efectos premium, brillos, "+XP" |
| `AppColors.onAzulMarino` | `Colors.white` | Texto/iconos **sobre** fondo navy. SIEMPRE blanco |
| `AppColors.onDorado` | = `azulMarino` | Texto/iconos **sobre** fondo dorado. SIEMPRE navy |

### 1.2 Tokens de superficie/texto (getters, cambian con el modo)

Delegan en `TemaGlobal` (`lib/config/app_theme.dart`):

| Token | Modo claro | Modo oscuro | Uso |
|---|---|---|---|
| `superficie` | `0xFFFAF7F2` (ivory) | `0xFF0F172A` (navy) | Fondo de página |
| `tarjeta` | `#FFFFFF` | `0xFF1E293B` | Cards y paneles |
| `capa` | `0xFFE8E0D0` (tan) | `0xFF334155` | Capas intermedias, tracks, bordes |
| `campoTexto` | `0xFFF2EBDD` | `0xFF1E293B` | Fondo de inputs |
| `texto` | `0xFF0F172A` | `#FFFFFF` | Texto principal |
| `textoSecundario` | `0xFF475569` | `0xFF94A3B8` | Texto secundario |
| `textoTenue` | `0xFF9CA3AF` | `0xFF64748B` | Texto de apoyo, hints |

### 1.3 Tokens de estado (getters, cambian con el modo)

| Token | Claro | Oscuro | Uso |
|---|---|---|---|
| `success` | `0xFF15803D` | `0xFF4ADE80` | Éxito |
| `error` | `0xFFB91C1C` | `0xFFF87171` | Error |
| `warning` | `0xFFC2410C` | `0xFFFBBF24` | Advertencia |
| `successBg` / `errorBg` / `warningBg` | alpha 0.15 | idem | Fondos suaves de estado |

### 1.4 Escala de alpha

Usar **solo** `AppColors.a06`, `a12`, `a18`, `a24`, `a48` con `withValues(alpha:)`.
Prohibido `withOpacity`/`withAlpha` (deprecados) y alphas libres arbitrarios.

### 1.5 Regla dura de uso del acento

| Contexto | Token |
|---|---|
| Icono/acento sobre superficie neutra, **cualquier modo** | `AppColors.acentoDorado` |
| Icono/acento que debe cambiar según modo | `AppColors.acento` (navy claro / dorado oscuro) |
| Texto/icono **sobre** fondo dorado | `AppColors.onDorado` |
| Texto **sobre** fondo claro | `AppColors.texto` / `textoSecundario` |

**Prohibiciones:**
- `Color(0xFF…)` y `Colors.red/green/blue/…` en pantallas (solo `Colors.transparent` y `Colors.white` sobre marca navy).
- `static const Color azulMarino/dorado` ni `static Color get acento` locales en widgets/páginas.
- `AppColors.primary`/`secondary` (deprecados).

---

## 2. Navegación

### 2.1 AppBarInstitucional

Componente obligatorio (`lib/widgets/app_bar_institucional.dart`). Fondo navy,
título dorado bold centrado, iconos (back, ☰, home) **dorados**.

| Situación | `mostrarBack` | `mostrarHome` | `mostrarDrawer` |
|---|---|---|---|
| Pantalla **pushed** (con `Navigator.push`) | ✅ `true` | ✅ `true` | ❌ `false` |
| Pantalla **pushed con AppDrawer** | ❌ `false` | ✅ `true` | ✅ `true` (el ☰ abre su drawer) |
| Pestaña principal (dashboard, agenda, hub consulta, asistente hub) | No usa AppBarInstitucional: header propio | — | — |

**Reglas:**
- El drawer se abre con el ☰ (si `mostrarDrawer`) o por swipe lateral. Nunca back + drawer a la vez.
- `document_editor_screen.dart` es la **única** excepción (AppBar manual con título TextField editable) — documentada.
- Iconos en `actions` del AppBarInstitucional: siempre `color: AppColors.dorado` explícito.

### 2.2 Patrones de navegación

> Principio tomado del router de Nylo (`nyRoutes`): **toda navegación es explícita
> y predecible** — cada pantalla tiene una ruta, un tipo de transición y (si aplica)
> un guard. Penalex navega con `Navigator` (sin router declarativo), así que la
> convención sustituye al registro central de Nylo.

| Acción | Regla | Código |
|---|---|---|
| Ir a detalle (nueva pantalla en el stack) | `Navigator.push`; el destino usa `mostrarBack: true, mostrarHome: true` | `Navigator.push(context, MaterialPageRoute(builder: …))` |
| Reemplazar pantalla (login → inicio, sin volver atrás) | `Navigator.pushReplacement` — **nunca** `push` para flujos de login/onboarding | `Navigator.pushReplacement(...)` |
| Limpiar todo el stack (logout / cerrar sesión) | `Navigator.pushAndRemoveUntil` hasta MainScreen | `pushAndRemoveUntil(context, MainScreen(), (r) => false)` |
| Volver al inicio (botón 🏠 en AppBarInstitucional) | `mainTabIndex.value = 0` + `pushAndRemoveUntil` a MainScreen | ver `AppBarInstitucional.mostrarHome` |
| Cerrar/atrás | `Navigator.pop` | — |
| Restricción por rol | `role_guard` **antes** de construir la pantalla — nunca dentro del `build` | `lib/widgets/role_guard.dart` |
| Navegación con datos | pasar por constructor de la pantalla destino (argumentos tipados) | `Screen(id: x, caso: y)` |
| Navegación con datos + ruta registrada | `Navigator.pushNamed('/ruta', arguments: …)` con `onGenerateRoute` en `main.dart` que castea y construye la pantalla | `/expediente` (argumento `Audiencia`) → `ExpedienteScreen(audiencia: aud)` |

**Reglas duras de navegación:**
- Una pantalla **pushed** nunca se alcanza con `pushReplacement` salvo login/onboarding/logout (documentado arriba).
- Nunca navegar con `Navigator` dentro del `build()` de un widget — siempre en callbacks (`onPressed`, `onTap`, gestos).
- El botón 🏠 es el único camino para "volver al inicio"; no se duplica con back + home en la misma pantalla (ver 2.1).

### 2.3 El AppScaffold (esqueleto unificado)

> **El gran ausente (verificado: no existe aún en `lib/widgets/`).** Es el widget
> contenedor que **decide el esqueleto completo** de cada pantalla: si muestra la
> `BottomNavigationBar`, si muestra el `AppBarInstitucional` con back, y qué
> `body` contiene. Así el 100% del esqueleto de la app se construye con una sola
> pieza — sin que cada pantalla arme su propio `Scaffold` a mano.
>
> **Patrón VIGENTE hasta que exista AppScaffold** (verificado en las pantallas
> nuevas): las pantallas pushed construyen `Scaffold(backgroundColor:
> TemaGlobal.superficie)` + `AppBarInstitucional(mostrarBack: true,
> mostrarHome: true)` directamente. Ejemplo: `expediente_screen.dart`.

```dart
// Contrato propuesto (API):
AppScaffold(
  title: 'Cómputo',              // → AppBarInstitucional
  body: ...,
  showBottomBar: false,          // false en pantallas pushed
  showBack: true,                // true en pantallas pushed
  showHome: true,                // true en pantallas pushed
  // derivado: pushed → mostrarBack+mostrarHome+sin bottom bar
  //           tab     → bottom bar + header (AppBarInstitucional o header propio)
)
```

| Tipo de pantalla | `showBottomBar` | `showBack` | `showHome` | Esqueleto resultante |
|---|---|---|---|---|
| **Pestaña principal** (dashboard, agenda, hub consulta, glosario, repositorio…) | ✅ `true` | ❌ | ❌ | `MainBottomBar` + header propio o `AppBarInstitucional` (ver 2.1) |
| **Pantalla pushed** (detalle, calculadora, editor…) | ❌ `false` | ✅ `true` | ✅ `true` | `AppBarInstitucional(mostrarBack, mostrarHome)` sin bottom bar |
| **Pantalla pushed con drawer** | ❌ `false` | ❌ | ✅ `true` | `AppBarInstitucional(mostrarDrawer, mostrarHome)` — drawer vía ☰/swipe |
| **Sin esqueleto** (ver excepciones abajo) | ❌ | ❌ | ❌ | `Scaffold` pelado, sin AppBar ni bottom bar |

**Reglas del AppScaffold:**
- Toda pantalla nueva **debe** usar `AppScaffold` (o una de las excepciones documentadas).
- Prohibido construir `Scaffold` + `AppBarInstitucional` + `MainBottomBar` a mano en cada pantalla.
- `AppScaffold` nunca decide contenido de negocio: solo estructura (AppBar/bottom bar/body).

### 2.4 Pantallas sin esqueleto (excepciones verificadas)

Hay pantallas donde **no** debe mostrarse ni AppBarInstitucional ni BottomNavigationBar:

| Pantalla | Por qué |
|---|---|
| `splash_screen.dart` | Pantalla de marca navy a pantalla completa |
| `quiz_game_screen.dart` | Gameplay a pantalla completa (Flame + HUD propio) |
| `escanear_documento_screen.dart` | Visor de documento navy a pantalla completa |
| `document_editor_screen.dart` | AppBar manual con título `TextField` editable (única excepción de AppBar) |

Cualquier pantalla nueva que entre en esta categoría debe **documentarse aquí**
antes de aprobarse — no se agrega silenciosamente.

---

## 3. Visual y componentes

### 3.1 Tarjetas

- Radio de esquina por jerarquía (verificado en dashboard/agenda/expediente):
  - **r24** — heroes de marca (gradiente navy): `_buildCaseHero` del expediente.
  - **r20** — contenedores grandes (calendario, cards principales del dashboard).
  - **r16** — tarjetas de lista/timeline (audiencias, día sin despacho, documentos, docs).
- Borde: `TemaGlobal.capa` en tarjetas sobre `TemaGlobal.tarjeta`; se usa `AppColors.acentoDorado.withValues(alpha: 0.25–0.3)` solo cuando se necesita acento dorado sutil explícito.
- Sombra: suave (`Colors.black.withValues(alpha: 0.02–0.03)`, blur 8–15), nunca sombras duras.
- Cards de "marca" (navy con gradiente): `LinearGradient([azulMarino, 0xFF1E293B])` con texto interno `Colors.white` — solo para contenido premium/destacado.
- **Borde de acento vertical (timeline):** las tarjetas de evento (audiencia/día sin despacho) usan una franja vertical de 4px (`AppColors.error` para día sin despacho, `dorado` para hoy) al lado izquierdo para señalizar el tipo.

### 3.2 Botones

| Tipo | Fondo | Texto/icono |
|---|---|---|
| Primario (FilledButton) | `AppColors.acento` (navy en claro / dorado en oscuro) | `AppColors.acento == dorado ? onDorado : onAzulMarino` |
| Acción premium | `AppColors.dorado` | `AppColors.onDorado` |
| Secundario (OutlinedButton) | transparente | `TemaGlobal.texto` con borde `TemaGlobal.capa` (ancho 1.5) |

**Notas verificadas (agenda premium):** el primario usa el getter `AppColors.acento`
dinámico — no `azulMarino` fijo — para que el CTA principal destaque en ambos modos.
`FilledButton.icon` con `padding vertical 14` y `BorderRadius.circular(12)`;
`OutlinedButton.icon` con `side: BorderSide(color: TemaGlobal.capa, width: 1.5)`.

### 3.3 Switches / SegmentedButton

**Switch:** siempre los 4 campos:
```dart
activeColor: AppColors.dorado,
activeTrackColor: AppColors.dorado.withValues(alpha: 0.35),
inactiveThumbColor: AppColors.textoSecundario,
inactiveTrackColor: AppColors.capa,
```

**SegmentedButton:**
- Seleccionado: fondo `AppColors.dorado`, texto `AppColors.onDorado`.
- No seleccionado: fondo `AppColors.capa`, texto `AppColors.texto`.
- Nunca fondo navy con texto dorado (ilegible).

### 3.4 SnackBars

Usar siempre `AppSnackBar.success(context, msg)` / `AppSnackBar.error(context, msg)`.
Prohibido `ScaffoldMessenger...showSnackBar(SnackBar(backgroundColor: …))` directo.

### 3.5 Iconografía

- Iconos de acción: `AppColors.acentoDorado` (o `AppColors.dorado` sobre navy).
- Iconos de estado: `success`/`error`/`warning`.
- Nunca iconos grises "apagados" sobre superficies claras cuando representan acción.

### 3.6 Tipografía (tamaños fijos)

Escala tipográfica única para toda la app — evita títulos gigantes en una pantalla
y diminutos en otra:

| Rol | Tamaño | Peso | Ejemplo de uso |
|---|---|---|---|
| Título de pestaña | **24px** | ExtraBold (w800) | Header "Agenda", "Dashboard" |
| Título de AppBar | **20px** | Bold | `AppBarInstitucional(title)` |
| Hero de tarjeta de marca | **22px** | ExtraBold (w800) | N° de expediente en `expediente_screen` |
| Título de sección | **15–18px** | Bold / ExtraBold | "Lapsos Procesales", encabezados de tarjetas |
| Título de tarjeta | **16px** | ExtraBold (w800) | Expediente/imputado en tarjetas de agenda |
| Subtítulo / meta | **13px** | Medium / SemiBold (w600) | Línea secundaria de cards |
| Texto de cuerpo | **14px** | Regular | Contenido, descripciones |
| Texto secundario | **12px** | Regular / SemiBold | Metadatos, hint, pie |
| Etiqueta / caption | **11px** | SemiBold | Leyenda del calendario |
| Badge | **10px** | ExtraBold (w800) + letterSpacing 0.5 | "AUDIENCIA", "DÍA SIN DESPACHO" |

**Reglas:**
- Sin tamaños "inventados" fuera de la escala (16.5, 18.5, etc.).
- Fuente institucional: `GoogleFonts.rubik` en textos de marca; el resto hereda del tema.
- Los **badges** (10px) se usan solo para etiquetas de estado sobre `alpha 0.12` del color
  del badge; los títulos de sección nunca usan `letterSpacing` > 1.

---

## 4. Modo claro / oscuro

### 4.1 Cómo funciona

`TemaGlobal.oscuro` (`ValueNotifier<bool>`) persiste en `'modo_oscuro'`.
Los getters de `AppColors`/`TemaGlobal` resuelven el color según el modo en runtime.

### 4.2 Reglas

1. **Todo** color de superficie/texto/estado va por getter — nunca un color fijo en una pantalla que deba cambiar con el modo.
2. **Marca no cambia**: `azulMarino`, `dorado`, `acentoDorado`, `onAzulMarino`, `onDorado` son iguales en ambos modos.
3. **No tocar el modo oscuro** cuando se ajusta el claro (y viceversa): cada paleta es independiente en `TemaGlobal`.
4. Al añadir una pantalla: verificar **ambos modos** antes de dar por terminado (criterio de aceptación obligatorio).
5. Contrastes mínimos: texto sobre dorado → `onDorado`; texto sobre navy → `onAzulMarino`; nunca dorado como texto sobre fondo claro.

### 4.3 Excepciones de marca (documentadas)

- `splash_screen.dart`: fondo navy por diseño (splash institucional).
- `escanear_documento_screen.dart`: visor de documento con fondo navy.
- `document_editor_screen.dart`: AppBar manual con título editable.

---

## 5. Estructura de archivos y contrato de capas

> Adaptado del directorio de Nylo (`app/` lógica, `resources/` UI, `config/`
> configuración, `routes/` navegación). Penalex usa carpetas propias; el contrato
> define **qué va en cada una** para que ningún archivo quede huérfano.

```
lib/
  config/     → tokens y tema (app_colors.dart, app_theme.dart, theme.dart)
  widgets/    → componentes reutilizables SIN lógica de negocio (AppBarInstitucional, AppSnackBar, AppDrawer, role_guard…)
  pages/      → una pantalla por archivo: <nombre>_screen.dart / <nombre>_page.dart
  services/   → lógica de datos y negocio (supabase, firebase, ai, exportación)
  providers/  → ChangeNotifiers globales de estado (user_provider, game_provider)
  models/     → modelos de datos
  logic/      → motores de cálculo puros (dosimetría, lapsos, reportes, secuencia)
  data/       → datos estáticos de la app (seed del quiz, catálogos)
  utils/      → helpers sin estado (fechas, controladores globales, conversiones)
  game/       → lógica de juegos (Flame quiz_effects_game)
  tools/      → (vacío actualmente — NO crear archivos aquí; mover a la capa correcta)
```

### Contrato por capa (dónde vive cada archivo)

| Capa | Qué va | Qué NO va | Ejemplos reales |
|---|---|---|---|
| `services/` | Acceso a datos (Supabase/Firebase), IA, exportación, negocio | Cálculos puros, widgets, navegación | `agenda_service`, `auth_service`, `deepseek_service`, `documentos_service`, `expediente_service`, `non_working_day_service` |
| `logic/` | Motores de cálculo **puros** (sin I/O, sin UI, testables) | Llamadas a red, widgets | `dosimetria_engine`, `lapsos_engine`, `report_generator`, `secuencia_procesal` |
| `data/` | Datos estáticos embebidos (seeds, catálogos) | Servicios con red | `quiz_questions_data` |
| `providers/` | `ChangeNotifier` globales (estado compartido) | Lógica de una sola pantalla (queda en su `State`) | `user_provider`, `game_provider` |
| `utils/` | Helpers sin estado reutilizables | Negocio, datos | `date_utils`, `pena_utils`, `storage_manager`, `transiciones`, `non_working_days` |
| `widgets/` | Widgets reutilizables — **sin** `BuildContext` de negocio ni acceso a Supabase | Pantallas completas | `AppBarInstitucional`, `AppSnackBar`, `role_guard` |
| `pages/` | Pantallas: una por archivo, estado local en `State` | Servicios/red directos en `build` (vía servicio) | `dashboard_screen`, `agenda_screen`, `expediente_screen`, `escanear_documento_screen` |
| `game/` | Lógica y efectos de juego (Flame) | UI de páginas | `quiz_effects_game` |

**Regla de dependencia (en capas):** `pages/` → `widgets/` y `services/`;
`services/` → `models/`, `logic/`, `utils/`; `logic/` no depende de nada más.
Nunca `services/` → `pages/` (la UI no se importa desde la lógica).

---

## 6. Pantallas premium implementadas (referencia)

> Patrones ya aprobados y en producción — usarlos como base, no reinventarlos.

| Pantalla | Patrones clave |
|---|---|
| `dashboard_screen.dart` | Header propio (saludo 22 w800 + avatar navy/oro) — **sin campanita**; hero Ulpiano (gradiente navy, badge ASISTENTE IA, CTA dorado → `/asistente_legal`); secciones 'Herramientas de Cálculo' / 'Tu Despacho Digital' / 'Próxima Audiencia' / 'Explorar'; Detector de Vicios = card gradiente navy con badge PROXIMAMENTE (SnackBar honesto, no navega a nada falso); cada herramienta abre su **pantalla real** (`pushNamed`) |
| `agenda_screen.dart` | Header 'Agenda' 24 w800; calendario r20 (selected = `AppColors.acento` r10, hoy = dorado a12, día sin despacho = error a0.15 + borde error); leyenda (dorado/error/hoy a0.3); CTA primario 'Nueva Audiencia' (acento dinámico) + secundario 'Día sin Despacho' (outlined capa); timeline con tarjetas r16: badge 'AUDIENCIA' (dorado a12), hora 14 w800 (acento si hoy), línea 2px, acciones 📁 portafolio / ⏳ lapsos / 🗑 eliminar; tarjeta de día sin despacho con borde error 4px + footer info (cómputo según procedimiento → remite al Calendario Judicial) |
| `expediente_screen.dart` | Pushed (`AppBarInstitucional` back+home, ruta `/expediente` con argumento `Audiencia`); hero navy r24 (badge estado, n° expediente 22, imputado, delito + tribunal); tarjeta lapsos → Calendario Judicial; portafolio de documentos (subir → `EscanearDocumentoScreen`, listar con icono PDF/imagen); grid IA (Detector de Vicios → SnackBar próximamente, Redactar Escrito → `RedactorDocumentosScreen`); FAB dorado extendido 'Preguntar a Ulpiano' centrado abajo (padding inferior 110) |
| `escanear_documento_screen.dart` | Pantalla sin esqueleto (visor navy) — excepción documentada en 2.4; guarda en Supabase Storage vía `DocumentosService` |

**Portafolio (persistencia):** `ExpedienteService.asegurarExpediente` crea/actualiza el
expediente (tabla `expedientes`, upsert por número) al abrir el workspace o al agendar;
los documentos se vinculan por `documentos_escaneados.expediente_id`. SQL:
`supabase_expedientes_setup.sql` (debe ejecutarse en el SQL Editor de Supabase).

---

## 7. Prompt para IA (cómo usar esta guía)

> Al pedirle a **cualquier IA** que refactorice, cree o modifique una pantalla de
> Penalex VE, se debe **adjuntar este archivo** y usar la instrucción estricta:

```
Aplica las reglas de GUIA_ARQUITECTURA.md. No improvises colores, tamaños,
navegación ni estructura: todo debe salir de las convenciones del documento.
Si una regla del documento contradice tu propuesta, sigue el documento.
```

**Regla de oro:** si la IA propone algo que contradice la guía, primero se cambia
la guía (con aprobación del dueño del proyecto) y después el código — nunca al revés.

---

## 8. Criterios de aceptación (antes de commitear UI)

- [ ] `flutter analyze` → "No issues found!"
- [ ] Cero `Color(0xFF…)` nuevos fuera de `config/`
- [ ] Cero `Colors.red/green`, `withOpacity`, `withAlpha` nuevos
- [ ] Pantallas pushed usan `AppBarInstitucional` con back + home (o `AppScaffold` cuando exista)
- [ ] Ruta con datos: `pushNamed` + `onGenerateRoute` tipado, o constructor tipado — nunca `Map<String, dynamic>` suelto
- [ ] Cero Scaffolds con `backgroundColor` navy fuera de las excepciones (2.4)
- [ ] Switches con los 4 campos; SegmentedButton con dorado/onDorado seleccionado
- [ ] SnackBars vía `AppSnackBar`
- [ ] Tamaños de fuente dentro de la escala de 3.6 (incluye 24/22/16/10 verificados)
- [ ] Radios de tarjeta: 16 / 20 / 24 según jerarquía de 3.1
- [ ] Primario = `AppColors.acento` (dinámico), secundario = outlined `TemaGlobal.capa` (3.2)
- [ ] Verificado en **modo claro** y **modo oscuro**