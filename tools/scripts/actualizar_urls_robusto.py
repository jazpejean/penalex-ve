#!/usr/bin/env python3
"""
Actualizar URLs de HTML y TXT en Supabase desde indice_completo.csv
VERSIÓN ROBUSTA CON CHECKPOINTS Y REINTENTOS
"""
import os
import csv
import sys
import json
import time
import urllib.request
from dotenv import load_dotenv

load_dotenv()

SUPABASE_URL = os.environ.get('SUPABASE_URL')
SUPABASE_KEY = os.environ.get('SUPABASE_ANON_KEY')
CHECKPOINT_FILE = 'checkpoint_actualizacion.txt'

if not SUPABASE_URL or not SUPABASE_KEY:
    print("❌ Faltan SUPABASE_URL o SUPABASE_ANON_KEY en .env")
    sys.exit(1)

print("=" * 80)
print("📊 ACTUALIZAR URLs EN SUPABASE (VERSIÓN ROBUSTA)")
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

# Leer checkpoint si existe
start_index = 0
if os.path.exists(CHECKPOINT_FILE):
    with open(CHECKPOINT_FILE, 'r') as f:
        start_index = int(f.read().strip())
    print(f"🔄 Reanudando desde documento {start_index:,}")

# Actualizar en Supabase
print(f"\n🔄 Actualizando desde {start_index:,} hasta {len(docs):,}...")

actualizados = 0
errores = 0
start_time = time.time()

for i in range(start_index, len(docs)):
    doc = docs[i]
    doc_id = doc['id']
    url_html = doc['url_html']
    url_txt = doc['url_txt']
    
    max_reintentos = 3
    exito = False
    
    for intento in range(max_reintentos):
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
                if response.status in [200, 204]:
                    actualizados += 1
                    exito = True
                    break
                else:
                    if intento == max_reintentos - 1:
                        errores += 1
        except Exception as e:
            if intento == max_reintentos - 1:
                errores += 1
            time.sleep(1)  # Esperar 1 segundo antes de reintentar
    
    # Guardar checkpoint cada 1000
    if (i + 1) % 1000 == 0:
        with open(CHECKPOINT_FILE, 'w') as f:
            f.write(str(i + 1))
        
        elapsed = time.time() - start_time
        rate = (i + 1 - start_index) / elapsed
        restantes = len(docs) - (i + 1)
        eta_segundos = restantes / rate if rate > 0 else 0
        
        print(f"   {i+1:,}/{len(docs):,} | "
              f"✅ {actualizados:,} | ❌ {errores} | "
              f"{rate:.1f}/s | ETA: {eta_segundos/60:.1f}min")

# Checkpoint final
print(f"\n✅ Actualización completada")
print(f"   Actualizados: {actualizados:,}")
print(f"   Errores: {errores}")

# Eliminar checkpoint al terminar
if os.path.exists(CHECKPOINT_FILE):
    os.remove(CHECKPOINT_FILE)
    print(f"   🗑️  Checkpoint eliminado")

print("\n" + "=" * 80 + "\n")
