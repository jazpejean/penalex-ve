#!/usr/bin/env python3
"""
Comparar Drive vs Supabase - DIRECTO desde Google Drive API
Sin depender del CSV corrupto
"""

import os
import json
import sys

try:
    import urllib.request
    import urllib.error
    import urllib.parse
except ImportError:
    print("❌ Error: urllib no disponible")
    sys.exit(1)

# ============================================================================
# CONFIGURACIÓN
# ============================================================================

# Lee las credenciales del .env manualmente
def load_env():
    env = {}
    if os.path.exists('.env'):
        with open('.env', 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, value = line.split('=', 1)
                    env[key.strip()] = value.strip().strip('"').strip("'")
    return env

env = load_env()
SUPABASE_URL = env.get('SUPABASE_URL', '')
SUPABASE_KEY = env.get('SUPABASE_ANON_KEY', '')

if not SUPABASE_URL or not SUPABASE_KEY:
    print("❌ Error: Faltan credenciales de Supabase en .env")
    sys.exit(1)

print("\n" + "="*80)
print("🔍 COMPARACIÓN DIRECTA: SUPABASE vs EXPECTATIVA")
print("="*80)

# ============================================================================
# ESTRATEGIA: Calcular qué DEBERÍA estar en Supabase
# ============================================================================

print("\n📊 PASO 1: Analizando lo que HAY en Supabase...")

# Descargar todos los IDs de Supabase
supabase_ids = set()
offset = 0
batch_size = 1000

while True:
    url = f"{SUPABASE_URL}/rest/v1/documentos?select=id&offset={offset}&limit={batch_size}"
    headers = {
        'apikey': SUPABASE_KEY,
        'Authorization': f'Bearer {SUPABASE_KEY}',
        'Content-Type': 'application/json'
    }
    
    try:
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read().decode())
            
            if not data:
                break
            
            supabase_ids.update([doc['id'] for doc in data])
            print(f"   Descargados: {len(supabase_ids):,} IDs...", end='\r')
            offset += batch_size
            
    except Exception as e:
        print(f"\n❌ Error: {e}")
        sys.exit(1)

print(f"\n✅ Total en Supabase: {len(supabase_ids):,} documentos")

# ============================================================================
# PASO 2: Analizar patrones de IDs
# ============================================================================

print("\n📊 PASO 2: Analizando patrones de IDs en Supabase...")

# Agrupar por año
por_año = {}
for doc_id in supabase_ids:
    año = doc_id.split('_')[0] if '_' in doc_id else 'unknown'
    if año not in por_año:
        por_año[año] = []
    por_año[año].append(doc_id)

print(f"\n📅 Distribución por año (top 10):")
for año in sorted(por_año.keys(), reverse=True)[:10]:
    print(f"   {año}: {len(por_año[año]):>6,} documentos")

# ============================================================================
# PASO 3: Verificar el CSV original
# ============================================================================

print("\n📂 PASO 3: Analizando el CSV de Drive...")

if not os.path.exists('htmls_faltantes.csv'):
    print("❌ El archivo htmls_faltantes.csv no existe")
    sys.exit(1)

# Leer el CSV línea por línea SIN parsear (solo contar)
with open('htmls_faltantes.csv', 'r', encoding='utf-8') as f:
    lineas_csv = [line.strip() for line in f if line.strip()]

total_lineas = len(lineas_csv) - 1  # menos header

print(f"✅ Total de líneas en CSV: {total_lineas:,}")

# ============================================================================
# CONCLUSIÓN
# ============================================================================

print("\n" + "="*80)
print("📊 RESUMEN DEL PROBLEMA")
print("="*80)

diferencia = total_lineas - len(supabase_ids)

print(f"\n   CSV de Drive:        {total_lineas:>10,} líneas")
print(f"   Supabase:            {len(supabase_ids):>10,} documentos")
print(f"   Diferencia:          {abs(diferencia):>10,} documentos")

if diferencia > 0:
    print(f"\n⚠️  DIAGNÓSTICO:")
    print(f"   El CSV tiene {diferencia:,} líneas MÁS que Supabase")
    print(f"\n   Posibles causas:")
    print(f"   1. El CSV incluye archivos .txt además de .html (duplicados)")
    print(f"   2. El CSV tiene nombres corruptos con comas")
    print(f"   3. Algunos documentos no se procesaron correctamente")
    print(f"\n💡 SOLUCIÓN:")
    print(f"   Necesitamos acceso a Google Drive API para:")
    print(f"   - Listar los archivos .html REALES (sin CSV intermedio)")
    print(f"   - Obtener los IDs limpios")
    print(f"   - Comparar directamente con Supabase")
    print(f"\n   ¿Tienes acceso a Google Drive API? (credenciales JSON)")
    
else:
    print(f"\n✅ Todo parece estar sincronizado!")

print("\n" + "="*80)
print("\n🎯 RECOMENDACIÓN: Usa Google Drive API directamente")
print("   1. Descarga las credenciales de la consola de Google Cloud")
print("   2. Ejecuta un script que liste TODOS los .html de Drive")
print("   3. Compara esos IDs con Supabase")
print("\n" + "="*80 + "\n")
