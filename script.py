#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os, re, io, csv, json, time, subprocess, threading, functools
import concurrent.futures
import requests
from googleapiclient.discovery import build
from googleapiclient.http import MediaIoBaseDownload
from googleapiclient.errors import HttpError
from google.oauth2 import service_account
import firebase_admin
from firebase_admin import credentials, firestore

# SALIDA SIN BÚFER: cada print se muestra al instante
print = functools.partial(print, flush=True)

WORK_DIR = os.getcwd()
PUB = os.path.join(WORK_DIR, 'public')
ASSETS = os.path.join(PUB, 'assets')
LOGO_URL = 'https://historico.tsj.gob.ve/graficos/encabezadotsj.jpg'
LOGO_LOCAL = os.path.join(ASSETS, 'logo-tsj.jpg')

MAX_WORKERS = 4      # runners tienen 2 vCPU; menos workers = menos pelea por CPU
BATCH_FS = 50        # commit a Firestore cada 50 docs (ves progreso pronto)

FOLDERS = [
    ('Sala_Constitucional',         '1kGbRPySacSvqZITKQ0ll4-T-O3Ns6ieN', 'sentencia',     'constitucional'),
    ('Sala_Penal',                  '1AlySvmxbfCsMV07Rs24FUt6VFQSPgPY1', 'sentencia',     'penal'),
    ('Sustanciacion_Constitucional','1gAXDSFKVAzVCKAXCBVAraKMM7xCXblD8', 'sentencia',     'sustanciacion'),
    ('Sala_Penal_Juris',            '1BL50vMykxVDiCFIQJuYlhcbvlCoD5afg', 'jurisprudencia','penal'),
    ('Sala_Constitucional_Juris',   '1Ais0FpCjLPOcwOCe8I86hgbGWYj2CQFK', 'jurisprudencia','constitucional'),
]

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
            firebase_admin.initialize_app(credentials.Certificate(CREDS_PATH))
        _db = firestore.client()
    return _db

_fs_lock = threading.Lock()
_fs_batch = None
_fs_count = 0
def fs_set(doc_id, data):
    global _fs_batch, _fs_count
    db = get_db()
    with _fs_lock:
        if _fs_batch is None: _fs_batch = db.batch()
        _fs_batch.set(db.collection('documentos').document(doc_id), data, merge=True)
        _fs_count += 1
        if _fs_count >= BATCH_FS:
            _fs_batch.commit(); _fs_batch = None; _fs_count = 0
            print(f"   💾 Commit a Firestore ({BATCH_FS} docs) | total ok={stats['ok']}")
def fs_flush():
    global _fs_batch, _fs_count
    with _fs_lock:
        if _fs_batch is not None and _fs_count > 0:
            _fs_batch.commit(); _fs_batch = None; _fs_count = 0
            print(f"   💾 Commit final a Firestore | total ok={stats['ok']}")

MAPA_ENC = {'Ã¡':'á','Ã©':'é','Ã­':'í','Ã³':'ó','Ãº':'ú','Ã±':'ñ','Ã‘':'Ñ','Â°':'°','Â¿':'¿','Â¡':'¡','â€™':'’','â€˜':'‘','â€œ':'"','â€':'"','â€“':'–','â€"':'—','â€¦':'…','ï¿½':'ñ'}
def rel_logo(p): return os.path.relpath(LOGO_LOCAL, os.path.dirname(p)).replace(os.sep,'/')
def curar(raw, logo_rel):
    try: t = raw.decode('utf-8')
    except UnicodeDecodeError: t = raw.decode('windows-1252', errors='replace')
    if 'Ã' in t or 'â€' in t or 'ï¿½' in t:
        try: t = t.encode('windows-1252').decode('utf-8')
        except Exception:
            for k,v in MAPA_ENC.items(): t = t.replace(k,v)
    t = re.sub(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]','',t).replace('\u00ad','')
    t = re.sub(r'<\?xml[^>]*\?>','',t)
    t = re.sub(r'<meta[^>]*charset[^>]*>','<meta charset="UTF-8">',t,flags=re.I)
    if 'charset' not in t.lower(): t = re.sub(r'(<head[^>]*>)',r'\1\n<meta charset="UTF-8">',t,count=1,flags=re.I)
    if 'noindex' not in t.lower(): t = re.sub(r'(<head[^>]*>)',r'\1\n<meta name="robots" content="noindex,nofollow,noarchive,nosnippet">',t,count=1,flags=re.I)
    t = re.sub(r'<img[^>]*src=["\'][^"\']*encabezado[^"\']*["\'][^>]*>',f'<img src="{logo_rel}" alt="TSJ" style="max-width:100%">',t,flags=re.I)
    if 'logo-tsj' not in t.lower() and 'encabezadotsj' not in t.lower():
        t = re.sub(r'(<body[^>]*>)',r'\1\n<div align="center" style="margin:8px 0"><img src="'+logo_rel+r'" alt="TSJ" style="max-width:100%"></div>',t,count=1,flags=re.I)
    return t
def html_a_texto(h):
    t = re.sub(r'<script[\s\S]*?</script>','',h,flags=re.I)
    t = re.sub(r'<style[\s\S]*?</style>','',t,flags=re.I)
    t = re.sub(r'<[^>]+>',' ',t)
    t = re.sub(r'&nbsp;?',' ',t); t = re.sub(r'&amp;','&',t); t = re.sub(r'&[a-z]+;',' ',t)
    return re.sub(r'\s+',' ',t).strip()

def generar_pdf(hp, pp):
    try:
        subprocess.run(['wkhtmltopdf','-q','--enable-local-file-access','--encoding','UTF-8',
            '--load-error-handling','ignore','--load-media-error-handling','ignore',
            '--no-stop-slow-scripts','--javascript-delay','0',hp,pp],
            capture_output=True, timeout=60, check=False)
        return os.path.exists(pp) and os.path.getsize(pp)>0
    except Exception:
        return False   # PDF opcional: si falla, no detiene el pipeline

MESES = {'enero':1,'febrero':2,'marzo':3,'abril':4,'mayo':5,'junio':6,'julio':7,'agosto':8,'septiembre':9,'octubre':10,'noviembre':11,'diciembre':12}
def normalizar_fecha(s):
    if not s: return ''
    s = s.strip()
    m = re.match(r'(\d{1,2})/(\d{1,2})/(\d{4})', s)
    if m: return f"{m.group(3)}-{int(m.group(2)):02d}-{int(m.group(1)):02d}"
    m = re.search(r'(\d{1,2})\s+de\s+([A-Za-záéíóúñ]+)\s+de\s+(\d{4})', s) or re.search(r',?\s*(\d{1,2})\s+([A-Za-záéíóúñ]+)\s+de\s+(\d{4})', s)
    if m:
        mes = MESES.get(m.group(2).lower(),0)
        if mes: return f"{m.group(3)}-{mes:02d}-{int(m.group(1)):02d}"
    return s

def normalizar_fila(row):
    d = {}
    for k,v in row.items():
        if v is None: continue
        v = str(v).strip()
        if not v: continue
        kl = (k or '').strip().lower()
        if kl in ('archivo','file','nombre','name'): d['archivo']=v
        elif 'url' in kl or 'enlace' in kl or 'link' in kl: d['url_tsj']=v
        elif 'fecha' in kl: d['fecha']=normalizar_fecha(v)
        elif 'num' in kl or kl in ('n°','no','numero'): d['num_sentencia']=v
        elif 'exp' in kl: d['expediente']=v
        elif 'ponente' in kl or 'magistrado' in kl: d['ponente']=v
        elif 'parte' in kl or 'demand' in kl or 'actor' in kl or 'recurrente' in kl or 'querell' in kl or 'acusad' in kl: d['partes']=(d.get('partes','')+' '+v).strip()
        elif 'procedimiento' in kl or 'recurso' in kl or 'accion' in kl or kl=='tipo': d['procedimiento']=v
        elif 'decision' in kl or 'fallo' in kl or 'veredicto' in kl: d['decision']=v
        elif 'extracto' in kl or 'criterio' in kl or 'resumen' in kl or 'descripcion' in kl or 'motiva' in kl or 'texto' in kl:
            if len(v)>len(d.get('extracto','')): d['extracto']=v
    return d if d.get('archivo') else None

def cargar_metadata_csv(folder_id):
    lookup = {}
    try:
        res = get_drive().files().list(q=f"'{folder_id}' in parents and name='metadata.csv' and trashed=false",fields="files(id)").execute()
        fs = res.get('files',[])
        if not fs: return lookup
        buf = io.BytesIO(); down = MediaIoBaseDownload(buf, get_drive().files().get_media(fileId=fs[0]['id']))
        done=False
        while not done: _,done = down.next_chunk()
        for row in csv.DictReader(io.StringIO(buf.getvalue().decode('utf-8',errors='replace'))):
            m = normalizar_fila(row)
            if m and m.get('archivo'): lookup[m['archivo']]=m
    except Exception as e:
        print(f"   ⚠️ metadata.csv: {e}")
    return lookup

def listar_htmls(folder_id):
    out=[]; pt=None
    while True:
        try:
            res = get_drive().files().list(q=f"'{folder_id}' in parents and mimeType='text/html' and trashed=false",fields="files(id,name),nextPageToken",pageSize=1000,pageToken=pt).execute()
        except HttpError as e:
            print(f"   ❌ listando: {e}"); break
        out += [{'id':f['id'],'nombre':f['name']} for f in res.get('files',[])]
        pt = res.get('nextPageToken')
        if not pt: break
    return out

def prueba_drive(folder_id):
    try:
        res = get_drive().files().list(q=f"'{folder_id}' in parents and trashed=false",fields="files(id)",pageSize=1).execute()
        return len(res.get('files',[]))
    except Exception as e:
        print(f"❌ Error acceso Drive: {e}"); return 0

def descargar(did):
    for _ in range(3):
        try:
            buf=io.BytesIO(); down=MediaIoBaseDownload(buf,get_drive().files().get_media(fileId=did))
            done=False
            while not done: _,done=down.next_chunk()
            return buf.getvalue()
        except Exception: time.sleep(2)
    return None

def parsear_nombre(n):
    m = re.match(r'^(\d{4})_(\d+)_exp_(.+)\.html$', n)
    if m: return {'num_sentencia':m.group(2),'expediente':m.group(3)}
    m2 = re.match(r'^resolucion_(.+)\.html$', n)
    if m2: return {'num_sentencia':m2.group(1)}
    return {}

def generar_texto_busqueda(meta, texto):
    p = [meta.get('tipo',''),meta.get('sala',''),meta.get('procedimiento',''),meta.get('decision',''),
         meta.get('partes',''),meta.get('ponente',''),meta.get('expediente',''),meta.get('num_sentencia',''),
         (meta.get('fecha','') or '')[:4],' '.join((meta.get('extracto','') or '').split()[:100])]
    return ' '.join([x for x in p if x] + texto.split()[:500])

stats_lock = threading.Lock()
stats = {'ok':0,'fail':0,'pdf':0}

def heartbeat(t0):
    while True:
        time.sleep(30)
        el=(time.time()-t0)/60
        print(f"💓 vivo | {el:.1f} min | ok={stats['ok']} fail={stats['fail']} pdf={stats['pdf']}")

def procesar(rec, tipo, sala, meta_lookup, verbose):
    doc_id = rec['nombre'][:-5]
    try:
        raw = descargar(rec['id'])
        if not raw:
            if verbose: print(f"   ⚠️ sin descargar: {rec['nombre']}")
            return False
        sub = 'resoluciones' if tipo=='resolucion' else (tipo+'s')
        hp = os.path.join(PUB,'html',sub,sala,rec['nombre'])
        pp = os.path.join(PUB,'pdf',sub,sala,doc_id+'.pdf')
        os.makedirs(os.path.dirname(hp),exist_ok=True); os.makedirs(os.path.dirname(pp),exist_ok=True)
        limpio = curar(raw, rel_logo(hp))
        with open(hp,'w',encoding='utf-8') as f: f.write(limpio)
        texto = html_a_texto(limpio)
        if generar_pdf(hp,pp):
            with stats_lock: stats['pdf']+=1
        doc = {'id':doc_id,'tipo':tipo,'sala':sala}; doc.update(parsear_nombre(rec['nombre']))
        cm = meta_lookup.get(rec['nombre'],{})
        for k in ('fecha','num_sentencia','expediente','partes','ponente','procedimiento','decision','url_tsj','descripcion','extracto'):
            if cm.get(k): doc[k]=cm[k]
        doc['texto_completo']=texto
        doc['texto_busqueda']=generar_texto_busqueda(doc,texto)
        doc['timestamp']=firestore.SERVER_TIMESTAMP
        fs_set(doc_id,doc)
        with stats_lock: stats['ok']+=1
        if verbose: print(f"   ✅ {doc_id}")
        return True
    except Exception as e:
        with stats_lock: stats['fail']+=1
        if verbose: print(f"   ❌ {doc_id}: {e}")
        return False

def publicar():
    print("📤 Publicando en Firebase Hosting...")
    cmd=['firebase','deploy','--only','hosting']
    tok=os.environ.get('FIREBASE_TOKEN')
    if tok: cmd+=['--token',tok]
    try:
        subprocess.run(cmd,check=True,capture_output=True,text=True,cwd=WORK_DIR)
        print("   ✅ Publicado en Hosting")
        return True
    except subprocess.CalledProcessError as e:
        print(f"   ❌ deploy: {(e.stderr or '')[:300]}")
        return False

def main():
    limite=int(os.environ.get('LIMITE','0') or 0)
    lote=int(os.environ.get('LOTE','1000') or 1000)
    os.makedirs(ASSETS,exist_ok=True)
    print("🚀 Iniciando pipeline...")

    if not os.path.exists(LOGO_LOCAL):
        try:
            r=requests.get(LOGO_URL,timeout=30)
            if r.status_code==200:
                open(LOGO_LOCAL,'wb').write(r.content); print("🖼️ Logo OK")
        except Exception as e: print(f"⚠️ logo: {e}")

    n = prueba_drive(FOLDERS[0][1])
    print(f"🔎 Acceso Drive: {n} archivo(s) en {FOLDERS[0][0]}")
    if n==0:
        print("❌ La cuenta de servicio NO ve Drive. Comparte las carpetas con su email (Viewer).")
        return

    t0=time.time()
    threading.Thread(target=heartbeat,args=(t0,),daemon=True).start()

    print("📊 Leyendo existentes en Firestore...")
    db=get_db(); existentes=set()
    try:
        for snap in db.collection('documentos').select([]).stream(): existentes.add(snap.id)
    except Exception as e: print(f"⚠️ Firestore: {e}")
    print(f"   existentes: {len(existentes)}")

    nuevos=0
    for nombre,folder_id,tipo,sala in FOLDERS:
        print(f"\n📂 {nombre} ({tipo}/{sala})")
        records=listar_htmls(folder_id)
        meta=cargar_metadata_csv(folder_id)
        print(f"   archivos={len(records)} metadata={len(meta)}")
        pend=[r for r in records if r['nombre'][:-5] not in existentes]
        if limite>0: pend=pend[:limite]
        print(f"   pendientes={len(pend)}")
        if not pend: continue
        with concurrent.futures.ThreadPoolExecutor(max_workers=MAX_WORKERS) as ex:
            futs={ex.submit(procesar,r,tipo,sala,meta,i<3):r for i,r in enumerate(pend)}
            done=0
            for fut in concurrent.futures.as_completed(futs):
                done+=1
                try:
                    if fut.result(): nuevos+=1
                except Exception: pass
                if done%10==0:
                    el=(time.time()-t0)/60
                    print(f"   ⚙️ {done}/{len(pend)} ok={stats['ok']} fail={stats['fail']} pdf={stats['pdf']} | {done/el:.0f}/min")
                if nuevos>=lote:
                    fs_flush(); publicar(); nuevos=0
    fs_flush()
    if nuevos>0: publicar()
    print(f"\n✅ FIN en {(time.time()-t0)/60:.1f} min | ok={stats['ok']} fail={stats['fail']} pdf={stats['pdf']}")

if __name__=='__main__':
    main()
