#!/usr/bin/env python3
"""
Analizar qué líneas del CSV NO fueron capturadas por el regex
"""

import re

print("\n" + "="*80)
print("🔍 ANÁLISIS: Líneas NO capturadas del CSV")
print("="*80)

# Patrones actuales
patterns = [
    r'(\d{4}_\d+_exp_[\w\-]+)\.html',
    r'(resolucion_\d+_\d{4})\.html',
]

capturadas = []
no_capturadas = []

with open('htmls_faltantes.csv', 'r', encoding='utf-8') as f:
    for i, line in enumerate(f):
        if i == 0:  # Skip header
            continue
        
        encontrado = False
        for pattern in patterns:
            matches = re.findall(pattern, line, re.IGNORECASE)
            if matches:
                encontrado = True
                capturadas.append((i+1, line.strip()))
                break
        
        if not encontrado:
            no_capturadas.append((i+1, line.strip()))

print(f"\n📊 Resumen:")
print(f"   Capturadas:      {len(capturadas):>10,}")
print(f"   NO capturadas:   {len(no_capturadas):>10,}")
print(f"   Total:           {len(capturadas) + len(no_capturadas):>10,}")

if no_capturadas:
    print(f"\n📄 Ejemplos de líneas NO capturadas (primeras 50):")
    print("="*80)
    for num_linea, linea in no_capturadas[:50]:
        # Truncar si es muy larga
        linea_display = linea[:100] + '...' if len(linea) > 100 else linea
        print(f"   {num_linea:>6}: {linea_display}")
    
    print(f"\n💾 Guardando todas las líneas no capturadas en: no_capturadas.txt")
    with open('no_capturadas.txt', 'w', encoding='utf-8') as f:
        for num_linea, linea in no_capturadas:
            f.write(f"{num_linea}: {linea}\n")
    
    print(f"✅ Guardado: no_capturadas.txt ({len(no_capturadas):,} líneas)")

print("\n" + "="*80 + "\n")
