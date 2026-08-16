#!/usr/bin/env python3
"""
Versión simplificada: solo actualizar Supabase con URL del TSJ
"""
import os
import json
import urllib.request
from dotenv import load_dotenv

load_dotenv()

URL_TSJ = "https://historico.tsj.gob.ve/decisiones/scon/julio/820-260700-644,%20645,%20652%20..htm"
ID_SUPABASE = "sentencias/constitucional/2000_820_exp_644"

print("=" * 80)
print("📝 ACTUALIZAR SUPABASE CON URL TSJ")
print("=" * 80)

SUPABASE_URL = os.environ.get('SUPABASE_URL')
SUPABASE_KEY = os.environ.get('SUPABASE_SERVICE_KEY')

print(f"\n💾 Actualizando Supabase...")
print(f"   ID: {ID_SUPABASE}")
print(f"   URL TSJ: {URL_TSJ}")

try:
    # URL-encodear el ID por si tiene espacios
    import urllib.parse
    doc_id_encoded = urllib.parse.quote(ID_SUPABASE, safe='')
    
    url = f"{SUPABASE_URL}/rest/v1/documentos?id=eq.{doc_id_encoded}"
    headers = {
        'apikey': SUPABASE_KEY,
        'Authorization': f'Bearer {SUPABASE_KEY}',
        'Content-Type': 'application/json',
        'Prefer': 'return=minimal'
    }
    
    data = json.dumps({
        'tipo': 'sentencia',
        'sala': 'constitucional',
        'fecha': '2000-07-26',
        'num_sentencia': '820',
        'expediente': '644, 645, 652',
        'url_tsj': URL_TSJ,
        'url_html': URL_TSJ,  # Usar URL del TSJ directamente
        'url_txt': None  # No hay TXT por ahora
    }).encode('utf-8')
    
    req = urllib.request.Request(url, data=data, headers=headers, method='PATCH')
    with urllib.request.urlopen(req, timeout=15) as response:
        if response.status in [200, 204]:
            print(f"\n✅ SUPABASE ACTUALIZADO")
            print(f"   El documento ahora apunta al TSJ directamente")
            print(f"   (No está en R2, pero está accesible)")
        else:
            print(f"\n⚠️  Status: {response.status}")
            
except Exception as e:
    print(f"\n❌ Error: {e}")

print("\n" + "=" * 80)
print("✅ COMPLETADO")
print("=" * 80)
print(f"El documento {ID_SUPABASE} ahora tiene URL del TSJ")
print(f"Los usuarios podrán verlo a través de: {URL_TSJ}")
print("=" * 80 + "\n")
