#!/usr/bin/env python3
r"""
Parser especializado para LOSDMVLV (Ley Orgánica sobre el Derecho de las Mujeres a una Vida Libre de Violencia)

PROBLEMA CRÍTICO: 67 reformas, 139 duplicados
- JSON: 346 | TXT únicos: 131 | Duplicados masivos

SOLUCIÓN: Filtrar anuncios de reforma
"""
import re
import json
from pathlib import Path

def limpiar_texto(texto):
    texto = re.sub(r'\n{3,}', '\n\n', texto)
    texto = re.sub(r' {2,}', ' ', texto)
    return texto.strip()

def extraer_articulos_losdmvlv(texto):
    articulos = []
    lineas = texto.split('\n')
    
    patron_articulo = r'^Artículo\s*(\d+)\s*\.?\s*(.*)$'
    patron_reforma = r'Se\s+(modifica|agrega|deroga|suprime)'
    
    articulo_actual = None
    contenido_actual = []
    es_anuncio_reforma = False
    
    for i, linea in enumerate(lineas):
        linea = linea.strip()
        match_art = re.match(patron_articulo, linea)
        
        if match_art:
            # Guardar anterior
            if articulo_actual and not es_anuncio_reforma:
                articulos.append({
                    'numero': articulo_actual['numero'],
                    'titulo': articulo_actual['titulo'],
                    'contenido': limpiar_texto('\n'.join(contenido_actual)),
                    'es_derogado': 'DEROGADO' in articulo_actual['titulo'].upper()
                })
            
            numero = match_art.group(1)
            titulo_linea = match_art.group(2).strip()
            
            # Verificar reforma
            contexto = '\n'.join([lineas[j].strip() for j in range(i, min(i+3, len(lineas)))])
            es_anuncio_reforma = bool(re.search(patron_reforma, contexto, re.IGNORECASE))
            
            articulo_actual = {'numero': numero, 'titulo': titulo_linea}
            contenido_actual = []
        else:
            if articulo_actual and linea:
                contenido_actual.append(linea)
    
    # Último
    if articulo_actual and not es_anuncio_reforma:
        articulos.append({
            'numero': articulo_actual['numero'],
            'titulo': articulo_actual['titulo'],
            'contenido': limpiar_texto('\n'.join(contenido_actual)),
            'es_derogado': 'DEROGADO' in articulo_actual['titulo'].upper()
        })
    
    return articulos

def parsear_losdmvlv(txt_path):
    print("="*80)
    print("📝 PARSER LOSDMVLV - Especializado")
    print("="*80)
    
    codigo = txt_path.stem
    with open(txt_path, 'r', encoding='utf-8') as f:
        texto = f.read()
    
    print(f"\n📚 {codigo}")
    print(f"   📄 Texto: {len(texto):,} caracteres")
    
    total_raw = len(re.findall(r'^Artículo\s+\d+', texto, re.MULTILINE))
    print(f"   🔍 Sin filtrar: {total_raw}")
    
    articulos = extraer_articulos_losdmvlv(texto)
    print(f"   ✅ Extraídos: {len(articulos)}")
    
    if articulos:
        print(f"   📊 Rango: {articulos[0]['numero']} → {articulos[-1]['numero']}")
    
    derogados = [a for a in articulos if a.get('es_derogado')]
    vigentes = [a for a in articulos if not a.get('es_derogado')]
    
    if derogados:
        print(f"   ❌ Derogados: {len(derogados)}")
    print(f"   ✅ Vigentes: {len(vigentes)}")
    
    ley_data = {
        'codigo': codigo,
        'num_articulos': len(articulos),
        'num_articulos_vigentes': len(vigentes),
        'num_articulos_derogados': len(derogados),
        'caracteres_totales': len(texto),
        'articulos': articulos
    }
    
    output_dir = Path("tools/data/leyes/estructurado")
    output_dir.mkdir(parents=True, exist_ok=True)
    with open(output_dir / f"{codigo}.json", 'w', encoding='utf-8') as f:
        json.dump(ley_data, f, ensure_ascii=False, indent=2)
    
    print(f"   💾 Guardado")
    print("\n" + "="*80)
    print("✅ COMPLETADO")
    print("="*80)
    return ley_data

if __name__ == "__main__":
    resultado = parsear_losdmvlv(Path("tools/data/leyes/textos/LOSDMVLV.txt"))
    print(f"\n📊 {resultado['num_articulos']} artículos (esperado: ~131)")
