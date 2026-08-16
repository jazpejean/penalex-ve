#!/usr/bin/env python3
"""
Sincronización definitiva: Cloudflare R2 → Supabase
R2 es la fuente de verdad
"""

import os
import json
import sys
import csv
import re

try:
    import urllib.request
    import urllib.error
    import urllib.parse
    from urllib.parse import urlencode
    import hashlib
    import hmac
    from datetime import datetime
except ImportError:
    print("❌ Error: urllib no disponible")
    sys.exit(1)

# ============================================================================
# CARGAR CONFIGURACIÓN
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
print("🔄 SINCRONIZACIÓN DEFINITIVA: R2 → SUPABASE")
print("="*80)

env = load_env()

# Validar credenciales
required = ['R2_ACCOUNT_ID', 'R2_ACCESS_KEY_ID', 'R2_SECRET_ACCESS_KEY', 
            'R2_BUCKET_NAME', 'SUPABASE_URL', 'SUPABASE_ANON_KEY']

missing = [k for k in required if k not in env]
if missing:
    print(f"❌ Error: Faltan credenciales en .env: {', '.join(missing)}")
    sys.exit(1)

print(f"✅ R2 Account: {env['R2_ACCOUNT_ID']}")
print(f"✅ R2 Bucket: {env['R2_BUCKET_NAME']}")
print(f"✅ Supabase URL: {env['SUPABASE_URL']}")

# ============================================================================
# PASO 1: LISTAR TODOS LOS HTMLS EN CLOUDFLARE R2
# ============================================================================

print("\n☁️  PASO 1: Listando documentos en Cloudflare R2...")

# R2 es compatible con S3, usamos el endpoint S3
R2_ENDPOINT = f"https://{env['R2_ACCOUNT_ID']}.r2.cloudflarestorage.com"
BUCKET = env['R2_BUCKET_NAME']

# Para listar objetos en R2 necesitamos usar boto3 o hacer requests S3 manualmente
# Como no tenemos boto3, usaremos una aproximación simple con la API REST

print("\n⚠️  NOTA: Para listar R2 correctamente necesitamos boto3")
print("   Instalando con: pip3 install --user boto3")

try:
    import boto3
    from botocore.config import Config
    HAS_BOTO3 = True
except ImportError:
    HAS_BOTO3 = False
    print("❌ boto3 no está instalado")
    print("\n💡 ALTERNATIVA: Usar el endpoint público de R2 si está configurado")
    print("   O instalar boto3 con: pip3 install --user boto3\n")

if HAS_BOTO3:
    # Limpiar credenciales (quitar espacios, comillas)
    account_id = env['R2_ACCOUNT_ID'].strip().strip('"').strip("'")
    access_key = env['R2_ACCESS_KEY_ID'].strip().strip('"').strip("'")
    secret_key = env['R2_SECRET_ACCESS_KEY'].strip().strip('"').strip("'")
    bucket = env['R2_BUCKET_NAME'].strip().strip('"').strip("'")
    
    print(f"\n🔐 Verificando credenciales:")
    print(f"   Account ID: {account_id}")
    print(f"   Access Key: {access_key[:10]}...{access_key[-4:]}")
    print(f"   Secret Key: {secret_key[:10]}...{secret_key[-4:]}")
    print(f"   Bucket: {bucket}")
    
    # Configurar cliente R2
    s3 = boto3.client(
        's3',
        endpoint_url=f'https://{account_id}.r2.cloudflarestorage.com',
        aws_access_key_id=access_key,
        aws_secret_access_key=secret_key,
        config=Config(signature_version='s3v4'),
        region_name='auto'
    )
    
    BUCKET = bucket
    
    print(f"✅ Conectado a R2")
    
    # Listar todos los objetos .html
    r2_docs = []
    continuation_token = None
    
    while True:
        try:
            if continuation_token:
                response = s3.list_objects_v2(
                    Bucket=BUCKET,
                    Prefix='',
                    ContinuationToken=continuation_token
                )
            else:
                response = s3.list_objects_v2(Bucket=BUCKET, Prefix='')
            
            if 'Contents' in response:
                for obj in response['Contents']:
                    key = obj['Key']
                    # Solo HTMLs
                    if key.endswith('.html'):
                        # Extraer ID del path: tipo/sala/año_num_exp_xxx.html
                        parts = key.split('/')
                        if len(parts) >= 3:
                            filename = parts[-1]
                            sala_folder = parts[-2] if len(parts) >= 2 else 'unknown'
                            tipo_folder = parts[-3] if len(parts) >= 3 else 'unknown'
                            
                            # Limpiar el ID (sin .html)
                            doc_id = filename.replace('.html', '')
                            
                            r2_docs.append({
                                'id': doc_id,
                                'path': key,
                                'tipo': tipo_folder,
                                'sala': sala_folder,
                                'size': obj['Size']
                            })
                
                print(f"   Listados: {len(r2_docs):,} HTMLs...", end='\r')
            
            if not response.get('IsTruncated'):
                break
            
            continuation_token = response.get('NextContinuationToken')
            
        except Exception as e:
            print(f"\n❌ Error listando R2: {e}")
            sys.exit(1)
    
    print(f"\n✅ Total HTMLs en R2: {len(r2_docs):,}")
    
    r2_ids = set([doc['id'] for doc in r2_docs])

else:
    print("\n❌ No se puede continuar sin boto3")
    print("\nPara instalar boto3:")
    print("   pip3 install --user boto3")
    print("\nO si tienes problemas:")
    print("   python3 -m pip install --user boto3")
    sys.exit(1)

# ============================================================================
# PASO 2: DESCARGAR IDS DE SUPABASE
# ============================================================================

print("\n💾 PASO 2: Descargando IDs de Supabase...")

supabase_ids = set()
offset = 0
batch_size = 1000
SUPABASE_URL = env['SUPABASE_URL']
SUPABASE_KEY = env['SUPABASE_ANON_KEY']

while True:
    url = f"{SUPABASE_URL}/rest/v1/documentos?select=id&offset={offset}&limit={batch_size}"
    headers = {
        'apikey': SUPABASE_KEY,
        'Authorization': f'Bearer {SUPABASE_KEY}',
        'Content-Type': 'application/json'
    }
    
    try:
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read().decode())
            
            if not data:
                break
            
            supabase_ids.update([doc['id'] for doc in data])
            print(f"   Descargados: {len(supabase_ids):,} IDs...", end='\r')
            offset += batch_size
            
    except Exception as e:
        print(f"\n❌ Error: {e}")
        sys.exit(1)

print(f"\n✅ Total en Supabase: {len(supabase_ids):,} documentos")

# ============================================================================
# PASO 3: COMPARAR
# ============================================================================

print("\n📊 PASO 3: Comparando R2 vs Supabase...")

faltantes_ids = r2_ids - supabase_ids
extra_ids = supabase_ids - r2_ids

print(f"\n✅ Análisis completado:")
print(f"   R2 (fuente verdad):      {len(r2_ids):>10,} HTMLs")
print(f"   Supabase:                {len(supabase_ids):>10,} documentos")
print(f"   ❌ Faltantes (R2→SB):        {len(faltantes_ids):>10,}")
if extra_ids:
    print(f"   ⚠️  Extra (SB, no en R2):     {len(extra_ids):>10,}")

# ============================================================================
# PASO 4: GENERAR CSV DE FALTANTES
# ============================================================================

if faltantes_ids:
    print(f"\n💾 PASO 4: Generando CSV de faltantes...")
    
    faltantes_docs = [doc for doc in r2_docs if doc['id'] in faltantes_ids]
    
    # Agrupar por carpeta
    por_carpeta = {}
    for doc in faltantes_docs:
        carpeta = f"{doc['tipo']}/{doc['sala']}"
        if carpeta not in por_carpeta:
            por_carpeta[carpeta] = []
        por_carpeta[carpeta].append(doc)
    
    print(f"\n📋 Distribución de faltantes por carpeta:")
    print("="*80)
    for carpeta, docs in sorted(por_carpeta.items(), key=lambda x: len(x[1]), reverse=True):
        print(f"   {carpeta:40} {len(docs):>6,} documentos")
    
    # Guardar CSV
    with open('faltantes_desde_r2.csv', 'w', newline='', encoding='utf-8') as f:
        fieldnames = ['id', 'path', 'tipo', 'sala', 'size']
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(faltantes_docs)
    
    print(f"\n✅ Guardado: faltantes_desde_r2.csv ({len(faltantes_docs):,} registros)")
    
    # Mostrar ejemplos
    print(f"\n📄 Ejemplos de documentos faltantes (primeros 10):")
    for doc in faltantes_docs[:10]:
        print(f"   - {doc['id']} → {doc['path']}")
    
else:
    print(f"\n✅ ¡PERFECTO! R2 y Supabase están 100% sincronizados")

if extra_ids:
    print(f"\n⚠️  ADVERTENCIA: Hay {len(extra_ids):,} documentos en Supabase que NO están en R2")
    print(f"   Estos deberían limpiarse o verificarse")
    
    # Guardar lista de extras
    with open('extras_en_supabase.txt', 'w') as f:
        for doc_id in sorted(extra_ids):
            f.write(f"{doc_id}\n")
    print(f"   Lista guardada en: extras_en_supabase.txt")

print("\n" + "="*80)
print("✅ SINCRONIZACIÓN COMPLETA")
print("="*80)

if faltantes_ids:
    print(f"\n🎯 SIGUIENTE PASO:")
    print(f"   Procesar {len(faltantes_ids):,} documentos faltantes")
    print(f"   Usar: faltantes_desde_r2.csv")
else:
    print(f"\n🎉 Todo está sincronizado correctamente!")

print("\n" + "="*80 + "\n")
