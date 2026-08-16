#!/usr/bin/env python3
"""
Script para buscar las URLs reales de las leyes en ley.com.ve
"""

import requests
from bs4 import BeautifulSoup
import re

def buscar_leyes():
    """Busca las leyes disponibles en ley.com.ve"""
    
    print("🔍 Explorando ley.com.ve...")
    print("="*70)
    
    # URLs posibles para explorar
    urls_explorar = [
        "https://www.ley.com.ve",
        "https://www.ley.com.ve/leyes-penales",
        "https://www.ley.com.ve/sitemap",
    ]
    
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
    }
    
    leyes_encontradas = {}
    
    for url_base in urls_explorar:
        try:
            print(f"\n📥 Explorando: {url_base}")
            response = requests.get(url_base, headers=headers, timeout=15)
            response.raise_for_status()
            
            soup = BeautifulSoup(response.text, 'html.parser')
            
            # Buscar todos los enlaces
            enlaces = soup.find_all('a', href=True)
            
            for enlace in enlaces:
                href = enlace['href']
                texto = enlace.get_text().strip()
                
                # Filtrar enlaces que parecen ser leyes
                if any(palabra in texto.lower() for palabra in ['ley', 'código', 'codigo']):
                    # Normalizar URL
                    if href.startswith('/'):
                        url_completa = f"https://www.ley.com.ve{href}"
                    elif href.startswith('http'):
                        url_completa = href
                    else:
                        continue
                    
                    # Guardar
                    if 'ley.com.ve' in url_completa and url_completa not in leyes_encontradas.values():
                        leyes_encontradas[texto[:80]] = url_completa
            
            print(f"✅ Encontrados {len(leyes_encontradas)} enlaces")
            
        except Exception as e:
            print(f"⚠️ Error explorando {url_base}: {e}")
    
    # Mostrar resultados
    print("\n" + "="*70)
    print("📚 LEYES ENCONTRADAS:")
    print("="*70 + "\n")
    
    # Filtrar las más relevantes
    leyes_relevantes = {}
    keywords = [
        'delincuencia organizada',
        'secuestro',
        'drogas',
        'trata',
        'contrabando',
        'código penal',
        'procesal penal',
        'niños',
        'mujeres',
        'violencia',
        'informáticos',
        'lopnna',
        'copp'
    ]
    
    for texto, url in leyes_encontradas.items():
        if any(kw in texto.lower() for kw in keywords):
            leyes_relevantes[texto] = url
    
    for i, (texto, url) in enumerate(sorted(leyes_relevantes.items()), 1):
        print(f"{i:2}. {texto}")
        print(f"    URL: {url}\n")
    
    # Generar código Python actualizado
    print("\n" + "="*70)
    print("📝 ACTUALIZACIÓN PARA scraper_leyes_ve.py:")
    print("="*70 + "\n")
    
    print("LEYES_CRITICAS = {")
    for texto, url in sorted(leyes_relevantes.items()):
        # Extraer clave del URL
        clave = url.replace('https://www.ley.com.ve/', '').strip('/')
        sigla = ''.join([word[0].upper() for word in texto.split()[:3]])
        
        print(f"    '{clave}': {{")
        print(f"        'nombre': '{texto}',")
        print(f"        'sigla': '{sigla}',")
        print(f"        'url_suffix': '/{clave}'")
        print(f"    }},")
    print("}")

if __name__ == '__main__':
    buscar_leyes()
