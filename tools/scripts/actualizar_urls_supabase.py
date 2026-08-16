#!/usr/bin/env python3
"""
Actualizar URLs de HTML y TXT en Supabase desde indice_completo.csv
"""
import os
import csv
import sys
from dotenv import load_dotenv

load_dotenv()

SUPABASE_URL = os.environ.get('SUPABASE_URL')
SUPABASE_KEY = os.environ.get('SUPABASE_ANON_KEY')

if not SUPABASE_URL or not SUPABASE_KEY:
    print("❌ Faltan SUPABASE_URL o SUPABASE_ANON_KEY en .env")
    sys.exit(1)

print("=" * 80)
print("📊 ACTUALIZAR URLs EN SUPABASE")
print("=" * 80)

# Leer índice
print("\n📂 Leyendo indice_completo.csv...")
if not os.path.exists('indice_completo.csv'):
    print("❌ No existe indice_completo.csv")
    print("   Descárgalo de GitHub Actions Artifacts primero")
    sys.exit(1)

docs = []
with open('indice_completo.csv', 'r', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    for row in reader:
        docs.append(row)

print(f"✅ {len(docs):,} documentos en el índice")

# Actualizar en Supabase (en lotes de 1000)
print("\n🔄 Actualizando Supabase...")

import urllib.request
import json

BATCH_SIZE = 1000
actualizados = 0
errores = 0

for i in range(0, len(docs), BATCH_SIZE):
    batch = docs[i:i+BATCH_SIZE]
    
    for doc in batch:
        doc_id = doc['id']
        url_html = doc['url_html']
        url_txt = doc['url_txt']
        
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
            with urllib.request.urlopen(req, timeout=10) as response:
                if response.status in [200, 204]:
                    actualizados += 1
                else:
                    errores += 1
        except Exception as e:
            errores += 1
    
    print(f"   {actualizados:,}/{len(docs):,} actualizados, {errores} errores", end='\r')

print(f"\n\n✅ Actualización completada")
print(f"   Actualizados: {actualizados:,}")
print(f"   Errores: {errores}")
print("\n" + "=" * 80 + "\n")
