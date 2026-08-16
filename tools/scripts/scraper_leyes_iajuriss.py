#!/usr/bin/env python3
"""
Scraper de leyes desde IAJuriss.com
Descarga y estructura 643 leyes venezolanas para PENALEX
"""
import os
import re
import json
import time
import requests
from bs4 import BeautifulSoup
from urllib.parse import urljoin
from pathlib import Path
import PyPDF2
from dotenv import load_dotenv

load_dotenv()

# Configuración
BASE_URL = "https://iajuriss.com"
LEYES_URL = f"{BASE_URL}/leyes"
OUTPUT_DIR = Path("../data/leyes")
PDF_DIR = OUTPUT_DIR / "pdfs"
JSON_DIR = OUTPUT_DIR / "json"

# Crear directorios
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
PDF_DIR.mkdir(exist_ok=True)
JSON_DIR.mkdir(exist_ok=True)

print("=" * 80)
print("📚 SCRAPER DE LEYES VENEZOLANAS - IAJuriss.com")
print("=" * 80)

def limpiar_texto(texto):
    """Limpia texto de espacios y caracteres especiales"""
    return ' '.join(texto.split()).strip()

def extraer_metadata_de_descripcion(descripcion):
    """
    Extrae metadata de la descripción
    Formato: "Tipo · G.O. XXXXX · Año · Área · XXX arts."
    """
    partes = [p.strip() for p in descripcion.split('·')]
    
    metadata = {
        'tipo': partes[0] if len(partes) > 0 else None,
        'gaceta_oficial': None,
        'año': None,
        'area_derecho': None,
        'num_articulos': None
    }
    
    for parte in partes:
        if 'G.O.' in parte:
            metadata['gaceta_oficial'] = parte.replace('G.O.', '').strip()
        elif parte.isdigit() and len(parte) == 4:
            metadata['año'] = int(parte)
        elif 'arts.' in parte or 'art.' in parte:
            num = re.search(r'(\d+)', parte)
            if num:
                metadata['num_articulos'] = int(num.group(1))
        elif parte not in ['Leyes Orgánicas', 'Constitución', 'Leyes Especiales']:
            metadata['area_derecho'] = parte
    
    return metadata

def scrape_lista_leyes():
    """
    Scrape la página principal de leyes
    """
    print(f"\n📥 Obteniendo lista de leyes desde {LEYES_URL}...")
    
    leyes = []
    
    try:
        response = requests.get(LEYES_URL, timeout=30)
        response.raise_for_status()
        
        soup = BeautifulSoup(response.content, 'html.parser')
        
        # Buscar todos los cards de leyes
        ley_cards = soup.find_all('div', class_='cursor-pointer')
        
        print(f"✅ Encontrados {len(ley_cards)} documentos")
        
        for idx, card in enumerate(ley_cards, 1):
            try:
                # Título
                titulo_elem = card.find('span', class_='text-[14px]')
                titulo = limpiar_texto(titulo_elem.text) if titulo_elem else None
                
                # Código (si existe)
                codigo_elem = card.find('span', class_='rounded border px-1.5')
                codigo = limpiar_texto(codigo_elem.text) if codigo_elem else None
                
                # Estado (VIGENTE)
                estado_elem = card.find('span', string=lambda t: 'VIGENTE' in str(t) if t else False)
                vigente = bool(estado_elem)
                
                # Descripción con metadata
                desc_elem = card.find('p', class_='mt-0.5')
                descripcion = limpiar_texto(desc_elem.text) if desc_elem else ""
                
                # PDF URL
                pdf_link = card.find('a', href=True)
                pdf_url = pdf_link['href'] if pdf_link else None
                
                # Extraer metadata de descripción
                metadata = extraer_metadata_de_descripcion(descripcion)
                
                ley = {
                    'id': f"ley_{idx:04d}",
                    'titulo': titulo,
                    'codigo': codigo,
                    'vigente': vigente,
                    'pdf_url': pdf_url,
                    'descripcion': descripcion,
                    **metadata
                }
                
                leyes.append(ley)
                
                if idx % 50 == 0:
                    print(f"   Procesados {idx} documentos...")
                    
            except Exception as e:
                print(f"   ⚠️  Error en documento {idx}: {str(e)[:60]}")
                continue
        
        print(f"\n✅ Total leyes extraídas: {len(leyes)}")
        
        # Guardar JSON con metadata
        json_path = JSON_DIR / "lista_leyes_iajuriss.json"
        with open(json_path, 'w', encoding='utf-8') as f:
            json.dump(leyes, f, ensure_ascii=False, indent=2)
        
        print(f"💾 Lista guardada en: {json_path}")
        
        return leyes
        
    except Exception as e:
        print(f"❌ Error al scrape: {str(e)}")
        return []

def descargar_pdf(url, destino):
    """Descarga un PDF desde URL"""
    try:
        response = requests.get(url, timeout=60, stream=True)
        response.raise_for_status()
        
        with open(destino, 'wb') as f:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)
        
        return True
    except Exception as e:
        print(f"   ❌ Error descargando: {str(e)[:60]}")
        return False

def extraer_texto_pdf(pdf_path):
    """Extrae texto de un PDF"""
    try:
        texto_completo = []
        
        with open(pdf_path, 'rb') as f:
            pdf_reader = PyPDF2.PdfReader(f)
            num_paginas = len(pdf_reader.pages)
            
            for i in range(num_paginas):
                try:
                    page = pdf_reader.pages[i]
                    texto = page.extract_text()
                    if texto:
                        texto_completo.append(texto)
                except:
                    continue
        
        return '\n'.join(texto_completo)
        
    except Exception as e:
        print(f"   ⚠️  Error extrayendo texto: {str(e)[:60]}")
        return None

def descargar_pdfs(leyes, limite=None):
    """
    Descarga los PDFs de las leyes
    limite: número máximo de PDFs a descargar (para testing)
    """
    print(f"\n📥 Descargando PDFs...")
    
    if limite:
        leyes = leyes[:limite]
        print(f"   Modo testing: solo {limite} leyes")
    
    exitosos = 0
    errores = 0
    
    for idx, ley in enumerate(leyes, 1):
        if not ley.get('pdf_url'):
            continue
        
        nombre_archivo = f"{ley['id']}_{ley.get('codigo', 'sin_codigo')}.pdf"
        nombre_archivo = re.sub(r'[<>:"/\\|?*]', '_', nombre_archivo)
        destino = PDF_DIR / nombre_archivo
        
        if destino.exists():
            print(f"   ⏭️  {idx}/{len(leyes)}: Ya existe - {ley['titulo'][:50]}")
            exitosos += 1
            continue
        
        print(f"   📥 {idx}/{len(leyes)}: {ley['titulo'][:50]}...")
        
        if descargar_pdf(ley['pdf_url'], destino):
            exitosos += 1
            
            # Extraer texto inmediatamente
            texto = extraer_texto_pdf(destino)
            if texto:
                ley['texto_extraido'] = True
                ley['texto_path'] = str(destino.with_suffix('.txt'))
                
                # Guardar texto
                with open(destino.with_suffix('.txt'), 'w', encoding='utf-8') as f:
                    f.write(texto)
            else:
                ley['texto_extraido'] = False
        else:
            errores += 1
        
        time.sleep(1)  # Rate limiting
    
    print(f"\n✅ Descarga completada:")
    print(f"   Exitosos: {exitosos}")
    print(f"   Errores: {errores}")
    
    return leyes

def filtrar_leyes_penales(leyes):
    """Filtra solo las leyes relacionadas con derecho penal"""
    palabras_clave = [
        'penal', 'código penal', 'copp', 'procesal penal',
        'drogas', 'delincuencia', 'secuestro', 'extorsión',
        'violencia', 'terrorismo', 'armas', 'penitenciario',
        'víctimas', 'justicia', 'ministerio público',
        'constitución'  # Fundamental para cualquier rama
    ]
    
    leyes_penales = []
    
    for ley in leyes:
        titulo_lower = ley.get('titulo', '').lower()
        desc_lower = ley.get('descripcion', '').lower()
        area = ley.get('area_derecho', '').lower() if ley.get('area_derecho') else ''
        
        texto_completo = f"{titulo_lower} {desc_lower} {area}".lower()
        
        if any(palabra in texto_completo for palabra in palabras_clave):
            leyes_penales.append(ley)
    
    return leyes_penales

# ============================================================================
# EJECUCIÓN PRINCIPAL
# ============================================================================

if __name__ == "__main__":
    
    # Paso 1: Scrape la lista
    leyes = scrape_lista_leyes()
    
    if not leyes:
        print("❌ No se pudieron obtener leyes")
        exit(1)
    
    # Paso 2: Filtrar solo penales
    print(f"\n🔍 Filtrando leyes penales...")
    leyes_penales = filtrar_leyes_penales(leyes)
    print(f"✅ {len(leyes_penales)} leyes relacionadas con derecho penal")
    
    # Guardar lista de penales
    json_path_penales = JSON_DIR / "leyes_penales.json"
    with open(json_path_penales, 'w', encoding='utf-8') as f:
        json.dump(leyes_penales, f, ensure_ascii=False, indent=2)
    
    # Paso 3: Descargar PDFs
    print(f"\n¿Descargar PDFs?")
    print(f"  1. Solo leyes penales ({len(leyes_penales)} leyes)")
    print(f"  2. Todas las leyes ({len(leyes)} leyes)")
    print(f"  3. Testing (solo 5 leyes)")
    print(f"  4. Omitir descarga")
    
    opcion = input("\nOpción (1-4): ").strip()
    
    if opcion == "1":
        leyes_penales = descargar_pdfs(leyes_penales)
        # Guardar actualizado
        with open(json_path_penales, 'w', encoding='utf-8') as f:
            json.dump(leyes_penales, f, ensure_ascii=False, indent=2)
    elif opcion == "2":
        leyes = descargar_pdfs(leyes)
        # Guardar actualizado
        with open(JSON_DIR / "lista_leyes_iajuriss.json", 'w', encoding='utf-8') as f:
            json.dump(leyes, f, ensure_ascii=False, indent=2)
    elif opcion == "3":
        test_leyes = descargar_pdfs(leyes_penales, limite=5)
    
    print("\n" + "=" * 80)
    print("✅ PROCESO COMPLETADO")
    print("=" * 80)
    print(f"\n📊 Resultados:")
    print(f"   Total leyes encontradas: {len(leyes)}")
    print(f"   Leyes penales: {len(leyes_penales)}")
    print(f"   Archivos en: {OUTPUT_DIR}")
    print("\n🎯 Próximo paso:")
    print("   Ejecutar script de carga a Supabase")
    print("=" * 80)
