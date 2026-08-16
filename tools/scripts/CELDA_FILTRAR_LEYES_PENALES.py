# ============================================================================
# CELDA PARA COLAB: FILTRAR SOLO LEYES PENALES
# ============================================================================
# Copiar y pegar esta celda en Google Colab para obtener solo leyes penales

import requests
import json

BASE_URL = 'https://khtepgjieasapanfxjft.supabase.co/rest/v1'
API_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtodGVwZ2ppZWFzYXBhbmZ4amZ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAxNDY3MzgsImV4cCI6MjA4NTcyMjczOH0.qt3TTd4EniWQevrm0XuxW0H8hsOx1-AIG8u6744mERk'

headers = {'apikey': API_KEY, 'Authorization': f'Bearer {API_KEY}'}

print('🔍 Obteniendo TODAS las leyes...')

# Obtener todas las leyes
r = requests.get(
    f'{BASE_URL}/leyes_venezolanas',
    headers=headers,
    params={
        'select': 'id,titulo_corto,rama_derecho,tipo_instrumento,numero_articulos,nombre_archivo',
        'esta_vigente': 'eq.true'
    }
)

todas = r.json()
print(f'✅ {len(todas)} leyes totales')
print()

# Filtrar penales
penales = []
for ley in todas:
    titulo = ley.get('titulo_corto', '').lower()
    rama = (ley.get('rama_derecho') or '').lower()
    tipo = (ley.get('tipo_instrumento') or '').lower()
    
    # Criterios
    if ('penal' in titulo or 'penal' in rama or 
        'constitucion' in titulo or 'constitución' in titulo or
        'copp' in titulo or tipo == 'codigo'):
        penales.append(ley)

print(f'📜 {len(penales)} LEYES PENALES ENCONTRADAS:')
print('=' * 70)

# Mostrar
for i, ley in enumerate(penales, 1):
    print(f"{i}. {ley['titulo_corto']}")
    print(f"   ID: {ley['id']} | Rama: {ley.get('rama_derecho', 'N/A')}")
    print(f"   PDF: {ley.get('nombre_archivo', 'No disponible')}")
    print()

# Guardar IDs
ids_penales = [ley['id'] for ley in penales]
print('=' * 70)
print(f'💾 {len(ids_penales)} IDs de leyes penales guardados')
print('📋 IDs:', ids_penales)
