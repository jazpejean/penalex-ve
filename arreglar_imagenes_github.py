#!/usr/bin/env python3
import os
import re
import gzip
import time
from concurrent.futures import ThreadPoolExecutor, as_completed

import boto3
from botocore.config import Config

# Env Vars (Solo Cloudflare R2)
R2_ACCOUNT_ID = os.environ.get('CLOUDFLARE_ACCOUNT_ID')
R2_ACCESS_KEY = os.environ.get('R2_ACCESS_KEY_ID')
R2_SECRET_KEY = os.environ.get('R2_SECRET_ACCESS_KEY')
R2_BUCKET = os.environ.get('R2_BUCKET_NAME', 'penalex-ve')
R2_PUBLIC_URL = os.environ.get('R2_PUBLIC_URL', 'https://pub-a6e0bfa2e9174e91b031ae28c0667009.r2.dev')

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

# Timeouts cortos para descargas/cargas en R2
BOTO3_CONFIG = Config(
    signature_version='s3v4',
    connect_timeout=5,
    read_timeout=5,
    retries={'max_attempts': 2}
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

def procesar_html(s3, key):
    try:
        response = s3.get_object(Bucket=R2_BUCKET, Key=key)
        content_encoding = response.get('ContentEncoding', '')
        raw_data = response['Body'].read()
        
        if 'gzip' in content_encoding:
            html = gzip.decompress(raw_data).decode('utf-8')
        else:
            try:
                html = raw_data.decode('utf-8')
            except UnicodeDecodeError:
                html = raw_data.decode('latin-1')
        
        # Eliminación de comentarios VML y corrección de imágenes
        html_corregido = re.sub(r'<!--\[if gte vml 1\]>.*?<!\[endif\]-->', '', html, flags=re.DOTALL | re.IGNORECASE)
        for patron in PATRONES_ROTOS:
            html_corregido = re.sub(patron, LOGO_CORRECTO, html_corregido, flags=re.IGNORECASE)
        
        # Solo guarda en R2 si hubo modificaciones reales
        if html_corregido != html:
            data_corregida = gzip.compress(html_corregido.encode('utf-8'), 6)
            s3.put_object(
                Bucket=R2_BUCKET,
                Key=key,
                Body=data_corregida,
                ContentType='text/html; charset=utf-8',
                ContentEncoding='gzip'
            )
            return True, None
            
        return False, None
    except Exception as e:
        return False, str(e)

if __name__ == '__main__':
    s3 = get_s3()
    print("📂 Obteniendo lista completa de R2...", flush=True)
    html_keys = []
    continuation_token = None

    while True:
        kwargs = {'Bucket': R2_BUCKET, 'Prefix': 'html/'}
        if continuation_token:
            kwargs['ContinuationToken'] = continuation_token
            
        response = s3.list_objects_v2(**kwargs)
        if 'Contents' in response:
            for obj in response['Contents']:
                k = obj['Key']
                if k.endswith('.html') or k.endswith('.HTML'):
                    html_keys.append(k)
        
        if not response.get('IsTruncated'):
            break
        continuation_token = response.get('NextContinuationToken')

    total = len(html_keys)
    print(f"✅ Total archivos: {total:,}", flush=True)

    procesados = 0
    modificados = 0
    errores = 0
    start_time = time.time()

    # Ejecución concurrente directa con 30 hilos
    with ThreadPoolExecutor(max_workers=30) as executor:
        futures = {executor.submit(procesar_html, s3, key): key for key in html_keys}
        
        for future in as_completed(futures):
            procesados += 1
            mod, err = future.result()
            
            if err:
                errores += 1
            elif mod:
                modificados += 1

            if procesados % 1000 == 0 or procesados == total:
                elapsed = time.time() - start_time
                rate = procesados / elapsed if elapsed > 0 else 0
                print(f"📊 Procesados: {procesados:,}/{total:,} | Modificados: {modificados:,} | Errores: {errores} | Vel: {rate:.1f} arch/s", flush=True)

    tiempo_total = time.time() - start_time
    print(f"\n✅ PROCESO COMPLETADO EN {tiempo_total:.1f} SEG")
    print(f"Archivos revisados: {procesados:,} | Modificados en R2: {modificados:,} | Errores: {errores}")
