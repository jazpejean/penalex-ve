#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
parser_docx_leyes.py
====================
Convierte los DOCX de "Leyes en word/" en JSON estructurado para la app
PenalEx (assets/data/leyes/).

SOLUCIONA dos problemas de los DOCX:
  1. "Puntos y aparte sin espacios": oraciones unidas sin espacio tras el
     punto final ("funcionamiento.Se estable") -> inserta el espacio.
  2. "Numerales y literales fuera de lista": los párrafos que comienzan con
     "1.", "2." o "a)", "b)" se marcan como numerales/literales para que la
     UI los renderice como listas.

SOLO se incluyen leyes directamente relacionadas con el derecho penal.
De la carpeta "Constitucional y DDHH" se excluyen las leyes de naturaleza
administrativa, notarial, electoral, civil o institucional no penal.

Extrae la jerarquía LIBRO → TÍTULO → CAPÍTULO → SECCIÓN y todos los
artículos, preservando cada párrafo del DOCX como "punto y aparte".

Integra además el cotejo Código Penal <-> Leyes Especiales (VERIFICADO) para
marcar artículos del CP como derogados o sustituidos.

Uso:
    python3 tools/scripts/parser_docx_leyes.py
Salida:
    assets/data/leyes/<id>.json          (una por ley)
    assets/data/leyes/_indice.json       (resumen de todas)
"""
import os
import re
import json
import zipfile
from datetime import datetime, timezone
from xml.etree import ElementTree as ET

W = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.abspath(os.path.join(SCRIPT_DIR, "..", ".."))
LEYES_DIR = os.path.join(RAIZ, "Leyes en word")
SALIDA_DIR = os.path.join(RAIZ, "assets", "data", "leyes")

PENAL_DIR = os.path.join(LEYES_DIR, "Leyes_Derecho_Penal_y_Criminológico")
CONST_DIR = os.path.join(LEYES_DIR, "Leyes_Derecho_Constitucional_y_DDHH")
COTEJO_PATH = os.path.join(LEYES_DIR,
                           "Cotejo_Codigo_Penal_Venezuela_Leyes_Especiales_VERIFICADO.json")

# ---------------------------------------------------------------------------
# 1. Filtro de leyes incluidas (SOLO derecho penal)
# ---------------------------------------------------------------------------
# Ids derivados del nombre del archivo (ver slugify).
INCLUIDAS = {
    # ---- Carpeta Penal (todas) ----
    "ley_del_estatuto_de_la_funcion_de_la_policia_de_investigacion_2026",
    "ley_organica_de_extincion_de_dominio_2023",
    "ley_de_registro_de_antecedentes_penales_2022",
    "ley_contra_la_corrupcion_2022",
    "codigo_organico_procesal_penal_2021",
    "ley_organica_sobre_el_derecho_de_las_mujeres_a_una_vida_libre_de_violencia_2021",
    "codigo_organico_penitenciario_2021",
    "ley_para_la_prevencion_y_erradicacion_del_abuso_sexual_contra_ninos_ninas_y_adolescentes",
    "ley_que_regula_el_uso_de_la_telefonia_celular_y_la_internet_en_el_interior_de_los_establecimientos_penitenciarios",
    "ley_para_el_desarme_y_control_de_armas_y_municiones_2013",
    "ley_especial_para_prevenir_y_sancionar_la_tortura_y_otros_tratos_crueles_inhumanos_o_degradantes",
    "ley_organica_del_servicio_de_policia_de_investigacion_el_cuerpo_de_investigaciones_cientificas_penales_y_criminalisticas",
    "ley_penal_del_ambiente_2012",
    "ley_organica_contra_la_delincuencia_organizada_y_financiamiento_al_terrorismo_2012",
    "ley_contra_la_estafa_inmobiliaria_2012",
    "ley_organica_de_drogas_2010",
    "ley_contra_el_secuestro_y_la_extorsion_2009",
    "codigo_penal_2005",
    "ley_especial_contra_los_delitos_informaticos_2001",
    "ley_penal_de_proteccion_a_la_actividad_ganadera_1997",
    "ley_sobre_proteccion_a_la_privacidad_de_las_comunicaciones_1991",
    # ---- Carpeta Constitucional (solo penal) ----
    "constitucion_de_la_republica_bolivariana_de_venezuela_1999",
    "ley_organica_de_la_defensa_publica_2022",
    "ley_del_estatuto_de_la_funcion_policial_2021",
    "ley_organica_de_amparo_a_la_libertad_y_seguridad_personal_2021",
    "codigo_organico_de_justicia_militar_2021",
    "ley_de_proteccion_de_victimas_testigos_y_demas_sujetos_procesales_2021",
    "ley_para_sancionar_los_crimenes_desapariciones_torturas_y_otras_violaciones_de_los_derechos_humanos_por_razones_politicas_en_el_periodo_1958_1998",
    "ley_organica_del_ministerio_publico_2007",
    "ley_organica_de_amparo_sobre_derechos_y_garantias_constitucionales_1998",
    # LOPNNA (duplicada en ambas carpetas; se deduplica por id)
    "ley_organica_para_la_proteccion_de_ninos_ninas_y_adolescentes_2015",
}

# Orden de prioridad (los 6 más importantes van primero)
PRIORIDAD = {
    "constitucion_de_la_republica_bolivariana_de_venezuela_1999": 1,
    "codigo_organico_procesal_penal_2021": 2,
    "codigo_penal_2005": 3,
    "ley_organica_sobre_el_derecho_de_las_mujeres_a_una_vida_libre_de_violencia_2021": 4,
    "ley_organica_para_la_proteccion_de_ninos_ninas_y_adolescentes_2015": 5,
    "ley_organica_de_drogas_2010": 6,
}

CODIGOS = {
    "constitucion_de_la_republica_bolivariana_de_venezuela_1999": "CRBV",
    "codigo_organico_procesal_penal_2021": "COPP",
    "codigo_penal_2005": "CP",
    "ley_organica_sobre_el_derecho_de_las_mujeres_a_una_vida_libre_de_violencia_2021": "LOSDMVLV",
    "ley_organica_para_la_proteccion_de_ninos_ninas_y_adolescentes_2015": "LOPNNA",
    "ley_organica_de_drogas_2010": "LOD",
    "ley_organica_contra_la_delincuencia_organizada_y_financiamiento_al_terrorismo_2012": "LODFT",
    "ley_contra_el_secuestro_y_la_extorsion_2009": "LCSE",
    "ley_especial_contra_los_delitos_informaticos_2001": "LECDI",
    "ley_para_el_desarme_y_control_de_armas_y_municiones_2013": "LDCAM",
    "ley_contra_la_corrupcion_2022": "LCC",
    "ley_organica_de_amparo_sobre_derechos_y_garantias_constitucionales_1998": "LOASDGC",
    "ley_organica_de_amparo_a_la_libertad_y_seguridad_personal_2021": "LOALSP",
    "codigo_organico_penitenciario_2021": "COP",
    "codigo_organico_de_justicia_militar_2021": "COJM",
    "ley_penal_del_ambiente_2012": "LPA",
    "ley_organica_de_extincion_de_dominio_2023": "LOED",
    "ley_organica_del_servicio_de_policia_de_investigacion_el_cuerpo_de_investigaciones_cientificas_penales_y_criminalisticas": "LOSPI",
    "ley_organica_del_ministerio_publico_2007": "LOMP",
    "ley_organica_de_la_defensa_publica_2022": "LODP",
    "ley_del_estatuto_de_la_funcion_policial_2021": "LEFPOL",
    "ley_que_regula_el_uso_de_la_telefonia_celular_y_la_internet_en_el_interior_de_los_establecimientos_penitenciarios": "LUTCIE",
    "ley_especial_para_prevenir_y_sancionar_la_tortura_y_otros_tratos_crueles_inhumanos_o_degradantes": "LPSTT",
    "ley_para_la_prevencion_y_erradicacion_del_abuso_sexual_contra_ninos_ninas_y_adolescentes": "LPEAS",
    "ley_de_registro_de_antecedentes_penales_2022": "LRAP",
    "ley_del_estatuto_de_la_funcion_de_la_policia_de_investigacion_2026": "LEFPI",
    "ley_sobre_proteccion_a_la_privacidad_de_las_comunicaciones_1991": "LSPC",
    "ley_penal_de_proteccion_a_la_actividad_ganadera_1997": "LPPAG",
    "ley_contra_la_estafa_inmobiliaria_2012": "LCEI",
    "ley_de_proteccion_de_victimas_testigos_y_demas_sujetos_procesales_2021": "LPVT",
    "ley_para_sancionar_los_crimenes_desapariciones_torturas_y_otras_violaciones_de_los_derechos_humanos_por_razones_politicas_en_el_periodo_1958_1998": "LCSDH",
}

STOP_CODIGO = {
    "el", "la", "los", "las", "de", "del", "para", "por", "con", "en", "y", "o",
    "sobre", "que", "a", "al", "su", "se", "una", "un", "las",
}

def generar_codigo(nombre):
    palabras = re.findall(r"[A-ZÁÉÍÓÚÑa-záéíóúñ]+", nombre)
    sig = []
    for p in palabras:
        if p.lower() in STOP_CODIGO or len(p) < 4:
            continue
        sig.append(p[:1].upper())
    codigo = "".join(sig)
    if len(codigo) < 3:
        codigo = "".join(p[:1].upper() for p in palabras[:6])
    return codigo[:10]

def slugify(s):
    s = s.lower()
    for a, b in (("á", "a"), ("é", "e"), ("í", "i"), ("ó", "o"), ("ú", "u"),
                 ("ü", "u"), ("ñ", "n"), ("à", "a"), ("è", "e"), ("ò", "o")):
        s = s.replace(a, b)
    s = re.sub(r"[^a-z0-9]+", "_", s)
    return s.strip("_")


def _incluida(_id):
    """True si el id está en el catálogo penal, incluso si el nombre del
    archivo en el corpus está truncado (acepta prefijos largos)."""
    if _id in INCLUIDAS:
        return True
    if len(_id) >= 30:
        return any(inc.startswith(_id) for inc in INCLUIDAS)
    return False


def _codigo_para(_id):
    """Devuelve el código de CODIGOS usando el mismo criterio de prefijo que
    _incluida (los nombres de archivo del corpus pueden estar truncados)."""
    if _id in CODIGOS:
        return CODIGOS[_id]
    if len(_id) >= 30:
        for clave, valor in CODIGOS.items():
            if clave.startswith(_id):
                return valor
    return None

def catalogar():
    """Construye el catálogo SOLO con las leyes penales incluidas."""
    vistos = set()
    cat = []
    for carpeta, rama in ((PENAL_DIR, "Derecho Penal y Criminológico"),
                          (CONST_DIR, "Derecho Constitucional y DDHH")):
        if not os.path.isdir(carpeta):
            continue
        for nombre in sorted(os.listdir(carpeta)):
            if not nombre.lower().endswith(".docx"):
                continue
            ruta = os.path.join(carpeta, nombre)
            try:
                with zipfile.ZipFile(ruta) as z:
                    z.read("word/document.xml")
            except Exception:
                print(f"  [!!] DOCX inválido, se omite: {nombre}")
                continue
            base = re.sub(r"^\d+\.\s*", "", nombre[:-5])
            m_anio = re.search(r"\((\d{4})\)", base)
            anio = m_anio.group(1) if m_anio else None
            nombre_limpio = re.sub(r"\s*\(\d{4}\)", "", base).strip()
            _id = slugify(nombre_limpio + (f"_{anio}" if anio else ""))
            if not _incluida(_id):
                continue
            if _id in vistos:  # dedupe (p. ej. LOPNNA en ambas carpetas)
                continue
            vistos.add(_id)
            codigo = _codigo_para(_id) or generar_codigo(nombre_limpio)
            cat.append({
                "id": _id, "codigo": codigo, "nombre": nombre_limpio,
                "rama": rama, "anio": anio, "archivo": nombre,
                "carpeta": os.path.basename(carpeta),
                "orden": PRIORIDAD.get(_id, 1000),
            })
    # Orden: prioridad 1-6, luego penal (año desc), luego constitucional (año desc)
    def clave_orden(c):
        if c["orden"] < 1000:
            return (0, c["orden"])
        if c["rama"].startswith("Derecho Penal"):
            return (1, -(int(c["anio"] or 0)))
        return (2, -(int(c["anio"] or 0)))
    cat.sort(key=clave_orden)
    for i, c in enumerate(cat, 1):
        c["orden"] = i
    return cat

# ---------------------------------------------------------------------------
# 2. Extracción de párrafos
# ---------------------------------------------------------------------------
def docx_parrafos(ruta):
    with zipfile.ZipFile(ruta) as z:
        root = ET.fromstring(z.read("word/document.xml"))
    out = []
    for p in root.iter(f"{{{W}}}p"):
        texto = "".join(n.text or "" for n in p.iter(f"{{{W}}}t"))
        out.append(texto)
    return out

def arreglar_oraciones(texto):
    """Inserta espacio tras el punto final si falta (puntos y aparte unidos)."""
    texto = re.sub(r"(?<=[a-záéíóúñü])\.(?=[A-ZÁÉÍÓÚÑ])", ". ", texto)
    texto = re.sub(r"[ \t]+", " ", texto).strip()
    return texto

# ---------------------------------------------------------------------------
# 3. Detección
# ---------------------------------------------------------------------------
RE_SECCION = [
    (re.compile(r"^(LIBRO)\s+([A-ZÁÉÍÓÚÑ0-9IVXLCDM]+)", re.I), "LIBRO", 1),
    (re.compile(r"^(TÍTULO|TITULO)\s+([A-ZÁÉÍÓÚÑ0-9IVXLCDM]+)", re.I), "TITULO", 2),
    (re.compile(r"^(CAPÍTULO|CAPITULO)\s+([A-ZÁÉÍÓÚÑ0-9IVXLCDM]+)", re.I), "CAPITULO", 3),
    (re.compile(r"^(SECCIÓN|SECCION)\s+([A-ZÁÉÍÓÚÑ0-9IVXLCDM]+)", re.I), "SECCION", 4),
]
RE_DISPOSICION = re.compile(
    r"^(DISPOSICIONES?\s+(TRANSITORIAS|DEROGATORIAS?|FINALES?|GENERALES?)|DISPOSICIÓN\s+(TRANSITORIAS?|DEROGATORIAS?|FINALES?|GENERALES?))",
    re.I)
RE_PREAMBULO = re.compile(r"^(PREÁMBULO|PREAMBULO|EXPOSICIÓN\s+DE\s+MOTIVOS|EXPOSICION\s+DE\s+MOTIVOS)", re.I)
# Número de artículo: admite "1", "1-A", "1o" (ordinal), "1º", "1°" (grupo capturante)
RE_NUM_ART = r"((?:ÚNICO|UNICO|\d+(?:-[A-Za-zÁÉÍÓÚÑ])?[a-záéíóúñº°]?))"
# Separador tras el número: "1.", "1º", "1°", "1.-", "1°)" ...
RE_SEP_ART = r"\s*[°º\.\-–—)]*\s*"
RE_ARTICULO = re.compile(r"^(?:Artículo|ARTICULO|Art\.?|ARTÍCULO)\s+" + RE_NUM_ART + RE_SEP_ART + r"$", re.I)
RE_ARTICULO_INLINE = re.compile(
    r"^(?:Artículo|ARTICULO|Art\.?|ARTÍCULO)\s+" + RE_NUM_ART + RE_SEP_ART, re.I)
RE_DISPOSICION_ITEM = re.compile(
    r"^(Única|Unica|Primera|Segunda|Tercera|Cuarta|Quinta|Sexta|Séptima|Septima|Octava|Novena|"
    r"Décima|Decima|Decimoprimera|Decimosegunda|Decimotercera|Decimocuarta|Decimoquinta|Decimosexta|"
    r"Decimoséptima|Decimoctava|Decimonovena|"
    r"(?:Vigésima|Vigesima|Trigésima|Trigesima)(?:\s+(?:Primera|Segunda|Tercera|Cuarta|Quinta|Sexta|Séptima|Septima|Octava|Novena))?)"
    r"\.?\s*", re.I)

NUMERALES_ROMANOS = {
    "I": "I", "II": "II", "III": "III", "IV": "IV", "V": "V", "VI": "VI",
    "VII": "VII", "VIII": "VIII", "IX": "IX", "X": "X", "XI": "XI", "XII": "XII",
    "XIII": "XIII", "XIV": "XIV", "XV": "XV", "XVI": "XVI", "XVII": "XVII",
    "XVIII": "XVIII", "XIX": "XIX", "XX": "XX", "XXI": "XXI", "XXII": "XXII",
}
ORDINALES = {
    "PRIMERO": "I", "SEGUNDO": "II", "TERCERO": "III", "CUARTO": "IV", "QUINTO": "V",
    "SEXTO": "VI", "SÉPTIMO": "VII", "SEPTIMO": "VII", "OCTAVO": "VIII", "NOVENO": "IX",
    "DÉCIMO": "X", "DECIMO": "X", "ÚNICO": "ÚNICO", "UNICO": "ÚNICO", "PRIMERA": "I",
    "SEGUNDA": "II", "TERCERA": "III", "CUARTA": "IV", "QUINTA": "V", "SEXTA": "VI",
    "SÉPTIMA": "VII", "SEPTIMA": "VII", "OCTAVA": "VIII", "NOVENA": "IX", "DÉCIMA": "X",
    "DECIMA": "X", "ÚNICA": "ÚNICA", "UNICA": "ÚNICA",
}

def normalizar_num_seccion(num_raw):
    n = num_raw.upper().strip(" .º°")
    if n in NUMERALES_ROMANOS:
        return n
    if n in ORDINALES:
        return ORDINALES[n]
    return n

def limpiar_titulo(t):
    t = re.sub(r"^[:\-–—]\s*", "", t)
    t = re.sub(r"\s+", " ", t).strip()
    return t

def tipo_parrafo(texto):
    t = texto.strip()
    if re.match(r"^\d{1,3}[a-o]?[ ]?[\.\)]\s", t):
        return "numeral"
    if re.match(r"^[a-z]{1,2}\)\s", t):
        return "literal"
    if re.match(r"^(Parágrafo|Paragrafo|Párrafo|Parrafo|Aparte)\b", t, re.I):
        return "apartado"
    return "parrafo"

# ---------------------------------------------------------------------------
# 4. Parseo de una ley
# ---------------------------------------------------------------------------
def parsear_ley(cat_entry, cotejo_cp=None):
    ruta = os.path.join(LEYES_DIR, cat_entry["carpeta"], cat_entry["archivo"])
    ps = [arreglar_oraciones(t) for t in docx_parrafos(ruta)]

    secciones = []
    articulos = []
    preambulo = None
    stack = []          # secciones abiertas
    orden_seccion = 0
    actual = None
    en_disposiciones = False
    disp_numero = "ÚNICO"
    en_preambulo = False
    i, n = 0, len(ps)

    def cerrar_articulo():
        nonlocal actual
        if actual is not None:
            if actual["parrafos"]:
                articulos.append(actual)
            actual = None

    def abrir_seccion(tipo, numero, titulo, nivel):
        nonlocal orden_seccion, en_disposiciones, en_preambulo, disp_numero
        cerrar_articulo()
        en_preambulo = False
        if tipo == "DISPOSICIONES":
            en_disposiciones = True
            disp_numero = numero if numero not in ("", "ÚNICO") else "ÚNICO"
        else:
            en_disposiciones = False
        while stack and stack[-1]["nivel"] >= nivel:
            stack.pop()
        parent_id = stack[-1]["id"] if stack else None
        orden_seccion += 1
        sid = f"{cat_entry['id']}_S{orden_seccion}"
        secciones.append({
            "id": sid, "tipo": tipo, "numero": numero, "titulo": titulo,
            "nivel": nivel, "parent_id": parent_id, "orden": orden_seccion,
            "disposicion": tipo == "DISPOSICIONES",
        })
        stack.append({"nivel": nivel, "id": sid})
        return sid

    def nuevo_articulo(numero_texto, sid):
        nonlocal actual
        cerrar_articulo()
        actual = {
            "numero_texto": numero_texto,
            "numero": None,
            "titulo": None,
            "seccion_id": sid,
            "parrafos": [],
        }
        mnum = re.match(r"^(\d+(?:-[A-Za-zÁÉÍÓÚÑ])?)$", numero_texto)
        if mnum:
            actual["numero"] = int(re.match(r"^(\d+)", numero_texto).group(1))
        return actual

    def seccion_actual_id():
        return stack[-1]["id"] if stack else None

    while i < n:
        linea = ps[i].strip()
        i += 1
        if not linea:
            continue

        # Preámbulo
        if RE_PREAMBULO.match(linea):
            cerrar_articulo()
            en_preambulo = True
            en_disposiciones = False
            preambulo = []
            continue
        if en_preambulo:
            if (RE_ARTICULO.match(linea) or RE_ARTICULO_INLINE.match(linea)
                    or any(rx.match(linea) for rx, _, _ in RE_SECCION)
                    or RE_DISPOSICION.match(linea)):
                en_preambulo = False
            else:
                preambulo.append(linea)
                continue

        # Secciones estructurales
        matched_sec = False
        for rx, tipo, nivel in RE_SECCION:
            m = rx.match(linea)
            if m:
                numero = normalizar_num_seccion(m.group(2))
                resto = limpiar_titulo(linea[m.end():])
                if not resto and i < n:
                    resto = limpiar_titulo(ps[i])
                    if resto:
                        i += 1
                abrir_seccion(tipo, numero, resto, nivel)
                matched_sec = True
                break
        if matched_sec:
            continue

        # Disposiciones
        if RE_DISPOSICION.match(linea):
            resto = limpiar_titulo(re.sub(RE_DISPOSICION, "", linea))
            if not resto and i < n:
                resto = limpiar_titulo(ps[i])
                if resto:
                    i += 1
            abrir_seccion("DISPOSICIONES", "ÚNICO", resto or "Disposiciones", 1)
            continue

        # Artículos
        m_art = RE_ARTICULO.match(linea)
        if m_art:
            num_texto = m_art.group(1).upper()
            art = nuevo_articulo(num_texto, seccion_actual_id())
            if i < n and ps[i].strip():
                sig = ps[i].strip()
                if (sig.isupper() and len(sig) < 90
                        and not RE_ARTICULO.match(sig)
                        and not any(rx.match(sig) for rx, _, _ in RE_SECCION)):
                    art["titulo"] = sig
                    i += 1
            continue

        m_inline = RE_ARTICULO_INLINE.match(linea)
        if m_inline:
            num_texto = m_inline.group(1).upper()
            art = nuevo_articulo(num_texto, seccion_actual_id())
            contenido = limpiar_titulo(linea[m_inline.end():])
            if contenido:
                art["parrafos"].append({"tipo": tipo_parrafo(contenido), "texto": contenido})
            continue

        # Items de Disposiciones (Primera., Única., etc.)
        if en_disposiciones:
            m_disp = RE_DISPOSICION_ITEM.match(linea)
            if m_disp:
                num_texto = m_disp.group(1).upper()
                art = nuevo_articulo(num_texto, seccion_actual_id())
                contenido = limpiar_titulo(linea[m_disp.end():])
                if contenido:
                    art["parrafos"].append({"tipo": "parrafo", "texto": contenido})
                continue
            # Contenido suelto dentro de una disposición sin ítem (p. ej.
            # Disposición Derogatoria que es un solo párrafo)
            if actual is None:
                art = nuevo_articulo(disp_numero, seccion_actual_id())
                art["parrafos"].append({"tipo": "parrafo", "texto": linea})
                continue

        # Contenido de artículo
        if actual is not None:
            if RE_PREAMBULO.match(linea):
                cerrar_articulo()
                en_preambulo = True
                preambulo = [linea]
                continue
            actual["parrafos"].append({"tipo": tipo_parrafo(linea), "texto": linea})
            continue

        # Texto suelto fuera de estructura (encabezados del documento)
        # Si aún no hay ninguna sección abierta, lo ignoramos.

    cerrar_articulo()

    # Etiquetas de sección
    por_id = {s["id"]: s for s in secciones}
    def etiqueta(sid):
        if not sid:
            return ""
        cur = por_id.get(sid)
        if not cur:
            return ""
        partes = []
        while cur:
            num = f"{cur['numero']}" if cur["numero"] else ""
            titulo = cur["titulo"] or ""
            partes.append(f"{cur['tipo']} {num}{': ' + titulo if titulo else ''}".strip())
            cur = por_id.get(cur["parent_id"]) if cur["parent_id"] else None
        return " · ".join(reversed(partes))

    for a in articulos:
        a["seccion_label"] = etiqueta(a["seccion_id"])

    # Cotejo CP
    if cat_entry["id"] == "codigo_penal_2005" and cotejo_cp:
        _aplicar_cotejo(articulos, cotejo_cp)

    return {
        "id": cat_entry["id"],
        "codigo": cat_entry["codigo"],
        "nombre": cat_entry["nombre"],
        "rama": cat_entry["rama"],
        "anio": cat_entry["anio"],
        "archivo": cat_entry["archivo"],
        "orden": cat_entry["orden"],
        "num_articulos": len(articulos),
        "num_secciones": len(secciones),
        "preambulo": "\n\n".join(preambulo) if preambulo else None,
        "secciones": secciones,
        "articulos": articulos,
    }

# ---------------------------------------------------------------------------
# 5. Cotejo Código Penal <-> Leyes Especiales
# ---------------------------------------------------------------------------
def _aplicar_cotejo(articulos, cotejo):
    for entrada in cotejo.get("analisis_articulos", []):
        m = re.search(r"Artículo\s+(\d+)", entrada.get("articulo_codigo_penal", ""))
        if not m:
            continue
        num = int(m.group(1))
        info = {
            "estatus": entrada.get("estatus"),
            "ley_especial": entrada.get("ley_especial_derogatoria"),
            "articulos_ley_especial": entrada.get("articulos_ley_especial"),
            "gaceta_ley_especial": entrada.get("gaceta_ley_especial"),
            "pena_ley_especial": entrada.get("pena_ley_especial"),
            "nota": (entrada.get("verificacion") or {}).get("nota"),
            "epigrafe": entrada.get("epigrafe_original"),
        }
        for a in articulos:
            if a["numero"] == num:
                a["cotejo"] = info

# ---------------------------------------------------------------------------
# 6. Ejecución
# ---------------------------------------------------------------------------
def main():
    os.makedirs(SALIDA_DIR, exist_ok=True)
    cat = catalogar()
    print("=" * 80)
    print(f"PARSER DOCX -> JSON | {len(cat)} leyes penales incluidas")
    print("=" * 80)

    cotejo_cp = None
    if os.path.exists(COTEJO_PATH):
        with open(COTEJO_PATH, encoding="utf-8") as f:
            cotejo_cp = json.load(f)
        print(f"📋 Cotejo CP cargado: {len(cotejo_cp.get('analisis_articulos', []))} entradas")

    total_arts = 0
    indice = []
    for entry in cat:
        try:
            ley = parsear_ley(entry, cotejo_cp)
        except Exception as e:
            import traceback
            print(f"  [✗] {entry['codigo']:<10} {entry['nombre'][:40]:<40} ERROR: {e}")
            traceback.print_exc()
            continue
        ruta_salida = os.path.join(SALIDA_DIR, f"{entry['id']}.json")
        with open(ruta_salida, "w", encoding="utf-8") as f:
            json.dump(ley, f, ensure_ascii=False, indent=1)
        total_arts += ley["num_articulos"]
        indice.append({
            "id": ley["id"], "codigo": ley["codigo"], "nombre": ley["nombre"],
            "rama": ley["rama"], "anio": ley["anio"], "archivo": ley["archivo"],
            "orden": ley["orden"], "num_articulos": ley["num_articulos"],
            "num_secciones": ley["num_secciones"],
        })
        print(f"  [✓] {ley['codigo']:<10} {ley['nombre'][:45]:<45} "
              f"{ley['num_articulos']:>4} arts | {ley['num_secciones']:>3} secs")

    with open(os.path.join(SALIDA_DIR, "_indice.json"), "w", encoding="utf-8") as f:
        json.dump({
            "generado": datetime.now(timezone.utc).isoformat(),
            "total_leyes": len(indice),
            "total_articulos": total_arts,
            "fuente": "Leyes en word/ (DOCX oficiales)",
            "leyes": indice,
        }, f, ensure_ascii=False, indent=1)

    print("=" * 80)
    print(f"✅ {len(indice)} leyes → {SALIDA_DIR}/  | {total_arts:,} artículos")
    print("=" * 80)


if __name__ == "__main__":
    main()
