#!/usr/bin/env python3
"""
Actualizar URLs de HTML y TXT en Supabase desde indice_completo.csv
VERSIÓN PARALELA ULTRA RÁPIDA (50 threads)
"""
import os
import csv
import sys
import json
import time
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from dotenv import load_dotenv

load_dotenv()

SUPABASE_URL = os.environ.get('SUPABASE_URL')
SUPABASE_KEY = os.environ.get('SUPABASE_ANON_KEY') or os.environ.get('SUPABASE_SERVICE_KEY')

if not SUPABASE_URL or not SUPABASE_KEY:
    print("❌ Faltan SUPABASE_URL o SUPABASE_ANON_KEY/SUPABASE_SERVICE_KEY en .env")
    sys.exit(1)

print("=" * 80)
print("⚡ ACTUALIZAR URLs EN SUPABASE (VERSIÓN PARALELA)")
print("=" * 80)

# Leer índice
print("\n📂 Leyendo indice_completo.csv...")
if not os.path.exists('indice_completo.csv'):
    print("❌ No existe indice_completo.csv")
    sys.exit(1)

docs = []
with open('indice_completo.csv', 'r', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    for row in reader:
        docs.append(row)

print(f"✅ {len(docs):,} documentos en el índice")

def actualizar_doc(doc):
    """Actualiza un documento en Supabase con reintentos"""
    doc_id = doc['id']
    url_html = doc['url_html']
    url_txt = doc['url_txt']
    
    for intento in range(3):  # 3 reintentos
        try:
            url = f"{SUPABASE_URL}/rest/v1/documentos?id=eq.{doc_id}"
            headers = {
                'apikey': SUPABASE_KEY,
                'Authorization': f'Bearer {SUPABASE_KEY}',
                'Content-Type': 'application/json',
                'Prefer': 'return=minimal'
            }
            
            data = json.dumps({
                'url_html': url_html if url_html else None,
                'url_txt': url_txt if url_txt else None
            }).encode('utf-8')
            
            req = urllib.request.Request(url, data=data, headers=headers, method='PATCH')
            with urllib.request.urlopen(req, timeout=15) as response:
                return response.status in [200, 204]
        except Exception as e:
            if intento == 2:  # Último intento
                return False
            time.sleep(0.5)  # Esperar antes de reintentar
    return False

# Procesar con threads paralelos
print(f"\n⚡ Actualizando con 50 threads en paralelo...")
print(f"   (Esto tomará ~{len(docs)/50/60:.1f} minutos)")

actualizados = 0
errores = 0
start_time = time.time()

with ThreadPoolExecutor(max_workers=50) as executor:
    # Enviar todos los trabajos
    futures = {executor.submit(actualizar_doc, doc): i for i, doc in enumerate(docs)}
    
    # Procesar resultados conforme van terminando
    for future in as_completed(futures):
        if future.result():
            actualizados += 1
        else:
            errores += 1
        
        # Mostrar progreso cada 500
        total_procesados = actualizados + errores
        if total_procesados % 500 == 0:
            elapsed = time.time() - start_time
            rate = total_procesados / elapsed
            restantes = len(docs) - total_procesados
            eta_segundos = restantes / rate if rate > 0 else 0
            
            print(f"   {total_procesados:,}/{len(docs):,} | "
                  f"✅ {actualizados:,} | ❌ {errores} | "
                  f"{rate:.1f}/s | ETA: {eta_segundos/60:.1f}min")

# Resumen final
elapsed = time.time() - start_time
print(f"\n✅ Actualización completada en {elapsed/60:.1f} minutos")
print(f"   Actualizados: {actualizados:,}")
print(f"   Errores: {errores}")
print(f"   Velocidad promedio: {len(docs)/elapsed:.1f} docs/segundo")
print("\n" + "=" * 80 + "\n")
