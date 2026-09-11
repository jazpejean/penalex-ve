#!/usr/bin/env python3
"""Scraping TSJ con estructura Liferay correcta"""
import os
import sys
import requests
import urllib3
import time
import argparse
from datetime import datetime

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

WORKER_URL = os.environ['WORKER_URL']
INGEST_TOKEN = os.environ['INGEST_TOKEN']

BASE_URL = "https://www.tsj.gob.ve/es/decisiones"

PORTLET_PARAMS = {
    "p_p_id": "displayListaDecision_WAR_NoticiasTsjPorlet612",
    "p_p_lifecycle": "2",
    "p_p_state": "normal",
    "p_p_mode": "view",
    "p_p_cacheability": "cacheLevelPage",
    "p_p_col_id": "column-1",
    "p_p_col_pos": "1",
    "p_p_col_count": "2"
}

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
    "Referer": "https://www.tsj.gob.ve/",
    "Accept": "application/json, text/javascript, */*; q=0.01",
    "X-Requested-With": "XMLHttpRequest"
}

SALAS = {
    'scon': ('Sala Constitucional', '005', 'scon'),
    'scp': ('Sala Penal', '003', 'scp')
}

def obtener_dias(sala_code, anio):
    """Obtiene los días con sentencias usando la estructura Liferay correcta"""
    payload = {
        **PORTLET_PARAMS,
        "endpoint": "/services/WSDecision.HTTPEndpoint",
        "method": "/listDayByAnoSala",
        "SALA": sala_code,
        "ANO": str(anio)
    }
    
    try:
        resp = requests.get(BASE_URL, params=payload, headers=HEADERS, verify=False, timeout=30)
        print(f"    Endpoint response: {resp.status_code}, length: {len(resp.text)}")
        if resp.status_code == 200:
            data = resp.json()
            dias = data.get("coleccion", {}).get("DIA", [])
            if isinstance(dias, dict):
                dias = [dias]
            return dias
    except Exception as e:
        print(f"  Error obteniendo días {sala_code}/{anio}: {e}")
    return []

def obtener_decisiones(sala_code, fecha):
    """Obtiene las decisiones de un día específico"""
    payload = {
        **PORTLET_PARAMS,
        "endpoint": "/services/WSDecision.HTTPEndpoint",
        "method": "/listDecisionByFechaSala",
        "SALA": sala_code,
        "FECHA": fecha
    }
    
    try:
        resp = requests.get(BASE_URL, params=payload, headers=HEADERS, verify=False, timeout=30)
        if resp.status_code == 200:
            data = resp.json()
            sentencias = data.get("coleccion", {}).get("SENTENCIA", [])
            if isinstance(sentencias, dict):
                sentencias = [sentencias]
            return sentencias
    except Exception as e:
        print(f"  Error obteniendo decisiones {fecha}: {e}")
    return []

def descargar_html(ssaladir, nombremes, doc_name):
    """Descarga el HTML de una sentencia"""
    url = f"https://historico.tsj.gob.ve/decisiones/{ssaladir}/{nombremes}/{doc_name}"
    try:
        resp = requests.get(url, verify=False, timeout=30)
        if resp.status_code == 200 and len(resp.content) > 500:
            return resp.text
    except Exception as e:
        print(f"  Error descargando {url}: {e}")
    return None

def enviar_al_worker(url, html, sala):
    """Envía el HTML al Worker de Cloudflare"""
    try:
        resp = requests.post(
            f"{WORKER_URL}/ingest",
            headers={"x-token": INGEST_TOKEN},
            json={"url": url, "html": html, "sala": sala},
            timeout=60
        )
        return resp.status_code == 200
    except Exception as e:
        print(f"  Error enviando al worker: {e}")
    return False

def procesar_sala(sala_nombre, sala_code, sala_dir, anio):
    """Procesa una sala completa para un año"""
    print(f"\n{'='*60}")
    print(f"Procesando: {sala_nombre} ({sala_code}) - Año {anio}")
    print(f"{'='*60}")
    
    dias = obtener_dias(sala_code, anio)
    print(f"Días encontrados: {len(dias)}")
    
    if len(dias) == 0:
        print("⚠️  No se encontraron días. Posibles causas:")
        print("   - Endpoint cambió o requiere autenticación")
        print("   - Sala/año no tiene datos disponibles")
        print("   - Firewall del TSJ bloqueando IPs de GitHub Actions")
        return 0
    
    total_enviadas = 0
    total_errores = 0
    
    for i, dia_info in enumerate(dias, 1):
        fecha = dia_info.get("FECHA", "")
        if not fecha:
            continue
        
        print(f"\n[{i}/{len(dias)}] Fecha: {fecha}")
        
        decisiones = obtener_decisiones(sala_code, fecha)
        print(f"  Decisiones: {len(decisiones)}")
        
        for decision in decisiones:
            ssaladir = decision.get("SSALADIR", "")
            nombremes = decision.get("NOMBREMES", "")
            doc_name = decision.get("SSENTNOMBREDOC", "")
            
            if not all([ssaladir, nombremes, doc_name]):
                total_errores += 1
                continue
            
            url = f"https://historico.tsj.gob.ve/decisiones/{ssaladir}/{nombremes}/{doc_name}"
            html = descargar_html(ssaladir, nombremes, doc_name)
            
            if html:
                if enviar_al_worker(url, html, sala_dir):
                    total_enviadas += 1
                    print(f"    ✓ {doc_name}")
                else:
                    total_errores += 1
                    print(f"    ✗ Error enviando {doc_name}")
            else:
                total_errores += 1
                print(f"    ✗ Error descargando {doc_name}")
            
            time.sleep(0.5)
    
    print(f"\n{'='*60}")
    print(f"Resumen {sala_nombre} {anio}:")
    print(f"  Enviadas: {total_enviadas}")
    print(f"  Errores: {total_errores}")
    print(f"{'='*60}\n")
    
    return total_enviadas

def main():
    parser = argparse.ArgumentParser(description='Scraping TSJ con estructura Liferay')
    parser.add_argument('--sala', type=str, default='scon', 
                       choices=['scon', 'scp', 'ambas'],
                       help='Sala a scrapear (scon, scp, o ambas)')
    parser.add_argument('--anio', type=int, default=datetime.now().year,
                       help='Año a scrapear')
    
    args = parser.parse_args()
    
    print(f"🔧 Argumentos recibidos: sala={args.sala}, anio={args.anio}")
    
    salas_a_procesar = []
    if args.sala == 'ambas':
        salas_a_procesar = [('Sala Constitucional', '005', 'scon'), 
                           ('Sala Penal', '003', 'scp')]
    else:
        if args.sala in SALAS:
            salas_a_procesar = [SALAS[args.sala]]
        else:
            print(f"Error: Sala '{args.sala}' no válida")
            sys.exit(1)
    
    for sala_nombre, sala_code, sala_dir in salas_a_procesar:
        procesar_sala(sala_nombre, sala_code, sala_dir, args.anio)

if __name__ == "__main__":
    main()
