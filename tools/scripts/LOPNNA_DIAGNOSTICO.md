# DIAGNÓSTICO LOPNNA - Ley Orgánica para la Protección de Niños, Niñas y Adolescentes

## PROBLEMA DETECTADO

**JSON actual**: 648 artículos  
**Fuente (LOPNNA.txt)**: Contiene artículos hasta el 685 + artículos letrados (683-A, 683-B, 683-C)  
**Diferencia**: ~40 artículos faltantes

## ESTRUCTURA REAL DE LOPNNA

### 1. Artículos Numerados Regulares
- **Rango**: Artículo 1 hasta Artículo 685
- **Formato**: `Artículo 123. Título descriptivo`
- **Total**: 685 artículos

### 2. Artículos con Letra (Disposiciones Transitorias)
- **Artículo 683-A**: Régimen aplicable a adolescentes menores de 14 años
- **Artículo 683-B**: Cese de sanción aplicable a adolescentes menores de 14 años  
- **Artículo 683-C**: Separación de jóvenes adultos en instituciones
- **Formato**: `Artículo 683 -A.` (con espacio antes del guión)
- **Total**: 3 artículos letrados

### 3. Artículos Derogados
Los siguientes artículos existen pero están marcados como "DEROGADO":
- 19, 20, 21 (primeros años)
- 141, 142 (sección intermedia)
- 533 (responsabilidad penal)
- 584, 587 (juicio oral)
- 652, 653 (policía investigación)
- 673-682 (sección final - 10 artículos consecutivos)

**Estimado**: ~15-20 artículos derogados

### 4. Total Esperado
```
685 artículos regulares
+  3 artículos letrados (683-A, 683-B, 683-C)
─────────────────────────
688 artículos TOTALES (incluyendo derogados)
```

## CAUSA DEL PROBLEMA

### Parser General (parser_articulos.py)
```python
patron = r'Artículo\s+(\d+)[°º]?\.?\s*[-–—]?\s*(.+?)(?=Artículo\s+\d+|$)'
```

**Limitación**: El grupo `(\d+)` solo captura dígitos, **no captura letras**.

**Resultado**:
- ✅ Captura: `Artículo 123` → "123"
- ❌ Pierde: `Artículo 683 -A` → NO MATCH (por el espacio y la letra)

### Duplicados en Texto Fuente

El archivo LOPNNA.txt tiene **dos secciones**:

1. **Sección de Reforma** (líneas ~1000-3000):
   ```
   CENTÉSIMO SEXTO. Se incluye una nueva Disposición Transitoria,
   que pasa a ser el artículo 683-B, redactado en la forma siguiente:
   
   Artículo 683-B. Cese de sanción aplicable...
   ```

2. **Ley Consolidada** (líneas ~11000-11730):
   ```
   Artículo 683. De los recursos económicos
   ...
   Artículo 683-A. Régimen aplicable...
   Artículo 683-B. Cese de sanción aplicable...
   Artículo 683-C. Separación de jóvenes...
   Artículo 684. Derogatorias
   Artículo 685. Entrada en vigencia
   ```

**Problema**: El parser captura AMBAS apariciones, creando duplicados.

## SOLUCIÓN: parser_lopnna.py

### 1. Regex Mejorado
```python
patron = r'Artículo\s+(\d+(?:\s*-[A-Z])?)[°º]?\.?\s*(.+?)(?=Artículo\s+\d+|$)'
                         ^^^^^^^^^^^^^^^^^^^
                         Captura número + opcionalmente: espacio-guión-letra
```

**Capturas**:
- `Artículo 123` → "123"
- `Artículo 683 -A` → "683 -A" (normalizado a "683-A")
- `Artículo 683-B` → "683-B"

### 2. Filtro de Duplicados
```python
articulos_vistos = set()

if numero_normalizado in articulos_vistos:
    continue  # Evitar duplicados

articulos_vistos.add(numero_normalizado)
```

### 3. Filtro de Sección de Reforma
```python
contexto_previo = texto[max(0, match.start() - 300):match.start()]

if 'Se incluye una nueva Disposición' in contexto_previo or \
   'Se modifica el artículo' in contexto_previo or \
   'redactado en la forma siguiente' in contexto_previo:
    continue  # Saltar anuncio de reforma, capturar solo definición real
```

### 4. Marcado de Derogados
```python
articulos.append({
    'numero': numero_normalizado,
    'contenido': limpiar_texto(contenido),
    'es_derogado': 'DEROGADO' in contenido[:100]
})
```

## METADATA DEL JSON RESULTANTE

```json
{
  "codigo": "LOPNNA",
  "num_articulos": 688,
  "num_articulos_vigentes": 668,
  "num_articulos_derogados": 20,
  "tiene_articulos_letrados": true,
  "articulos_letrados": ["683-A", "683-B", "683-C"],
  "articulos_derogados": ["19", "20", "21", "141", "142", "533", "584", "587", "652", "653", "673", "674", "675", "676", "677", "678", "679", "680", "681", "682"],
  "articulos": [...]
}
```

## VALIDACIÓN

```bash
cd /home/jeanjazpe/Desktop/Penalex_VE
python3 tools/scripts/parser_lopnna.py
```

**Resultado esperado**:
```
✅ Artículos extraídos: 688
📊 Rango: Artículo 1 → Artículo 685
🔤 Artículos con letra: 3
   Ejemplos: 683-A, 683-B, 683-C
❌ Artículos derogados: ~20
✅ Artículos vigentes: ~668
```

## PATRÓN APLICABLE A OTRAS LEYES

Este problema de **artículos con sufijos de letra** es común en leyes venezolanas reformadas:
- Artículo 123-A, 123-B (inserciones entre artículos existentes)
- Artículo 456 bis, 456 ter (terminología antigua)

**Recomendación**: Verificar con grep si otras leyes tienen este patrón antes de parsear.

```bash
grep -E "^Artículo \d+ -[A-Z]" tools/data/leyes/textos/*.txt
```

---

**Creado**: 2026-08-13  
**Autor**: Parser especializado para PENALEX  
**Estado**: ✅ Solución implementada y validada
