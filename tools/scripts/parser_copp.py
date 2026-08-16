#!/usr/bin/env python3
r"""
Parser especializado para COPP (Código Orgánico Procesal Penal)

PROBLEMA: Ley de reforma con duplicados
- 22 reformas "Se modifica el artículo..."
- JSON: 637 | TXT únicos: 503 | Duplicados: 56

SOLUCIÓN: Filtrar anuncios de reforma (igual que LOCC)
"""
import re
import json
from pathlib import Path

def limpiar_texto(texto):
    """Limpia el texto extraído"""
    texto = re.sub(r'\n{3,}', '\n\n', texto)
    texto = re.sub(r' {2,}', ' ', texto)
    return texto.strip()

def extraer_articulos_copp(texto):
    """Extrae artículos filtrando anuncios de reforma"""
    
    # FILTRO: La ley consolidada empieza después de las reformas
    # Buscar la última aparición de "Artículo 1." (ley consolidada, no reforma)
    # Está en línea ~283
    matches = list(re.finditer(r'\nArtículo 1\.', texto))
    
    if matches:
        # Usar la ÚLTIMA aparición (ley consolidada)
        inicio_ley = matches[-1].start()
        texto_ley = texto[inicio_ley:]
        print(f"   🔍 Ley consolidada desde posición: {inicio_ley:,}")
    else:
        print(f"   ⚠️  No se encontró inicio de ley, parseando completo")
        texto_ley = texto
    
    articulos = []
    lineas = texto_ley.split('\n')
    
    patron_articulo = r'^Artículo\s*(\d+)\s*\.?\s*(.*)$'
    patron_reforma = r'Se\s+(modifica|agrega|deroga|suprime)\s+(el\s+)?artículo'
    
    articulo_actual = None
    contenido_actual = []
    es_anuncio_reforma = False
    
    i = 0
    while i < len(lineas):
        linea = lineas[i].strip()
        
        match_art = re.match(patron_articulo, linea)
        
        if match_art:
            # Guardar artículo anterior (si no era anuncio)
            if articulo_actual and not es_anuncio_reforma:
                articulos.append({
                    'numero': articulo_actual['numero'],
                    'titulo': articulo_actual['titulo'],
                    'contenido': limpiar_texto('\n'.join(contenido_actual)),
                    'es_derogado': 'DEROGADO' in articulo_actual['titulo'].upper()
                })
            
            # Nuevo artículo
            numero = match_art.group(1)
            titulo_linea = match_art.group(2).strip()
            
            # Verificar si es anuncio de reforma
            contexto = '\n'.join([lineas[j].strip() for j in range(i, min(i+3, len(lineas)))])
            es_anuncio_reforma = bool(re.search(patron_reforma, contexto, re.IGNORECASE))
            
            articulo_actual = {
                'numero': numero,
                'titulo': titulo_linea
            }
            contenido_actual = []
        else:
            if articulo_actual and linea:
                contenido_actual.append(linea)
        
        i += 1
    
    # Último artículo
    if articulo_actual and not es_anuncio_reforma:
        articulos.append({
            'numero': articulo_actual['numero'],
            'titulo': articulo_actual['titulo'],
            'contenido': limpiar_texto('\n'.join(contenido_actual)),
            'es_derogado': 'DEROGADO' in articulo_actual['titulo'].upper()
        })
    
    return articulos

def parsear_copp(txt_path):
    """Procesa COPP.txt"""
    
    print("=" * 80)
    print("📝 PARSER COPP - Especializado")
    print("=" * 80)
    
    codigo = txt_path.stem
    
    with open(txt_path, 'r', encoding='utf-8') as f:
        texto = f.read()
    
    print(f"\n📚 {codigo}")
    print(f"   📄 Texto: {len(texto):,} caracteres")
    
    total_raw = len(re.findall(r'^Artículo\s+\d+', texto, re.MULTILINE))
    print(f"   🔍 Artículos detectados (sin filtrar): {total_raw}")
    
    articulos = extraer_articulos_copp(texto)
    
    print(f"   ✅ Artículos reales extraídos: {len(articulos)}")
    
    if articulos:
        print(f"   📊 Rango: Artículo {articulos[0]['numero']} → Artículo {articulos[-1]['numero']}")
    
    derogados = [a for a in articulos if a.get('es_derogado', False)]
    vigentes = [a for a in articulos if not a.get('es_derogado', False)]
    
    if derogados:
        print(f"   ❌ Derogados: {len(derogados)}")
    print(f"   ✅ Vigentes: {len(vigentes)}")
    
    ley_data = {
        'codigo': codigo,
        'num_articulos': len(articulos),
        'num_articulos_vigentes': len(vigentes),
        'num_articulos_derogados': len(derogados),
        'caracteres_totales': len(texto),
        'articulos_derogados': [a['numero'] for a in derogados],
        'articulos': articulos
    }
    
    output_dir = Path("tools/data/leyes/estructurado")
    output_dir.mkdir(parents=True, exist_ok=True)
    output_path = output_dir / f"{codigo}.json"
    
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(ley_data, f, ensure_ascii=False, indent=2)
    
    print(f"   💾 Guardado: {output_path}")
    print("\n" + "=" * 80)
    print("✅ COMPLETADO")
    print("=" * 80)
    
    return ley_data

if __name__ == "__main__":
    txt_path = Path("tools/data/leyes/textos/COPP.txt")
    
    if not txt_path.exists():
        print(f"❌ Error: No se encontró {txt_path}")
        exit(1)
    
    resultado = parsear_copp(txt_path)
    
    print(f"\n📊 Resultado: {resultado['num_articulos']} artículos")
    print(f"   Esperado: ~503 (únicos detectados en auditoría)")
