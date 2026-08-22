# CONTEXTO DE PENALEX VE
## Estado del proyecto al 21 de agosto de 2026

### 1. Diagnóstico general
- 155 archivos Dart, ~1.42 MB de código.
- 62% del código está en `pages/` (UI), solo 1.6% en `logic/` (lógica de negocio).
- La lógica de dosimetría (validada en juicios reales) está atrapada dentro de widgets.
- No existe carpeta `test/` → 0 tests sobre lógica que se usa en tribunales.
- Doble stack de autenticación: Firebase (legado) y Supabase (activo).
- Gestión de estado: Provider/Riverpod (legado) y GetX (meta).

### 2. Hallazgos críticos
- `dosimetria_engine.dart`: 4.2 KB (demasiado pequeño para un motor real).
- `dosimetria_page.dart`: 56.6 KB (la lógica está aquí, no en el engine).
- `computo_page.dart`: 38.2 KB, `concurso_page.dart`: 25.2 KB.
- Tres fuentes de días no hábiles: `date_utils.dart`, `non_working_days.dart`, `non_working_day_service.dart`.
- Duplicados: `calculos_guardados_page` vs `saved_calculations_screen`, `reportes_guardados_page` vs `saved_reports_screen`.
- 5 pantallas de redactor: la oficial es `redactor_documentos_screen.dart`.
- Capa IA: `ai_service.dart` usa DeepSeek. Pendiente migrar a Puter + Claude Opus 5.

### 3. Prioridades (confirmadas)
1. **Bloque A** → Extraer lógica de dosimetría de la UI a `domain/dosimetria/` en Dart puro.
2. **Golden tests** → Usar los dos casos reales (concurso real) para blindar el motor.
3. **Bloque B** → Migrar IA a Puter + Claude Opus 5 con fallback a DeepSeek.
4. **Bloque C** → Unificar días no hábiles y agenda judicial.
5. **Bloque D** → Chat legal con RAG (pgvector en Supabase).

### 4. Decisiones tomadas
- Año = 360 días, mes = 30 días (convención penal venezolana).
- Tope constitucional: 30 años (Art. 44.3 CRBV).
- `saved_calculations_screen.dart` es el vivo; `calculos_guardados_page.dart` es legado.
- `saved_reports_screen.dart` es el vivo; `reportes_guardados_page.dart` es legado.
- `document_scanner_service_pro.dart` es el activo; el otro es legado.
- GetX es la meta, Provider es legado (se migrará gradualmente).
- Firebase solo para login → se eliminará después.
- Puter será primario, DeepSeek fallback (no se elimina).

### 5. Archivos clave para el Bloque A (dosimetría)
- `lib/logic/dosimetria_engine.dart`
- `lib/utils/pena_utils.dart`
- `lib/models/delito.dart`
- `lib/models/calculation_model.dart`
- `lib/pages/dosimetria_page.dart`
- `lib/pages/concurso_page.dart`
- `lib/pages/computo_page.dart`
- `lib/pages/lapsos_page.dart`
- `lib/logic/report_generator.dart`
- `lib/services/calculation_service.dart`
- `lib/services/report_service.dart`
- `lib/widgets/delito_card.dart`
- `lib/utils/date_utils.dart`
- `lib/utils/non_working_days.dart`
- `lib/services/non_working_day_service.dart`
- `lib/pages/calculos_guardados_page.dart` (legado)
- `lib/pages/saved_calculations_screen.dart` (vivo)
- `lib/pages/reportes_guardados_page.dart` (legado)
- `lib/pages/saved_reports_screen.dart` (vivo)

### 6. Casos reales para tests
- Caso 1: Tráfico de municiones (20-25) + Porte (4-8) + Agavillamiento (2-5) → 24 años, 6 meses, 8 días.
- Caso 2: Tráfico primer aparte (12-18) + Porte (4-8) + Agavillamiento (2-5) → 17 años, 0 meses, 8 días.
- Ambos validados en juicios condenatorios reales. Los PDFs están en `data/reportes/`.

### 7. Siguiente paso inmediato
- Leer los 4 archivos del Bloque 1-A (`dosimetria_engine.dart`, `pena_utils.dart`, `delito.dart`, `calculation_model.dart`).
- Ejecutar checklist de reglas penales (Art. 37, 74, 80-82, 88, 99, 375 COPP, etc.).
- Entregar informe detallado con plan de extracción.

### 8. Estado de la conversación con el agente
- El agente ha propuesto un plan de auditoría en 5 bloques.
- Se ha confirmado el Bloque 1-A como prioridad.
- Los reportes reales están en `data/reportes/` y se usarán como golden tests.
- El agente aún no ha leído el contenido de los archivos; está esperando que se le proporcione.
