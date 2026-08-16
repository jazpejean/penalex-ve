#!/usr/bin/env python3
"""
Script completo para identificar documentos faltantes y reconstruir metadata
Genera CSV con URLs del TSJ y metadata completa
"""

import os
import csv
import json
import sys
import re
from datetime import datetime

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
CSV_OUTPUT = 'faltantes_con_metadata_completa.csv'

# Mapeo de salas a códigos del TSJ
SALA_CODES = {
    'constitucional': 'scon',
    'penal': 'scp',
    'plena': 'plena',
    'penal_juris': 'scp',
    'constitucional_juris': 'scon'
}

# Meses en español
MESES = {
    1: 'enero', 2: 'febrero', 3: 'marzo', 4: 'abril',
    5: 'mayo', 6: 'junio', 7: 'julio', 8: 'agosto',
    9: 'septiembre', 10: 'octubre', 11: 'noviembre', 12: 'diciembre'
}

# ============================================================================
# FUNCIONES AUXILIARES
# ============================================================================

def load_env():
    """Lee credenciales del .env"""
    env = {}
    if os.path.exists('.env'):
        with open('.env', 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, value = line.split('=', 1)
                    env[key.strip()] = value.strip().strip('"').strip("'")
    return env

def extraer_metadata_del_nombre(nombre_archivo):
    """
    Extrae metadata del nombre del archivo
    Ejemplos:
    - 2001_99_exp_00-2301.html → año: 2001, numero: 99, expediente: 00-2301
    - 2022_0735_exp_22-0537.html → año: 2022, numero: 0735, expediente: 22-0537
    """
    # Quitar extensión
    nombre_limpio = nombre_archivo.replace('.html', '').replace('.txt', '')
    
    # Patrón: YYYY_NNN_exp_EE-EEEE
    match = re.match(r'(\d{4})_(\d+)(?:_exp_(.+))?', nombre_limpio)
    
    if match:
        año = match.group(1)
        numero = match.group(2)
        expediente = match.group(3) if match.group(3) else ''
        
        return {
            'año': año,
            'numero': numero.zfill(4),  # Pad con ceros
            'expediente': expediente,
            'fecha_estimada': f"{año}-01-01"  # Fecha por defecto
        }
    
    return {
        'año': '',
        'numero': '',
        'expediente': '',
        'fecha_estimada': ''
    }

def construir_urls_tsj(metadata, tipo, sala):
    """
    Construye posibles URLs del TSJ
    El TSJ tiene múltiples patrones de URL
    """
    año = metadata['año']
    numero = metadata['numero']
    sala_code = SALA_CODES.get(sala.lower(), 'scon')
    
    urls = []
    
    # Patrón 1: https://historico.tsj.gob.ve/decisiones/scon/YYYY/NNNN.HTML
    urls.append(f"https://historico.tsj.gob.ve/decisiones/{sala_code}/{año}/{numero}.HTML")
    
    # Patrón 2: https://historico.tsj.gob.ve/decisiones/scon/NNNN.HTML
    urls.append(f"https://historico.tsj.gob.ve/decisiones/{sala_code}/{numero}.HTML")
    
    # Si tenemos el expediente, agregar más variantes
    if metadata['expediente']:
        exp = metadata['expediente']
        
        # Patrón 3: Con expediente completo
        urls.append(f"https://historico.tsj.gob.ve/decisiones/{sala_code}/{año}/{numero}-{exp}.HTML")
        
        # Patrón 4: Formato RC (resoluciones)
        if tipo == 'resoluciones':
            urls.append(f"https://historico.tsj.gob.ve/decisiones/{sala_code}/{año}/RC-{numero}.HTML")
            urls.append(f"https://historico.tsj.gob.ve/decisiones/{sala_code}/{año}/rc{numero}.HTML")
    
    # Probar con cada mes (si no encontramos, intentar por mes)
    for mes_num, mes_nombre in MESES.items():
        urls.append(f"https://historico.tsj.gob.ve/decisiones/{sala_code}/{mes_nombre}/{año}/{numero}.HTML")
        urls.append(f"https://historico.tsj.gob.ve/decisiones/{sala_code}/{año}/{mes_nombre}/{numero}.HTML")
    
    return urls

# ============================================================================
# MAIN
# ============================================================================

env = load_env()
SUPABASE_URL = env.get('SUPABASE_URL', '')
SUPABASE_KEY = env.get('SUPABASE_ANON_KEY', '')

if not SUPABASE_URL or not SUPABASE_KEY:
    print("❌ Error: Faltan credenciales en .env")
    sys.exit(1)

if not os.path.exists(CSV_DRIVE):
    print(f"❌ Error: No se encuentra '{CSV_DRIVE}'")
    sys.exit(1)

print("\n" + "="*80)
print("🔍 ANÁLISIS COMPLETO: DRIVE vs SUPABASE + RECONSTRUCCIÓN DE METADATA")
print("="*80)

# ============================================================================
# PASO 1: CARGAR IDS DE DRIVE
# ============================================================================

print("\n📂 PASO 1: Cargando IDs de Drive desde CSV...")

drive_docs = []
errores = []

with open(CSV_DRIVE, 'r', encoding='utf-8') as f:
    lines = f.readlines()
    
    for i, line in enumerate(lines[1:], start=2):
        parts = line.strip().split(',')
        
        # Buscar .html o .txt para identificar dónde termina el nombre
        nombre_completo = None
        tipo = None
        sala = None
        
        for j in range(len(parts)):
            test_nombre = ','.join(parts[:j+1])
            if '.html' in test_nombre or '.txt' in test_nombre:
                nombre_completo = test_nombre
                remaining = parts[j+1:]
                if len(remaining) >= 1:
                    tipo = remaining[0]
                if len(remaining) >= 2:
                    sala = remaining[1]
                break
        
        if nombre_completo:
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

print(f"✅ Total IDs en Drive: {len(drive_ids):,}")
print(f"   Documentos con metadata: {len(drive_docs):,}")

# ============================================================================
# PASO 2: DESCARGAR IDS DE SUPABASE
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
            
    except Exception as e:
        print(f"\n❌ Error descargando de Supabase: {e}")
        sys.exit(1)

print(f"\n✅ Total IDs en Supabase: {len(supabase_ids):,}")

# ============================================================================
# PASO 3: IDENTIFICAR FALTANTES
# ============================================================================

print("\n📊 PASO 3: Identificando documentos faltantes...")

faltantes_ids = drive_ids - supabase_ids

print(f"\n✅ Análisis:")
print(f"   Drive IDs:               {len(drive_ids):>10,}")
print(f"   Supabase IDs:            {len(supabase_ids):>10,}")
print(f"   ❌ Faltantes:             {len(faltantes_ids):>10,}")

# ============================================================================
# PASO 4: RECONSTRUIR METADATA COMPLETA
# ============================================================================

if faltantes_ids:
    print(f"\n🔧 PASO 4: Reconstruyendo metadata completa...")
    
    faltantes_completos = []
    
    for doc in drive_docs:
        if doc['id'] in faltantes_ids:
            # Extraer metadata del nombre
            metadata = extraer_metadata_del_nombre(doc['nombre'])
            
            # Construir URLs del TSJ
            urls_tsj = construir_urls_tsj(metadata, doc['tipo'], doc['sala'])
            
            # Crear registro completo
            registro = {
                'id': doc['id'],
                'nombre_archivo': doc['nombre'],
                'tipo': doc['tipo'],
                'sala': doc['sala'],
                'año': metadata['año'],
                'numero': metadata['numero'],
                'expediente': metadata['expediente'],
                'fecha_estimada': metadata['fecha_estimada'],
                'url_tsj_principal': urls_tsj[0] if urls_tsj else '',
                'urls_tsj_alternativas': '|'.join(urls_tsj[1:5]) if len(urls_tsj) > 1 else ''
            }
            
            faltantes_completos.append(registro)
    
    # Agrupar por carpeta
    por_carpeta = {}
    for doc in faltantes_completos:
        carpeta = f"{doc['tipo']}/{doc['sala']}"
        if carpeta not in por_carpeta:
            por_carpeta[carpeta] = []
        por_carpeta[carpeta].append(doc)
    
    print(f"\n📋 Distribución de faltantes por carpeta:")
    print("="*80)
    for carpeta, docs in sorted(por_carpeta.items(), key=lambda x: len(x[1]), reverse=True):
        print(f"   {carpeta:40} {len(docs):>6,} documentos")
    
    # Guardar CSV
    with open(CSV_OUTPUT, 'w', newline='', encoding='utf-8') as f:
        fieldnames = [
            'id', 'nombre_archivo', 'tipo', 'sala',
            'año', 'numero', 'expediente', 'fecha_estimada',
            'url_tsj_principal', 'urls_tsj_alternativas'
        ]
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(faltantes_completos)
    
    print(f"\n✅ Guardado: {CSV_OUTPUT}")
    print(f"   Total registros: {len(faltantes_completos):,}")
    print(f"\n📄 El CSV incluye:")
    print(f"   • ID del documento")
    print(f"   • Nombre del archivo")
    print(f"   • Tipo y sala")
    print(f"   • Metadata extraída (año, número, expediente)")
    print(f"   • URL principal del TSJ")
    print(f"   • URLs alternativas del TSJ")
    
else:
    print(f"\n✅ ¡PERFECTO! No hay documentos faltantes.")

print("\n" + "="*80)
print("✅ ANÁLISIS COMPLETO")
print("="*80)

if faltantes_ids:
    print(f"\n🎯 PRÓXIMOS PASOS:")
    print(f"   1. Revisar el CSV: {CSV_OUTPUT}")
    print(f"   2. Validar las URLs del TSJ (algunas pueden no existir)")
    print(f"   3. Descargar los HTMLs faltantes desde Drive")
    print(f"   4. Procesar con tu pipeline")

print("\n" + "="*80 + "\n")
