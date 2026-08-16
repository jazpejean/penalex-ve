#!/usr/bin/env python3
"""
Script para identificar qué documentos faltan en Supabase comparando con Drive
"""

import os
from supabase import create_client
from dotenv import load_dotenv

# Cargar variables de entorno
load_dotenv()

SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_KEY = os.getenv('SUPABASE_ANON_KEY')

supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

print("🔍 ANÁLISIS DE DOCUMENTOS EN SUPABASE\n")
print("=" * 60)

# 1. Contar total de documentos
response = supabase.table('documentos').select('id', count='exact').execute()
total = response.count
print(f"\n📊 TOTAL DE DOCUMENTOS: {total:,}")

# 2. Contar por TIPO
print(f"\n📁 POR TIPO:")
print("-" * 60)
response = supabase.rpc('count_by_tipo').execute()
# Si la función no existe, hacer query manual
try:
    response = supabase.table('documentos').select('tipo').execute()
    tipos = {}
    for doc in response.data:
        tipo = doc.get('tipo', 'sin_tipo')
        tipos[tipo] = tipos.get(tipo, 0) + 1
    
    for tipo, count in sorted(tipos.items(), key=lambda x: x[1], reverse=True):
        print(f"  {tipo:30} {count:>8,}")
except Exception as e:
    print(f"  Error: {e}")

# 3. Contar por SALA
print(f"\n🏛️  POR SALA:")
print("-" * 60)
try:
    response = supabase.table('documentos').select('sala').execute()
    salas = {}
    for doc in response.data:
        sala = doc.get('sala', 'sin_sala')
        salas[sala] = salas.get(sala, 0) + 1
    
    for sala, count in sorted(salas.items(), key=lambda x: x[1], reverse=True):
        print(f"  {sala:30} {count:>8,}")
except Exception as e:
    print(f"  Error: {e}")

# 4. Contar por TIPO + SALA
print(f"\n📋 POR TIPO Y SALA:")
print("-" * 60)
try:
    response = supabase.table('documentos').select('tipo, sala').execute()
    combinaciones = {}
    for doc in response.data:
        tipo = doc.get('tipo', 'sin_tipo')
        sala = doc.get('sala', 'sin_sala')
        key = f"{tipo} / {sala}"
        combinaciones[key] = combinaciones.get(key, 0) + 1
    
    for combo, count in sorted(combinaciones.items(), key=lambda x: x[1], reverse=True):
        print(f"  {combo:50} {count:>8,}")
except Exception as e:
    print(f"  Error: {e}")

# 5. Comparar con lo esperado
print(f"\n\n📊 COMPARACIÓN CON LO ESPERADO:")
print("=" * 60)

ESPERADO = {
    'sentencia/constitucional': 51316,
    'sentencia/penal': 16604,
    'sentencia/sustanciacion': 986,
    'jurisprudencia/penal': 3714,
    'jurisprudencia/constitucional': 725,
    'resolucion/?': 366,  # Resoluciones (sala desconocida)
}

print(f"\n{'Tipo/Sala':<50} {'Esperado':>10} {'Real':>10} {'Diferencia':>12}")
print("-" * 85)

total_esperado = sum(ESPERADO.values())
diferencia_total = total - total_esperado

for key, esperado in ESPERADO.items():
    real = combinaciones.get(key, 0)
    diff = real - esperado
    simbolo = "✅" if diff >= 0 else "❌"
    print(f"{simbolo} {key:<47} {esperado:>10,} {real:>10,} {diff:>+12,}")

print("-" * 85)
print(f"{'TOTAL':<50} {total_esperado:>10,} {total:>10,} {diferencia_total:>+12,}")

# 6. Resumen
print(f"\n\n🎯 RESUMEN:")
print("=" * 60)
print(f"Total esperado (conocido):  {total_esperado:,}")
print(f"Total en Supabase:          {total:,}")
print(f"Diferencia:                 {diferencia_total:+,}")

if diferencia_total < 0:
    print(f"\n⚠️  FALTAN {abs(diferencia_total):,} documentos por cargar")
    print("\nPosibles causas:")
    print("  1. Carpetas de Drive no procesadas")
    print("  2. Errores durante la carga")
    print("  3. Documentos duplicados que se saltaron")
elif diferencia_total > 0:
    print(f"\n✅ HAY {diferencia_total:,} documentos EXTRA en Supabase")
    print("  (Puede ser normal si hay otras fuentes)")
else:
    print(f"\n✅ Todos los documentos conocidos están cargados")

print("\n" + "=" * 60)
