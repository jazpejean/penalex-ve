#!/usr/bin/env python3
"""
Sincronización completa: Actualizar URLs y detectar faltantes
"""
import os
import csv
import json
import time
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from dotenv import load_dotenv

load_dotenv()

SUPABASE_URL = os.environ.get('SUPABASE_URL')
SUPABASE_KEY = os.environ.get('SUPABASE_SERVICE_KEY')

print("=" * 80)
print("📊 SINCRONIZACIÓN COMPLETA R2 ↔ SUPABASE")
print("=" * 80)

# 1. Cargar índice R2 con búsqueda por nombre de archivo
print("\n📂 Paso 1/5: Cargando índice R2...")
indice_r2_completo = {}  # ID completo -> URLs
indice_r2_por_nombre = {}  # Nombre archivo -> URLs

with open('indice_completo.csv', 'r', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    for row in reader:
        full_id = row['id']
        nombre_archivo = full_id.split('/')[-1]  # Última parte
        
        urls = {
            'url_html': row['url_html'],
            'url_txt': row['url_txt']
        }
        
        indice_r2_completo[full_id] = urls
        
        # Guardar por nombre (puede haber duplicados, guardar el primero)
        if nombre_archivo not in indice_r2_por_nombre:
            indice_r2_por_nombre[nombre_archivo] = urls

print(f"✅ {len(indice_r2_completo):,} IDs completos en R2")
print(f"✅ {len(indice_r2_por_nombre):,} nombres únicos")

# 2. Obtener TODOS los IDs de Supabase
print("\n📥 Paso 2/5: Obteniendo todos los IDs de Supabase...")
ids_supabase = set()
offset = 0
batch_size = 1000

while True:
    url = f"{SUPABASE_URL}/rest/v1/documentos?select=id&limit={batch_size}&offset={offset}"
    headers = {
        'apikey': SUPABASE_KEY,
        'Authorization': f'Bearer {SUPABASE_KEY}'
    }
    
    req = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(req, timeout=15) as response:
        data = json.loads(response.read().decode('utf-8'))
        
        if not data:
            break
        
        ids_supabase.update([doc['id'] for doc in data])
        offset += batch_size
        print(f"   Obtenidos: {len(ids_supabase):,}", end='\r')

print(f"\n✅ {len(ids_supabase):,} IDs en Supabase")

# 3. Obtener IDs SIN URLs
print("\n📥 Paso 3/5: Obteniendo IDs sin URLs...")
ids_sin_url_html = set()
ids_sin_url_txt = set()
offset = 0

while True:
    url = f"{SUPABASE_URL}/rest/v1/documentos?select=id,url_html,url_txt&or=(url_html.is.null,url_txt.is.null)&limit={batch_size}&offset={offset}"
    headers = {
        'apikey': SUPABASE_KEY,
        'Authorization': f'Bearer {SUPABASE_KEY}'
    }
    
    req = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(req, timeout=15) as response:
        data = json.loads(response.read().decode('utf-8'))
        
        if not data:
            break
        
        for doc in data:
            if not doc.get('url_html'):
                ids_sin_url_html.add(doc['id'])
            if not doc.get('url_txt'):
                ids_sin_url_txt.add(doc['id'])
        
        offset += batch_size
        print(f"   Sin HTML: {len(ids_sin_url_html):,} | Sin TXT: {len(ids_sin_url_txt):,}", end='\r')

print(f"\n✅ {len(ids_sin_url_html):,} sin url_html")
print(f"✅ {len(ids_sin_url_txt):,} sin url_txt")

# 4. Hacer matching con R2
print("\n🔍 Paso 4/5: Haciendo matching...")
urls_a_actualizar = {}
ids_no_encontrados = set()

ids_a_buscar = ids_sin_url_html | ids_sin_url_txt

for doc_id in ids_a_buscar:
    # Buscar por nombre de archivo
    if doc_id in indice_r2_por_nombre:
        urls_a_actualizar[doc_id] = indice_r2_por_nombre[doc_id]
    else:
        ids_no_encontrados.add(doc_id)
    
    if (len(urls_a_actualizar) + len(ids_no_encontrados)) % 1000 == 0:
        print(f"   Procesados: {len(urls_a_actualizar) + len(ids_no_encontrados):,} | "
              f"✅ {len(urls_a_actualizar):,} | ⚠️  {len(ids_no_encontrados):,}", end='\r')

print(f"\n✅ {len(urls_a_actualizar):,} IDs con URLs en R2")
print(f"⚠️  {len(ids_no_encontrados):,} IDs NO encontrados en R2")

# 5. Detectar documentos en R2 pero NO en Supabase
print("\n🔍 Detectando documentos en R2 que NO están en Supabase...")
nombres_supabase = {doc_id.split('/')[-1] for doc_id in ids_supabase}
nombres_supabase.update(ids_supabase)  # Incluir también IDs completos

ids_r2_faltantes = []
for full_id in indice_r2_completo.keys():
    nombre = full_id.split('/')[-1]
    if nombre not in nombres_supabase and full_id not in ids_supabase:
        ids_r2_faltantes.append({
            'id_r2': full_id,
            'url_html': indice_r2_completo[full_id]['url_html'],
            'url_txt': indice_r2_completo[full_id]['url_txt']
        })

print(f"⚠️  {len(ids_r2_faltantes):,} documentos en R2 que NO están en Supabase")

# Guardar faltantes en CSV
if ids_r2_faltantes:
    with open('documentos_r2_faltantes_en_supabase.csv', 'w', encoding='utf-8', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=['id_r2', 'url_html', 'url_txt'])
        writer.writeheader()
        writer.writerows(ids_r2_faltantes)
    print(f"✅ Guardado en: documentos_r2_faltantes_en_supabase.csv")

# 6. Actualizar URLs en Supabase
def actualizar_doc(doc_id):
    urls = urls_a_actualizar[doc_id]
    
    for intento in range(3):
        try:
            url = f"{SUPABASE_URL}/rest/v1/documentos?id=eq.{doc_id}"
            headers = {
                'apikey': SUPABASE_KEY,
                'Authorization': f'Bearer {SUPABASE_KEY}',
                'Content-Type': 'application/json',
                'Prefer': 'return=minimal'
            }
            
            data = json.dumps({
                'url_html': urls['url_html'] if urls['url_html'] else None,
                'url_txt': urls['url_txt'] if urls['url_txt'] else None
            }).encode('utf-8')
            
            req = urllib.request.Request(url, data=data, headers=headers, method='PATCH')
            with urllib.request.urlopen(req, timeout=15) as response:
                return response.status in [200, 204]
        except Exception as e:
            if intento == 2:
                return False
            time.sleep(0.5)
    return False

if urls_a_actualizar:
    print(f"\n⚡ Paso 5/5: Actualizando {len(urls_a_actualizar):,} documentos...")

    actualizados = 0
    errores = 0
    start_time = time.time()

    with ThreadPoolExecutor(max_workers=50) as executor:
        futures = {executor.submit(actualizar_doc, doc_id): doc_id for doc_id in urls_a_actualizar.keys()}
        
        for future in as_completed(futures):
            if future.result():
                actualizados += 1
            else:
                errores += 1
            
            if (actualizados + errores) % 500 == 0:
                elapsed = time.time() - start_time
                rate = (actualizados + errores) / elapsed
                restantes = len(urls_a_actualizar) - (actualizados + errores)
                eta = restantes / rate if rate > 0 else 0
                
                print(f"   {actualizados + errores:,}/{len(urls_a_actualizar):,} | "
                      f"✅ {actualizados:,} | ❌ {errores} | "
                      f"{rate:.1f}/s | ETA: {eta/60:.1f}min")

    elapsed = time.time() - start_time
    print(f"\n✅ Actualización completada en {elapsed/60:.1f} minutos")
    print(f"   Actualizados: {actualizados:,}")
    print(f"   Errores: {errores}")

print("\n" + "=" * 80)
print("📊 RESUMEN FINAL")
print("=" * 80)
print(f"✅ Supabase:        {len(ids_supabase):,} documentos")
print(f"✅ R2:              {len(indice_r2_completo):,} documentos")
print(f"✅ Actualizados:    {actualizados if urls_a_actualizar else 0:,}")
print(f"⚠️  No encontrados: {len(ids_no_encontrados):,}")
print(f"📝 R2 faltantes:   {len(ids_r2_faltantes):,} (ver CSV)")
print("=" * 80 + "\n")
