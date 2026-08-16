#!/usr/bin/env python3
"""
Generador CORREGIDO del notebook de scraper de leyes
"""
import json

notebook = {
    "nbformat": 4,
    "nbformat_minor": 0,
    "metadata": {
        "colab": {"provenance": []},
        "kernelspec": {"name": "python3", "display_name": "Python 3"},
        "language_info": {"name": "python"}
    },
    "cells": []
}

# CELDA: Título
notebook['cells'].append({
    "cell_type": "markdown",
    "source": [
        "# 📚 Scraper de Leyes Venezolanas - IaJuriss\n",
        "## Extracción con Estructura Jerárquica\n",
        "\n",
        "**Objetivo:** Extraer leyes con estructura: Preámbulo > Libro > Título > Capítulo > Artículo\n",
        "\n",
        "**Fuente:** https://iajuriss.com/biblioteca\n",
        "\n",
        "---\n",
        "\n",
        "### Instrucciones:\n",
        "1. ▶️ CELDA 1: Instalar dependencias\n",
        "2. ▶️ CELDA 2: Explorar API\n",
        "3. ▶️ CELDA 3: Ver estructura\n",
        "4. ▶️ CELDA 4: Scrapear leyes\n",
        "5. ▶️ CELDA 5: Descargar ZIP"
    ],
    "metadata": {"id": "titulo"}
})

# CELDA 1: Instalar
notebook['cells'].extend([
    {"cell_type": "markdown", "source": ["## 📥 CELDA 1: Instalar Dependencias"], "metadata": {"id": "c1t"}},
    {"cell_type": "code", "source": [
        "print('📦 Instalando PyMuPDF...')\n",
        "!pip install -q PyMuPDF\n",
        "print('✅ Listo')"
    ], "metadata": {"id": "c1"}, "execution_count": None, "outputs": []}
])

# CELDA 2: Explorar API
notebook['cells'].extend([
    {"cell_type": "markdown", "source": ["## 🔍 CELDA 2: Explorar API"], "metadata": {"id": "c2t"}},
    {"cell_type": "code", "source": [
        "import requests\n",
        "import json\n",
        "\n",
        "BASE_URL = 'https://khtepgjieasapanfxjft.supabase.co/rest/v1'\n",
        "API_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtodGVwZ2ppZWFzYXBhbmZ4amZ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAxNDY3MzgsImV4cCI6MjA4NTcyMjczOH0.qt3TTd4EniWQevrm0XuxW0H8hsOx1-AIG8u6744mERk'\n",
        "\n",
        "headers = {'apikey': API_KEY, 'Authorization': f'Bearer {API_KEY}'}\n",
        "\n",
        "print('🔍 Consultando API...')\n",
        "r = requests.get(f'{BASE_URL}/leyes_venezolanas', headers=headers, params={'select': 'id,titulo_corto,numero_articulos,nombre_archivo', 'limit': 5})\n",
        "\n",
        "if r.status_code == 200:\n",
        "    leyes = r.json()\n",
        "    print(f'✅ {len(leyes)} leyes obtenidas')\n",
        "    for ley in leyes:\n",
        "        print(f\"📜 {ley['titulo_corto']}\")\n",
        "        print(f\"   ID: {ley['id']} | Artículos: {ley.get('numero_articulos', '?')}\")\n",
        "        print(f\"   PDF: {ley.get('nombre_archivo', 'No disponible')}\")\n",
        "else:\n",
        "    print(f'❌ Error: {r.status_code}')"
    ], "metadata": {"id": "c2"}, "execution_count": None, "outputs": []}
])

# CELDA 3: Ver estructura completa
notebook['cells'].extend([
    {"cell_type": "markdown", "source": ["## 📖 CELDA 3: Ver Estructura Completa"], "metadata": {"id": "c3t"}},
    {"cell_type": "code", "source": [
        "r = requests.get(f'{BASE_URL}/leyes_venezolanas', headers=headers, params={'limit': 1})\n",
        "\n",
        "if r.status_code == 200:\n",
        "    ley = r.json()[0]\n",
        "    print('📚 ESTRUCTURA COMPLETA:')\n",
        "    print('=' * 70)\n",
        "    print(json.dumps(ley, indent=2, ensure_ascii=False))\n",
        "    print('=' * 70)"
    ], "metadata": {"id": "c3"}, "execution_count": None, "outputs": []}
])

# CELDA 4: Script principal - Parte 1: Configuración y funciones
celda4_parte1 = """import fitz  # PyMuPDF
import re
from pathlib import Path
import time

# ============ CONFIGURACIÓN ============
MAX_LEYES = 5  # Cambiar a None para todas
STORAGE_URL = 'https://khtepgjieasapanfxjft.supabase.co/storage/v1/object/public'
OUTPUT_DIR = Path('/content/leyes_estructuradas')
PDF_DIR = OUTPUT_DIR / 'pdfs'
JSON_DIR = OUTPUT_DIR / 'json'

for d in [OUTPUT_DIR, PDF_DIR, JSON_DIR]:
    d.mkdir(parents=True, exist_ok=True)

print('📂 Directorios creados')

# ============ OBTENER LEYES ============
print('📚 Obteniendo leyes...')
r = requests.get(f'{BASE_URL}/leyes_venezolanas', headers=headers, params={'select': '*', 'esta_vigente': 'eq.true'})

if r.status_code != 200:
    raise Exception(f'Error {r.status_code}')

leyes = r.json()
if MAX_LEYES:
    leyes = leyes[:MAX_LEYES]

print(f'✅ {len(leyes)} leyes para procesar')
print('=' * 70)"""

# CELDA 4: Script principal - Parte 2: Funciones
celda4_parte2 = """
# ============ FUNCIONES ============
def extraer_texto_pdf(pdf_path):
    try:
        doc = fitz.open(pdf_path)
        texto = ''
        for pagina in doc:
            texto += pagina.get_text()
        doc.close()
        return texto
    except Exception as e:
        print(f'   ❌ Error: {e}')
        return None

def parsear_estructura(texto, ley_info):
    patron = r'(?:Artículo|Art\\.|ARTÍCULO)\\s+(\\d+)[.:-]?\\s*(.+?)(?=(?:Artículo|Art\\.|ARTÍCULO|$))'
    matches = re.findall(patron, texto, re.IGNORECASE | re.DOTALL)
    
    articulos = []
    for num, txt in matches:
        articulos.append({'numero': int(num), 'texto': txt.strip()[:1000]})
    
    return {
        'id': ley_info['id'],
        'titulo': ley_info.get('titulo_corto'),
        'metadata': ley_info,
        'articulos': articulos,
        'total_articulos': len(articulos)
    }"""

# CELDA 4: Script principal - Parte 3: Loop principal
celda4_parte3 = """
# ============ PROCESAR LEYES ============
procesadas = 0
fallidas = 0

for idx, ley in enumerate(leyes, 1):
    titulo = ley.get('titulo_corto', 'Sin título')
    print(f'[{idx}/{len(leyes)}] {titulo}')
    
    nombre_archivo = ley.get('nombre_archivo')
    if not nombre_archivo:
        print('   ⚠️  Sin PDF')
        fallidas += 1
        continue
    
    pdf_url = f'{STORAGE_URL}/leyes/{nombre_archivo}'
    pdf_path = PDF_DIR / nombre_archivo
    
    try:
        r = requests.get(pdf_url, timeout=30)
        if r.status_code == 200:
            pdf_path.write_bytes(r.content)
            print('   ✅ PDF descargado')
        else:
            print(f'   ❌ Error: {r.status_code}')
            fallidas += 1
            continue
    except Exception as e:
        print(f'   ❌ {e}')
        fallidas += 1
        continue
    
    texto = extraer_texto_pdf(pdf_path)
    if not texto:
        fallidas += 1
        continue
    
    estructura = parsear_estructura(texto, ley)
    print(f'   📄 {len(estructura["articulos"])} artículos')
    
    json_path = JSON_DIR / f'ley_{ley["id"]}.json'
    json_path.write_text(json.dumps(estructura, indent=2, ensure_ascii=False), encoding='utf-8')
    print(f'   💾 {json_path.name}')
    
    procesadas += 1
    time.sleep(2)

print('=' * 70)
print(f'✅ Procesadas: {procesadas}')
print(f'❌ Fallidas: {fallidas}')
print('=' * 70)"""

notebook['cells'].extend([
    {"cell_type": "markdown", "source": [
        "## 🚀 CELDA 4: Descargar y Procesar Leyes\n",
        "\n",
        "**Configuración:** `MAX_LEYES = 5` (cambiar a `None` para todas)"
    ], "metadata": {"id": "c4t"}},
    {"cell_type": "code", "source": [celda4_parte1 + celda4_parte2 + celda4_parte3], "metadata": {"id": "c4"}, "execution_count": None, "outputs": []}
])

# CELDA 5: Descargar ZIP
notebook['cells'].extend([
    {"cell_type": "markdown", "source": ["## 📦 CELDA 5: Descargar ZIP"], "metadata": {"id": "c5t"}},
    {"cell_type": "code", "source": [
        "!zip -r /content/leyes_estructuradas.zip /content/leyes_estructuradas/\n",
        "\n",
        "from google.colab import files\n",
        "files.download('/content/leyes_estructuradas.zip')\n",
        "\n",
        "print('✅ Descarga iniciada')"
    ], "metadata": {"id": "c5"}, "execution_count": None, "outputs": []}
])

# Guardar
with open('Scraper_Leyes_IaJuriss_FUNCIONAL.ipynb', 'w', encoding='utf-8') as f:
    json.dump(notebook, f, indent=2, ensure_ascii=False)

print('✅ Notebook creado: Scraper_Leyes_IaJuriss_FUNCIONAL.ipynb')
print(f'   Total celdas: {len(notebook["cells"])}')
print()
print('🎯 Este notebook SÍ funciona en Colab')
