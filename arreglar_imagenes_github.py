#!/usr/bin/env python3
"""
Arreglar imágenes rotas en HTMLs de Cloudflare R2
Para GitHub Actions
- Reemplaza rutas de imágenes rotas por logo correcto
- Actualiza URL del HTML en Supabase
"""

import os
import sys
import re
import gzip
import json
from concurrent.futures import ThreadPoolExecutor, as_completed
import threading
import time

# ============================================================================
# INSTALAR DEPENDENCIAS
# ============================================================================

def instalar_deps():
    try:
        import boto3
        import urllib3
    except ImportError:
        print("📦 Instalando dependencias...")
        os.system("pip install -q boto3 urllib3")
        import boto3
        import urllib3

instalar_deps()

import boto3
from botocore.config import Config
import urllib3
import urllib.request
import urllib.error

# ============================================================================
# CONFIGURACIÓN DESDE VARIABLES DE ENTORNO (GitHub Secrets)
# ============================================================================

print("\n" + "="*80)
print("🔧 ARREGLAR IMÁGENES EN R2 + ACTUALIZAR SUPABASE")
print("="*80)

# R2
R2_ACCOUNT_ID = os.environ.get('CLOUDFLARE_ACCOUNT_ID')
R2_ACCESS_KEY = os.environ.get('R2_ACCESS_KEY_ID')
R2_SECRET_KEY = os.environ.get('R2_SECRET_ACCESS_KEY')
R2_BUCKET = os.environ.get('R2_BUCKET_NAME', 'penalex-ve')

# Supabase
SUPABASE_URL = os.environ.get('SUPABASE_URL')
SUPABASE_KEY = os.environ.get('SUPABASE_SERVICE_KEY')  # Service key para escritura

# R2 Public URL base
R2_PUBLIC_URL = os.environ.get('R2_PUBLIC_URL', 'https://pub-a6e0bfa2e9174e91b031ae28c0667009.r2.dev')

# Validar
if not all([R2_ACCOUNT_ID, R2_ACCESS_KEY, R2_SECRET_KEY, SUPABASE_URL, SUPABASE_KEY]):
    print("❌ Faltan variables de entorno:")
    print(f"   CLOUDFLARE_ACCOUNT_ID: {'✅' if R2_ACCOUNT_ID else '❌'}")
    print(f"   R2_ACCESS_KEY_ID: {'✅' if R2_ACCESS_KEY else '❌'}")
    print(f"   R2_SECRET_ACCESS_KEY: {'✅' if R2_SECRET_KEY else '❌'}")
    print(f"   SUPABASE_URL: {'✅' if SUPABASE_URL else '❌'}")
    print(f"   SUPABASE_SERVICE_KEY: {'✅' if SUPABASE_KEY else '❌'}")
    sys.exit(1)

print(f"✅ Bucket: {R2_BUCKET}")
print(f"✅ Supabase: {SUPABASE_URL}")

# Logo correcto
LOGO_CORRECTO = f'{R2_PUBLIC_URL}/assets/logo.jpg'

# Patrones a reemplazar (orden importa: más específicos primero)
PATRONES_ROTOS = [
    # URLs absolutas con dominio R2 (primero para evitar reemplazos parciales)
    r'https://pub-a6e0bfa2e9174e91b031ae28c0667009\.r2\.dev/html/[^"\'<>\s]+_archivos/[^"\'<>\s]+\.(jpg|png|gif|jpeg)',
    # Logo viejo del TSJ (URLs completas primero)
    r'https://historico\.tsj\.gob\.ve/graficos/encabezadotsj\.jpg',
    r'http://historico\.tsj\.gob\.ve/graficos/encabezadotsj\.jpg',
    # Rutas relativas con punto (./)
    r'\./[^"\'<>\s]+_archivos/[^"\'<>\s]+\.(jpg|png|gif|jpeg)',
    # Rutas relativas sin punto
    r'(?<![:/])[^/"\s]+_archivos/[^"\'<>\s]+\.(jpg|png|gif|jpeg)',
    # Rutas absolutas relativas al dominio
    r'/graficos/encabezadotsj\.jpg',
    r'/imagenes/[^"\'<>\s]+\.(jpg|png|gif|jpeg)',
]

# ============================================================================
# FUNCIONES
# ============================================================================

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

def actualizar_supabase(doc_id, html_url):
    """Actualiza la URL del HTML en Supabase"""
    try:
        url = f"{SUPABASE_URL}/rest/v1/documentos?id=eq.{doc_id}"
        headers = {
            'apikey': SUPABASE_KEY,
            'Authorization': f'Bearer {SUPABASE_KEY}',
            'Content-Type': 'application/json',
            'Prefer': 'return=minimal'
        }
        
        data = json.dumps({'url_html': html_url}).encode('utf-8')
        
        req = urllib.request.Request(url, data=data, headers=headers, method='PATCH')
        with urllib.request.urlopen(req, timeout=10) as response:
            return response.status == 204 or response.status == 200
        
    except Exception as e:
        return False

def arreglar_html(key):
    """
    Descarga HTML de R2, corrige imágenes, re-sube, actualiza Supabase
    Retorna: (key, modificado, sb_actualizado, error)
    """
    try:
        s3 = get_s3()
        
        # Descargar
        response = s3.get_object(Bucket=R2_BUCKET, Key=key)
        
        # Leer contenido
        content_encoding = response.get('ContentEncoding', '')
        raw_data = response['Body'].read()
        
        if 'gzip' in content_encoding:
            html = gzip.decompress(raw_data).decode('utf-8')
        else:
            try:
                html = raw_data.decode('utf-8')
            except UnicodeDecodeError:
                html = raw_data.decode('latin-1')
        
        html_original = html
        
        # PASO 1: Eliminar líneas problemáticas del <head> de Microsoft Word
        # Eliminar xmlns:v, xmlns:o, xmlns:w del tag <html>
        html = re.sub(
            r'(<html[^>]*)\s+xmlns:v="[^"]*"',
            r'\1',
            html,
            flags=re.IGNORECASE
        )
        html = re.sub(
            r'(<html[^>]*)\s+xmlns:o="[^"]*"',
            r'\1',
            html,
            flags=re.IGNORECASE
        )
        html = re.sub(
            r'(<html[^>]*)\s+xmlns:w="[^"]*"',
            r'\1',
            html,
            flags=re.IGNORECASE
        )
        html = re.sub(
            r'(<html[^>]*)\s+xmlns="[^"]*"',
            r'\1',
            html,
            flags=re.IGNORECASE
        )
        
        # Eliminar tags de estilos VML
        html = re.sub(
            r'<!--\[if !mso\]>.*?<!\[endif\]-->',
            '',
            html,
            flags=re.DOTALL | re.IGNORECASE
        )
        
        # Eliminar bloques XML de Microsoft Office
        html = re.sub(
            r'<!--\[if gte mso 9\]>.*?<!\[endif\]-->',
            '',
            html,
            flags=re.DOTALL | re.IGNORECASE
        )
        
        # PASO 2: Reemplazar TODAS las imágenes rotas por el logo correcto
        for patron in PATRONES_ROTOS:
            html = re.sub(patron, LOGO_CORRECTO, html, flags=re.IGNORECASE)
        
        # Verificar si hubo cambios
        if html_original == html:
            # No hubo cambios, solo actualizar Supabase
            doc_id = os.path.basename(key).replace('.html', '').replace('.HTML', '')
            html_url = f"{R2_PUBLIC_URL}/{key}"
            sb_ok = actualizar_supabase(doc_id, html_url)
            return (key, False, sb_ok, None)
        
        html_corregido = html
        
        # Re-subir (comprimido)
        data_corregida = gzip.compress(html_corregido.encode('utf-8'), 6)
        
        s3.put_object(
            Bucket=R2_BUCKET,
            Key=key,
            Body=data_corregida,
            ContentType='text/html; charset=utf-8',
            ContentEncoding='gzip'
        )
        
        # Actualizar Supabase
        doc_id = os.path.basename(key).replace('.html', '').replace('.HTML', '')
        html_url = f"{R2_PUBLIC_URL}/{key}"
        sb_ok = actualizar_supabase(doc_id, html_url)
        
        return (key, True, sb_ok, None)
        
    except Exception as e:
        return (key, False, False, str(e))

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

# ============================================================================
# PROCESAR EN PARALELO
# ============================================================================

print(f"\n🔧 Procesando {len(html_keys):,} HTMLs...")

stats = {
    'modificados': 0,
    'sin_cambios': 0,
    'sb_actualizados': 0,
    'sb_errores': 0,
    'errores': 0
}
stats_lock = threading.Lock()

MAX_WORKERS = int(os.environ.get('MAX_WORKERS', '10'))

start_time = time.time()

with ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
    futures = {executor.submit(arreglar_html, key): key for key in html_keys}
    
    procesados = 0
    
    for future in as_completed(futures):
        key, modificado, sb_ok, error = future.result()
        
        procesados += 1
        
        with stats_lock:
            if error:
                stats['errores'] += 1
                if procesados <= 5:  # Solo mostrar primeros errores
                    print(f"   ❌ {key}: {error}")
            else:
                if modificado:
                    stats['modificados'] += 1
                else:
                    stats['sin_cambios'] += 1
                
                if sb_ok:
                    stats['sb_actualizados'] += 1
                else:
                    stats['sb_errores'] += 1
        
        # Mostrar progreso
        if procesados % 100 == 0 or procesados == len(html_keys):
            elapsed = time.time() - start_time
            rate = procesados / elapsed if elapsed > 0 else 0
            eta = (len(html_keys) - procesados) / rate if rate > 0 else 0
            
            print(f"   📊 {procesados:,}/{len(html_keys):,} | "
                  f"Modificados: {stats['modificados']:,} | "
                  f"SB: {stats['sb_actualizados']:,} | "
                  f"{rate:.1f}/s | ETA: {eta/60:.1f}min")

elapsed = time.time() - start_time

print("\n" + "="*80)
print("✅ PROCESO COMPLETADO")
print("="*80)

print(f"\n📊 RESUMEN:")
print(f"   Total procesados:           {procesados:,}")
print(f"   ✅ HTMLs modificados:         {stats['modificados']:,}")
print(f"   ⚪ Sin cambios:               {stats['sin_cambios']:,}")
print(f"   💾 Supabase actualizados:    {stats['sb_actualizados']:,}")
print(f"   ⚠️  Supabase errores:         {stats['sb_errores']:,}")
print(f"   ❌ Errores R2:                {stats['errores']:,}")
print(f"   ⏱️  Tiempo total:             {elapsed/60:.1f} minutos")
print(f"   📈 Velocidad:                 {procesados/elapsed:.1f} archivos/seg")

print("\n" + "="*80 + "\n")

# Exit code para GitHub Actions
if stats['errores'] > len(html_keys) * 0.05:  # Más del 5% de errores
    print("⚠️  Demasiados errores, marcando como fallido")
    sys.exit(1)
else:
    print("✅ Proceso exitoso")
    sys.exit(0)
