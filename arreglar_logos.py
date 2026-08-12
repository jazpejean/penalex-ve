#!/usr/bin/env python3
"""
Arreglar SOLO el logo del encabezado TSJ y generar índice completo
"""
import os
import sys
import re
import gzip
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
import threading

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

# LOGO CORRECTO
LOGO_URL = f'{R2_PUBLIC_URL}/assets/logo.jpg'

# Validar credenciales
if not all([R2_ACCOUNT_ID, R2_ACCESS_KEY, R2_SECRET_KEY]):
    print("❌ Faltan credenciales R2")
    sys.exit(1)

# SOLO estos patrones (logo del encabezado TSJ)
PATRONES = [
    r'https://historico\.tsj\.gob\.ve/graficos/encabezadotsj\.jpg',
    r'http://historico\.tsj\.gob\.ve/graficos/encabezadotsj\.jpg',
    r'/graficos/encabezadotsj\.jpg',
    r'graficos/encabezadotsj\.jpg',
]

# Cliente thread-safe
_local = threading.local()

def get_s3():
    if not hasattr(_local, 's3'):
        _local.s3 = boto3.client(
            's3',
            endpoint_url=f'https://{R2_ACCOUNT_ID}.r2.cloudflarestorage.com',
            aws_access_key_id=R2_ACCESS_KEY,
            aws_secret_access_key=R2_SECRET_KEY,
            region_name='auto',
            config=Config(signature_version='s3v4', retries={'max_attempts': 3})
        )
    return _local.s3

def procesar_html(key):
    """Arregla logo en un HTML"""
    try:
        s3 = get_s3()
        resp = s3.get_object(Bucket=R2_BUCKET, Key=key)
        raw = resp['Body'].read()
        
        # Decodificar
        if 'gzip' in resp.get('ContentEncoding', ''):
            html = gzip.decompress(raw).decode('utf-8', errors='ignore')
        else:
            html = raw.decode('utf-8', errors='ignore')
        
        original = html
        
        # Reemplazar SOLO logo TSJ
        for patron in PATRONES:
            html = re.sub(patron, LOGO_URL, html, flags=re.IGNORECASE)
        
        # Si no cambió, no subir
        if html == original:
            return (False, None)
        
        # Re-subir
        compressed = gzip.compress(html.encode('utf-8'), 6)
        s3.put_object(
            Bucket=R2_BUCKET,
            Key=key,
            Body=compressed,
            ContentType='text/html; charset=utf-8',
            ContentEncoding='gzip'
        )
        return (True, None)
        
    except Exception as e:
        return (False, str(e))

print("=" * 70)
print("🔧 ARREGLAR LOGOS TSJ EN R2")
print("=" * 70)
print(f"\nLogo: {LOGO_URL}\n")

# Listar HTMLs
print("📂 Listando HTMLs...")
s3 = get_s3()
htmls = []
pg = 0

try:
    paginator = s3.get_paginator('list_objects_v2')
    for page in paginator.paginate(Bucket=R2_BUCKET, Prefix='html/', PaginationConfig={'PageSize': 1000}):
        pg += 1
        if 'Contents' in page:
            htmls.extend([o['Key'] for o in page['Contents'] if o['Key'].lower().endswith('.html')])
            print(f"  Página {pg}: {len(htmls):,} HTMLs", end='\r', flush=True)
    
    print(f"\n✅ Total: {len(htmls):,} HTMLs\n")
except Exception as e:
    print(f"\n❌ Error: {e}")
    sys.exit(1)

if not htmls:
    print("⚠️ No hay HTMLs")
    sys.exit(0)

# Procesar
print("🔧 Procesando...\n")
modificados = errores = procesados = 0
lock = threading.Lock()
workers = int(os.environ.get('MAX_WORKERS', '20'))
inicio = time.time()

with ThreadPoolExecutor(max_workers=workers) as exe:
    futures = {exe.submit(procesar_html, k): k for k in htmls}
    
    for fut in as_completed(futures):
        cambio, err = fut.result()
        
        with lock:
            procesados += 1
            if err:
                errores += 1
            elif cambio:
                modificados += 1
        
        if procesados % 500 == 0 or procesados == len(htmls):
            t = time.time() - inicio
            rate = procesados / t if t > 0 else 0
            eta = (len(htmls) - procesados) / rate / 60 if rate > 0 else 0
            print(f"📊 {procesados:,}/{len(htmls):,} | Mod: {modificados:,} | Err: {errores} | {rate:.1f}/s | ETA: {eta:.1f}min")

t_total = time.time() - inicio

print("\n" + "=" * 70)
print("✅ LOGOS COMPLETADO")
print("=" * 70)
print(f"\nTotal:       {procesados:,}")
print(f"Modificados: {modificados:,}")
print(f"Errores:     {errores}")
print(f"Tiempo:      {t_total/60:.1f} min\n")

# GENERAR ÍNDICE
print("=" * 70)
print("📋 GENERANDO ÍNDICE")
print("=" * 70 + "\n")

try:
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
    
    # Guardar índice completo
    with open('indice_completo.csv', 'w', encoding='utf-8') as f:
        f.write("id,url_html,url_txt\n")
        for doc_id in all_ids:
            h = html_map.get(doc_id, '')
            t = txt_map.get(doc_id, '')
            f.write(f"{doc_id},{h},{t}\n")
    
    print(f"💾 indice_completo.csv: {len(all_ids):,} documentos\n")
    
    ambos = sum(1 for i in all_ids if i in html_map and i in txt_map)
    solo_h = sum(1 for i in all_ids if i in html_map and i not in txt_map)
    solo_t = sum(1 for i in all_ids if i in txt_map and i not in html_map)
    
    print(f"📊 Ambos:     {ambos:,}")
    print(f"   Solo HTML: {solo_h:,}")
    print(f"   Solo TXT:  {solo_t:,}\n")

except Exception as e:
    print(f"\n❌ Error generando índice: {e}\n")

print("=" * 70)
print("✅ PROCESO COMPLETO")
print("=" * 70 + "\n")

sys.exit(0)
