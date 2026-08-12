#!/usr/bin/env python3
"""
Sincronizar URLs entre R2 y Supabase con análisis de diferencias
"""
import os
import sys
import csv
import time
import threading
import requests

try:
    import boto3
except ImportError:
    os.system("pip install -q boto3")
    import boto3

from botocore.config import Config

# Config
R2_ACCOUNT_ID = os.environ.get('R2_ACCOUNT_ID') or os.environ.get('CLOUDFLARE_ACCOUNT_ID')
R2_ACCESS_KEY = os.environ.get('R2_ACCESS_KEY_ID')
R2_SECRET_KEY = os.environ.get('R2_SECRET_ACCESS_KEY')
R2_BUCKET = os.environ.get('R2_BUCKET_NAME', 'penalex-ve')
R2_PUBLIC_URL = 'https://pub-a6e0bfa2e9174e91b031ae28c0667009.r2.dev'

SUPABASE_URL = os.environ.get('SUPABASE_URL')
SUPABASE_KEY = os.environ.get('SUPABASE_SERVICE_KEY') or os.environ.get('SUPABASE_ANON_KEY')

if not all([R2_ACCOUNT_ID, R2_ACCESS_KEY, R2_SECRET_KEY, SUPABASE_URL, SUPABASE_KEY]):
    print("❌ Faltan credenciales")
    sys.exit(1)

print("=" * 80)
print("🔄 SINCRONIZAR URLs R2 ↔ SUPABASE")
print("=" * 80 + "\n")

# 1. LISTAR ARCHIVOS EN R2
print("📂 Paso 1/5: Listando archivos en R2...")
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
htmls = []
pg = 0
for page in paginator.paginate(Bucket=R2_BUCKET, Prefix='html/', PaginationConfig={'PageSize': 1000}):
    pg += 1
    if 'Contents' in page:
        htmls.extend([o['Key'] for o in page['Contents'] if o['Key'].lower().endswith('.html')])
        print(f"  HTMLs: Página {pg}, Total: {len(htmls):,}", end='\r', flush=True)
print(f"\n✅ HTMLs: {len(htmls):,}")

# Listar TXTs
txts = []
pg = 0
for page in paginator.paginate(Bucket=R2_BUCKET, Prefix='txt/', PaginationConfig={'PageSize': 1000}):
    pg += 1
    if 'Contents' in page:
        txts.extend([o['Key'] for o in page['Contents'] if o['Key'].lower().endswith('.txt')])
        print(f"  TXTs: Página {pg}, Total: {len(txts):,}", end='\r', flush=True)
print(f"\n✅ TXTs: {len(txts):,}\n")

# Crear diccionario de R2
r2_docs = {}
for k in htmls:
    doc_id = k.replace('html/', '').replace('.html', '').replace('.HTML', '')
    r2_docs[doc_id] = {'html': f"{R2_PUBLIC_URL}/{k}", 'txt': None}

for k in txts:
    doc_id = k.replace('txt/', '').replace('.txt', '').replace('.TXT', '')
    if doc_id in r2_docs:
        r2_docs[doc_id]['txt'] = f"{R2_PUBLIC_URL}/{k}"
    else:
        r2_docs[doc_id] = {'html': None, 'txt': f"{R2_PUBLIC_URL}/{k}"}

print(f"📊 R2 tiene {len(r2_docs):,} documentos únicos\n")

# 2. OBTENER DOCUMENTOS DE SUPABASE
print("📂 Paso 2/5: Obteniendo documentos de Supabase...")
supabase_docs = {}
offset = 0
batch_size = 1000

while True:
    url = f"{SUPABASE_URL}/rest/v1/jurisprudencia?select=id,numero&limit={batch_size}&offset={offset}"
    headers = {
        'apikey': SUPABASE_KEY,
        'Authorization': f'Bearer {SUPABASE_KEY}'
    }

    response = requests.get(url, headers=headers, timeout=30)
    if response.status_code != 200:
        print(f"❌ Error: {response.status_code}")
        break

    batch = response.json()
    if not batch:
        break

    for doc in batch:
        supabase_docs[doc['id']] = doc.get('numero', '')

    offset += batch_size
    print(f"  Documentos: {len(supabase_docs):,}", end='\r', flush=True)

print(f"\n✅ Supabase tiene {len(supabase_docs):,} documentos\n")

# 3. ANÁLISIS DE DIFERENCIAS
print("📊 Paso 3/5: Analizando diferencias...")

en_r2_no_supabase = set(r2_docs.keys()) - set(supabase_docs.keys())
en_supabase_no_r2 = set(supabase_docs.keys()) - set(r2_docs.keys())
en_ambos = set(r2_docs.keys()) & set(supabase_docs.keys())

print(f"✅ En ambos:             {len(en_ambos):,}")
print(f"⚠️  Solo en R2:           {len(en_r2_no_supabase):,}")
print(f"⚠️  Solo en Supabase:     {len(en_supabase_no_r2):,}\n")

# 4. ACTUALIZAR URLS EN SUPABASE
print("📂 Paso 4/5: Actualizando URLs en Supabase...")
actualizados = 0
errores = 0

for doc_id in en_ambos:
    r2_data = r2_docs[doc_id]

    try:
        url = f"{SUPABASE_URL}/rest/v1/jurisprudencia?id=eq.{doc_id}"
        headers = {
            'apikey': SUPABASE_KEY,
            'Authorization': f'Bearer {SUPABASE_KEY}',
            'Content-Type': 'application/json',
            'Prefer': 'return=minimal'
        }

        data = {
            'url_html': r2_data['html'],
            'url_txt': r2_data['txt']
        }

        response = requests.patch(url, json=data, headers=headers, timeout=10)
        if response.status_code in [200, 204]:
            actualizados += 1
        else:
            errores += 1
    except Exception as e:
        errores += 1

    if (actualizados + errores) % 500 == 0:
        print(f"  {actualizados:,} actualizados, {errores} errores", end='\r', flush=True)

print(f"\n✅ Actualización completada: {actualizados:,} documentos\n")

# 5. GENERAR REPORTES
print("📂 Paso 5/5: Generando reportes...")

# Índice completo
with open('indice_completo.csv', 'w', encoding='utf-8') as f:
    f.write("id,url_html,url_txt\n")
    for doc_id in sorted(r2_docs.keys()):
        html = r2_docs[doc_id]['html'] or ''
        txt = r2_docs[doc_id]['txt'] or ''
        f.write(f"{doc_id},{html},{txt}\n")

# Faltantes en R2
with open('faltantes_en_r2.csv', 'w', encoding='utf-8') as f:
    f.write("id,numero\n")
    for doc_id in sorted(en_supabase_no_r2):
        numero = supabase_docs.get(doc_id, '')
        f.write(f"{doc_id},{numero}\n")

# Faltantes en Supabase
with open('faltantes_en_supabase.csv', 'w', encoding='utf-8') as f:
    f.write("id,url_html,url_txt\n")
    for doc_id in sorted(en_r2_no_supabase):
        html = r2_docs[doc_id]['html'] or ''
        txt = r2_docs[doc_id]['txt'] or ''
        f.write(f"{doc_id},{html},{txt}\n")

# Reporte resumen
with open('reporte_sincronizacion.txt', 'w', encoding='utf-8') as f:
    f.write("=" * 80 + "\n")
    f.write("REPORTE DE SINCRONIZACIÓN\n")
    f.write("=" * 80 + "\n\n")
    f.write(f"📊 ESTADÍSTICAS:\n")
    f.write(f"   Total en R2:          {len(r2_docs):,}\n")
    f.write(f"   Total en Supabase:    {len(supabase_docs):,}\n")
    f.write(f"   En ambos:             {len(en_ambos):,}\n")
    f.write(f"   Solo en R2:           {len(en_r2_no_supabase):,}\n")
    f.write(f"   Solo en Supabase:     {len(en_supabase_no_r2):,}\n\n")
    f.write(f"✅ URLs actualizadas:    {actualizados:,}\n")
    f.write(f"❌ Errores:              {errores}\n\n")
    f.write("=" * 80 + "\n")

print("✅ Reportes generados\n")

print("=" * 80)
print("✅ SINCRONIZACIÓN COMPLETADA")
print("=" * 80)
print(f"\n📊 Resumen:")
print(f"   Actualizados:  {actualizados:,}")
print(f"   Faltantes R2:  {len(en_supabase_no_r2):,}")
print(f"   Faltantes SB:  {len(en_r2_no_supabase):,}")
print("\n" + "=" * 80 + "\n")
