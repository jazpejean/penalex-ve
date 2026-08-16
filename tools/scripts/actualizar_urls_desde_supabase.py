#!/usr/bin/env python3
"""
Actualizar URLs leyendo IDs desde Supabase y buscando en indice R2
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
print("⚡ ACTUALIZAR URLs (Basado en IDs de Supabase)")
print("=" * 80)

# 1. Cargar índice R2 en memoria
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

# 3. Filtrar solo los que existen en R2
print("\n🔍 Filtrando IDs que existen en R2...")
ids_a_actualizar = [doc_id for doc_id in ids_sin_url if doc_id in indice_r2]
ids_no_encontrados = len(ids_sin_url) - len(ids_a_actualizar)

print(f"✅ {len(ids_a_actualizar):,} IDs tienen URLs en R2")
print(f"⚠️  {ids_no_encontrados:,} IDs NO existen en R2")

# 4. Actualizar en Supabase
def actualizar_doc(doc_id):
    urls = indice_r2[doc_id]
    
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

print(f"\n⚡ Actualizando {len(ids_a_actualizar):,} documentos con 50 threads...")

actualizados = 0
errores = 0
start_time = time.time()

with ThreadPoolExecutor(max_workers=50) as executor:
    futures = {executor.submit(actualizar_doc, doc_id): doc_id for doc_id in ids_a_actualizar}
    
    for future in as_completed(futures):
        if future.result():
            actualizados += 1
        else:
            errores += 1
        
        if (actualizados + errores) % 500 == 0:
            elapsed = time.time() - start_time
            rate = (actualizados + errores) / elapsed
            restantes = len(ids_a_actualizar) - (actualizados + errores)
            eta = restantes / rate if rate > 0 else 0
            
            print(f"   {actualizados + errores:,}/{len(ids_a_actualizar):,} | "
                  f"✅ {actualizados:,} | ❌ {errores} | "
                  f"{rate:.1f}/s | ETA: {eta/60:.1f}min")

elapsed = time.time() - start_time
print(f"\n✅ Actualización completada en {elapsed/60:.1f} minutos")
print(f"   Actualizados: {actualizados:,}")
print(f"   Errores: {errores}")
print(f"   Velocidad: {(actualizados + errores)/elapsed:.1f} docs/s")
print("\n" + "=" * 80)
