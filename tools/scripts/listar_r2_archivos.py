"""
Script para listar todos los archivos HTML y TXT en Cloudflare R2
y generar un índice completo para actualizar Supabase
"""
import boto3
import json
from botocore.config import Config

# ====== CONFIGURACIÓN DE CLOUDFLARE R2 ======
# Obtén estos valores en: https://dash.cloudflare.com → R2 → Manage R2 API Tokens
R2_ACCOUNT_ID = "TU_ACCOUNT_ID_AQUI"  # ejemplo: abc123def456
R2_ACCESS_KEY_ID = "TU_ACCESS_KEY_ID_AQUI"
R2_SECRET_ACCESS_KEY = "TU_SECRET_ACCESS_KEY_AQUI"
BUCKET_NAME = "penalex-ve"

# URL del endpoint de R2
ENDPOINT_URL = f"https://{R2_ACCOUNT_ID}.r2.cloudflarestorage.com"

def listar_archivos_r2():
    """Lista todos los archivos del bucket de R2"""
    print(f"🔍 Conectando a R2 bucket: {BUCKET_NAME}...")
    
    # Configurar cliente S3 compatible con R2
    s3 = boto3.client(
        's3',
        endpoint_url=ENDPOINT_URL,
        aws_access_key_id=R2_ACCESS_KEY_ID,
        aws_secret_access_key=R2_SECRET_ACCESS_KEY,
        config=Config(signature_version='s3v4'),
        region_name='auto'
    )
    
    archivos_html = []
    archivos_txt = []
    archivos_otros = []
    total = 0
    
    try:
        # Listar todos los archivos (paginado automático)
        print("📥 Descargando lista de archivos...")
        paginator = s3.get_paginator('list_objects_v2')
        
        for page_num, page in enumerate(paginator.paginate(Bucket=BUCKET_NAME), 1):
            contents = page.get('Contents', [])
            print(f"   Página {page_num}: {len(contents)} archivos")
            
            for obj in contents:
                key = obj['Key']
                size = obj['Size']
                total += 1
                
                if key.endswith('.html'):
                    archivos_html.append({
                        'key': key,
                        'size': size,
                        'url': f"https://pub-{R2_ACCOUNT_ID}.r2.dev/{key}"
                    })
                elif key.endswith('.txt'):
                    archivos_txt.append({
                        'key': key,
                        'size': size,
                        'url': f"https://pub-{R2_ACCOUNT_ID}.r2.dev/{key}"
                    })
                else:
                    archivos_otros.append(key)
        
        print(f"\n✅ Total de archivos: {total}")
        print(f"   📄 HTML: {len(archivos_html)}")
        print(f"   📝 TXT: {len(archivos_txt)}")
        print(f"   📦 Otros: {len(archivos_otros)}")
        
        # Guardar índices en JSON
        with open('indice_html.json', 'w', encoding='utf-8') as f:
            json.dump(archivos_html, f, indent=2, ensure_ascii=False)
        
        with open('indice_txt.json', 'w', encoding='utf-8') as f:
            json.dump(archivos_txt, f, indent=2, ensure_ascii=False)
        
        with open('indice_completo.json', 'w', encoding='utf-8') as f:
            json.dump({
                'total': total,
                'html': archivos_html,
                'txt': archivos_txt,
                'otros': archivos_otros
            }, f, indent=2, ensure_ascii=False)
        
        print(f"\n💾 Archivos guardados:")
        print(f"   - indice_html.json ({len(archivos_html)} archivos)")
        print(f"   - indice_txt.json ({len(archivos_txt)} archivos)")
        print(f"   - indice_completo.json (todos los archivos)")
        
        # Mostrar ejemplos
        if archivos_html:
            print(f"\n📋 Ejemplo de archivo HTML:")
            print(f"   Key: {archivos_html[0]['key']}")
            print(f"   URL: {archivos_html[0]['url']}")
        
        if archivos_txt:
            print(f"\n📋 Ejemplo de archivo TXT:")
            print(f"   Key: {archivos_txt[0]['key']}")
            print(f"   URL: {archivos_txt[0]['url']}")
        
        return archivos_html, archivos_txt
        
    except Exception as e:
        print(f"❌ Error al listar archivos: {e}")
        return None, None

if __name__ == "__main__":
    print("=" * 60)
    print("🗂️  LISTADOR DE ARCHIVOS CLOUDFLARE R2")
    print("=" * 60)
    
    # Validar configuración
    if R2_ACCOUNT_ID == "TU_ACCOUNT_ID_AQUI":
        print("\n❌ ERROR: Debes configurar las credenciales de R2")
        print("\n📝 Pasos:")
        print("1. Ve a: https://dash.cloudflare.com")
        print("2. R2 → Manage R2 API Tokens")
        print("3. Create API Token")
        print("4. Copia Account ID, Access Key ID y Secret Access Key")
        print("5. Pégalos en este script (líneas 9-11)")
    else:
        archivos_html, archivos_txt = listar_archivos_r2()
        
        if archivos_html is not None:
            print("\n✅ ¡Listo! Ahora puedes usar estos índices para actualizar Supabase.")
