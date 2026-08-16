#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
SCRAPER CRBV DEFINITIVO - Sin "apartes" automáticos
Solo: cuerpo + numerales(+literales) + parágrafos
Preserva \n\n en el texto completo
"""
import requests
from bs4 import BeautifulSoup
import json, time, random, re, logging
from pathlib import Path
from typing import Optional, Dict, List

BASE_URL = "https://www.ley.com.ve"
URL_PREAMBULO = f"{BASE_URL}/constitucion/constitucion-de-la-republica-bolivariana-de-venezuela-preambulo"
URL_DEROGATORIA = f"{BASE_URL}/constitucion/crbv-disposicion-derogatoria"
URL_FINAL = f"{BASE_URL}/constitucion/crbv-disposicion-final"
ORDINALES_TRANSITORIAS = ['primera', 'segunda', 'tercera', 'cuarta', 'quinta', 'sexta', 'septima', 
                          'octava', 'novena', 'decima', 'decimoprimera', 'decimosegunda', 
                          'decimotercera', 'decimocuarta', 'decimoquinta', 'decimosexta', 
                          'decimoseptima', 'decimoctava']

DELAY_MIN, DELAY_MAX = 1.5, 2.5
MAX_REINTENTOS = 3
ARCHIVO_SALIDA = Path("../leyes_json/crbv_completa.json")

HEADERS = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
                         "(KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36"}

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s",
                    handlers=[logging.FileHandler("scraper_crbv.log", encoding="utf-8"),
                              logging.StreamHandler()])
session = requests.Session()
session.headers.update(HEADERS)


def delay():
    time.sleep(random.uniform(DELAY_MIN, DELAY_MAX))

def get_soup(url):
    for intento in range(MAX_REINTENTOS):
        try:
            resp = session.get(url, timeout=20)
            if resp.status_code == 404: return None
            resp.raise_for_status()
            resp.encoding = 'utf-8'
            return BeautifulSoup(resp.text, 'html.parser')
        except Exception as e:
            if intento < MAX_REINTENTOS - 1:
                logging.warning(f"  Intento {intento+1}/{MAX_REINTENTOS} falló ({url}): {e}")
                time.sleep(3)
    logging.error(f"  ❌ No accesible: {url}")
    return None

def limpiar_texto(t):
    if not t: return ""
    for m in [r'Concordancia adicional.*', r'Ver también:?.*', r'Artículo anterior:?.*',
              r'Artículo siguiente:?.*', r'Códigos Concordados.*', r'Más Artículos.*',
              r'🔍 Buscar', r'Más Resultados', r'\[X\]\(', r'\[WhatsApp\]\(',
              r'\[Telegram\]\(', r'\[Facebook\]\(', r'\[LinkedIn\]\(', r'\[Skype\]\(',
              r'\[Google Translate\]\(', r'\[Tumblr\]\(', r'\[Pinterest\]\(',
              r'\[Reddit\]\(', r'\[Copy Link\]\(', r'\[Email\]\(']:
        t = re.split(m, t, flags=re.IGNORECASE)[0]
    t = re.sub(r'^Código:.*$', '', t, flags=re.I | re.M)
    t = re.sub(r'[ \t]+', ' ', t)
    t = re.sub(r'\n\s*\n+', '\n', t)
    return t.strip()


# ============================================================
# PARSER SIMPLE: cuerpo + numerales + parágrafos
# NO crea "apartes" automáticamente
# ============================================================
def parsear_articulo(paras):
    if not paras: return {}
    cuerpo = re.sub(r'^Art[ií]culo\s+\d+\s*[.\-]?\s*', '', paras[0], flags=re.I)
    numerales, parrafos = [], []
    ci = cl = None
    seen_num = False

    for linea in paras[1:]:
        mp = re.match(r'^Parágrafo\b', linea, re.I)
        mn = re.match(r'^(\d+)[.\)]\s*(.*)$', linea)
        ml = re.match(r'^([a-z])[.\)]\s*(.*)$', linea)

        if mp:
            parrafos.append(linea); ci = cl = None
        elif mn:
            seen_num = True
            ci = {"numero": int(mn.group(1)), "texto": mn.group(2).strip()}
            numerales.append(ci); cl = None
        elif ml and seen_num:
            cl = {"letra": ml.group(1), "texto": ml.group(2).strip()}
            if ci is None:
                ci = {"numero": None, "texto": None}
                numerales.append(ci)
            ci.setdefault("literales", []).append(cl)
        else:
            # Si ya vimos numerales, este párrafo va a parrafos_finales
            # Si NO hemos visto numerales, se concatena al cuerpo
            if seen_num:
                parrafos.append(linea)
            else:
                cuerpo += "\n\n" + linea

    res = {"cuerpo": cuerpo}
    if numerales: res["numerales"] = numerales
    if parrafos: res["parrafos_finales"] = parrafos
    res["texto"] = "\n\n".join(paras)
    return res


def extraer_articulo(num):
    url = f"{BASE_URL}/constitucion/constitucion-de-la-republica-bolivariana-de-venezuela-articulo-{num}"
    soup = get_soup(url)
    if not soup: return None
    div = soup.find('div', class_='com-content-article__body') or soup
    paras = []
    for p in div.find_all('p'):
        t = limpiar_texto(p.get_text(" ", strip=True))
        if t and len(t) > 3: paras.append(t)
    if not paras: return None
    art = {"numero": num}
    art.update(parsear_articulo(paras))
    return art


def extraer_pagina_especial(url, prefijo):
    soup = get_soup(url)
    if not soup: return None
    div = soup.find('div', class_='com-content-article__body') or soup
    texto = limpiar_texto(div.get_text(" "))
    if prefijo:
        texto = re.sub(rf'^{prefijo}\.?\s*', '', texto, flags=re.IGNORECASE).strip()
    return texto or None


def extraer_disposiciones():
    logging.info("📜 Extrayendo Disposiciones...")
    disp = {"derogatoria": None, "transitorias": [], "final": None}
    texto = extraer_pagina_especial(URL_DEROGATORIA, r'Disposición\s+Derogatoria')
    if texto: disp["derogatoria"] = {"texto": texto}
    delay()
    for ordinal in ORDINALES_TRANSITORIAS:
        url = f"{BASE_URL}/constitucion/crbv-disposicion-transitoria-{ordinal}"
        texto = extraer_pagina_especial(url, r'Disposición\s+Transitoria\s+\w+')
        if texto:
            disp["transitorias"].append({"numero": ordinal.capitalize(), "texto": texto})
            logging.info(f"  ✓ {ordinal.capitalize()}")
        delay()
    texto = extraer_pagina_especial(URL_FINAL, r'Disposición\s+Final')
    if texto: disp["final"] = {"texto": texto}
    return disp


def validar(crbv, errores):
    logging.info("=" * 70)
    logging.info("📊 VALIDACIÓN FINAL")
    logging.info("=" * 70)
    nums = [a["numero"] for a in crbv["articulos"]]
    faltan = [n for n in range(1, 351) if n not in nums]
    dups = sorted({n for n in nums if nums.count(n) > 1})
    con_numerales = sum(1 for a in crbv["articulos"] if "numerales" in a)
    con_parrafos = sum(1 for a in crbv["articulos"] if "parrafos_finales" in a)
    logging.info(f"  📝 Artículos: {len(nums)}/350")
    logging.info(f"  ❌ Faltantes: {faltan or 'ninguno'}")
    logging.info(f"  ⚠️ Duplicados: {dups or 'ninguno'}")
    logging.info(f"  🔢 Con numerales: {con_numerales}")
    logging.info(f"  📄 Con párrafos finales: {con_parrafos}")
    logging.info(f"  ❌ Errores de extracción: {errores or 'ninguno'}")
    logging.info(f"  📖 Preámbulo: {'✓' if crbv.get('preambulo') else '✗'}")
    logging.info(f"  📜 Transitorias: {len(crbv['disposiciones']['transitorias'])}/18")
    ok = not (faltan or dups or errores)
    logging.info("✅ TODO CORRECTO" if ok else "❌ HAY ERRORES")
    return ok


def main():
    logging.info("🚀 SCRAPER CRBV DEFINITIVO (sin apartes automáticos)")
    inicio = time.time()
    crbv = {"documento": "Constitución de la República Bolivariana de Venezuela",
            "gaceta_oficial": "36.860", "fecha": "1999-12-30",
            "preambulo": None, "articulos": [], "disposiciones": {}}
    
    logging.info("📖 Extrayendo Preámbulo...")
    texto_preambulo = extraer_pagina_especial(URL_PREAMBULO, r'Preámbulo')
    if texto_preambulo: crbv["preambulo"] = {"texto": texto_preambulo}
    delay()
    
    errores = []
    logging.info("📥 Extrayendo artículos 1-350...")
    for num in range(1, 351):
        if num % 20 == 1: logging.info(f"  Procesando {num}-{min(num+19, 350)}...")
        art = extraer_articulo(num)
        if art:
            crbv["articulos"].append(art)
        else:
            errores.append(num)
            logging.error(f"  ❌ Error en artículo {num}")
        delay()
    
    crbv["disposiciones"] = extraer_disposiciones()
    validar(crbv, errores)
    
    ARCHIVO_SALIDA.parent.mkdir(parents=True, exist_ok=True)
    with open(ARCHIVO_SALIDA, "w", encoding="utf-8") as f:
        json.dump(crbv, f, ensure_ascii=False, indent=2)
    logging.info(f"\n💾 Guardado en {ARCHIVO_SALIDA}")
    logging.info(f"⏱️ Tiempo: {(time.time() - inicio) / 60:.2f} minutos")


if __name__ == "__main__":
    main()
