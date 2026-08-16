#!/usr/bin/env python3
"""
SCRIPT DEFINITIVO: Cruzar Cloudflare R2 con Supabase
Identifica qué HTMLs en R2 NO tienen metadata en Supabase
"""

import os
import json
import sys
import csv

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
print("🔄 CRUCE DEFINITIVO: R2 ↔ SUPABASE")
print("="*80)

env = load_env()

# Validar credenciales
required = ['R2_ACCOUNT_ID', 'R2_ACCESS_KEY_ID', 'R2_SECRET_ACCESS_KEY', 
            'R2_BUCKET_NAME', 'SUPABASE_URL', 'SUPABASE_ANON_KEY']

missing = [k for k in required if k not in env]
if missing:
    print(f"❌ Error: Faltan credenciales: {', '.join(missing)}")
    sys.exit(1)

# ============================================================================
# PASO 1: INTENTAR CONECTAR A R2 CON CONFIGURACIÓN ALTERNATIVA
# ============================================================================

print("\n☁️  PASO 1: Conectando a Cloudflare R2...")

try:
    import boto3
    from botocore.config import Config
    from botocore.exceptions import ClientError, NoCredentialsError
    HAS_BOTO3 = True
except ImportError:
    HAS_BOTO3 = False
    print("❌ boto3 no instalado. Instalando...")
    os.system("pip install boto3 -q")
    try:
        import boto3
        from botocore.config import Config
        from botocore.exceptions import ClientError, NoCredentialsError
        HAS_BOTO3 = True
        print("✅ boto3 instalado correctamente")
    except:
        print("❌ No se pudo instalar boto3")
        sys.exit(1)

# Limpiar credenciales
account_id = env['R2_ACCOUNT_ID'].strip()
access_key = env['R2_ACCESS_KEY_ID'].strip()
secret_key = env['R2_SECRET_ACCESS_KEY'].strip()
bucket = env['R2_BUCKET_NAME'].strip()

print(f"   Account ID: {account_id}")
print(f"   Bucket: {bucket}")
print(f"   Access Key: {access_key[:10]}...{access_key[-4:]}")

# Probar diferentes configuraciones de endpoint
endpoints_to_try = [
    f"https://{account_id}.r2.cloudflarestorage.com",
    f"https://{bucket}.{account_id}.r2.cloudflarestorage.com",
]

s3_client = None
for endpoint in endpoints_to_try:
    try:
        print(f"\n   Probando endpoint: {endpoint}")
        
        s3_client = boto3.client(
            's3',
            endpoint_url=endpoint,
            aws_access_key_id=access_key,
            aws_secret_access_key=secret_key,
            region_name='auto',
            config=Config(
                signature_version='s3v4',
                s3={'addressing_style': 'path'}
            )
        )
        
        # Probar conexión
        response = s3_client.list_objects_v2(Bucket=bucket, MaxKeys=1)
        print(f"   ✅ Conexión exitosa!")
        break
        
    except ClientError as e:
        error_code = e.response['Error']['Code']
        error_msg = e.response['Error']['Message']
        print(f"   ❌ Error {error_code}: {error_msg}")
        s3_client = None
        continue
    except Exception as e:
        print(f"   ❌ Error: {str(e)[:100]}")
        s3_client = None
        continue

if not s3_client:
    print("\n❌ No se pudo conectar a R2 con ninguna configuración")
    print("\n🔧 DIAGNÓSTICO:")
    print("   1. Verifica las credenciales en .env")
    print("   2. Regenera el API token en Cloudflare Dashboard")
    print("   3. Asegúrate que el token tenga permisos de lectura")
    print("\n💡 ALTERNATIVA: Usar Google Drive API")
    sys.exit(1)

# ============================================================================
# PASO 2: LISTAR TODOS LOS HTMLS EN R2
# ============================================================================

print("\n📂 PASO 2: Listando todos los HTMLs en R2...")

r2_docs = []
continuation_token = None
total_files = 0
html_files = 0

try:
    while True:
        if continuation_token:
            response = s3_client.list_objects_v2(
                Bucket=bucket,
                ContinuationToken=continuation_token
            )
        else:
            response = s3_client.list_objects_v2(Bucket=bucket)
        
        if 'Contents' in response:
            for obj in response['Contents']:
                key = obj['Key']
                total_files += 1
                
                # Solo HTMLs
                if key.endswith('.html') or key.endswith('.HTML'):
                    html_files += 1
                    
                    # Extraer metadata del path
                    # Formato esperado: sentencia/constitucional/2001_99_exp_00-2301.html
                    parts = key.split('/')
                    filename = parts[-1]
                    
                    # Extraer ID (sin .html)
                    doc_id = filename.replace('.html', '').replace('.HTML', '')
                    
                    # Extraer tipo y sala del path
                    tipo = parts[0] if len(parts) > 0 else 'unknown'
                    sala = parts[1] if len(parts) > 1 else 'unknown'
                    
                    r2_docs.append({
                        'id': doc_id,
                        'path': key,
                        'tipo': tipo,
                        'sala': sala,
                        'size': obj['Size'],
                        'last_modified': obj['LastModified'].isoformat()
                    })
        
        print(f"   Archivos: {total_files:,} | HTMLs: {html_files:,}", end='\r')
        
        if not response.get('IsTruncated'):
            break
        
        continuation_token = response.get('NextContinuationToken')

except Exception as e:
    print(f"\n❌ Error listando R2: {e}")
    sys.exit(1)

print(f"\n✅ Total archivos en R2: {total_files:,}")
print(f"✅ Total HTMLs en R2: {html_files:,}")

r2_ids = set([doc['id'] for doc in r2_docs])

# ============================================================================
# PASO 3: DESCARGAR IDS DE SUPABASE
# ============================================================================

print("\n💾 PASO 3: Descargando IDs de Supabase...")

import urllib.request
import urllib.error

supabase_ids = set()
offset = 0
batch_size = 1000
SUPABASE_URL = env['SUPABASE_URL']
SUPABASE_KEY = env['SUPABASE_ANON_KEY']

try:
    while True:
        url = f"{SUPABASE_URL}/rest/v1/documentos?select=id&offset={offset}&limit={batch_size}"
        headers = {
            'apikey': SUPABASE_KEY,
            'Authorization': f'Bearer {SUPABASE_KEY}',
            'Content-Type': 'application/json'
        }
        
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read().decode())
            
            if not data:
                break
            
            supabase_ids.update([doc['id'] for doc in data])
            print(f"   Descargados: {len(supabase_ids):,} IDs...", end='\r')
            offset += batch_size

except Exception as e:
    print(f"\n❌ Error descargando Supabase: {e}")
    sys.exit(1)

print(f"\n✅ Total en Supabase: {len(supabase_ids):,} documentos")

# ============================================================================
# PASO 4: CRUCE DE DATOS
# ============================================================================

print("\n🔍 PASO 4: Cruzando R2 ↔ Supabase...")

# HTMLs en R2 que NO tienen metadata en Supabase
faltantes_metadata = r2_ids - supabase_ids

# Documentos en Supabase que NO tienen HTML en R2
sin_html = supabase_ids - r2_ids

print(f"\n" + "="*80)
print("📊 RESULTADO DEL CRUCE")
print("="*80)
print(f"\n   HTMLs en R2:                  {len(r2_ids):>10,}")
print(f"   Metadatas en Supabase:        {len(supabase_ids):>10,}")
print(f"   ─────────────────────────────────────────────")
print(f"   ❌ Faltantes (R2 sin metadata):  {len(faltantes_metadata):>10,}")
print(f"   ⚠️  Sin HTML (SB sin R2):         {len(sin_html):>10,}")

# ============================================================================
# PASO 5: GENERAR REPORTE
# ============================================================================

if faltantes_metadata:
    print(f"\n💾 PASO 5: Generando reporte de faltantes...")
    
    faltantes_docs = [doc for doc in r2_docs if doc['id'] in faltantes_metadata]
    
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
    
    # Guardar CSV completo
    with open('faltantes_r2_definitivo.csv', 'w', newline='', encoding='utf-8') as f:
        fieldnames = ['id', 'path', 'tipo', 'sala', 'size', 'last_modified']
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(faltantes_docs)
    
    print(f"\n✅ CSV guardado: faltantes_r2_definitivo.csv ({len(faltantes_docs):,} registros)")
    
    # Ejemplos
    print(f"\n📄 Primeros 20 documentos sin metadata:")
    for i, doc in enumerate(faltantes_docs[:20], 1):
        print(f"   {i:2}. {doc['id']}")
        print(f"       Path: {doc['path']}")
        print(f"       Tamaño: {doc['size']:,} bytes")

if sin_html:
    print(f"\n⚠️  ADVERTENCIA: {len(sin_html):,} metadatas en Supabase SIN HTML en R2")
    with open('supabase_sin_html.txt', 'w') as f:
        for doc_id in sorted(sin_html):
            f.write(f"{doc_id}\n")
    print(f"   Lista guardada en: supabase_sin_html.txt")

# ============================================================================
# RESUMEN FINAL
# ============================================================================

print("\n" + "="*80)
print("✅ CRUCE COMPLETO")
print("="*80)

completitud = 100 * (1 - len(faltantes_metadata) / len(r2_ids)) if r2_ids else 100

print(f"\n📊 ESTADÍSTICAS:")
print(f"   Total HTMLs disponibles (R2): {len(r2_ids):,}")
print(f"   Con metadata (Supabase):      {len(r2_ids - faltantes_metadata):,}")
print(f"   Sin metadata:                 {len(faltantes_metadata):,}")
print(f"   % Completitud:                {completitud:.2f}%")

if faltantes_metadata:
    print(f"\n🎯 PRÓXIMO PASO:")
    print(f"   Procesar los {len(faltantes_metadata):,} HTMLs sin metadata")
    print(f"   Archivo: faltantes_r2_definitivo.csv")
else:
    print(f"\n🎉 ¡PERFECTO! Todos los HTMLs tienen metadata en Supabase")

print("\n" + "="*80 + "\n")
