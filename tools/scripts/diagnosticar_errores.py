#!/usr/bin/env python3
"""
Diagnosticar por qué fallan esos 61 documentos
"""
import os
import csv
import json
import urllib.request
from dotenv import load_dotenv

load_dotenv()

SUPABASE_URL = os.environ.get('SUPABASE_URL')
SUPABASE_KEY = os.environ.get('SUPABASE_SERVICE_KEY')

print("=" * 80)
print("🔍 DIAGNÓSTICO DE ERRORES")
print("=" * 80)

# 1. Obtener documentos sin URL
print("\n📥 Obteniendo documentos sin URLs...")
url = f"{SUPABASE_URL}/rest/v1/documentos?select=id,url_html,url_txt&url_html=is.null&limit=150"
headers = {
    'apikey': SUPABASE_KEY,
    'Authorization': f'Bearer {SUPABASE_KEY}'
}

req = urllib.request.Request(url, headers=headers)
with urllib.request.urlopen(req, timeout=15) as response:
    docs_sin_url = json.loads(response.read().decode('utf-8'))

print(f"✅ {len(docs_sin_url)} documentos sin url_html")

# 2. Cargar índice R2
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

# 3. Analizar cada documento sin URL
print("\n🔍 Analizando documentos...")
problemas = []

for i, doc in enumerate(docs_sin_url[:10], 1):  # Solo primeros 10 para diagnóstico
    doc_id = doc['id']
    print(f"\n[{i}/10] ID: {doc_id}")
    
    # Verificar si existe en índice
    if doc_id in indice_r2:
        print(f"   ✅ Existe en R2")
        print(f"   📄 HTML: {indice_r2[doc_id]['url_html'][:80]}...")
        
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
                'url_html': indice_r2[doc_id]['url_html'],
                'url_txt': indice_r2[doc_id]['url_txt']
            }).encode('utf-8')
            
            req = urllib.request.Request(update_url, data=data, headers=update_headers, method='PATCH')
            with urllib.request.urlopen(req, timeout=15) as response:
                if response.status in [200, 204]:
                    print(f"   ✅ ACTUALIZADO exitosamente")
                else:
                    print(f"   ❌ Error HTTP: {response.status}")
                    problemas.append({
                        'id': doc_id,
                        'error': f'HTTP {response.status}'
                    })
        except Exception as e:
            print(f"   ❌ Error: {str(e)[:100]}")
            problemas.append({
                'id': doc_id,
                'error': str(e)[:100]
            })
    else:
        print(f"   ⚠️  NO existe en índice R2")
        problemas.append({
            'id': doc_id,
            'error': 'No existe en R2'
        })

print("\n" + "=" * 80)
print(f"📊 Problemas detectados: {len(problemas)}")
for p in problemas:
    print(f"   • {p['id']}: {p['error']}")
print("=" * 80)
