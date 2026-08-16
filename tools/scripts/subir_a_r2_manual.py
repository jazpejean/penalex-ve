#!/usr/bin/env python3
"""
Subir HTML y TXT a R2 manualmente usando requests
"""
import os
import re
import json
import requests
import urllib.request
from bs4 import BeautifulSoup
from datetime import datetime
import hashlib
import hmac
from dotenv import load_dotenv

load_dotenv()

URL_TSJ = "https://historico.tsj.gob.ve/decisiones/scon/julio/820-260700-644,%20645,%20652%20..htm"
ID_SUPABASE = "sentencias/constitucional/2000_820_exp_644"

print("=" * 80)
print("📥 SUBIR SENTENCIA A R2")
print("=" * 80)

# 1. Descargar HTML
print(f"\n📥 Descargando HTML...")
import ssl
ssl_context = ssl._create_unverified_context()
req = urllib.request.Request(URL_TSJ, headers={'User-Agent': 'Mozilla/5.0'})
with urllib.request.urlopen(req, timeout=30, context=ssl_context) as response:
    html_content = response.read().decode('latin-1', errors='ignore')
print(f"✅ {len(html_content):,} caracteres")

# 2. Corregir logos
print(f"\n🖼️  Corrigiendo logos...")
LOGO_CORRECTO = 'https://pub-a6e0bfa2e9174e91b031ae28c0667009.r2.dev/assets/logo.jpg'
patrones = [
    (r'https?://pub-[a-f0-9]+\.r2\.dev/[^"\s]*?(?:logo|image\d+|header)\.(?:jpg|gif|png)', LOGO_CORRECTO),
    (r'https?://historico\.tsj\.(?:gov\.ve|gob\.ve)/[^"\s]*?(?:logo|image\d+|admin|portal)\.(?:jpg|gif|png)', LOGO_CORRECTO),
    (r'(?:\.\.\/)+(?:_archivos|portal|admin)/[^"\s]*?(?:logo|image\d+)\.(?:jpg|gif|png)', LOGO_CORRECTO),
]
for patron, reemplazo in patrones:
    html_content = re.sub(patron, reemplazo, html_content, flags=re.IGNORECASE)
print(f"✅ Logos corregidos")

# 3. Extraer texto
print(f"\n📝 Extrayendo texto...")
soup = BeautifulSoup(html_content, 'html.parser')
for tag in soup(['script', 'style']):
    tag.decompose()
texto = soup.get_text(separator='\n', strip=True)
print(f"✅ {len(texto):,} caracteres")

# 4. Subir a R2 usando wrangler (más simple)
print(f"\n☁️  Preparando archivos...")

# Guardar temporalmente
with open('/tmp/sentencia.html', 'w', encoding='utf-8') as f:
    f.write(html_content)
with open('/tmp/sentencia.txt', 'w', encoding='utf-8') as f:
    f.write(texto)

print(f"✅ Archivos guardados en /tmp/")

print("\n" + "=" * 80)
print("⚠️  NECESITAS SUBIR MANUALMENTE A R2:")
print("=" * 80)
print(f"\nOpción 1 - Desde el Dashboard de Cloudflare:")
print(f"1. Ve a: https://dash.cloudflare.com/9245781c2bca24b4c7e868111ef122f7/r2/default/buckets/penalex-ve")
print(f"2. Navega a la carpeta: html/sentencias/constitucional/")
print(f"3. Sube: /tmp/sentencia.html como 2000_820_exp_644.html")
print(f"4. Navega a la carpeta: txt/sentencias/constitucional/")
print(f"5. Sube: /tmp/sentencia.txt como 2000_820_exp_644.txt")

print(f"\nOpción 2 - Usar wrangler CLI:")
print(f"npx wrangler r2 object put penalex-ve/html/sentencias/constitucional/2000_820_exp_644.html --file=/tmp/sentencia.html")
print(f"npx wrangler r2 object put penalex-ve/txt/sentencias/constitucional/2000_820_exp_644.txt --file=/tmp/sentencia.txt")

print(f"\nLuego ejecuta para actualizar Supabase:")
print(f"python3 agregar_sentencia_simple.py")

print("\n" + "=" * 80)
