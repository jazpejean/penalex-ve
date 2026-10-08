#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Integra nuevos modelos/documentos al banco de estilos de Ulpiano.

USO (3 pasos):
  1. Copia los archivos nuevos (.doc / .docx / .pdf) a:  ejemplos/entrada/
     (si pones subcarpetas dentro de entrada/, cada subcarpeta se
      convierte en una categoría del banco, ej. "MEDIDA CAUTELAR")
  2. Ejecuta:  python3 integrar_modelos.py
  3. Listo: quedan en ejemplos_estilos/ sanitizados y el manifest.json
     se actualiza solo. Los originales se mueven a entrada/procesados/.

Qué hace por cada archivo:
  - copia el original a ejemplos/ (junto a los demás modelos)
  - convierte a texto plano (LibreOffice para .doc/.docx, pdftotext para .pdf)
  - sanitiza: cédulas y números de causa -> [CÉDULA] / [CAUSA]
  - guarda el texto limpio en ejemplos_texto/ y el estilizado en ejemplos_estilos/
  - regenera manifest.json (índice categoría -> archivos)
"""
import os
import re
import shutil
import subprocess
import json
import sys

ROOT = os.path.dirname(os.path.abspath(__file__))
ENTRADA = os.path.join(ROOT, "ejemplos", "entrada")
PROCESADOS = os.path.join(ENTRADA, "procesados")
ORIGINALES = os.path.join(ROOT, "ejemplos")
TEXTO = os.path.join(ROOT, "ejemplos_texto")
ESTILOS = os.path.join(ROOT, "ejemplos_estilos")

RE_CEDULA = re.compile(r"\b[VEJ]-\s?\d{6,9}\b|\b[VEJ]-\s?\d{1,3}(?:\.\d{3}){2}\b")
RE_CAUSA = re.compile(r"\b\dU-\d{4}-\d{2}\b|\b\dU-\d{4}-\d{2,4}\b")


def sanitizar(texto: str) -> tuple[str, int, int]:
    nc = len(RE_CEDULA.findall(texto))
    nca = len(RE_CAUSA.findall(texto))
    texto = RE_CEDULA.sub("[CÉDULA]", texto)
    texto = RE_CAUSA.sub("[CAUSA]", texto)
    return texto, nc, nca


def convertir_a_texto(archivo: str, outdir: str) -> bool:
    os.makedirs(outdir, exist_ok=True)
    ext = os.path.splitext(archivo)[1].lower()
    env = dict(os.environ, HOME="/tmp")
    if ext == ".pdf":
        r = subprocess.run(["pdftotext", archivo,
                            os.path.join(outdir, os.path.splitext(os.path.basename(archivo))[0] + ".txt")],
                           capture_output=True, text=True, env=env)
        return r.returncode == 0
    r = subprocess.run(
        ["soffice", "-env:UserInstallation=file:///tmp/lo_profile",
         "--headless", "--convert-to", "txt:Text", "--outdir", outdir, archivo],
        capture_output=True, text=True, env=env)
    base = os.path.splitext(os.path.basename(archivo))[0]
    return os.path.exists(os.path.join(outdir, base + ".txt"))


def regenerar_manifest() -> None:
    manifest: dict[str, list[str]] = {}
    for root, _dirs, files in os.walk(ESTILOS):
        txts = sorted(x for x in files if x.endswith(".txt"))
        if not txts:
            continue
        manifest[os.path.relpath(root, ESTILOS)] = txts
    with open(os.path.join(ESTILOS, "manifest.json"), "w", encoding="utf-8") as fh:
        json.dump(manifest, fh, ensure_ascii=False, indent=2)


def main() -> int:
    docs = []
    for root, _dirs, files in os.walk(ENTRADA):
        if root.startswith(PROCESADOS):
            continue
        for f in files:
            if f.lower().endswith((".doc", ".docx", ".pdf")):
                docs.append(os.path.join(root, f))
    if not docs:
        print("No hay archivos nuevos en ejemplos/entrada/")
        return 0

    print(f"Procesando {len(docs)} archivo(s)...")
    nuevos, saltados = 0, 0
    for doc in sorted(docs):
        rel = os.path.relpath(os.path.dirname(doc), ENTRADA)  # subcarpeta = categoría
        nombre = os.path.basename(doc)
        destino_estilo = os.path.join(ESTILOS, rel, os.path.splitext(nombre)[0] + ".txt")
        if os.path.exists(destino_estilo):
            saltados += 1
            # También se mueve a procesados/ para no volver a revisarlo
            os.makedirs(os.path.join(PROCESADOS, rel), exist_ok=True)
            shutil.move(doc, os.path.join(PROCESADOS, rel, nombre))
            continue

        # 1) texto crudo
        out_raw = os.path.join(TEXTO, rel)
        if not convertir_a_texto(doc, out_raw):
            print(f"  FALLO conversión: {nombre}")
            continue
        # 2) sanitizar
        with open(os.path.join(out_raw, os.path.splitext(nombre)[0] + ".txt"),
                  encoding="utf-8-sig", errors="replace") as fh:
            texto = fh.read()
        limpio, nc, nca = sanitizar(texto)
        os.makedirs(os.path.dirname(destino_estilo), exist_ok=True)
        with open(destino_estilo, "w", encoding="utf-8") as fh:
            fh.write(limpio)
        # 3) original junto a los demás modelos
        if not os.path.exists(os.path.join(ORIGINALES, rel, nombre)):
            os.makedirs(os.path.join(ORIGINALES, rel), exist_ok=True)
            shutil.copy2(doc, os.path.join(ORIGINALES, rel, nombre))
        # 4) mover a procesados
        os.makedirs(os.path.join(PROCESADOS, rel), exist_ok=True)
        shutil.move(doc, os.path.join(PROCESADOS, rel, nombre))
        print(f"  + {nombre}  (cédulas: {nc}, causas: {nca})")
        nuevos += 1

    regenerar_manifest()
    total = sum(len(v) for v in json.load(open(os.path.join(ESTILOS, "manifest.json"), encoding="utf-8")).values())
    print(f"\nListo: {nuevos} nuevo(s), {saltados} ya existente(s).")
    print(f"Banco de estilos total: {total} documentos (ver ejemplos_estilos/manifest.json)")
    return 0


if __name__ == "__main__":
    sys.exit(main())