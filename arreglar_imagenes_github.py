#!/usr/bin/env python3
import os
import sys
import re
import gzip
import json
import socket
import time
import urllib.request
import urllib.error
from concurrent.futures import ProcessPoolExecutor, as_completed

# 1. FORZAR TIMEOUT GLOBAL A NIVEL DE SOCKET (Evita congelamientos para siempre)
socket.setdefaulttimeout(15.0)

import boto3
from botocore.config import Config

# Variables de entorno
R2_ACCOUNT_ID = os.environ.get('CLOUDFLARE_ACCOUNT_ID')
R2_ACCESS_KEY = os.environ.get('R2_ACCESS_KEY_ID')
R2_SECRET_KEY = os.environ.get('R2_SECRET_ACCESS_KEY')
R2_BUCKET = os.environ.get('R2_BUCKET_NAME', 'penalex-ve')
SUPABASE_URL = os.environ.get('SUPABASE_URL')
SUPABASE_KEY = os.environ.get('SUPABASE_SERVICE_KEY')
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

def get_s3():
    return boto3.client(
        's3',
        endpoint_url=f'https://{R2_ACCOUNT_ID}.r2.cloudflarestorage.com',
        aws_access_key_id=R2_ACCESS_KEY,
        aws_secret_access_key=R2_SECRET_KEY,
        region_name='auto',
        config=Config(
            signature_version='s3v4',
            connect_timeout=10,
            read_timeout=10,
            retries={'max_attempts': 2}
        )
    )

def procesar_archivo_r2(key):
    """Solo interactúa con R2 (Sin llamadas a Supabase)"""
    try:
        s3 = get_s3()
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
        
        # Corrección del HTML
        html_corregido = re.sub(r'<!--\[if gte vml 1\]>.*?<!\[endif\]-->', '', html, flags=re.DOTALL | re.IGNORECASE)
        for patron in PATRONES_ROTOS:
            html_corregido = re.sub(patron, LOGO_CORRECTO, html_corregido, flags=re.IGNORECASE)
        
        modificado = (html_corregido != html)
        if modificado:
            data_corregida = gzip.compress(html_corregido.encode('utf-8'), 6)
            s3.put_object(
                Bucket=R2_BUCKET,
                Key=key,
                Body=data_corregida,
                ContentType='text/html; charset=utf-8',
                ContentEncoding='gzip'
            )
            
        doc_id = os.path.basename(key).replace('.html', '').replace('.HTML', '')
        html_url = f"{R2_PUBLIC_URL}/{key}"
        
        return (key, doc_id, html_url, modificado, None)
    except Exception as e:
        return (key, None, None, False, str(e))

def actualizar_supabase_en_lote(registros):
    """
    Actualiza Supabase en Lotes masivos via RPC/Upsert para no saturar HTTP
    o realiza peticiones masivas agrupadas.
    """
    if not registros:
        return True
    
    # Enviar los datos estructurados en lote
    payload = [{"id": r["doc_id"], "url_html": r["html_url"]} for r in registros]
    
    url = f"{SUPABASE_URL}/rest/v1/documentos"
    headers = {
        'apikey': SUPABASE_KEY,
        'Authorization': f'Bearer {SUPABASE_KEY}',
        'Content-Type': 'application/json',
        'Prefer': 'resolution=merge-duplicates' # Hace un UPSERT eficiente
    }
    
    data = json.dumps(payload).encode('utf-8')
    req = urllib.request.Request(url, data=data, headers=headers, method='POST')
    
    try:
        with urllib.request.urlopen(req, timeout=15) as response:
            return response.status in (200, 201, 204)
    except Exception as e:
        print(f"\n⚠️ Falló actualización de lote en Supabase: {e}", flush=True)
        return False

if __name__ == '__main__':
    print("📂 Obteniendo lista de archivos desde R2...", flush=True)
    s3 = get_s3()
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

    print(f"✅ Total archivos encontrados: {len(html_keys):,}", flush=True)

    # Procesar con aislamiento por proceso (Evita congelamientos de Threading)
    batch_supabase = []
    procesados = 0
    modificados = 0
    errores = 0

    start_time = time.time()

    # ProcessPoolExecutor mata y aisla los procesos que se queden colgados
    with ProcessPoolExecutor(max_workers=4) as executor:
        futures = {executor.submit(procesar_archivo_r2, key): key for key in html_keys}
        
        for future in as_completed(futures):
            key, doc_id, html_url, mod, err = future.result()
            procesados += 1
            
            if err:
                errores += 1
            else:
                if mod:
                    modificados += 1
                batch_supabase.append({"doc_id": doc_id, "html_url": html_url})

            # Cuando se acumulen 100 registros, enviamos 1 sola petición a Supabase
            if len(batch_supabase) >= 100:
                actualizar_supabase_en_lote(batch_supabase)
                batch_supabase.clear()

            if procesados % 100 == 0 or procesados == len(html_keys):
                elapsed = time.time() - start_time
                rate = procesados / elapsed if elapsed > 0 else 0
                print(f"📊 Procesados: {procesados:,}/{len(html_keys):,} | Modificados: {modificados:,} | Rate: {rate:.1f} arch/s", flush=True)

    # Guardar los pendientes finales
    if batch_supabase:
        actualizar_supabase_en_lote(batch_supabase)

    print("\n✅ PROCESO FINALIZADO SIN BLOQUEOS", flush=True)
