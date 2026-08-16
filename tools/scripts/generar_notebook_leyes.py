#!/usr/bin/env python3
"""
Generador del notebook completo para scrapear leyes de IaJuriss
"""

import json

# Estructura del notebook
notebook = {
    "cells": [],
    "metadata": {
        "kernelspec": {
            "display_name": "Python 3",
            "language": "python",
            "name": "python3"
        },
        "language_info": {
            "name": "python",
            "version": "3.10.12"
        }
    },
    "nbformat": 4,
    "nbformat_minor": 2
}

# ========================================================================
# CELDA 0: Título y descripción
# ========================================================================
notebook['cells'].append({
    "cell_type": "markdown",
    "metadata": {},
    "source": [
        "# 📚 Scraper de Leyes Venezolanas - IaJuriss\\n",
        "## Extracción de estructura jerárquica: Preámbulo > Libro > Título > Capítulo > Artículo\\n",
        "\\n",
        "**Autor:** Jean Peña - Penalex VE\\n",
        "\\n",
        "**Fecha:** Julio 2026\\n",
        "\\n",
        "---\\n",
        "\\n",
        "### ✅ Características:\\n",
        "- Descarga PDFs de leyes desde Supabase de IaJuriss\\n",
        "- Extrae texto con PyMuPDF\\n",
        "- Parsea estructura jerárquica con regex\\n",
        "- Exporta JSON estructurado para Firestore\\n",
        "\\n",
        "### 📦 Stack:\\n",
        "- `requests` - Descargar PDFs\\n",
        "- `PyMuPDF (fitz)` - Extraer texto de PDF\\n",
        "- `re` - Parsear estructura\\n",
        "- `json` - Exportar datos\\n",
        "\\n",
        "### 📋 Instrucciones:\\n",
        "1. ▶️ Ejecutar CELDA 1 (instalar dependencias)\\n",
        "2. ▶️ Ejecutar CELDA 2 (configuración)\\n",
        "3. ▶️ Ejecutar CELDA 3 (obtener lista de leyes)\\n",
        "4. ▶️ Ejecutar CELDA 4 (descargar y procesar leyes)\\n",
        "5. ▶️ Ejecutar CELDA 5 (descargar resultados)"
    ]
})

# ========================================================================
# CELDA 1: Instalar dependencias
# ========================================================================
notebook['cells'].extend([
    {
        "cell_type": "markdown",
        "metadata": {},
        "source": ["---\\n## 📥 CELDA 1: Instalar Dependencias"]
    },
    {
        "cell_type": "code",
        "execution_count": None,
        "metadata": {},
        "outputs": [],
        "source": [
            "print(\"📦 Instalando dependencias...\\n\")\\n",
            "\\n",
            "!pip install -q PyMuPDF requests\\n",
            "\\n",
            "print(\"\\n✅ Dependencias instaladas\")\\n",
            "print(\"   - PyMuPDF (fitz): Extracción de texto de PDF\")\\n",
            "print(\"   - requests: Descarga de archivos\")"
        ]
    }
])

print("✅ Notebook generado con", len(notebook['cells']), "celdas")
print("   Guardando en: Scraper_Leyes_IaJuriss_Completo.ipynb")

with open('Scraper_Leyes_IaJuriss_Completo.ipynb', 'w', encoding='utf-8') as f:
    json.dump(notebook, f, indent=1, ensure_ascii=False)

print("✅ Archivo creado exitosamente")
