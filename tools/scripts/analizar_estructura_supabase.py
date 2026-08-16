#!/usr/bin/env python3
"""
Analizar estructura de la tabla documentos en Supabase
para identificar qué campo usar para comparar con Drive
"""

import os
from supabase import create_client, Client
from dotenv import load_dotenv
import json

load_dotenv()

print("\n" + "="*70)
print("🔍 ANALIZANDO ESTRUCTURA DE SUPABASE")
print("="*70)

# Conectar
SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_KEY = os.getenv('SUPABASE_ANON_KEY')
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# Obtener algunos documentos de muestra
print("\n📊 Obteniendo 5 documentos de muestra...\n")

response = supabase.table('documentos').select('*').limit(5).execute()

if response.data:
    print("✅ Campos en la tabla 'documentos':")
    print("="*70)
    
    # Mostrar campos del primer documento
    primer_doc = response.data[0]
    campos = list(primer_doc.keys())
    
    for campo in campos:
        valor = primer_doc[campo]
        tipo = type(valor).__name__
        longitud = len(str(valor)) if valor else 0
        print(f"  • {campo:20} ({tipo:10}) - Ejemplo: {str(valor)[:50]}")
    
    print("\n" + "="*70)
    print("📋 CAMPOS CLAVE PARA COMPARAR:")
    print("="*70)
    
    # Identificar posibles campos únicos
    posibles_claves = []
    
    if 'id' in campos:
        print(f"  ✓ id: {primer_doc['id'][:50]}")
        posibles_claves.append('id')
    
    if 'url_tsj' in campos and primer_doc.get('url_tsj'):
        print(f"  ✓ url_tsj: {str(primer_doc['url_tsj'])[:60]}")
        posibles_claves.append('url_tsj')
    
    if 'num_sentencia' in campos and primer_doc.get('num_sentencia'):
        print(f"  ✓ num_sentencia: {primer_doc['num_sentencia']}")
        posibles_claves.append('num_sentencia')
    
    if 'expediente' in campos and primer_doc.get('expediente'):
        print(f"  ✓ expediente: {primer_doc['expediente']}")
        posibles_claves.append('expediente')
    
    print("\n" + "="*70)
    print("💡 ANÁLISIS:")
    print("="*70)
    print("""
El campo 'id' en Supabase probablemente es:
  - El ID del archivo HTML en Google Drive, O
  - Un ID generado de alguna otra forma (hash, nombre, etc.)

Para identificar qué documentos faltan, necesitas:
  1. Ver si el 'id' de Supabase coincide con el 'id' de Drive
  2. O usar otro campo único como 'url_tsj' para comparar
  
Revisa el CSV descargado:
  - ¿El campo 'id' coincide entre Drive y Supabase?
  - ¿O los nombres de archivo tienen el ID embebido?
""")
    
    print("\n" + "="*70)
    print("📄 DOCUMENTO COMPLETO DE EJEMPLO:")
    print("="*70)
    print(json.dumps(primer_doc, indent=2, ensure_ascii=False)[:1000])
    
else:
    print("❌ No se pudieron obtener documentos")

print("\n" + "="*70)
