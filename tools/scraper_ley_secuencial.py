#!/usr/bin/env python3
"""
Scraper de leyes venezolanas (artículos secuenciales)
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

class LeySecuencialScraper:
    """Scraper para leyes con artículos en URLs secuenciales"""
    
    BASE_URL = "https://www.ley.com.ve"
    HEADERS = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'es-ES,es;q=0.9,en;q=0.8',
    }
    
    # Configuración de leyes disponibles
    LEYES_CONFIG = {
        'crbv': {
            'nombre': 'Constitución de la República Bolivariana de Venezuela',
            'sigla': 'CRBV',
            'categoria': 'constitucion',
            'slug': 'constitucion-de-la-republica-bolivariana-de-venezuela',
            'rango': (1, 350),
            'buscar_variantes': False  # CRBV no tiene artículos con letras
        },
        'cp': {
            'nombre': 'Código Penal',
            'sigla': 'CP',
            'categoria': 'penal',  # Corregido: usa /penal/ no /codigo-penal/
            'slug': 'codigo-penal',
            'rango': (1, 600),
            'buscar_variantes': True  # CP sí tiene 406-A, 191-A, etc.
        },
        'copp': {
            'nombre': 'Código Orgánico Procesal Penal',
            'sigla': 'COPP',
            'categoria': 'codigo-organico-procesal-penal',
            'slug': 'codigo-organico-procesal-penal',
            'rango': (1, 600),
            'buscar_variantes': False
        },
        'lopnna': {
            'nombre': 'Ley Orgánica para la Protección de Niños, Niñas y Adolescentes',
            'sigla': 'LOPNNA',
            'categoria': 'lopnna',
            'slug': 'ley-organica-para-la-proteccion-de-ninos-ninas-y-adolescentes',
            'rango': (1, 700),
            'buscar_variantes': False
        },
        'losdmvlv': {
            'nombre': 'Ley sobre el Derecho de las Mujeres a una Vida Libre de Violencia',
            'sigla': 'LOSDMVLV',
            'categoria': 'ley-organica-sobre-el-derecho-de-las-mujeres',
            'slug': 'ley-organica-sobre-el-derecho-de-las-mujeres-a-una-vida-libre-de-violencia',
            'rango': (1, 100),
            'buscar_variantes': False
        },
    }
    
    def __init__(self, output_dir: str = '../leyes_json'):
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(exist_ok=True)
        self.session = requests.Session()
        self.session.headers.update(self.HEADERS)
    
    def generar_url_articulo(self, config: Dict, numero: int) -> str:
        """Genera la URL de un artículo específico"""
        return f"{self.BASE_URL}/{config['categoria']}/{config['slug']}-articulo-{numero}"
    
    def scrappear_articulo(self, url: str, numero) -> Optional[Dict]:
        """Scrappea un artículo individual (numero puede ser int o string como '406-A')"""
        """Scrappea un artículo individual"""
        try:
            # Agregar delay y retry para páginas lentas
            max_intentos = 3
            for intento in range(max_intentos):
                try:
                    response = self.session.get(url, timeout=30)  # Aumentado a 30s
                    
                    # Si es 404, el artículo no existe
                    if response.status_code == 404:
                        if intento == 0:
                            print(f"    ⚠️ Art.{numero}: 404 Not Found")
                        return None
                    
                    response.raise_for_status()
                    response.encoding = 'utf-8'
                    
                    # Esperar un poco para asegurar carga completa
                    time.sleep(1)
                    
                    soup = BeautifulSoup(response.text, 'html.parser')
                    
                    # Buscar contenido EXACTO del artículo
                    contenido = soup.find('div', class_='com-content-article__body')
                    
                    if not contenido:
                        if intento < max_intentos - 1:
                            print(f"    🔄 Art.{numero}: Reintentando ({intento + 1}/{max_intentos})...")
                            time.sleep(2)
                            continue
                        else:
                            print(f"    ⚠️ Art.{numero}: Sin contenido después de {max_intentos} intentos")
                            return None
                    
                    # Extraer solo los párrafos <p> dentro del contenido
                    parrafos = []
                    for p in contenido.find_all('p'):
                        texto = p.get_text().strip()
                        if texto and len(texto) > 10:  # Ignorar párrafos muy cortos
                            # Limpiar textos basura del sitio
                            texto = self._limpiar_texto_basura(texto)
                            if texto:  # Solo agregar si quedó contenido después de limpiar
                                parrafos.append(texto)
                    
                    texto_completo = '\n\n'.join(parrafos)
                    
                    if not texto_completo or len(texto_completo) < 20:
                        if intento < max_intentos - 1:
                            print(f"    🔄 Art.{numero}: Texto vacío, reintentando...")
                            time.sleep(2)
                            continue
                        else:
                            print(f"    ⚠️ Art.{numero}: Texto vacío o muy corto")
                            return None
                    
                    # Limpiar texto (normalizar espacios)
                    texto_completo = re.sub(r'\s+', ' ', texto_completo)
                    
                    # Extraer número del artículo del texto (ej: "CRBV Artículo 103")
                    titulo_match = re.search(r'(CRBV|CP|COPP|LOPNNA)\s+Artículo\s+(\d+[-A-Z]*)', texto_completo)
                    if titulo_match:
                        numero_real = titulo_match.group(2)
                        titulo_texto = f"Artículo {numero_real}"
                        # Remover el prefijo del texto
                        texto_completo = re.sub(r'^.*?Artículo\s+\d+[-A-Z]*\.\s*', '', texto_completo).strip()
                    else:
                        titulo_texto = f"Artículo {numero}"
                    
                    # Detectar si tiene numerales o literales
                    tiene_estructura = bool(re.search(r'^\d+[.\)]|\n[a-z][.\)]', texto_completo, re.MULTILINE))
                    
                    articulo_data = {
                        'numero': numero,
                        'titulo': titulo_texto,
                        'url': url
                    }
                    
                    # Si tiene estructura compleja, extraerla
                    if tiene_estructura:
                        estructura_extraida = self._extraer_numerales(texto_completo)
                        if estructura_extraida and estructura_extraida['items']:
                            articulo_data['intro'] = estructura_extraida['intro']
                            articulo_data['items'] = estructura_extraida['items']
                        else:
                            # Fallback: guardar como texto simple
                            articulo_data['texto'] = texto_completo
                    else:
                        # Artículo simple sin numerales
                        articulo_data['texto'] = texto_completo
                    
                    # Limpiar espacios en todas las claves
                    articulo_data = self._limpiar_claves(articulo_data)
                    
                    return articulo_data
                    
                except requests.exceptions.Timeout:
                    if intento < max_intentos - 1:
                        print(f"    ⏱️ Art.{numero}: Timeout, reintentando...")
                        time.sleep(3)
                        continue
                    else:
                        print(f"    ⚠️ Art.{numero}: Timeout después de {max_intentos} intentos")
                        return None
            
            return None
            
        except requests.exceptions.RequestException as e:
            if "404" in str(e):
                return None
            print(f"    ⚠️ Art.{numero}: Error - {e}")
            return None
        except Exception as e:
            print(f"    ⚠️ Art.{numero}: Error inesperado - {e}")
            return None
    
    def _limpiar_texto_basura(self, texto: str) -> str:
        """Elimina textos de navegación y basura del sitio web"""
        if not texto:
            return ""
        
        # Patrones de texto basura (referencias cruzadas, navegación, etc.)
        patrones_basura = [
            # Concordancias y referencias cruzadas (el más común)
            r'Concordancia\s+adicional\s*[A-Z]{2,6}\s+artículo\s+\d+[\w\s]*',
            r'Concordancia\s+adicional[^.]*',
            r'Ver\s+también:?[^.]*',
            r'Artículos?\s+relacionados?:?[^.]*',
            r'Referencias?\s+cruzadas?:?[^.]*',
            # Gacetas oficiales
            r'Gaceta\s+Oficial\s+N[oº°]?\s*\d+[^.]*',
            r'Publicado\s+en:?[^.]*',
            r'G\.O\.\s+N[oº°]?\s*\d+[^.]*',
            # Navegación del sitio
            r'Compartir\s+en\s+redes\s+sociales',
            r'Imprimir\s+artículo',
            r'Descargar\s+PDF',
            r'Consultar\s+en:?',
            r'Fuente:?',
            r'Volver\s+al\s+índice',
            r'Ir\s+al\s+artículo',
            # Referencias a otros códigos al final
            r'[A-Z]{2,6}\s+artículo\s+\d+\s*$',
        ]
        
        import re
        for patron in patrones_basura:
            texto = re.sub(patron, '', texto, flags=re.IGNORECASE)
        
        # Normalizar espacios
        texto = re.sub(r'\s+', ' ', texto)
        
        return texto.strip()
    
    def _extraer_numerales(self, texto: str) -> Optional[Dict]:
        """Extrae numerales, literales y parágrafos de un artículo con estructura compleja"""
        lineas = texto.split('\n')
        
        estructura = {
            'intro': '',
            'items': [],
            'paragrafos': []
        }
        
        intro_lines = []
        current_numeral = None
        current_literales = []
        current_paragrafo = None
        
        for linea in lineas:
            linea = linea.strip()
            if not linea:
                continue
            
            # Detectar parágrafo: "Parágrafo Único", "Parágrafo Primero", etc.
            match_paragrafo = re.match(r'^(Parágrafo|Paragrafo)\s*(Único|Primero|Segundo|Tercero|Cuarto|Quinto)?[:\.]?\s*(.*)$', linea, re.IGNORECASE)
            if match_paragrafo:
                # Guardar numeral anterior si existe
                if current_numeral:
                    if current_literales:
                        current_numeral['literales'] = current_literales
                    estructura['items'].append(current_numeral)
                    current_numeral = None
                    current_literales = []
                
                # Nuevo parágrafo
                tipo = match_paragrafo.group(2) or 'Único'
                texto_paragrafo = match_paragrafo.group(3).strip()
                
                current_paragrafo = {
                    'tipo': tipo,
                    'texto': texto_paragrafo
                }
                continue
            
            # Detectar numeral: "1.", "2.", etc.
            match_numeral = re.match(r'^(\d+)[.\)]\s+(.+)$', linea)
            if match_numeral:
                # Guardar numeral anterior si existe
                if current_numeral:
                    if current_literales:
                        current_numeral['literales'] = current_literales
                    estructura['items'].append(current_numeral)
                
                # Nuevo numeral
                current_numeral = {
                    'numero': int(match_numeral.group(1)),
                    'texto': match_numeral.group(2).strip()
                }
                current_literales = []
                current_paragrafo = None  # Ya no estamos en parágrafo
                continue
            
            # Detectar literal: "a)", "b)", etc. dentro de un numeral
            match_literal = re.match(r'^([a-z])[.\)]\s+(.+)$', linea)
            if match_literal and current_numeral:
                current_literales.append({
                    'letra': match_literal.group(1),
                    'texto': match_literal.group(2).strip()
                })
                continue
            
            # Si estamos en un parágrafo, agregar al texto del parágrafo
            if current_paragrafo:
                if current_paragrafo['texto']:
                    current_paragrafo['texto'] += ' ' + linea
                else:
                    current_paragrafo['texto'] = linea
                continue
            
            # Si no es numeral, literal ni parágrafo
            if not current_numeral:
                intro_lines.append(linea)
            else:
                # Es continuación del numeral actual
                if current_literales:
                    # Agregar a último literal
                    current_literales[-1]['texto'] += ' ' + linea
                else:
                    # Agregar al texto del numeral
                    current_numeral['texto'] += ' ' + linea
        
        # Guardar último numeral
        if current_numeral:
            if current_literales:
                current_numeral['literales'] = current_literales
            estructura['items'].append(current_numeral)
        
        # Guardar último parágrafo
        if current_paragrafo:
            estructura['paragrafos'].append(current_paragrafo)
        
        estructura['intro'] = ' '.join(intro_lines).strip()
        
        # Solo retornar si realmente tiene estructura
        if estructura['items'] or estructura['paragrafos']:
            # Limpiar campos vacíos
            if not estructura['paragrafos']:
                del estructura['paragrafos']
            return estructura
        return None
    
    def _limpiar_claves(self, obj):
        """Elimina espacios de las claves recursivamente"""
        if isinstance(obj, dict):
            return {k.strip(): self._limpiar_claves(v) for k, v in obj.items()}
        elif isinstance(obj, list):
            return [self._limpiar_claves(item) for item in obj]
        elif isinstance(obj, str):
            return obj.strip()
        return obj
    
    def scrappear_ley(self, clave: str) -> bool:
        """Scrappea una ley completa"""
        if clave not in self.LEYES_CONFIG:
            print(f"❌ Ley '{clave}' no encontrada")
            print(f"Disponibles: {', '.join(self.LEYES_CONFIG.keys())}")
            return False
        
        config = self.LEYES_CONFIG[clave]
        inicio, fin = config['rango']
        
        print(f"\n{'='*70}")
        print(f"🔍 Scrappeando: {config['nombre']}")
        print(f"   Sigla: {config['sigla']}")
        print(f"   Rango: Artículos {inicio}-{fin}")
        print(f"{'='*70}\n")
        
        articulos = []
        articulos_fallidos = 0
        articulos_no_encontrados = 0
        
        for numero in range(inicio, fin + 1):
            # Primero intentar artículo normal
            url = self.generar_url_articulo(config, numero)
            
            # Mostrar progreso cada 10 artículos
            if numero % 10 == 1:
                print(f"📥 Descargando artículos {numero}-{min(numero+9, fin)}...")
            
            articulo = self.scrappear_articulo(url, numero)
            
            if articulo:
                articulos.append(articulo)
                articulos_no_encontrados = 0  # Resetear contador
                print(f"    ✓ Art.{numero}: OK ({len(articulo.get('texto', articulo.get('intro', '')))} chars)")
                
                # Intentar variantes con letras SOLO si está configurado
                if config.get('buscar_variantes', False):
                    for letra in ['a', 'b', 'c', 'd', 'e']:
                        url_letra = f"{self.BASE_URL}/{config['categoria']}/{config['slug']}-articulo-{numero}-{letra}"
                        articulo_letra = self.scrappear_articulo(url_letra, f"{numero}-{letra.upper()}")
                        
                        if articulo_letra:
                            articulos.append(articulo_letra)
                            print(f"    ✓ Art.{numero}-{letra.upper()}: OK")
                        else:
                            break  # Si no existe 406-A, no buscar 406-B
                
                if numero % 10 == 0:
                    print(f"   → {len(articulos)} artículos extraídos")
            else:
                articulos_no_encontrados += 1
                # Si hay 50 artículos consecutivos no encontrados, probablemente terminamos
                if articulos_no_encontrados >= 50:
                    print(f"   ℹ️ Se encontraron 50 artículos consecutivos inexistentes")
                    print(f"   ℹ️ Asumiendo fin de la ley en artículo {numero-50}")
                    break
            
            # Pausa para no saturar el servidor y dar tiempo a cargar
            time.sleep(1.5)  # Aumentado de 0.5s a 1.5s
        
        if not articulos:
            print("❌ No se extrajo ningún artículo")
            return False
        
        # Estructurar JSON con nodo raíz y metadatos
        ley_json = {
            'metadata': {
                'codigo': config['sigla'],
                'nombre': config['nombre'],
                'fecha_extraccion': time.strftime('%Y-%m-%d'),
                'total_articulos': len(articulos),
                'rango_scrapeado': f"Artículos {inicio}-{fin}",
                'articulos_extraidos': len(articulos),
                'articulos_no_encontrados': articulos_no_encontrados,
                'advertencia_legal': 'Contenido de referencia informativa. Verificar con Gaceta Oficial para uso legal.'
            },
            'estructura': articulos  # Array de artículos
        }
        
        print(f"\n✅ Extraídos {len(articulos)} artículos válidos")
        print(f"   ℹ️ {articulos_no_encontrados} artículos no encontrados (probablemente no existen)")
        
        # Guardar JSON
        output_file = self.output_dir / f"{config['sigla'].lower()}_scraped.json"
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(ley_json, f, ensure_ascii=False, indent=2)
        
        print(f"💾 Guardado en: {output_file}")
        
        return True
    
    def scrappear_todas(self):
        """Scrappea todas las leyes configuradas"""
        print(f"\n{'='*70}")
        print(f"🚀 Iniciando scraping de {len(self.LEYES_CONFIG)} leyes")
        print(f"{'='*70}")
        
        exitosas = 0
        fallidas = 0
        
        for clave in self.LEYES_CONFIG.keys():
            try:
                if self.scrappear_ley(clave):
                    exitosas += 1
                else:
                    fallidas += 1
            except Exception as e:
                print(f"❌ Error crítico en {clave}: {e}")
                fallidas += 1
            
            # Pausa entre leyes
            time.sleep(3)
        
        print(f"\n{'='*70}")
        print(f"📊 RESUMEN:")
        print(f"   ✅ Exitosas: {exitosas}")
        print(f"   ❌ Fallidas: {fallidas}")
        print(f"   📁 Archivos en: {self.output_dir}")
        print(f"{'='*70}\n")
    
    def listar_leyes(self):
        """Lista las leyes disponibles"""
        print(f"\n{'='*70}")
        print("📚 LEYES DISPONIBLES PARA SCRAPING")
        print(f"{'='*70}\n")
        
        for i, (clave, config) in enumerate(self.LEYES_CONFIG.items(), 1):
            inicio, fin = config['rango']
            print(f"{i}. {config['sigla']:10} - {config['nombre']}")
            print(f"   Clave: {clave}")
            print(f"   Rango: Artículos {inicio}-{fin}")
            print(f"   URL ejemplo: {self.generar_url_articulo(config, 1)}\n")
        
        print(f"{'='*70}\n")


def main():
    import argparse
    
    parser = argparse.ArgumentParser(
        description='Scraper de leyes venezolanas'
    )
    parser.add_argument(
        '--ley',
        type=str,
        help='Clave de la ley (ej: crbv, cp, copp, lopnna)'
    )
    parser.add_argument(
        '--todas',
        action='store_true',
        help='Scrappear todas las leyes'
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
        help='Directorio de salida'
    )
    
    args = parser.parse_args()
    
    scraper = LeySecuencialScraper(output_dir=args.output)
    
    if args.listar:
        scraper.listar_leyes()
    elif args.todas:
        scraper.scrappear_todas()
    elif args.ley:
        scraper.scrappear_ley(args.ley)
    else:
        print("❌ Debes especificar --ley, --todas o --listar")
        print("\nEjemplos:")
        print("  python scraper_ley_secuencial.py --listar")
        print("  python scraper_ley_secuencial.py --ley crbv")
        print("  python scraper_ley_secuencial.py --todas")


if __name__ == '__main__':
    main()
