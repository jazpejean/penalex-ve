#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import re
import io
import time
import json
import subprocess
import threading
import tempfile
import concurrent.futures
from googleapiclient.discovery import build
from googleapiclient.http import MediaIoBaseDownload
from googleapiclient.errors import HttpError

# ============================================================
# CONFIGURACIÓN (cambia según tu proyecto)
# ============================================================
PUB = '/content/staging/public'               # Carpeta local de salida
LOGO_URL_PUBLIC = '/assets/logo-tsj.jpg'      # Ruta en Firebase Hosting
PROGRESO_FILE = '/content/progreso.json'      # Archivo de progreso
LOTE = 10                                     # Publicar cada N archivos (por defecto)
MAX_WORKERS = 20                              # Hilos de descarga simultánea

# ============================================================
# CARPETAS DE DRIVE (id de cada carpeta)
# ============================================================
# DEBES REEMPLAZAR ESTOS IDS POR LOS REALES DE TUS CARPETAS
# Puedes obtenerlos de la URL de Drive: https://drive.google.com/drive/folders/xxxxx
FOLDER_IDS = {
    'Sala_Constitucional': '1a2b3c4d5e6f7g8h9i0j',   # <- CAMBIA ESTO
    'Sala_Penal': '2b3c4d5e6f7g8h9i0j1k',            # <- CAMBIA ESTO
    'Sustanciacion_Constitucional': '3c4d5e6f7g8h9i0j1k2l',
    'Sala_Plena': '4d5e6f7g8h9i0j1k2l3m',
    'Sala_Penal_Juris': '5e6f7g8h9i0j1k2l3m4n',
    'Sala_Constitucional_Juris': '6f7g8h9i0j1k2l3m4n5o'
}

# Asignamos un 'tipo' a cada carpeta (para organizar en firebase)
TIPO_POR_CARPETA = {
    'Sala_Constitucional': 'sentencias',
    'Sala_Penal': 'sentencias',
    'Sustanciacion_Constitucional': 'sentencias',
    'Sala_Plena': 'resoluciones',
    'Sala_Penal_Juris': 'jurisprudencia',
    'Sala_Constitucional_Juris': 'jurisprudencia'
}

# ============================================================
# AUTENTICACIÓN (funciona en Colab y GitHub Actions)
# ============================================================
_local = threading.local()

def get_drive():
    if hasattr(_local, 'drv'):
        return _local.drv

    # 1. Intentar usar credenciales desde variable de entorno
    creds_json = os.environ.get('GOOGLE_APPLICATION_CREDENTIALS_JSON')
    if creds_json:
        # Crear un archivo temporal con el JSON
        temp_file = tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False)
        temp_file.write(creds_json)
        temp_file.close()
        # Establecer la variable de entorno para que apunte al archivo
        os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = temp_file.name
        
        # Usar las credenciales por defecto (que ahora apuntan al archivo temporal)
        from google.auth import default
        credentials, project = default(scopes=['https://www.googleapis.com/auth/drive.readonly'])
        _local.drv = build('drive', 'v3', credentials=credentials)
    else:
        # En Colab se asume que ya hay autenticación (google.colab.drive.mount)
        _local.drv = build('drive', 'v3')
    return _local.drv

def listar_archivos_en_carpeta(folder_id, page_token=None):
    """Lista recursivamente todos los archivos HTML dentro de una carpeta de Drive."""
    q = f"'{folder_id}' in parents and mimeType='text/html' and trashed=false"
    fields = "files(id, name, parents), nextPageToken"
    try:
        results = get_drive().files().list(
            q=q,
            pageToken=page_token,
            fields=fields,
            pageSize=1000
        ).execute()
    except HttpError as e:
        print(f"❌ Error listando carpeta {folder_id}: {e}")
        return [], None

    files = results.get('files', [])
    next_token = results.get('nextPageToken')
    return files, next_token

def obtener_todos_archivos():
    """Recorre todas las carpetas configuradas y devuelve lista de registros."""
    records = []
    for sala, folder_id in FOLDER_IDS.items():
        print(f"📂 Listando {sala} (ID: {folder_id})...")
        page_token = None
        contador = 0
        while True:
            archivos, page_token = listar_archivos_en_carpeta(folder_id, page_token)
            for f in archivos:
                records.append({
                    'id': f['id'],
                    'nombre': f['name'],
                    'sala': sala,
                    'tipo': TIPO_POR_CARPETA.get(sala, 'otros'),
                    'drive_id': f['id']
                })
                contador += 1
            if not page_token:
                break
        print(f"   ✅ {contador} archivos encontrados en {sala}")
    return records

# ============================================================
# FUNCIONES DE CURADO (TAL CUAL)
# ============================================================
MAPA = {
    'Ã¡':'á', 'Ã©':'é', 'Ã­':'í', 'Ã³':'ó', 'Ãº':'ú',
    'Ã±':'ñ', 'Â°':'°', 'Â¿':'¿', 'Â¡':'¡',
    'â€™':'’', 'â€˜':'‘', 'â€œ':'"', 'â€':'"',
    'â€“':'–', 'â€"':'—', 'â€¦':'…'
}

def curar(raw):
    try:
        t = raw.decode('utf-8')
    except:
        t = raw.decode('windows-1252', errors='replace')
    if 'Ã' in t or 'â€' in t:
        try:
            t = t.encode('windows-1252').decode('utf-8')
        except:
            for k, v in MAPA.items():
                t = t.replace(k, v)
    t = re.sub(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]', '', t).replace('\u00ad', '')
    t = re.sub(r'<\?xml[^>]*\?>', '', t)
    t = re.sub(r'<meta[^>]*charset=[^>]*>', '<meta charset="UTF-8">', t, flags=re.I)
    if 'charset' not in t.lower():
        t = re.sub(r'(<head[^>]*>)', r'\1\n<meta charset="UTF-8">', t, count=1, flags=re.I)
    # Añadir noindex (si no existe)
    if 'noindex' not in t.lower():
        t = re.sub(r'(<head[^>]*>)', r'\1\n<meta name="robots" content="noindex, nofollow, noarchive, nosnippet">', t, count=1, flags=re.I)
    # Reemplazar logo del TSJ
    t = re.sub(r'<img[^>]*src=["\'][^"\']*encabezado[^"\']*["\'][^>]*>',
               f'<img src="{LOGO_URL_PUBLIC}" alt="TSJ" style="max-width:100%">', t, flags=re.I)
    if 'logo-tsj' not in t.lower() and 'encabezadotsj' not in t.lower():
        t = re.sub(r'(<body[^>]*>)',
                   r'\1\n<div align="center" style="margin:8px 0"><img src="' + LOGO_URL_PUBLIC + r'" alt="TSJ" style="max-width:100%"></div>',
                   t, count=1, flags=re.I)
    return t

def a_texto(html):
    t = re.sub(r'<script[\s\S]*?</script>', '', html, flags=re.I)
    t = re.sub(r'<style[\s\S]*?</style>', '', t, flags=re.I)
    t = re.sub(r'<[^>]+>', ' ', t)
    return re.sub(r'\s+', ' ', t).strip()

def descargar_t(did):
    for intento in range(3):
        try:
            buf = io.BytesIO()
            down = MediaIoBaseDownload(buf, get_drive().files().get_media(fileId=did))
            done = False
            while not done:
                _, done = down.next_chunk()
            return buf.getvalue()
        except Exception:
            time.sleep(2)
    return None

# ============================================================
# CONTROL DE PROGRESO
# ============================================================
def cargar_progreso():
    if os.path.exists(PROGRESO_FILE):
        with open(PROGRESO_FILE, 'r') as f:
            return set(json.load(f))
    return set()

def guardar_progreso(conjunto):
    with open(PROGRESO_FILE, 'w') as f:
        json.dump(list(conjunto), f)

# ============================================================
# PUBLICAR EN FIREBASE
# ============================================================
def publicar_firebase():
    print("📤 Publicando en Firebase Hosting...")
    try:
        subprocess.run(['firebase', '--version'], check=True, capture_output=True)
    except:
        subprocess.run(['npm', 'install', '-g', 'firebase-tools'], check=True)

    cmd = ['firebase', 'deploy', '--only', 'hosting', '--public', PUB]
    token = os.environ.get('FIREBASE_TOKEN')
    if token:
        cmd.extend(['--token', token])

    try:
        resultado = subprocess.run(cmd, check=True, capture_output=True, text=True)
        print("✅ Publicación exitosa.")
        return True
    except Exception as e:
        print(f"❌ Error al publicar: {e}")
        return False

# ============================================================
# PROCESAR UN ARCHIVO
# ============================================================
def procesar_archivo(rec, procesados_set, lock):
    if rec['id'] in procesados_set:
        return 0  # ya procesado

    hd = f"{PUB}/html/{rec['tipo']}/{rec['sala']}/{rec['nombre']}"
    td = f"{PUB}/txt/{rec['tipo']}/{rec['sala']}/{rec['id']}.txt"

    # Si ya existen en disco, considerar procesados
    if os.path.exists(hd) and os.path.exists(td):
        with lock:
            procesados_set.add(rec['id'])
            guardar_progreso(procesados_set)
        return 0

    raw = descargar_t(rec['drive_id'])
    if raw is None:
        return -1

    os.makedirs(os.path.dirname(hd), exist_ok=True)
    os.makedirs(os.path.dirname(td), exist_ok=True)

    limpio = curar(raw)
    with open(hd, 'w', encoding='utf-8') as f:
        f.write(limpio)
    with open(td, 'w', encoding='utf-8') as f:
        f.write(a_texto(limpio))

    with lock:
        procesados_set.add(rec['id'])
        guardar_progreso(procesados_set)
    return 1

# ============================================================
# MAIN
# ============================================================
def main():
    # Obtener límite desde variable de entorno (para GitHub Actions) o preguntar en Colab
    limite_env = os.environ.get('LIMITE')
    if limite_env is not None:
        limite = int(limite_env)
    else:
        try:
            limite = int(input("¿Cuántos archivos quieres procesar? (0 = todos): "))
        except:
            limite = 0

    lote_env = os.environ.get('LOTE')
    if lote_env is not None:
        lote = int(lote_env)
    else:
        try:
            lote = int(input("¿Cada cuántos archivos publicar? (ej: 10): "))
            if lote < 1:
                lote = 1
        except:
            lote = 10

    # Cargar progreso
    procesados = cargar_progreso()
    print(f"📌 Archivos ya procesados: {len(procesados)}")

    # Obtener lista de archivos desde Drive
    print("🔍 Obteniendo lista de archivos de Drive...")
    records = obtener_todos_archivos()
    print(f"📄 Total archivos encontrados: {len(records)}")

    if limite > 0:
        records = records[:limite]

    print(f"🔧 Procesando {len(records)} archivos...")
    print(f"📤 Publicando cada {lote} archivos.")

    # Preparar conjunto de procesados y lock para threads
    procesados_set = set(procesados)
    lock = threading.Lock()

    hechos = 0
    fallos = 0
    contador_lote = 0

    # Usar ThreadPoolExecutor para descargas en paralelo
    with concurrent.futures.ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
        future_to_rec = {executor.submit(procesar_archivo, rec, procesados_set, lock): rec for rec in records}
        for i, future in enumerate(concurrent.futures.as_completed(future_to_rec), 1):
            rec = future_to_rec[future]
            try:
                resultado = future.result()
            except Exception as e:
                print(f"❌ Error inesperado en {rec['nombre']}: {e}")
                resultado = -1

            if resultado == 1:
                hechos += 1
                contador_lote += 1
            elif resultado == -1:
                fallos += 1

            # Mostrar progreso
            if i % 10 == 0 or i == len(records):
                print(f"⚙️ Procesados {i}/{len(records)} | nuevos: {hechos} | fallos: {fallos}")

            # Publicar cada lote
            if contador_lote >= lote:
                publicar_firebase()
                contador_lote = 0

    # Publicar lo que quede
    if contador_lote > 0 and hechos > 0:
        publicar_firebase()

    print(f"\n✅ Procesamiento completado: {hechos} nuevos, {fallos} fallos.")
    print(f"📌 Total acumulado: {len(procesados_set)}")

if __name__ == '__main__':
    main()
