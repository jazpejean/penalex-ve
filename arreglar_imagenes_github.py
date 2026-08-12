#!/usr/bin/env python3
"""
Arreglar SOLO logos en HTMLs de R2 - SIN Supabase
"""
import os
import sys
import re
import gzip
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
import threading

# Instalar dependencias
try:
    import boto3
except ImportError:
    print("📦 Instalando boto3...")
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
R2_PUBLIC_URL = os.environ.get('R2_PUBLIC_URL', 'https://pub-a6e0bfa2e9174e91b031ae28c0667009.r2.dev')
LOGO_CORRECTO = f'{R2_PUBLIC_URL}/assets/logo.jpg'

# Validar
if not all([R2_ACCOUNT_ID, R2_ACCESS_KEY, R2_SECRET_KEY]):
    print("❌ Faltan variables de entorno:")
    print(f"   R2_ACCOUNT_ID: {'✅' if R2_ACCOUNT_ID else '❌'}")
    print(f"   R2_ACCESS_KEY_ID: {'✅' if R2_ACCESS_KEY else '❌'}")
    print(f"   R2_SECRET_ACCESS_KEY: {'✅' if R2_SECRET_KEY else '❌'}")
    sys.exit(1)

# Patrones de imágenes rotas
PATRONES_ROTOS = [
    r'https://pub-a6e0bfa2e9174e91b031ae28c0667009\.r2\.dev/html/[^"\'<>\s]+_archivos/[^"\'<>\s]+\.(jpg|png|gif|jpeg)',
    r'https://historico\.tsj\.gob\.ve/graficos/encabezadotsj\.jpg',
    r'http://historico\.tsj\.gob\.ve/graficos/encabezadotsj\.jpg',
    r'\./[^"\'<>\s]+_archivos/[^"\'<>\s]+\.(jpg|png|gif|jpeg)',
    r'(?<![:/])[^/"\s]+_archivos/[^"\'<>\s]+\.(jpg|png|gif|jpeg)',
    r'/graficos/encabezadotsj\.jpg',
    r'/imagenes/[^"\'<>\s]+\.(jpg|png|gif|jpeg)',
]

# Cliente S3 thread-local
_local = threading.local()

def get_s3():
    if not hasattr(_local, 's3'):
        _local.s3 = boto3.client(
            's3',
            endpoint_url=f'https://{R2_ACCOUNT_ID}.r2.cloudflarestorage.com',
            aws_access_key_id=R2_ACCESS_KEY,
            aws_secret_access_key=R2_SECRET_KEY,
            region_name='auto',
            config=Config(signature_version='s3v4')
        )
    return _local.s3

def arreglar_html(key):
    """Descarga HTML, corrige imágenes, re-sube"""
    try:
        s3 = get_s3()
        
        # Descargar
        response = s3.get_object(Bucket=R2_BUCKET, Key=key)
        content_encoding = response.get('ContentEncoding', '')
        raw_data = response['Body'].read()
        
        # Decodificar
        if 'gzip' in content_encoding:
            html = gzip.decompress(raw_data).decode('utf-8')
        else:
            try:
                html = raw_data.decode('utf-8')
            except UnicodeDecodeError:
                html = raw_data.decode('latin-1')
        
        html_original = html
        
        # Eliminar bloques VML de Word
        html = re.sub(r'<!--\[if gte vml 1\]>.*?<!\[endif\]-->', '', html, flags=re.DOTALL | re.IGNORECASE)
        
        # Reemplazar imágenes rotas
        for patron in PATRONES_ROTOS:
            html = re.sub(patron, LOGO_CORRECTO, html, flags=re.IGNORECASE)
        
        # Solo re-subir si cambió
        if html_original == html:
            return (key, False, None)
        
        # Re-subir comprimido
        data_corregida = gzip.compress(html.encode('utf-8'), 6)
        s3.put_object(
            Bucket=R2_BUCKET,
            Key=key,
            Body=data_corregida,
            ContentType='text/html; charset=utf-8',
            ContentEncoding='gzip'
        )
        
        return (key, True, None)
        
    except Exception as e:
        return (key, False, str(e))

# MAIN
print("=" * 80)
print("🔧 ARREGLAR LOGOS EN R2")
print("=" * 80)
print(f"\n✅ Bucket: {R2_BUCKET}")
print(f"✅ Logo: {LOGO_CORRECTO}")

# Listar HTMLs
print("\n📂 Listando HTMLs en R2...")
s3 = get_s3()
html_keys = []
continuation_token = None

try:
    while True:
        if continuation_token:
            response = s3.list_objects_v2(
                Bucket=R2_BUCKET,
                Prefix='html/',
                ContinuationToken=continuation_token
            )
        else:
            response = s3.list_objects_v2(Bucket=R2_BUCKET, Prefix='html/')
        
        if 'Contents' in response:
            for obj in response['Contents']:
                key = obj['Key']
                if key.endswith('.html') or key.endswith('.HTML'):
                    html_keys.append(key)
        
        print(f"   HTMLs: {len(html_keys):,}", end='\r')
        
        if not response.get('IsTruncated'):
            break
        
        continuation_token = response.get('NextContinuationToken')

except Exception as e:
    print(f"\n❌ Error listando: {e}")
    sys.exit(1)

print(f"\n✅ Total: {len(html_keys):,}")

if not html_keys:
    print("⚠️  No hay HTMLs")
    sys.exit(0)

# Procesar
print(f"\n🔧 Procesando {len(html_keys):,} HTMLs...")

stats = {'modificados': 0, 'sin_cambios': 0, 'errores': 0}
stats_lock = threading.Lock()

MAX_WORKERS = int(os.environ.get('MAX_WORKERS', '10'))
start_time = time.time()

with ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
    futures = {executor.submit(arreglar_html, key): key for key in html_keys}
    
    procesados = 0
    
    for future in as_completed(futures):
        key, modificado, error = future.result()
        procesados += 1
        
        with stats_lock:
            if error:
                stats['errores'] += 1
            elif modificado:
                stats['modificados'] += 1
            else:
                stats['sin_cambios'] += 1
        
        if procesados % 100 == 0 or procesados == len(html_keys):
            elapsed = time.time() - start_time
            rate = procesados / elapsed if elapsed > 0 else 0
            eta = (len(html_keys) - procesados) / rate if rate > 0 else 0
            
            print(f"   📊 {procesados:,}/{len(html_keys):,} | "
                  f"Modificados: {stats['modificados']:,} | "
                  f"Errores: {stats['errores']} | "
                  f"{rate:.1f}/s | ETA: {eta/60:.1f}min")

elapsed = time.time() - start_time

print("\n" + "=" * 80)
print("✅ COMPLETADO")
print("=" * 80)
print(f"\n📊 RESUMEN:")
print(f"   Total:       {procesados:,}")
print(f"   Modificados: {stats['modificados']:,}")
print(f"   Sin cambios: {stats['sin_cambios']:,}")
print(f"   Errores:     {stats['errores']}")
print(f"   Tiempo:      {elapsed/60:.1f} min")
print(f"   Velocidad:   {procesados/elapsed:.1f} arch/s")

# Generar índices
print("\n" + "=" * 80)
print("📋 GENERANDO ÍNDICES")
print("=" * 80)

try:
    print("\n📂 Listando TXTs...")
    txt_keys = []
    continuation_token = None
    
    while True:
        if continuation_token:
            response = s3.list_objects_v2(
                Bucket=R2_BUCKET,
                Prefix='txt/',
                ContinuationToken=continuation_token
            )
        else:
            response = s3.list_objects_v2(Bucket=R2_BUCKET, Prefix='txt/')
        
        if 'Contents' in response:
            for obj in response['Contents']:
                k = obj['Key']
                if k.lower().endswith('.txt'):
                    txt_keys.append(k)
        
        print(f"   TXTs: {len(txt_keys):,}", end='\r')
        
        if not response.get('IsTruncated'):
            break
        continuation_token = response.get('NextContinuationToken')
    
    print(f"\n✅ Total TXTs: {len(txt_keys):,}")
    
    # Crear diccionarios
    html_dict = {}
    for key in html_keys:
        doc_id = key.replace('html/', '').replace('.html', '').replace('.HTML', '')
        html_dict[doc_id] = f"{R2_PUBLIC_URL}/{key}"
    
    txt_dict = {}
    for key in txt_keys:
        doc_id = key.replace('txt/', '').replace('.txt', '').replace('.TXT', '')
        txt_dict[doc_id] = f"{R2_PUBLIC_URL}/{key}"
    
    all_ids = sorted(set(html_dict.keys()) | set(txt_dict.keys()))
    
    # Guardar índices
    with open('indice_html.txt', 'w', encoding='utf-8') as f:
        for doc_id in sorted(html_dict.keys()):
            f.write(f"{doc_id}\t{html_dict[doc_id]}\n")
    
    with open('indice_txt.txt', 'w', encoding='utf-8') as f:
        for doc_id in sorted(txt_dict.keys()):
            f.write(f"{doc_id}\t{txt_dict[doc_id]}\n")
    
    with open('indice_completo.csv', 'w', encoding='utf-8') as f:
        f.write("id,url_html,url_txt\n")
        for doc_id in all_ids:
            f.write(f"{doc_id},{html_dict.get(doc_id,'')},{txt_dict.get(doc_id,'')}\n")
    
    print(f"\n💾 indice_html.txt: {len(html_dict):,} archivos")
    print(f"💾 indice_txt.txt: {len(txt_dict):,} archivos")
    print(f"💾 indice_completo.csv: {len(all_ids):,} documentos")
    
    solo_html = len([i for i in all_ids if i in html_dict and i not in txt_dict])
    solo_txt = len([i for i in all_ids if i in txt_dict and i not in html_dict])
    ambos = len([i for i in all_ids if i in html_dict and i in txt_dict])
    
    print(f"\n📊 ESTADÍSTICAS:")
    print(f"   Con HTML y TXT: {ambos:,}")
    print(f"   Solo HTML:      {solo_html:,}")
    print(f"   Solo TXT:       {solo_txt:,}")

except Exception as e:
    print(f"\n❌ Error generando índices: {e}")

print("\n" + "=" * 80 + "\n")

sys.exit(0 if stats['errores'] < len(html_keys) * 0.05 else 1)
