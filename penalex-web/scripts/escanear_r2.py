#!/usr/bin/env python3
"""Escanea los 55.208 HTML de R2 para detectar sentencias en blanco/defectuosas.

Criterio de "en blanco" (defectos de la fuente TSJ):
  - HTTP != 200 (404, 403…)
  - Archivo < 2 KB (HTML de Word real siempre supera eso)
  - Texto visible < 400 caracteres (solo markup/CSS, sin contenido)

Escribe data/escaneo_r2.json:
  { "escaneados": N, "blancas": [ {id, r2_html_key, tamaño, texto_visible, motivo} ],
    "sanas": N, "timestamps": ... }

Uso: python3 scripts/escanear_r2.py
"""
import concurrent.futures
import json
import os
import re
import sys
import time
import urllib.parse
import urllib.request

ROOT = "/home/jeanjazpe/Penalex_VE/penalex-web"
BASE = "https://pub-ccca0a4f4395464da7752af871c16943.r2.dev/"
UA = {"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/120 Safari/537.36"}
HILOS = 16
TIMEOUT = 60
UMBRAL_BYTES = 2048
UMBRAL_TEXTO = 400


def texto_visible(html: bytes) -> int:
    """Cuenta caracteres de texto visible (sin tags, scripts ni estilos)."""
    txt = html.decode("utf-8", errors="replace")
    txt = re.sub(r"<(script|style)[^>]*>.*?</\1>", " ", txt, flags=re.S | re.I)
    txt = re.sub(r"<[^>]+>", " ", txt)
    txt = re.sub(r"\s+", " ", txt)
    return len(txt.strip())


def escanear(key: str) -> dict:
    url = BASE + urllib.parse.quote(key, safe="/")
    for intento in range(3):
        try:
            req = urllib.request.Request(url, headers=UA, method="GET")
            with urllib.request.urlopen(req, timeout=TIMEOUT) as r:
                data = r.read()
            if r.status != 200:
                return {"key": key, "ok": False, "motivo": f"HTTP {r.status}", "bytes": 0, "texto": 0}
            if len(data) < UMBRAL_BYTES:
                return {"key": key, "ok": False, "motivo": "archivo pequeño", "bytes": len(data), "texto": 0}
            tv = texto_visible(data)
            if tv < UMBRAL_TEXTO:
                return {"key": key, "ok": False, "motivo": "sin contenido", "bytes": len(data), "texto": tv}
            return {"key": key, "ok": True, "motivo": "", "bytes": len(data), "texto": tv}
        except Exception as e:
            if intento == 2:
                return {"key": key, "ok": False, "motivo": f"error: {str(e)[:50]}", "bytes": 0, "texto": 0}
            time.sleep(0.5 * (intento + 1))
    return {"key": key, "ok": False, "motivo": "desconocido", "bytes": 0, "texto": 0}


def main():
    payload = json.load(open(os.path.join(ROOT, "data", "sentencias.json"), "r"))
    sentencias = payload["sentencias"]
    total = len(sentencias)
    print(f"Escaneando {total} HTML… (16 hilos)")

    resultados = []
    t0 = time.time()
    with concurrent.futures.ThreadPoolExecutor(max_workers=HILOS) as ex:
        futuros = {ex.submit(escanear, s["r2_html_key"]): s for s in sentencias}
        done = 0
        for fut in concurrent.futures.as_completed(futuros):
            s = futuros[fut]
            try:
                r = fut.result()
            except Exception as e:
                r = {"key": s["r2_html_key"], "ok": False, "motivo": f"excepción: {str(e)[:40]}", "bytes": 0, "texto": 0}
            r["id"] = s["id"]
            r["slug"] = s["slug"]
            resultados.append(r)
            done += 1
            if done % 5000 == 0:
                vel = done / (time.time() - t0)
                print(f"  … {done}/{total} ({vel:.1f}/s, faltan ~{(total-done)/vel/60:.0f} min)")

    dur = time.time() - t0
    sanas = [r for r in resultados if r["ok"]]
    blancas = [r for r in resultados if not r["ok"]]

    salida = {
        "escaneados": len(resultados),
        "sanas": len(sanas),
        "blancas": len(blancas),
        "duracion_s": round(dur, 1),
        "blancas_detalle": blancas,
    }
    with open(os.path.join(ROOT, "data", "escaneo_r2.json"), "w", encoding="utf-8") as f:
        json.dump(salida, f, ensure_ascii=False)

    motivos = {}
    for b in blancas:
        m = b["motivo"].split(":")[0]
        motivos[m] = motivos.get(m, 0) + 1

    print(f"\n✅ Escaneo completo en {dur/60:.1f} min")
    print(f"   Sanas: {len(sanas)} | En blanco: {len(blancas)}")
    print(f"   Motivos: {motivos}")
    print(f"   → data/escaneo_r2.json")


if __name__ == "__main__":
    main()