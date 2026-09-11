#!/usr/bin/env python3
import os, sys, json, time, asyncio, argparse, requests, base64
from playwright.async_api import async_playwright
from datetime import datetime

WORKER_URL = os.environ.get('WORKER_URL', 'https://penalex-scraper.ignaciojazpe47.workers.dev')
INGEST_TOKEN = os.environ.get('INGEST_TOKEN', '37c112d5ce886b13f394610f49aed5de')

BASE_DECISIONES = "https://www.tsj.gob.ve/es/decisiones"
BASE_JURISPRUDENCIAS = "https://www.tsj.gob.ve/es/juriprudencias"
BASE_RESOLUCIONES = "https://www.tsj.gob.ve/es/web/tsj/resoluciones"
HISTORICO = "https://historico.tsj.gob.ve"

PROGRESO_FILE = 'progreso.json'
PROGRESO = {'enviadas': 0, 'errores': 0, 'urls_enviadas': set()}

if os.path.exists(PROGRESO_FILE):
    with open(PROGRESO_FILE, 'r') as f:
        data = json.load(f)
        PROGRESO['urls_enviadas'] = set(data.get('urls_enviadas', []))
        PROGRESO['enviadas'] = data.get('enviadas', 0)
        PROGRESO['errores'] = data.get('errores', 0)

def guardar_progreso():
    with open(PROGRESO_FILE, 'w') as f:
        json.dump({
            'urls_enviadas': list(PROGRESO['urls_enviadas']),
            'enviadas': PROGRESO['enviadas'],
            'errores': PROGRESO['errores']
        }, f)

LOGO_R2 = b"https://pub-a6e0bfa2e9174e91b031ae28c0667009.r2.dev/assets/logo.jpg"
LOGOS_TSJ = [
    b"http://historico.tsj.gov.ve/portal/admin/image002.jpg",
    b"https://historico.tsj.gov.ve/portal/admin/image002.jpg",
    b"http://historico.tsj.gob.ve/portal/admin/image002.jpg",
    b"https://historico.tsj.gob.ve/portal/admin/image002.jpg",
    b"http://historico.tsj.gov.ve/portal/admin/image001.jpg",
    b"http://historico.tsj.gob.ve/portal/admin/image001.jpg",
]

def reemplazar_logo_en_bytes(body: bytes) -> bytes:
    for logo_tsj in LOGOS_TSJ:
        body = body.replace(logo_tsj, LOGO_R2)
    return body

def log(msg, tipo="INFO"):
    print(f"[{datetime.now().strftime('%H:%M:%S')}] [{tipo}] {msg}", flush=True)

async def enviar_al_worker(url, body_bytes, sala, tipo):
    if url in PROGRESO['urls_enviadas']:
        return True
    try:
        html_b64 = base64.b64encode(body_bytes).decode('ascii')
        r = requests.post(f"{WORKER_URL}/ingest", headers={"x-token": INGEST_TOKEN},
            json={"url": url, "html_b64": html_b64, "sala": sala, "tipo": tipo}, timeout=90)
        if r.status_code == 200:
            PROGRESO['enviadas'] += 1
            PROGRESO['urls_enviadas'].add(url)
            if PROGRESO['enviadas'] % 10 == 0:
                guardar_progreso()
            return True
        PROGRESO['errores'] += 1
    except:
        PROGRESO['errores'] += 1
    return False

async def seleccionar_sala_y_anio(page, sala_id, anio, base_url):
    """Función centralizada para navegar, seleccionar sala y año de forma robusta"""
    await page.goto(base_url, wait_until="networkidle", timeout=60000)
    await page.wait_for_timeout(3000)
    
    sala_selector = 'li[id="5"]' if sala_id == '003' else 'li[id="1"]'
    texto_sala = "Penal" if sala_id == '003' else "Constitucional"
    
    # Estrategia 1: Selector por ID
    try:
        await page.wait_for_selector(sala_selector, timeout=10000)
        await page.click(sala_selector)
        await page.wait_for_timeout(3000)
    except:
        # Estrategia 2: Por texto
        try:
            await page.wait_for_selector(f"text={texto_sala}", timeout=10000)
            await page.click(f"text={texto_sala}")
            await page.wait_for_timeout(3000)
        except:
            # Estrategia 3: JavaScript directo
            await page.evaluate(f'''() => {{
                const lis = document.querySelectorAll('li[id]');
                for (let li of lis) {{
                    if (li.id === "5" || li.id === "1") {{ li.click(); return; }}
                }}
                const elementos = document.querySelectorAll('*');
                for (let el of elementos) {{
                    if (el.textContent && el.textContent.includes("{'Penal' if sala_id == '003' else 'Constitucional'}")) {{
                        el.click(); return;
                    }}
                }}
            }}''')
            await page.wait_for_timeout(3000)
    
    # Seleccionar año
    try:
        await page.wait_for_selector("select", timeout=10000)
        await page.evaluate(f'''() => {{
            const selects = document.querySelectorAll('select');
            for (let sel of selects) {{
                for (let opt of sel.options) {{
                    if (opt.value === '{anio}') {{
                        sel.value = '{anio}';
                        sel.dispatchEvent(new Event('change'));
                        return true;
                    }}
                }}
            }}
        }}''')
        await page.wait_for_timeout(5000)
        return True
    except Exception as e:
        log(f"    ⚠️ Error seleccionando año {anio}: {e}", "WARN")
        return False

# ============================================================
# FASE 1: SENTENCIAS
# ============================================================
async def scrape_sentencias(page, sala_id, anio_start, anio_end):
    nombre = "Sala Penal" if sala_id == "003" else "Sala Constitucional"
    log(f"🏛️  {nombre} ({sala_id}) - SENTENCIAS")
    
    dias_data, sentencias_data = [], []
    async def handle_response(response):
        try:
            if 'listDayByAnoSala' in response.url:
                try: dias_data.append(await response.json())
                except: pass
            elif 'listDecisionByFechaSala' in response.url:
                try: sentencias_data.append(await response.json())
                except: pass
        except: pass
    
    page.on("response", handle_response)
    total = 0
    
    for anio in range(anio_start, anio_end + 1):
        log(f"  📅 Año {anio}...")
        dias_data.clear()
        sentencias_data.clear()
        
        if not await seleccionar_sala_y_anio(page, sala_id, anio, BASE_DECISIONES):
            continue
        
        dias = []
        for d in dias_data:
            col = d.get("coleccion", {}).get("DIA", [])
            if isinstance(col, dict): col = [col]
            dias.extend(col)
        
        if not dias:
            log(f"    (sin datos)")
            continue
        
        log(f"    {len(dias)} días encontrados")
        
        for idx, dia_info in enumerate(dias, 1):
            fecha = dia_info.get("FECHA", "")
            if not fecha: continue
            
            sentencias_data.clear()
            if idx % 10 == 0:
                log(f"    Progreso: {idx}/{len(dias)} días | {total} nuevas")
            
            try:
                await page.evaluate(f'''() => {{
                    const links = document.querySelectorAll('a');
                    for (let link of links) {{
                        if (link.textContent && link.textContent.includes("{fecha}")) {{
                            link.click(); return;
                        }}
                    }}
                }}''')
                await page.wait_for_timeout(2000)
            except: pass
            
            if not sentencias_data:
                try:
                    await page.evaluate(f'''() => {{
                        if (typeof getDataFromServer === 'function') {{
                            getDataFromServer(function(data) {{ window.__captured_data = data; }}, {{
                                url: "{BASE_DECISIONES}?p_p_id=displayListaDecision_WAR_NoticiasTsjPorlet612&p_p_lifecycle=2&p_p_state=normal&p_p_mode=view&p_p_cacheability=cacheLevelPage",
                                server: {{ endpoint: "/services/WSDecision.HTTPEndpoint", method: "/listDecisionByFechaSala" }},
                                params: {{ SALA: "{sala_id}", FECHA: "{fecha}" }}
                            }});
                        }}
                    }}''')
                    await page.wait_for_timeout(2000)
                    captured = await page.evaluate('() => window.__captured_data || null')
                    if captured: sentencias_data.append(captured)
                except: pass
            
            for sd in sentencias_data:
                sentencias = sd.get("coleccion", {}).get("SENTENCIA", [])
                if isinstance(sentencias, dict): sentencias = [sentencias]
                
                for sent in sentencias:
                    ssaladir, nombremes, doc_name = sent.get("SSALADIR", ""), sent.get("NOMBREMES", ""), sent.get("SSENTNOMBREDOC", "")
                    if not all([ssaladir, nombremes, doc_name]): continue
                    
                    url = f"{HISTORICO}/decisiones/{ssaladir}/{nombremes}/{doc_name}"
                    if url in PROGRESO['urls_enviadas']: continue
                    
                    try:
                        resp = await page.context.request.get(url, timeout=60000)
                        if resp.ok:
                            body_bytes = await resp.body()
                            if len(body_bytes) > 500:
                                if await enviar_al_worker(url, reemplazar_logo_en_bytes(body_bytes), sala_id, 'sentencia'):
                                    total += 1
                    except: pass
                    await asyncio.sleep(0.2)
    
    log(f"  ✅ {nombre}: {total} nuevas sentencias", "SUCCESS")
    return total

# ============================================================
# FASE 2: JURISPRUDENCIAS
# ============================================================
async def scrape_jurisprudencias(page, sala_id, anio_start, anio_end):
    nombre = "Jurisprudencia Penal" if sala_id == "003" else "Jurisprudencia Constitucional"
    log(f"📚 {nombre} ({sala_id})")
    total = 0
    
    for anio in range(anio_start, anio_end + 1):
        log(f"  📅 Año {anio}...")
        if not await seleccionar_sala_y_anio(page, sala_id, anio, BASE_JURISPRUDENCIAS):
            continue
        
        enlaces = await page.evaluate('''() => {
            const items = [];
            document.querySelectorAll('a[href*="historico.tsj"], a[href*="decisiones"]').forEach(a => {
                if (a.href && (a.href.includes('/scp/') || a.href.includes('/scon/'))) items.push(a.href);
            });
            return [...new Set(items)];
        }''')
        
        if not enlaces:
            log(f"    (sin datos)")
            continue
        
        log(f"    {len(enlaces)} jurisprudencias encontradas")
        
        for idx, url in enumerate(enlaces, 1):
            if idx % 20 == 0:
                log(f"    Progreso: {idx}/{len(enlaces)} | {total} nuevas")
            
            if url in PROGRESO['urls_enviadas']: continue
            
            try:
                resp = await page.context.request.get(url, timeout=60000)
                if resp.ok:
                    body_bytes = await resp.body()
                    if len(body_bytes) > 500:
                        if await enviar_al_worker(url, reemplazar_logo_en_bytes(body_bytes), sala_id, 'jurisprudencia'):
                            total += 1
            except: pass
            await asyncio.sleep(0.2)
            
    log(f"  ✅ {nombre}: {total} nuevas jurisprudencias", "SUCCESS")
    return total

# ============================================================
# FASE 3: RESOLUCIONES
# ============================================================
async def scrape_resoluciones(page, anio_start, anio_end):
    log(f"📋 RESOLUCIONES - Rango {anio_start}-{anio_end}")
    await page.goto(BASE_RESOLUCIONES, wait_until="networkidle", timeout=120000)
    await page.wait_for_timeout(5000)
    
    total = 0
    for anio in range(anio_start, anio_end + 1):
        log(f"   Año {anio}...")
        try:
            await page.select_option("#select_anos", str(anio), timeout=10000)
            await page.wait_for_timeout(3000)
        except Exception as e:
            log(f"    ⚠️ Error seleccionando año: {e}", "WARN")
            continue
        
        meses = await page.evaluate('''() => {
            const opciones = Array.from(document.querySelectorAll('#select_meses option'));
            return opciones.map(o => ({value: o.value, text: o.textContent.trim()}));
        }''')
        
        for mes in meses:
            try:
                await page.select_option("#select_meses", mes['value'], timeout=10000)
                await page.wait_for_timeout(2000)
                
                resoluciones = await page.evaluate('''() => {
                    const items = [];
                    document.querySelectorAll('[onclick*="showPopUpIFrame"]').forEach(el => {
                        const onclick = el.getAttribute('onclick') || '';
                        const match = onclick.match(/showPopUpIFrame\\('([^']+)',/);
                        if (match) items.push(match[1]);
                    });
                    return [...new Set(items)];
                }''')
                
                if not resoluciones: continue
                log(f"    {mes['text']}: {len(resoluciones)} resoluciones")
                
                for idx, url in enumerate(resoluciones, 1):
                    if idx % 20 == 0:
                        log(f"      Progreso: {idx}/{len(resoluciones)}")
                    
                    if not url.startswith('http'): url = f"https://www.tsj.gob.ve{url}"
                    if url in PROGRESO['urls_enviadas']: continue
                    
                    try:
                        resp = await page.context.request.get(url, timeout=60000)
                        if resp.ok:
                            body_bytes = await resp.body()
                            if len(body_bytes) > 500:
                                if await enviar_al_worker(url, reemplazar_logo_en_bytes(body_bytes), 'resoluciones', 'resolucion'):
                                    total += 1
                    except: pass
                    await asyncio.sleep(0.2)
            except Exception as e:
                log(f"    ⚠️ Error mes {mes.get('text','')}: {e}", "WARN")
                continue
    
    log(f"  ✅ Total resoluciones nuevas: {total}", "SUCCESS")
    return total

# ============================================================
# MAIN
# ============================================================
async def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--tipo', choices=['sentencias', 'jurisprudencias', 'resoluciones', 'todo'], default='todo')
    parser.add_argument('--sala', default='todas')
    parser.add_argument('--anio-start', type=int, default=2000)
    parser.add_argument('--anio-end', type=int, default=2026)
    args = parser.parse_args()
    
    log("="*70)
    log("🚀 SCRAPER TSJ COMPLETO v3.7 - 3 Fases + Progreso Persistente")
    log("="*70)
    log(f"Tipo: {args.tipo} | Sala: {args.sala} | Rango: {args.anio_start}-{args.anio_end}")
    log(f"URLs ya enviadas (se omitirán): {len(PROGRESO['urls_enviadas'])}")
    
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        context = await browser.new_context(ignore_https_errors=True, user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120.0.0.0")
        page = await context.new_page()
        
        totales = {'sentencias': 0, 'jurisprudencias': 0, 'resoluciones': 0}
        
        if args.tipo in ('sentencias', 'todo'):
            salas = {'003': True, '005': True} if args.sala == 'todas' else {args.sala: True}
            for sala_id in salas:
                totales['sentencias'] += await scrape_sentencias(page, sala_id, args.anio_start, args.anio_end)
        
        if args.tipo in ('jurisprudencias', 'todo'):
            salas = {'003': True, '005': True} if args.sala == 'todas' else {args.sala: True}
            for sala_id in salas:
                totales['jurisprudencias'] += await scrape_jurisprudencias(page, sala_id, args.anio_start, args.anio_end)
        
        if args.tipo in ('resoluciones', 'todo'):
            totales['resoluciones'] += await scrape_resoluciones(page, args.anio_start, args.anio_end)
        
        await browser.close()
    
    guardar_progreso()
    log("="*70)
    log(f"🏁 FINALIZADO | Nuevas: {sum(totales.values())} | Total histórico enviado: {len(PROGRESO['urls_enviadas'])}", "SUCCESS")

if __name__ == "__main__":
    asyncio.run(main())
