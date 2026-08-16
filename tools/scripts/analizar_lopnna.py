#!/usr/bin/env python3
"""
Analiza LOPNNA.json para encontrar artículos faltantes
"""
import json
import sys

def main():
    with open('/home/jeanjazpe/Desktop/Penalex_VE/tools/data/leyes/estructurado/LOPNNA.json', 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    # Extract all article numbers
    articulos = []
    for seccion in data.get('secciones', []):
        for articulo in seccion.get('articulos', []):
            num_str = articulo.get('numero', '')
            if num_str and num_str.isdigit():
                articulos.append(int(num_str))
    
    articulos_unicos = sorted(set(articulos))
    
    print(f"Total artículos extraídos: {len(articulos)}")
    print(f"Artículos únicos: {len(articulos_unicos)}")
    print(f"Rango: {min(articulos_unicos)} - {max(articulos_unicos)}")
    print(f"Esperados: 683")
    print(f"Faltantes: {683 - len(articulos_unicos)}")
    print()
    
    # Find missing articles
    faltantes = []
    for i in range(1, 684):
        if i not in articulos_unicos:
            faltantes.append(i)
    
    if faltantes:
        print(f"Artículos faltantes ({len(faltantes)}):")
        # Group consecutive ranges
        ranges = []
        start = faltantes[0]
        end = faltantes[0]
        
        for i in range(1, len(faltantes)):
            if faltantes[i] == end + 1:
                end = faltantes[i]
            else:
                if start == end:
                    ranges.append(f"{start}")
                else:
                    ranges.append(f"{start}-{end}")
                start = faltantes[i]
                end = faltantes[i]
        
        # Add last range
        if start == end:
            ranges.append(f"{start}")
        else:
            ranges.append(f"{start}-{end}")
        
        print(", ".join(ranges))
    
    # Find duplicates
    duplicados = []
    seen = {}
    for num in articulos:
        if num in seen:
            seen[num] += 1
        else:
            seen[num] = 1
    
    duplicados = {k: v for k, v in seen.items() if v > 1}
    if duplicados:
        print(f"\nArtículos duplicados: {len(duplicados)}")
        for num, count in sorted(duplicados.items()):
            print(f"  Artículo {num}: {count} veces")

if __name__ == '__main__':
    main()
