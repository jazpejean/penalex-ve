#!/usr/bin/env python3
"""
Script para scrapear leyes de ley.com.ve donde cada artículo tiene su propia URL
Autor: PENALEX VE
Fecha: 2026-08-13
"""

import requests
from bs4 import BeautifulSoup
import json
import time
import re
from pathlib import Path
from typing import Dict, List, Optional
import argparse
from urllib.parse import urljoin

class LeyArticulosScraper:
    """Scraper para leyes con artículos en URLs separadas"""
    
    BASE_URL = "https://www.ley.com.ve"
    HEADERS = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'es-ES,es;q=0.9,en;q=0.8',
    }
    
    def __init__(self, output_dir: str = '../leyes_json'):
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(exist_ok=True)
        self.session = requests.Session()
        self.session.headers.update(self.HEADERS)
    
    def fetch_page(self, url: str) -> Optional[BeautifulSoup]:
        """Descarga y parsea una página HTML"""
        try:
            print(f"📥 {url}")
            response = self.session.get(url, timeout=30)
            response.raise_for_status()
            response.encoding = 'utf-8'
            time.sleep(1)  # Pausa para no saturar
            return BeautifulSoup(response.text, 'html.parser')
        except Exception as e:
            print(f"❌ Error: {e}")
            return None
    
    def buscar_indice_ley(self, nombre_ley: str) -> Optional[str]:
        """Busca la URL del índice de una ley en el buscador"""
        try:
            # Buscar en el sitio
            search_url = f"{self.BASE_URL}/?s={nombre_ley.replace(' ', '+')}"
            soup = self.fetch_page(search_url)
            
            if not soup:
                return None
            
            # Buscar el primer resultado relevante
            enlaces = soup.find_all('a', href=True)
            for enlace in enlaces:
                href = enlace['href']
                texto = enlace.get_text().lower()
                
                if nombre_ley.lower() in texto and 'articulo' not in href:
                    return href
            
            return None
        except Exception as e:
            print(f"❌ Error buscando índice: {e}")
            return None
    
    def extraer_enlaces_articulos(self, url_indice: str) -> List[Dict]:
        """Extrae todos los enlaces a artículos desde la página índice"""
        soup = self.fetch_page(url_indice)
        if not soup:
            return []
        
        articulos = []
        
        # Buscar todos los enlaces que contengan "articulo"
        enlaces = soup.find_all('a', href=True)
        
        for enlace in enlaces:
            href = enlace['href']
            texto = enlace.get_text().strip()
            
            # Filtrar enlaces de artículos
            if 'articulo' in href.lower() or 'art' in texto.lower()[:10]:
                # Intentar extraer número de artículo
                numero_match = re.search(r'(\d+)', texto)
                numero = int(numero_match.group(1)) if numero_match else None
                
                # Construir URL completa
                url_completa = urljoin(self.BASE_URL, href)
                
                articulos.append({
                    'numero': numero,
                    'url': url_completa,
                    'titulo': texto
                })
        
        # Ordenar por número de artículo
        articulos.sort(key=lambda x: x['numero'] if x['numero'] else 999999)
        
        return articulos
    
    def scrappear_articulo(self, url: str) -> Optional[Dict]:
        """Scrappea el contenido de un artículo individual"""
        soup = self.fetch_page(url)
        if not soup:
            return None
        
        # Buscar el contenido principal del artículo
        contenido = soup.find('div', class_='entry-content') or soup.find('article')
        
        if not contenido:
            return None
        
        # Extraer número del artículo
        titulo = soup.find('h1') or soup.find('h2')
        titulo_texto = titulo.get_text() if titulo else ""
        
        numero_match = re.search(r'Art[íi]culo\s+(\d+)', titulo_texto, re.IGNORECASE)
        numero = int(numero_match.group(1)) if numero_match else None
        
        # Extraer texto completo
        texto_completo = contenido.get_text().strip()
        
        # Limpiar texto
        texto_completo = re.sub(r'\s+', ' ', texto_completo)
        texto_completo = re.sub(r'\n+', '\n', texto_completo)
        
        return {
            'numero': numero,
            'texto': texto_completo,
            'url': url
        }
    
    def scrappear_ley_completa(self, nombre_ley: str, sigla: str, url_indice: Optional[str] = None) -> Dict:
        """Scrappea una ley completa artículo por artículo"""
        print(f"\n{'='*70}")
        print(f"🔍 Scrappeando: {nombre_ley} ({sigla})")
        print(f"{'='*70}\n")
        
        # Buscar índice si no se proporciona
        if not url_indice:
            print("🔎 Buscando índice de la ley...")
            url_indice = self.buscar_indice_ley(nombre_ley)
            if not url_indice:
                print("❌ No se encontró el índice de la ley")
                return None
        
        print(f"📑 Índice encontrado: {url_indice}\n")
        
        # Extraer enlaces de artículos
        print("📋 Extrayendo lista de artículos...")
        enlaces_articulos = self.extraer_enlaces_articulos(url_indice)
        
        if not enlaces_articulos:
            print("❌ No se encontraron artículos")
            return None
        
        print(f"✅ Encontrados {len(enlaces_articulos)} artículos\n")
        
        # Scrappear cada artículo
        print("📥 Descargando artículos...")
        articulos = []
        
        for i, info_articulo in enumerate(enlaces_articulos, 1):
            print(f"  [{i}/{len(enlaces_articulos)}] Artículo {info_articulo['numero']}...", end=" ")
            
            articulo = self.scrappear_articulo(info_articulo['url'])
            
            if articulo:
                articulos.append(articulo)
                print("✓")
            else:
                print("✗")
            
            # Pausa para no saturar el servidor
            if i % 10 == 0:
                time.sleep(2)
        
        # Estructurar en JSON
        ley_json = {
            'codigo': sigla,
            'nombre': nombre_ley,
            'fuente': 'ley.com.ve',
            'fecha_extraccion': time.strftime('%Y-%m-%d'),
            'url_indice': url_indice,
            'total_articulos': len(articulos),
            'articulos': articulos
        }
        
        print(f"\n✅ Extraídos {len(articulos)} artículos")
        
        # Guardar JSON
        output_file = self.output_dir / f"{sigla.lower()}_scraped.json"
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(ley_json, f, ensure_ascii=False, indent=2)
        
        print(f"💾 Guardado en: {output_file}")
        
        return ley_json
    
    def scrappear_con_url_directa(self, sigla: str, nombre: str, url: str) -> bool:
        """Scrappea una ley proporcionando la URL directamente"""
        try:
            resultado = self.scrappear_ley_completa(nombre, sigla, url)
            return resultado is not None
        except Exception as e:
            print(f"❌ Error: {e}")
            return False


def main():
    parser = argparse.ArgumentParser(
        description='Scraper de leyes venezolanas (artículos individuales)'
    )
    parser.add_argument(
        '--url',
        type=str,
        required=True,
        help='URL del índice de la ley'
    )
    parser.add_argument(
        '--sigla',
        type=str,
        required=True,
        help='Sigla de la ley (ej: LCDOFT, LCSE)'
    )
    parser.add_argument(
        '--nombre',
        type=str,
        required=True,
        help='Nombre completo de la ley'
    )
    parser.add_argument(
        '--output',
        type=str,
        default='../leyes_json',
        help='Directorio de salida'
    )
    
    args = parser.parse_args()
    
    scraper = LeyArticulosScraper(output_dir=args.output)
    scraper.scrappear_con_url_directa(args.sigla, args.nombre, args.url)


if __name__ == '__main__':
    # Ejemplo de uso interactivo
    print("\n🕷️ Scraper de Leyes Venezolanas (Artículos Individuales)")
    print("="*70)
    
    # Ejemplos de uso
    print("\nEjemplos de uso:")
    print("python scraper_leyes_articulos.py \\")
    print("  --url 'https://www.ley.com.ve/codigo-penal' \\")
    print("  --sigla 'CP' \\")
    print("  --nombre 'Código Penal'")
    print()
    
    import sys
    if len(sys.argv) == 1:
        print("❌ Debes proporcionar los parámetros --url, --sigla y --nombre")
        print("\nEjecuta con --help para ver opciones")
        sys.exit(1)
    
    main()
