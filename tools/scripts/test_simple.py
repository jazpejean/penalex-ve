#!/usr/bin/env python3
import re

LOGO = 'https://pub-a6e0bfa2e9174e91b031ae28c0667009.r2.dev/assets/logo.jpg'

html = '''<h1><!--[if gte vml 1]><v:imagedata src="./01-200100-00-002_archivos/image001.jpg" o:title="encabezadotsj"/><![endif]--><!--[if !vml]--><img width="235" height="192" src="./01-200100-00-002_archivos/image001.jpg"><!--[endif]--><br>
<span>sala constitucional</span></h1>'''

print("ORIGINAL:")
print(html)
print()

# Paso 1: Reemplazar en v:imagedata
html_paso1 = re.sub(
    r'(<v:imagedata\s+src=")[^"]+_archivos/[^"]+\.(jpg|png|gif|jpeg)(")',
    r'\1' + LOGO + r'\3',
    html,
    flags=re.IGNORECASE
)

print("PASO 1 (v:imagedata):")
print(html_paso1)
print()

# Paso 2: Reemplazar en <img>
html_final = re.sub(
    r'\./[^"\'<>\s]+_archivos/[^"\'<>\s]+\.(jpg|png|gif|jpeg)',
    LOGO,
    html_paso1,
    flags=re.IGNORECASE
)

print("FINAL:")
print(html_final)
print()

if "sala constitucional" in html_final:
    print("✅ Texto preservado")
if html_final.count(LOGO) == 2:
    print("✅ Ambas imágenes reemplazadas")
