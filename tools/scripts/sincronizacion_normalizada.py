#!/usr/bin/env python3
"""
Sincronización con normalización de IDs (espacios, guiones, etc.)
"""
import os
import csv
import json
import time
import re
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from dotenv import load_dotenv

load_dotenv()

SUPABASE_URL = os.environ.get('SUPABASE_URL')
SUPABASE_KEY = os.environ.get('SUPABASE_SERVICE_KEY')

def normalizar_id(text):
    """Normalizar ID: sin espacios extras, minúsculas, sin caracteres raros"""
    if not text:
        return ''
    # Quitar espacios extras
    text = re.sub(r'\s+', '', text)
    # Minúsculas
    text = text.lower()
    return text

print("=" * 80)
print("⚡ SINCRONIZACIÓN CON NORMALIZACIÓN DE IDs")
print("=" * 80)

# 1. Cargar índice R2 con normalización
print("\n📂 Paso 1/4: Cargando índice R2...")
indice_r2_normalizado = {}  # ID normalizado -> URLs
indice_r2_original = {}  # ID original -> URLs

with open('indice_completo.csv', 'r', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    for row in reader:
        full_id = row['id']
        nombre = full_id.split('/')[-1]
        nombre_normalizado = normalizar_id(nombre)
        
        urls = {
            'url_html': row['url_html'],
            'url_txt': row['url_txt']
        }
        
        indice_r2_original[nombre] = urls
        
        # Guardar por nombre normalizado (usar el primero si hay duplicados)
        if nombre_normalizado not in indice_r2_normalizado:
            indice_r2_normalizado[nombre_normalizado] = urls

print(f"✅ {len(indice_r2_original):,} IDs originales")
print(f"✅ {len(indice_r2_normalizado):,} IDs normalizados únicos")

# 2. Obtener IDs de Supabase SIN URLs
print("\n📥 Paso 2/4: Obteniendo IDs sin URLs desde Supabase...")
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
        print(f"   Obtenidos: {len(ids_sin_url):,}", end='\r')

print(f"\n✅ {len(ids_sin_url):,} documentos sin URLs completas")

# 3. Hacer matching con normalización
print("\n🔍 Paso 3/4: Haciendo matching normalizado...")
urls_a_actualizar = {}
no_encontrados = []

for doc in ids_sin_url:
    doc_id = doc['id']
    doc_id_normalizado = normalizar_id(doc_id)
    
    encontrado = False
    
    # 1. Intento exacto (original)
    if doc_id in indice_r2_original:
        urls_a_actualizar[doc_id] = indice_r2_original[doc_id]
        encontrado = True
    # 2. Intento normalizado
    elif doc_id_normalizado in indice_r2_normalizado:
        urls_a_actualizar[doc_id] = indice_r2_normalizado[doc_id_normalizado]
        encontrado = True
    
    if not encontrado:
        no_encontrados.append(doc_id)
    
    if (len(urls_a_actualizar) + len(no_encontrados)) % 1000 == 0:
        print(f"   Procesados: {len(urls_a_actualizar) + len(no_encontrados):,} | "
              f"✅ {len(urls_a_actualizar):,} | ⚠️  {len(no_encontrados):,}", end='\r')

print(f"\n✅ {len(urls_a_actualizar):,} IDs encontrados")
print(f"⚠️  {len(no_encontrados):,} IDs NO encontrados")

# Guardar no encontrados
if no_encontrados:
    with open('ids_no_encontrados.txt', 'w', encoding='utf-8') as f:
        for doc_id in no_encontrados:
            f.write(f"{doc_id}\n")
    print(f"✅ IDs no encontrados guardados en: ids_no_encontrados.txt")

# 4. Actualizar en Supabase
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
    print(f"\n⚡ Paso 4/4: Actualizando {len(urls_a_actualizar):,} documentos...")

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
else:
    print("\n⚠️  No hay documentos para actualizar")

print("\n" + "=" * 80)
