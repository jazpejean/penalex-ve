#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os, re, io, csv, json, time, gzip, subprocess, tempfile
import threading, functools, concurrent.futures
import requests, urllib3, boto3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
from googleapiclient.discovery import build
from googleapiclient.http import MediaIoBaseDownload
from googleapiclient.errors import HttpError
from google.oauth2 import service_account
from supabase import create_client

print = functools.partial(print, flush=True)

MAX_WORKERS = 8
BATCH = 200
R2_BUCKET = 'penalex-ve'
LOGO_URL = 'https://pub-a6e0bfa2e9174e91b031ae28c0667009.r2.dev/assets/logo.jpg'

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
    if not hasattr(_local,'drv'):
        creds = service_account.Credentials.from_service_account_file(
            CREDS_PATH, scopes=['https://www.googleapis.com/auth/drive.readonly'])
        _local.drv = build('drive','v3',credentials=creds,cache_discovery=False)
    return _local.drv

def get_r2():
    if not hasattr(_local,'r2'):
        _local.r2 = boto3.client('s3',
            endpoint_url=f"https://{os.environ['CLOUDFLARE_ACCOUNT_ID']}.r2.cloudflarestorage.com",
            aws_access_key_id=os.environ['R2_ACCESS_KEY_ID'],
            aws_secret_access_key=os.environ['R2_SECRET_ACCESS_KEY'],
            region_name='auto')
    return _local.r2

def r2_put(key, data, ctype, compress=False):
    extra={}
    if compress:
        data=gzip.compress(data,6); extra['ContentEncoding']='gzip'
    for _ in range(3):
        try:
            get_r2().put_object(Bucket=R2_BUCKET,Key=key,Body=data,ContentType=ctype,**extra)
            return True
        except Exception: time.sleep(2)
    return False

def r2_exists(key):
    try:
        get_r2().head_object(Bucket=R2_BUCKET, Key=key)
        return True
    except Exception:
        return False

_sb=None
def get_sb():
    global _sb
    if _sb is None:
        _sb=create_client(os.environ['SUPABASE_URL'],os.environ['SUPABASE_SERVICE_KEY'])
    return _sb

_sb_buf=[]; _sb_lock=threading.Lock()

def _clean(v):
    if isinstance(v,str):
        return re.sub(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]','',v).replace('\ufffd','')
    return v

def _flush_sb():
    global _sb_buf
    if not _sb_buf: return
    rows=[{k:_clean(v) for k,v in r.items()} for r in _sb_buf]
    _sb_buf=[]
    try: get_sb().table('documentos').upsert(rows,on_conflict='id').execute()
    except Exception as e: print(f"⚠️ upsert: {e}")

def fs_set(doc_id,data):
    global _sb_buf
    with _sb_lock:
        _sb_buf.append(data)
        if len(_sb_buf)>=BATCH: _flush_sb()

def fs_flush():
    with _sb_lock: _flush_sb()

MAPA_ENC={'Ã¡':'á','Ã©':'é','Ã­':'í','Ã³':'ó','Ãº':'ú','Ã±':'ñ','Ã‘':'Ñ','Â°':'°','Â¿':'¿','Â¡':'¡','â€™':'’','â€˜':'‘','â€œ':'"','â€':'"','â€“':'–','â€"':'—','â€¦':'…','ï¿½':'','Ã':'í'}
def corregir_encoding(t):
    if not isinstance(t,str): return str(t)
    t=re.sub(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]','',t).replace('\ufffd','')
    if 'Ã' in t or 'â€' in t or 'Â' in t:
        try: return t.encode('windows-1252',errors='ignore').decode('utf-8',errors='ignore')
        except Exception:
            for k,v in MAPA_ENC.items(): t=t.replace(k,v)
    return t

def asegurar_logo():
    if r2_exists('assets/logo.jpg'):
        print(f"🖼️ Logo ya en R2: {LOGO_URL}")
        return
    try:
        r=requests.get('https://historico.tsj.gob.ve/graficos/encabezadotsj.jpg',timeout=20,verify=False)
        if r.status_code==200 and len(r.content)>1000:
            r2_put('assets/logo.jpg', r.content, 'image/jpeg')
            print(f"🖼️ Logo subido a R2: {LOGO_URL}")
        else:
            print(f"⚠️ Logo: HTTP {r.status_code}")
    except Exception as e:
        print(f"⚠️ logo TSJ: {e}")

def curar(raw):
    try: t=raw.decode('utf-8')
    except UnicodeDecodeError: t=raw.decode('latin-1')
    t=corregir_encoding(t)
    # Solo reemplazar la ruta del logo con la URL completa de R2
    t=re.sub(r'/graficos/encabezadotsj\.jpg', LOGO_URL, t, flags=re.I)
    return t

def html_a_texto(h):
    t=re.sub(r'<[^>]+>',' ',h)
    t=re.sub(r'&nbsp;?',' ',t); t=re.sub(r'&amp;','&',t); t=re.sub(r'&[a-z]+;',' ',t)
    return re.sub(r'\s+',' ',t).strip()

def extraer_url_tsj(html):
    for pat in (r'<meta[^>]*property=["\']og:url["\'][^>]*content=["\']([^"\']+)["\']',
                r'<link[^>]*rel=["\']canonical["\'][^>]*href=["\']([^"\']+)["\']'):
        m=re.search(pat,html,re.I)
        if m and 'tsj.gob.ve' in m.group(1): return m.group(1).strip()
    m=re.search(r'https?://[^"\'\s<>]*historico\.tsj\.gob\.ve/(?:decisiones|informacion)/[^"\'\s<>]+\.[Hh][Tt][Mm][Ll]?',html)
    return m.group(0) if m else ''

def generar_pdf(hp,pp):
    try:
        subprocess.run(['wkhtmltopdf','-q','--enable-local-file-access','--encoding','UTF-8',
            '--page-size','A4','--margin-top','15','--margin-bottom','15','--margin-left','15','--margin-right','15',
            '--load-error-handling','ignore','--load-media-error-handling','ignore',
            '--no-stop-slow-scripts','--javascript-delay','0','--disable-external-links',
            hp,pp],capture_output=True,timeout=60,check=False)
        return os.path.exists(pp) and os.path.getsize(pp)>0
    except Exception: return False

MESES={'enero':1,'febrero':2,'marzo':3,'abril':4,'mayo':5,'junio':6,'julio':7,'agosto':8,'septiembre':9,'octubre':10,'noviembre':11,'diciembre':12}
def normalizar_fecha(s):
    if not s: return ''
    s=s.strip()
    m=re.match(r'(\d{1,2})/(\d{1,2})/(\d{4})',s)
    if m: return f"{m.group(3)}-{int(m.group(2)):02d}-{int(m.group(1)):02d}"
    m=re.search(r'(\d{1,2})\s+de\s+([A-Za-záéíóúñ]+)\s+de\s+(\d{4})',s)
    if m:
        mes=MESES.get(m.group(2).lower(),0)
        if mes: return f"{m.group(3)}-{mes:02d}-{int(m.group(1)):02d}"
    return s

def normalizar_fila(row):
    d={}
    for k,v in row.items():
        if v is None: continue
        v=str(v).strip()
        if not v: continue
        v=corregir_encoding(v)
        kl=(k or '').strip().lower()
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
    lookup={}
    try:
        res=get_drive().files().list(q=f"'{folder_id}' in parents and name='metadata.csv' and trashed=false",fields="files(id)").execute()
        fs=res.get('files',[])
        if not fs: return lookup
        buf=io.BytesIO(); down=MediaIoBaseDownload(buf,get_drive().files().get_media(fileId=fs[0]['id']))
        done=False
        while not done: _,done=down.next_chunk()
        raw=buf.getvalue()
        try: contenido=raw.decode('utf-8')
        except UnicodeDecodeError: contenido=raw.decode('latin-1')
        for row in csv.DictReader(io.StringIO(corregir_encoding(contenido))):
            m=normalizar_fila(row)
            if m and m.get('archivo'): lookup[m['archivo']]=m
    except Exception as e: print(f"   ⚠️ metadata.csv: {e}")
    return lookup

def listar_htmls(folder_id):
    out=[]; pt=None
    while True:
        try:
            res=get_drive().files().list(q=f"'{folder_id}' in parents and mimeType='text/html' and trashed=false",fields="files(id,name),nextPageToken",pageSize=1000,pageToken=pt).execute()
        except HttpError as e: print(f"   ❌ listando: {e}"); break
        out+=[{'id':f['id'],'nombre':f['name']} for f in res.get('files',[])]
        pt=res.get('nextPageToken')
        if not pt: break
    return out

def prueba_drive(folder_id):
    try:
        res=get_drive().files().list(q=f"'{folder_id}' in parents and trashed=false",fields="files(id)",pageSize=1).execute()
        return len(res.get('files',[]))
    except Exception as e: print(f"❌ Drive: {e}"); return 0

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
    m=re.match(r'^(\d{4})_(\d+)_exp_(.+)\.html$',n)
    if m: return {'num_sentencia':m.group(2),'expediente':m.group(3)}
    m2=re.match(r'^resolucion_(.+)\.html$',n)
    if m2: return {'num_sentencia':m2.group(1)}
    return {}

def generar_texto_busqueda(meta,texto):
    p=[meta.get('tipo',''),meta.get('sala',''),meta.get('procedimiento',''),meta.get('decision',''),
       meta.get('partes',''),meta.get('ponente',''),meta.get('expediente',''),meta.get('num_sentencia',''),
       (meta.get('fecha','') or '')[:4],' '.join((meta.get('extracto','') or '').split()[:100])]
    return ' '.join([x for x in p if x]+texto.split()[:500])

CAMPOS_LIMPIAR=['partes','ponente','procedimiento','decision','extracto','texto_busqueda','url_tsj','expediente','num_sentencia','fecha']

def modo_limpiar():
    print("🧹 MODO LIMPIAR: arreglando datos viejos en Supabase...")
    docs=[]; off=0
    while True:
        r=get_sb().table('documentos').select('*').range(off,off+999).execute()
        docs.extend(r.data)
        if len(r.data)<1000: break
        off+=1000
    print(f"   {len(docs)} documentos")
    batch=[]; act=0
    for i,doc in enumerate(docs):
        up={}
        for c in CAMPOS_LIMPIAR:
            if c in doc and doc[c]:
                cl=corregir_encoding(doc[c])
                if cl!=doc[c]: up[c]=cl
        if up:
            up['id']=doc['id']; batch.append(up); act+=1
        if len(batch)>=100:
            get_sb().table('documentos').upsert(batch,on_conflict='id').execute()
            print(f"   ✅ {i+1}/{len(docs)}")
            batch=[]; time.sleep(0.3)
    if batch:
        get_sb().table('documentos').upsert(batch,on_conflict='id').execute()
    print(f"✅ Limpieza completa: {act} actualizados de {len(docs)}")

stats_lock=threading.Lock()
stats={'ok':0,'fail':0,'url':0,'pdf':0}
def heartbeat(t0):
    while True:
        time.sleep(30)
        print(f"💓 vivo | {(time.time()-t0)/60:.1f} min | ok={stats['ok']} fail={stats['fail']} url={stats['url']} pdf={stats['pdf']}")

def procesar(rec,tipo,sala,meta_lookup,modo,verbose):
    doc_id=rec['nombre'][:-5]
    try:
        raw=descargar(rec['id'])
        if not raw: return False
        limpio=curar(raw)
        texto=html_a_texto(limpio)
        sub='resoluciones' if tipo=='resolucion' else tipo+'s'

        if modo=='pdf':
            with tempfile.TemporaryDirectory() as td:
                hp=os.path.join(td,rec['nombre']); pp=os.path.join(td,doc_id+'.pdf')
                with open(hp,'w',encoding='utf-8') as f: f.write(limpio)
                if generar_pdf(hp,pp):
                    with open(pp,'rb') as f:
                        r2_put(f'pdf/{sub}/{sala}/{doc_id}.pdf',f.read(),'application/pdf')
                    get_sb().table('documentos').update({'tiene_pdf':True}).eq('id',doc_id).execute()
                    with stats_lock: stats['pdf']+=1
            with stats_lock: stats['ok']+=1
            return True

        r2_put(f'html/{sub}/{sala}/{rec["nombre"]}',limpio.encode('utf-8'),'text/html; charset=utf-8',compress=True)
        r2_put(f'txt/{sub}/{sala}/{doc_id}.txt',texto.encode('utf-8'),'text/plain; charset=utf-8',compress=True)
        doc={'id':doc_id,'tipo':tipo,'sala':sala}; doc.update(parsear_nombre(rec['nombre']))
        cm=meta_lookup.get(rec['nombre'],{})
        for k in ('fecha','num_sentencia','expediente','partes','ponente','procedimiento','decision','url_tsj','extracto'):
            if cm.get(k): doc[k]=cm[k]
        if not doc.get('url_tsj'):
            u=extraer_url_tsj(limpio)
            if u:
                doc['url_tsj']=u
                with stats_lock: stats['url']+=1
        doc['texto_busqueda']=generar_texto_busqueda(doc,texto)
        fs_set(doc_id,doc)
        with stats_lock: stats['ok']+=1
        if verbose: print(f"   ✅ {doc_id}")
        return True
    except Exception as e:
        with stats_lock: stats['fail']+=1
        if verbose: print(f"   ❌ {doc_id}: {e}")
        return False

def main():
    limite=int(os.environ.get('LIMITE','0') or 0)
    modo=os.environ.get('MODO','full')
    print(f"🚀 Pipeline MODO={modo}...")

    if modo=='limpiar':
        modo_limpiar()
        return

    n=prueba_drive(FOLDERS[0][1])
    print(f"🔎 Acceso Drive: {n}")
    if n==0:
        print("❌ Sin acceso a Drive. Comparte carpetas con la cuenta de servicio."); return
    asegurar_logo()
    t0=time.time()
    threading.Thread(target=heartbeat,args=(t0,),daemon=True).start()

    print("📊 Leyendo existentes en Supabase...")
    existentes={}; off=0
    try:
        while True:
            r=get_sb().table('documentos').select('id,tiene_pdf').range(off,off+999).execute()
            for x in r.data: existentes[x['id']]=bool(x.get('tiene_pdf'))
            if len(r.data)<1000: break
            off+=1000
    except Exception as e: print(f"⚠️ Supabase: {e}")
    print(f"   existentes: {len(existentes)}")

    for nombre,folder_id,tipo,sala in FOLDERS:
        print(f"\n📂 {nombre} ({tipo}/{sala})")
        records=listar_htmls(folder_id)
        meta=cargar_metadata_csv(folder_id)
        print(f"   archivos={len(records)} metadata={len(meta)}")
        if modo=='full':
            pend=[r for r in records if r['nombre'][:-5] not in existentes]
        else:
            pend=[r for r in records if existentes.get(r['nombre'][:-5])==False]
        if limite>0: pend=pend[:limite]
        print(f"   pendientes={len(pend)}")
        if not pend: continue
        with concurrent.futures.ThreadPoolExecutor(max_workers=MAX_WORKERS) as ex:
            futs={ex.submit(procesar,r,tipo,sala,meta,modo,i<3):r for i,r in enumerate(pend)}
            done=0
            for fut in concurrent.futures.as_completed(futs):
                done+=1
                try: fut.result()
                except Exception: pass
                if done%50==0:
                    el=(time.time()-t0)/60
                    print(f"   ⚙️ {done}/{len(pend)} ok={stats['ok']} fail={stats['fail']} url={stats['url']} pdf={stats['pdf']} | {done/el:.0f}/min")
    fs_flush()
    print(f"\n✅ FIN en {(time.time()-t0)/60:.1f} min | ok={stats['ok']} fail={stats['fail']} url={stats['url']} pdf={stats['pdf']}")

if __name__=='__main__':
    main()
