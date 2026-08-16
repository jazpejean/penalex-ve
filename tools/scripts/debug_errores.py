#!/usr/bin/env python3
"""
Debug: Ver qué errores están ocurriendo
"""
import os
import csv
import json
import re
import urllib.request
from dotenv import load_dotenv

load_dotenv()

SUPABASE_URL = os.environ.get('SUPABASE_URL')
SUPABASE_KEY = os.environ.get('SUPABASE_SERVICE_KEY')

def normalizar_id(text):
    if not text:
        return ''
    text = re.sub(r'\s+', '', text)
    text = text.lower()
    return text

print("=" * 80)
print("🔍 DEBUG: Analizar errores de actualización")
print("=" * 80)

# Cargar índice
indice_r2_normalizado = {}
with open('indice_completo.csv', 'r', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    for row in reader:
        nombre = row['id'].split('/')[-1]
        nombre_normalizado = normalizar_id(nombre)
        if nombre_normalizado not in indice_r2_normalizado:
            indice_r2_normalizado[nombre_normalizado] = {
                'url_html': row['url_html'],
                'url_txt': row['url_txt'],
                'id_original': row['id']
            }

# Obtener IDs sin URL
url = f"{SUPABASE_URL}/rest/v1/documentos?select=id,url_html,url_txt&or=(url_html.is.null,url_txt.is.null)&limit=10"
headers = {
    'apikey': SUPABASE_KEY,
    'Authorization': f'Bearer {SUPABASE_KEY}'
}

req = urllib.request.Request(url, headers=headers)
with urllib.request.urlopen(req, timeout=15) as response:
    docs = json.loads(response.read().decode('utf-8'))

print(f"\n📋 Analizando primeros {len(docs)} documentos sin URL...\n")

for i, doc in enumerate(docs, 1):
    doc_id = doc['id']
    doc_id_norm = normalizar_id(doc_id)
    
    print(f"\n{i}. ID Supabase: {doc_id}")
    print(f"   ID normalizado: {doc_id_norm}")
    print(f"   url_html actual: {doc.get('url_html')}")
    print(f"   url_txt actual: {doc.get('url_txt')}")
    
    if doc_id_norm in indice_r2_normalizado:
        urls = indice_r2_normalizado[doc_id_norm]
        print(f"   ✅ Encontrado en R2:")
        print(f"      ID R2: {urls['id_original']}")
        print(f"      URL HTML: {urls['url_html']}")
        print(f"      URL TXT: {urls['url_txt']}")
        
        # Intentar actualizar
        try:
            update_url = f"{SUPABASE_URL}/rest/v1/documentos?id=eq.{doc_id}"
            update_headers = {
                'apikey': SUPABASE_KEY,
                'Authorization': f'Bearer {SUPABASE_KEY}',
                'Content-Type': 'application/json',
                'Prefer': 'return=minimal'
            }
            
            data = json.dumps({
                'url_html': urls['url_html'],
                'url_txt': urls['url_txt']
            }).encode('utf-8')
            
            update_req = urllib.request.Request(update_url, data=data, headers=update_headers, method='PATCH')
            with urllib.request.urlopen(update_req, timeout=15) as update_response:
                if update_response.status in [200, 204]:
                    print(f"   ✅ ACTUALIZADO correctamente")
                else:
                    print(f"   ❌ Error HTTP {update_response.status}")
        except Exception as e:
            print(f"   ❌ ERROR: {e}")
    else:
        print(f"   ⚠️  NO encontrado en R2")

print("\n" + "=" * 80)
