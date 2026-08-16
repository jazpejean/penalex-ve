#!/usr/bin/env python3
"""
Comparar CSV de Drive con IDs de Supabase
Versión simple sin dependencias externas
"""

import os
import csv
import json
import sys

try:
    import urllib.request
    import urllib.error
except ImportError:
    print("❌ Error: urllib no disponible")
    sys.exit(1)

# ============================================================================
# CONFIGURACIÓN
# ============================================================================

CSV_DRIVE = 'htmls_faltantes.csv'
CSV_OUTPUT = 'documentos_realmente_faltantes.csv'

# Lee las credenciales del .env manualmente
def load_env():
    env = {}
    if os.path.exists('.env'):
        with open('.env', 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, value = line.split('=', 1)
                    env[key.strip()] = value.strip().strip('"').strip("'")
    return env

env = load_env()
SUPABASE_URL = env.get('SUPABASE_URL', '')
SUPABASE_KEY = env.get('SUPABASE_ANON_KEY', '')

if not SUPABASE_URL or not SUPABASE_KEY:
    print("❌ Error: Faltan credenciales en .env")
    print(f"   SUPABASE_URL: {'✅' if SUPABASE_URL else '❌'}")
    print(f"   SUPABASE_ANON_KEY: {'✅' if SUPABASE_KEY else '❌'}")
    sys.exit(1)

if not os.path.exists(CSV_DRIVE):
    print(f"❌ Error: No se encuentra el archivo '{CSV_DRIVE}'")
    print(f"   Búscalo en: {os.getcwd()}")
    sys.exit(1)

print("\n" + "="*80)
print("🔍 COMPARACIÓN PRECISA: DRIVE vs SUPABASE")
print("="*80)

# ============================================================================
# PASO 1: CARGAR IDS DE DRIVE (del CSV)
# ============================================================================

print("\n📂 PASO 1: Cargando IDs de Drive desde CSV...")

drive_docs = []
errores = []

with open(CSV_DRIVE, 'r', encoding='utf-8') as f:
    # Leer línea por línea para manejar comas en nombres de archivo
    lines = f.readlines()
    header = lines[0].strip()
    
    for i, line in enumerate(lines[1:], start=2):
        parts = line.strip().split(',')
        
        # Buscar .html o .txt para identificar dónde termina el nombre
        nombre_completo = None
        tipo = None
        sala = None
        
        # Reconstruir el nombre si tiene comas
        for j in range(len(parts)):
            test_nombre = ','.join(parts[:j+1])
            if '.html' in test_nombre or '.txt' in test_nombre:
                nombre_completo = test_nombre
                # El resto son tipo y sala
                remaining = parts[j+1:]
                if len(remaining) >= 1:
                    tipo = remaining[0]
                if len(remaining) >= 2:
                    sala = remaining[1]
                break
        
        if nombre_completo:
            # Extraer ID: quitar .html o .txt
            doc_id = nombre_completo.replace('.html', '').replace('.txt', '')
            
            drive_docs.append({
                'nombre': nombre_completo,
                'tipo': tipo or '',
                'sala': sala or '',
                'id': doc_id
            })
        else:
            errores.append((i, line.strip()))

drive_ids = set([doc['id'] for doc in drive_docs])

print(f"✅ Total IDs en Drive (del CSV): {len(drive_ids):,}")
print(f"   Documentos con metadata: {len(drive_docs):,}")
if errores:
    print(f"⚠️  Líneas con errores de parsing: {len(errores)}")
    print(f"   (Primeras 5: {[e[0] for e in errores[:5]]})")

# ============================================================================
# PASO 2: DESCARGAR IDS DE SUPABASE (usando urllib)
# ============================================================================

print("\n💾 PASO 2: Descargando IDs de Supabase...")

supabase_ids = set()
offset = 0
batch_size = 1000

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
            
    except urllib.error.HTTPError as e:
        print(f"\n❌ Error HTTP {e.code}: {e.reason}")
        print(f"   URL: {url}")
        print(f"   Respuesta: {e.read().decode()}")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Error: {e}")
        sys.exit(1)

print(f"\n✅ Total IDs en Supabase: {len(supabase_ids):,}")

# ============================================================================
# PASO 3: COMPARAR
# ============================================================================

print("\n📊 PASO 3: Comparando IDs...")

faltantes_ids = drive_ids - supabase_ids
extra_ids = supabase_ids - drive_ids

print(f"\n✅ Análisis completado:")
print(f"   Drive IDs:               {len(drive_ids):>10,}")
print(f"   Supabase IDs:            {len(supabase_ids):>10,}")
print(f"   ❌ Faltantes (Drive → Supabase): {len(faltantes_ids):>10,}")
if extra_ids:
    print(f"   ⚠️  Extra en Supabase:        {len(extra_ids):>10,}")

# ============================================================================
# PASO 4: GENERAR CSV DE FALTANTES
# ============================================================================

if faltantes_ids:
    print(f"\n💾 PASO 4: Generando CSV de documentos faltantes...")
    
    faltantes_docs = [doc for doc in drive_docs if doc['id'] in faltantes_ids]
    
    # Agrupar por carpeta
    por_carpeta = {}
    for doc in faltantes_docs:
        carpeta = f"{doc.get('tipo', 'unknown')}/{doc.get('sala', 'unknown')}"
        if carpeta not in por_carpeta:
            por_carpeta[carpeta] = []
        por_carpeta[carpeta].append(doc)
    
    print(f"\n📋 Distribución de faltantes por carpeta:")
    print("="*80)
    for carpeta, docs in sorted(por_carpeta.items(), key=lambda x: len(x[1]), reverse=True):
        print(f"   {carpeta:40} {len(docs):>6,} documentos")
    
    # Guardar CSV
    with open(CSV_OUTPUT, 'w', newline='', encoding='utf-8') as f:
        if faltantes_docs:
            fieldnames = faltantes_docs[0].keys()
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(faltantes_docs)
    
    print(f"\n✅ Guardado: {CSV_OUTPUT} ({len(faltantes_docs):,} registros)")
    print(f"\n📄 Este CSV contiene SOLO los documentos que FALTAN en Supabase")
    
else:
    print(f"\n✅ ¡PERFECTO! No hay documentos faltantes.")

if extra_ids:
    print(f"\n⚠️  Nota: Hay {len(extra_ids):,} IDs en Supabase que no están en Drive")
    with open('ids_extra_en_supabase.txt', 'w') as f:
        for doc_id in sorted(extra_ids):
            f.write(f"{doc_id}\n")

print("\n" + "="*80)
print("✅ ANÁLISIS COMPLETO")
print("="*80)

if faltantes_ids:
    print(f"\n🎯 PRÓXIMO PASO: Procesar los {len(faltantes_ids):,} documentos faltantes")
    print(f"\nUsa este CSV en tu pipeline:")
    print(f"   {CSV_OUTPUT}")

print("\n" + "="*80 + "\n")
