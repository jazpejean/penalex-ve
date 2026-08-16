#!/usr/bin/env python3
import json
import sys

with open('leyes_json/LOPNNA.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

articulos = []

for ley in data.get('leyes', []):
    for titulo in ley.get('titulos', []):
        for art in titulo.get('articulos', []):
            articulos.append(art.get('numero'))
        for cap in titulo.get('capitulos', []):
            for art in cap.get('articulos', []):
                articulos.append(art.get('numero'))
            for sec in cap.get('secciones', []):
                for art in sec.get('articulos', []):
                    articulos.append(art.get('numero'))

numericos = sorted([a for a in articulos if isinstance(a, int)])
especiales = sorted([a for a in articulos if not isinstance(a, int)])

print("="*80)
print("VERIFICACIÓN: LOPNNA")
print("="*80)
print(f"\nTotal artículos: {len(articulos)}")
print(f"Artículos numéricos: {len(numericos)} (rango {min(numericos)}-{max(numericos)})")
print(f"Artículos especiales: {len(especiales)}")

if especiales:
    print(f"\nArtículos con numeración especial:")
    for e in especiales:
        print(f"  - {e}")

esperados = set(range(1, max(numericos) + 1))
encontrados = set(numericos)
faltantes = sorted(esperados - encontrados)

if faltantes:
    print(f"\n✗ ARTÍCULOS FALTANTES: {len(faltantes)}")
    print(f"  {faltantes}")
else:
    print(f"\n✓ SECUENCIA COMPLETA: Todos los artículos del 1 al {max(numericos)} presentes")

# Verificar duplicados
duplicados = [n for n in set(numericos) if numericos.count(n) > 1]
if duplicados:
    print(f"\n✗ ARTÍCULOS DUPLICADOS: {sorted(duplicados)}")
else:
    print("\n✓ Sin duplicados")

print("="*80)
sys.exit(0)
