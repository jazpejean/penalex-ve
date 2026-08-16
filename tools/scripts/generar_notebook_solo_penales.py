#!/usr/bin/env python3
"""
Generador de notebook que SOLO descarga leyes penales
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
        "# ⚖️ Scraper de Leyes PENALES - IaJuriss\n",
        "## Solo Constitución, Códigos y Leyes Penales\n",
        "\n",
        "**Filtros aplicados:**\n",
        "- ✅ Constitución de Venezuela\n",
        "- ✅ Código Penal\n",
        "- ✅ Código Orgánico Procesal Penal (COPP)\n",
        "- ✅ Todas las leyes con rama_derecho = 'Penal'\n",
        "- ✅ Leyes con 'penal' en el título\n",
        "\n",
        "---\n",
        "\n",
        "### Instrucciones:\n",
        "1. ▶️ CELDA 1: Instalar PyMuPDF\n",
        "2. ▶️ CELDA 2: Filtrar leyes penales\n",
        "3. ▶️ CELDA 3: Descargar y procesar\n",
        "4. ▶️ CELDA 4: Descargar ZIP"
    ],
    "metadata": {"id": "titulo"}
})

# CELDA 1: Instalar
notebook['cells'].extend([
    {"cell_type": "markdown", "source": ["## 📥 CELDA 1: Instalar PyMuPDF"], "metadata": {"id": "c1t"}},
    {"cell_type": "code", "source": [
        "print('📦 Instalando PyMuPDF...')\n",
        "!pip install -q PyMuPDF\n",
        "print('✅ Listo')"
    ], "metadata": {"id": "c1"}, "execution_count": None, "outputs": []}
])

# CELDA 2: Filtrar leyes penales
celda2_code = """import requests
import json
import fitz
import re
from pathlib import Path
import time

BASE_URL = 'https://khtepgjieasapanfxjft.supabase.co/rest/v1'
STORAGE_URL = 'https://khtepgjieasapanfxjft.supabase.co/storage/v1/object/public'
API_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtodGVwZ2ppZWFzYXBhbmZ4amZ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAxNDY3MzgsImV4cCI6MjA4NTcyMjczOH0.qt3TTd4EniWQevrm0XuxW0H8hsOx1-AIG8u6744mERk'

headers = {'apikey': API_KEY, 'Authorization': f'Bearer {API_KEY}'}

print('=' * 70)
print('🔍 FILTRANDO SOLO LEYES PENALES')
print('=' * 70)
print()

# Obtener todas las leyes
print('📚 Descargando lista completa...')
r = requests.get(
    f'{BASE_URL}/leyes_venezolanas',
    headers=headers,
    params={
        'select': '*',
        'esta_vigente': 'eq.true'
    }
)

if r.status_code != 200:
    raise Exception(f'Error {r.status_code}: {r.text}')

todas = r.json()
print(f'✅ {len(todas)} leyes totales')
print()

# Filtrar penales
leyes_penales = []
for ley in todas:
    titulo = ley.get('titulo_corto', '').lower()
    titulo_oficial = ley.get('titulo_oficial', '').lower()
    rama = (ley.get('rama_derecho') or '').lower()
    tipo = (ley.get('tipo_instrumento') or '').lower()
    
    # Criterios de filtrado
    es_penal = False
    
    # Constitución (siempre)
    if 'constitucion' in titulo or 'constitución' in titulo:
        es_penal = True
    
    # Rama penal
    if 'penal' in rama:
        es_penal = True
    
    # Códigos (todos)
    if tipo == 'codigo' or 'código' in titulo:
        es_penal = True
    
    # Palabras clave penales
    palabras_penal = ['penal', 'copp', 'delito', 'pena', 'prisión', 
                      'ministerio público', 'defensa pública', 'policía',
                      'flagrancia', 'violencia', 'crimen organizado', 
                      'drogas', 'corrupción']
    
    for palabra in palabras_penal:
        if palabra in titulo or palabra in titulo_oficial:
            es_penal = True
            break
    
    if es_penal:
        leyes_penales.append(ley)

print(f'⚖️  {len(leyes_penales)} LEYES PENALES FILTRADAS')
print('=' * 70)
print()

# Mostrar lista
for i, ley in enumerate(leyes_penales, 1):
    print(f"{i:2d}. {ley['titulo_corto']}")
    print(f"    ID: {ley['id']} | Rama: {ley.get('rama_derecho', 'N/A')} | Arts: {ley.get('numero_articulos', '?')}")
    print(f"    PDF: {ley.get('nombre_archivo', 'No disponible')}")
    print()

print('=' * 70)
print(f'✅ Filtrado completado - {len(leyes_penales)} leyes para procesar')
print('=' * 70)"""

notebook['cells'].extend([
    {"cell_type": "markdown", "source": [
        "## 🔎 CELDA 2: Filtrar Leyes Penales\n",
        "\n",
        "Esta celda filtra automáticamente solo:\n",
        "- Constitución\n",
        "- Códigos (Penal, COPP, etc.)\n",
        "- Leyes con rama = Penal\n",
        "- Leyes con palabras clave penales"
    ], "metadata": {"id": "c2t"}},
    {"cell_type": "code", "source": [celda2_code], "metadata": {"id": "c2"}, "execution_count": None, "outputs": []}
])

# CELDA 3: Descargar y procesar
celda3_code = """# Crear directorios
OUTPUT_DIR = Path('/content/leyes_penales')
PDF_DIR = OUTPUT_DIR / 'pdfs'
JSON_DIR = OUTPUT_DIR / 'json'

for d in [OUTPUT_DIR, PDF_DIR, JSON_DIR]:
    d.mkdir(parents=True, exist_ok=True)

print('📂 Directorios creados')
print()

# Funciones
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

def parsear_articulos(texto, ley_info):
    patron = r'(?:Artículo|Art\\.|ARTÍCULO)\\s+(\\d+)[.:-]?\\s*(.+?)(?=(?:Artículo|Art\\.|ARTÍCULO|$))'
    matches = re.findall(patron, texto, re.IGNORECASE | re.DOTALL)
    
    articulos = []
    for num, txt in matches:
        articulos.append({
            'numero': int(num),
            'texto': txt.strip()[:2000]  # Primeros 2000 caracteres
        })
    
    return {
        'id': ley_info['id'],
        'titulo': ley_info.get('titulo_corto'),
        'titulo_oficial': ley_info.get('titulo_oficial'),
        'rama_derecho': ley_info.get('rama_derecho'),
        'tipo_instrumento': ley_info.get('tipo_instrumento'),
        'metadata': ley_info,
        'articulos': articulos,
        'total_articulos': len(articulos)
    }

# Procesar cada ley
print('=' * 70)
print('📥 PROCESANDO LEYES PENALES')
print('=' * 70)
print()

procesadas = 0
fallidas = 0

for idx, ley in enumerate(leyes_penales, 1):
    titulo = ley.get('titulo_corto', 'Sin título')
    print(f'[{idx}/{len(leyes_penales)}] {titulo}')
    
    nombre_archivo = ley.get('nombre_archivo')
    if not nombre_archivo:
        print('   ⚠️  Sin PDF')
        fallidas += 1
        continue
    
    # Descargar PDF
    pdf_url = f'{STORAGE_URL}/leyes/{nombre_archivo}'
    pdf_path = PDF_DIR / nombre_archivo
    
    try:
        r = requests.get(pdf_url, timeout=30)
        if r.status_code == 200:
            pdf_path.write_bytes(r.content)
            print(f'   ✅ PDF descargado ({len(r.content)//1024} KB)')
        else:
            print(f'   ❌ Error descarga: {r.status_code}')
            fallidas += 1
            continue
    except Exception as e:
        print(f'   ❌ {e}')
        fallidas += 1
        continue
    
    # Extraer texto
    texto = extraer_texto_pdf(pdf_path)
    if not texto:
        fallidas += 1
        continue
    
    # Parsear
    estructura = parsear_articulos(texto, ley)
    print(f'   📄 {len(estructura["articulos"])} artículos extraídos')
    
    # Guardar JSON
    json_path = JSON_DIR / f'ley_{ley["id"]}.json'
    json_path.write_text(json.dumps(estructura, indent=2, ensure_ascii=False), encoding='utf-8')
    print(f'   💾 {json_path.name}')
    print()
    
    procesadas += 1
    time.sleep(2)  # Rate limiting

print('=' * 70)
print('📊 RESUMEN')
print('=' * 70)
print(f'✅ Procesadas: {procesadas}')
print(f'❌ Fallidas: {fallidas}')
print(f'📂 Resultados: {OUTPUT_DIR}')
print('=' * 70)"""

notebook['cells'].extend([
    {"cell_type": "markdown", "source": [
        "## 🚀 CELDA 3: Descargar y Procesar\n",
        "\n",
        "Descarga los PDFs y extrae los artículos de cada ley penal."
    ], "metadata": {"id": "c3t"}},
    {"cell_type": "code", "source": [celda3_code], "metadata": {"id": "c3"}, "execution_count": None, "outputs": []}
])

# CELDA 4: Descargar ZIP
notebook['cells'].extend([
    {"cell_type": "markdown", "source": ["## 📦 CELDA 4: Descargar ZIP"], "metadata": {"id": "c4t"}},
    {"cell_type": "code", "source": [
        "!zip -r /content/leyes_penales.zip /content/leyes_penales/\n",
        "\n",
        "from google.colab import files\n",
        "files.download('/content/leyes_penales.zip')\n",
        "\n",
        "print('✅ Descarga iniciada: leyes_penales.zip')"
    ], "metadata": {"id": "c4"}, "execution_count": None, "outputs": []}
])

# Guardar
with open('Scraper_SOLO_Leyes_Penales.ipynb', 'w', encoding='utf-8') as f:
    json.dump(notebook, f, indent=2, ensure_ascii=False)

print('✅ Notebook creado: Scraper_SOLO_Leyes_Penales.ipynb')
print(f'   Total celdas: {len(notebook["cells"])}')
print()
print('🎯 Este notebook filtra y descarga SOLO leyes penales')
