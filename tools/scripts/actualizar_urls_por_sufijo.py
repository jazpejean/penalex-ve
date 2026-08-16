#!/usr/bin/env python3
"""
Actualizar URLs buscando por sufijo (endswith)
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
print("⚡ ACTUALIZAR URLs (Búsqueda por Sufijo)")
print("=" * 80)

# 1. Cargar índice R2
print("\n📂 Cargando índice R2...")
indice_r2 = {}

with open('indice_completo.csv', 'r', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    for row in reader:
        indice_r2[row['id']] = {
            'url_html': row['url_html'],
            'url_txt': row['url_txt']
        }

print(f"✅ {len(indice_r2):,} documentos en índice R2")

# 2. Obtener IDs de Supabase SIN URL
print("\n📥 Obteniendo IDs sin URL desde Supabase...")
ids_sin_url = []
offset = 0
batch_size = 1000

while True:
    url = f"{SUPABASE_URL}/rest/v1/documentos?select=id&url_html=is.null&limit={batch_size}&offset={offset}"
    headers = {
        'apikey': SUPABASE_KEY,
        'Authorization': f'Bearer {SUPABASE_KEY}'
    }
    
    req = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(req, timeout=15) as response:
        data = json.loads(response.read().decode('utf-8'))
        
        if not data:
            break
        
        ids_sin_url.extend([doc['id'] for doc in data])
        offset += batch_size
        print(f"   Obtenidos: {len(ids_sin_url):,}", end='\r')

print(f"\n✅ {len(ids_sin_url):,} documentos sin URL en Supabase")

# 3. Buscar coincidencias por sufijo
print("\n🔍 Buscando coincidencias por sufijo...")
urls_encontradas = {}
no_encontrados = []

for doc_id_supabase in ids_sin_url:
    encontrado = False
    
    # Buscar en R2 si algún ID termina con el ID de Supabase
    for id_r2, urls in indice_r2.items():
        if id_r2.endswith(doc_id_supabase):
            urls_encontradas[doc_id_supabase] = urls
            encontrado = True
            break
    
    if not encontrado:
        no_encontrados.append(doc_id_supabase)
    
    if (len(urls_encontradas) + len(no_encontrados)) % 1000 == 0:
        print(f"   Procesados: {len(urls_encontradas) + len(no_encontrados):,} | "
              f"✅ {len(urls_encontradas):,} | ⚠️  {len(no_encontrados):,}", end='\r')

print(f"\n✅ {len(urls_encontradas):,} IDs encontrados")
print(f"⚠️  {len(no_encontrados):,} IDs NO encontrados")

# 4. Actualizar en Supabase
def actualizar_doc(doc_id):
    urls = urls_encontradas[doc_id]
    
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

if urls_encontradas:
    print(f"\n⚡ Actualizando {len(urls_encontradas):,} documentos con 50 threads...")

    actualizados = 0
    errores = 0
    start_time = time.time()

    with ThreadPoolExecutor(max_workers=50) as executor:
        futures = {executor.submit(actualizar_doc, doc_id): doc_id for doc_id in urls_encontradas.keys()}
        
        for future in as_completed(futures):
            if future.result():
                actualizados += 1
            else:
                errores += 1
            
            if (actualizados + errores) % 500 == 0:
                elapsed = time.time() - start_time
                rate = (actualizados + errores) / elapsed
                restantes = len(urls_encontradas) - (actualizados + errores)
                eta = restantes / rate if rate > 0 else 0
                
                print(f"   {actualizados + errores:,}/{len(urls_encontradas):,} | "
                      f"✅ {actualizados:,} | ❌ {errores} | "
                      f"{rate:.1f}/s | ETA: {eta/60:.1f}min")

    elapsed = time.time() - start_time
    print(f"\n✅ Actualización completada en {elapsed/60:.1f} minutos")
    print(f"   Actualizados: {actualizados:,}")
    print(f"   Errores: {errores}")
    print(f"   Velocidad: {(actualizados + errores)/elapsed:.1f} docs/s")
else:
    print("\n⚠️  No hay documentos para actualizar")

print("\n" + "=" * 80)
