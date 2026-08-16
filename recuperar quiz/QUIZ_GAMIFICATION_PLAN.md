# 🎮 PENALEX VE - PLAN DE GAMIFICACIÓN DEL QUIZ

## 💎 MODELO DE MONETIZACIÓN

### Estructura de Precios

```
🆓 VERSIÓN GRATUITA (Sin anuncios):
├─ Repositorio: 5 documentos/día, búsqueda básica
├─ Dosímetro: 3 cálculos/día
├─ Quiz: Niveles 1-10 únicamente
├─ Leyes: Lectura completa
└─ ❌ Sin IA, sin descargas, sin agenda

🎓 PLAN ESTUDIANTE: $5.99/mes o $49.99/año
├─ Requiere verificación con carnet universitario
├─ Acceso completo a todas las funciones
└─ Renovación anual con reverificación

👤 PLAN INDIVIDUAL: $10/mes o $99/año (ahorra 17%)
├─ Acceso completo
├─ 1 dispositivo simultáneo
└─ Soporte estándar

⚖️ PLAN PROFESIONAL: $20/mes o $199/año (ahorra 17%)
├─ Todo del Plan Individual +
├─ 3 dispositivos simultáneos
├─ Exportación con logo personalizado
├─ Soporte prioritario
└─ Facturación fiscal

🏢 PLAN CORPORATIVO: Desde $150/mes (5 usuarios)
├─ $25/usuario adicional
├─ Gestión centralizada
├─ Panel de administración
├─ SSO (Single Sign-On)
├─ Reportes de uso
├─ Onboarding personalizado
└─ SLA 99.9% uptime
```

### Trial y Conversión

```
🎁 TRIAL: 14 días gratis
├─ Acceso completo sin restricciones
├─ Sin cobro hasta decidir
└─ Conversión esperada: 30-35%

📧 Email Drip Campaign:
├─ Día 1: Bienvenida + guía rápida
├─ Día 3: Feature highlight (dosimetría)
├─ Día 5: Feature highlight (búsqueda IA)
├─ Día 7: Progreso semanal
├─ Día 10: Mitad del trial
├─ Día 12: Quedan 2 días
├─ Día 13: 10% descuento si activa hoy
└─ Día 14: Conversión o downgrade
```

---

## 🎮 SISTEMA DE QUIZ GAMIFICADO

### Filosofía: "Difícil pero Adictivo"

**Principios:**
- ❌ NUNCA revelar respuesta correcta si falla
- ✅ Pistas útiles pero vagas (educativas)
- ✅ Sistema de apelaciones regenerable (como Candy Crush)
- ✅ Progresión adictiva con recompensas constantes
- ✅ Casos hipotéticos únicos (anti-trampa)

### Versión Free vs Premium

| Característica | Free | Premium |
|----------------|------|---------|
| Niveles | 1-10 | 1-3000 |
| Apelaciones | 3 (regen 2h) | 7 (regen 30min) |
| Banco Repaso | ❌ | ✅ Ilimitado |
| Boosters | ❌ | ✅ Semanales |
| Certificados | ❌ | ✅ Cada 100 niveles |
| Ver fundamentación | Paga 100 pts | Gratis |

---

## 🎨 TEMÁTICA VENEZOLANA

### Elementos Visuales

**Colores Patrios:**
```dart
- Amarillo: #FCDD09
- Azul: #003893
- Rojo: #CF142B
```

**Lobby (Implementado):**
- ✅ Cielo azul venezolano con degradado
- ✅ Montañas del Ávila con efecto parallax
- ✅ Camino de adoquines serpenteante
- ✅ Araguaneys con flores amarillas a los lados
- ✅ Flores cayendo animadas
- ✅ Césped y vegetación de fondo
- ✅ 21 monumentos venezolanos posicionados

**Monumentos (cada ~100 niveles):**
```
Nivel 1:    Inicio del Camino
Nivel 100:  Palacio Federal Legislativo
Nivel 200:  Tribunal Supremo de Justicia
Nivel 300:  Capitolio Federal
Nivel 400:  Panteón Nacional
Nivel 500:  Universidad Central
Nivel 600:  Parque del Este
Nivel 700:  Teatro Teresa Carreño
Nivel 800:  Plaza Bolívar
Nivel 900:  Casa Natal del Libertador
Nivel 1000: Ávila Mágico
Nivel 1200: Catedral de Caracas
Nivel 1400: Parque Los Caobos
Nivel 1600: Biblioteca Nacional
Nivel 1800: Palacio de Justicia
Nivel 2000: Complejo Cultural
Nivel 2200: Parque Nacional Waraira Repano
Nivel 2400: Aula Magna UCV
Nivel 2600: Jardín Botánico
Nivel 2800: Cumbre del Ávila
Nivel 3000: Magistrado Supremo ⚖️
```

---

## 📊 SISTEMA DE CASOS HIPOTÉTICOS

### Generación de Preguntas

**Pool de Casos por Nivel:**
- Cada nivel tiene 5 casos diferentes (pool)
- Sistema selecciona UNO aleatorio cada intento
- Nunca repite hasta agotar pool
- Orden de opciones aleatorio (anti-memorización)

**Estructura del Caso:**
```typescript
{
  id: "uuid",
  nivel: 234,
  pool_id: 1-5,
  delito_base: "homicidio_calificado",
  agravante: "alevosía",
  contexto_narrativo: "Carlos en Maracaibo...",
  opciones: [
    "15-20 años - Homicidio calificado",
    "10-15 años - Homicidio simple",
    "5-10 años - Lesiones gravísimas",
    "20-25 años - Asesinato agravado"
  ],
  respuesta_correcta: 0
}
```

### Fundamentación Legal (solo si acierta)

```typescript
{
  explicacion: "Se configura homicidio calificado por...",
  articulos: [
    {
      codigo: "penal",
      articulo: "405",
      texto: "El que intencionalmente..."
    }
  ],
  sentencias_ids: ["2002_214_exp_C01-0163"],
  jurisprudencias_ids: ["2004_089_exp_04-0123"]
}
```

### Sistema de Pistas (si falla)

**Pistas Vagas (NO revelan respuesta):**

Primer fallo:
```
"Este caso involucra un delito del Título IX
del Código Penal (Delitos contra las Personas).
Considera las circunstancias que rodean el hecho."
```

Segundo fallo (caso DIFERENTE):
```
"Ambos casos son sobre delitos contra la vida
con agravantes especiales. Estudia los tipos
agravados en el Código Penal."
```

Tercer fallo (caso DIFERENTE):
```
"Los 5 casos de este nivel tratan sobre
HOMICIDIO CALIFICADO con diferentes agravantes.
Calcula bien las penas.

Tasa de éxito global: 38% ⚠️"
```

---

## 🎯 MECÁNICAS ANTI-TRAMPA

### Rotación de Casos
1. Usuario intenta nivel 234 → Caso A (homicidio con alevosía)
2. Falla y sale
3. Vuelve a nivel 234 → Caso B (homicidio con ensañamiento)
4. Screenshot de Caso A ya no sirve

### Aleatorización
- Contextos con variables aleatorias (nombres, ciudades)
- Opciones en orden diferente cada vez
- Detección de respuestas rápidas (< 3 seg)
- Penalización por patrones sospechosos

### Tracking
```sql
CREATE TABLE intentos_casos (
  user_id TEXT,
  caso_id UUID,
  nivel INT,
  correcto BOOLEAN,
  tiempo_respuesta INT,
  created_at TIMESTAMPTZ
);
```

---

## 🏗️ ARQUITECTURA TÉCNICA

### Base de Datos Supabase

**Tablas principales:**
```sql
casos_hipoteticos (
  id, nivel, pool_id, delito_base, agravante,
  contexto_narrativo, opciones, respuesta_correcta,
  dificultad, tasa_exito, activo
)

fundamentaciones (
  id, caso_id, explicacion, articulos,
  sentencias_ids, jurisprudencias_ids
)

pistas_casos (
  id, caso_id, nivel_pista, texto_pista,
  articulos_sugeridos, busqueda_sugerida
)

banco_repaso (
  id, user_id, caso_id, veces_fallado,
  ultima_vez_fallado, bloqueado, estudiado
)

intentos_casos (
  id, user_id, caso_id, nivel, correcto,
  tiempo_respuesta, created_at
)
```

### Servicios Flutter

**Estructura de servicios:**
```
lib/services/
├── casos_service.dart          # Obtener casos, validar respuestas
├── fundamentacion_service.dart # Obtener fundamentación legal
├── pistas_service.dart         # Obtener pistas según intento
└── banco_repaso_service.dart   # Gestionar casos fallados
```

---

## 📈 PROYECCIÓN DE INGRESOS

### Año 1 (conservador)

```
Usuarios totales: 400
├─ Individual: 180 × $10/mes × 12 = $21,600
├─ Estudiante: 120 × $5.99/mes × 12 = $8,629
├─ Profesional: 50 × $20/mes × 12 = $12,000
└─ Corporativo: 3 × $150/mes × 12 = $5,400

TOTAL: $47,629/año
Costos: ~$4,560/año
GANANCIA NETA: $43,069/año
```

### Año 2 (crecimiento orgánico)

```
Usuarios totales: 1,000
├─ Individual: 500 × $10 × 12 = $60,000
├─ Estudiante: 300 × $5.99 × 12 = $21,564
├─ Profesional: 150 × $20 × 12 = $36,000
└─ Corporativo: 10 × $180 × 12 = $21,600

TOTAL: $139,164/año
Costos: ~$11,400/año
GANANCIA NETA: $127,764/año
```

---

## ✅ IMPLEMENTADO

### Lobby del Quiz (Flame Engine)
- ✅ `lib/models/caso_hipotetico_model.dart` - Modelos de datos
- ✅ `lib/games/quiz_lobby_game.dart` - Game con Flame
  - Parallax background (cielo + montañas Ávila)
  - Camino de adoquines serpenteante
  - Araguaneys con flores amarillas
  - Flores cayendo animadas (20 partículas)
  - Nodos de nivel interactivos
  - Sistema de capítulos (10 niveles por capítulo)
  - Scroll suave con cámara
  - Efectos glow en nivel actual
- ✅ `lib/pages/quiz_lobby_screen_flame.dart` - UI con GameWidget
  - Banner superior con avatar, rango, XP, apelaciones
  - Colores patrios venezolanos en toda la UI
  - Controles de navegación entre capítulos
  - Modal de selección de nivel
  - Botón de ranking
- ✅ `assets/images/quiz_lobby/README.md` - Guía de imágenes

### 0 Errores de Compilación
- Todos los archivos validados
- Sin warnings ni errores
- Listo para agregar imágenes artísticas

---

## 📋 PENDIENTE DE IMPLEMENTAR

### 1. Tablas Supabase
```sql
-- Crear tablas de casos, fundamentaciones, pistas, banco_repaso
-- Poblar con casos iniciales (niveles 1-100)
```

### 2. Servicios Backend
```dart
// lib/services/casos_service.dart
// lib/services/fundamentacion_service.dart
// lib/services/pistas_service.dart
// lib/services/banco_repaso_service.dart
```

### 3. Pantalla del Juego
```dart
// lib/pages/quiz_game_screen.dart
// - Burbuja cayendo con caso
// - Timer visual
// - 4 opciones de respuesta
// - Animaciones de acierto/fallo
```

### 4. Modales
```dart
// lib/widgets/fundamentacion_modal.dart
// lib/widgets/pista_modal.dart
// lib/widgets/banco_repaso_screen.dart
```

### 5. Sistema de Pagos
```dart
// lib/services/payment_service.dart
// - Integración con Stripe/RevenueCat
// - Gestión de suscripciones
// - Trial de 14 días
```

---

## 🎯 PRÓXIMOS PASOS

1. **Crear tablas en Supabase** (SQL migrations)
2. **Generar 100 casos iniciales** (script Python)
3. **Implementar servicios Flutter** (casos_service, etc.)
4. **Pantalla del juego** (quiz_game_screen.dart)
5. **Modales de resultado** (fundamentación/pista)
6. **Testing completo** del flujo
7. **Sistema de pagos** (Stripe/RevenueCat)
8. **Beta testing** con usuarios reales

---

**Creado:** 2026-08-16
**Última actualización:** 2026-08-16
**Estado:** Lobby implementado, backend pendiente
