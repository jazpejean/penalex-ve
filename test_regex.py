#!/usr/bin/env python3
"""
Test del regex para verificar que capture las URLs correctamente
"""

import re

# La URL del logo correcto
LOGO_CORRECTO = 'https://pub-a6e0bfa2e9174e91b031ae28c0667009.r2.dev/assets/logo.jpg'

# Patrones actualizados (orden importa)
PATRONES_ROTOS = [
    r'https://pub-a6e0bfa2e9174e91b031ae28c0667009\.r2\.dev/html/[^"\'<>\s]+_archivos/[^"\'<>\s]+\.(jpg|png|gif|jpeg)',
    r'https://historico\.tsj\.gob\.ve/graficos/encabezadotsj\.jpg',
    r'http://historico\.tsj\.gob\.ve/graficos/encabezadotsj\.jpg',
    r'/graficos/encabezadotsj\.jpg',
    r'/imagenes/[^"\'<>\s]+\.(jpg|png|gif|jpeg)',
]

# URLs de prueba (las que mencionaste)
urls_test = [
    'https://pub-a6e0bfa2e9174e91b031ae28c0667009.r2.dev/html/jurisprudencias/constitucional/01-200100-00-002_archivos/image001.jpg',
    'https://pub-a6e0bfa2e9174e91b031ae28c0667009.r2.dev/html/sentencias/constitucional/05-270100-00-003_archivos/image001.jpg',
    '/graficos/encabezadotsj.jpg',
    'https://historico.tsj.gob.ve/graficos/encabezadotsj.jpg',
]

print("="*80)
print("🧪 TEST DE REGEX")
print("="*80)

print(f"\n✅ Logo correcto: {LOGO_CORRECTO}\n")

for url in urls_test:
    print(f"URL original: {url}")
    
    encontrado = False
    for patron in PATRONES_ROTOS:
        if re.search(patron, url):
            print(f"  ✅ Capturado por: {patron[:50]}...")
            encontrado = True
            break
    
    if not encontrado:
        print(f"  ❌ NO capturado por ningún patrón")
    
    # Simular reemplazo
    html_test = f'<img src="{url}">'
    html_corregido = html_test
    for patron in PATRONES_ROTOS:
        html_corregido = re.sub(patron, LOGO_CORRECTO, html_corregido, flags=re.IGNORECASE)
    
    if html_test != html_corregido:
        print(f"  ✅ REEMPLAZADO: {html_corregido}")
    else:
        print(f"  ❌ NO REEMPLAZADO")
    
    print()

print("="*80)
