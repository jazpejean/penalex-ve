#!/usr/bin/env python3
"""
Script para contar archivos en Cloudflare R2
"""

import boto3
from botocore.client import Config
import os
from dotenv import load_dotenv

# Cargar variables de entorno
load_dotenv()

# Configuración de Cloudflare R2
# Las credenciales deberían estar en tu .env como:
# R2_ACCOUNT_ID=tu_account_id
# R2_ACCESS_KEY_ID=tu_access_key
# R2_SECRET_ACCESS_KEY=tu_secret_key
# R2_BUCKET_NAME=tu_bucket_name

R2_ACCOUNT_ID = os.getenv('R2_ACCOUNT_ID')
R2_ACCESS_KEY_ID = os.getenv('R2_ACCESS_KEY_ID')
R2_SECRET_ACCESS_KEY = os.getenv('R2_SECRET_ACCESS_KEY')
R2_BUCKET_NAME = os.getenv('R2_BUCKET_NAME', 'penalex-assets')  # Default

# Endpoint de R2
R2_ENDPOINT = f'https://{R2_ACCOUNT_ID}.r2.cloudflarestorage.com'

# Crear cliente S3 compatible
s3 = boto3.client(
    's3',
    endpoint_url=R2_ENDPOINT,
    aws_access_key_id=R2_ACCESS_KEY_ID,
    aws_secret_access_key=R2_SECRET_ACCESS_KEY,
    config=Config(signature_version='s3v4'),
    region_name='auto'
)

print("🔍 ANÁLISIS DE CLOUDFLARE R2\n")
print("=" * 70)

try:
    # Listar todos los objetos
    print(f"\n📦 Bucket: {R2_BUCKET_NAME}")
    print("   Contando objetos...\n")
    
    total_objects = 0
    total_size = 0
    file_types = {}
    
    paginator = s3.get_paginator('list_objects_v2')
    pages = paginator.paginate(Bucket=R2_BUCKET_NAME)
    
    for page in pages:
        if 'Contents' in page:
            for obj in page['Contents']:
                total_objects += 1
                total_size += obj['Size']
                
                # Contar por tipo de archivo
                key = obj['Key']
                ext = key.split('.')[-1].lower() if '.' in key else 'sin_extension'
                file_types[ext] = file_types.get(ext, 0) + 1
                
                if total_objects % 1000 == 0:
                    print(f"   Procesados: {total_objects:,} objetos...", end='\r')
    
    print(f"\n\n{'='*70}")
    print("📊 RESUMEN")
    print("=" * 70)
    
    print(f"\n📁 Total de objetos:     {total_objects:>15,}")
    print(f"💾 Espacio total usado:  {total_size:>15,} bytes")
    print(f"                         {total_size / (1024**2):>15,.2f} MB")
    print(f"                         {total_size / (1024**3):>15,.2f} GB")
    
    if total_objects > 0:
        print(f"📏 Tamaño promedio:      {total_size / total_objects:>15,.0f} bytes/archivo")
    
    print(f"\n{'='*70}")
    print("📋 TIPOS DE ARCHIVO")
    print("=" * 70)
    
    # Ordenar por cantidad
    sorted_types = sorted(file_types.items(), key=lambda x: x[1], reverse=True)
    
    for ext, count in sorted_types[:20]:  # Top 20
        porcentaje = (count / total_objects * 100) if total_objects > 0 else 0
        print(f"  {ext:20} {count:>10,} ({porcentaje:>5.1f}%)")
    
    if len(sorted_types) > 20:
        otros = sum([count for ext, count in sorted_types[20:]])
        print(f"  {'(otros)':20} {otros:>10,}")
    
    print("\n" + "=" * 70)
    
except Exception as e:
    print(f"\n❌ Error: {e}")
    print("\n⚠️  Verifica que las credenciales de R2 estén configuradas en .env:")
    print("   - R2_ACCOUNT_ID")
    print("   - R2_ACCESS_KEY_ID")
    print("   - R2_SECRET_ACCESS_KEY")
    print("   - R2_BUCKET_NAME")
