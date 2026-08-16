#!/usr/bin/env python3
r"""
Parser especializado para LOCC (Ley Orgánica Contra la Corrupción)

PROBLEMA DETECTADO:
- LOCC es una LEY DE REFORMA PARCIAL
- Cada modificación tiene estructura duplicada:
  1. "Artículo X. Se modifica el artículo Y..." ← Anuncio (IGNORAR)
  2. "Artículo Y. [contenido real]" ← Definición real (CAPTURAR)
- Parser general captura ambos → duplicados

ESTRUCTURA LOCC:
- Artículo 1. Se modifica el artículo 1...
  - Artículo 1. [texto real del artículo 1]
- Artículo 2. Se modifica el artículo 3...
  - Artículo 3. [texto real del artículo 3]
- Artículo 3. Se modifica el artículo 4...
  - Artículo 4. [texto real del artículo 4]

SOLUCIÓN:
- Detectar artículos con "Se modifica", "Se agrega", "Se deroga"
- SALTAR estos (son anuncios de reforma)
- Solo capturar artículos con contenido sustantivo
"""
import re
import json
from pathlib import Path

def limpiar_texto(texto):
    """Limpia el texto extraído"""
    texto = re.sub(r'\n{3,}', '\n\n', texto)
    texto = re.sub(r' {2,}', ' ', texto)
    return texto.strip()

def extraer_articulos_locc(texto):
    """
    Extrae artículos de LOCC filtrando anuncios de reforma
    
    Filtros:
    - Artículos que dicen "Se modifica el artículo..." → IGNORAR
    - Artículos que dicen "Se agrega..." → IGNORAR
    - Artículos que dicen "Se deroga..." → IGNORAR (pero marcar como derogado)
    - Solo capturar artículos con contenido real
    
    FORMATO ESPECIAL LOCC:
    "Artículo" está en una línea, número en otra, punto en otra:
    Artículo
    1
    .
    Texto...
    
    Pre-procesamos para unir: "Artículo 1. Texto..."
    """
    
    # PRE-PROCESO: Unir "Artículo\n123\n.\n" a "Artículo 123. "
    texto_normalizado = re.sub(
        r'Artículo\s*\n\s*(\d+)\s*\n\s*\.\s*\n',
        r'Artículo \1. ',
        texto,
        flags=re.MULTILINE
    )
    
    articulos = []
    
    # Procesar línea por línea
    lineas = texto_normalizado.split('\n')
    
    # Patterns
    patron_articulo = r'^Artículo\s*(\d+)\s*\.?\s*(.*)$'
    patron_reforma = r'Se\s+(modifica|agrega|deroga|suprime)\s+(el\s+)?artículo'
    
    articulo_actual = None
    contenido_actual = []
    es_anuncio_reforma = False
    
    i = 0
    while i < len(lineas):
        linea = lineas[i].strip()
        
        # Detectar inicio de artículo
        match_art = re.match(patron_articulo, linea)
        
        if match_art:
            # Guardar artículo anterior (si no era anuncio de reforma)
            if articulo_actual and not es_anuncio_reforma:
                articulos.append({
                    'numero': articulo_actual['numero'],
                    'titulo': articulo_actual['titulo'],
                    'contenido': limpiar_texto('\n'.join(contenido_actual)),
                    'es_derogado': 'DEROGADO' in articulo_actual['titulo'].upper() or \
                                   'DEROGADO' in '\n'.join(contenido_actual[:5]).upper()
                })
            
            # Nuevo artículo
            numero = match_art.group(1)
            titulo_linea = match_art.group(2).strip()
            
            # Verificar si es anuncio de reforma
            # Necesitamos ver líneas siguientes para confirmar
            es_anuncio_reforma = False
            
            # Mirar las próximas 5 líneas
            contexto = '\n'.join([lineas[j].strip() for j in range(i, min(i+5, len(lineas)))])
            
            if re.search(patron_reforma, contexto, re.IGNORECASE):
                es_anuncio_reforma = True
            
            articulo_actual = {
                'numero': numero,
                'titulo': titulo_linea
            }
            contenido_actual = []
        
        # Contenido del artículo
        else:
            if articulo_actual and linea:
                contenido_actual.append(linea)
        
        i += 1
    
    # No olvidar último artículo
    if articulo_actual and not es_anuncio_reforma:
        articulos.append({
            'numero': articulo_actual['numero'],
            'titulo': articulo_actual['titulo'],
            'contenido': limpiar_texto('\n'.join(contenido_actual)),
            'es_derogado': 'DEROGADO' in articulo_actual['titulo'].upper() or \
                           'DEROGADO' in '\n'.join(contenido_actual[:5]).upper()
        })
    
    return articulos

def parsear_locc(txt_path):
    """Procesa LOCC.txt con lógica especializada"""
    
    print("=" * 80)
    print("📝 PARSER LOCC - Especializado")
    print("=" * 80)
    
    codigo = txt_path.stem
    
    # Leer texto
    with open(txt_path, 'r', encoding='utf-8') as f:
        texto = f.read()
    
    print(f"\n📚 {codigo}")
    print(f"   📄 Texto: {len(texto):,} caracteres")
    
    # Contar total de líneas "Artículo" (antes de filtrar)
    total_articulos_raw = len(re.findall(r'^Artículo\s+\d+', texto, re.MULTILINE))
    print(f"   🔍 Artículos detectados (sin filtrar): {total_articulos_raw}")
    
    # Contar anuncios de reforma
    anuncios = len(re.findall(r'^Artículo.*Se\s+(modifica|agrega|deroga)', texto, re.MULTILINE | re.IGNORECASE))
    print(f"   🚫 Anuncios de reforma (filtrados): {anuncios}")
    
    # Extraer artículos reales (sin anuncios)
    articulos = extraer_articulos_locc(texto)
    
    print(f"   ✅ Artículos reales extraídos: {len(articulos)}")
    
    if articulos:
        primero = articulos[0]['numero']
        ultimo = articulos[-1]['numero']
        print(f"   📊 Rango: Artículo {primero} → Artículo {ultimo}")
    
    # Contar derogados
    derogados = [a for a in articulos if a.get('es_derogado', False)]
    vigentes = [a for a in articulos if not a.get('es_derogado', False)]
    
    if derogados:
        print(f"   ❌ Artículos derogados: {len(derogados)}")
    print(f"   ✅ Artículos vigentes: {len(vigentes)}")
    
    # Metadata
    ley_data = {
        'codigo': codigo,
        'num_articulos': len(articulos),
        'num_articulos_vigentes': len(vigentes),
        'num_articulos_derogados': len(derogados),
        'caracteres_totales': len(texto),
        'articulos_derogados': [a['numero'] for a in derogados],
        'articulos': articulos
    }
    
    # Guardar JSON
    output_dir = Path("tools/data/leyes/estructurado")
    output_dir.mkdir(parents=True, exist_ok=True)
    output_path = output_dir / f"{codigo}.json"
    
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(ley_data, f, ensure_ascii=False, indent=2)
    
    print(f"   💾 Guardado: {output_path}")
    
    print("\n" + "=" * 80)
    print("✅ PROCESAMIENTO COMPLETADO")
    print("=" * 80)
    
    return ley_data

if __name__ == "__main__":
    txt_path = Path("tools/data/leyes/textos/LOCC.txt")
    
    if not txt_path.exists():
        print(f"❌ Error: No se encontró {txt_path}")
        exit(1)
    
    resultado = parsear_locc(txt_path)
    
    print(f"\n📊 Resultado final:")
    print(f"   Artículos totales: {resultado['num_articulos']}")
    print(f"   Artículos vigentes: {resultado['num_articulos_vigentes']}")
    if resultado['num_articulos_derogados'] > 0:
        print(f"   Artículos derogados: {resultado['num_articulos_derogados']}")
    
    print(f"\n   ℹ️  LOCC es una ley de reforma parcial")
    print(f"   ℹ️  Los anuncios 'Se modifica...' fueron filtrados correctamente")
