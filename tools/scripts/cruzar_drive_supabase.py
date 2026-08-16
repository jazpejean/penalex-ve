#!/usr/bin/env python3
"""
CRUCE DEFINITIVO: Google Drive ↔ Supabase
Lista todos los HTMLs de Drive y cruza con Supabase
"""

import os
import json
import sys
import csv

# ============================================================================
# INSTALAR DEPENDENCIAS SI ES NECESARIO
# ============================================================================

print("\n" + "="*80)
print("🔄 CRUCE DEFINITIVO: GOOGLE DRIVE ↔ SUPABASE")
print("="*80)

print("\n📦 Verificando dependencias...")

try:
    from google.oauth2 import service_account
    from googleapiclient.discovery import build
    from googleapiclient.errors import HttpError
    print("✅ Google API Client instalado")
except ImportError:
    print("❌ Instalando google-api-python-client...")
    os.system("pip3 install --break-system-packages google-api-python-client google-auth -q")
    try:
        from google.oauth2 import service_account
        from googleapiclient.discovery import build
        from googleapiclient.errors import HttpError
        print("✅ Instalado correctamente")
    except:
        print("❌ No se pudo instalar google-api-python-client")
        sys.exit(1)

# ============================================================================
# CARGAR CONFIGURACIÓN
# ============================================================================

def load_env():
    env = {}
    if os.path.exists('.env'):
        with open('.env', 'r', encoding='utf-8') as f:
            content = f.read()
            
            # Parsear líneas simples
            for line in content.split('\n'):
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, value = line.split('=', 1)
                    env[key.strip()] = value.strip()
    return env

env = load_env()

# Construir credenciales de Google desde el .env
# Las credenciales están mezcladas en el .env, necesitamos extraerlas
print("\n🔐 Buscando credenciales de Google...")

# Buscar si hay un archivo de credenciales separado
creds_files = [
    'credentials.json',
    'firebase-adminsdk.json',
    'google-credentials.json'
]

google_creds = None
for creds_file in creds_files:
    if os.path.exists(creds_file):
        print(f"✅ Encontrado: {creds_file}")
        with open(creds_file, 'r') as f:
            google_creds = json.load(f)
        break

if not google_creds:
    print("❌ No se encontró archivo de credenciales JSON")
    print("\n📝 Las credenciales están en el .env pero necesitan estar en un JSON")
    print("\n🔧 CREA UN ARCHIVO: google-credentials.json")
    print("Con el siguiente contenido (extrayendo del .env):\n")
    print("""{
  "type": "service_account",
  "project_id": "penalex-ve",
  "private_key_id": "7d51224194bca4510f01b1682e83df964821ed80",
  "private_key": "-----BEGIN PRIVATE KEY-----\\n...\\n-----END PRIVATE KEY-----\\n",
  "client_email": "firebase-adminsdk-fbsvc@penalex-ve.iam.gserviceaccount.com",
  "client_id": "117263337420364693928",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40penalex-ve.iam.gserviceaccount.com"
}""")
    print("\n(Reemplaza el private_key con el valor completo del .env, incluyendo \\n)")
    sys.exit(1)

# Configuración de carpetas de Drive
FOLDERS = {
    'Sala_Constitucional': {'id': '1kGbRPySacSvqZITKQ0ll4-T-O3Ns6ieN', 'tipo': 'sentencia', 'sala': 'constitucional'},
    'Sala_Penal': {'id': '1AlySvmxbfCsMV07Rs24FUt6VFQSPgPY1', 'tipo': 'sentencia', 'sala': 'penal'},
    'Sustanciacion_Constitucional': {'id': '1gAXDSFKVAzVCKAXCBVAraKMM7xCXblD8', 'tipo': 'sentencia', 'sala': 'sustanciacion'},
    'Sala_Penal_Juris': {'id': '1BL50vMykxVDiCFIQJuYlhcbvlCoD5afg', 'tipo': 'jurisprudencia', 'sala': 'penal'},
    'Sala_Constitucional_Juris': {'id': '1Ais0FpCjLPOcwOCe8I86hgbGWYj2CQFK', 'tipo': 'jurisprudencia', 'sala': 'constitucional'},
    'Sala_Plena': {'id': '1hgpAKqvge2NF-QrWDv5Lf6EKGfZJzEUo', 'tipo': 'resoluciones', 'sala': 'plena'}
}

# ============================================================================
# PASO 1: CONECTAR A GOOGLE DRIVE
# ============================================================================

print("\n☁️  PASO 1: Conectando a Google Drive...")

try:
    credentials = service_account.Credentials.from_service_account_info(
        google_creds,
        scopes=['https://www.googleapis.com/auth/drive.readonly']
    )
    
    drive_service = build('drive', 'v3', credentials=credentials)
    print("✅ Conectado a Google Drive")
    
except Exception as e:
    print(f"❌ Error conectando a Drive: {e}")
    sys.exit(1)

# ============================================================================
# PASO 2: LISTAR TODOS LOS HTMLS EN DRIVE
# ============================================================================

print("\n📂 PASO 2: Listando HTMLs en Google Drive...")

drive_docs = []

for folder_name, folder_info in FOLDERS.items():
    folder_id = folder_info['id']
    tipo = folder_info['tipo']
    sala = folder_info['sala']
    
    print(f"\n   📁 {folder_name}...")
    
    page_token = None
    folder_count = 0
    
    try:
        while True:
            query = f"'{folder_id}' in parents and (name contains '.html' or name contains '.HTML')"
            
            results = drive_service.files().list(
                q=query,
                pageSize=1000,
                fields="nextPageToken, files(id, name, size, modifiedTime)",
                pageToken=page_token
            ).execute()
            
            files = results.get('files', [])
            folder_count += len(files)
            
            for file in files:
                filename = file['name']
                doc_id = filename.replace('.html', '').replace('.HTML', '')
                
                drive_docs.append({
                    'id': doc_id,
                    'name': filename,
                    'drive_id': file['id'],
                    'tipo': tipo,
                    'sala': sala,
                    'size': file.get('size', 0),
                    'modified': file.get('modifiedTime', '')
                })
            
            print(f"      Encontrados: {folder_count:,}", end='\r')
            
            page_token = results.get('nextPageToken')
            if not page_token:
                break
        
        print(f"      ✅ Total: {folder_count:,} HTMLs")
        
    except HttpError as e:
        print(f"      ❌ Error: {e}")
        continue

print(f"\n✅ Total HTMLs en Drive: {len(drive_docs):,}")

# Detectar duplicados
from collections import Counter
id_counts = Counter([doc['id'] for doc in drive_docs])
duplicados = {id: count for id, count in id_counts.items() if count > 1}

if duplicados:
    print(f"\n⚠️  ADVERTENCIA: {len(duplicados):,} IDs duplicados detectados")
    print(f"   Total de archivos duplicados: {sum(duplicados.values()) - len(duplicados):,}")
    
    # Guardar duplicados
    with open('duplicados_drive.csv', 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerow(['id', 'count', 'archivos'])
        for doc_id, count in sorted(duplicados.items(), key=lambda x: x[1], reverse=True)[:100]:
            archivos = [d['name'] for d in drive_docs if d['id'] == doc_id]
            writer.writerow([doc_id, count, ' | '.join(archivos)])
    
    print(f"   Lista guardada en: duplicados_drive.csv")
    print(f"\n   Top 10 duplicados:")
    for doc_id, count in list(sorted(duplicados.items(), key=lambda x: x[1], reverse=True))[:10]:
        print(f"      {doc_id}: {count} veces")

drive_ids = set([doc['id'] for doc in drive_docs])
print(f"\n✅ IDs únicos en Drive: {len(drive_ids):,}")

# ============================================================================
# PASO 3: DESCARGAR IDS DE SUPABASE
# ============================================================================

print("\n💾 PASO 3: Descargando IDs de Supabase...")

import urllib.request
import urllib.error

if 'SUPABASE_URL' not in env or 'SUPABASE_ANON_KEY' not in env:
    print("❌ Faltan credenciales de Supabase en .env")
    sys.exit(1)

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
    print(f"\n❌ Error: {e}")
    sys.exit(1)

print(f"\n✅ Total en Supabase: {len(supabase_ids):,} documentos")

# ============================================================================
# PASO 4: CRUCE DE DATOS
# ============================================================================

print("\n🔍 PASO 4: Cruzando Drive ↔ Supabase...")

faltantes_metadata = drive_ids - supabase_ids
sin_html = supabase_ids - drive_ids

print(f"\n" + "="*80)
print("📊 RESULTADO DEL CRUCE")
print("="*80)
print(f"\n   HTMLs en Drive:               {len(drive_ids):>10,}")
print(f"   Metadatas en Supabase:        {len(supabase_ids):>10,}")
print(f"   ─────────────────────────────────────────────")
print(f"   ❌ Faltantes (Drive sin SB):     {len(faltantes_metadata):>10,}")
print(f"   ⚠️  Sin HTML (SB sin Drive):     {len(sin_html):>10,}")

# ============================================================================
# PASO 5: GENERAR REPORTE
# ============================================================================

if faltantes_metadata:
    print(f"\n💾 PASO 5: Generando reporte de faltantes...")
    
    faltantes_docs = [doc for doc in drive_docs if doc['id'] in faltantes_metadata]
    
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
    with open('faltantes_drive_definitivo.csv', 'w', newline='', encoding='utf-8') as f:
        fieldnames = ['id', 'name', 'drive_id', 'tipo', 'sala', 'size', 'modified']
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(faltantes_docs)
    
    print(f"\n✅ CSV guardado: faltantes_drive_definitivo.csv ({len(faltantes_docs):,} registros)")
    
    # Ejemplos
    print(f"\n📄 Primeros 20 documentos sin metadata:")
    for i, doc in enumerate(faltantes_docs[:20], 1):
        print(f"   {i:2}. {doc['id']}")
        print(f"       Drive ID: {doc['drive_id']}")
        print(f"       Carpeta: {doc['tipo']}/{doc['sala']}")

if sin_html:
    print(f"\n⚠️  {len(sin_html):,} metadatas en Supabase SIN HTML en Drive")
    with open('supabase_sin_html_drive.txt', 'w') as f:
        for doc_id in sorted(sin_html):
            f.write(f"{doc_id}\n")
    print(f"   Lista: supabase_sin_html_drive.txt")

# ============================================================================
# RESUMEN
# ============================================================================

print("\n" + "="*80)
print("✅ CRUCE COMPLETO")
print("="*80)

completitud = 100 * (1 - len(faltantes_metadata) / len(drive_ids)) if drive_ids else 100

print(f"\n📊 ESTADÍSTICAS:")
print(f"   Total HTMLs en Drive:         {len(drive_ids):,}")
print(f"   Con metadata (Supabase):      {len(drive_ids - faltantes_metadata):,}")
print(f"   Sin metadata:                 {len(faltantes_metadata):,}")
print(f"   % Completitud:                {completitud:.2f}%")

if faltantes_metadata:
    print(f"\n🎯 ACCIÓN REQUERIDA:")
    print(f"   Procesar {len(faltantes_metadata):,} HTMLs sin metadata")
    print(f"   Archivo: faltantes_drive_definitivo.csv")

print("\n" + "="*80 + "\n")
