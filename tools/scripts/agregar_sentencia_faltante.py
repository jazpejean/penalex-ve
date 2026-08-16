#!/usr/bin/env python3
"""
Descargar, procesar y subir sentencia faltante a R2 y Supabase
"""
import os
import re
import json
import boto3
from botocore.config import Config
import urllib.request
from bs4 import BeautifulSoup
from datetime import datetime
from dotenv import load_dotenv

load_dotenv()

# Configuración
URL_TSJ = "https://historico.tsj.gob.ve/decisiones/scon/julio/820-260700-644,%20645,%20652%20..htm"
ID_SUPABASE = "sentencias/constitucional/2000_820_exp_644"
SALA = "constitucional"
TIPO = "sentencia"

print("=" * 80)
print("📥 AGREGAR SENTENCIA FALTANTE")
print("=" * 80)

# 1. Descargar HTML
print(f"\n📥 Descargando desde TSJ...")
try:
    import ssl
    # Desactivar verificación SSL para el TSJ (certificado expirado)
    ssl_context = ssl._create_unverified_context()
    req = urllib.request.Request(URL_TSJ, headers={'User-Agent': 'Mozilla/5.0'})
    with urllib.request.urlopen(req, timeout=30, context=ssl_context) as response:
        html_content = response.read().decode('latin-1', errors='ignore')
    print(f"✅ HTML descargado: {len(html_content):,} caracteres")
except Exception as e:
    print(f"❌ Error descargando: {e}")
    exit(1)

# 2. Corregir logos rotos en HTML
print(f"\n🖼️  Corrigiendo logos...")
LOGO_CORRECTO = 'https://pub-a6e0bfa2e9174e91b031ae28c0667009.r2.dev/assets/logo.jpg'

# Patrones de logos rotos
patrones_rotos = [
    # URLs completas R2 con _archivos - CAPTURAR ESTE ESPECÍFICO PRIMERO
    (r'https://pub-a6e0bfa2e9174e91b031ae28c0667009\.r2\.dev/html/sentencias/constitucional/820-260700-644,%20645,%20652%20\._archivos/image001\.jpg', LOGO_CORRECTO),
    # URLs completas R2 con _archivos (GENERAL)
    (r'https?://pub-[a-f0-9]+\.r2\.dev/html/[^"\s]+_archivos/image\d+\.(?:jpg|gif|png)', LOGO_CORRECTO),
    # URLs completas R2 rotas
    (r'https?://pub-[a-f0-9]+\.r2\.dev/[^"\s]*?(?:logo|image\d+|header)\.(?:jpg|gif|png)', LOGO_CORRECTO),
    (r'https?://historico\.tsj\.(?:gov\.ve|gob\.ve)/[^"\s]*?(?:logo|image\d+|admin|portal)\.(?:jpg|gif|png)', LOGO_CORRECTO),
    # Rutas relativas
    (r'(?:\.\.\/)+(?:_archivos|portal|admin)/[^"\s]*?(?:logo|image\d+)\.(?:jpg|gif|png)', LOGO_CORRECTO),
    (r'[^"\s]*?/(?:portal|admin|_archivos)/image\d+\.jpg', LOGO_CORRECTO),
]

for patron, reemplazo in patrones_rotos:
    html_content = re.sub(patron, reemplazo, html_content, flags=re.IGNORECASE)

print(f"✅ Logos corregidos")

# 3. Extraer texto del HTML
print(f"\n📝 Extrayendo texto...")
try:
    soup = BeautifulSoup(html_content, 'html.parser')
    # Quitar scripts y styles
    for tag in soup(['script', 'style']):
        tag.decompose()
    texto = soup.get_text(separator='\n', strip=True)
    print(f"✅ Texto extraído: {len(texto):,} caracteres")
except Exception as e:
    print(f"❌ Error extrayendo texto: {e}")
    exit(1)

# 4. Extraer metadata del HTML
print(f"\n🔍 Extrayendo metadata...")
metadata = {
    'fecha': None,
    'num_sentencia': '820',
    'expediente': '644, 645, 652',
    'ponente': None,
    'partes': None,
    'procedimiento': None,
    'decision': None
}

# Buscar fecha (formato: dd/mm/yyyy o similar)
fecha_match = re.search(r'(\d{1,2})\s*de\s*(\w+)\s*de\s*(\d{4})', texto, re.IGNORECASE)
if fecha_match:
    meses = {
        'enero': '01', 'febrero': '02', 'marzo': '03', 'abril': '04',
        'mayo': '05', 'junio': '06', 'julio': '07', 'agosto': '08',
        'septiembre': '09', 'octubre': '10', 'noviembre': '11', 'diciembre': '12'
    }
    dia = fecha_match.group(1).zfill(2)
    mes = meses.get(fecha_match.group(2).lower(), '07')
    ano = fecha_match.group(3)
    metadata['fecha'] = f'{ano}-{mes}-{dia}'
    print(f"   Fecha: {metadata['fecha']}")

# Buscar ponente
ponente_match = re.search(r'Ponente[:\s]+(.+?)(?:\n|$)', texto, re.IGNORECASE)
if ponente_match:
    metadata['ponente'] = ponente_match.group(1).strip()[:200]
    print(f"   Ponente: {metadata['ponente']}")

print(f"✅ Metadata extraída")

# 5. Subir a R2
print(f"\n☁️  Subiendo a Cloudflare R2...")

R2_ACCOUNT_ID = os.environ.get('R2_ACCOUNT_ID')
R2_ACCESS_KEY = os.environ.get('R2_ACCESS_KEY_ID')
R2_SECRET_KEY = os.environ.get('R2_SECRET_ACCESS_KEY')
R2_BUCKET = 'penalex-ve'
R2_PUBLIC_URL = 'https://pub-a6e0bfa2e9174e91b031ae28c0667009.r2.dev'

print(f"   Account: {R2_ACCOUNT_ID}")
print(f"   Bucket: {R2_BUCKET}")

if not all([R2_ACCOUNT_ID, R2_ACCESS_KEY, R2_SECRET_KEY]):
    print("❌ Faltan credenciales R2 en .env")
    exit(1)

try:
    s3 = boto3.client(
        's3',
        endpoint_url=f'https://{R2_ACCOUNT_ID}.r2.cloudflarestorage.com',
        aws_access_key_id=R2_ACCESS_KEY,
        aws_secret_access_key=R2_SECRET_KEY,
        region_name='auto',
        config=Config(signature_version='s3v4')
    )
    
    # Subir HTML
    html_key = f'html/{ID_SUPABASE}.html'
    s3.put_object(
        Bucket=R2_BUCKET,
        Key=html_key,
        Body=html_content.encode('utf-8'),
        ContentType='text/html; charset=utf-8'
    )
    url_html = f'{R2_PUBLIC_URL}/{html_key}'
    print(f"✅ HTML subido: {url_html}")
    
    # Subir TXT
    txt_key = f'txt/{ID_SUPABASE}.txt'
    s3.put_object(
        Bucket=R2_BUCKET,
        Key=txt_key,
        Body=texto.encode('utf-8'),
        ContentType='text/plain; charset=utf-8'
    )
    url_txt = f'{R2_PUBLIC_URL}/{txt_key}'
    print(f"✅ TXT subido: {url_txt}")
    
except Exception as e:
    print(f"❌ Error subiendo a R2: {e}")
    exit(1)

# 6. Actualizar Supabase
print(f"\n💾 Actualizando Supabase...")

SUPABASE_URL = os.environ.get('SUPABASE_URL')
SUPABASE_KEY = os.environ.get('SUPABASE_SERVICE_KEY')

try:
    url = f"{SUPABASE_URL}/rest/v1/documentos?id=eq.{ID_SUPABASE}"
    headers = {
        'apikey': SUPABASE_KEY,
        'Authorization': f'Bearer {SUPABASE_KEY}',
        'Content-Type': 'application/json',
        'Prefer': 'return=minimal'
    }
    
    data = json.dumps({
        'tipo': TIPO,
        'sala': SALA,
        'fecha': metadata['fecha'],
        'num_sentencia': metadata['num_sentencia'],
        'expediente': metadata['expediente'],
        'ponente': metadata['ponente'],
        'url_html': url_html,
        'url_txt': url_txt,
        'url_tsj': URL_TSJ
    }).encode('utf-8')
    
    req = urllib.request.Request(url, data=data, headers=headers, method='PATCH')
    with urllib.request.urlopen(req, timeout=15) as response:
        if response.status in [200, 204]:
            print(f"✅ Supabase actualizado")
        else:
            print(f"⚠️  Status: {response.status}")
            
except Exception as e:
    print(f"❌ Error actualizando Supabase: {e}")

print("\n" + "=" * 80)
print("✅ PROCESO COMPLETADO")
print("=" * 80)
print(f"ID: {ID_SUPABASE}")
print(f"HTML: {url_html}")
print(f"TXT: {url_txt}")
print(f"Fecha: {metadata['fecha']}")
print(f"Ponente: {metadata['ponente']}")
print("=" * 80 + "\n")
