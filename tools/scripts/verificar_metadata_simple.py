#!/usr/bin/env python3
"""
Script simple para verificar cuántos documentos hay en Supabase
No requiere R2 ni Google Drive
"""

import os
from supabase import create_client, Client
from dotenv import load_dotenv

# Cargar variables de entorno
load_dotenv()

# Conectar a Supabase
SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_KEY = os.getenv('SUPABASE_ANON_KEY')

if not SUPABASE_URL or not SUPABASE_KEY:
    print("❌ Error: Faltan variables SUPABASE_URL o SUPABASE_ANON_KEY en .env")
    exit(1)

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

print("\n🔍 VERIFICANDO SUPABASE...")
print("=" * 70)

# Total de documentos
try:
    response = supabase.table('documentos').select('id', count='exact').limit(1).execute()
    total = response.count
    print(f"\n📊 TOTAL DE DOCUMENTOS EN SUPABASE: {total:,}\n")
except Exception as e:
    print(f"❌ Error consultando total: {e}")
    exit(1)

# Definir categorías esperadas
categorias = [
    ('sentencia', 'constitucional', 'Sentencias Constitucionales', 51316),
    ('sentencia', 'penal', 'Sentencias Penales', 16604),
    ('sentencia', 'sustanciacion', 'Sustanciación Constitucional', 986),
    ('jurisprudencia', 'penal', 'Jurisprudencia Penal', 3714),
    ('jurisprudencia', 'constitucional', 'Jurisprudencia Constitucional', 725),
    ('resoluciones', 'plena', 'Resoluciones Sala Plena', 366),
]

print("📋 DESGLOSE POR TIPO Y SALA:")
print("=" * 70)

total_encontrado = 0
faltantes_total = 0

for tipo, sala, nombre, esperado in categorias:
    try:
        response = supabase.table('documentos').select('id', count='exact').eq('tipo', tipo).eq('sala', sala).limit(1).execute()
        encontrado = response.count
        total_encontrado += encontrado
        faltante = esperado - encontrado
        faltantes_total += faltante
        
        status = "✅" if encontrado == esperado else "❌"
        print(f"{status} {nombre:35} {encontrado:>7,} / {esperado:>7,}  ({faltante:>6,} faltantes)")
    except Exception as e:
        print(f"❌ {nombre:35} ERROR: {e}")

print("=" * 70)
print(f"   {'TOTAL':35} {total_encontrado:>7,} / {sum([c[3] for c in categorias]):>7,}  ({faltantes_total:>6,} faltantes)")
print()

# Resumen
print("=" * 70)
print("📈 RESUMEN:")
print("=" * 70)
esperado_total = 73345
print(f"   Esperado en Drive:               {esperado_total:>10,}")
print(f"   Encontrado en Supabase:          {total:>10,}")
print(f"   Faltantes:                       {esperado_total - total:>10,}")
print(f"   % Completado:                    {(total/esperado_total*100):>9.1f}%")
print()

if faltantes_total > 0:
    print("⚠️  ACCIÓN REQUERIDA:")
    print("   1. Procesar los HTMLs faltantes con tu pipeline")
    print("   2. Especialmente las 366 resoluciones de Sala_Plena")
    print()

print("💡 PARA VER IDS ESPECÍFICOS FALTANTES:")
print("   Ejecuta el notebook de Colab: verificar_faltantes_colab_final.ipynb")
print()
