#!/usr/bin/env python3
"""
Corregir logo de la sentencia 820 que ya está en R2
"""
import os
import re
import boto3
from botocore.config import Config
from dotenv import load_dotenv

load_dotenv()

R2_ACCOUNT_ID = os.environ.get('R2_ACCOUNT_ID')
R2_ACCESS_KEY = os.environ.get('R2_ACCESS_KEY_ID')
R2_SECRET_KEY = os.environ.get('R2_SECRET_ACCESS_KEY')
R2_BUCKET = 'penalex-ve'
LOGO_CORRECTO = 'https://pub-a6e0bfa2e9174e91b031ae28c0667009.r2.dev/assets/logo.jpg'

print("=" * 80)
print("🔧 CORREGIR LOGO EN SENTENCIA 820")
print("=" * 80)

# 1. Conectar a R2
print("\n☁️  Conectando a R2...")
s3 = boto3.client(
    's3',
    endpoint_url=f'https://{R2_ACCOUNT_ID}.r2.cloudflarestorage.com',
    aws_access_key_id=R2_ACCESS_KEY,
    aws_secret_access_key=R2_SECRET_KEY,
    region_name='auto',
    config=Config(signature_version='s3v4')
)

# 2. Bajar el HTML
html_key = 'html/sentencias/constitucional/2000_820_exp_644.html'
print(f"\n📥 Descargando {html_key}...")

try:
    response = s3.get_object(Bucket=R2_BUCKET, Key=html_key)
    html_content = response['Body'].read().decode('utf-8')
    print(f"✅ Descargado: {len(html_content):,} caracteres")
except Exception as e:
    print(f"❌ Error descargando: {e}")
    exit(1)

# 3. Buscar el logo actual
print(f"\n🔍 Buscando logos...")
logo_pattern = r'https://pub-a6e0bfa2e9174e91b031ae28c0667009\.r2\.dev/html/sentencias/constitucional/820-260700-644,%20645,%20652%20\._archivos/image001\.jpg'
matches = re.findall(logo_pattern, html_content)
print(f"   Encontrados: {len(matches)} logos rotos")

# 4. Reemplazar
print(f"\n🔧 Corrigiendo logos...")
html_corregido = re.sub(logo_pattern, LOGO_CORRECTO, html_content)

# Verificar
if html_content != html_corregido:
    print(f"✅ Logos reemplazados")
else:
    print(f"⚠️  No se encontró el logo a reemplazar")
    print(f"   Buscando cualquier logo en el HTML...")
    # Buscar cualquier mención de image001
    if 'image001' in html_content:
        print(f"   ✓ Se encontró 'image001' en el HTML")
        # Reemplazar cualquier variante
        html_corregido = re.sub(r'[^"\'<>\s]+image001\.jpg', LOGO_CORRECTO, html_content)
        print(f"✅ Logos reemplazados con patrón amplio")

# 5. Subir corregido
print(f"\n☁️  Subiendo HTML corregido...")
try:
    s3.put_object(
        Bucket=R2_BUCKET,
        Key=html_key,
        Body=html_corregido.encode('utf-8'),
        ContentType='text/html; charset=utf-8'
    )
    print(f"✅ HTML corregido subido exitosamente")
except Exception as e:
    print(f"❌ Error subiendo: {e}")
    exit(1)

print("\n" + "=" * 80)
print("✅ LOGO CORREGIDO")
print("=" * 80)
print(f"URL: https://pub-a6e0bfa2e9174e91b031ae28c0667009.r2.dev/{html_key}")
print(f"Logo ahora apunta a: {LOGO_CORRECTO}")
print("=" * 80 + "\n")
