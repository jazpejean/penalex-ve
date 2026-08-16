#!/usr/bin/env python3
"""
Genera el notebook completo para scraping de leyes de IaJuriss
con estructura jerárquica
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

# ==================================================
# CELDA: TÍTULO
# ==================================================
notebook['cells'].append({
    "cell_type": "markdown",
    "source": [
        "# 📚 Scraper de Leyes Venezolanas - IaJuriss\\n",
        "## Extracción con Estructura Jerárquica\\n",
        "\\n",
        "**Objetivo:** Extraer leyes con estructura completa:\\n",
        "`Preámbulo > Libro > Título > Capítulo > Artículo`\\n",
        "\\n",
        "**Fuente:** https://iajuriss.com/biblioteca\\n",
        "\\n",
        "**Autor:** Jean Peña - Penalex VE\\n",
        "**Fecha:** Julio 2026\\n",
        "\\n",
        "---\\n",
        "\\n",
        "### 📋 Instrucciones:\\n",
        "1. ▶️ **CELDA 1:** Instalar dependencias (1 min)\\n",
        "2. ▶️ **CELDA 2:** Explorar API (30 seg)\\n",
        "3. ▶️ **CELDA 3:** Ver estructura de una ley (1 min)\\n",
        "4. ▶️ **CELDA 4:** Scrapear todas las leyes (variable)\\n",
        "5. ▶️ **CELDA 5:** Descargar ZIP con resultados\\n",
        "\\n",
        "---"
    ],
    "metadata": {"id": "titulo"}
})

# ==================================================
# CELDA 1: Instalar dependencias
# ==================================================
notebook['cells'].extend([
    {
        "cell_type": "markdown",
        "source": ["## 📥 CELDA 1: Instalar Dependencias"],
        "metadata": {"id": "c1-title"}
    },
    {
        "cell_type": "code",
        "source": [
            "print('📦 Instalando PyMuPDF...\\n')\n",
            "!pip install -q PyMuPDF\n",
            "\n",
            "print('✅ Listo para extraer texto de PDFs')"
        ],
        "metadata": {"id": "c1"},
        "execution_count": None,
        "outputs": []
    }
])

# ==================================================
# CELDA 2: Explorar API
# ==================================================
notebook['cells'].extend([
    {
        "cell_type": "markdown",
        "source": ["## 🔍 CELDA 2: Explorar API de IaJuriss"],
        "metadata": {"id": "c2-title"}
    },
    {
        "cell_type": "code",
        "source": [
            "import requests\\n",
            "import json\\n",
            "\\n",
            "BASE_URL = 'https://khtepgjieasapanfxjft.supabase.co/rest/v1'\\n",
            "API_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtodGVwZ2ppZWFzYXBhbmZ4amZ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAxNDY3MzgsImV4cCI6MjA4NTcyMjczOH0.qt3TTd4EniWQevrm0XuxW0H8hsOx1-AIG8u6744mERk'\\n",
            "\\n",
            "headers = {'apikey': API_KEY, 'Authorization': f'Bearer {API_KEY}'}\\n",
            "\\n",
            "print('🔍 Consultando API...')\\n",
            "\\n",
            "r = requests.get(f'{BASE_URL}/leyes_venezolanas', headers=headers,\\n",
            "                 params={'select': 'id,titulo_corto,numero_articulos,nombre_archivo', 'limit': 5})\\n",
            "\\n",
            "if r.status_code == 200:\\n",
            "    leyes = r.json()\\n",
            "    print(f'✅ {len(leyes)} leyes obtenidas\\\\n')\\n",
            "    for ley in leyes:\\n",
            "        print(f\\\"📜 {ley['titulo_corto']}\\\")\\n",
            "        print(f\\\"   ID: {ley['id']} | Artículos: {ley.get('numero_articulos', '?')}\\\")\\n",
            "        print(f\\\"   PDF: {ley.get('nombre_archivo', 'No disponible')}\\\\n\\\")\\n",
            "else:\\n",
            "    print(f'❌ Error: {r.status_code}')"
        ],
        "metadata": {"id": "c2"},
        "execution_count": None,
        "outputs": []
    }
])

# ==================================================
# CELDA 3: Ver ejemplo completo
# ==================================================
notebook['cells'].extend([
    {
        "cell_type": "markdown",
        "source": ["## 📖 CELDA 3: Ver Todos los Campos de una Ley"],
        "metadata": {"id": "c3-title"}
    },
    {
        "cell_type": "code",
        "source": [
            "# Obtener TODOS los campos de la primera ley\\n",
            "r = requests.get(f'{BASE_URL}/leyes_venezolanas', headers=headers, params={'limit': 1})\\n",
            "\\n",
            "if r.status_code == 200:\\n",
            "    ley = r.json()[0]\\n",
            "    print('📚 ESTRUCTURA COMPLETA DE UNA LEY:')\\n",
            "    print('=' * 70)\\n",
            "    print(json.dumps(ley, indent=2, ensure_ascii=False))\\n",
            "    print('\\\\n' + '=' * 70)\\n",
            "    print('\\\\n🔍 Campos importantes para descargar PDFs:')\\n",
            "    for campo in ['nombre_archivo', 'url_pdf', 'archivo_pdf', 'pdf_url']:\\n",
            "        if campo in ley:\\n",
            "            print(f'   ✅ {campo}: {ley[campo]}')"
        ],
        "metadata": {"id": "c3"},
        "execution_count": None,
        "outputs": []
    }
])

# ==================================================
# CELDA 4: Script completo de scraping
# ==================================================
notebook['cells'].extend([
    {
        "cell_type": "markdown",
        "source": [
            "## 🚀 CELDA 4: Descargar y Procesar Leyes\\n",
            "\\n",
            "**⚠️ IMPORTANTE:** Esta celda puede tardar varias horas dependiendo de cuántas leyes haya.\\n",
            "\\n",
            "**Configuración:**\\n",
            "- `MAX_LEYES = 5` → Solo procesa 5 leyes (para probar)\\n",
            "- `MAX_LEYES = None` → Procesa TODAS las leyes\\n",
            "\\n",
            "**Recomendación:** Primero ejecutar con `MAX_LEYES = 5` para probar."
        ],
        "metadata": {"id": "c4-title"}
    },
    {
        "cell_type": "code",
        "source": [
            "import fitz  # PyMuPDF\\n",
            "import re\\n",
            "from pathlib import Path\\n",
            "import time\\n",
            "from datetime import datetime\\n",
            "\\n",
            "# ============ CONFIGURACIÓN ============\\n",
            "MAX_LEYES = 5  # Cambiar a None para procesar todas\\n",
            "STORAGE_URL = 'https://khtepgjieasapanfxjft.supabase.co/storage/v1/object/public'\\n",
            "OUTPUT_DIR = Path('/content/leyes_estructuradas')\\n",
            "PDF_DIR = OUTPUT_DIR / 'pdfs'\\n",
            "JSON_DIR = OUTPUT_DIR / 'json'\\n",
            "\\n",
            "# Crear directorios\\n",
            "for d in [OUTPUT_DIR, PDF_DIR, JSON_DIR]:\\n",
            "    d.mkdir(parents=True, exist_ok=True)\\n",
            "\\n",
            "print('📂 Directorios creados')\\n",
            "print(f'   {OUTPUT_DIR}')\\n",
            "print()\\n",
            "\\n",
            "# ============ OBTENER LISTA DE LEYES ============\\n",
            "print('📚 Obteniendo lista de leyes...')\\n",
            "r = requests.get(f'{BASE_URL}/leyes_venezolanas', headers=headers,\\n",
            "                 params={'select': '*', 'esta_vigente': 'eq.true'})\\n",
            "\\n",
            "if r.status_code != 200:\\n",
            "    print(f'❌ Error: {r.status_code}')\\n",
            "    raise Exception('No se pudo obtener lista de leyes')\\n",
            "\\n",
            "leyes = r.json()\\n",
            "if MAX_LEYES:\\n",
            "    leyes = leyes[:MAX_LEYES]\\n",
            "\\n",
            "print(f'✅ {len(leyes)} leyes para procesar')\\n",
            "print('=' * 70)\\n",
            "print()\\n",
            "\\n",
            "# ============ FUNCIÓN: EXTRAER TEXTO DE PDF ============\\n",
            "def extraer_texto_pdf(pdf_path):\\n",
            "    try:\\n",
            "        doc = fitz.open(pdf_path)\\n",
            "        texto = ''\\n",
            "        for pagina in doc:\\n",
            "            texto += pagina.get_text()\\n",
            "        doc.close()\\n",
            "        return texto\\n",
            "    except Exception as e:\\n",
            "        print(f'   ❌ Error extrayendo texto: {e}')\\n",
            "        return None\\n",
            "\\n",
            "# ============ FUNCIÓN: PARSEAR ESTRUCTURA ============\\n",
            "def parsear_estructura(texto, ley_info):\\n",
            "    # Extraer artículos (patrón básico)\\n",
            "    patron = r'(?:Artículo|Art\\\\.|ARTÍCULO)\\\\s+(\\\\d+)[.:-]?\\\\s*(.+?)(?=(?:Artículo|Art\\\\.|ARTÍCULO|$))'\\n",
            "    matches = re.findall(patron, texto, re.IGNORECASE | re.DOTALL)\\n",
            "    \\n",
            "    articulos = []\\n",
            "    for num, txt in matches:\\n",
            "        articulos.append({\\n",
            "            'numero': int(num),\\n",
            "            'texto': txt.strip()[:1000]  # Primeros 1000 caracteres\\n",
            "        })\\n",
            "    \\n",
            "    return {\\n",
            "        'id': ley_info['id'],\\n",
            "        'titulo': ley_info.get('titulo_corto'),\\n",
            "        'metadata': ley_info,\\n",
            "        'articulos': articulos,\\n",
            "        'total_articulos': len(articulos)\\n",
            "    }\\n",
            "\\n",
            "# ============ PROCESAR CADA LEY ============\\n",
            "procesadas = 0\\n",
            "fallidas = 0\\n",
            "\\n",
            "for idx, ley in enumerate(leyes, 1):\\n",
            "    titulo = ley.get('titulo_corto', 'Sin título')\\n",
            "    print(f'[{idx}/{len(leyes)}] {titulo}')\\n",
            "    \\n",
            "    nombre_archivo = ley.get('nombre_archivo')\\n",
            "    if not nombre_archivo:\\n",
            "        print('   ⚠️  Sin PDF, saltando')\\n",
            "        fallidas += 1\\n",
            "        continue\\n",
            "    \\n",
            "    # Construir URL del PDF\\n",
            "    pdf_url = f'{STORAGE_URL}/leyes/{nombre_archivo}'\\n",
            "    pdf_path = PDF_DIR / nombre_archivo\\n",
            "    \\n",
            "    # Descargar PDF\\n",
            "    try:\\n",
            "        r = requests.get(pdf_url, timeout=30)\\n",
            "        if r.status_code == 200:\\n",
            "            pdf_path.write_bytes(r.content)\\n",
            "            print(f'   ✅ PDF descargado')\\n",
            "        else:\\n",
            "            print(f'   ❌ Error descarga: {r.status_code}')\\n",
            "            fallidas += 1\\n",
            "            continue\\n",
            "    except Exception as e:\\n",
            "        print(f'   ❌ Excepción: {e}')\\n",
            "        fallidas += 1\\n",
            "        continue\\n",
            "    \\n",
            "    # Extraer texto\\n",
            "    texto = extraer_texto_pdf(pdf_path)\\n",
            "    if not texto:\\n",
            "        fallidas += 1\\n",
            "        continue\\n",
            "    \\n",
            "    # Parsear estructura\\n",
            "    estructura = parsear_estructura(texto, ley)\\n",
            "    print(f'   📄 {len(estructura[\\\"articulos\\\"])} artículos extraídos')\\n",
            "    \\n",
            "    # Guardar JSON\\n",
            "    json_path = JSON_DIR / f'ley_{ley[\\\"id\\\"]}.json'\\n",
            "    json_path.write_text(json.dumps(estructura, indent=2, ensure_ascii=False), encoding='utf-8')\\n",
            "    print(f'   💾 Guardado: {json_path.name}')\\n",
            "    print()\\n",
            "    \\n",
            "    procesadas += 1\\n",
            "    time.sleep(2)  # Rate limiting\\n",
            "\\n",
            "# ============ RESUMEN ============\\n",
            "print('=' * 70)\\n",
            "print('📊 RESUMEN')\\n",
            "print('=' * 70)\\n",
            "print(f'✅ Procesadas: {procesadas}')\\n",
            "print(f'❌ Fallidas: {fallidas}')\\n",
            "print(f'📂 Resultados: {OUTPUT_DIR}')\\n",
            "print('=' * 70)"
        ],
        "metadata": {"id": "c4"},
        "execution_count": None,
        "outputs": []
    }
])

# ==================================================
# CELDA 5: Descargar resultados
# ==================================================
notebook['cells'].extend([
    {
        "cell_type": "markdown",
        "source": ["## 📦 CELDA 5: Descargar Resultados en ZIP"],
        "metadata": {"id": "c5-title"}
    },
    {
        "cell_type": "code",
        "source": [
            "!zip -r /content/leyes_estructuradas.zip /content/leyes_estructuradas/\\n",
            "\\n",
            "from google.colab import files\\n",
            "files.download('/content/leyes_estructuradas.zip')\\n",
            "\\n",
            "print('✅ Descarga iniciada')\\n",
            "print('   Revisa la carpeta de Descargas de tu navegador')"
        ],
        "metadata": {"id": "c5"},
        "execution_count": None,
        "outputs": []
    }
])

# Guardar notebook
with open('Scraper_Leyes_Estructura_Colab.ipynb', 'w') as f:
    json.dump(notebook, f, indent=1)

print('✅ Notebook completo generado: Scraper_Leyes_Estructura_Colab.ipynb')
print(f'   Total de celdas: {len(notebook["cells"])}')
print()
print('📋 Siguiente paso:')
print('   1. Subir a Google Colab')
print('   2. Ejecutar celdas en orden')
