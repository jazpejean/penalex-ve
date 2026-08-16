#!/usr/bin/env python3
"""
Descarga las leyes ESENCIALES para PENALEX
Prioridad 1: CRBV, CP, COPP, Leyes penales especiales, Ley de Amparo
"""
import os
import re
import json
import time
import requests
from pathlib import Path
import PyPDF2
from dotenv import load_dotenv

load_dotenv()

# Configuración
OUTPUT_DIR = Path("tools/data/leyes")
PDF_DIR = OUTPUT_DIR / "pdfs"
TXT_DIR = OUTPUT_DIR / "textos"

# Crear directorios
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
PDF_DIR.mkdir(exist_ok=True)
TXT_DIR.mkdir(exist_ok=True)

print("=" * 80)
print("⚖️  DESCARGAR LEYES ESENCIALES PARA PENALEX")
print("=" * 80)

# ============================================================================
# LEYES PRIORITARIAS (En orden de importancia)
# ============================================================================

LEYES_ESENCIALES = [
    # PRIORIDAD MÁXIMA
    {
        'nombre': 'Constitución de Venezuela',
        'codigo': 'CRBV',
        'url': 'https://iajuriss.com/docs/leyes/constitucion_venezuela.pdf',
        'prioridad': 1
    },
    {
        'nombre': 'Código Penal Venezolano',
        'codigo': 'CP',
        'url': 'https://iajuriss.com/docs/leyes/codigo_penal.pdf',
        'prioridad': 1
    },
    {
        'nombre': 'Código Orgánico Procesal Penal',
        'codigo': 'COPP',
        'url': 'https://iajuriss.com/docs/leyes/copp_2012.pdf',
        'prioridad': 1
    },
    {
        'nombre': 'Ley de Amparo',
        'codigo': 'LOA',
        'url': 'https://iajuriss.com/docs/leyes/ley-organica-de-amparo-sobre-derechos-y-garantias-constitucionales.pdf',
        'prioridad': 1
    },
    
    # LEYES PENALES ESPECIALES
    {
        'nombre': 'Ley Orgánica sobre el Derecho de las Mujeres a una Vida Libre de Violencia',
        'codigo': 'LOSDMVLV',
        'url': 'https://iajuriss.com/docs/leyes/ley-mujer.pdf',
        'prioridad': 2
    },
    {
        'nombre': 'Ley Orgánica de Drogas',
        'codigo': 'LOD',
        'url': 'https://iajuriss.com/docs/leyes/lod_2010.pdf',
        'prioridad': 2
    },
    {
        'nombre': 'Ley contra la Delincuencia Organizada y Financiamiento al Terrorismo',
        'codigo': 'LCDOFT',
        'url': 'https://iajuriss.com/docs/leyes/ley-contra-delincuencia-organizada.pdf',
        'prioridad': 2
    },
    {
        'nombre': 'Ley contra el Secuestro y la Extorsión',
        'codigo': 'LCSE',
        'url': 'https://iajuriss.com/docs/leyes/ley-contra-secuestro-extorsion.pdf',
        'prioridad': 2
    },
    {
        'nombre': 'Ley sobre Hurto y Robo de Vehículos Automotores',
        'codigo': 'LHRVA',
        'url': 'https://iajuriss.com/docs/leyes/ley-hurto-robo-vehiculos.pdf',
        'prioridad': 2
    },
    {
        'nombre': 'Ley para el Desarme y Control de Armas y Municiones',
        'codigo': 'LDCAM',
        'url': 'https://iajuriss.com/docs/leyes/ley-desarme-armas.pdf',
        'prioridad': 2
    },
    {
        'nombre': 'Código Orgánico Penitenciario',
        'codigo': 'COP',
        'url': 'https://iajuriss.com/docs/leyes/g6647.pdf',
        'prioridad': 2
    },
    {
        'nombre': 'Ley Orgánica del Ministerio Público',
        'codigo': 'LOMP',
        'url': 'https://iajuriss.com/docs/leyes/ley-ministerio-publico.pdf',
        'prioridad': 2
    },
    {
        'nombre': 'Ley de Protección de Víctimas, Testigos y demás Sujetos Procesales',
        'codigo': 'LPVT',
        'url': 'https://iajuriss.com/docs/leyes/ley-proteccion-victimas.pdf',
        'prioridad': 2
    }
]

def descargar_pdf(url, destino):
    """Descarga un PDF desde URL"""
    try:
        print(f"   📥 Descargando desde {url[:60]}...")
        response = requests.get(url, timeout=60, stream=True)
        response.raise_for_status()
        
        with open(destino, 'wb') as f:
            total = 0
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)
                total += len(chunk)
                if total > 1024*1024:  # Cada MB
                    print(f"      {total // (1024*1024)} MB descargados...", end='\r')
        
        print(f"   ✅ Descargado: {destino.stat().st_size // 1024} KB")
        return True
        
    except requests.exceptions.HTTPError as e:
        if e.response.status_code == 404:
            print(f"   ⚠️  URL no encontrada (404) - puede tener nombre diferente")
        else:
            print(f"   ❌ Error HTTP {e.response.status_code}")
        return False
    except Exception as e:
        print(f"   ❌ Error: {str(e)[:60]}")
        return False

def extraer_texto_pdf(pdf_path):
    """Extrae texto de un PDF"""
    try:
        print(f"   📄 Extrayendo texto...")
        texto_completo = []
        
        with open(pdf_path, 'rb') as f:
            pdf_reader = PyPDF2.PdfReader(f)
            num_paginas = len(pdf_reader.pages)
            
            print(f"      Total páginas: {num_paginas}")
            
            for i in range(num_paginas):
                try:
                    page = pdf_reader.pages[i]
                    texto = page.extract_text()
                    if texto:
                        texto_completo.append(texto)
                    
                    if (i + 1) % 50 == 0:
                        print(f"      Procesadas {i+1}/{num_paginas} páginas...", end='\r')
                except:
                    continue
        
        resultado = '\n'.join(texto_completo)
        print(f"   ✅ Texto extraído: {len(resultado):,} caracteres")
        return resultado
        
    except Exception as e:
        print(f"   ⚠️  Error extrayendo texto: {str(e)[:60]}")
        return None

def limpiar_nombre_archivo(nombre):
    """Limpia nombre para usar como archivo"""
    return re.sub(r'[<>:"/\\|?*]', '_', nombre)

def procesar_ley(ley):
    """Descarga y procesa una ley"""
    print(f"\n{'='*80}")
    print(f"📚 {ley['nombre']}")
    print(f"   Código: {ley['codigo']}")
    print(f"{'='*80}")
    
    # Nombres de archivos
    nombre_limpio = limpiar_nombre_archivo(f"{ley['codigo']}_{ley['nombre']}")
    pdf_path = PDF_DIR / f"{ley['codigo']}.pdf"
    txt_path = TXT_DIR / f"{ley['codigo']}.txt"
    json_path = TXT_DIR / f"{ley['codigo']}.json"
    
    # Verificar si ya existe
    if pdf_path.exists() and txt_path.exists():
        print(f"   ⏭️  Ya procesada anteriormente")
        return True
    
    # Descargar PDF
    if not pdf_path.exists():
        if not descargar_pdf(ley['url'], pdf_path):
            return False
    else:
        print(f"   ⏭️  PDF ya existe")
    
    # Extraer texto
    if not txt_path.exists():
        texto = extraer_texto_pdf(pdf_path)
        if texto:
            with open(txt_path, 'w', encoding='utf-8') as f:
                f.write(texto)
            print(f"   💾 Texto guardado en: {txt_path}")
        else:
            print(f"   ⚠️  No se pudo extraer texto (puede ser imagen escaneada)")
    else:
        print(f"   ⏭️  Texto ya existe")
        with open(txt_path, 'r', encoding='utf-8') as f:
            texto = f.read()
    
    # Guardar metadata
    metadata = {
        'nombre': ley['nombre'],
        'codigo': ley['codigo'],
        'url': ley['url'],
        'prioridad': ley['prioridad'],
        'pdf_path': str(pdf_path),
        'txt_path': str(txt_path),
        'tamaño_pdf': pdf_path.stat().st_size if pdf_path.exists() else 0,
        'caracteres_texto': len(texto) if texto else 0,
        'procesado': True
    }
    
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(metadata, f, ensure_ascii=False, indent=2)
    
    print(f"   ✅ Ley procesada completamente")
    time.sleep(2)  # Rate limiting
    return True

# ============================================================================
# EJECUCIÓN PRINCIPAL
# ============================================================================

if __name__ == "__main__":
    
    print(f"\n📋 Leyes a descargar:")
    print(f"   Prioridad 1 (Core): 4 leyes")
    print(f"   Prioridad 2 (Especiales): {len([l for l in LEYES_ESENCIALES if l['prioridad'] == 2])} leyes")
    print(f"   Total: {len(LEYES_ESENCIALES)} leyes")
    
    input("\n▶️  Presiona Enter para comenzar la descarga...")
    
    exitosos = 0
    errores = 0
    
    # Procesar en orden de prioridad
    for prioridad in [1, 2]:
        leyes_prioridad = [l for l in LEYES_ESENCIALES if l['prioridad'] == prioridad]
        
        print(f"\n{'#'*80}")
        print(f"{'#'*80}")
        print(f"  PROCESANDO PRIORIDAD {prioridad}")
        print(f"{'#'*80}")
        print(f"{'#'*80}")
        
        for ley in leyes_prioridad:
            if procesar_ley(ley):
                exitosos += 1
            else:
                errores += 1
    
    print("\n" + "=" * 80)
    print("✅ DESCARGA COMPLETADA")
    print("=" * 80)
    print(f"\n📊 Resumen:")
    print(f"   Exitosas: {exitosos}/{len(LEYES_ESENCIALES)}")
    print(f"   Errores: {errores}")
    print(f"\n📁 Archivos guardados en:")
    print(f"   PDFs: {PDF_DIR}")
    print(f"   Textos: {TXT_DIR}")
    
    # Listar archivos descargados
    pdfs = list(PDF_DIR.glob("*.pdf"))
    txts = list(TXT_DIR.glob("*.txt"))
    
    print(f"\n📚 Leyes descargadas:")
    for pdf in sorted(pdfs):
        txt = TXT_DIR / f"{pdf.stem}.txt"
        estado = "✅ Texto OK" if txt.exists() else "⚠️  Sin texto"
        tamaño = pdf.stat().st_size // 1024
        print(f"   {pdf.stem:<15} {tamaño:>6} KB  {estado}")
    
    print("\n" + "=" * 80)
    print("🎯 PRÓXIMO PASO:")
    print("   1. Revisar que todas las leyes core se descargaron")
    print("   2. Ejecutar script de estructuración (extraer artículos)")
    print("   3. Cargar a Supabase")
    print("=" * 80 + "\n")
