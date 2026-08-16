#!/usr/bin/env python3
"""
Descarga las 17 LEYES SELECCIONADAS para PENALEX
Basado en selección del usuario (especialización en derecho penal)
"""
import os
import re
import json
import time
import requests
from pathlib import Path
import PyPDF2

# Configuración
OUTPUT_DIR = Path("tools/data/leyes")
PDF_DIR = OUTPUT_DIR / "pdfs"
TXT_DIR = OUTPUT_DIR / "textos"

# Crear directorios
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
PDF_DIR.mkdir(exist_ok=True)
TXT_DIR.mkdir(exist_ok=True)

print("=" * 80)
print("⚖️  DESCARGAR LEYES SELECCIONADAS PARA PENALEX")
print("=" * 80)

# ============================================================================
# LEYES SELECCIONADAS (17 total)
# ============================================================================

LEYES_SELECCIONADAS = [
    # PRIORIDAD 1: CORE (4 leyes)
    {
        'nombre': 'Constitución de la República Bolivariana de Venezuela',
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
        'nombre': 'Ley Orgánica de Amparo sobre Derechos y Garantías Constitucionales',
        'codigo': 'LOA',
        'url': 'https://iajuriss.com/docs/leyes/ley-organica-de-amparo-sobre-derechos-y-garantias-constitucionales.pdf',
        'prioridad': 1
    },
    
    # PRIORIDAD 2: LEYES PENALES ESPECIALES (6 leyes)
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
    
    # PRIORIDAD 3: COMPLEMENTARIAS (7 leyes)
    {
        'nombre': 'Ley de Protección de Víctimas, Testigos y demás Sujetos Procesales',
        'codigo': 'LPVT',
        'url': 'https://iajuriss.com/docs/leyes/ley-proteccion-victimas.pdf',
        'prioridad': 3
    },
    {
        'nombre': 'Ley Especial contra los Delitos Informáticos',
        'codigo': 'LECDI',
        'url': 'https://iajuriss.com/docs/leyes/ley-delitos-informaticos.pdf',
        'prioridad': 3
    },
    {
        'nombre': 'Ley contra la Trata de Personas y Tráfico Ilícito de Migrantes',
        'codigo': 'LCTPTIM',
        'url': 'https://iajuriss.com/docs/leyes/ley-trata-personas.pdf',
        'prioridad': 3
    },
    {
        'nombre': 'Ley de Responsabilidad Penal del Adolescente',
        'codigo': 'LORPA',
        'url': 'https://iajuriss.com/docs/leyes/ley-responsabilidad-penal-adolescente.pdf',
        'prioridad': 3
    },
    {
        'nombre': 'Ley Orgánica para la Protección de Niños, Niñas y Adolescentes',
        'codigo': 'LOPNNA',
        'url': 'https://iajuriss.com/docs/leyes/lopnna.pdf',
        'prioridad': 3
    },
    {
        'nombre': 'Ley Orgánica contra la Corrupción',
        'codigo': 'LOCC',
        'url': 'https://iajuriss.com/docs/leyes/ley-contra-corrupcion.pdf',
        'prioridad': 3
    },
    {
        'nombre': 'Manual Único de Cadena de Custodia de Evidencias Físicas',
        'codigo': 'MUCC',
        'url': 'https://iajuriss.com/docs/leyes/manual-cadena-custodia.pdf',
        'prioridad': 3
    }
]

def descargar_pdf(url, destino):
    """Descarga un PDF desde URL"""
    try:
        print(f"   📥 Descargando...")
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        }
        response = requests.get(url, timeout=60, stream=True, headers=headers)
        response.raise_for_status()
        
        with open(destino, 'wb') as f:
            total = 0
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)
                total += len(chunk)
                if total > 1024*1024:  # Cada MB
                    print(f"      {total // (1024*1024)} MB...", end='\r')
        
        tamaño_kb = destino.stat().st_size // 1024
        print(f"   ✅ Descargado: {tamaño_kb:,} KB")
        return True
        
    except requests.exceptions.HTTPError as e:
        if e.response.status_code == 404:
            print(f"   ⚠️  URL no encontrada (404)")
            print(f"      Posible nombre alternativo en IAJuriss")
        else:
            print(f"   ❌ Error HTTP {e.response.status_code}")
        return False
    except Exception as e:
        print(f"   ❌ Error: {str(e)[:80]}")
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
                        print(f"      {i+1}/{num_paginas}...", end='\r')
                except:
                    continue
        
        resultado = '\n\n'.join(texto_completo)
        print(f"   ✅ Extraído: {len(resultado):,} caracteres")
        return resultado
        
    except Exception as e:
        print(f"   ⚠️  Error extrayendo: {str(e)[:60]}")
        print(f"      (Puede ser imagen escaneada)")
        return None

def procesar_ley(ley, num, total):
    """Descarga y procesa una ley"""
    print(f"\n{'='*80}")
    print(f"[{num}/{total}] 📚 {ley['nombre']}")
    print(f"       Código: {ley['codigo']}")
    print(f"{'='*80}")
    
    # Nombres de archivos
    pdf_path = PDF_DIR / f"{ley['codigo']}.pdf"
    txt_path = TXT_DIR / f"{ley['codigo']}.txt"
    json_path = TXT_DIR / f"{ley['codigo']}.json"
    
    # Verificar si ya existe
    if pdf_path.exists() and txt_path.exists():
        print(f"   ⏭️  Ya procesada")
        tamaño = pdf_path.stat().st_size // 1024
        with open(txt_path, 'r', encoding='utf-8') as f:
            texto = f.read()
        print(f"   ℹ️  PDF: {tamaño:,} KB | Texto: {len(texto):,} caracteres")
        return True
    
    # Descargar PDF
    if not pdf_path.exists():
        if not descargar_pdf(ley['url'], pdf_path):
            print(f"   ⚠️  Marcada para revisión manual")
            # Guardar metadata con error
            metadata = {
                'nombre': ley['nombre'],
                'codigo': ley['codigo'],
                'url': ley['url'],
                'prioridad': ley['prioridad'],
                'error': 'descarga_fallida',
                'procesado': False
            }
            with open(json_path, 'w', encoding='utf-8') as f:
                json.dump(metadata, f, ensure_ascii=False, indent=2)
            return False
    else:
        print(f"   ⏭️  PDF ya existe")
    
    # Extraer texto
    texto = None
    if not txt_path.exists():
        texto = extraer_texto_pdf(pdf_path)
        if texto and len(texto) > 100:  # Mínimo razonable
            with open(txt_path, 'w', encoding='utf-8') as f:
                f.write(texto)
            print(f"   💾 Guardado: {txt_path.name}")
        else:
            print(f"   ⚠️  Sin texto extraíble (posible imagen)")
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
        'tamaño_pdf_bytes': pdf_path.stat().st_size if pdf_path.exists() else 0,
        'caracteres_texto': len(texto) if texto else 0,
        'tiene_texto': bool(texto and len(texto) > 100),
        'procesado': True
    }
    
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(metadata, f, ensure_ascii=False, indent=2)
    
    print(f"   ✅ Completado")
    time.sleep(1.5)  # Rate limiting cortés
    return True

# ============================================================================
# EJECUCIÓN PRINCIPAL
# ============================================================================

if __name__ == "__main__":
    
    print(f"\n📋 Leyes seleccionadas:")
    print(f"   Prioridad 1 (Core): 4 leyes")
    print(f"   Prioridad 2 (Penales Especiales): 6 leyes")
    print(f"   Prioridad 3 (Complementarias): 7 leyes")
    print(f"   TOTAL: {len(LEYES_SELECCIONADAS)} leyes\n")
    
    for i, ley in enumerate(LEYES_SELECCIONADAS, 1):
        print(f"   {i:2}. {ley['codigo']:<12} - {ley['nombre'][:60]}")
    
    print(f"\n📁 Destino:")
    print(f"   PDFs:   {PDF_DIR}")
    print(f"   Textos: {TXT_DIR}")
    
    print("\n▶️  Iniciando descarga automática...\n")
    
    exitosos = 0
    fallidos = 0
    
    # Procesar en orden de prioridad
    for prioridad in [1, 2, 3]:
        leyes_prioridad = [l for l in LEYES_SELECCIONADAS if l['prioridad'] == prioridad]
        
        if leyes_prioridad:
            print(f"\n{'#'*80}")
            print(f"  PRIORIDAD {prioridad} - {len(leyes_prioridad)} leyes")
            print(f"{'#'*80}")
            
            for ley in leyes_prioridad:
                num = LEYES_SELECCIONADAS.index(ley) + 1
                if procesar_ley(ley, num, len(LEYES_SELECCIONADAS)):
                    exitosos += 1
                else:
                    fallidos += 1
    
    # RESUMEN FINAL
    print("\n" + "=" * 80)
    print("🎉 DESCARGA COMPLETADA")
    print("=" * 80)
    print(f"\n📊 Resumen:")
    print(f"   Exitosas: {exitosos}/{len(LEYES_SELECCIONADAS)}")
    print(f"   Fallidas: {fallidos}")
    
    # Listar archivos descargados
    pdfs = sorted(PDF_DIR.glob("*.pdf"))
    
    print(f"\n📚 Leyes descargadas ({len(pdfs)}):\n")
    
    total_mb = 0
    for pdf in pdfs:
        txt = TXT_DIR / f"{pdf.stem}.txt"
        json_file = TXT_DIR / f"{pdf.stem}.json"
        
        tamaño_kb = pdf.stat().st_size // 1024
        total_mb += pdf.stat().st_size / (1024*1024)
        
        # Leer metadata
        if json_file.exists():
            with open(json_file, 'r', encoding='utf-8') as f:
                meta = json.load(f)
                chars = meta.get('caracteres_texto', 0)
                tiene_texto = "✅" if meta.get('tiene_texto') else "⚠️ "
        else:
            chars = 0
            tiene_texto = "❓"
        
        print(f"   {pdf.stem:<12} {tamaño_kb:>6} KB  {tiene_texto}  {chars:>8,} chars")
    
    print(f"\n   Total: {total_mb:.1f} MB")
    
    # Identificar problemas
    fallidas_json = list(TXT_DIR.glob("*.json"))
    problemas = []
    for json_file in fallidas_json:
        with open(json_file, 'r', encoding='utf-8') as f:
            meta = json.load(f)
            if not meta.get('procesado') or not meta.get('tiene_texto'):
                problemas.append(meta['codigo'])
    
    if problemas:
        print(f"\n⚠️  Requieren revisión manual ({len(problemas)}):")
        for codigo in problemas:
            print(f"   - {codigo}")
        print(f"\n   Revisar URLs en IAJuriss.com o buscar nombres alternativos")
    
    print("\n" + "=" * 80)
    print("🎯 PRÓXIMOS PASOS:")
    print("=" * 80)
    print("   1. ✅ Revisar leyes descargadas")
    print("   2. 📝 Estructurar artículos (parser)")
    print("   3. 🗄️  Crear schema en Supabase")
    print("   4. ⬆️  Cargar a base de datos")
    print("   5. 🔄 Migrar leyes_service.dart a Supabase")
    print("=" * 80 + "\n")
