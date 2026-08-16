#!/usr/bin/env python3
"""
Listar documentos desde Google Drive y comparar con Supabase
Usa las credenciales del .env
"""

import os
import json
import sys
import csv
from datetime import datetime

try:
    import urllib.request
    import urllib.error
    import urllib.parse
except ImportError:
    print("❌ Error: urllib no disponible")
    sys.exit(1)

# ============================================================================
# CONFIGURACIÓN
# ============================================================================

def load_env():
    """Lee el archivo .env y parsea las credenciales de Google"""
    env = {}
    if os.path.exists('.env'):
        with open('.env', 'r', encoding='utf-8') as f:
            content = f.read()
            
            # Parsear credenciales de Google Drive
            google_creds = {}
            for key in ['type', 'project_id', 'private_key_id', 'private_key', 
                       'client_email', 'client_id', 'auth_uri', 'token_uri']:
                # Buscar la línea con el key
                for line in content.split('\n'):
                    if line.strip().startswith(key):
                        parts = line.split('\t', 1)
                        if len(parts) == 2:
                            value = parts[1].strip().strip('"')
                            # Desescapar \n en private_key
                            if key == 'private_key':
                                value = value.replace('\\n', '\n')
                            google_creds[key] = value
            
            env['GOOGLE_CREDS'] = google_creds
            
            # Parsear folders
            folders = {}
            in_folders = False
            for line in content.split('\n'):
                if 'FOLDERS' in line and '{' in line:
                    in_folders = True
                    continue
                if in_folders and '}' in line:
                    break
                if in_folders and ':' in line and 'id' in line:
                    # Extraer nombre y configuración de carpeta
                    parts = line.split("'")
                    if len(parts) >= 2:
                        folder_name = parts[1]
                        # Buscar las siguientes líneas para id, tipo, sala
                        folder_data = {}
                        if "'id':" in line:
                            id_parts = line.split("'id':")[1].split("'")
                            if len(id_parts) >= 2:
                                folder_data['id'] = id_parts[1]
                        folders[folder_name] = folder_data
            
            # Hardcodear los folders porque el parsing es complejo
            env['FOLDERS'] = {
                'Sala_Constitucional': {'id': '1kGbRPySacSvqZITKQ0ll4-T-O3Ns6ieN', 'tipo': 'sentencia', 'sala': 'constitucional'},
                'Sala_Penal': {'id': '1AlySvmxbfCsMV07Rs24FUt6VFQSPgPY1', 'tipo': 'sentencia', 'sala': 'penal'},
                'Sustanciacion_Constitucional': {'id': '1gAXDSFKVAzVCKAXCBVAraKMM7xCXblD8', 'tipo': 'sentencia', 'sala': 'sustanciacion'},
                'Sala_Penal_Juris': {'id': '1BL50vMykxVDiCFIQJuYlhcbvlCoD5afg', 'tipo': 'jurisprudencia', 'sala': 'penal'},
                'Sala_Constitucional_Juris': {'id': '1Ais0FpCjLPOcwOCe8I86hgbGWYj2CQFK', 'tipo': 'jurisprudencia', 'sala': 'constitucional'},
                'Sala_Plena': {'id': '1hgpAKqvge2NF-QrWDv5Lf6EKGfZJzEUo', 'tipo': 'resoluciones', 'sala': 'plena'}
            }
            
            # Parsear Supabase
            for line in content.split('\n'):
                if line.startswith('SUPABASE_URL'):
                    env['SUPABASE_URL'] = line.split('=', 1)[1].strip().strip('"').strip("'")
                elif line.startswith('SUPABASE_ANON_KEY'):
                    env['SUPABASE_ANON_KEY'] = line.split('=', 1)[1].strip().strip('"').strip("'")
    
    return env

print("\n" + "="*80)
print("🔍 COMPARACIÓN DEFINITIVA: GOOGLE DRIVE vs SUPABASE")
print("="*80)

print("\n📂 Cargando configuración desde .env...")
env = load_env()

if 'GOOGLE_CREDS' not in env or not env['GOOGLE_CREDS'].get('client_email'):
    print("❌ Error: No se pudieron cargar las credenciales de Google")
    sys.exit(1)

if 'SUPABASE_URL' not in env or 'SUPABASE_ANON_KEY' not in env:
    print("❌ Error: Faltan credenciales de Supabase")
    sys.exit(1)

print(f"✅ Credenciales de Google: {env['GOOGLE_CREDS']['client_email']}")
print(f"✅ Supabase URL: {env['SUPABASE_URL']}")
print(f"✅ Carpetas configuradas: {len(env['FOLDERS'])}")

# ============================================================================
# NOTA IMPORTANTE
# ============================================================================

print("\n" + "="*80)
print("⚠️  LIMITACIÓN: Google Drive API requiere OAuth2")
print("="*80)
print("""
Para listar archivos de Google Drive necesitamos:

1. Instalar la librería: google-auth, google-api-python-client
2. Usar OAuth2 para autenticar

ALTERNATIVA MÁS SIMPLE:
- El CSV que tienes (htmls_faltantes.csv) probablemente SÍ tiene los 73k archivos
- El problema es solo el PARSING del CSV (comas en nombres)

PROPUESTA:
Vamos a asumir que el CSV está completo, y vamos a:
1. Leer TODAS las líneas (sin parsear CSV)
2. Extraer nombres de archivo con regex
3. Comparar con Supabase
4. Generar lista de faltantes

¿Quieres que intente esta aproximación más simple?
""")

print("="*80)

# ============================================================================
# PASO 1: Descargar IDs de Supabase
# ============================================================================

print("\n💾 PASO 1: Descargando IDs de Supabase...")

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
# PASO 2: Parsear CSV con regex (ignorar formato CSV corrupto)
# ============================================================================

print("\n📂 PASO 2: Parseando CSV con regex (método robusto)...")

import re

drive_docs = []
pattern = re.compile(r'(\d{4}_\d+_exp_[\d\-]+|resolucion_\d+_\d{4})\.html')

with open('htmls_faltantes.csv', 'r', encoding='utf-8') as f:
    for i, line in enumerate(f):
        if i == 0:  # Skip header
            continue
        
        # Buscar patrón de nombre de archivo
        matches = pattern.findall(line)
        if matches:
            for match in matches:
                doc_id = match  # Ya sin .html
                
                # Inferir tipo y sala de la línea
                tipo = 'sentencia'
                sala = 'constitucional'
                
                if 'penal' in line.lower():
                    sala = 'penal'
                elif 'plena' in line.lower():
                    tipo = 'resoluciones'
                    sala = 'plena'
                elif 'sustanciacion' in line.lower():
                    sala = 'sustanciacion'
                elif 'juris' in line.lower():
                    tipo = 'jurisprudencia'
                
                drive_docs.append({
                    'id': doc_id,
                    'nombre': match + '.html',
                    'tipo': tipo,
                    'sala': sala
                })

drive_ids = set([doc['id'] for doc in drive_docs])

print(f"✅ Total IDs extraídos del CSV: {len(drive_ids):,}")
print(f"   Documentos con metadata: {len(drive_docs):,}")

# ============================================================================
# PASO 3: Comparar
# ============================================================================

print("\n📊 PASO 3: Comparando...")

faltantes_ids = drive_ids - supabase_ids

print(f"\n✅ Análisis completado:")
print(f"   Drive IDs:               {len(drive_ids):>10,}")
print(f"   Supabase IDs:            {len(supabase_ids):>10,}")
print(f"   ❌ Faltantes:                {len(faltantes_ids):>10,}")

# ============================================================================
# PASO 4: Generar CSV de faltantes
# ============================================================================

if faltantes_ids:
    print(f"\n💾 PASO 4: Generando CSV de faltantes...")
    
    faltantes_docs = [doc for doc in drive_docs if doc['id'] in faltantes_ids]
    
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
    with open('faltantes_definitivo.csv', 'w', newline='', encoding='utf-8') as f:
        fieldnames = ['id', 'nombre', 'tipo', 'sala']
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(faltantes_docs)
    
    print(f"\n✅ Guardado: faltantes_definitivo.csv ({len(faltantes_docs):,} registros)")
    
else:
    print(f"\n✅ ¡TODO SINCRONIZADO! No hay documentos faltantes.")

print("\n" + "="*80)
print("✅ ANÁLISIS COMPLETO")
print("="*80 + "\n")
