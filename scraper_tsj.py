#!/usr/bin/env python3
"""
SCRAPER TSJ COMPLETO - Todo en uno
Scrapea sentencias + jurisprudencias + resoluciones de todas las salas
Enriquece con IA y guarda en Supabase + R2
"""
import os, sys, json, time, asyncio, argparse, requests, hashlib
from playwright.async_api import async_playwright
from datetime import datetime
from typing import Dict, List, Optional

# ============================================================
# CONFIGURACIÓN
# ============================================================
WORKER_URL = os.environ['WORKER_URL']
INGEST_TOKEN = os.environ['INGEST_TOKEN']
CF_AI_TOKEN = os.environ.get('CF_AI_TOKEN', '')  # Para enriquecimiento con IA

BASE_DECISIONES = "https://www.tsj.gob.ve/es/decisiones"
BASE_JURISPRUDENCIAS = "https://www.tsj.gob.ve/es/juriprudencias"
BASE_RESOLUCIONES = "https://www.tsj.gob.ve/es/web/tsj/resoluciones"
HISTORICO = "https://historico.tsj.gob.ve"

# Salas para sentencias y jurisprudencias
SALAS_PRINCIPALES = {
    '003': {'nombre': 'Sala de Casación Penal', 'liferay': '5', 'dir': 'scp'},
    '005': {'nombre': 'Sala Constitucional', 'liferay': '1', 'dir': 'scon'},
}

# Salas para resoluciones
SALAS_RESOLUCIONES = {
    'tplen': {'nombre': 'Sala Plena', 'selector': '#0', 'dir': 'tplen'},
    'jscon': {'nombre': 'Sustanciación Constitucional', 'selector': '#14', 'dir': 'jscon'},
    'scc': {'nombre': 'Sala de Casación Civil', 'selector': '#2', 'dir': 'scc'},
    'scs': {'nombre': 'Sala de Casación Social', 'selector': '#4', 'dir': 'scs'},
    'selec': {'nombre': 'Sala Electoral', 'selector': '#3', 'dir': 'selec'},
    'spa': {'nombre': 'Sala Político-Administrativa', 'selector': '#2', 'dir': 'spa'},
}

# Estado global para progreso
PROGRESO = {'enviadas': 0, 'errores': 0, 'saltadas': 0}

# ============================================================
# UTILIDADES
# ============================================================
def log(msg: str, tipo: str = "INFO"):
    timestamp = datetime.now().strftime("%H:%M:%S")
    print(f"[{timestamp}] [{tipo}] {msg}", flush=True)

async def enviar_al_worker(url: str, html: str, sala: str, tipo: str) -> bool:
    """Envía HTML al Worker para curado y almacenamiento"""
    try:
        resp = requests.post(
            f"{WORKER_URL}/ingest",
            headers={"x-token": INGEST_TOKEN},
            json={"url": url, "html": html, "sala": sala, "tipo": tipo},
            timeout=90
        )
        if resp.status_code == 200:
            PROGRESO['enviadas'] += 1
            return True
        else:
            PROGRESO['errores'] += 1
            log(f"Worker error {resp.status_code}: {url}", "ERROR")
    except Exception as e:
        PROGRESO['errores'] += 1
        log(f"Error enviando {url}: {e}", "ERROR")
    return False

async def descargar_html(page, url: str) -> Optional[str]:
    """Descarga HTML usando la sesión de Playwright"""
    try:
        resp = await page.context.request.get(url, timeout=60000)
        if resp.ok and len(resp.body()) > 500:
            return await resp.text()
    except Exception as e:
        log(f"Error descargando {url}: {e}", "WARN")
    return None

# ============================================================
# FASE 1: SENTENCIAS (Liferay API con cookies)
# ============================================================
async def scrape_sentencias(page, sala_id: str, config: Dict, anio_start: int, anio_end: int):
    log(f"🏛️  {config['nombre']} ({sala_id}) - Sentencias")
    
    # Inicializar sesión con cookies
    await page.goto(BASE_DECISIONES, wait_until="domcontentloaded", timeout=60000)
    await page.wait_for_timeout(2000)
    
    # Inicializar portlet Liferay
    init_url = f"{BASE_DECISIONES}?p_p_id=senderSentencias_WAR_NoticiasTsjPorlet612&p_p_lifecycle=2&p_p_state=normal&p_p_mode=view&endpoint=/services/WSDecision.HTTPEndpoint&method=/listSala"
    await page.goto(init_url, timeout=30000)
    await page.wait_for_timeout(1500)
    
    total = 0
    
    for anio in range(anio_start, anio_end + 1):
        log(f"  📅 Año {anio}...")
        
        # Obtener días con sentencias
        dias_url = f"{BASE_DECISIONES}?p_p_id=displaySentencias_WAR_NoticiasTsjPorlet612&p_p_lifecycle=2&p_p_state=normal&p_p_mode=view&endpoint=/services/WSDecision.HTTPEndpoint&method=/listDayByAnoSala&SALA={config['liferay']}&ANO={anio}"
        
        resp = await page.context.request.get(dias_url, timeout=30000)
        if not resp.ok:
            log(f"    ❌ Error {resp.status}", "WARN")
            continue
        
        try:
            data = await resp.json()
            dias = data.get("coleccion", {}).get("DIA", [])
            if isinstance(dias, dict):
                dias = [dias]
        except:
            log(f"    ❌ Respuesta no JSON", "WARN")
            continue
        
        if not dias:
            log(f"    (sin datos)")
            continue
        
        log(f"    {len(dias)} días con sentencias")
        
        for dia_info in dias:
            fecha = dia_info.get("FECHA", "")
            if not fecha:
                continue
            
            # Obtener decisiones del día
            dec_url = f"{BASE_DECISIONES}?p_p_id=displayListaDecision_WAR_NoticiasTsjPorlet612&p_p_lifecycle=2&p_p_state=normal&p_p_mode=view&endpoint=/services/WSDecision.HTTPEndpoint&method=/listDecisionByFechaSala&SALA={config['liferay']}&FECHA={fecha}"
            
            try:
                resp2 = await page.context.request.get(dec_url, timeout=30000)
                if not resp2.ok:
                    continue
                data2 = await resp2.json()
            except:
                continue
            
            sentencias = data2.get("coleccion", {}).get("SENTENCIA", [])
            if isinstance(sentencias, dict):
                sentencias = [sentencias]
            
            for sent in sentencias:
                ssaladir = sent.get("SSALADIR", "")
                nombremes = sent.get("NOMBREMES", "")
                doc_name = sent.get("SSENTNOMBREDOC", "")
                
                if not all([ssaladir, nombremes, doc_name]):
                    PROGRESO['errores'] += 1
                    continue
                
                url = f"{HISTORICO}/decisiones/{ssaladir}/{nombremes}/{doc_name}"
                html = await descargar_html(page, url)
                
                if html:
                    if await enviar_al_worker(url, html, config['dir'], 'sentencia'):
                        total += 1
                        if total % 10 == 0:
                            log(f"    ✓ {total} sentencias enviadas")
                else:
                    PROGRESO['errores'] += 1
                
                await asyncio.sleep(0.3)
    
    log(f"  ✅ {config['nombre']}: {total} sentencias", "SUCCESS")
    return total

# ============================================================
# FASE 2: JURISPRUDENCIAS (HTML con Playwright)
# ============================================================
async def scrape_jurisprudencias(page, sala_id: str, config: Dict, anio_start: int, anio_end: int):
    log(f"📚 {config['nombre']} ({sala_id}) - Jurisprudencias")
    
    await page.goto(BASE_JURISPRUDENCIAS, wait_until="domcontentloaded", timeout=60000)
    await page.wait_for_timeout(2000)
    
    # Click en pestaña de sala
    selector = '#5' if sala_id == '003' else '#1'
    try:
        await page.click(selector, timeout=10000)
        await page.wait_for_timeout(2000)
    except:
        log(f"  ⚠️ No se pudo click en {selector}", "WARN")
    
    total = 0
    
    for anio in range(anio_start, anio_end + 1):
        log(f"  📅 Año {anio}...")
        
        # Intentar seleccionar año
        try:
            await page.select_option("select[name*='year'], #select_years_juris", str(anio), timeout=5000)
            await page.wait_for_timeout(3000)
        except:
            pass
        
        # Extraer enlaces
        enlaces = await page.evaluate('''() => {
            const items = [];
            document.querySelectorAll('a[href*="historico.tsj"], a[href*="decisiones"]').forEach(a => {
                if (a.href && (a.href.includes('/scp/') || a.href.includes('/scon/'))) {
                    items.push(a.href);
                }
            });
            return [...new Set(items)];
        }''')
        
        if not enlaces:
            log(f"    (sin datos)")
            continue
        
        log(f"    {len(enlaces)} jurisprudencias")
        
        for url in enlaces:
            html = await descargar_html(page, url)
            if html:
                if await enviar_al_worker(url, html, config['dir'], 'jurisprudencia'):
                    total += 1
            else:
                PROGRESO['errores'] += 1
            
            await asyncio.sleep(0.3)
    
    log(f"  ✅ {config['nombre']}: {total} jurisprudencias", "SUCCESS")
    return total

# ============================================================
# FASE 3: RESOLUCIONES (HTML estático con showPopUpIFrame)
# ============================================================
async def scrape_resoluciones(page, sala_id: str, config: Dict, anio_start: int, anio_end: int):
    log(f"📋 {config['nombre']} ({sala_id}) - Resoluciones")
    
    await page.goto(BASE_RESOLUCIONES, wait_until="domcontentloaded", timeout=60000)
    await page.wait_for_timeout(2000)
    
    # Click en pestaña de sala
    try:
        await page.click(config['selector'], timeout=10000)
        await page.wait_for_timeout(2000)
    except:
        log(f"  ⚠️ Sala no disponible: {config['selector']}", "WARN")
        return 0
    
    total = 0
    
    for anio in range(anio_start, anio_end + 1):
        log(f"  📅 Año {anio}...")
        
        url_anio = f"{BASE_RESOLUCIONES}/{anio}"
        try:
            await page.goto(url_anio, wait_until="domcontentloaded", timeout=30000)
            await page.wait_for_timeout(2000)
        except:
            log(f"    ❌ No existe página", "WARN")
            continue
        
        # Extraer resoluciones
        resoluciones = await page.evaluate('''() => {
            const items = [];
            document.querySelectorAll('.resumen-boleta, [onclick*="showPopUp"]').forEach(el => {
                const onclick = el.getAttribute('onclick') || '';
                const match = onclick.match(/showPopUpIFrame\\('([^']+)',/);
                if (match) items.push(match[1]);
            });
            return [...new Set(items)];
        }''')
        
        if not resoluciones:
            log(f"    (sin datos)")
            continue
        
        log(f"    {len(resoluciones)} resoluciones")
        
        for url in resoluciones:
            if not url.startswith('http'):
                url = f"https://www.tsj.gob.ve{url}"
            
            html = await descargar_html(page, url)
            if html:
                if await enviar_al_worker(url, html, config['dir'], 'resolucion'):
                    total += 1
            else:
                PROGRESO['errores'] += 1
            
            await asyncio.sleep(0.3)
    
    log(f"  ✅ {config['nombre']}: {total} resoluciones", "SUCCESS")
    return total

# ============================================================
# MAIN
# ============================================================
async def main():
    parser = argparse.ArgumentParser(description='Scraper TSJ Completo')
    parser.add_argument('--tipo', choices=['sentencias', 'jurisprudencias', 'resoluciones', 'todo'], 
                       default='todo', help='Tipo de documentos a scrapear')
    parser.add_argument('--sala', default='todas', help='Sala específica o "todas"')
    parser.add_argument('--anio-start', type=int, default=2000, help='Año inicio')
    parser.add_argument('--anio-end', type=int, default=2026, help='Año fin')
    args = parser.parse_args()
    
    log("="*70)
    log("🚀 SCRAPER TSJ COMPLETO")
    log("="*70)
    log(f"Tipo: {args.tipo}")
    log(f"Sala: {args.sala}")
    log(f"Rango: {args.anio_start} - {args.anio_end}")
    log(f"Worker: {WORKER_URL}")
    log("="*70)
    
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        context = await browser.new_context(
            ignore_https_errors=True,
            user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120.0.0.0"
        )
        page = await context.new_page()
        
        totales = {'sentencias': 0, 'jurisprudencias': 0, 'resoluciones': 0}
        
        # FASE 1: SENTENCIAS
        if args.tipo in ('sentencias', 'todo'):
            for sala_id, config in SALAS_PRINCIPALES.items():
                if args.sala != 'todas' and args.sala != sala_id:
                    continue
                n = await scrape_sentencias(page, sala_id, config, args.anio_start, args.anio_end)
                totales['sentencias'] += n
        
        # FASE 2: JURISPRUDENCIAS
        if args.tipo in ('jurisprudencias', 'todo'):
            for sala_id, config in SALAS_PRINCIPALES.items():
                if args.sala != 'todas' and args.sala != sala_id:
                    continue
                n = await scrape_jurisprudencias(page, sala_id, config, args.anio_start, args.anio_end)
                totales['jurisprudencias'] += n
        
        # FASE 3: RESOLUCIONES
        if args.tipo in ('resoluciones', 'todo'):
            for sala_id, config in SALAS_RESOLUCIONES.items():
                if args.sala != 'todas' and args.sala != sala_id:
                    continue
                n = await scrape_resoluciones(page, sala_id, config, args.anio_start, args.anio_end)
                totales['resoluciones'] += n
        
        await browser.close()
    
    log("="*70)
    log("🏁 RESULTADOS FINALES", "SUCCESS")
    log("="*70)
    log(f"📜 Sentencias:      {totales['sentencias']}")
    log(f"📚 Jurisprudencias: {totales['jurisprudencias']}")
    log(f"📋 Resoluciones:    {totales['resoluciones']}")
    log(f"📊 TOTAL:           {sum(totales.values())}")
    log(f"✅ Enviadas:        {PROGRESO['enviadas']}")
    log(f"❌ Errores:         {PROGRESO['errores']}")
    log("="*70)

if __name__ == "__main__":
    asyncio.run(main())
