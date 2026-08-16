#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Parche: corrige Capítulo IV del Título VIII (Libro Segundo).
Reemplaza los artículos 160-165 (colisión de slug) por los correctos 391-393."""

import json, re, time
import requests
from bs4 import BeautifulSoup

BASE_URL = "https://www.ley.com.ve"
ENTRADA = "codigo_penal_corregido.json"   # tu archivo con el fix del 296-A
SALIDA = "codigo_penal_definitivo.json"

HEADERS = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"}


def limpiar_texto(texto: str) -> str:
    for m in [r'Códigos Concordados', r'Más Artículos', r'Concordancia adicional',
              r'Artículo anterior:', r'Artículo siguiente:', r'Indice Código Penal']:
        texto = re.split(m, texto, flags=re.IGNORECASE)[0]
    return re.sub(r'\s+', ' ', texto).strip()


def scrape_articulo(num: int) -> dict:
    url = f"{BASE_URL}/penal/codigo-penal-articulo-{num}"
    r = requests.get(url, headers=HEADERS, timeout=20)
    soup = BeautifulSoup(r.text, "html.parser")
    cuerpo = soup.find('div', class_='com-content-article__body') or soup
    h1 = soup.find('h1').get_text() if soup.find('h1') else ""
    return {
        "numero": str(num),
        "estatus": "DEROGADO" if "DEROGADO" in h1 else "VIGENTE",
        "texto": limpiar_texto(cuerpo.get_text(" "))
    }


with open(ENTRADA, encoding="utf-8") as f:
    cp = json.load(f)

# --- Parche quirúrgico ---
for libro in cp["libros"]:
    if "Segundo" in libro["numero"]:
        for titulo in libro["titulos"]:
            if "Buenas Costumbres" in titulo["nombre"]:
                for cap in titulo["capitulos"]:
                    nums = [str(a["numero"]) for a in cap["articulos"]]
                    if nums and nums[0] == "160":  # ← delata la colisión
                        print(f"⚠️  {cap['nombre']}: tenía 160-165 → re-scrapeando 391-393")
                        nuevos = []
                        for n in (391, 392, 393):
                            nuevos.append(scrape_articulo(n))
                            time.sleep(2)
                        cap["articulos"] = nuevos
                        print("✅ Capítulo IV corregido")

# --- Verificación global: duplicados y secuencia del Título VIII ---
conteo = {}
def rec(n):
    if isinstance(n, dict):
        if "numero" in n and "texto" in n:
            conteo[str(n["numero"])] = conteo.get(str(n["numero"]), 0) + 1
        for v in n.values(): rec(v)
    elif isinstance(n, list):
        for v in n: rec(v)
rec(cp)
print("Duplicados:", [k for k, v in conteo.items() if v > 1] or "ninguno")

with open(SALIDA, "w", encoding="utf-8") as f:
    json.dump(cp, f, ensure_ascii=False, indent=2)
print(f"💾 Guardado en {SALIDA}")