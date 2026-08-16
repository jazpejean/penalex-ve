#!/usr/bin/env python3
"""
Script para agregar Preámbulo, Disposiciones Transitorias y Disposición Final a la CRBV
Autor: PENALEX VE
Fecha: 2026-08-13
"""

import requests
from bs4 import BeautifulSoup
import json
import time
import re
from pathlib import Path

BASE_URL = "https://www.ley.com.ve"
HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
}

def limpiar_texto(texto):
    """Limpia texto de concordancias y basura"""
    patrones = [
        r'Concordancia\s+adicional\s*[A-Z]{2,6}\s+artículo\s+\d+[\w\s]*',
        r'Concordancia\s+adicional[^.]*',
        r'Ver\s+también:?[^.]*',
        r'Gaceta\s+Oficial\s+N[oº°]?\s*\d+[^.]*',
    ]
    for patron in patrones:
        texto = re.sub(patron, '', texto, flags=re.IGNORECASE)
    texto = re.sub(r'\s+', ' ', texto).strip()
    return texto

def extraer_contenido(url):
    """Extrae contenido de una URL"""
    try:
        response = requests.get(url, headers=HEADERS, timeout=30)
        response.raise_for_status()
        response.encoding = 'utf-8'
        
        soup = BeautifulSoup(response.text, 'html.parser')
        contenido = soup.find('div', class_='com-content-article__body')
        
        if not contenido:
            return None
        
        parrafos = []
        for p in contenido.find_all('p'):
            texto = p.get_text().strip()
            if texto and len(texto) > 10:
                texto = limpiar_texto(texto)
                if texto:
                    parrafos.append(texto)
        
        return '\n\n'.join(parrafos)
    
    except Exception as e:
        print(f"❌ Error en {url}: {e}")
        return None

def main():
    print("\n" + "="*70)
    print("🔧 COMPLETANDO CRBV CON SECCIONES FALTANTES")
    print("="*70 + "\n")
    
    # Cargar JSON actual
    json_path = Path('../leyes_json/crbv_scraped.json')
    with open(json_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    secciones_nuevas = []
    
    # 1. PREÁMBULO
    print("📥 Extrayendo Preámbulo...")
    url_preambulo = f"{BASE_URL}/constitucion/preambulo"
    texto_preambulo = extraer_contenido(url_preambulo)
    
    if texto_preambulo:
        # Limpiar el prefijo "Preámbulo."
        texto_preambulo = re.sub(r'^Preámbulo\.?\s*', '', texto_preambulo, flags=re.IGNORECASE).strip()
        
        secciones_nuevas.append({
            'numero': 'preambulo',
            'titulo': 'Preámbulo',
            'texto': texto_preambulo
        })
        print(f"   ✅ Preámbulo ({len(texto_preambulo)} chars)")
    else:
        print("   ⚠️ No se pudo extraer el Preámbulo")
    
    time.sleep(1)
    
    # 2. DISPOSICIONES TRANSITORIAS (1-18)
    print("\n📥 Extrayendo Disposiciones Transitorias...")
    
    nombres_ordinales = [
        'primera', 'segunda', 'tercera', 'cuarta', 'quinta', 'sexta',
        'septima', 'octava', 'novena', 'decima', 'decimoprimera',
        'decimosegunda', 'decimotercera', 'decimocuarta', 'decimoquinta',
        'decimosexta', 'decimoseptima', 'decimoctava'
    ]
    
    disposiciones = []
    
    for i, ordinal in enumerate(nombres_ordinales, 1):
        url_disp = f"{BASE_URL}/constitucion/crbv-disposicion-transitoria-{ordinal}"
        texto_disp = extraer_contenido(url_disp)
        
        if texto_disp:
            # Limpiar prefijo "Disposición Transitoria Primera."
            texto_disp = re.sub(r'^Disposición\s+Transitoria\s+\w+\.?\s*', '', texto_disp, flags=re.IGNORECASE).strip()
            
            disposiciones.append({
                'numero': ordinal,
                'titulo': f'Disposición Transitoria {ordinal.capitalize()}',
                'texto': texto_disp
            })
            print(f"   ✅ Disposición {ordinal.capitalize()} ({len(texto_disp)} chars)")
        else:
            print(f"   ⚠️ No se pudo extraer Disposición {ordinal.capitalize()}")
        
        time.sleep(0.8)
    
    # 3. DISPOSICIÓN FINAL
    print("\n📥 Extrayendo Disposición Final...")
    url_final = f"{BASE_URL}/constitucion/crbv-disposicion-final"
    texto_final = extraer_contenido(url_final)
    
    if texto_final:
        texto_final = re.sub(r'^Disposición\s+Final\.?\s*', '', texto_final, flags=re.IGNORECASE).strip()
        
        disposiciones.append({
            'numero': 'final',
            'titulo': 'Disposición Final',
            'texto': texto_final
        })
        print(f"   ✅ Disposición Final ({len(texto_final)} chars)")
    else:
        print("   ⚠️ No se pudo extraer Disposición Final")
    
    # Reorganizar estructura: Preámbulo + Artículos + Disposiciones
    estructura_completa = []
    
    # Agregar preámbulo al inicio
    if secciones_nuevas:
        estructura_completa.append(secciones_nuevas[0])
    
    # Agregar artículos existentes
    estructura_completa.extend(data['estructura'])
    
    # Agregar disposiciones al final
    estructura_completa.extend(disposiciones)
    
    # Actualizar metadata
    data['estructura'] = estructura_completa
    data['metadata']['total_articulos'] = len(estructura_completa)
    data['metadata']['incluye'] = 'Preámbulo, Artículos 1-350, Disposiciones Transitorias (1-18), Disposición Final'
    
    # Guardar
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print("\n" + "="*70)
    print("📊 RESUMEN:")
    print(f"   Preámbulo: {'✅' if secciones_nuevas else '❌'}")
    print(f"   Artículos: {len([x for x in data['estructura'] if isinstance(x.get('numero'), int)])}")
    print(f"   Disposiciones Transitorias: {len([x for x in disposiciones if x['numero'] != 'final'])}")
    print(f"   Disposición Final: {'✅' if any(x['numero'] == 'final' for x in disposiciones) else '❌'}")
    print(f"   Total elementos: {len(estructura_completa)}")
    print(f"\n💾 Guardado en: {json_path}")
    print("="*70 + "\n")

if __name__ == '__main__':
    main()
