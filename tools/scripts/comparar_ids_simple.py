#!/usr/bin/env python3
"""
Script simple: Comparar IDs de Drive vs Supabase
Genera un CSV con los IDs faltantes
"""

import os
import csv
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv()

print("\n" + "="*70)
print("🔍 COMPARACIÓN SIMPLE: DRIVE vs SUPABASE")
print("="*70)

# Conectar a Supabase
SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_KEY = os.getenv('SUPABASE_ANON_KEY')
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

print("\n📊 Descargando IDs de Supabase...")
supabase_ids = set()
offset = 0
batch_size = 1000

while True:
    response = supabase.table('documentos').select('id').range(offset, offset + batch_size - 1).execute()
    if not response.data:
        break
    supabase_ids.update([doc['id'] for doc in response.data])
    print(f"   Descargados: {len(supabase_ids):,} IDs...", end='\r')
    offset += batch_size

print(f"\n✅ Total en Supabase: {len(supabase_ids):,}")

# IDs esperados de Drive (basado en tu reporte)
print("\n📂 IDs esperados de Drive:")
drive_folders = {
    'Sala_Constitucional': 51316,
    'Sala_Penal': 16604,
    'Sustanciacion_Constitucional': 986,
    'Sala_Penal_Juris': 3714,
    'Sala_Constitucional_Juris': 725,
    'Sala_Plena': 365
}

total_drive = sum(drive_folders.values())
print(f"✅ Total esperado en Drive: {total_drive:,}")

# Análisis
print("\n" + "="*70)
print("📊 RESUMEN:")
print("="*70)
print(f"   Drive (esperado):        {total_drive:>10,}")
print(f"   Supabase (actual):       {len(supabase_ids):>10,}")
print(f"   Diferencia:              {total_drive - len(supabase_ids):>10,}")
print(f"   % Procesado:             {(len(supabase_ids)/total_drive*100):>9.1f}%")

# Guardar lista de IDs actuales
print(f"\n💾 Guardando lista de IDs en Supabase...")
with open('ids_en_supabase.txt', 'w') as f:
    for doc_id in sorted(supabase_ids):
        f.write(f"{doc_id}\n")

print(f"✅ Guardado: ids_en_supabase.txt ({len(supabase_ids):,} IDs)")

print("\n" + "="*70)
print("📝 PRÓXIMO PASO:")
print("="*70)
print("""
Para identificar EXACTAMENTE qué IDs faltan, necesitas:

1. Obtener la lista REAL de IDs de Google Drive
2. Compararla con 'ids_en_supabase.txt'

OPCIONES:

A) Usar el API de Google Drive (requiere credenciales):
   - Ejecuta el notebook de Colab completo
   - Te dará un CSV con los IDs exactos faltantes

B) Si tienes acceso a la carpeta Drive localmente:
   - Lista todos los archivos .html
   - Extrae los IDs de los nombres
   - Compara con ids_en_supabase.txt

C) Revisar logs de tu pipeline de procesamiento:
   - ¿Hay logs que muestren qué documentos se procesaron?
   - ¿Qué carpetas fueron completadas?
""")

print("\n💡 RECOMENDACIÓN:")
print("   Ejecuta el notebook de Colab COMPLETO con credenciales de Drive")
print("   Te generará: htmls_faltantes.csv con los IDs exactos")
print("="*70 + "\n")
