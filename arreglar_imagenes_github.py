#!/usr/bin/env python3
"""
Script OPTIMIZADO para arreglar imágenes en R2 - SIN Supabase
Máxima velocidad con 50 hilos concurrentes
"""
import os
import sys
import re
import gzip
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
import boto3
from botocore.config import Config
from botocore.exceptions import ClientError

# Cargar .env si existe
try:
    from dotenv import load_dotenv
    load_dotenv()
except:
    pass

# Env Vars (Solo Cloudflare R2)
R2_ACCOUNT_ID = os.environ.get('R2_ACCOUNT_ID') or os.environ.get('CLOUDFLARE_ACCOUNT_ID')
R2_ACCESS_KEY = os.environ.get('R2_ACCESS_KEY_ID')
R2_SECRET_KEY = os.environ.get('R2_SECRET_ACCESS_KEY')
R2_BUCKET = os.environ.get('R2_BUCKET_NAME', 'penalex-ve')
R2_PUBLIC_URL = os.environ.get('R2_PUBLIC_URL', 'https://pub-a6e0bfa2e9174e91b031ae28c0667009.r2.dev')
LOGO_CORRECTO = f'{R2_PUBLIC_URL}/assets/logo.jpg'

# Patrones compilados (más rápido)
PATRONES_ROTOS = [
    r'https://pub-a6e0bfa2e9174e91b031ae28c0667009\.r2\.dev/html/[^"\'<>\s]+_archivos/[^"\'<>\s]+\.(jpg|png|gif|jpeg)',
    r'https://historico\.tsj\.gob\.ve/graficos/encabezadotsj\.jpg',
    r'http://historico\.tsj\.gob\.ve/graficos/encabezadotsj\.jpg',
    r'\./[^"\'<>\s]+_archivos/[^"\'<>\s]+\.(jpg|png|gif|jpeg)',
    r'(?<![:/])[^/"\s]+_archivos/[^"\'<>\s]+\.(jpg|png|gif|jpeg)',
    r'/graficos/encabezadotsj\.jpg',
    r'/imagenes/[^"\'<>\s]+\.(jpg|png|gif|jpeg)',
]

PATRONES_COMPILADOS = [re.compile(p, re.IGNORECASE) for p in PATRONES_ROTOS]
PATRON_VML = re.compile(r'<!--\[if gte vml 1\]>.*?<!\[endif\]-->', re.DOTALL | re.IGNORECASE)

# Config agresivo para velocidad
BOTO3_CONFIG = Config(
    signature_version='s3v4',
    connect_timeout=3,
    read_timeout=10,
    retries={'max_attempts': 1}
)

def get_s3():
    """Crea cliente S3 para R2"""
    return boto3.client(
        's3',
        endpoint_url=f'https://{R2_ACCOUNT_ID}.r2.cloudflarestorage.com',
        aws_access_key_id=R2_ACCESS_KEY,
        aws_secret_access_key=R2_SECRET_KEY,
        region_name='auto',
        config=BOTO3_CONFIG
    )

def procesar_html(key):
    """
    Procesa un archivo HTML: descarga, corrige, re-sube
    Retorna: (modificado, error)
    """
    s3 = get_s3()  # Cada thread tiene su propio cliente
    try:
        # Descargar
        response = s3.get_object(Bucket=R2_BUCKET, Key=key)
        content_encoding = response.get('ContentEncoding', '')
        raw_data = response['Body'].read()
        
        # Decodificar
        if 'gzip' in content_encoding:
            html = gzip.decompress(raw_data).decode('utf-8', errors='replace')
        else:
            try:
                html = raw_data.decode('utf-8', errors='replace')
            except:
                html = raw_data.decode('latin-1', errors='replace')
        
        # Correcciones usando patrones precompilados
        html_corregido = PATRON_VML.sub('', html)
        for patron in PATRONES_COMPILADOS:
            html_corregido = patron.sub(LOGO_CORRECTO, html_corregido)
        
        # Solo guarda si cambió
        if html_corregido != html:
            data_corregida = gzip.compress(html_corregido.encode('utf-8'), compresslevel=6)
            s3.put_object(
                Bucket=R2_BUCKET,
                Key=key,
                Body=data_corregida,
                ContentType='text/html; charset=utf-8',
                ContentEncoding='gzip'
            )
            return True, None
            
        return False, None
    except ClientError as e:
        return False, f"ClientError: {e.response['Error']['Code']}"
    except Exception as e:
        return False, str(e)[:100]

if __name__ == '__main__':
    print("=" * 80)
    print("🚀 ARREGLAR IMÁGENES EN R2 - MODO RÁPIDO")
    print("=" * 80)
    
    # Validar variables
    if not all([R2_ACCOUNT_ID, R2_ACCESS_KEY, R2_SECRET_KEY]):
        print("\n❌ ERROR: Faltan variables de entorno:")
        print(f"   CLOUDFLARE_ACCOUNT_ID: {'✅' if R2_ACCOUNT_ID else '❌'}")
        print(f"   R2_ACCESS_KEY_ID: {'✅' if R2_ACCESS_KEY else '❌'}")
        print(f"   R2_SECRET_ACCESS_KEY: {'✅' if R2_SECRET_KEY else '❌'}")
        sys.exit(1)
    
    print(f"\n✅ Configuración:")
    print(f"   Bucket: {R2_BUCKET}")
    print(f"   Logo: {LOGO_CORRECTO}")
    
    # Listar archivos
    print("\n📂 Listando archivos HTML en R2...", flush=True)
    s3 = get_s3()
    
    html_keys = []
    continuation_token = None
    pages = 0
    
    try:
        while True:
            kwargs = {'Bucket': R2_BUCKET, 'Prefix': 'html/', 'MaxKeys': 1000}
            if continuation_token:
                kwargs['ContinuationToken'] = continuation_token
            
            print(f"   Página {pages + 1}...", end=' ', flush=True)
            response = s3.list_objects_v2(**kwargs)
            pages += 1
            
            if 'Contents' in response:
                for obj in response['Contents']:
                    k = obj['Key']
                    if k.lower().endswith('.html'):
                        html_keys.append(k)
            
            print(f"({len(html_keys):,} archivos acumulados)", flush=True)
            
            if not response.get('IsTruncated'):
                break
            continuation_token = response.get('NextContinuationToken')
    
    except Exception as e:
        print(f"\n❌ Error listando R2: {e}")
        sys.exit(1)
    
    total = len(html_keys)
    print(f"\n✅ Total archivos HTML: {total:,}")
    
    if total == 0:
        print("⚠️  No se encontraron archivos para procesar")
        sys.exit(0)
    
    # Procesar con ThreadPool
    print(f"\n⚡ Procesando con 50 hilos concurrentes...")
    print("=" * 80)
    
    procesados = 0
    modificados = 0
    errores = 0
    start_time = time.time()
    
    with ThreadPoolExecutor(max_workers=50) as executor:
        futures = {executor.submit(procesar_html, key): key for key in html_keys}
        
        for future in as_completed(futures):
            procesados += 1
            try:
                mod, err = future.result(timeout=15)
                
                if err:
                    errores += 1
                    # Solo mostrar primeros 5 errores
                    if errores <= 5:
                        print(f"❌ Error: {err}")
                elif mod:
                    modificados += 1
            except Exception as e:
                errores += 1
            
            # Reportar cada 500 archivos o al final
            if procesados % 500 == 0 or procesados == total:
                elapsed = time.time() - start_time
                rate = procesados / elapsed if elapsed > 0 else 0
                eta = (total - procesados) / rate if rate > 0 else 0
                
                print(f"📊 {procesados:,}/{total:,} | "
                      f"Modificados: {modificados:,} | "
                      f"Errores: {errores} | "
                      f"{rate:.1f} arch/s | "
                      f"ETA: {eta/60:.1f} min", flush=True)
    
    # Resumen final
    tiempo_total = time.time() - start_time
    print("\n" + "=" * 80)
    print("✅ PROCESO COMPLETADO")
    print("=" * 80)
    print(f"\n📊 RESUMEN:")
    print(f"   Total procesados:     {procesados:,}")
    print(f"   ✅ Modificados:        {modificados:,}")
    print(f"   ⚪ Sin cambios:        {procesados - modificados - errores:,}")
    print(f"   ❌ Errores:            {errores}")
    print(f"   ⏱️  Tiempo total:      {tiempo_total/60:.1f} minutos ({tiempo_total:.1f} seg)")
    print(f"   📈 Velocidad promedio: {procesados/tiempo_total:.1f} archivos/seg")
    
    # Generar índices de HTML y TXT
    print("\n" + "=" * 80)
    print("📋 GENERANDO ÍNDICES DE ARCHIVOS")
    print("=" * 80)
    
    try:
        print("\n📂 Listando archivos TXT...")
        txt_keys = []
        continuation_token = None
        
        while True:
            kwargs = {'Bucket': R2_BUCKET, 'Prefix': 'txt/', 'MaxKeys': 1000}
            if continuation_token:
                kwargs['ContinuationToken'] = continuation_token
            
            response = s3.list_objects_v2(**kwargs)
            
            if 'Contents' in response:
                for obj in response['Contents']:
                    k = obj['Key']
                    if k.lower().endswith('.txt'):
                        txt_keys.append(k)
            
            if not response.get('IsTruncated'):
                break
            continuation_token = response.get('NextContinuationToken')
        
        print(f"✅ Archivos TXT encontrados: {len(txt_keys):,}")
        
        # Guardar índice HTML
        with open('indice_html.txt', 'w', encoding='utf-8') as f:
            for key in sorted(html_keys):
                # Extraer ID del archivo (nombre sin extensión ni carpeta)
                doc_id = key.replace('html/', '').replace('.html', '').replace('.HTML', '')
                url = f"{R2_PUBLIC_URL}/{key}"
                f.write(f"{doc_id}\t{url}\n")
        
        print(f"💾 Guardado: indice_html.txt ({len(html_keys):,} archivos)")
        
        # Guardar índice TXT
        with open('indice_txt.txt', 'w', encoding='utf-8') as f:
            for key in sorted(txt_keys):
                doc_id = key.replace('txt/', '').replace('.txt', '').replace('.TXT', '')
                url = f"{R2_PUBLIC_URL}/{key}"
                f.write(f"{doc_id}\t{url}\n")
        
        print(f"💾 Guardado: indice_txt.txt ({len(txt_keys):,} archivos)")
        
        # Guardar índice combinado (CSV para Supabase)
        with open('indice_completo.csv', 'w', encoding='utf-8') as f:
            f.write("id,url_html,url_txt\n")
            
            # Crear diccionarios para lookup rápido
            html_dict = {}
            for key in html_keys:
                doc_id = key.replace('html/', '').replace('.html', '').replace('.HTML', '')
                html_dict[doc_id] = f"{R2_PUBLIC_URL}/{key}"
            
            txt_dict = {}
            for key in txt_keys:
                doc_id = key.replace('txt/', '').replace('.txt', '').replace('.TXT', '')
                txt_dict[doc_id] = f"{R2_PUBLIC_URL}/{key}"
            
            # Combinar (todos los IDs únicos)
            all_ids = sorted(set(html_dict.keys()) | set(txt_dict.keys()))
            
            for doc_id in all_ids:
                html_url = html_dict.get(doc_id, '')
                txt_url = txt_dict.get(doc_id, '')
                f.write(f"{doc_id},{html_url},{txt_url}\n")
        
        print(f"💾 Guardado: indice_completo.csv ({len(all_ids):,} documentos)")
        
        # Estadísticas
        solo_html = len([i for i in all_ids if i in html_dict and i not in txt_dict])
        solo_txt = len([i for i in all_ids if i in txt_dict and i not in html_dict])
        ambos = len([i for i in all_ids if i in html_dict and i in txt_dict])
        
        print(f"\n📊 ESTADÍSTICAS DE ÍNDICE:")
        print(f"   Total documentos únicos: {len(all_ids):,}")
        print(f"   ✅ Con HTML y TXT:        {ambos:,}")
        print(f"   📄 Solo HTML:             {solo_html:,}")
        print(f"   📝 Solo TXT:              {solo_txt:,}")
        
    except Exception as e:
        print(f"\n❌ Error generando índices: {e}")
    
    print("\n" + "=" * 80)
    print()
    
    # Exit code
    if errores > total * 0.05:  # Más del 5% de errores
        print("⚠️  Demasiados errores (>5%), marcando como fallido")
        sys.exit(1)
    else:
        print("✅ Proceso exitoso")
        sys.exit(0)
