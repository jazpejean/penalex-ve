#!/usr/bin/env python3
"""
🔵 SCRAPER DE LEYES VENEZOLANAS - IAJURISS
============================================

Extrae leyes en formato PDF desde IaJuriss y las estructura jerárquicamente:
Preámbulo > Libro > Título > Capítulo > Artículo

USO EN GOOGLE COLAB:
1. Subir este archivo a Colab
2. Ejecutar: !python scraper_leyes_iajuriss_completo.py
3. Descargar el ZIP generado

Autor: Jean Peña - Penalex VE
Fecha: Julio 2026
"""

import requests
import json
import re
import os
from pathlib import Path
import time
from datetime import datetime

# ============================================================================
# CONFIGURACIÓN
# ============================================================================

# API de Supabase de IaJuriss
BASE_URL = 'https://khtepgjieasapanfxjft.supabase.co/rest/v1'
STORAGE_URL = 'https://khtepgjieasapanfxjft.supabase.co/storage/v1/object/public'
API_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtodGVwZ2ppZWFzYXBhbmZ4amZ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAxNDY3MzgsImV4cCI6MjA4NTcyMjczOH0.qt3TTd4EniWQevrm0XuxW0H8hsOx1-AIG8u6744mERk'

HEADERS = {
    'apikey': API_KEY,
    'Authorization': f'Bearer {API_KEY}'
}

# Directorios
OUTPUT_DIR = Path('/content/leyes_estructuradas') if os.path.exists('/content') else Path('./leyes_estructuradas')
PDF_DIR = OUTPUT_DIR / 'pdfs'
JSON_DIR = OUTPUT_DIR / 'json'
LOGS_DIR = OUTPUT_DIR / 'logs'

# Configuración
DELAY_BETWEEN_DOWNLOADS = 5  # segundos
MAX_LEYES = None  # None = todas, o número específico para testing

# ============================================================================
# FUNCIONES AUXILIARES
# ============================================================================

def crear_directorios():
    """Crea la estructura de directorios"""
    for dir_path in [OUTPUT_DIR, PDF_DIR, JSON_DIR, LOGS_DIR]:
        dir_path.mkdir(parents=True, exist_ok=True)
    print(f"✅ Directorios creados en: {OUTPUT_DIR}")

def log_mensaje(mensaje, archivo='scraper.log'):
    """Guarda un mensaje en el log"""
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    log_line = f"[{timestamp}] {mensaje}\\n"
    
    with open(LOGS_DIR / archivo, 'a', encoding='utf-8') as f:
        f.write(log_line)
    
    print(mensaje)

# ============================================================================
# PASO 1: OBTENER LISTA DE LEYES
# ============================================================================

def obtener_leyes():
    """Obtiene la lista de leyes desde la API de IaJuriss"""
    log_mensaje("=" * 80)
    log_mensaje("📚 OBTENIENDO LISTA DE LEYES DESDE IAJURISS")
    log_mensaje("=" * 80)
    
    try:
        response = requests.get(
            f'{BASE_URL}/leyes_venezolanas',
            headers=HEADERS,
            params={
                'select': '*',
                'esta_vigente': 'eq.true',
                'order': 'titulo_corto.asc'
            }
        )
        
        if response.status_code == 200:
            leyes = response.json()
            log_mensaje(f"✅ {len(leyes)} leyes obtenidas")
            
            # Guardar lista completa
            with open(JSON_DIR / 'lista_leyes.json', 'w', encoding='utf-8') as f:
                json.dump(leyes, f, indent=2, ensure_ascii=False)
            
            return leyes
        else:
            log_mensaje(f"❌ Error al obtener leyes: {response.status_code}")
            log_mensaje(response.text)
            return []
            
    except Exception as e:
        log_mensaje(f"❌ Excepción al obtener leyes: {e}")
        return []

# ============================================================================
# PASO 2: DESCARGAR PDF
# ============================================================================

def descargar_pdf(ley_info):
    """Descarga el PDF de una ley"""
    titulo = ley_info.get('titulo_corto', 'sin_titulo')
    ley_id = ley_info.get('id')
    nombre_archivo = ley_info.get('nombre_archivo')
    
    if not nombre_archivo:
        log_mensaje(f"⚠️  {titulo}: No tiene nombre_archivo, saltando")
        return None
    
    # Construir URL del PDF (suponiendo que está en Storage)
    # Ajustar según la estructura real de IaJuriss
    pdf_url = f"{STORAGE_URL}/leyes/{nombre_archivo}"
    
    try:
        log_mensaje(f"📥 Descargando: {titulo}")
        
        response = requests.get(pdf_url, timeout=30)
        
        if response.status_code == 200:
            # Guardar PDF
            pdf_filename = PDF_DIR / f"ley_{ley_id}_{nombre_archivo}"
            with open(pdf_filename, 'wb') as f:
                f.write(response.content)
            
            log_mensaje(f"   ✅ Descargado: {pdf_filename.name}")
            return pdf_filename
        else:
            log_mensaje(f"   ❌ Error {response.status_code}: {pdf_url}")
            return None
            
    except Exception as e:
        log_mensaje(f"   ❌ Excepción al descargar: {e}")
        return None

# ============================================================================
# PASO 3: EXTRAER TEXTO DEL PDF
# ============================================================================

def extraer_texto_pdf(pdf_path):
    """Extrae todo el texto de un PDF usando PyMuPDF"""
    try:
        import fitz  # PyMuPDF
        
        doc = fitz.open(pdf_path)
        texto_completo = ""
        
        for pagina_num in range(len(doc)):
            pagina = doc[pagina_num]
            texto_completo += pagina.get_text()
        
        doc.close()
        return texto_completo
        
    except ImportError:
        log_mensaje("❌ PyMuPDF no está instalado. Ejecuta: pip install PyMuPDF")
        return None
    except Exception as e:
        log_mensaje(f"❌ Error al extraer texto: {e}")
        return None

# ============================================================================
# PASO 4: PARSEAR ESTRUCTURA JERÁRQUICA
# ============================================================================

def parsear_estructura(texto, ley_info):
    """
    Parsea el texto de la ley y extrae la estructura jerárquica:
    Preámbulo > Libro > Título > Capítulo > Artículo
    """
    estructura = {
        "id": ley_info.get('id'),
        "titulo_oficial": ley_info.get('titulo_oficial'),
        "titulo_corto": ley_info.get('titulo_corto'),
        "metadata": ley_info,
        "preambulo": None,
        "libros": []
    }
    
    # TODO: Implementar parsing específico según el formato de cada ley
    # Esto requiere analizar manualmente algunos PDFs para entender su estructura
    
    # Por ahora, extraer artículos básicos
    # Patrón: "Artículo 123" o "Art. 123" o "Artículo 123."
    patron_articulo = r'(?:Artículo|Art\.?)\s+(\d+)\.?\s*[-:]?\s*(.+?)(?=(?:Artículo|Art\.?)\s+\d+|$)'
    
    articulos = re.findall(patron_articulo, texto, re.IGNORECASE | re.DOTALL)
    
    estructura['articulos'] = [
        {
            "numero": int(num),
            "texto": texto_art.strip()[:500]  # Primeros 500 caracteres
        }
        for num, texto_art in articulos
    ]
    
    log_mensaje(f"   📄 {len(estructura['articulos'])} artículos encontrados")
    
    return estructura

# ============================================================================
# MAIN: PROCESO COMPLETO
# ============================================================================

def main():
    """Proceso principal"""
    print("\\n" + "=" * 80)
    print("🔵 SCRAPER DE LEYES VENEZOLANAS - IAJURISS")
    print("=" * 80)
    print()
    
    # 1. Crear directorios
    crear_directorios()
    
    # 2. Obtener lista de leyes
    leyes = obtener_leyes()
    
    if not leyes:
        print("❌ No se pudieron obtener las leyes")
        return
    
    # Limitar si es necesario (para testing)
    if MAX_LEYES:
        leyes = leyes[:MAX_LEYES]
        log_mensaje(f"⚠️  Limitado a {MAX_LEYES} leyes para testing")
    
    # 3. Procesar cada ley
    log_mensaje("\\n" + "=" * 80)
    log_mensaje("📥 PROCESANDO LEYES")
    log_mensaje("=" * 80)
    
    leyes_procesadas = 0
    leyes_fallidas = 0
    
    for idx, ley in enumerate(leyes, 1):
        titulo = ley.get('titulo_corto', 'Sin título')
        
        log_mensaje(f"\\n[{idx}/{len(leyes)}] {titulo}")
        
        # Descargar PDF
        pdf_path = descargar_pdf(ley)
        
        if not pdf_path:
            leyes_fallidas += 1
            continue
        
        # Extraer texto
        texto = extraer_texto_pdf(pdf_path)
        
        if not texto:
            leyes_fallidas += 1
            continue
        
        # Parsear estructura
        estructura = parsear_estructura(texto, ley)
        
        # Guardar JSON
        json_filename = JSON_DIR / f"ley_{ley.get('id')}.json"
        with open(json_filename, 'w', encoding='utf-8') as f:
            json.dump(estructura, f, indent=2, ensure_ascii=False)
        
        log_mensaje(f"   ✅ Guardado: {json_filename.name}")
        leyes_procesadas += 1
        
        # Rate limiting
        if idx < len(leyes):
            time.sleep(DELAY_BETWEEN_DOWNLOADS)
    
    # 4. Resumen final
    log_mensaje("\\n" + "=" * 80)
    log_mensaje("📊 RESUMEN FINAL")
    log_mensaje("=" * 80)
    log_mensaje(f"✅ Leyes procesadas: {leyes_procesadas}")
    log_mensaje(f"❌ Leyes fallidas: {leyes_fallidas}")
    log_mensaje(f"📂 Resultados en: {OUTPUT_DIR}")
    log_mensaje("=" * 80)
    
    # 5. Crear ZIP (si está en Colab)
    if os.path.exists('/content'):
        log_mensaje("\\n📦 Creando archivo ZIP...")
        os.system(f"cd /content && zip -r leyes_estructuradas.zip leyes_estructuradas/")
        log_mensaje("✅ Archivo listo: /content/leyes_estructuradas.zip")
        log_mensaje("   Descárgalo desde el panel de archivos de Colab")

if __name__ == "__main__":
    main()
