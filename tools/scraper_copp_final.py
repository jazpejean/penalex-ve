#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
SCRAPER COPP v3 — definitivo, autónomo
- Auto-recuperación: descarta checkpoints corruptos automáticamente
- Parser por <p>: cuerpo + apartes + numerales(+literales) + parágrafos
- Ubicación por breadcrumb "Código:" (no por la hoja que lo menciona)
- Filtro correcto: no excluye copp-articulo-*
- Checkpoint incremental robusto
Uso: python3 scraper_copp_final.py
"""
import requests
from bs4 import BeautifulSoup
import json, time, random, re, logging
from pathlib import Path
from collections import defaultdict
from typing import Optional, Dict, List

# ============================================================
# CONFIGURACIÓN
# ============================================================
BASE_URL = "https://www.ley.com.ve"
URL_INDICE = f"{BASE_URL}/penal/codigo-organico-procesal-penal"
DELAY_MIN, DELAY_MAX = 1.5, 3.0
MAX_REINTENTOS = 3
ARCHIVO_SALIDA = Path("copp_completo.json")
ARCHIVO_CHECKPOINT = Path("copp_checkpoint.json")

# Umbral de sanidad: si hay hojas "procesadas" pero muy pocos artículos,
# el checkpoint está envenenado y se descarta solo.
UMBRAL_SANIDAD = 50

HEADERS = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
                         "(KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36"}

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s",
                    handlers=[logging.FileHandler("scraper_copp.log", encoding="utf-8"),
                              logging.StreamHandler()])

session = requests.Session()
session.headers.update(HEADERS)

NOMBRES_APARTES = ["Primer aparte", "Segundo aparte", "Tercer aparte",
                   "Cuarto aparte", "Quinto aparte", "Sexto aparte"]


# ============================================================
# UTILIDADES
# ============================================================
def delay():
    time.sleep(random.uniform(DELAY_MIN, DELAY_MAX))

def norm_url(u):
    return u.rstrip("/")

def clave_num(n):
    m = re.match(r'(\d+)(?:-([a-z]))?', str(n).lower())
    return (int(m.group(1)), m.group(2) or '') if m else (9999, '')

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

def limpiar_ml(t):
    for m in [r'Códigos Concordados', r'Más Artículos', r'Concordancia adicional',
              r'Artículo anterior:', r'Artículo siguiente:', r'Indice COPP',
              r'Indice Código', r'🔍 Buscar', r'Más Resultados',
              r'\[X\]\(', r'\[WhatsApp\]\(', r'\[Telegram\]\(', r'\[Facebook\]\(',
              r'\[LinkedIn\]\(', r'\[Skype\]\(', r'\[Google Translate\]\(',
              r'\[Tumblr\]\(', r'\[Pinterest\]\(', r'\[Reddit\]\(',
              r'\[Copy Link\]\(', r'\[Email\]\(']:
        t = re.split(m, t, flags=re.IGNORECASE)[0]
    t = re.sub(r'^Código:.*$', '', t, flags=re.I | re.M)
    t = re.sub(r'[ \t]+', ' ', t)
    t = re.sub(r'\n\s*\n+', '\n', t)
    return t.strip()


# ============================================================
# PARSER CON APARTES (técnica legislativa venezolana)
# ============================================================
def parsear_articulo(texto_ml):
    """cuerpo + apartes + numerales(+literales) + parágrafos, conserva \n\n"""
    paras = [p.strip() for p in texto_ml.split("\n") if p.strip()]
    if not paras:
        return {}
    cuerpo = re.sub(r'^Art[ií]culo\s+\d+(?:-[A-Za-z])?\s*[.\-]?\s*', '', paras[0], flags=re.I)
    apartes, numerales, parrafos = [], [], []
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
            apartes.append(linea)

    # Fallback: numerales inline (sitio que los mete en un solo <p>)
    if not numerales and re.search(r'[:.]\s+1\.\s+\w', cuerpo):
        m = re.search(r'(?<=[:.])\s+1\.\s+', cuerpo)
        if m:
            head, rest = cuerpo[:m.start()].strip(), cuerpo[m.start():]
            cand = []
            for chunk in re.split(r'\s+(?=\d+\.\s+)', rest):
                mm = re.match(r'(\d+)[.\)]\s*(.*)$', chunk.strip(), re.S)
                if mm:
                    cand.append({"numero": int(mm.group(1)), "texto": mm.group(2).strip()})
            if len(cand) >= 2 and cand[0]["numero"] == 1:
                cuerpo, numerales = head, cand

    res = {"cuerpo": cuerpo}
    if apartes:
        res["apartes"] = [
            {"numero": i + 1,
             "nombre": NOMBRES_APARTES[i] if i < len(NOMBRES_APARTES) else f"Aparte {i + 1}",
             "texto": t}
            for i, t in enumerate(apartes)
        ]
    if numerales:
        res["numerales"] = numerales
    if parrafos:
        res["parrafos_finales"] = parrafos
    res["texto"] = "\n\n".join(paras)
    return res


# ============================================================
# EXTRACCIÓN DE UN ARTÍCULO
# ============================================================
def extraer_padre(soup):
    for a in soup.find_all('a', href=True):
        prev = a.find_previous(string=True)
        if prev and 'Código:' in prev and '/penal/' in a['href']:
            return norm_url(BASE_URL + a['href'])
    return None

def extraer_articulo_copp(url):
    soup = get_soup(url)
    if not soup: return None
    div = soup.find('div', class_='com-content-article__body') or soup
    ml = limpiar_ml(div.get_text("\n"))
    h1 = soup.find('h1').get_text() if soup.find('h1') else ""
    m = re.search(r'Art[ií]culo\s+(\d+(?:-[A-Za-z])?)', h1 + "\n" + ml[:200])
    if m:
        numero, tipo = m.group(1).lower(), "articulo"
    else:
        m2 = re.search(r'(Disposici[oó]n\s+(?:Transitoria\s+\w+|Derogatoria\s*\w*|Final\s*\w*))',
                       h1 + "\n" + ml[:300], re.I)
        if not m2: return None
        numero, tipo = re.sub(r'\s+', ' ', m2.group(1)).strip(), "disposicion"
    art = {"numero": numero, "tipo": tipo,
           "estatus": "DEROGADO" if "DEROGADO" in h1 else "VIGENTE"}
    art.update(parsear_articulo(ml))
    art["_padre"] = extraer_padre(soup)
    return art


# ============================================================
# CANDIDATOS DE UNA HOJA (filtro correcto)
# ============================================================
def candidatos_de_hoja(soup):
    urls, seen = [], set()
    cont = soup.find('div', class_='com-content-category-blog') or soup
    for a in cont.find_all('a', href=True):
        href = a['href']
        # Nunca categorías (libro/titulo/capitulo/seccion sin articulo)
        if re.search(r'/(copp-libro|titulo-|capitulo-|seccion-)', href) and 'articulo' not in href:
            continue
        # Solo artículos o página de disposiciones
        if not re.search(r'(copp-articulo|disposiciones)', href):
            continue
        u = norm_url(BASE_URL + href)
        if u not in seen:
            seen.add(u)
            urls.append(u)
    return urls


# ============================================================
# ÁRBOL DEL ÍNDICE
# ============================================================
def tipo_nodo(nombre):
    n = nombre.lower()
    if 'libro' in n: return 'libro'
    if n.startswith('título') or n.startswith('titulo') or n == 'título preliminar': return 'titulo'
    if n.startswith('capítulo') or n.startswith('capitulo'): return 'capitulo'
    if n.startswith('sección') or n.startswith('seccion'): return 'seccion'
    if 'disposicion' in n: return 'disposiciones'
    return 'otro'

def parsear_items(container):
    nodos = []
    if not container: return nodos
    for item in container.find_all('div', class_='com-content-categories__item', recursive=False):
        td = item.find('div', class_='com-content-categories__item-title')
        enlace = td.find('a') if td else None
        if not enlace: continue
        nodo = {"tipo": tipo_nodo(enlace.get_text()),
                "nombre": enlace.get_text(strip=True),
                "url": norm_url(BASE_URL + enlace['href']),
                "children": [], "articulos": []}
        ch = item.find('div', class_='com-content-categories__children', recursive=False)
        if ch:
            nodo["children"] = parsear_items(
                ch.find('div', class_='com-content-categories__items', recursive=False))
        nodos.append(nodo)
    return nodos

def todas_las_hojas(nodos, acc):
    for n in nodos:
        if n["children"]: todas_las_hojas(n["children"], acc)
        else: acc.append(n)
    return acc


# ============================================================
# CARGA DE CHECKPOINT CON AUTO-SANIDAD
# ============================================================
def cargar_checkpoint():
    """Si el checkpoint está corrupto (hojas procesadas pero pool casi vacío),
    lo descarta automáticamente. No requiere intervención manual."""
    if not ARCHIVO_CHECKPOINT.exists():
        return defaultdict(list), set()
    try:
        with open(ARCHIVO_CHECKPOINT, encoding="utf-8") as f:
            chk = json.load(f)
        pool = chk.get("pool", {})
        urls = set(chk.get("urls_procesadas", []))
        total_pool = sum(len(v) for v in pool.values())
        # Checkpoint envenenado: muchas hojas procesadas, pocos artículos
        if urls and total_pool < UMBRAL_SANIDAD:
            logging.warning(
                f"⚠️  Checkpoint corrupto detectado ({len(urls)} hojas, "
                f"{total_pool} artículos). Se descarta automáticamente.")
            ARCHIVO_CHECKPOINT.unlink()
            return defaultdict(list), set()
        logging.info(f"♻️  Reanudando: {len(urls)} hojas, {total_pool} artículos en pool")
        return defaultdict(list, pool), urls
    except Exception as e:
        logging.warning(f"⚠️  Checkpoint ilegible: {e}. Se descarta.")
        ARCHIVO_CHECKPOINT.unlink(missing_ok=True)
        return defaultdict(list), set()

def guardar_checkpoint(pool, urls):
    with open(ARCHIVO_CHECKPOINT, "w", encoding="utf-8") as f:
        json.dump({"pool": dict(pool), "urls_procesadas": list(urls)}, f, ensure_ascii=False)


# ============================================================
# MAIN
# ============================================================
def main():
    logging.info("🚀 INICIANDO SCRAPER COPP v3 (auto-recuperación + apartes)")
    soup = get_soup(URL_INDICE)
    if not soup:
        logging.error("❌ Índice inaccesible"); return
    arbol = parsear_items(soup.find('div', class_='com-content-categories__items'))
    hojas = todas_las_hojas(arbol, [])
    urls_hojas = {h["url"] for h in hojas}
    logging.info(f"🌳 Nodos raíz: {len(arbol)} | hojas: {len(hojas)}")

    POR_PADRE, urls_procesadas = cargar_checkpoint()

    CACHE = set()
    def procesar(url_cand):
        if url_cand in CACHE: return
        CACHE.add(url_cand)
        art = extraer_articulo_copp(url_cand)
        if art:
            padre = art.pop("_padre", None)
            num = str(art["numero"]).lower()
            if not any(num == str(a["numero"]).lower() for v in POR_PADRE.values() for a in v):
                POR_PADRE[padre].append(art)
                logging.info(f"      ✅ {art['tipo']} {num} → {padre or 'SIN PADRE'}")
        delay()

    inicio = time.time()
    for i, hoja in enumerate(hojas, 1):
        if hoja["url"] in urls_procesadas: continue
        logging.info(f"  🍃 [{i}/{len(hojas)}] {hoja['nombre']}")
        s = get_soup(hoja["url"])
        if s:
            for cand in candidatos_de_hoja(s):
                procesar(cand)
        urls_procesadas.add(hoja["url"])
        if i % 5 == 0 or i == len(hojas):
            guardar_checkpoint(POR_PADRE, urls_procesadas)

    # Enrutado final: cada nodo recibe SOLO lo que su breadcrumb dice que es suyo
    for hoja in hojas:
        hoja["articulos"] = sorted(POR_PADRE.get(hoja["url"], []),
                                   key=lambda a: clave_num(a["numero"]))

    huerfanos = {k: [a["numero"] for a in v] for k, v in POR_PADRE.items()
                 if k not in urls_hojas}
    if huerfanos:
        logging.warning(f"⚠️ Artículos con padre no encontrado en el árbol: {huerfanos}")

    # Validación
    nums = sorted((a["numero"] for v in POR_PADRE.values() for a in v if a["tipo"] == "articulo"),
                  key=clave_num)
    con_apartes = sum(1 for v in POR_PADRE.values() for a in v if "apartes" in a)
    con_numerales = sum(1 for v in POR_PADRE.values() for a in v if "numerales" in a)

    logging.info("=" * 70)
    logging.info("📊 VALIDACIÓN FINAL")
    logging.info("=" * 70)
    logging.info(f"  📝 Artículos: {len(nums)}")
    logging.info(f"  📜 Disposiciones: {sum(len(v) for v in POR_PADRE.values()) - len(nums)}")
    logging.info(f"  📄 Con apartes: {con_apartes}")
    logging.info(f"  🔢 Con numerales: {con_numerales}")
    if huerfanos:
        logging.warning(f"  ⚠️ Huérfanos: {list(huerfanos.keys())}")

    copp = {"documento": "Código Orgánico Procesal Penal", "fuente": "ley.com.ve",
            "gaceta_oficial": "6644", "fecha": "2021-07-17", "estructura": arbol}
    with open(ARCHIVO_SALIDA, "w", encoding="utf-8") as f:
        json.dump(copp, f, ensure_ascii=False, indent=2)
    logging.info(f"\n💾 Guardado en {ARCHIVO_SALIDA}")
    logging.info(f"⏱️ Tiempo total: {(time.time() - inicio) / 60:.2f} minutos")

    # Si todo salió bien, limpiar checkpoint
    if not huerfanos and len(nums) > 400:
        ARCHIVO_CHECKPOINT.unlink(missing_ok=True)
        logging.info("🧹 Checkpoint eliminado (scraping completo)")

if __name__ == "__main__":
    main()
