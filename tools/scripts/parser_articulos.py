#!/usr/bin/env python3
"""
Parser de artículos de las leyes venezolanas
Extrae estructura: Título -> Capítulo -> Artículo
"""
import re
import json
from pathlib import Path

TXT_DIR = Path("tools/data/leyes/textos")
OUTPUT_DIR = Path("tools/data/leyes/estructurado")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

print("=" * 80)
print("📝 PARSER DE ARTÍCULOS - LEYES VENEZOLANAS")
print("=" * 80)

def limpiar_texto(texto):
    """Limpia el texto extraído"""
    # Remover saltos de línea múltiples
    texto = re.sub(r'\n{3,}', '\n\n', texto)
    # Remover espacios múltiples
    texto = re.sub(r' {2,}', ' ', texto)
    return texto.strip()

def extraer_articulos(texto, codigo_ley):
    """Extrae artículos del texto"""
    articulos = []
    
    # Patrones comunes para artículos
    patrones = [
        r'Artículo\s+(\d+)[°º]?\.?\s*[-–—]?\s*(.+?)(?=Artículo\s+\d+|$)',
        r'Artículo\s+(\d+)[°º]?\.?\s+(.+?)(?=Artículo\s+\d+|$)',
        r'Art(?:ículo)?\.?\s+(\d+)[°º]?\.?\s*[-–—]?\s*(.+?)(?=Art(?:ículo)?\.?\s+\d+|$)',
    ]
    
    for patron in patrones:
        matches = re.finditer(patron, texto, re.IGNORECASE | re.DOTALL)
        temp_articulos = []
        
        for match in matches:
            numero = int(match.group(1))
            contenido = match.group(2).strip()
            
            # Limitar contenido a tamaño razonable
            if len(contenido) > 10000:
                contenido = contenido[:10000] + "..."
            
            temp_articulos.append({
                'numero': numero,
                'contenido': limpiar_texto(contenido)
            })
        
        # Si encontramos artículos con este patrón, usarlos
        if temp_articulos:
            articulos = temp_articulos
            break
    
    # Si no se encontraron artículos, dividir por párrafos
    if not articulos:
        print(f"   ⚠️  No se encontraron artículos con patrones estándar")
        parrafos = [p.strip() for p in texto.split('\n\n') if len(p.strip()) > 50]
        for i, parrafo in enumerate(parrafos[:100], 1):  # Máximo 100 secciones
            articulos.append({
                'numero': i,
                'contenido': limpiar_texto(parrafo)
            })
    
    return articulos

def procesar_ley(txt_path):
    """Procesa una ley completa"""
    codigo = txt_path.stem
    
    print(f"\n📚 {codigo}")
    
    # Leer texto
    with open(txt_path, 'r', encoding='utf-8') as f:
        texto = f.read()
    
    print(f"   📄 Texto: {len(texto):,} caracteres")
    
    # Extraer artículos
    articulos = extraer_articulos(texto, codigo)
    
    print(f"   ✅ Artículos extraídos: {len(articulos)}")
    
    # Metadata de la ley
    ley_data = {
        'codigo': codigo,
        'num_articulos': len(articulos),
        'caracteres_totales': len(texto),
        'articulos': articulos
    }
    
    # Guardar JSON estructurado
    output_path = OUTPUT_DIR / f"{codigo}.json"
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(ley_data, f, ensure_ascii=False, indent=2)
    
    print(f"   💾 Guardado: {output_path.name}")
    
    return ley_data

# ============================================================================
# EJECUCIÓN
# ============================================================================

if __name__ == "__main__":
    
    txt_files = sorted(TXT_DIR.glob("*.txt"))
    
    print(f"\n📋 {len(txt_files)} leyes para procesar\n")
    
    leyes_procesadas = []
    total_articulos = 0
    
    for txt_path in txt_files:
        ley_data = procesar_ley(txt_path)
        leyes_procesadas.append({
            'codigo': ley_data['codigo'],
            'articulos': ley_data['num_articulos']
        })
        total_articulos += ley_data['num_articulos']
    
    # Resumen
    print("\n" + "=" * 80)
    print("✅ PROCESAMIENTO COMPLETADO")
    print("=" * 80)
    
    print(f"\n📊 Resumen:\n")
    print(f"   Leyes procesadas: {len(leyes_procesadas)}")
    print(f"   Total artículos: {total_articulos:,}")
    print(f"   Promedio por ley: {total_articulos // len(leyes_procesadas)}")
    
    print(f"\n📚 Detalle:\n")
    for ley in sorted(leyes_procesadas, key=lambda x: x['articulos'], reverse=True):
        print(f"   {ley['codigo']:<12} {ley['articulos']:>4} artículos")
    
    print(f"\n📁 Archivos generados en: {OUTPUT_DIR}")
    print("=" * 80 + "\n")
