#!/usr/bin/env python3
"""
Script para scrapear leyes de ley.com.ve y convertirlas a JSON
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

class LeyVenezolanaScraper:
    """Scraper para leyes venezolanas desde ley.com.ve"""
    
    BASE_URL = "https://www.ley.com.ve"
    HEADERS = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'es-ES,es;q=0.9,en;q=0.8',
    }
    
    # Leyes críticas para scrappear
    LEYES_CRITICAS = {
        'codigo-penal': {
            'nombre': 'Código Penal',
            'sigla': 'CP',
            'url_suffix': '/codigo-penal'
        },
        'copp': {
            'nombre': 'Código Orgánico Procesal Penal',
            'sigla': 'COPP',
            'url_suffix': '/codigo-organico-procesal-penal'
        },
        'lcdoft': {
            'nombre': 'Ley Contra la Delincuencia Organizada y Financiamiento al Terrorismo',
            'sigla': 'LCDOFT',
            'url_suffix': '/ley-organica-contra-la-delincuencia-organizada-y-financiamiento-al-terrorismo'
        },
        'lcse': {
            'nombre': 'Ley Contra el Secuestro y la Extorsión',
            'sigla': 'LCSE',
            'url_suffix': '/ley-contra-el-secuestro-y-la-extorsion'
        },
        'lod': {
            'nombre': 'Ley Orgánica de Drogas',
            'sigla': 'LOD',
            'url_suffix': '/ley-organica-de-drogas'
        },
        'loctp': {
            'nombre': 'Ley Orgánica Contra la Trata de Personas',
            'sigla': 'LOCTP',
            'url_suffix': '/ley-organica-contra-la-trata-de-personas-y-trafico-de-migrantes'
        },
        'lcc': {
            'nombre': 'Ley Contra el Contrabando',
            'sigla': 'LCC',
            'url_suffix': '/ley-organica-de-prevencion-investigacion-y-persecucion-del-delito-de-contrabando'
        },
        'lopnna': {
            'nombre': 'Ley Orgánica para la Protección de Niños, Niñas y Adolescentes',
            'sigla': 'LOPNNA',
            'url_suffix': '/ley-organica-para-la-proteccion-de-ninos-ninas-y-adolescentes'
        },
        'losdmvlv': {
            'nombre': 'Ley Orgánica sobre el Derecho de las Mujeres a una Vida Libre de Violencia',
            'sigla': 'LOSDMVLV',
            'url_suffix': '/ley-organica-sobre-el-derecho-de-las-mujeres-a-una-vida-libre-de-violencia'
        },
        'lecdi': {
            'nombre': 'Ley Especial Contra los Delitos Informáticos',
            'sigla': 'LECDI',
            'url_suffix': '/ley-especial-contra-los-delitos-informaticos'
        },
    }
    
    def __init__(self, output_dir: str = '../leyes_json'):
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(exist_ok=True)
        self.session = requests.Session()
        self.session.headers.update(self.HEADERS)
    
    def fetch_page(self, url: str) -> Optional[str]:
        """Descarga una página HTML"""
        try:
            print(f"📥 Descargando: {url}")
            response = self.session.get(url, timeout=30)
            response.raise_for_status()
            response.encoding = 'utf-8'
            time.sleep(2)  # Respetar el servidor
            return response.text
        except Exception as e:
            print(f"❌ Error descargando {url}: {e}")
            return None
    
    def limpiar_texto(self, texto: str) -> str:
        """Limpia texto extraído del HTML"""
        if not texto:
            return ""
        # Remover espacios múltiples
        texto = re.sub(r'\s+', ' ', texto)
        # Remover saltos de línea múltiples
        texto = re.sub(r'\n+', '\n', texto)
        return texto.strip()
    
    def extraer_articulo(self, elemento) -> Optional[Dict]:
        """Extrae información de un artículo"""
        try:
            # Buscar número de artículo
            numero_match = re.search(r'Art[íi]culo\s+(\d+)', elemento.get_text(), re.IGNORECASE)
            if not numero_match:
                return None
            
            numero = numero_match.group(1)
            texto_completo = self.limpiar_texto(elemento.get_text())
            
            # Extraer contenido después del número
            contenido = texto_completo.split(numero, 1)[-1].strip()
            
            return {
                'numero': int(numero),
                'texto': contenido,
                'texto_completo': texto_completo
            }
        except Exception as e:
            print(f"⚠️ Error extrayendo artículo: {e}")
            return None
    
    def extraer_titulo_o_capitulo(self, elemento) -> Optional[Dict]:
        """Extrae información de títulos o capítulos"""
        try:
            texto = self.limpiar_texto(elemento.get_text())
            
            # Detectar TÍTULO
            titulo_match = re.search(r'T[ÍI]TULO\s+([IVXLCDM]+)', texto, re.IGNORECASE)
            if titulo_match:
                return {
                    'tipo': 'titulo',
                    'numero': titulo_match.group(1),
                    'nombre': texto.split(titulo_match.group(0))[-1].strip()
                }
            
            # Detectar CAPÍTULO
            capitulo_match = re.search(r'CAP[ÍI]TULO\s+([IVXLCDM]+)', texto, re.IGNORECASE)
            if capitulo_match:
                return {
                    'tipo': 'capitulo',
                    'numero': capitulo_match.group(1),
                    'nombre': texto.split(capitulo_match.group(0))[-1].strip()
                }
            
            # Detectar SECCIÓN
            seccion_match = re.search(r'SECCI[ÓO]N\s+([IVXLCDM]+)', texto, re.IGNORECASE)
            if seccion_match:
                return {
                    'tipo': 'seccion',
                    'numero': seccion_match.group(1),
                    'nombre': texto.split(seccion_match.group(0))[-1].strip()
                }
            
            return None
        except Exception as e:
            print(f"⚠️ Error extrayendo título/capítulo: {e}")
            return None
    
    def estructurar_ley(self, html: str, codigo: str, nombre: str) -> Dict:
        """Estructura una ley en formato JSON jerárquico"""
        soup = BeautifulSoup(html, 'html.parser')
        
        # Estructura base
        ley = {
            'codigo': codigo,
            'nombre': nombre,
            'fuente': 'ley.com.ve',
            'fecha_extraccion': time.strftime('%Y-%m-%d'),
            'estructura': []
        }
        
        # Buscar contenedor principal del contenido
        contenido = soup.find('div', class_='entry-content') or soup.find('article') or soup.body
        
        if not contenido:
            print("⚠️ No se encontró contenido principal")
            return ley
        
        # Estructura jerárquica
        titulo_actual = None
        capitulo_actual = None
        seccion_actual = None
        
        # Buscar todos los elementos relevantes
        elementos = contenido.find_all(['h1', 'h2', 'h3', 'h4', 'p', 'div'])
        
        for elemento in elementos:
            texto = elemento.get_text().strip()
            if not texto or len(texto) < 5:
                continue
            
            # Detectar estructura jerárquica
            estructura = self.extraer_titulo_o_capitulo(elemento)
            
            if estructura:
                if estructura['tipo'] == 'titulo':
                    # Nuevo título
                    titulo_actual = {
                        'titulo': estructura['numero'],
                        'nombre': estructura['nombre'],
                        'capitulos': []
                    }
                    ley['estructura'].append(titulo_actual)
                    capitulo_actual = None
                    seccion_actual = None
                    print(f"  📘 TÍTULO {estructura['numero']}: {estructura['nombre'][:50]}...")
                
                elif estructura['tipo'] == 'capitulo':
                    # Nuevo capítulo
                    capitulo_actual = {
                        'capitulo': estructura['numero'],
                        'nombre': estructura['nombre'],
                        'secciones': [],
                        'articulos': []
                    }
                    if titulo_actual:
                        titulo_actual['capitulos'].append(capitulo_actual)
                    else:
                        # Capítulo sin título padre
                        ley['estructura'].append({
                            'titulo': 'ÚNICO',
                            'nombre': 'Disposiciones Generales',
                            'capitulos': [capitulo_actual]
                        })
                        titulo_actual = ley['estructura'][-1]
                    seccion_actual = None
                    print(f"    📗 CAPÍTULO {estructura['numero']}: {estructura['nombre'][:50]}...")
                
                elif estructura['tipo'] == 'seccion':
                    # Nueva sección
                    seccion_actual = {
                        'seccion': estructura['numero'],
                        'nombre': estructura['nombre'],
                        'articulos': []
                    }
                    if capitulo_actual:
                        capitulo_actual['secciones'].append(seccion_actual)
                    print(f"      📄 SECCIÓN {estructura['numero']}: {estructura['nombre'][:50]}...")
            
            else:
                # Buscar artículo
                if 'art' in texto.lower()[:20]:
                    articulo = self.extraer_articulo(elemento)
                    if articulo:
                        # Agregar al contenedor apropiado
                        if seccion_actual:
                            seccion_actual['articulos'].append(articulo)
                        elif capitulo_actual:
                            capitulo_actual['articulos'].append(articulo)
                        elif titulo_actual and titulo_actual['capitulos']:
                            titulo_actual['capitulos'][-1]['articulos'].append(articulo)
                        else:
                            # Artículo suelto
                            if not ley['estructura']:
                                ley['estructura'].append({
                                    'titulo': 'ÚNICO',
                                    'nombre': 'Disposiciones',
                                    'capitulos': [{
                                        'capitulo': 'I',
                                        'nombre': 'General',
                                        'articulos': []
                                    }]
                                })
                            ley['estructura'][0]['capitulos'][0]['articulos'].append(articulo)
                        
                        print(f"        ✓ Artículo {articulo['numero']}")
        
        return ley
    
    def scrappear_ley(self, clave: str) -> bool:
        """Scrappea una ley específica"""
        if clave not in self.LEYES_CRITICAS:
            print(f"❌ Ley '{clave}' no encontrada en catálogo")
            return False
        
        info = self.LEYES_CRITICAS[clave]
        url = self.BASE_URL + info['url_suffix']
        
        print(f"\n{'='*70}")
        print(f"🔍 Scrappeando: {info['nombre']} ({info['sigla']})")
        print(f"{'='*70}")
        
        # Descargar HTML
        html = self.fetch_page(url)
        if not html:
            return False
        
        # Estructurar en JSON
        ley_json = self.estructurar_ley(html, info['sigla'], info['nombre'])
        
        # Contar artículos
        total_articulos = 0
        for titulo in ley_json['estructura']:
            for capitulo in titulo.get('capitulos', []):
                total_articulos += len(capitulo.get('articulos', []))
                for seccion in capitulo.get('secciones', []):
                    total_articulos += len(seccion.get('articulos', []))
        
        print(f"\n✅ Extraídos {total_articulos} artículos")
        
        # Guardar JSON
        output_file = self.output_dir / f"{info['sigla'].lower()}_scraped.json"
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(ley_json, f, ensure_ascii=False, indent=2)
        
        print(f"💾 Guardado en: {output_file}")
        return True
    
    def scrappear_todas(self, solo_criticas: bool = True):
        """Scrappea todas las leyes del catálogo"""
        leyes = self.LEYES_CRITICAS if solo_criticas else self.LEYES_CRITICAS
        
        print(f"\n{'='*70}")
        print(f"🚀 Iniciando scraping de {len(leyes)} leyes")
        print(f"{'='*70}\n")
        
        exitosas = 0
        fallidas = 0
        
        for clave in leyes:
            try:
                if self.scrappear_ley(clave):
                    exitosas += 1
                else:
                    fallidas += 1
                time.sleep(3)  # Pausa entre leyes
            except Exception as e:
                print(f"❌ Error en {clave}: {e}")
                fallidas += 1
        
        print(f"\n{'='*70}")
        print(f"📊 RESUMEN:")
        print(f"   ✅ Exitosas: {exitosas}")
        print(f"   ❌ Fallidas: {fallidas}")
        print(f"   📁 Archivos en: {self.output_dir}")
        print(f"{'='*70}\n")
    
    def listar_leyes(self):
        """Lista todas las leyes disponibles para scrappear"""
        print(f"\n{'='*70}")
        print("📚 LEYES DISPONIBLES PARA SCRAPPING")
        print(f"{'='*70}\n")
        
        for i, (clave, info) in enumerate(self.LEYES_CRITICAS.items(), 1):
            print(f"{i:2}. {info['sigla']:10} - {info['nombre']}")
            print(f"    Clave: {clave}")
            print(f"    URL: {self.BASE_URL}{info['url_suffix']}\n")
        
        print(f"{'='*70}\n")


def main():
    parser = argparse.ArgumentParser(
        description='Scraper de leyes venezolanas desde ley.com.ve'
    )
    parser.add_argument(
        '--ley',
        type=str,
        help='Clave de la ley a scrappear (ej: lcdoft, lcse, lod)'
    )
    parser.add_argument(
        '--todas',
        action='store_true',
        help='Scrappear todas las leyes críticas'
    )
    parser.add_argument(
        '--listar',
        action='store_true',
        help='Listar leyes disponibles'
    )
    parser.add_argument(
        '--output',
        type=str,
        default='../leyes_json',
        help='Directorio de salida para JSONs'
    )
    
    args = parser.parse_args()
    
    scraper = LeyVenezolanaScraper(output_dir=args.output)
    
    if args.listar:
        scraper.listar_leyes()
    elif args.todas:
        scraper.scrappear_todas()
    elif args.ley:
        scraper.scrappear_ley(args.ley)
    else:
        print("❌ Debes especificar --ley, --todas o --listar")
        print("Ejemplos:")
        print("  python scraper_leyes_ve.py --listar")
        print("  python scraper_leyes_ve.py --ley lcdoft")
        print("  python scraper_leyes_ve.py --todas")
        parser.print_help()


if __name__ == '__main__':
    main()
