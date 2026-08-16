#!/usr/bin/env python3
"""
Genera índice completo de archivos en R2 sin modificar nada
"""
import os
import sys

try:
    import boto3
except ImportError:
    os.system("pip install -q boto3")
    import boto3

from botocore.config import Config

# Cargar .env si existe
try:
    from dotenv import load_dotenv
    load_dotenv()
except:
    pass

# Config
R2_ACCOUNT_ID = os.environ.get('R2_ACCOUNT_ID') or os.environ.get('CLOUDFLARE_ACCOUNT_ID')
R2_ACCESS_KEY = os.environ.get('R2_ACCESS_KEY_ID')
R2_SECRET_KEY = os.environ.get('R2_SECRET_ACCESS_KEY')
R2_BUCKET = os.environ.get('R2_BUCKET_NAME', 'penalex-ve')
R2_PUBLIC_URL = 'https://pub-a6e0bfa2e9174e91b031ae28c0667009.r2.dev'

if not all([R2_ACCOUNT_ID, R2_ACCESS_KEY, R2_SECRET_KEY]):
    print("❌ Faltan credenciales R2")
    sys.exit(1)

print("=" * 70)
print("📋 GENERAR ÍNDICE COMPLETO")
print("=" * 70 + "\n")

# Cliente S3
s3 = boto3.client(
    's3',
    endpoint_url=f'https://{R2_ACCOUNT_ID}.r2.cloudflarestorage.com',
    aws_access_key_id=R2_ACCESS_KEY,
    aws_secret_access_key=R2_SECRET_KEY,
    region_name='auto',
    config=Config(signature_version='s3v4')
)

paginator = s3.get_paginator('list_objects_v2')

# Listar HTMLs
print("📂 Listando HTMLs...")
htmls = []
pg = 0

for page in paginator.paginate(Bucket=R2_BUCKET, Prefix='html/', PaginationConfig={'PageSize': 1000}):
    pg += 1
    if 'Contents' in page:
        htmls.extend([o['Key'] for o in page['Contents'] if o['Key'].lower().endswith('.html')])
        print(f"  Página {pg}: {len(htmls):,} HTMLs", end='\r', flush=True)

print(f"\n✅ Total: {len(htmls):,} HTMLs\n")

# Listar TXTs
print("📂 Listando TXTs...")
txts = []
pg = 0

for page in paginator.paginate(Bucket=R2_BUCKET, Prefix='txt/', PaginationConfig={'PageSize': 1000}):
    pg += 1
    if 'Contents' in page:
        txts.extend([o['Key'] for o in page['Contents'] if o['Key'].lower().endswith('.txt')])
        print(f"  Página {pg}: {len(txts):,} TXTs", end='\r', flush=True)

print(f"\n✅ Total: {len(txts):,} TXTs\n")

# Crear diccionarios
html_map = {}
for k in htmls:
    doc_id = k.replace('html/', '').replace('.html', '').replace('.HTML', '')
    html_map[doc_id] = f"{R2_PUBLIC_URL}/{k}"

txt_map = {}
for k in txts:
    doc_id = k.replace('txt/', '').replace('.txt', '').replace('.TXT', '')
    txt_map[doc_id] = f"{R2_PUBLIC_URL}/{k}"

all_ids = sorted(set(html_map.keys()) | set(txt_map.keys()))

# Guardar índice
print("💾 Guardando indice_completo.csv...")
with open('indice_completo.csv', 'w', encoding='utf-8') as f:
    f.write("id,url_html,url_txt\n")
    for doc_id in all_ids:
        h = html_map.get(doc_id, '')
        t = txt_map.get(doc_id, '')
        f.write(f"{doc_id},{h},{t}\n")

print(f"✅ Guardado: {len(all_ids):,} documentos\n")

ambos = sum(1 for i in all_ids if i in html_map and i in txt_map)
solo_h = sum(1 for i in all_ids if i in html_map and i not in txt_map)
solo_t = sum(1 for i in all_ids if i in txt_map and i not in html_map)

print(f"📊 Estadísticas:")
print(f"   Con ambos:  {ambos:,}")
print(f"   Solo HTML:  {solo_h:,}")
print(f"   Solo TXT:   {solo_t:,}\n")

print("=" * 70)
print("✅ ÍNDICE GENERADO")
print("=" * 70 + "\n")
