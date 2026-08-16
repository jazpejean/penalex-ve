#!/usr/bin/env python3
"""
Script para obtener SOLO leyes penales desde IaJuriss:
- Constitución
- Códigos penales
- Leyes penales
"""

import requests
import json

BASE_URL = 'https://khtepgjieasapanfxjft.supabase.co/rest/v1'
API_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtodGVwZ2ppZWFzYXBhbmZ4amZ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAxNDY3MzgsImV4cCI6MjA4NTcyMjczOH0.qt3TTd4EniWQevrm0XuxW0H8hsOx1-AIG8u6744mERk'

headers = {'apikey': API_KEY, 'Authorization': f'Bearer {API_KEY}'}

print('=' * 80)
print('🔍 BUSCANDO LEYES PENALES EN IAJURISS')
print('=' * 80)
print()

# ==============================================================================
# PASO 1: Obtener TODAS las leyes para filtrar
# ==============================================================================
print('📚 Descargando lista completa de leyes...')

r = requests.get(
    f'{BASE_URL}/leyes_venezolanas',
    headers=headers,
    params={
        'select': 'id,titulo_oficial,titulo_corto,acronimo,rama_derecho,tipo_instrumento,numero_articulos,nombre_archivo,esta_vigente',
        'esta_vigente': 'eq.true'
    }
)

if r.status_code != 200:
    print(f'❌ Error: {r.status_code}')
    print(r.text)
    exit(1)

todas_leyes = r.json()
print(f'✅ {len(todas_leyes)} leyes totales descargadas')
print()

# ==============================================================================
# PASO 2: Filtrar leyes penales
# ==============================================================================
print('🔎 Filtrando leyes penales...')
print()

# Palabras clave para identificar leyes penales
palabras_clave_penales = [
    'penal', 'pena', 'código penal', 'copp', 'procesal penal',
    'delito', 'constitución', 'constitucion', 'policía',
    'ministerio público', 'defensa pública', 'prisión',
    'flagrancia', 'violencia', 'drogas', 'crimen organizado'
]

leyes_penales = []

for ley in todas_leyes:
    titulo = ley.get('titulo_corto', '').lower()
    titulo_oficial = ley.get('titulo_oficial', '').lower()
    rama = ley.get('rama_derecho', '').lower() if ley.get('rama_derecho') else ''
    tipo = ley.get('tipo_instrumento', '').lower() if ley.get('tipo_instrumento') else ''
    
    # Criterios de filtrado
    es_penal = False
    
    # 1. Por rama de derecho
    if 'penal' in rama:
        es_penal = True
    
    # 2. Por tipo (Códigos siempre)
    if tipo == 'codigo' or 'código' in titulo:
        es_penal = True
    
    # 3. Por palabras clave en título
    for palabra in palabras_clave_penales:
        if palabra in titulo or palabra in titulo_oficial:
            es_penal = True
            break
    
    if es_penal:
        leyes_penales.append(ley)

print(f'✅ {len(leyes_penales)} leyes penales encontradas')
print()

# ==============================================================================
# PASO 3: Mostrar resultados
# ==============================================================================
print('=' * 80)
print('📜 LEYES PENALES ENCONTRADAS')
print('=' * 80)
print()

# Ordenar por importancia
orden_prioridad = {
    'constitucion': 0,
    'constitución': 0,
    'código penal': 1,
    'codigo penal': 1,
    'copp': 2,
    'procesal penal': 2
}

def prioridad(ley):
    titulo = ley.get('titulo_corto', '').lower()
    for key, val in orden_prioridad.items():
        if key in titulo:
            return val
    return 99

leyes_penales_ordenadas = sorted(leyes_penales, key=prioridad)

# Mostrar
for idx, ley in enumerate(leyes_penales_ordenadas, 1):
    print(f"{idx:3d}. {ley.get('titulo_corto', 'Sin título')}")
    print(f"     ID: {ley['id']} | Rama: {ley.get('rama_derecho', 'N/A')} | Tipo: {ley.get('tipo_instrumento', 'N/A')}")
    print(f"     Artículos: {ley.get('numero_articulos', '?')} | PDF: {ley.get('nombre_archivo', 'No disponible')}")
    print()

# ==============================================================================
# PASO 4: Guardar JSON
# ==============================================================================
output_file = 'leyes_penales_lista.json'

with open(output_file, 'w', encoding='utf-8') as f:
    json.dump(leyes_penales_ordenadas, f, indent=2, ensure_ascii=False)

print('=' * 80)
print(f'💾 Lista guardada en: {output_file}')
print('=' * 80)
print()

# ==============================================================================
# PASO 5: Resumen por tipo
# ==============================================================================
print('📊 RESUMEN POR TIPO')
print('=' * 80)

tipos_count = {}
for ley in leyes_penales:
    tipo = ley.get('tipo_instrumento', 'DESCONOCIDO')
    tipos_count[tipo] = tipos_count.get(tipo, 0) + 1

for tipo, count in sorted(tipos_count.items()):
    print(f"  {tipo:30s}: {count:3d} leyes")

print()
print('=' * 80)
print('✅ PROCESO COMPLETADO')
print('=' * 80)
print()
print('📋 Siguiente paso:')
print('   Revisar: leyes_penales_lista.json')
print('   Contiene todas las leyes penales con sus metadatos')
