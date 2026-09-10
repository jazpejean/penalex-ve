#!/usr/bin/env python3
"""Scraping híbrido TSJ: GitHub Actions descarga el HTML, el Worker penalex-scraper procesa."""
import os, time, argparse
from datetime import datetime
import requests, urllib3
urllib3.disable_warnings()

BASE   = 'https://historico.tsj.gob.ve/decisiones'
MESES  = ['enero','febrero','marzo','abril','mayo','junio','julio','agosto','septiembre','octubre','noviembre','diciembre']
WORKER = os.environ['WORKER_URL']
TOKEN  = os.environ['INGEST_TOKEN']

S = requests.Session()
S.verify = False
S.headers.update({'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36'})

def get(url, tries=3):
    for i in range(tries):
        try:
            r = S.get(url, timeout=45)
            if r.status_code == 200: return r
            if r.status_code == 404: return None
        except Exception as e:
            print(f'   retry {i+1} {url} -> {e}', flush=True)
            time.sleep(2*(i+1))
    return None

def dias_del_anio(sala, anio):
    r = get(f'{BASE}/listDayByAnoSala?ano={anio}&ssaladir={sala}')
    if not r: return []
    try: j = r.json()
    except Exception: return []
    return j.get('dias') or (j.get('coleccion') or {}).get('DIA') or []

def decisiones(sala, fecha):
    for ep in ('listDecisionByFechaSala', 'listSentenciaByFecha'):
        r = get(f'{BASE}/{ep}?fecha={fecha}&ssaladir={sala}')
        if not r: continue
        try: j = r.json()
        except Exception: continue
        decs = ((j.get('decisiones') or {}).get('coleccion') or {}).get('SENTENCIA') \
            or (j.get('coleccion') or {}).get('SENTENCIA') or []
        if decs: return decs
    return []

def url_de(sala, fecha, d):
    u = d.get('url') or d.get('SSENTURL')
    if u: return u if u.startswith('http') else f'https://historico.tsj.gob.ve{u}'
    doc = d.get('SSENTNOMBREDOC')
    if not doc: return None
    try: mes = MESES[int(fecha.split('/')[1]) - 1]
    except Exception: return None
    return f'{BASE}/{sala}/{mes}/{doc}'

def enviar(url, html, sala):
    try:
        r = requests.post(f'{WORKER}/ingest', headers={'x-token': TOKEN},
                          json={'url': url, 'html': html, 'sala': sala}, timeout=90)
        return r.ok
    except Exception as e:
        print(f'   ingest fail {url} -> {e}', flush=True)
        return False

def procesar(sala, anio, solo_dias=None):
    dias = dias_del_anio(sala, anio)
    if solo_dias: dias = dias[-solo_dias:]
    ok = err = 0
    print(f'-> {sala}/{anio}: {len(dias)} dias con decisiones', flush=True)
    for fecha in dias:
        for d in decisiones(sala, fecha):
            u = url_de(sala, fecha, d)
            if not u: err += 1; continue
            r = get(u)
            if not r: err += 1; continue
            if enviar(u, r.text, sala): ok += 1
            else: err += 1
            time.sleep(0.7)   # cortesia con el servidor del TSJ
        print(f'   {fecha}: ok={ok} err={err}', flush=True)
    print(f'FIN {sala}/{anio}: ok={ok} err={err}', flush=True)

if __name__ == '__main__':
    p = argparse.ArgumentParser()
    p.add_argument('--sala', default='ambas')
    p.add_argument('--anio', default='')
    p.add_argument('--dias-recientes', type=int, default=45)
    a = p.parse_args()
    salas = ['scon','scp'] if a.sala in ('','ambas') else [a.sala]
    anio  = int(a.anio) if a.anio else datetime.now().year
    for sala in salas:
        procesar(sala, anio, None if a.anio else a.dias_recientes)
