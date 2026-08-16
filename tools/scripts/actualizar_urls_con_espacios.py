#!/usr/bin/env python3
"""
Actualizar URLs con URL encoding para IDs con espacios
"""
import os
import csv
import json
import time
import urllib.request
import urllib.parse
from concurrent.futures import ThreadPoolExecutor, as_completed
from dotenv import load_dotenv

load_dotenv()

SUPABASE_URL = os.environ.get('SUPABASE_URL')
SUPABASE_KEY = os.environ.get('SUPABASE_SERVICE_KEY')

print("=" * 80)
print("⚡ ACTUALIZAR URLs (con URL encoding)")
print("=" * 80)

# 1. Cargar índice R2
print("\n📂 Cargando índice R2...")
indice_r2 = {}
with open('indice_completo.csv', 'r', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    for row in reader:
        nombre = row['id'].split('/')[-1]
        indice_r2[nombre] = {
            'url_html': row['url_html'],
            'url_txt': row['url_txt']
        }

print(f"✅ {len(indice_r2):,} documentos en índice R2")

# 2. Obtener IDs sin URL
print("\n📥 Obteniendo IDs sin URLs...")
ids_sin_url = []
offset = 0
batch_size = 1000

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
        
        ids_sin_url.extend(data)
        offset += batch_size

print(f"✅ {len(ids_sin_url):,} documentos sin URLs")

# 3. Filtrar los que existen en R2
urls_a_actualizar = {}
for doc in ids_sin_url:
    doc_id = doc['id']
    if doc_id in indice_r2:
        urls_a_actualizar[doc_id] = indice_r2[doc_id]

print(f"✅ {len(urls_a_actualizar):,} documentos con URLs en R2")

# 4. Actualizar con URL encoding
def actualizar_doc(doc_id):
    urls = urls_a_actualizar[doc_id]
    
    for intento in range(3):
        try:
            # URL-encodear el ID para manejar espacios y caracteres especiales
            doc_id_encoded = urllib.parse.quote(doc_id, safe='')
            url = f"{SUPABASE_URL}/rest/v1/documentos?id=eq.{doc_id_encoded}"
            
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
                print(f"   ❌ Error en {doc_id}: {str(e)[:80]}")
                return False
            time.sleep(0.5)
    return False

if urls_a_actualizar:
    print(f"\n⚡ Actualizando {len(urls_a_actualizar):,} documentos...")

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
            
            if (actualizados + errores) % 50 == 0:
                elapsed = time.time() - start_time
                rate = (actualizados + errores) / elapsed
                restantes = len(urls_a_actualizar) - (actualizados + errores)
                eta = restantes / rate if rate > 0 else 0
                
                print(f"   {actualizados + errores:,}/{len(urls_a_actualizar):,} | "
                      f"✅ {actualizados:,} | ❌ {errores} | "
                      f"{rate:.1f}/s | ETA: {eta:.1f}s")

    elapsed = time.time() - start_time
    print(f"\n✅ Actualización completada en {elapsed:.1f} segundos")
    print(f"   Actualizados: {actualizados:,}")
    print(f"   Errores: {errores}")

print("\n" + "=" * 80)
