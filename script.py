#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Pipeline Penalex VE (sin LLM, sin claves):
  Drive -> cura HTML -> texto plano -> PDF -> Firestore -> Firebase Hosting
Idempotente: usa Firestore como fuente de verdad para no reprocesar.
"""

import os
import re
import io
import csv
import json
import time
import subprocess
import threading
import concurrent.futures

import requests
from googleapiclient.discovery import build
from googleapiclient.http import MediaIoBaseDownload
from googleapiclient.errors import HttpError
from google.oauth2 import service_account

import firebase_admin
from firebase_admin import credentials, firestore

# ============================================================
# CONFIGURACIÓN (rutas relativas para GitHub Actions)
# ============================================================
WORK_DIR = os.getcwd()
PUB = os.path.join(WORK_DIR, 'public')
ASSETS = os.path.join(PUB, 'assets')
LOGO_URL = 'https://historico.tsj.gob.ve/graficos/encabezadotsj.jpg'
LOGO_LOCAL = os.path.join(ASSETS, 'logo-tsj.jpg')

MAX_WORKERS = 8
BATCH_FS = 400

# ============================================================
# CARPETAS DE DRIVE (nombre, id, tipo, sala)
# ⚠️ Reemplaza el ID de Sala_Plena por el ID real de esa carpeta
# ============================================================
FOLDERS = [
    ('Sala_Constitucional',         '1kGbRPySacSvqZITKQ0ll4-T-O3Ns6ieN', 'sentencia',     'constitucional'),
    ('Sala_Penal',                  '1AlySvmxbfCsMV07Rs24FUt6VFQSPgPY1', 'sentencia',     'penal'),
    ('Sustanciacion_Constitucional','1gAXDSFKVAzVCKAXCBVAraKMM7xCXblD8', 'sentencia',     'sustanciacion'),
    ('Sala_Penal_Juris',            '1BL50vMykxVDiCFIQJuYlhcbvlCoD5afg', 'jurisprudencia','penal'),
    ('Sala_Constitucional_Juris',   '1Ais0FpCjLPOcwOCe8I86hgbGWYj2CQFK', 'jurisprudencia','constitucional'),
]

# ============================================================
# AUTENTICACIÓN (Drive + Firestore usan la misma cuenta de servicio)
# ============================================================
_local = threading.local()
CREDS_PATH = os.environ.get('GOOGLE_APPLICATION_CREDENTIALS')

def get_drive():
    if not hasattr(_local, 'drv'):
        creds = service_account.Credentials.from_service_account_file(
            CREDS_PATH, scopes=['https://www.googleapis.com/auth/drive.readonly'])
        _local.drv = build('drive', 'v3', credentials=creds, cache_discovery=False)
    return _local.drv

_db = None
def get_db():
    global _db
    if _db is None:
        if not firebase_admin._apps:
            cred = credentials.Certificate(CREDS_PATH)
            firebase_admin.initialize_app(cred)
        _db = firestore.client()
    return _db

# ============================================================
# BATCH DE FIRESTORE (thread-safe)
# ============================================================
_fs_lock = threading.Lock()
_fs_batch = None
_fs_count = 0

def fs_set(doc_id, data):
    global _fs_batch, _fs_count
    db = get_db()
    with _fs_lock:
        if _fs_batch is None:
            _fs_batch = db.batch()
        _fs_batch.set(db.collection('documentos').document(doc_id), data, merge=True)
        _fs_count += 1
        if _fs_count >= BATCH_FS:
            _fs_batch.commit()
            _fs_batch = None
            _fs_count = 0

def fs_flush():
    global _fs_batch, _fs_count
    with _fs_lock:
        if _fs_batch is not None and _fs_count > 0:
            _fs_batch.commit()
            _fs_batch = None
            _fs_count = 0

# ============================================================
# CURADO HTML (corrige encoding + logo + meta, preserva apariencia)
# ============================================================
MAPA_ENC = {
    'Ã¡':'á','Ã©':'é','Ã­':'í','Ã³':'ó','Ãº':'ú','Ã±':'ñ','Ã‘':'Ñ',
    'Â°':'°','Â¿':'¿','Â¡':'¡','â€™':'’','â€˜':'‘','â€œ':'"','â€':'"',
    'â€“':'–','â€"':'—','â€¦':'…','ï¿½':'ñ',
}

def rel_logo(dest_path):
    """Ruta relativa al logo desde el HTML (funciona en Hosting y en PDF local)."""
    return os.path.relpath(LOGO_LOCAL, os.path.dirname(dest_path)).replace(os.sep, '/')

def curar(raw, logo_rel):
    try:
        t = raw.decode('utf-8')
    except UnicodeDecodeError:
        t = raw.decode('windows-1252', errors='replace')
    if 'Ã' in t or 'â€' in t or 'ï¿½' in t:
        try:
            t = t.encode('windows-1252').decode('utf-8')
        except Exception:
            for k, v in MAPA_ENC.items():
                t = t.replace(k, v)
    t = re.sub(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]', '', t).replace('\u00ad', '')
    t = re.sub(r'<\?xml[^>]*\?>', '', t)
    t = re.sub(r'<meta[^>]*charset[^>]*>', '<meta charset="UTF-8">', t, flags=re.I)
    if 'charset' not in t.lower():
        t = re.sub(r'(<head[^>]*>)', r'\1\n<meta charset="UTF-8">', t, count=1, flags=re.I)
    if 'noindex' not in t.lower():
        t = re.sub(r'(<head[^>]*>)',
                   r'\1\n<meta name="robots" content="noindex, nofollow, noarchive, nosnippet">',
                   t, count=1, flags=re.I)
    t = re.sub(r'<img[^>]*src=["\'][^"\']*encabezado[^"\']*["\'][^>]*>',
               f'<img src="{logo_rel}" alt="TSJ" style="max-width:100%">', t, flags=re.I)
    if 'logo-tsj' not in t.lower() and 'encabezadotsj' not in t.lower():
        t = re.sub(r'(<body[^>]*>)',
                   r'\1\n<div align="center" style="margin:8px 0"><img src="' + logo_rel + r'" alt="TSJ" style="max-width:100%"></div>',
                   t, count=1, flags=re.I)
    return t

def html_a_texto(html):
    t = re.sub(r'<script[\s\S]*?</script>', '', html, flags=re.I)
    t = re.sub(r'<style[\s\S]*?</style>', '', t, flags=re.I)
    t = re.sub(r'<[^>]+>', ' ', t)
    t = re.sub(r'&nbsp;?', ' ', t)
    t = re.sub(r'&amp;', '&', t)
    t = re.sub(r'&[a-z]+;', ' ', t)
    return re.sub(r'\s+', ' ', t).strip()

# ============================================================
# GENERAR PDF
# ============================================================
def generar_pdf(html_path, pdf_path):
    try:
        subprocess.run([
            'wkhtmltopdf', '-q',
            '--enable-local-file-access',
            '--encoding', 'UTF-8',
            '--load-error-handling', 'ignore',
            '--load-media-error-handling', 'ignore',
            '--no-stop-slow-scripts',
            '--javascript-delay', '0',
            html_path, pdf_path
        ], capture_output=True, timeout=180, check=False)
        return os.path.exists(pdf_path) and os.path.getsize(pdf_path) > 0
    except Exception:
        return False

# ============================================================
# NORMALIZACIÓN DE FECHA -> ISO (yyyy-mm-dd)
# ============================================================
MESES = {'enero':1,'febrero':2,'marzo':3,'abril':4,'mayo':5,'junio':6,
         'julio':7,'agosto':8,'septiembre':9,'octubre':10,'noviembre':11,'diciembre':12}

def normalizar_fecha(s):
    if not s: return ''
    s = s.strip()
    m = re.match(r'(\d{1,2})/(\d{1,2})/(\d{4})', s)
    if m:
        return f"{m.group(3)}-{int(m.group(2)):02d}-{int(m.group(1)):02d}"
    m = re.search(r'(\d{1,2})\s+de\s+([A-Za-záéíóúñ]+)\s+de\s+(\d{4})', s)
    if not m:
        m = re.search(r',?\s*(\d{1,2})\s+([A-Za-záéíóúñ]+)\s+de\s+(\d{4})', s)
    if m:
        mes = MESES.get(m.group(2).lower(), 0)
        if mes:
            return f"{m.group(3)}-{mes:02d}-{int(m.group(1)):02d}"
    return s

# ============================================================
# PARSEO DE METADATA.CSV (por nombre de columna, captura extracto)
# ============================================================
def normalizar_fila(row):
    d = {}
    for k, v in row.items():
        if v is None:
            continue
        v = str(v).strip()
        if not v:
            continue
        kl = (k or '').strip().lower()

        if kl in ('archivo', 'file', 'nombre', 'name'):
            d['archivo'] = v
        elif 'url' in kl or 'enlace' in kl or 'link' in kl:
            d['url_tsj'] = v
        elif 'fecha' in kl:
            d['fecha'] = normalizar_fecha(v)
        elif 'num' in kl or kl in ('n°', 'no', 'numero'):
            d['num_sentencia'] = v
        elif 'exp' in kl:
            d['expediente'] = v
        elif 'ponente' in kl or 'magistrado' in kl:
            d['ponente'] = v
        elif 'parte' in kl or 'demand' in kl or 'actor' in kl or 'recurrente' in kl or 'querell' in kl or 'acusad' in kl:
            d['partes'] = (d.get('partes', '') + ' ' + v).strip()
        elif 'procedimiento' in kl or 'recurso' in kl or 'accion' in kl or kl == 'tipo':
            d['procedimiento'] = v
        elif 'decision' in kl or 'fallo' in kl or 'veredicto' in kl:
            d['decision'] = v
        elif 'extracto' in kl or 'criterio' in kl or 'resumen' in kl or 'descripcion' in kl or 'motiva' in kl or 'texto' in kl:
            if len(v) > len(d.get('extracto', '')):
                d['extracto'] = v
    return d if d.get('archivo') else None

def cargar_metadata_csv(folder_id):
    lookup = {}
    try:
        res = get_drive().files().list(
            q=f"'{folder_id}' in parents and name='metadata.csv' and trashed=false",
            fields="files(id)").execute()
        files = res.get('files', [])
        if not files:
            return lookup
        buf = io.BytesIO()
        down = MediaIoBaseDownload(buf, get_drive().files().get_media(fileId=files[0]['id']))
        done = False
        while not done:
            _, done = down.next_chunk()
        contenido = buf.getvalue().decode('utf-8', errors='replace')
        for row in csv.DictReader(io.StringIO(contenido)):
            meta = normalizar_fila(row)
            if meta and meta.get('archivo'):
                lookup[meta['archivo']] = meta
    except Exception as e:
        print(f"   ⚠️ No se pudo cargar metadata.csv: {e}")
    return lookup

# ============================================================
# DRIVE: listar y descargar
# ============================================================
def listar_htmls(folder_id):
    out = []
    page_token = None
    while True:
        try:
            res = get_drive().files().list(
                q=f"'{folder_id}' in parents and mimeType='text/html' and trashed=false",
                fields="files(id,name),nextPageToken",
                pageSize=1000, pageToken=page_token).execute()
        except HttpError as e:
            print(f"   ❌ Error listando: {e}")
            break
        for f in res.get('files', []):
            out.append({'id': f['id'], 'nombre': f['name']})
        page_token = res.get('nextPageToken')
        if not page_token:
            break
    return out

def descargar(did):
    for _ in range(3):
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
# HELPERS
# ============================================================
def parsear_nombre(nombre):
    m = re.match(r'^(\d{4})_(\d+)_exp_(.+)\.html$', nombre)
    if m:
        return {'num_sentencia': m.group(2), 'expediente': m.group(3)}
    m2 = re.match(r'^resolucion_(.+)\.html$', nombre)
    if m2:
        return {'num_sentencia': m2.group(1)}
    return {}

def generar_texto_busqueda(meta, texto):
    partes = [
        meta.get('tipo',''), meta.get('sala',''), meta.get('procedimiento',''),
        meta.get('decision',''), meta.get('partes',''), meta.get('ponente',''),
        meta.get('expediente',''), meta.get('num_sentencia',''),
        (meta.get('fecha','') or '')[:4],
        ' '.join((meta.get('extracto','') or '').split()[:100]),
    ]
    palabras = texto.split()[:500]
    return ' '.join([p for p in partes if p] + palabras)

# ============================================================
# PROCESAR UN DOCUMENTO
# ============================================================
stats_lock = threading.Lock()
stats = {'ok':0, 'fail':0}

def procesar(rec, tipo, sala, meta_lookup):
    doc_id = rec['nombre'][:-5]
    try:
        raw = descargar(rec['id'])
        if not raw:
            return False

        sub = 'resoluciones' if tipo == 'resolucion' else (tipo + 's')
        html_path = os.path.join(PUB, 'html', sub, sala, rec['nombre'])
        pdf_path  = os.path.join(PUB, 'pdf',  sub, sala, doc_id + '.pdf')
        os.makedirs(os.path.dirname(html_path), exist_ok=True)
        os.makedirs(os.path.dirname(pdf_path), exist_ok=True)

        limpio = curar(raw, rel_logo(html_path))
        with open(html_path, 'w', encoding='utf-8') as f:
            f.write(limpio)

        texto = html_a_texto(limpio)
        generar_pdf(html_path, pdf_path)

        doc = {'id': doc_id, 'tipo': tipo, 'sala': sala}
        doc.update(parsear_nombre(rec['nombre']))
        csv_meta = meta_lookup.get(rec['nombre'], {})
        for k in ('fecha','num_sentencia','expediente','partes','ponente',
                  'procedimiento','decision','url_tsj','descripcion','extracto'):
            if csv_meta.get(k):
                doc[k] = csv_meta[k]

        doc['texto_completo'] = texto
        doc['texto_busqueda'] = generar_texto_busqueda(doc, texto)
        doc['timestamp'] = firestore.SERVER_TIMESTAMP

        fs_set(doc_id, doc)

        with stats_lock:
            stats['ok'] += 1
        return True
    except Exception:
        with stats_lock:
            stats['fail'] += 1
        return False

# ============================================================
# PUBLICAR EN FIREBASE HOSTING
# ============================================================
def publicar():
    print("📤 Publicando en Firebase Hosting...")
    token = os.environ.get('FIREBASE_TOKEN')
    cmd = ['firebase', 'deploy', '--only', 'hosting']
    if token:
        cmd += ['--token', token]
    try:
        subprocess.run(cmd, check=True, capture_output=True, text=True, cwd=WORK_DIR)
        print("   ✅ Publicado")
        return True
    except subprocess.CalledProcessError as e:
        print(f"   ❌ Error publicando: {e.stderr[:300] if e.stderr else e}")
        return False

# ============================================================
# MAIN
# ============================================================
def main():
    limite = int(os.environ.get('LIMITE', '0') or 0)
    lote   = int(os.environ.get('LOTE', '5000') or 5000)

    os.makedirs(ASSETS, exist_ok=True)

    if not os.path.exists(LOGO_LOCAL):
        try:
            r = requests.get(LOGO_URL, timeout=30)
            if r.status_code == 200:
                with open(LOGO_LOCAL, 'wb') as f:
                    f.write(r.content)
                print(f"🖼️ Logo descargado ({len(r.content)//1024} KB)")
        except Exception as e:
            print(f"⚠️ No se pudo descargar el logo: {e}")

    print("📊 Leyendo documentos existentes en Firestore...")
    db = get_db()
    existentes = set()
    try:
        for snap in db.collection('documentos').select([]).stream():
            existentes.add(snap.id)
    except Exception as e:
        print(f"   ⚠️ No se pudo leer Firestore: {e}")
    print(f"   Ya existen {len(existentes)} documentos")

    t0 = time.time()
    nuevos_desde_deploy = 0

    for nombre, folder_id, tipo, sala in FOLDERS:
        if not folder_id or folder_id.startswith('PON_AQUI'):
            print(f"\n⚠️ {nombre}: ID de carpeta pendiente, se omite")
            continue
        print(f"\n📂 {nombre} ({tipo}/{sala})")

        records = listar_htmls(folder_id)
        meta_lookup = cargar_metadata_csv(folder_id)
        print(f"   Archivos: {len(records)} | metadata.csv: {len(meta_lookup)} filas")

        pendientes = [r for r in records if r['nombre'][:-5] not in existentes]
        if limite > 0:
            pendientes = pendientes[:limite]
        print(f"   Pendientes: {len(pendientes)}")
        if not pendientes:
            continue

        with concurrent.futures.ThreadPoolExecutor(max_workers=MAX_WORKERS) as ex:
            futs = {ex.submit(procesar, r, tipo, sala, meta_lookup): r for r in pendientes}
            done = 0
            for fut in concurrent.futures.as_completed(futs):
                done += 1
                try:
                    ok = fut.result()
                    if ok: nuevos_desde_deploy += 1
                except Exception:
                    pass
                if done % 50 == 0:
                    el = (time.time()-t0)/60
                    print(f"   ⚙️ {done}/{len(pendientes)} | ✅{stats['ok']} ❌{stats['fail']} | {done/el:.0f}/min")
                if nuevos_desde_deploy >= lote:
                    fs_flush()
                    publicar()
                    nuevos_desde_deploy = 0

    fs_flush()
    if nuevos_desde_deploy > 0:
        publicar()

    el = (time.time()-t0)/60
    print(f"\n{'='*60}")
    print(f"✅ COMPLETADO en {el:.1f} min")
    print(f"   Subidos: {stats['ok']} | Fallos: {stats['fail']}")
    print(f"{'='*60}")

if __name__ == '__main__':
    main()
