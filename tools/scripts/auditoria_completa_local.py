#!/usr/bin/env python3
"""
Auditoría completa: Supabase vs Cloudflare R2
Identifica qué documentos faltan o están incompletos
"""

import os
import sys
from dotenv import load_dotenv

# Cargar variables de entorno
load_dotenv()

# Verificar dependencias
try:
    from supabase import create_client, Client
    import boto3
    from botocore.config import Config
except ImportError:
    print("❌ Error: Faltan dependencias.")
    print("\n📦 Instalando dependencias necesarias...")
    os.system("pip3 install supabase boto3 python-dotenv -q")
    print("✅ Dependencias instaladas. Ejecuta el script de nuevo.\n")
    sys.exit(0)

# ============================================================================
# CONFIGURACIÓN
# ============================================================================

SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_KEY = os.getenv('SUPABASE_ANON_KEY')
R2_ACCOUNT_ID = os.getenv('R2_ACCOUNT_ID')
R2_ACCESS_KEY = os.getenv('R2_ACCESS_KEY_ID')
R2_SECRET_KEY = os.getenv('R2_SECRET_ACCESS_KEY')
R2_BUCKET = os.getenv('R2_BUCKET_NAME', 'penalex-assets')

# Validar configuración
if not all([SUPABASE_URL, SUPABASE_KEY]):
    print("❌ Error: Faltan credenciales de Supabase en .env")
    sys.exit(1)

if not all([R2_ACCOUNT_ID, R2_ACCESS_KEY, R2_SECRET_KEY]):
    print("⚠️  Advertencia: Faltan credenciales de Cloudflare R2 en .env")
    print("\n📝 Necesitas agregar al archivo .env:")
    print("   R2_ACCOUNT_ID=tu_account_id")
    print("   R2_ACCESS_KEY_ID=tu_access_key")
    print("   R2_SECRET_ACCESS_KEY=tu_secret_key")
    print("\n💡 ¿Dónde conseguir las credenciales de R2?")
    print("   1. Ve a: https://dash.cloudflare.com/")
    print("   2. Selecciona tu cuenta")
    print("   3. R2 → Manage R2 API Tokens")
    print("   4. Create API Token con permisos de lectura")
    print("\n⏭️  Por ahora, solo analizaré Supabase...\n")
    R2_ENABLED = False
else:
    R2_ENABLED = True

# ============================================================================
# CONEXIONES
# ============================================================================

print("\n🔗 CONECTANDO A SERVICIOS...")
print("=" * 80)

# Supabase
try:
    supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
    print("✅ Supabase conectado")
except Exception as e:
    print(f"❌ Error conectando a Supabase: {e}")
    sys.exit(1)

# Cloudflare R2
if R2_ENABLED:
    try:
        r2_endpoint = f"https://{R2_ACCOUNT_ID}.r2.cloudflarestorage.com"
        r2_client = boto3.client(
            's3',
            endpoint_url=r2_endpoint,
            aws_access_key_id=R2_ACCESS_KEY,
            aws_secret_access_key=R2_SECRET_KEY,
            config=Config(signature_version='s3v4')
        )
        # Test de conexión
        r2_client.head_bucket(Bucket=R2_BUCKET)
        print(f"✅ Cloudflare R2 conectado (bucket: {R2_BUCKET})")
    except Exception as e:
        print(f"❌ Error conectando a R2: {e}")
        print("   Verifica tus credenciales en .env")
        R2_ENABLED = False

# ============================================================================
# PASO 1: ANALIZAR SUPABASE
# ============================================================================

print("\n📊 PASO 1: ANALIZANDO SUPABASE...")
print("=" * 80)

try:
    # Total
    response = supabase.table('documentos').select('id', count='exact').limit(1).execute()
    total_supabase = response.count
    print(f"\n📈 Total documentos en Supabase: {total_supabase:,}")
    
    # Descargar todos los IDs (en batches)
    print("\n⏳ Descargando IDs de Supabase...")
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
    
    print(f"\n✅ Total IDs descargados: {len(supabase_ids):,}")
    
except Exception as e:
    print(f"❌ Error consultando Supabase: {e}")
    sys.exit(1)

# ============================================================================
# PASO 2: ANALIZAR CLOUDFLARE R2
# ============================================================================

if R2_ENABLED:
    print("\n📦 PASO 2: ANALIZANDO CLOUDFLARE R2...")
    print("=" * 80)
    
    try:
        r2_htmls = set()
        r2_txts = set()
        r2_otros = []
        
        print("\n⏳ Escaneando archivos en R2...")
        paginator = r2_client.get_paginator('list_objects_v2')
        pages = paginator.paginate(Bucket=R2_BUCKET)
        
        total_archivos = 0
        for page in pages:
            if 'Contents' in page:
                for obj in page['Contents']:
                    key = obj['Key']
                    total_archivos += 1
                    
                    # Extraer ID del archivo (sin extensión)
                    file_name = key.split('/')[-1]
                    
                    if key.endswith('.html'):
                        doc_id = file_name.replace('.html', '')
                        r2_htmls.add(doc_id)
                    elif key.endswith('.txt'):
                        doc_id = file_name.replace('.txt', '')
                        r2_txts.add(doc_id)
                    else:
                        r2_otros.append(key)
                    
                    if total_archivos % 1000 == 0:
                        print(f"   Procesados: {total_archivos:,} archivos...", end='\r')
        
        r2_completos = r2_htmls & r2_txts
        
        print(f"\n\n✅ Total archivos en R2: {total_archivos:,}")
        print(f"   📄 HTMLs:             {len(r2_htmls):,}")
        print(f"   📝 TXTs:              {len(r2_txts):,}")
        print(f"   ✅ Completos (HTML+TXT): {len(r2_completos):,}")
        if r2_otros:
            print(f"   📦 Otros:             {len(r2_otros):,}")
        
    except Exception as e:
        print(f"❌ Error escaneando R2: {e}")
        R2_ENABLED = False

# ============================================================================
# PASO 3: COMPARAR Y REPORTAR
# ============================================================================

print("\n" + "=" * 80)
print("📊 ANÁLISIS COMPLETO")
print("=" * 80)

if R2_ENABLED:
    # Calcular diferencias
    falta_en_r2 = supabase_ids - r2_completos
    archivos_huerfanos = r2_completos - supabase_ids
    solo_html = r2_htmls - r2_txts
    solo_txt = r2_txts - r2_htmls
    
    print(f"""
📈 PIPELINE: SUPABASE → R2

  Supabase (Metadata)          Cloudflare R2 (HTML+TXT)
  ═══════════════════    →     ════════════════════════
       {len(supabase_ids):>7,}                         {len(r2_completos):>7,}

1️⃣  SUPABASE → R2 (Copia de archivos)
    ✅ Completos en R2:               {len(r2_completos):>10,}
    ❌ Pendientes en R2:              {len(falta_en_r2):>10,}
    ⚠️  Solo HTML (sin TXT):          {len(solo_html):>10,}
    ⚠️  Solo TXT (sin HTML):          {len(solo_txt):>10,}
    📊 % Completado:                  {(len(r2_completos)/len(supabase_ids)*100) if len(supabase_ids) > 0 else 0:>9.1f}%
""")
    
    if archivos_huerfanos:
        print(f"⚠️  ARCHIVOS HUÉRFANOS (R2 sin metadata): {len(archivos_huerfanos):,}")
    
    # Guardar reportes
    if falta_en_r2:
        print(f"\n💾 Guardando lista de documentos sin archivos en R2...")
        with open('documentos_sin_r2.txt', 'w') as f:
            for doc_id in sorted(falta_en_r2):
                f.write(f"{doc_id}\n")
        print(f"✅ Guardado: documentos_sin_r2.txt ({len(falta_en_r2):,} IDs)")
    
    if solo_html:
        print(f"\n💾 Guardando lista de documentos con solo HTML...")
        with open('documentos_solo_html.txt', 'w') as f:
            for doc_id in sorted(solo_html):
                f.write(f"{doc_id}\n")
        print(f"✅ Guardado: documentos_solo_html.txt ({len(solo_html):,} IDs)")
    
    if solo_txt:
        print(f"\n💾 Guardando lista de documentos con solo TXT...")
        with open('documentos_solo_txt.txt', 'w') as f:
            for doc_id in sorted(solo_txt):
                f.write(f"{doc_id}\n")
        print(f"✅ Guardado: documentos_solo_txt.txt ({len(solo_txt):,} IDs)")
    
    if archivos_huerfanos:
        print(f"\n💾 Guardando lista de archivos huérfanos...")
        with open('archivos_huerfanos_r2.txt', 'w') as f:
            for doc_id in sorted(archivos_huerfanos):
                f.write(f"{doc_id}\n")
        print(f"✅ Guardado: archivos_huerfanos_r2.txt ({len(archivos_huerfanos):,} IDs)")

else:
    print(f"""
📊 RESUMEN SUPABASE:
    Total documentos:                 {len(supabase_ids):>10,}
    
⚠️  No se pudo analizar R2 (faltan credenciales)
""")

# ============================================================================
# COMPARACIÓN CON DRIVE (ESPERADO)
# ============================================================================

print("\n" + "=" * 80)
print("📈 COMPARACIÓN CON DRIVE (ESPERADO)")
print("=" * 80)

ESPERADO_DRIVE = 73345
faltante_vs_drive = ESPERADO_DRIVE - len(supabase_ids)

print(f"""
Esperado en Drive:                    {ESPERADO_DRIVE:>10,}
Encontrado en Supabase:               {len(supabase_ids):>10,}
Faltantes (Drive → Supabase):         {faltante_vs_drive:>10,}
% Procesado:                          {(len(supabase_ids)/ESPERADO_DRIVE*100):>9.1f}%

⚠️  FALTAN PROCESAR ~{faltante_vs_drive:,} HTMLs DE DRIVE
    Incluyendo las 366 resoluciones de Sala_Plena
""")

print("=" * 80)
print("\n✅ Auditoría completa finalizada!\n")

if not R2_ENABLED:
    print("💡 PRÓXIMO PASO: Agrega credenciales de R2 al .env para análisis completo")
    print("   Abre .env y completa:")
    print("   - R2_ACCOUNT_ID")
    print("   - R2_ACCESS_KEY_ID")
    print("   - R2_SECRET_ACCESS_KEY")
    print()
