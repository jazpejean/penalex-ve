#!/usr/bin/env python3
"""
Descarga las 16 LEYES CONFIRMADAS para PENALEX
URLs verificadas manualmente en IAJuriss
"""
import os
import requests
from pathlib import Path
import PyPDF2
import json
import time

# Configuración
OUTPUT_DIR = Path("tools/data/leyes")
PDF_DIR = OUTPUT_DIR / "pdfs"
TXT_DIR = OUTPUT_DIR / "textos"

# Crear directorios
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
PDF_DIR.mkdir(exist_ok=True)
TXT_DIR.mkdir(exist_ok=True)

print("=" * 80)
print("⚖️  DESCARGAR 16 LEYES CONFIRMADAS PARA PENALEX")
print("=" * 80)

# ============================================================================
# 16 LEYES CON URLs VERIFICADAS
# ============================================================================

LEYES_CONFIRMADAS = [
    # CORE (4)
    {
        'codigo': 'CRBV',
        'nombre': 'Constitución de Venezuela',
        'url': 'https://iajuriss.com/docs/leyes/constitucion_venezuela.pdf'
    },
    {
        'codigo': 'CP',
        'nombre': 'Código Penal',
        'url': 'https://iajuriss.com/docs/leyes/codigo-penal-2005.pdf'
    },
    {
        'codigo': 'COPP',
        'nombre': 'Código Orgánico Procesal Penal',
        'url': 'https://iajuriss.com/docs/leyes/copp_2021.pdf'
    },
    {
        'codigo': 'LOA',
        'nombre': 'Ley de Amparo',
        'url': 'https://iajuriss.com/docs/leyes/ley-organica-de-amparo-sobre-derechos-y-garantias-constitucionales.pdf'
    },
    
    # PENALES ESPECIALES (6)
    {
        'codigo': 'LOSDMVLV',
        'nombre': 'Ley sobre el Derecho de las Mujeres a una Vida Libre de Violencia',
        'url': 'https://iajuriss.com/docs/leyes/mujeres_2021.pdf'
    },
    {
        'codigo': 'LOD',
        'nombre': 'Ley Orgánica de Drogas',
        'url': 'https://iajuriss.com/docs/leyes/drogas_2010.pdf'
    },
    {
        'codigo': 'LCDOFT',
        'nombre': 'Ley contra la Delincuencia Organizada',
        'url': 'https://sovedagro.com/wp-content/uploads/2025/06/Ley-Organica-Contra-la-Delincuencia-Organizada-y-Financiamiento-al-Terrorismo.pdf'
    },
    {
        'codigo': 'LCSE',
        'nombre': 'Ley Contra el Secuestro y la Extorsión',
        'url': 'https://iajuriss.com/docs/leyes/secuestro_extorsion_2009.pdf'
    },
    {
        'codigo': 'LHRVA',
        'nombre': 'Ley sobre Hurto y Robo de Vehículos',
        'url': 'https://iajuriss.com/docs/leyes/ley-sobre-el-hurto-y-robo-de-vehiculos-automotores.pdf'
    },
    {
        'codigo': 'LDCAM',
        'nombre': 'Ley de Armas y Explosivos',
        'url': 'https://iajuriss.com/docs/leyes/ley-de-armas-y-explosivos.pdf'
    },
    
    # COMPLEMENTARIAS (6)
    {
        'codigo': 'LPVT',
        'nombre': 'Ley de Protección de Víctimas y Testigos',
        'url': 'https://iajuriss.com/docs/leyes/g6645.pdf'
    },
    {
        'codigo': 'LECDI',
        'nombre': 'Ley contra Delitos Informáticos',
        'url': 'https://iajuriss.com/docs/leyes/ley-especial-contra-los-delitos-informaticos.pdf'
    },
    {
        'codigo': 'LOPNNA',
        'nombre': 'Ley de Protección de Niños, Niñas y Adolescentes',
        'url': 'https://iajuriss.com/docs/leyes/lopnna_2015.pdf'
    },
    {
        'codigo': 'LOCC',
        'nombre': 'Ley Contra la Corrupción',
        'url': 'https://iajuriss.com/docs/leyes/corrupcion_2022.pdf'
    },
    {
        'codigo': 'CEA',
        'nombre': 'Código de Ética Profesional del Abogado',
        'url': 'https://iajuriss.com/docs/leyes/codigo-de-etica-profesional-del-abogado-venezolano.pdf'
    },
    {
        'codigo': 'COP',
        'nombre': 'Código Orgánico Penitenciario',
        'url': 'https://iajuriss.com/docs/leyes/g6647.pdf'
    }
]

def descargar_pdf(url, destino):
    """Descarga un PDF"""
    try:
        print(f"   📥 Descargando...")
        headers = {'User-Agent': 'Mozilla/5.0'}
        response = requests.get(url, timeout=60, stream=True, headers=headers)
        response.raise_for_status()
        
        with open(destino, 'wb') as f:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)
        
        tamaño_kb = destino.stat().st_size // 1024
        print(f"   ✅ Descargado: {tamaño_kb:,} KB")
        return True
        
    except Exception as e:
        print(f"   ❌ Error: {str(e)[:60]}")
        return False

def extraer_texto_pdf(pdf_path):
    """Extrae texto de PDF"""
    try:
        print(f"   📄 Extrayendo texto...")
        texto_completo = []
        
        with open(pdf_path, 'rb') as f:
            pdf_reader = PyPDF2.PdfReader(f)
            num_paginas = len(pdf_reader.pages)
            
            for i in range(num_paginas):
                try:
                    texto = pdf_reader.pages[i].extract_text()
                    if texto:
                        texto_completo.append(texto)
                except:
                    continue
        
        resultado = '\n\n'.join(texto_completo)
        print(f"   ✅ Extraído: {len(resultado):,} caracteres")
        return resultado
        
    except Exception as e:
        print(f"   ⚠️  Error: {str(e)[:60]}")
        return None

def procesar_ley(ley, num, total):
    """Procesa una ley"""
    print(f"\n{'='*80}")
    print(f"[{num}/{total}] 📚 {ley['nombre']}")
    print(f"       {ley['codigo']}")
    print(f"{'='*80}")
    
    pdf_path = PDF_DIR / f"{ley['codigo']}.pdf"
    txt_path = TXT_DIR / f"{ley['codigo']}.txt"
    json_path = TXT_DIR / f"{ley['codigo']}.json"
    
    # Verificar si ya existe
    if pdf_path.exists() and txt_path.exists():
        print(f"   ⏭️  Ya procesada")
        return True
    
    # Descargar PDF
    if not pdf_path.exists():
        if not descargar_pdf(ley['url'], pdf_path):
            return False
    else:
        print(f"   ⏭️  PDF ya existe")
    
    # Extraer texto
    texto = None
    if not txt_path.exists():
        texto = extraer_texto_pdf(pdf_path)
        if texto and len(texto) > 100:
            with open(txt_path, 'w', encoding='utf-8') as f:
                f.write(texto)
            print(f"   💾 Guardado: {txt_path.name}")
    else:
        print(f"   ⏭️  Texto ya existe")
        with open(txt_path, 'r', encoding='utf-8') as f:
            texto = f.read()
    
    # Metadata
    metadata = {
        'codigo': ley['codigo'],
        'nombre': ley['nombre'],
        'url': ley['url'],
        'pdf_path': str(pdf_path),
        'txt_path': str(txt_path),
        'tamaño_bytes': pdf_path.stat().st_size if pdf_path.exists() else 0,
        'caracteres': len(texto) if texto else 0,
        'procesado': True
    }
    
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(metadata, f, ensure_ascii=False, indent=2)
    
    print(f"   ✅ Completado")
    time.sleep(1)
    return True

# ============================================================================
# EJECUCIÓN
# ============================================================================

if __name__ == "__main__":
    
    print(f"\n📋 16 leyes a descargar:")
    print(f"   Core: 4")
    print(f"   Penales Especiales: 6")
    print(f"   Complementarias: 6\n")
    
    for i, ley in enumerate(LEYES_CONFIRMADAS, 1):
        print(f"   {i:2}. {ley['codigo']:<12} {ley['nombre'][:55]}")
    
    print(f"\n📁 Destino: {PDF_DIR}\n")
    
    exitosos = 0
    fallidos = 0
    
    for i, ley in enumerate(LEYES_CONFIRMADAS, 1):
        if procesar_ley(ley, i, len(LEYES_CONFIRMADAS)):
            exitosos += 1
        else:
            fallidos += 1
    
    # RESUMEN
    print("\n" + "=" * 80)
    print("🎉 DESCARGA COMPLETADA")
    print("=" * 80)
    print(f"\n📊 Resumen:")
    print(f"   Exitosas: {exitosos}/{len(LEYES_CONFIRMADAS)}")
    print(f"   Fallidas: {fallidos}")
    
    pdfs = sorted(PDF_DIR.glob("*.pdf"))
    total_mb = sum(p.stat().st_size for p in pdfs) / (1024*1024)
    
    print(f"\n📚 Leyes descargadas ({len(pdfs)}):\n")
    for pdf in pdfs:
        tamaño_kb = pdf.stat().st_size // 1024
        txt = TXT_DIR / f"{pdf.stem}.txt"
        estado = "✅" if txt.exists() else "⚠️ "
        print(f"   {pdf.stem:<12} {tamaño_kb:>6} KB  {estado}")
    
    print(f"\n   Total: {total_mb:.1f} MB")
    
    print("\n" + "=" * 80)
    print("⚠️  NOTA: Faltan 2 leyes (no encontradas en IAJuriss):")
    print("   - Ley Trata de Personas (buscar fuente alternativa)")
    print("   - Manual Cadena de Custodia (documento del Ministerio Público)")
    print("=" * 80 + "\n")
