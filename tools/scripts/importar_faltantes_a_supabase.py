#!/usr/bin/env python3
"""
Procesar metadata de Google Drive e importar faltantes a Supabase
"""
import os
import sys
import csv
import glob
from datetime import datetime
import requests

SUPABASE_URL = os.environ.get('SUPABASE_URL')
SUPABASE_KEY = os.environ.get('SUPABASE_SERVICE_KEY') or os.environ.get('SUPABASE_ANON_KEY')

print("=" * 80)
print("📋 IMPORTAR FALTANTES A SUPABASE")
print("=" * 80 + "\n")

# 1. Leer faltantes de R2
print("📂 Paso 1/4: Leyendo faltantes_en_supabase.csv...")
if not os.path.exists('faltantes_en_supabase.csv'):
    print("❌ No existe faltantes_en_supabase.csv")
    sys.exit(1)

faltantes_r2 = {}
with open('faltantes_en_supabase.csv', 'r', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    for row in reader:
        doc_id = row['id'].replace('.html', '').replace('.HTML', '')
        faltantes_r2[doc_id] = {
            'url_html': row['url_html'],
            'url_txt': row['url_txt']
        }

print(f"✅ {len(faltantes_r2):,} documentos faltantes en Supabase\n")

# 2. Leer TODOS los CSV de metadata
print("📂 Paso 2/4: Leyendo metadata de Google Drive...")
metadata = {}
archivos_csv = glob.glob('Metadata/*.csv')

for archivo in archivos_csv:
    print(f"  Procesando: {os.path.basename(archivo)}")
    try:
        with open(archivo, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                # Extraer ID del archivo
                archivo_html = row.get('archivo', '')
                doc_id = archivo_html.replace('.html', '').replace('.HTML', '')
                
                if doc_id:
                    metadata[doc_id] = row
    except Exception as e:
        print(f"    ⚠️ Error: {e}")

print(f"✅ {len(metadata):,} documentos en metadata\n")

# 3. Cruzar datos
print("📊 Paso 3/4: Cruzando datos...")
coincidencias = 0
sin_metadata = 0
listos_para_importar = []

for doc_id, urls in faltantes_r2.items():
    if doc_id in metadata:
        coincidencias += 1
        meta = metadata[doc_id]
        
        # Parsear fecha (formato: 20/01/2000)
        try:
            fecha_str = meta.get('fecha', '')
            if '/' in fecha_str:
                fecha_obj = datetime.strptime(fecha_str, '%d/%m/%Y')
                fecha_iso = fecha_obj.strftime('%Y-%m-%d')
            else:
                fecha_iso = None
        except:
            fecha_iso = None
        
        # Preparar documento completo
        doc_completo = {
            'id': doc_id,
            'tipo': 'sentencia',
            'sala': 'constitucional',  # Ajusta según necesites
            'fecha': fecha_iso,
            'num_sentencia': meta.get('num_sentencia', ''),
            'expediente': meta.get('expediente', ''),
            'partes': meta.get('partes', ''),
            'ponente': meta.get('ponente', ''),
            'procedimiento': meta.get('procedimiento', ''),
            'decision': meta.get('decision', ''),
            'url_html': urls['url_html'],
            'url_txt': urls['url_txt'],
            'tiene_pdf': False,
            'relevancia': 3,
            'vistas': 0
        }
        
        listos_para_importar.append(doc_completo)
    else:
        sin_metadata += 1

print(f"✅ Coincidencias:    {coincidencias:,}")
print(f"⚠️  Sin metadata:    {sin_metadata:,}\n")

if coincidencias == 0:
    print("⚠️  No hay coincidencias.")
    print("\nPrimeros 5 IDs en faltantes:")
    for i, doc_id in enumerate(list(faltantes_r2.keys())[:5]):
        print(f"  - {doc_id}")
    print("\nPrimeros 5 IDs en metadata:")
    for i, doc_id in enumerate(list(metadata.keys())[:5]):
        print(f"  - {doc_id}")
    sys.exit(0)

# 4. Guardar CSV para revisión
print("💾 Guardando listos_para_importar.csv...")
if listos_para_importar:
    keys = listos_para_importar[0].keys()
    with open('listos_para_importar.csv', 'w', encoding='utf-8', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=keys)
        writer.writeheader()
        writer.writerows(listos_para_importar)
    
    print(f"✅ Guardado: {len(listos_para_importar):,} documentos\n")

# 5. Importar a Supabase
if SUPABASE_URL and SUPABASE_KEY and listos_para_importar:
    print("📊 Paso 4/4: Importando a Supabase...")
    importados = 0
    errores = 0
    
    for doc in listos_para_importar:
        try:
            url = f"{SUPABASE_URL}/rest/v1/documentos"
            headers = {
                'apikey': SUPABASE_KEY,
                'Authorization': f'Bearer {SUPABASE_KEY}',
                'Content-Type': 'application/json',
                'Prefer': 'return=minimal'
            }
            
            response = requests.post(url, json=doc, headers=headers, timeout=10)
            if response.status_code in [200, 201, 204]:
                importados += 1
            else:
                errores += 1
        except Exception as e:
            errores += 1
        
        if (importados + errores) % 100 == 0:
            print(f"  {importados:,} importados, {errores} errores", end='\r', flush=True)
    
    print(f"\n✅ Importación completada: {importados:,} documentos")
    if errores > 0:
        print(f"❌ Errores: {errores}\n")

print("\n" + "=" * 80)
print("✅ PROCESO COMPLETADO")
print("=" * 80)
print(f"\n📊 Resumen:")
print(f"   Metadata encontrada:  {len(metadata):,}")
print(f"   Coincidencias:        {coincidencias:,}")
print(f"   Importados:           {importados:,}")
print(f"   Sin metadata:         {sin_metadata:,}")
print("\n" + "=" * 80 + "\n")
