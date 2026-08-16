#!/usr/bin/env python3
"""
Script para probar la API de Supabase de IaJuriss
y ver la estructura de las leyes
"""

import requests
import json

# API de Supabase de IaJuriss
BASE_URL = 'https://khtepgjieasapanfxjft.supabase.co/rest/v1'
API_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtodGVwZ2ppZWFzYXBhbmZ4amZ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAxNDY3MzgsImV4cCI6MjA4NTcyMjczOH0.qt3TTd4EniWQevrm0XuxW0H8hsOx1-AIG8u6744mERk'

headers = {
    'apikey': API_KEY,
    'Authorization': f'Bearer {API_KEY}'
}

print("=" * 80)
print("🔍 EXPLORANDO API DE IAJURISS - LEYES VENEZOLANAS")
print("=" * 80)
print()

# 1. Obtener lista de leyes
print("📚 Obteniendo primeras 5 leyes...")
response = requests.get(
    f'{BASE_URL}/leyes_venezolanas',
    headers=headers,
    params={
        'select': 'id,titulo_oficial,titulo_corto,acronimo,numero_articulos',
        'limit': 5,
        'esta_vigente': 'eq.true'
    }
)

if response.status_code == 200:
    leyes = response.json()
    print(f"✅ {len(leyes)} leyes obtenidas\n")
    
    for ley in leyes:
        print(f"📜 {ley.get('titulo_corto', 'Sin título')}")
        print(f"   ID: {ley.get('id')}")
        print(f"   Artículos: {ley.get('numero_articulos', 'N/A')}")
        print()
    
    # Guardar primera ley para análisis
    if leyes:
        primera_ley_id = leyes[0]['id']
        print(f"📖 Obteniendo TODOS los campos de: {leyes[0].get('titulo_corto')}")
        print()
        
        # Obtener todos los campos de la primera ley
        response_detalle = requests.get(
            f'{BASE_URL}/leyes_venezolanas',
            headers=headers,
            params={'id': f'eq.{primera_ley_id}'}
        )
        
        if response_detalle.status_code == 200:
            ley_completa = response_detalle.json()[0]
            print("=" * 80)
            print("📚 LEY COMPLETA - TODOS LOS CAMPOS:")
            print("=" * 80)
            print(json.dumps(ley_completa, indent=2, ensure_ascii=False))
            print()
            
            # Buscar campo con URL del PDF
            print("=" * 80)
            print("🔍 BUSCANDO URL DEL PDF...")
            print("=" * 80)
            campos_pdf = ['url_pdf', 'pdf_url', 'archivo_pdf', 'pdf', 'url_archivo', 'archivo', 'nombre_archivo']
            for campo in campos_pdf:
                if campo in ley_completa and ley_completa[campo]:
                    print(f"✅ Campo encontrado: {campo}")
                    print(f"   Valor: {ley_completa[campo]}")
                    print()
            print()
else:
    print(f"❌ Error: {response.status_code}")
    print(response.text)

print()
print("=" * 80)
print("🔍 BUSCANDO TABLA DE ARTÍCULOS...")
print("=" * 80)

# 2. Buscar si existe una tabla de artículos
tablas_posibles = [
    'articulos',
    'articulos_ley',
    'estructura_leyes',
    'contenido_leyes',
    'libros',
    'titulos',
    'capitulos'
]

for tabla in tablas_posibles:
    try:
        response = requests.get(
            f'{BASE_URL}/{tabla}',
            headers=headers,
            params={'limit': 1}
        )
        if response.status_code == 200:
            print(f"✅ Tabla encontrada: {tabla}")
            datos = response.json()
            if datos:
                print(f"   Campos: {list(datos[0].keys())}")
        elif response.status_code == 404:
            print(f"❌ No existe: {tabla}")
        else:
            print(f"⚠️  {tabla}: Status {response.status_code}")
    except Exception as e:
        print(f"⚠️  Error al consultar {tabla}: {e}")

print()
print("=" * 80)
print("✅ EXPLORACIÓN COMPLETADA")
print("=" * 80)
