#!/usr/bin/env python3
"""
Diagnóstico LOCC - Identificar artículos de reforma vs artículos reformados
"""
import re
import json

print("=" * 80)
print("DIAGNÓSTICO LOCC - LEY DE REFORMA")
print("=" * 80)

# Leer texto
with open('tools/data/leyes/textos/LOCC.txt', 'r', encoding='utf-8') as f:
    texto = f.read()

# Leer JSON actual
with open('tools/data/leyes/estructurado/LOCC.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

# Buscar TODOS los "Artículo X."
pattern_articulo = r'\bArtículo\s+(\d+)\s*\.'
todos_articulos = re.findall(pattern_articulo, texto)

# Buscar artículos de reforma (los que anuncian cambios)
pattern_modifica = r'Se modifica el artículo (\d+)'
pattern_agrega = r'Se agrega un nuevo artículo'
pattern_deroga = r'Se deroga el artículo (\d+)'

articulos_modifica = re.findall(pattern_modifica, texto)
articulos_agrega = len(re.findall(pattern_agrega, texto))
articulos_deroga = re.findall(pattern_deroga, texto)

print(f"\n📊 CONTEO DE ARTÍCULOS")
print(f"  Total menciones 'Artículo X.': {len(todos_articulos)}")
print(f"  Artículos que modifican:      {len(articulos_modifica)}")
print(f"  Artículos que agregan nuevos: {articulos_agrega}")
print(f"  Artículos que derogan:        {len(articulos_deroga)}")
print(f"  Parser extrajo:               {len(data['articulos'])}")

print(f"\n🔍 ANÁLISIS")
print(f"  La ley de reforma tiene artículos en dos formatos:")
print(f"    1. Artículos de anuncio: 'Artículo X. Se modifica el artículo Y...'")
print(f"    2. Artículos reformados: 'Artículo Y. [contenido reformado]'")
print(f"  ")
print(f"  El parser captura AMBOS tipos, por eso:")
print(f"    108 extraídos / 2 = {len(data['articulos']) // 2} artículos reales")

# Mostrar primeros 10 artículos del JSON
print(f"\n📋 PRIMEROS 10 ARTÍCULOS EXTRAÍDOS:")
for i, art in enumerate(data['articulos'][:10], 1):
    contenido = art['contenido'][:60].replace('\n', ' ')
    print(f"  {i}. Art {art['numero']}: {contenido}...")

# Contar artículos únicos
numeros_unicos = set(art['numero'] for art in data['articulos'])
print(f"\n🎯 NÚMEROS DE ARTÍCULOS ÚNICOS: {len(numeros_unicos)}")
print(f"  Números: {sorted(numeros_unicos, key=lambda x: int(x))[:20]}...")

# Buscar duplicados
from collections import Counter
counter = Counter(art['numero'] for art in data['articulos'])
duplicados = {k: v for k, v in counter.items() if v > 1}

print(f"\n⚠️  ARTÍCULOS DUPLICADOS:")
for num, count in sorted(duplicados.items(), key=lambda x: int(x[0]))[:10]:
    print(f"  Artículo {num}: {count} veces")

print(f"\n💡 SOLUCIÓN:")
print(f"  Para LOCC necesitamos un parser especializado que:")
print(f"    1. Identifique que es una ley de reforma")
print(f"    2. Solo capture los artículos DESPUÉS de 'quedando la redacción de la siguiente manera:'")
print(f"    3. Ignore los artículos de anuncio de reforma")
print(f"  Esto debería reducir de 108 a ~43 artículos")

print("=" * 80)
