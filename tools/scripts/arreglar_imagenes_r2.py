#!/usr/bin/env python3
"""
Arreglar imágenes rotas en HTMLs de Cloudflare R2
Reemplaza rutas de imágenes por el logo correcto
"""

import os
import sys
import re
import gzip
from concurrent.futures import ThreadPoolExecutor, as_completed
import threading

# ============================================================================
# INSTALAR BOTO3 SI ES NECESARIO
# ============================================================================

try:
    import boto3
    from botocore.config import Config
except ImportError:
    print("❌ Instalando boto3...")
    os.system("pip3 install --break-system-packages boto3 -q")
    import boto3
    from botocore.config import Config

# ============================================================================
# CONFIGURACIÓN
# ============================================================================

def load_env():
    env = {}
    if os.path.exists('.env'):
        with open('.env', 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, value = line.split('=', 1)
                    env[key.strip()] = value.strip()
    return env

print("\n" + "="*80)
print("🔧 ARREGLANDO IMÁGENES EN R2")
print("="*80)

env = load_env()

# Configurar R2
account_id = env.get('R2_ACCOUNT_ID', '').strip()
access_key = env.get('R2_ACCESS_KEY_ID', '').strip()
secret_key = env.get('R2_SECRET_ACCESS_KEY', '').strip()
bucket = env.get('R2_BUCKET_NAME', 'penalex-assets').strip()

if not all([account_id, access_key, secret_key]):
    print("❌ Faltan credenciales de R2 en .env")
    sys.exit(1)

print(f"✅ Bucket: {bucket}")

# Logo correcto
LOGO_CORRECTO = 'https://pub-a6e0bfa2e9174e91b031ae28c0667009.r2.dev/assets/logo.jpg'

# Patrones a reemplazar
PATRONES_ROTOS = [
    # Patrón principal que mencionaste
    r'https://pub-a6e0bfa2e9174e91b031ae28c0667009\.r2\.dev/html/[^/]+/[^/]+/[^/]+_archivos/image\d+\.jpg',
    # Otras variantes comunes
    r'/graficos/encabezadotsj\.jpg',
    r'https://historico\.tsj\.gob\.ve/graficos/encabezadotsj\.jpg',
]

# ============================================================================
# FUNCIONES
# ============================================================================

# Thread-local para cliente S3
_local = threading.local()

def get_s3():
    if not hasattr(_local, 's3'):
        _local.s3 = boto3.client(
            's3',
            endpoint_url=f'https://{account_id}.r2.cloudflarestorage.com',
            aws_access_key_id=access_key,
            aws_secret_access_key=secret_key,
            region_name='auto',
            config=Config(signature_version='s3v4')
        )
    return _local.s3

def arreglar_html(key):
    """
    Descarga HTML de R2, corrige imágenes, re-sube
    Retorna: (key, modificado, error)
    """
    try:
        s3 = get_s3()
        
        # Descargar
        response = s3.get_object(Bucket=bucket, Key=key)
        
        # Leer contenido (podría estar comprimido)
        content_encoding = response.get('ContentEncoding', '')
        raw_data = response['Body'].read()
        
        if 'gzip' in content_encoding:
            html = gzip.decompress(raw_data).decode('utf-8')
        else:
            try:
                html = raw_data.decode('utf-8')
            except UnicodeDecodeError:
                html = raw_data.decode('latin-1')
        
        # Verificar si tiene imágenes rotas
        tiene_rotas = False
        for patron in PATRONES_ROTOS:
            if re.search(patron, html):
                tiene_rotas = True
                break
        
        if not tiene_rotas:
            return (key, False, None)  # No necesita corrección
        
        # Reemplazar todas las rutas rotas
        html_corregido = html
        for patron in PATRONES_ROTOS:
            html_corregido = re.sub(patron, LOGO_CORRECTO, html_corregido)
        
        # Re-subir (comprimido)
        data_corregida = gzip.compress(html_corregido.encode('utf-8'), 6)
        
        s3.put_object(
            Bucket=bucket,
            Key=key,
            Body=data_corregida,
            ContentType='text/html; charset=utf-8',
            ContentEncoding='gzip'
        )
        
        return (key, True, None)
        
    except Exception as e:
        return (key, False, str(e))

# ============================================================================
# MAIN
# ============================================================================

print("\n📂 Listando HTMLs en R2...")

s3 = get_s3()

html_keys = []
continuation_token = None

try:
    while True:
        if continuation_token:
            response = s3.list_objects_v2(
                Bucket=bucket,
                Prefix='html/',
                ContinuationToken=continuation_token
            )
        else:
            response = s3.list_objects_v2(Bucket=bucket, Prefix='html/')
        
        if 'Contents' in response:
            for obj in response['Contents']:
                key = obj['Key']
                if key.endswith('.html') or key.endswith('.HTML'):
                    html_keys.append(key)
        
        print(f"   HTMLs encontrados: {len(html_keys):,}", end='\r')
        
        if not response.get('IsTruncated'):
            break
        
        continuation_token = response.get('NextContinuationToken')

except Exception as e:
    print(f"\n❌ Error listando R2: {e}")
    sys.exit(1)

print(f"\n✅ Total HTMLs: {len(html_keys):,}")

if not html_keys:
    print("⚠️  No hay HTMLs en R2")
    sys.exit(0)

# Preguntar confirmación
print(f"\n⚠️  Se procesarán {len(html_keys):,} archivos HTML")
confirmar = input("¿Continuar? (s/N): ").strip().lower()

if confirmar != 's':
    print("❌ Cancelado")
    sys.exit(0)

# ============================================================================
# PROCESAR EN PARALELO
# ============================================================================

print(f"\n🔧 Procesando {len(html_keys):,} HTMLs...")

stats = {'modificados': 0, 'sin_cambios': 0, 'errores': 0}
stats_lock = threading.Lock()

MAX_WORKERS = 10  # Ajusta según tu conexión

with ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
    futures = {executor.submit(arreglar_html, key): key for key in html_keys}
    
    procesados = 0
    
    for future in as_completed(futures):
        key, modificado, error = future.result()
        
        procesados += 1
        
        with stats_lock:
            if error:
                stats['errores'] += 1
                print(f"   ❌ {key}: {error}")
            elif modificado:
                stats['modificados'] += 1
            else:
                stats['sin_cambios'] += 1
        
        # Mostrar progreso cada 50 archivos
        if procesados % 50 == 0:
            print(f"   Progreso: {procesados:,}/{len(html_keys):,} | "
                  f"Modificados: {stats['modificados']:,} | "
                  f"Sin cambios: {stats['sin_cambios']:,} | "
                  f"Errores: {stats['errores']:,}")

print("\n" + "="*80)
print("✅ PROCESO COMPLETADO")
print("="*80)

print(f"\n📊 RESUMEN:")
print(f"   Total procesados:        {procesados:,}")
print(f"   ✅ Modificados:            {stats['modificados']:,}")
print(f"   ⚪ Sin cambios:            {stats['sin_cambios']:,}")
print(f"   ❌ Errores:                {stats['errores']:,}")

print("\n" + "="*80 + "\n")
