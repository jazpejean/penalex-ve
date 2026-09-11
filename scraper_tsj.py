#!/usr/bin/env python3
"""
SCRAPER TSJ COMPLETO - Todo en un solo script
Scrapea: sentencias + jurisprudencias + resoluciones de todas las salas
"""
import os, sys, json, time, asyncio, argparse, requests
from playwright.async_api import async_playwright
from datetime import datetime

# ============================================================
# CONFIGURACIÓN
# ============================================================
WORKER_URL = os.environ.get('WORKER_URL', 'https://penalex-scraper.ignaciojazpe47.workers.dev')
INGEST_TOKEN = os.environ.get('INGEST_TOKEN', '37c112d5ce886b13f394610f49aed5de')

BASE_DECISIONES = "https://www.tsj.gob.ve/es/decisiones"
BASE_JURISPRUDENCIAS = "https://www.tsj.gob.ve/es/juriprudencias"
BASE_RESOLUCIONES = "https://www.tsj.gob.ve/es/web/tsj/resoluciones"
HISTORICO = "https://historico.tsj.gob.ve"

# Salas principales (sentencias + jurisprudencias)
SALAS_PRINCIPALES = {
    '003': {'nombre': 'Sala de Casación Penal', 'liferay': '5', 'dir': 'scp'},
    '005': {'nombre': 'Sala Constitucional', 'liferay': '1', 'dir': 'scon'},
}

# Estado global
PROGRESO = {'enviadas': 0, 'errores': 0, 'saltadas': 0}
ARCHIVO_PROGRESO = 'progreso_scraping.json'

# ============================================================
# UTILIDADES
# ============================================================
def log(msg: str, tipo: str = "INFO"):
    timestamp = datetime.now().strftime("%H:%M:%S")
    print(f"[{timestamp}] [{tipo}] {msg}", flush=True)

def guardar_progreso():
    try:
        with open(ARCHIVO_PROGRESO, 'w') as f:
            json.dump(PROGRESO, f)
    except:
        pass

def cargar_progreso():
    global PROGRESO
    try:
        if os.path.exists(ARCHIVO_PROGRESO):
            with open(ARCHIVO_PROGRESO, 'r') as f:
                PROGRESO = json.load(f)
            log(f"Progreso cargado: {PROGRESO['enviadas']} enviadas")
    except:
        PROGRESO = {'enviadas': 0, 'errores': 0, 'saltadas': 0}

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
            if PROGRESO['enviadas'] % 10 == 0:
                guardar_progreso()
            return True
        else:
            PROGRESO['errores'] += 1
            log(f"Worker error {resp.status_code}", "WARN")
    except Exception as e:
        PROGRESO['errores'] += 1
        log(f"Error worker: {e}", "ERROR")
    return False

async def fetch_dentro_del_navegador(page, url: str):
    """Hace fetch() DENTRO del navegador (con cookies JSESSIONID)"""
    try:
        result = await page.evaluate('''async (url) => {
            try {
                const resp = await fetch(url, {
                    credentials: 'include',
                    headers: {
                        'X-Requested-With': 'XMLHttpRequest',
                        'Accept': 'application/json, text/javascript, */*; q=0.01'
                    }
                });
                if (!resp.ok) return { error: resp.status };
                const text = await resp.text();
                try {
                    return { data: JSON.parse(text) };
                } catch {
                    return { error: 'no_json', body: text.slice(0, 200) };
                }
            } catch (e) {
                return { error: e.message };
            }
        }''', url)
        return result
    except Exception as e:
        return {"error": str(e)}

# ============================================================
# FASE 1: SENTENCIAS (API Liferay con cookies)
# ============================================================
async def scrape_sentencias(page, sala_id: str, config: dict, anio_start: int, anio_end: int):
    log(f"🏛️  {config['nombre']} ({sala_id}) - SENTENCIAS")
    
    # Inicializar sesión
    await page.goto(BASE_DECISIONES, wait_until="domcontentloaded", timeout=60000)
    await page.wait_for_timeout(3000)
    
    # Inicializar portlet Liferay
    init_url = f"{BASE_DECISIONES}?p_p_id=senderSentencias_WAR_NoticiasTsjPorlet612&p_p_lifecycle=2&p_p_state=normal&p_p_mode=view&endpoint=/services/WSDecision.HTTPEndpoint&method=/listSala"
    await page.goto(init_url, timeout=30000)
    await page.wait_for_timeout(2000)
    
    # Volver a la página principal
    await page.goto(BASE_DECISIONES, wait_until="domcontentloaded", timeout=60000)
    await page.wait_for_timeout(2000)
    
    total = 0
    
    for anio in range(anio_start, anio_end + 1):
        log(f"  📅 Año {anio}...")
        
        # Obtener días con sentencias
        dias_url = f"{BASE_DECISIONES}?p_p_id=displaySentencias_WAR_NoticiasTsjPorlet612&p_p_lifecycle=2&p_p_state=normal&p_p_mode=view&endpoint=/services/WSDecision.HTTPEndpoint&method=/listDayByAnoSala&SALA={config['liferay']}&ANO={anio}"
        
        result = await fetch_dentro_del_navegador(page, dias_url)
        
        if "error" in result:
            log(f"    ❌ Error: {result['error']}", "WARN")
            continue
        
        data = result.get("data", {})
        dias = data.get("coleccion", {}).get("DIA", [])
        if isinstance(dias, dict):
            dias = [dias]
        
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
            
            result2 = await fetch_dentro_del_navegador(page, dec_url)
            if "error" in result2:
                continue
            
            data2 = result2.get("data", {})
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
                
                # Descargar HTML dentro del navegador
                html_result = await page.evaluate('''async (url) => {
                    try {
                        const resp = await fetch(url, { credentials: 'include' });
                        if (!resp.ok) return null;
                        return await resp.text();
                    } catch {
                        return null;
                    }
                }''', url)
                
                if html_result and len(html_result) > 500:
                    if await enviar_al_worker(url, html_result, config['dir'], 'sentencia'):
                        total += 1
                        if total % 10 == 0:
                            log(f"    ✓ {total} sentencias enviadas")
                else:
                    PROGRESO['errores'] += 1
                
                await asyncio.sleep(0.3)
    
    log(f"  ✅ {config['nombre']}: {total} sentencias", "SUCCESS")
    return total

# ============================================================
# FASE 2: JURISPRUDENCIAS
# ============================================================
async def scrape_jurisprudencias(page, sala_id: str, config: dict, anio_start: int, anio_end: int):
    log(f"📚 {config['nombre']} ({sala_id}) - JURISPRUDENCIAS")
    
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
            html_result = await page.evaluate('''async (url) => {
                try {
                    const resp = await fetch(url, { credentials: 'include' });
                    if (!resp.ok) return null;
                    return await resp.text();
                } catch {
                    return null;
                }
            }''', url)
            
            if html_result and len(html_result) > 500:
                if await enviar_al_worker(url, html_result, config['dir'], 'jurisprudencia'):
                    total += 1
            else:
                PROGRESO['errores'] += 1
            
            await asyncio.sleep(0.3)
    
    log(f"  ✅ {config['nombre']}: {total} jurisprudencias", "SUCCESS")
    return total

# ============================================================
# FASE 3: RESOLUCIONES (estructura año/mes, no por sala)
# ============================================================
async def scrape_resoluciones(page, anio_start: int, anio_end: int):
    log(f"📋 RESOLUCIONES - Rango {anio_start}-{anio_end}")
    
    await page.goto(BASE_RESOLUCIONES, wait_until="domcontentloaded", timeout=60000)
    await page.wait_for_timeout(2000)
    
    total = 0
    
    for anio in range(anio_start, anio_end + 1):
        log(f"  📅 Año {anio}...")
        
        try:
            await page.select_option("#select_anos", str(anio))
            await page.wait_for_timeout(2500)
        except:
            log(f"    ❌ Error seleccionando año", "WARN")
            continue
        
        # Obtener meses disponibles
        meses = await page.evaluate('''() => {
            const opciones = Array.from(document.querySelectorAll('#select_meses option'));
            return opciones.map(o => ({value: o.value, text: o.textContent.trim()}));
        }''')
        
        if not meses:
            log(f"    (sin meses)")
            continue
        
        for mes in meses:
            try:
                await page.select_option("#select_meses", mes['value'])
                await page.wait_for_timeout(2000)
                
                # Extraer resoluciones del mes
                resoluciones = await page.evaluate('''() => {
                    const items = [];
                    document.querySelectorAll('[onclick*="showPopUpIFrame"]').forEach(el => {
                        const onclick = el.getAttribute('onclick') || '';
                        const match = onclick.match(/showPopUpIFrame\\('([^']+)',/);
                        if (match) {
                            const texto = el.innerText || '';
                            const numMatch = texto.match(/Resolución N°\\s*:\\s*([^\\n]+)/);
                            const fechaMatch = texto.match(/Fecha:\\s*([^\\n]+)/);
                            items.push({
                                url: match[1],
                                num: numMatch ? numMatch[1].trim() : '',
                                fecha: fechaMatch ? fechaMatch[1].trim() : '',
                                descripcion: texto
                            });
                        }
                    });
                    return items;
                }''')
                
                if not resoluciones:
                    continue
                
                log(f"    {mes['text']}: {len(resoluciones)} resoluciones")
                
                for res in resoluciones:
                    url = res['url']
                    if not url.startswith('http'):
                        url = f"https://www.tsj.gob.ve{url}"
                    
                    # Descargar HTML
                    html_result = await page.evaluate('''async (url) => {
                        try {
                            const resp = await fetch(url, { credentials: 'include' });
                            if (!resp.ok) return null;
                            return await resp.text();
                        } catch {
                            return null;
                        }
                    }''', url)
                    
                    if html_result and len(html_result) > 500:
                        if await enviar_al_worker(url, html_result, 'resoluciones', 'resolucion'):
                            total += 1
                    
                    await asyncio.sleep(0.3)
            
            except Exception as e:
                log(f"    ⚠️ Error en mes {mes['text']}: {e}", "WARN")
                continue
    
    log(f"  ✅ Total resoluciones: {total}", "SUCCESS")
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
    log("🚀 SCRAPER TSJ COMPLETO - TODO EN UNO")
    log("="*70)
    log(f"Tipo: {args.tipo}")
    log(f"Sala: {args.sala}")
    log(f"Rango: {args.anio_start} - {args.anio_end}")
    log(f"Worker: {WORKER_URL}")
    log("="*70)
    
    cargar_progreso()
    
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
            n = await scrape_resoluciones(page, args.anio_start, args.anio_end)
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
    
    if os.path.exists(ARCHIVO_PROGRESO):
        os.remove(ARCHIVO_PROGRESO)

if __name__ == "__main__":
    asyncio.run(main())
