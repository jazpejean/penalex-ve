#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Script maestro para convertir todos los PDFs de una carpeta a JSON estructurado.
Uso: python convertir_leyes.py [--carpeta ./pdfs] [--salida ./json]
"""

import re
import json
import sys
import os
from collections import OrderedDict
from typing import Dict, List, Optional, Tuple, Any, Union
import glob

import pdfplumber
from tqdm import tqdm

# =============================================================================
#  CONFIGURACIÓN DE PATRONES Y REGLAS POR LEY (igual que antes)
# =============================================================================

DEFAULT_CONFIG = {
    "nombre_ley": "Ley sin nombre",
    "ignorar_paginas": [],
    "patrones": {
        "libro": re.compile(r'^LIBRO\s+(PRIMERO|SEGUNDO|TERCERO|CUARTO|QUINTO|SEXTO|SÉPTIMO|OCTAVO|NOVENO|DÉCIMO)\s*$', re.I),
        "titulo": re.compile(r'^T[ÍI]TULO\s+([IVXLCDM]+|\d+)\s*$', re.I),
        "capitulo": re.compile(r'^CAP[ÍI]TULO\s+([IVXLCDM]+|\d+)\s*$', re.I),
        "seccion": re.compile(r'^SECCI[ÓO]N\s+([IVXLCDM]+|\d+)\s*$', re.I),
        "articulo": re.compile(r'^(Art[íI]culo|Artículo|ART[ÍI]CULO)\s+(\d+)([A-Za-z]?)[\s\-–]+(.*?)(?=\.\s*$|\.\s+[A-Z]|$)', re.I),
        "parrafo": re.compile(r'^P[áa]rrafo\s+(Primero|Segundo|Tercero|Cuarto|Quinto|Único|Unico|I|II|III|IV|V|VI|VII|VIII|IX|X)\s*$', re.I),
    },
    "limpiar_texto": True,
    "unir_lineas": True,
    "separador_articulo": "\n\n",
}

# Configuraciones particulares para cada ley (sobrescriben DEFAULT_CONFIG)
LEY_CONFIGS = {
    "copp": {
        "nombre_ley": "Código Orgánico Procesal Penal",
        "patrones": {
            "libro": re.compile(r'^LIBRO\s+(PRIMERO|SEGUNDO|TERCERO|CUARTO|QUINTO|SEXTO|SÉPTIMO|OCTAVO|NOVENO|DÉCIMO)\s*$', re.I),
            "titulo": re.compile(r'^T[ÍI]TULO\s+([IVXLCDM]+|\d+)\s*$', re.I),
            "capitulo": re.compile(r'^CAP[ÍI]TULO\s+([IVXLCDM]+|\d+)\s*$', re.I),
            "seccion": re.compile(r'^SECCI[ÓO]N\s+([IVXLCDM]+|\d+)\s*$', re.I),
            "articulo": re.compile(r'^(Art[íI]culo|Artículo|ART[ÍI]CULO)\s+(\d+)([A-Za-z]?)[\s\-–]+(.*?)(?=\.\s*$|\.\s+[A-Z]|$)', re.I),
            "parrafo": re.compile(r'^P[áa]rrafo\s+(Primero|Segundo|Tercero|Cuarto|Quinto|Único|Unico|I|II|III|IV|V|VI|VII|VIII|IX|X)\s*$', re.I),
        },
    },
    "cp": {
        "nombre_ley": "Código Penal",
        "patrones": {
            "libro": re.compile(r'^LIBRO\s+(PRIMERO|SEGUNDO|TERCERO|CUARTO|QUINTO|SEXTO|SÉPTIMO|OCTAVO|NOVENO|DÉCIMO)\s*$', re.I),
            "titulo": re.compile(r'^T[ÍI]TULO\s+([IVXLCDM]+|\d+)\s*$', re.I),
            "capitulo": re.compile(r'^CAP[ÍI]TULO\s+([IVXLCDM]+|\d+)\s*$', re.I),
            "seccion": re.compile(r'^SECCI[ÓO]N\s+([IVXLCDM]+|\d+)\s*$', re.I),
            "articulo": re.compile(r'^(Art[íI]culo|Artículo|ART[ÍI]CULO)\s+(\d+)([A-Za-z]?)[\s\-–]+(.*?)(?=\.\s*$|\.\s+[A-Z]|$)', re.I),
            "parrafo": re.compile(r'^P[áa]rrafo\s+(Primero|Segundo|Tercero|Cuarto|Quinto|Único|Unico|I|II|III|IV|V|VI|VII|VIII|IX|X)\s*$', re.I),
        },
    },
    "lopnna": {
        "nombre_ley": "Ley Orgánica para la Protección de Niños, Niñas y Adolescentes",
        "patrones": {
            "libro": re.compile(r'^LIBRO\s+(PRIMERO|SEGUNDO|TERCERO|CUARTO|QUINTO|SEXTO|SÉPTIMO|OCTAVO|NOVENO|DÉCIMO)\s*$', re.I),
            "titulo": re.compile(r'^T[ÍI]TULO\s+([IVXLCDM]+|\d+)\s*$', re.I),
            "capitulo": re.compile(r'^CAP[ÍI]TULO\s+([IVXLCDM]+|\d+)\s*$', re.I),
            "seccion": re.compile(r'^SECCI[ÓO]N\s+([IVXLCDM]+|\d+)\s*$', re.I),
            "articulo": re.compile(r'^(Art[íI]culo|Artículo|ART[ÍI]CULO)\s+(\d+)([A-Za-z]?)[\s\-–]+(.*?)(?=\.\s*$|\.\s+[A-Z]|$)', re.I),
            "parrafo": re.compile(r'^P[áa]rrafo\s+(Primero|Segundo|Tercero|Cuarto|Quinto|Único|Unico|I|II|III|IV|V|VI|VII|VIII|IX|X)\s*$', re.I),
        },
    },
    "lcdof": {
        "nombre_ley": "Ley Orgánica Contra la Delincuencia Organizada y Financiamiento al Terrorismo",
        "patrones": {
            "titulo": re.compile(r'^T[ÍI]TULO\s+([IVXLCDM]+|\d+)\s*$', re.I),
            "capitulo": re.compile(r'^CAP[ÍI]TULO\s+([IVXLCDM]+|\d+)\s*$', re.I),
            "seccion": re.compile(r'^SECCI[ÓO]N\s+([IVXLCDM]+|\d+)\s*$', re.I),
            "articulo": re.compile(r'^(Art[íI]culo|Artículo|ART[ÍI]CULO)\s+(\d+)([A-Za-z]?)[\s\-–]+(.*?)(?=\.\s*$|\.\s+[A-Z]|$)', re.I),
        },
    },
    "crbv": {
        "nombre_ley": "Constitución de la República Bolivariana de Venezuela",
        "patrones": {
            "titulo": re.compile(r'^T[ÍI]TULO\s+([IVXLCDM]+|\d+)\s*$', re.I),
            "capitulo": re.compile(r'^CAP[ÍI]TULO\s+([IVXLCDM]+|\d+)\s*$', re.I),
            "seccion": re.compile(r'^SECCI[ÓO]N\s+([IVXLCDM]+|\d+)\s*$', re.I),
            "articulo": re.compile(r'^(Art[íI]culo|Artículo|ART[ÍI]CULO)\s+(\d+)([A-Za-z]?)[\s\-–]+(.*?)(?=\.\s*$|\.\s+[A-Z]|$)', re.I),
        },
    },
    # Puedes agregar más configuraciones aquí (ej: "loa": {...})
}

# =============================================================================
#  FUNCIONES DE LIMPIEZA Y PREPROCESAMIENTO (igual que antes)
# =============================================================================

def clean_text(text: str) -> str:
    text = re.sub(r'[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]', '', text)
    text = re.sub(r'[ \t]+', ' ', text)
    text = re.sub(r'\n{3,}', '\n\n', text)
    return text.strip()

def unify_lines(text: str) -> str:
    lines = text.splitlines()
    unified = []
    i = 0
    while i < len(lines):
        line = lines[i].strip()
        if not line:
            unified.append('')
            i += 1
            continue
        if line.endswith('-') and i+1 < len(lines):
            next_line = lines[i+1].strip()
            if next_line and not re.match(r'^(Art[íI]culo|Cap[íI]tulo|T[íI]tulo|Secci[óo]n|Libro|Párrafo)', next_line, re.I):
                unified.append(line[:-1] + next_line)
                i += 2
                continue
        unified.append(line)
        i += 1
    return '\n'.join(unified)

# =============================================================================
#  PARSER DE JERARQUÍA (igual que antes)
# =============================================================================

class LeyParser:
    def __init__(self, config: Dict):
        self.config = config
        self.patrones = config.get("patrones", {})
        self.nombre_ley = config.get("nombre_ley", "Ley")

    def parse(self, texto: str) -> Dict:
        if self.config.get("limpiar_texto", True):
            texto = clean_text(texto)
        if self.config.get("unir_lineas", True):
            texto = unify_lines(texto)

        lineas = [line.strip() for line in texto.splitlines() if line.strip()]

        raiz = {
            "codigo": self.nombre_ley,
            "libros": [],
            "titulo_preliminar": None,
            "articulos_sueltos": []
        }

        pila = []
        articulo_actual = None
        articulo_contenido = []
        dentro_articulo = False

        for linea in lineas:
            if re.match(r'^\d+$', linea) or re.match(r'^GACETA OFICIAL', linea, re.I):
                continue

            match_libro = self._match_patron('libro', linea)
            match_titulo = self._match_patron('titulo', linea)
            match_capitulo = self._match_patron('capitulo', linea)
            match_seccion = self._match_patron('seccion', linea)
            match_articulo = self._match_patron('articulo', linea)

            if match_articulo:
                if dentro_articulo and articulo_actual:
                    self._finalizar_articulo(articulo_actual, articulo_contenido, pila, raiz)
                articulo_actual = {
                    "numero": int(match_articulo.group(2)),
                    "epigrafe": match_articulo.group(4).strip() or None,
                    "contenido": "",
                    "intro": None,
                    "items": [],
                    "parrafos_finales": []
                }
                articulo_contenido = []
                dentro_articulo = True
                continue

            if dentro_articulo:
                articulo_contenido.append(linea)
                continue

            if match_libro:
                libro = self._crear_libro(match_libro)
                self._cerrar_contexto(pila, raiz)
                pila.append({"tipo": "libro", "objeto": libro, "nivel": 0})
                continue

            if match_titulo:
                titulo = self._crear_titulo(match_titulo)
                if pila and pila[-1]["tipo"] == "libro":
                    pila[-1]["objeto"]["titulos"].append(titulo)
                    pila.append({"tipo": "titulo", "objeto": titulo, "nivel": 1})
                else:
                    if not raiz["titulo_preliminar"]:
                        raiz["titulo_preliminar"] = titulo
                    else:
                        if "titulos_extra" not in raiz:
                            raiz["titulos_extra"] = []
                        raiz["titulos_extra"].append(titulo)
                    pila.append({"tipo": "titulo", "objeto": titulo, "nivel": 1})
                continue

            if match_capitulo:
                capitulo = self._crear_capitulo(match_capitulo)
                if pila and pila[-1]["tipo"] == "titulo":
                    pila[-1]["objeto"]["capitulos"].append(capitulo)
                    pila.append({"tipo": "capitulo", "objeto": capitulo, "nivel": 2})
                else:
                    if "capitulos_sueltos" not in raiz:
                        raiz["capitulos_sueltos"] = []
                    raiz["capitulos_sueltos"].append(capitulo)
                    pila.append({"tipo": "capitulo", "objeto": capitulo, "nivel": 2})
                continue

            if match_seccion:
                seccion = self._crear_seccion(match_seccion)
                if pila and pila[-1]["tipo"] == "capitulo":
                    pila[-1]["objeto"]["secciones"].append(seccion)
                    pila.append({"tipo": "seccion", "objeto": seccion, "nivel": 3})
                else:
                    if "secciones_sueltas" not in raiz:
                        raiz["secciones_sueltas"] = []
                    raiz["secciones_sueltas"].append(seccion)
                    pila.append({"tipo": "seccion", "objeto": seccion, "nivel": 3})
                continue

        if dentro_articulo and articulo_actual:
            self._finalizar_articulo(articulo_actual, articulo_contenido, pila, raiz)

        self._cerrar_contexto(pila, raiz)
        self._limpiar_estructura(raiz)
        return raiz

    def _match_patron(self, clave: str, linea: str) -> Optional[re.Match]:
        patron = self.patrones.get(clave)
        if patron:
            return patron.match(linea)
        return None

    def _crear_libro(self, match):
        return {"numero": match.group(1).strip(), "nombre": match.group(1).strip(), "titulos": []}

    def _crear_titulo(self, match):
        return {"numero": match.group(1).strip(), "nombre": match.group(1).strip(), "capitulos": []}

    def _crear_capitulo(self, match):
        return {"numero": match.group(1).strip(), "nombre": match.group(1).strip(), "secciones": [], "articulos": []}

    def _crear_seccion(self, match):
        return {"numero": match.group(1).strip(), "nombre": match.group(1).strip(), "articulos": []}

    def _finalizar_articulo(self, articulo, contenido_lines, pila, raiz):
        contenido_raw = ' '.join(contenido_lines).strip()
        articulo_procesado = self._procesar_contenido_articulo(contenido_raw, articulo)
        if pila:
            ultimo = pila[-1]
            if ultimo["tipo"] == "seccion":
                ultimo["objeto"]["articulos"].append(articulo_procesado)
            elif ultimo["tipo"] == "capitulo":
                ultimo["objeto"]["articulos"].append(articulo_procesado)
            elif ultimo["tipo"] == "titulo":
                ultimo["objeto"]["articulos"].append(articulo_procesado)
            elif ultimo["tipo"] == "libro":
                if "articulos_sueltos" not in ultimo["objeto"]:
                    ultimo["objeto"]["articulos_sueltos"] = []
                ultimo["objeto"]["articulos_sueltos"].append(articulo_procesado)
        else:
            raiz["articulos_sueltos"].append(articulo_procesado)

    def _cerrar_contexto(self, pila, raiz):
        pila.clear()

    def _limpiar_estructura(self, obj):
        if isinstance(obj, dict):
            for key in list(obj.keys()):
                if isinstance(obj[key], list) and not obj[key]:
                    del obj[key]
                elif isinstance(obj[key], dict):
                    self._limpiar_estructura(obj[key])
                elif obj[key] is None:
                    del obj[key]
        elif isinstance(obj, list):
            for item in obj:
                if isinstance(item, dict):
                    self._limpiar_estructura(item)

    def _procesar_contenido_articulo(self, contenido: str, articulo_base: dict) -> dict:
        if not contenido:
            articulo_base["contenido"] = ""
            return articulo_base

        lineas = contenido.splitlines()
        if len(lineas) < 2:
            articulo_base["contenido"] = contenido
            return articulo_base

        items = []
        intro_lines = []
        final_lines = []
        modo = "intro"

        numeral_pattern = re.compile(r'^(\d+)\.\s+')
        literal_pattern = re.compile(r'^([a-zA-Z])\)\s+')

        i = 0
        while i < len(lineas):
            linea = lineas[i].strip()
            if not linea:
                i += 1
                continue

            m_num = numeral_pattern.match(linea)
            if m_num:
                numero = m_num.group(1)
                texto = linea[m_num.end():].strip()
                item = {"numero": numero, "texto": texto}
                literales = []
                i += 1
                while i < len(lineas):
                    next_line = lineas[i].strip()
                    m_lit = literal_pattern.match(next_line)
                    if m_lit:
                        lit_letra = m_lit.group(1)
                        lit_texto = next_line[m_lit.end():].strip()
                        literales.append({"literal": lit_letra, "texto": lit_texto})
                        i += 1
                    else:
                        if literales:
                            literales[-1]["texto"] += " " + next_line
                        else:
                            item["texto"] += " " + next_line
                        i += 1
                        if numeral_pattern.match(next_line):
                            break
                if literales:
                    item["literales"] = literales
                items.append(item)
                modo = "items"
                continue

            m_lit = literal_pattern.match(linea)
            if m_lit and not items:
                letra = m_lit.group(1)
                texto = linea[m_lit.end():].strip()
                items.append({"literal": letra, "texto": texto})
                i += 1
                modo = "items"
                continue

            if modo == "items":
                if re.match(r'^(P[áa]rrafo|En ningún caso|Si concurren|En caso de|Cuando)', linea, re.I):
                    final_lines.append(linea)
                    modo = "final"
                    i += 1
                    continue
                else:
                    if items:
                        last_item = items[-1]
                        if "literales" in last_item and last_item["literales"]:
                            last_item["literales"][-1]["texto"] += " " + linea
                        else:
                            last_item["texto"] += " " + linea
                    i += 1
                    continue

            if modo == "intro":
                intro_lines.append(linea)
                i += 1
                continue

            if modo == "final":
                final_lines.append(linea)
                i += 1
                continue

            intro_lines.append(linea)
            i += 1

        articulo_procesado = {
            "numero": articulo_base["numero"],
            "epigrafe": articulo_base.get("epigrafe")
        }
        if intro_lines:
            articulo_procesado["intro"] = ' '.join(intro_lines).strip()
        if items:
            articulo_procesado["items"] = items
        if final_lines:
            articulo_procesado["parrafos_finales"] = [line.strip() for line in final_lines if line.strip()]

        if not items and not intro_lines and not final_lines:
            articulo_procesado["contenido"] = contenido

        return articulo_procesado

# =============================================================================
#  FUNCIÓN PARA PROCESAR UN PDF INDIVIDUAL
# =============================================================================

def convertir_pdf_a_json(ruta_pdf: str, config_key: str = "default", output_file: str = None) -> Dict:
    config = DEFAULT_CONFIG.copy()
    if config_key in LEY_CONFIGS:
        for key, value in LEY_CONFIGS[config_key].items():
            if isinstance(value, dict) and key in config:
                config[key].update(value)
            else:
                config[key] = value

    texto_completo = ""
    with pdfplumber.open(ruta_pdf) as pdf:
        paginas_a_procesar = range(1, len(pdf.pages)+1)
        if config.get("ignorar_paginas"):
            paginas_a_procesar = [i for i in paginas_a_procesar if i not in config["ignorar_paginas"]]
        for i in tqdm(paginas_a_procesar, desc=f"Extrayendo {os.path.basename(ruta_pdf)}"):
            page = pdf.pages[i-1]
            texto = page.extract_text()
            if texto:
                texto_completo += texto + "\n"

    if not texto_completo.strip():
        raise ValueError(f"No se pudo extraer texto de {ruta_pdf}. ¿Está dañado o es escaneado?")

    parser = LeyParser(config)
    resultado = parser.parse(texto_completo)

    if output_file is None:
        base = os.path.splitext(os.path.basename(ruta_pdf))[0]
        output_file = f"{base}_estructurado.json"

    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(resultado, f, ensure_ascii=False, indent=2)

    print(f"✅ {os.path.basename(ruta_pdf)} -> {output_file}")
    return resultado

# =============================================================================
#  FUNCIÓN PARA PROCESAR TODOS LOS PDFs DE UNA CARPETA
# =============================================================================

def procesar_carpeta(carpeta: str, salida: str = None):
    """
    Busca todos los archivos .pdf en la carpeta, detecta la configuración según el nombre
    y convierte cada uno a JSON en la carpeta de salida (por defecto, la misma carpeta).
    """
    archivos = glob.glob(os.path.join(carpeta, "*.pdf"))
    if not archivos:
        print(f"❌ No se encontraron archivos PDF en {carpeta}")
        return

    if salida is None:
        salida = carpeta

    os.makedirs(salida, exist_ok=True)

    for ruta_pdf in archivos:
        nombre_base = os.path.splitext(os.path.basename(ruta_pdf))[0].lower()
        # Detectar configuración por nombre
        config_key = "default"
        for key in LEY_CONFIGS.keys():
            if key in nombre_base:
                config_key = key
                break
        # Si contiene "copp" pero también "cop" (Código Orgánico Procesal Penal) se puede afinar
        # pero es un ejemplo.

        output_file = os.path.join(salida, f"{nombre_base}.json")
        try:
            convertir_pdf_a_json(ruta_pdf, config_key=config_key, output_file=output_file)
        except Exception as e:
            print(f"❌ Error en {ruta_pdf}: {e}")

# =============================================================================
#  PUNTO DE ENTRADA (CLI)
# =============================================================================

if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Convierte PDFs de leyes venezolanas a JSON estructurado.")
    parser.add_argument("--carpeta", default=".", help="Carpeta donde están los PDFs (por defecto la actual)")
    parser.add_argument("--salida", default=None, help="Carpeta donde guardar los JSON (por defecto la misma)")
    args = parser.parse_args()

    procesar_carpeta(args.carpeta, args.salida)
