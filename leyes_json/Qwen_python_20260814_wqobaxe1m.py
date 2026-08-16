#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
PARSER OFFLINE CÓDIGO PENAL — lee 'codigo penal.html' LOCAL.
Sin red, sin delays, sin checkpoints. Determinista.
Salida: libros→títulos→capítulos→artículos, SIN urls, SIN "apartes",
texto con \n\n, numerales+literales, parágrafos, estatus y fundamentación.
"""
import json, re
from bs4 import BeautifulSoup
from pathlib import Path

RUTA_HTML = Path("codigo penal.html")
RUTA_SALIDA = Path("../leyes_json/codigo_penal_completo.json")

RE_LIBRO   = re.compile(r'^(?:CP\s+)?LIBRO\s*(PRIMERO|SEGUNDO|TERCERO)\b[:\s]*(.*)$', re.I)
RE_TITULO  = re.compile(r'^T[IÍ]TULO\s*([IVX]+)\b[:\s]*(.*)$', re.I)
RE_CAPITULO= re.compile(r'^CAP[IÍ]TULO\s*([IVX]+)\b[:\s]*(.*)$', re.I)
RE_DISP    = re.compile(r'^DISPOSICI[IÓ]N\s+(COMPLEMENTARIA|FINAL|DEROGATORIA)\b(.*)$', re.I)
RE_ART     = re.compile(r'Art[ií]culo\s*(\d+)\s*[-–]?\s*([A-Za-z])?')
RE_NUM     = re.compile(r'^(\d+)[.\)]\s+(.*)$')
RE_LIT     = re.compile(r'^([a-z])[.\)]\s+(.*)$')
RE_PAR     = re.compile(r'^Par[aá]grafo\b', re.I)

BASURA = [r'Concordancia adicional.*', r'Ver también:?.*', r'Artículo anterior:?.*',
          r'Artículo siguiente:?.*', r'Códigos Concordados.*', r'Más Artículos.*',
          r'🔍.*', r'Compartir.*', r'Imprimir artículo.*', r'Descargar PDF.*',
          r'Volver al índice.*', r'^Código:.*']

def norm(t): return re.sub(r'\s+', ' ', t or '').strip()
def despegar(t):  # separa "Delacaída" → "De la caída" (transiciones minús→mayús)
    return re.sub(r'([a-záéíóúñ])([A-ZÁÉÍÓÚ])', r'\1 \2', t)
def limpiar(t):
    for b in BASURA: t = re.split(b, t, flags=re.I)[0]
    return norm(t)

def libro_de(n):
    if n <= 127: return "Primero"
    if n <= 482: return "Segundo"
    return "Tercero"

def main():
    soup = BeautifulSoup(RUTA_HTML.read_text(encoding='utf-8', errors='replace'), 'html.parser')

    bloques = [limpiar(el.get_text(' ')) for el in soup.find_all(['p','h1','h2','h3','h4','li'])]
    bloques = [b for b in bloques if b and len(b) > 2]

    libros, disposiciones = [], {}
    cur_l = cur_t = cur_c = None
    articulos, orden, dup = {}, [], 0
    current = None

    for blk in bloques:
        m = RE_LIBRO.match(blk)
        if m:
            cur_l = {"tipo":"libro","numero":m.group(1).capitalize(),"nombre":norm(m.group(2)),"titulos":[]}
            libros.append(cur_l); cur_t = cur_c = None; continue
        m = RE_TITULO.match(blk)
        if m:
            if cur_l is None:
                cur_l = {"tipo":"libro","numero":None,"nombre":"","titulos":[]}
                libros.append(cur_l)
            cur_t = {"tipo":"titulo","numero":m.group(1),"nombre":despegar(norm(m.group(2))),"capitulos":[],"articulos":[]}
            cur_t["_libro_ref"] = None
            cur_l["titulos"].append(cur_t); cur_c = None; continue
        m = RE_CAPITULO.match(blk)
        if m:
            if cur_t is None: continue
            cur_c = {"tipo":"capitulo","numero":m.group(1),"nombre":despegar(norm(m.group(2))),"articulos":[]}
            cur_t["capitulos"].append(cur_c); continue
        m = RE_DISP.match(blk)
        if m:
            disposiciones[m.group(1).lower()] = {"nombre": norm(blk), "articulos": []}
            current = None; cur_c = ("__disp__", m.group(1).lower()); continue

        # Dividir el bloque en segmentos por marcador de artículo
        for seg in re.split(r'(?=Art[ií]culo\s*\d)', blk):
            seg = seg.strip()
            if not seg: continue
            ma = RE_ART.match(seg)
            if ma:
                num = ma.group(1) + (f"-{ma.group(2).lower()}" if ma.group(2) else "")
                if num in articulos:
                    dup += 1; current = None; continue   # eco duplicado: ignorar
                art = {"numero": num,
                       "estatus": "DEROGADO" if "DEROGADO" in seg else "VIGENTE",
                       "raw": [seg], "paras": []}
                articulos[num] = art; orden.append(num); current = art
                resto = re.sub(r'^Art[ií]culo\s*\d+(?:\s*[-–]?\s*[A-Za-z])?\s*[.\-]?\s*', '', seg)
                if resto: art["paras"].append(resto)
                # ubicación en árbol
                n = int(ma.group(1))
                if isinstance(cur_c, tuple) and cur_c[0] == "__disp__":
                    disposiciones[cur_c[1]]["articulos"].append(art)
                elif cur_c is not None:
                    cur_c["articulos"].append(art); cur_c.setdefault("_n0", n)
                elif cur_t is not None:
                    cur_t["articulos"].append(art); cur_t.setdefault("_n0", n)
            elif current is not None:
                current["raw"].append(seg); current["paras"].append(seg)

    # Construir campos finales de cada artículo
    for num in orden:
        art = articulos[num]
        cuerpo, nums, pf = [], [], []
        ci = cl = None; seen = False
        for p in art["paras"]:
            if RE_PAR.match(p): pf.append(p); ci = cl = None; continue
            mn, ml = RE_NUM.match(p), RE_LIT.match(p)
            if mn:
                seen = True; ci = {"numero": int(mn.group(1)), "texto": mn.group(2).strip()}
                nums.append(ci); cl = None
            elif ml and seen:
                cl = {"letra": ml.group(1), "texto": ml.group(2).strip()}
                if ci is None: ci = {"numero": None, "texto": None}; nums.append(ci)
                ci.setdefault("literales", []).append(cl)
            elif seen: pf.append(p)
            else: cuerpo.append(p)
        art["cuerpo"] = "\n\n".join(cuerpo)
        if nums: art["numerales"] = nums
        if pf: art["parrafos_finales"] = pf
        art["texto"] = "\n\n".join(art["raw"])
        del art["raw"], art["paras"]

    # Asignar libros por rango si el HTML no trajo encabezados LIBRO
    for l in libros:
        if l["numero"] is None:
            for t in l["titulos"]:
                n0 = t.get("_n0") or next((c.get("_n0") for c in t["capitulos"] if c.get("_n0")), None)
                l["numero"] = libro_de(n0) if n0 else "?"
    for l in libros:
        for t in l["titulos"]: t.pop("_n0", None); t.pop("_libro_ref", None)
        for t in l["titulos"]:
            for c in t["capitulos"]: c.pop("_n0", None)

    salida = {
        "documento": "Código Penal de la República Bolivariana de Venezuela",
        "fuente": "ley.com.ve (HTML local)",
        "libros": libros,
        "disposiciones": disposiciones,
        "articulos": [articulos[n] for n in orden],
    }
    RUTA_SALIDA.parent.mkdir(parents=True, exist_ok=True)
    with open(RUTA_SALIDA, "w", encoding="utf-8") as f:
        json.dump(salida, f, ensure_ascii=False, indent=2)

    # ---- Validación ----
    nums = [n for n in orden if "-" not in n]
    falt = [n for n in range(1, 547) if str(n) not in nums]
    con_num = sum(1 for n in orden if "numerales" in articulos[n])
    print(f"📝 Artículos: {len(orden)} | Duplicados ignorados: {dup}")
    print(f"❌ Faltantes 1-546: {falt or 'ninguno'}")
    print(f"🔤 Variantes: {[n for n in orden if '-' in n]}")
    print(f"🔢 Con numerales: {con_num} | 📚 Libros: {len(libros)}")
    print(f"✅ 296-A presente: {'296-a' in articulos}")
    print(f"💾 {RUTA_SALIDA}")

if __name__ == "__main__":
    main()