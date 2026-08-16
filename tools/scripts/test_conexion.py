#!/usr/bin/env python3
import os
from dotenv import load_dotenv

load_dotenv()

print("Probando conexión a Supabase...")

try:
    from supabase import create_client
    url = os.getenv('SUPABASE_URL')
    key = os.getenv('SUPABASE_ANON_KEY')
    
    print(f"URL: {url}")
    print(f"Key: {key[:20]}...")
    
    supabase = create_client(url, key)
    response = supabase.table('documentos').select('id', count='exact').limit(1).execute()
    
    print(f"\n✅ CONEXIÓN EXITOSA!")
    print(f"Total documentos: {response.count:,}")
    
except Exception as e:
    print(f"\n❌ ERROR: {e}")
