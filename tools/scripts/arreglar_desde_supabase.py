#!/usr/bin/env python3
"""
Procesa archivos usando IDs de Supabase - NO lista R2 (evita cuelgues)
"""
import os
import sys
import re
import gzip
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
import boto3
from botocore.config import Config
from botocore.exceptions import ClientError

try:
    from dotenv import load_dotenv
    load_dotenv()
except:
    pass

# Env Vars
R2_ACCOUNT_ID = os.environ.get('R2_ACCOUNT_ID') or os.environ.get('CLOUDFLARE_ACCOUNT_ID')
R2_ACCESS_KEY = os.environ.get('R2_ACCESS_KEY_ID')
R2_SECRET_KEY = os.environ.get('R2_SECRET_ACCESS_KEY')
R2_BUCKET = os.environ.get('R2_BUCKET_NAME', 'penalex-ve')
R2_PUBLIC_URL = os.environ.get('R2_PUBLIC_URL', 'https://pub-a6e0bfa2e9174e91b031ae28c0667009.r2.dev')
SUPABASE_URL = os.environ.get('SUPABASE_URL')
SUPABASE_KEY = os.environ.get('SUPABASE_ANON_KEY')
LOGO_CORRECTO = f'{R2_PUBLIC_URL}/assets/logo.jpg'

PATRONES_ROTOS = [
    r'https://pub-a6e0bfa2e9174e91b031ae28c0667009\.r2\.dev/html/[^"\'<>\s]+_archivos/[^"\'<>\s]+\.(jpg|png|gif|jpeg)',
    r'https://historico\.tsj\.gob\.ve/graficos/encabezadotsj\.jpg',
    r'http://historico\.tsj\.gob\.ve/graficos/encabezadotsj\.jpg',
    r'\./[^"\'<>\s]+_archivos/[^"\'<>\s]+\.(jpg|png|gif|jpeg)',
    r'(?<![:/])[^/"\s]+_archivos/[^"\'<>\s]+\.(jpg|png|gif|jpeg)',
    r'/graficos/encabezadotsj\.jpg',
    r'/imagenes/[^"\'<>\s]+\.(jpg|png|gif|jpeg)',
]

PATRONES_COMPILADOS = [re.compile(p, re.IGNORECASE) for p in PATRONES_ROTOS]
PATRON_VML = re.compile(r'<!--\[if gte vml 1\]>.*?<!\[endif\]-->', re.DOTALL | re.IGNORECASE)

BOTO3_CONFIG = Config(
    signature_version='s3v4',
    connect_timeout=10,
    read_timeout=30,
    retries={'max_attempts': 3}
)

def get_s3():
    return boto3.client(
        's3',
        endpoint_url=f'https://{R2_ACCOUNT_ID}.r2.cloudflarestorage.com',
        aws_access_key_id=R2_ACCESS_KEY,
        aws_secret_access_key=R2_SECRET_KEY,
        region_name='auto',
        config=BOTO3_CONFIG
    )

def procesar_html(key):
    s3 = get_s3()
    try:
        response = s3.get_object(Bucket=R2_BUCKET, Key=key)
        content_encoding = response.get('ContentEncoding', '')
        raw_data = response['Body'].read()
        
        if 'gzip' in content_encoding:
            html = gzip.decompress(raw_data).decode('utf-8', errors='replace')
        else:
            html = raw_data.decode('utf-8', errors='replace')
        
        html_corregido = PATRON_VML.sub('', html)
        for patron in PATRONES_COMPILADOS:
            html_corregido = patron.sub(LOGO_CORRECTO, html_corregido)
        
        if html_corregido != html:
            data_corregida = gzip.compress(html_corregido.encode('utf-8'), compresslevel=6)
            s3.put_object(
                Bucket=R2_BUCKET,
                Key=key,
                Body=data_corregida,
                ContentType='text/html; charset=utf-8',
                ContentEncoding='gzip'
            )
            return True, None
        return False, None
    except ClientError as e:
        return False, f"ClientError: {e.response['Error']['Code']}"
    except Exception as e:
        return False, str(e)[:100]

if __name__ == '__main__':
    print("=" * 80)
    print("🚀 ARREGLAR IMÁGENES - USANDO IDs DE SUPABASE")
    print("=" * 80)
    
    if not all([R2_ACCOUNT_ID, R2_ACCESS_KEY, R2_SECRET_KEY, SUPABASE_URL, SUPABASE_KEY]):
        print("\n❌ ERROR: Faltan variables de entorno")
        sys.exit(1)
    
    print(f"\n✅ Configuración OK")
    
    # Obtener IDs desde Supabase
    print("\n📊 Obteniendo IDs desde Supabase...")
    import urllib.request
    import json
    
    url = f"{SUPABASE_URL}/rest/v1/documentos?select=id"
    headers = {
        'apikey': SUPABASE_KEY,
        'Authorization': f'Bearer {SUPABASE_KEY}'
    }
    
    req = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(req, timeout=30) as response:
        docs = json.loads(response.read())
    
    doc_ids = [doc['id'] for doc in docs]
    print(f"✅ IDs obtenidos de Supabase: {len(doc_ids):,}")
    
    # Construir rutas de HTML
    html_keys = [f"html/{doc_id}.html" for doc_id in doc_ids]
    total = len(html_keys)
    
    print(f"\n⚡ Procesando {total:,} archivos con 50 hilos...")
    print("=" * 80)
    
    procesados = 0
    modificados = 0
    errores = 0
    start_time = time.time()
    
    with ThreadPoolExecutor(max_workers=50) as executor:
        futures = {executor.submit(procesar_html, key): key for key in html_keys}
        
        for future in as_completed(futures):
            procesados += 1
            try:
                mod, err = future.result(timeout=15)
                
                if err:
                    errores += 1
                elif mod:
                    modificados += 1
            except:
                errores += 1
            
            if procesados % 500 == 0 or procesados == total:
                elapsed = time.time() - start_time
                rate = procesados / elapsed if elapsed > 0 else 0
                eta = (total - procesados) / rate if rate > 0 else 0
                
                print(f"📊 {procesados:,}/{total:,} | "
                      f"Modificados: {modificados:,} | "
                      f"Errores: {errores} | "
                      f"{rate:.1f} arch/s | "
                      f"ETA: {eta/60:.1f} min", flush=True)
    
    tiempo_total = time.time() - start_time
    print("\n" + "=" * 80)
    print("✅ COMPLETADO")
    print("=" * 80)
    print(f"\n📊 RESUMEN:")
    print(f"   Total:      {procesados:,}")
    print(f"   Modificados: {modificados:,}")
    print(f"   Sin cambios: {procesados - modificados - errores:,}")
    print(f"   Errores:     {errores}")
    print(f"   Tiempo:      {tiempo_total/60:.1f} min")
    print(f"   Velocidad:   {procesados/tiempo_total:.1f} arch/s")
    print()
    
    sys.exit(0 if errores < total * 0.05 else 1)
