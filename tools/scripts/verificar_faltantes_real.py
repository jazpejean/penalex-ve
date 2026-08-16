#!/usr/bin/env python3
"""
Verificación REAL de faltantes - método simple
Cada línea del CSV = 1 documento, sin regex complicado
"""

import os
import json
import sys
import csv
import re

try:
    import urllib.request
    import urllib.error
except ImportError:
    print("❌ Error: urllib no disponible")
    sys.exit(1)

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
print("🔍 VERIFICACIÓN REAL DE FALTANTES - MÉTODO SIMPLE")
print("="*80)

env = load_env()

if 'SUPABASE_URL' not in env or 'SUPABASE_ANON_KEY' not in env:
    print("❌ Error: Faltan credenciales de Supabase en .env")
    sys.exit(1)

# ============================================================================
# PASO 1: LEER CSV LÍNEA POR LÍNEA (método brutal pero efectivo)
# ============================================================================

print("\n📂 PASO 1: Leyendo CSV línea por línea...")

drive_docs = []

with open('htmls_faltantes.csv', 'r', encoding='utf-8') as f:
    lines = f.readlines()
    
    print(f"✅ Total líneas en CSV: {len(lines):,}")
    
    # Saltar header
    for i, line in enumerate(lines[1:], start=2):
        line = line.strip()
        if not line:
            continue
        
        # Extraer CUALQUIER cosa que parezca un nombre de archivo
        # Buscar cualquier patrón que termine en .html
        match = re.search(r'([^\s,]+\.html)', line)
        
        if match:
            nombre_completo = match.group(1)
            # Limpiar el ID: quitar .html y normalizar
            doc_id = nombre_completo.replace('.html', '')
            
            # Limpiar caracteres raros pero mantener estructura
            doc_id = doc_id.strip()
            
            # Inferir tipo y sala
            tipo = 'sentencia'
            sala = 'constitucional'
            
            line_lower = line.lower()
            if 'penal' in line_lower:
                sala = 'penal'
            if 'plena' in line_lower or 'resolucion' in doc_id.lower():
                tipo = 'resoluciones'
                sala = 'plena'
            if 'sustanciacion' in line_lower:
                sala = 'sustanciacion'
            if 'juris' in line_lower:
                tipo = 'jurisprudencia'
            
            drive_docs.append({
                'id': doc_id,
                'nombre': nombre_completo,
                'tipo': tipo,
                'sala': sala,
                'linea_csv': i
            })

print(f"✅ Documentos extraídos: {len(drive_docs):,}")

# Remover duplicados
drive_ids_set = set()
drive_docs_uniq = []
for doc in drive_docs:
    if doc['id'] not in drive_ids_set:
        drive_ids_set.add(doc['id'])
        drive_docs_uniq.append(doc)

drive_docs = drive_docs_uniq
drive_ids = set([doc['id'] for doc in drive_docs])

print(f"✅ IDs únicos: {len(drive_ids):,}")

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
# PASO 3: COMPARAR - SIN NORMALIZACIÓN AGRESIVA
# ============================================================================

print("\n📊 PASO 3: Comparando IDs...")

# Comparación directa
faltantes_ids_directo = drive_ids - supabase_ids

print(f"\n✅ Comparación directa:")
print(f"   Drive IDs:               {len(drive_ids):>10,}")
print(f"   Supabase IDs:            {len(supabase_ids):>10,}")
print(f"   Faltantes (directo):     {len(faltantes_ids_directo):>10,}")

# Intentar comparación normalizada (quitar espacios, guiones bajos, etc.)
def normalizar_id(id_str):
    """Normalización agresiva para matching"""
    # Quitar espacios, comas, puntos extra
    normalized = re.sub(r'[\s,]+', '_', id_str)
    normalized = re.sub(r'_+', '_', normalized)
    normalized = normalized.strip('_')
    return normalized.lower()

drive_ids_norm = {normalizar_id(id): id for id in drive_ids}
supabase_ids_norm = {normalizar_id(id) for id in supabase_ids}

faltantes_norm = set(drive_ids_norm.keys()) - supabase_ids_norm

print(f"\n✅ Comparación normalizada:")
print(f"   Faltantes (normalizado): {len(faltantes_norm):>10,}")

# Usar la comparación directa (más confiable)
faltantes_ids = faltantes_ids_directo

# ============================================================================
# PASO 4: GENERAR CSV
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
    with open('faltantes_verificado.csv', 'w', newline='', encoding='utf-8') as f:
        fieldnames = ['id', 'nombre', 'tipo', 'sala', 'linea_csv']
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(faltantes_docs)
    
    print(f"\n✅ Guardado: faltantes_verificado.csv ({len(faltantes_docs):,} registros)")
    
    # Ejemplos
    print(f"\n📄 Primeros 20 faltantes:")
    for doc in faltantes_docs[:20]:
        print(f"   - {doc['id']}")
    
else:
    print(f"\n✅ ¡TODO SINCRONIZADO!")

print("\n" + "="*80)
print("✅ VERIFICACIÓN COMPLETA")
print("="*80)

print(f"\n🎯 RESUMEN:")
print(f"   CSV original:            {len(lines)-1:>10,} líneas")
print(f"   IDs extraídos:           {len(drive_ids):>10,}")
print(f"   Supabase:                {len(supabase_ids):>10,}")
print(f"   ❌ FALTANTES REALES:        {len(faltantes_ids):>10,}")
print(f"   % Completitud:           {100*(1-len(faltantes_ids)/len(drive_ids)):.1f}%")

print("\n" + "="*80 + "\n")
