#!/usr/bin/env python3
"""Test final - Simple y directo"""

import re

LOGO_CORRECTO = 'https://pub-a6e0bfa2e9174e91b031ae28c0667009.r2.dev/assets/logo.jpg'

PATRONES_ROTOS = [
    r'https://pub-a6e0bfa2e9174e91b031ae28c0667009\.r2\.dev/html/[^"\'<>\s]+_archivos/[^"\'<>\s]+\.(jpg|png|gif|jpeg)',
    r'https://historico\.tsj\.gob\.ve/graficos/encabezadotsj\.jpg',
    r'http://historico\.tsj\.gob\.ve/graficos/encabezadotsj\.jpg',
    r'\./[^"\'<>\s]+_archivos/[^"\'<>\s]+\.(jpg|png|gif|jpeg)',
    r'(?<![:/])[^/"\s]+_archivos/[^"\'<>\s]+\.(jpg|png|gif|jpeg)',
    r'/graficos/encabezadotsj\.jpg',
    r'/imagenes/[^"\'<>\s]+\.(jpg|png|gif|jpeg)',
]

html_original = '''<html xmlns:v="urn:schemas-microsoft-com:vml" xmlns:o="urn:schemas-microsoft-com:office:office">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=windows-1252">
<link rel="File-List" href="./01-200100-00-002_archivos/filelist.xml">
<!--[if gte mso 9]><xml>
 <o:DocumentProperties>
  <o:Company>Tribunal Supremo de Justicia</o:Company>
 </o:DocumentProperties>
</xml><![endif]-->
</head>
<body>
<h1>
<img width="235" height="192" src="./01-200100-00-002_archivos/image001.jpg">
<span>sala constitucional</span>
</h1>
<p>Contenido de la sentencia...</p>
</body>
</html>'''

print("="*80)
print("TEST FINAL - SIMPLE Y DIRECTO")
print("="*80)

print("\n1️⃣  HTML ORIGINAL:")
print("-"*80)
print(html_original[:500])
print("...")

# PASO 1: Eliminar <head> de Microsoft Word
html = re.sub(
    r'<html[^>]*xmlns:v[^>]*>.*?</head>',
    '<html><head><meta charset="UTF-8"><title>Sentencia</title></head>',
    html_original,
    flags=re.DOTALL | re.IGNORECASE
)

print("\n2️⃣  DESPUÉS DE ELIMINAR <head> DE WORD:")
print("-"*80)
print(html[:500])
print("...")

# PASO 2: Reemplazar imágenes
for patron in PATRONES_ROTOS:
    html = re.sub(patron, LOGO_CORRECTO, html, flags=re.IGNORECASE)

print("\n3️⃣  RESULTADO FINAL:")
print("-"*80)
print(html)

print("\n" + "="*80)
print("VERIFICACIÓN:")
print("="*80)

checks = [
    ("xmlns:v eliminado", "xmlns:v" not in html),
    ("xmlns:o eliminado", "xmlns:o" not in html),
    ("<head> limpio", "<meta charset=\"UTF-8\">" in html),
    ("Logo correcto", LOGO_CORRECTO in html),
    ("Texto preservado", "sala constitucional" in html),
    ("Imagen rota eliminada", "01-200100-00-002_archivos" not in html),
]

for nombre, resultado in checks:
    print(f"  {'✅' if resultado else '❌'} {nombre}")

print("\n" + "="*80)
