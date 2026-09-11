import os, re, json, time, requests
from datetime import datetime
from playwright.async_api import async_playwright
from bs4 import BeautifulSoup

# Configuración
WORKER_URL = os.environ.get('WORKER_URL', 'https://penalex-scraper.ignaciojazpe47.workers.dev')
INGEST_TOKEN = os.environ.get('INGEST_TOKEN', '37c112d5ce886b13f394610f49aed5de')
HISTORICO_BASE_URL = "https://historico.tsj.gob.ve/decisiones"
LOGO_URL = "https://pub-a6e0bfa2e9174e91b031ae28c0667009.r2.dev/assets/logo.jpg"
PROGRESO_FILE = "progreso_scraping.json"
OUTPUT_DIR = "./scraped_tsJ"

os.makedirs(OUTPUT_DIR, exist_ok=True)

SALAS = {
    "Sala_Penal": {"codigo": "003", "selector": "#5", "dir": "scp"},
    "Sala_Constitucional": {"codigo": "005", "selector": "#1", "dir": "scon"}
}

def cargar_progreso():
    if os.path.exists(PROGRESO_FILE):
        with open(PROGRESO_FILE, 'r') as f:
            return json.load(f).get("procesados", [])
    return []

def guardar_progreso(procesados):
    with open(PROGRESO_FILE, 'w') as f:
        json.dump({"procesados": procesados, "ultima_actualizacion": datetime.now().isoformat()}, f)

def corregir_html(html):
    # 1. Encoding: intentar UTF-8, fallback a Windows-1252
    try:
        soup = BeautifulSoup(html, 'html.parser')
    except:
        soup = BeautifulSoup(html.encode('windows-1252', errors='replace').decode('utf-8', errors='replace'), 'html.parser')
    
    # 2. Reemplazar logos
    html_str = str(soup)
    html_str = re.sub(r'src="[^"]*encabezadotsj\.jpg[^"]*"', f'src="{LOGO_URL}"', html_str, flags=re.I)
    html_str = re.sub(r'src="[^"]*image001\.jpg[^"]*"', f'src="{LOGO_URL}"', html_str, flags=re.I)
    html_str = re.sub(r'src="[^"]*image002\.jpg[^"]*"', f'src="{LOGO_URL}"', html_str, flags=re.I)
    
    # 3. Meta tags
    html_str = re.sub(r'<meta[^>]*charset=[^>]*>', '<meta charset="UTF-8">', html_str, flags=re.I)
    if 'noindex' not in html_str.lower():
        html_str = re.sub(r'(<head[^>]*>)', r'\1\n<meta name="robots" content="noindex, nofollow, noarchive, nosnippet">', html_str, count=1, flags=re.I)
    
    return html_str

async def scrape_sala(nombre_sala, config, start_year, end_year):
    print(f"\n{'='*60}")
    print(f"🏛️ INICIANDO: {nombre_sala} (Código: {config['codigo']})")
    print(f"{'='*60}")
    
    procesados = cargar_progreso()
    nuevas_descargas = 0
    
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True, args=['--no-sandbox', '--disable-setuid-sandbox'])
        context = await browser.new_context(ignore_https_errors=True, user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
        page = await context.new_page()
        
        json_capturado = {}
        async def capturar_response(response):
            if "listDayByAnoSala" in response.url:
                try: json_capturado["dias"] = await response.json()
                except: pass
            elif "listDecisionByFechaSala" in response.url or "listSentenciaByFecha" in response.url:
                try: json_capturado["decisiones"] = await response.json()
                except: pass
        
        page.on("response", capturar_response)
        
        print("🌐 Cargando portal TSJ...")
        await page.goto("https://www.tsj.gob.ve/es/decisiones", wait_until="domcontentloaded", timeout=90000)
        await page.wait_for_selector("#contentDisplayLista", timeout=30000)
        
        print(f"🎯 Seleccionando {nombre_sala}...")
        await page.click(f"a[href='{config['selector']}']")
        await page.wait_for_timeout(3000)
        
        for year in range(start_year, end_year + 1):
            print(f"\n📅 Año {year}")
            try:
                await page.select_option("#select_years", str(year))
                await page.wait_for_timeout(3000)
            except Exception as e:
                print(f"   [!] No se pudo seleccionar año {year}: {e}")
                continue
            
            if "dias" not in json_capturado:
                print(f"   [-] No se capturaron días para {year}")
                continue
            
            dias_data = json_capturado["dias"]
            dias_list = dias_data.get("coleccion", {}).get("DIA", [])
            if isinstance(dias_list, dict):
                dias_list = [dias_list]
            
            if not dias_list:
                print(f"   [-] Sin registros en {year}")
                json_capturado.clear()
                continue
            
            print(f"   [+] {len(dias_list)} días con sentencias")
            
            for i, dia_info in enumerate(dias_list):
                fecha = dia_info.get("FECHA")
                if not fecha:
                    continue
                
                print(f"      → Procesando {fecha}")
                json_capturado.clear()
                
                try:
                    dia_elements = await page.query_selector_all("a.numero-dia")
                    if i < len(dia_elements):
                        await dia_elements[i].click()
                        await page.wait_for_timeout(2500)
                    else:
                        print(f"         [!] Día {i} no encontrado en elementos")
                        continue
                except Exception as e:
                    print(f"         [!] Error clic en día: {e}")
                    continue
                
                if "decisiones" not in json_capturado:
                    print(f"         [-] No se capturaron decisiones")
                    continue
                
                sentencias_data = json_capturado["decisiones"]
                sentencias = sentencias_data.get("coleccion", {}).get("SENTENCIA", [])
                if isinstance(sentencias, dict):
                    sentencias = [sentencias]
                
                for sent in sentencias:
                    exp = sent.get("SSENTEXPEDIENTE", "SIN_EXP").replace("/", "-")
                    num = sent.get("SSENTNUMERO", "SIN_NUM").replace("/", "-")
                    doc_name = sent.get("SSENTNOMBREDOC", " ")
                    ssaladir_val = sent.get("SSALADIR", config["dir"])
                    nombremes = sent.get("NOMBREMES", " ")
                    
                    if not doc_name or doc_name == "null":
                        continue
                    
                    fname = f"{year}_{num}_exp_{exp}.html"
                    url_tsj = f"{HISTORICO_BASE_URL}/{ssaladir_val}/{nombremes.strip()}/{doc_name}"
                    
                    if url_tsj in procesados:
                        continue
                    
                    # Descargar y curar
                    try:
                        resp = await page.context.request.get(url_tsj, timeout=30000)
                        if resp.ok and len(await resp.body()) > 500:
                            html_raw = await resp.text()
                            html_curado = corregir_html(html_raw)
                            
                            # Guardar localmente
                            save_path = os.path.join(OUTPUT_DIR, fname)
                            with open(save_path, 'w', encoding='utf-8') as f:
                                f.write(html_curado)
                            
                            # Enviar al Worker (opcional, pero útil para tu pipeline)
                            try:
                                import base64
                                r = requests.post(
                                    f"{WORKER_URL}/ingest",
                                    headers={"x-token": INGEST_TOKEN},
                                    json={"url": url_tsj, "html_b64": base64.b64encode(html_curado.encode('utf-8')).decode('ascii'), "sala": config["dir"], "tipo": "sentencia"},
                                    timeout=30
                                )
                            except:
                                pass
                            
                            procesados.append(url_tsj)
                            nuevas_descargas += 1
                            
                            if nuevas_descargas % 10 == 0:
                                guardar_progreso(procesados)
                    except Exception as e:
                        print(f"         [!] Error descargando: {e}")
                
                json_capturado.clear()
                await page.wait_for_timeout(300)
            
            guardar_progreso(procesados)
        
        await browser.close()
    
    print(f"\n✅ {nombre_sala} completado. Nuevas descargas: {nuevas_descargas}")

async def main():
    import sys
    start_year = int(sys.argv[1]) if len(sys.argv) > 1 else 2000
    end_year = int(sys.argv[2]) if len(sys.argv) > 2 else 2026
    
    print(f"🚀 Iniciando scraper TSJ ({start_year}-{end_year})")
    for nombre, config in SALAS.items():
        await scrape_sala(nombre, config, start_year, end_year)
    print("🏁 Proceso completado.")

if __name__ == "__main__":
    import asyncio
    asyncio.run(main())
