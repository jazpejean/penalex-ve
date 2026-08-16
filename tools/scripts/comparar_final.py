#!/usr/bin/env python3
"""
Comparar Drive (CSV) vs Supabase usando REGEX para parsear nombres
Versión simplificada sin necesidad de Google Drive API
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
    """Lee solo Supabase del .env"""
    env = {}
    if os.path.exists('.env'):
        with open('.env', 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if line.startswith('SUPABASE_URL'):
                    env['SUPABASE_URL'] = line.split('=', 1)[1].strip().strip('"').strip("'")
                elif line.startswith('SUPABASE_ANON_KEY'):
                    env['SUPABASE_ANON_KEY'] = line.split('=', 1)[1].strip().strip('"').strip("'")
    return env

print("\n" + "="*80)
print("🔍 COMPARACIÓN FINAL: DRIVE (CSV) vs SUPABASE")
print("="*80)

env = load_env()

if 'SUPABASE_URL' not in env or 'SUPABASE_ANON_KEY' not in env:
    print("❌ Error: Faltan credenciales de Supabase en .env")
    sys.exit(1)

print(f"✅ Supabase URL: {env['SUPABASE_URL']}")

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
# PASO 2: Parsear CSV con REGEX (robusto contra comas)
# ============================================================================

print("\n📂 PASO 2: Parseando CSV con regex...")

if not os.path.exists('htmls_faltantes.csv'):
    print("❌ Error: htmls_faltantes.csv no encontrado")
    sys.exit(1)

drive_docs = []

# Patrón MEGA flexible para capturar todos los formatos posibles
# Busca: año_número_exp_algo.html (ignorando espacios, comas, puntos raros)
pattern = r'(\d{4}[_,\s]*\d+[_,\s]*exp[_,\s]*[\w\-\.\s\[\]]+?)[\s,]*\.html'

with open('htmls_faltantes.csv', 'r', encoding='utf-8') as f:
    for i, line in enumerate(f):
        if i == 0:  # Skip header
            continue
        
        # Buscar patrón de documento
        matches = re.findall(pattern, line, re.IGNORECASE)
        
        for match in matches:
            # Limpiar el ID: quitar espacios, comas extra
            doc_id = match.strip()
            doc_id = re.sub(r'\s+', '_', doc_id)  # Espacios → _
            doc_id = re.sub(r',+', '', doc_id)     # Quitar comas
            doc_id = re.sub(r'_+', '_', doc_id)    # Múltiples _ → una _
            
            # Inferir tipo y sala de la línea
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
                'nombre': doc_id + '.html',
                'tipo': tipo,
                'sala': sala
            })

# Remover duplicados manteniendo el primero
seen_ids = set()
drive_docs_uniq = []
for doc in drive_docs:
    if doc['id'] not in seen_ids:
        seen_ids.add(doc['id'])
        drive_docs_uniq.append(doc)

drive_docs = drive_docs_uniq
drive_ids = set([doc['id'] for doc in drive_docs])

print(f"✅ Total IDs extraídos del CSV: {len(drive_ids):,}")
print(f"   Documentos con metadata: {len(drive_docs):,}")

# ============================================================================
# PASO 3: Comparar
# ============================================================================

print("\n📊 PASO 3: Comparando...")

faltantes_ids = drive_ids - supabase_ids
extra_ids = supabase_ids - drive_ids

print(f"\n✅ Análisis completado:")
print(f"   Drive IDs:               {len(drive_ids):>10,}")
print(f"   Supabase IDs:            {len(supabase_ids):>10,}")
print(f"   ❌ Faltantes (Drive→SB):     {len(faltantes_ids):>10,}")
if extra_ids:
    print(f"   ⚠️  Extra (SB→Drive):        {len(extra_ids):>10,}")

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
    
    # Mostrar algunos ejemplos
    print(f"\n📄 Ejemplos de documentos faltantes (primeros 10):")
    for doc in faltantes_docs[:10]:
        print(f"   - {doc['id']} ({doc['tipo']}/{doc['sala']})")
    
else:
    print(f"\n✅ ¡TODO SINCRONIZADO! No hay documentos faltantes.")

if extra_ids:
    print(f"\n⚠️  Nota: {len(extra_ids):,} IDs están en Supabase pero no en el CSV")
    print(f"   (Probablemente documentos viejos o de prueba)")

print("\n" + "="*80)
print("✅ ANÁLISIS COMPLETO")
print("="*80)

if faltantes_ids:
    print(f"\n🎯 SIGUIENTE PASO:")
    print(f"   Procesar los {len(faltantes_ids):,} documentos del archivo:")
    print(f"   → faltantes_definitivo.csv")

print("\n" + "="*80 + "\n")
