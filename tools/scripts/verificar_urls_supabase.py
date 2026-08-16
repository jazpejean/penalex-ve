#!/usr/bin/env python3
import os
import urllib.request
import json
from dotenv import load_dotenv

load_dotenv()

SUPABASE_URL = os.environ.get('SUPABASE_URL')
SUPABASE_KEY = os.environ.get('SUPABASE_SERVICE_KEY')

print("=" * 80)
print("📊 VERIFICACIÓN DE URLs EN SUPABASE")
print("=" * 80)

# Total de documentos
url = f"{SUPABASE_URL}/rest/v1/documentos?select=id&limit=1"
headers = {
    'apikey': SUPABASE_KEY,
    'Authorization': f'Bearer {SUPABASE_KEY}',
    'Range': '0-0',
    'Prefer': 'count=exact'
}

req = urllib.request.Request(url, headers=headers)
with urllib.request.urlopen(req, timeout=15) as response:
    content_range = response.headers.get('Content-Range')
    total = int(content_range.split('/')[1])
    print(f"\n✅ Total documentos en Supabase: {total:,}")

# Documentos CON url_html
url_con = f"{SUPABASE_URL}/rest/v1/documentos?select=id&url_html=not.is.null&limit=1"
req_con = urllib.request.Request(url_con, headers=headers)
with urllib.request.urlopen(req_con, timeout=15) as response:
    content_range = response.headers.get('Content-Range')
    con_html = int(content_range.split('/')[1])
    print(f"✅ Documentos CON url_html: {con_html:,}")

# Documentos CON url_txt
url_txt = f"{SUPABASE_URL}/rest/v1/documentos?select=id&url_txt=not.is.null&limit=1"
req_txt = urllib.request.Request(url_txt, headers=headers)
with urllib.request.urlopen(req_txt, timeout=15) as response:
    content_range = response.headers.get('Content-Range')
    con_txt = int(content_range.split('/')[1])
    print(f"✅ Documentos CON url_txt: {con_txt:,}")

# Documentos SIN url_html
sin_html = total - con_html
print(f"\n⚠️  Documentos SIN url_html: {sin_html:,}")

# Documentos SIN url_txt
sin_txt = total - con_txt
print(f"⚠️  Documentos SIN url_txt: {sin_txt:,}")

# Porcentajes
print(f"\n📊 Cobertura:")
print(f"   url_html: {(con_html/total*100):.2f}%")
print(f"   url_txt:  {(con_txt/total*100):.2f}%")

print("\n" + "=" * 80)
