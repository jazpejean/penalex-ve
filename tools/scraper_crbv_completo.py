#!/usr/bin/env python3
"""
Scraper completo de la CRBV con estructura jerárquica
Extrae: Preámbulo, Títulos, Capítulos, Artículos, Disposiciones
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

class CRBVCompleto:
    
    BASE_URL = "https://www.ley.com.ve"
    HEADERS = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    }
    
    # Mapeo de artículos a Títulos y Capítulos (extraído del índice)
    ESTRUCTURA_TITULOS = {
        'I': {
            'nombre': 'Principios Fundamentales',
            'articulos': list(range(1, 10)),  # Arts. 1-9
            'capitulos': []
        },
        'II': {
            'nombre': 'Del Espacio Geográfico y La División Política',
            'articulos': [],
            'capitulos': [
                {
                    'numero': 'I',
                    'nombre': 'Del Territorio y demás Espacios Geográficos',
                    'articulos': list(range(10, 16))  # Arts. 10-15
                },
                {
                    'numero': 'II',
                    'nombre': 'De la División Política',
                    'articulos': list(range(16, 19))  # Arts. 16-18
                }
            ]
        },
        'III': {
            'nombre': 'De los Deberes, Derechos Humanos y Garantías',
            'articulos': [],
            'capitulos': [
                {'numero': 'I', 'nombre': 'Disposiciones Generales', 'articulos': list(range(19, 32))},
                {'numero': 'II', 'nombre': 'De la Nacionalidad y de la Ciudadanía', 'articulos': list(range(32, 43))},
                {'numero': 'III', 'nombre': 'De los Derechos Civiles', 'articulos': list(range(43, 62))},
                {'numero': 'IV', 'nombre': 'De los Derechos Políticos y del Referendo Popular', 'articulos': list(range(62, 75))},
                {'numero': 'V', 'nombre': 'De los Derechos Sociales y de las Familias', 'articulos': list(range(75, 98))},
                {'numero': 'VI', 'nombre': 'De los Derechos Culturales y Educativos', 'articulos': list(range(98, 112))},
                {'numero': 'VII', 'nombre': 'De los Derechos Económicos', 'articulos': list(range(112, 119))},
                {'numero': 'VIII', 'nombre': 'De los Derechos de los Pueblos Indígenas', 'articulos': list(range(119, 127))},
                {'numero': 'IX', 'nombre': 'De los Derechos Ambientales', 'articulos': list(range(127, 130))},
                {'numero': 'X', 'nombre': 'De los Deberes', 'articulos': list(range(130, 136))}
            ]
        },
        'IV': {
            'nombre': 'Del Poder Público',
            'articulos': [],
            'capitulos': [
                {'numero': 'I', 'nombre': 'De las Disposiciones Fundamentales', 'articulos': list(range(136, 143))},
                {'numero': 'II', 'nombre': 'De la Competencia del Poder Público Nacional', 'articulos': list(range(143, 157))},
                {'numero': 'III', 'nombre': 'Del Poder Público Estadal', 'articulos': list(range(157, 168))},
                {'numero': 'IV', 'nombre': 'Del Poder Público Municipal', 'articulos': list(range(168, 185))},
                {'numero': 'V', 'nombre': 'Del Consejo Federal de Gobierno', 'articulos': list(range(185, 186))}
            ]
        },
        'V': {
            'nombre': 'De La Organización del Poder Público Nacional',
            'articulos': [],
            'capitulos': [
                {'numero': 'I', 'nombre': 'Del Poder Legislativo Nacional', 'articulos': list(range(186, 225))},
                {'numero': 'II', 'nombre': 'Del Poder Ejecutivo Nacional', 'articulos': list(range(225, 253))},
                {'numero': 'III', 'nombre': 'Del Poder Judicial y del Sistema de Justicia', 'articulos': list(range(253, 273))},
                {'numero': 'IV', 'nombre': 'Del Poder Ciudadano', 'articulos': list(range(273, 291))},
                {'numero': 'V', 'nombre': 'Del Poder Electoral', 'articulos': list(range(291, 298))}
            ]
        },
        'VI': {
            'nombre': 'Del Sistema Socio Económico',
            'articulos': [],
            'capitulos': [
                {'numero': 'I', 'nombre': 'Del Régimen Socioeconómico y de la Función del Estado en la Economía', 'articulos': list(range(299, 321))},
                {'numero': 'II', 'nombre': 'Del Régimen Fiscal y Monetario', 'articulos': list(range(321, 327))}
            ]
        },
        'VII': {
            'nombre': 'De La Seguridad De La Nación',
            'articulos': [],
            'capitulos': [
                {'numero': 'I', 'nombre': 'Disposiciones Generales', 'articulos': list(range(322, 327))},
                {'numero': 'II', 'nombre': 'De los Principios de Seguridad de la Nación', 'articulos': list(range(327, 331))},
                {'numero': 'III', 'nombre': 'De la Fuerza Armada Nacional', 'articulos': list(range(328, 331))},
                {'numero': 'IV', 'nombre': 'De los órganos de Seguridad Ciudadana', 'articulos': list(range(332, 333))}
            ]
        },
        'VIII': {
            'nombre': 'De La Protección De La Constitución',
            'articulos': [],
            'capitulos': [
                {'numero': 'I', 'nombre': 'De la Garantía de esta Constitución', 'articulos': list(range(333, 337))},
                {'numero': 'II', 'nombre': 'De los Estados de Excepción', 'articulos': list(range(337, 340))}
            ]
        },
        'IX': {
            'nombre': 'De La Reforma Constitucional',
            'articulos': [],
            'capitulos': [
                {'numero': 'I', 'nombre': 'De las Enmiendas', 'articulos': list(range(340, 342))},
                {'numero': 'II', 'nombre': 'De la Reforma Constitucional', 'articulos': list(range(342, 347))},
                {'numero': 'III', 'nombre': 'De la Asamblea Nacional Constituyente', 'articulos': list(range(347, 351))}
            ]
        }
    }
    
    def __init__(self, output_dir: str = '../leyes_json'):
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(exist_ok=True)
        self.session = requests.Session()
        self.session.headers.update(self.HEADERS)
    
    def limpiar_texto(self, texto: str) -> str:
        """Limpia texto de referencias y basura"""
        if not texto:
            return ""
        
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
    
    def extraer_contenido(self, url: str) -> Optional[str]:
        """Extrae contenido de una URL"""
        try:
            response = self.session.get(url, timeout=30)
            if response.status_code == 404:
                return None
            
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
                    texto = self.limpiar_texto(texto)
                    if texto:
                        parrafos.append(texto)
            
            return '\n\n'.join(parrafos)
        
        except Exception as e:
            print(f"    ⚠️ Error: {e}")
            return None
    
    def extraer_articulo(self, numero: int) -> Optional[Dict]:
        """Extrae un artículo individual"""
        url = f"{self.BASE_URL}/constitucion/constitucion-de-la-republica-bolivariana-de-venezuela-articulo-{numero}"
        texto = self.extraer_contenido(url)
        
        if not texto:
            return None
        
        # Limpiar prefijo "CRBV Artículo X."
        texto = re.sub(r'^CRBV\s+Artículo\s+\d+\.?\s*', '', texto, flags=re.IGNORECASE).strip()
        
        return {
            'numero': numero,
            'titulo': f'Artículo {numero}',
            'texto': texto
        }
    
    def encontrar_ubicacion(self, num_articulo: int) -> Dict:
        """Encuentra a qué Título y Capítulo pertenece un artículo"""
        for titulo_num, titulo_data in self.ESTRUCTURA_TITULOS.items():
            # Verificar si está en artículos directos del título
            if num_articulo in titulo_data['articulos']:
                return {
                    'titulo': titulo_num,
                    'titulo_nombre': titulo_data['nombre'],
                    'capitulo': None,
                    'capitulo_nombre': None
                }
            
            # Verificar en capítulos
            for capitulo in titulo_data['capitulos']:
                if num_articulo in capitulo['articulos']:
                    return {
                        'titulo': titulo_num,
                        'titulo_nombre': titulo_data['nombre'],
                        'capitulo': capitulo['numero'],
                        'capitulo_nombre': capitulo['nombre']
                    }
        
        return {
            'titulo': None,
            'titulo_nombre': None,
            'capitulo': None,
            'capitulo_nombre': None
        }
    
    def scrappear_completo(self):
        """Scrappea la CRBV completa con estructura jerárquica"""
        print("\n" + "="*70)
        print("🔍 SCRAPEANDO CRBV COMPLETA CON ESTRUCTURA JERÁRQUICA")
        print("="*70 + "\n")
        
        estructura_completa = []
        
        # 1. PREÁMBULO
        print("📥 Extrayendo Preámbulo...")
        url_preambulo = f"{self.BASE_URL}/constitucion/preambulo"
        texto_preambulo = self.extraer_contenido(url_preambulo)
        
        if texto_preambulo:
            texto_preambulo = re.sub(r'^Preámbulo\.?\s*', '', texto_preambulo, flags=re.IGNORECASE).strip()
            estructura_completa.append({
                'tipo': 'preambulo',
                'titulo': 'Preámbulo',
                'texto': texto_preambulo
            })
            print(f"   ✅ Preámbulo ({len(texto_preambulo)} chars)\n")
        
        time.sleep(1)
        
        # 2. ARTÍCULOS 1-350 CON JERARQUÍA
        print("📥 Extrayendo artículos con jerarquía de Títulos y Capítulos...\n")
        
        articulos_extraidos = []
        
        for num in range(1, 351):
            if num % 20 == 1:
                print(f"📥 Artículos {num}-{min(num+19, 350)}...")
            
            articulo = self.extraer_articulo(num)
            
            if articulo:
                # Agregar ubicación jerárquica
                ubicacion = self.encontrar_ubicacion(num)
                articulo['pertenece_a'] = ubicacion
                
                articulos_extraidos.append(articulo)
                
                if num % 20 == 0:
                    print(f"   → {len(articulos_extraidos)} artículos extraídos")
            
            time.sleep(0.8)
        
        print(f"\n✅ {len(articulos_extraidos)} artículos extraídos\n")
        
        # Agregar artículos a la estructura
        estructura_completa.extend(articulos_extraidos)
        
        # 3. DISPOSICIONES TRANSITORIAS
        print("📥 Extrayendo Disposiciones Transitorias...")
        
        nombres_ordinales = [
            'primera', 'segunda', 'tercera', 'cuarta', 'quinta', 'sexta',
            'septima', 'octava', 'novena', 'decima', 'decimoprimera',
            'decimosegunda', 'decimotercera', 'decimocuarta', 'decimoquinta',
            'decimosexta', 'decimoseptima', 'decimoctava'
        ]
        
        for i, ordinal in enumerate(nombres_ordinales, 1):
            url_disp = f"{self.BASE_URL}/constitucion/crbv-disposicion-transitoria-{ordinal}"
            texto_disp = self.extraer_contenido(url_disp)
            
            if texto_disp:
                texto_disp = re.sub(r'^Disposición\s+Transitoria\s+\w+\.?\s*', '', texto_disp, flags=re.IGNORECASE).strip()
                
                estructura_completa.append({
                    'tipo': 'disposicion_transitoria',
                    'numero': i,
                    'titulo': f'Disposición Transitoria {ordinal.capitalize()}',
                    'texto': texto_disp
                })
                print(f"   ✅ Disposición Transitoria {ordinal.capitalize()}")
            
            time.sleep(0.8)
        
        # 4. DISPOSICIÓN FINAL
        print("\n📥 Extrayendo Disposición Final...")
        url_final = f"{self.BASE_URL}/constitucion/crbv-disposicion-final"
        texto_final = self.extraer_contenido(url_final)
        
        if texto_final:
            texto_final = re.sub(r'^Disposición\s+Final\.?\s*', '', texto_final, flags=re.IGNORECASE).strip()
            
            estructura_completa.append({
                'tipo': 'disposicion_final',
                'titulo': 'Disposición Final',
                'texto': texto_final
            })
            print("   ✅ Disposición Final\n")
        
        # Construir JSON final con metadata y jerarquía
        crbv_completa = {
            'metadata': {
                'codigo': 'CRBV',
                'nombre': 'Constitución de la República Bolivariana de Venezuela',
                'fecha_extraccion': time.strftime('%Y-%m-%d'),
                'total_elementos': len(estructura_completa),
                'contiene': {
                    'preambulo': 1,
                    'articulos': len(articulos_extraidos),
                    'disposiciones_transitorias': 18,
                    'disposicion_final': 1
                },
                'advertencia_legal': 'Contenido de referencia informativa. Verificar con Gaceta Oficial para uso legal.'
            },
            'estructura_jerarquica': self.ESTRUCTURA_TITULOS,
            'contenido': estructura_completa
        }
        
        # Guardar
        output_file = self.output_dir / 'crbv_completa.json'
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(crbv_completa, f, ensure_ascii=False, indent=2)
        
        print("="*70)
        print("📊 RESUMEN:")
        print(f"   Preámbulo: ✅")
        print(f"   Artículos: {len(articulos_extraidos)}")
        print(f"   Disposiciones Transitorias: 18")
        print(f"   Disposición Final: ✅")
        print(f"   Total elementos: {len(estructura_completa)}")
        print(f"\n💾 Guardado en: {output_file}")
        print("="*70 + "\n")

def main():
    scraper = CRBVCompleto()
    scraper.scrappear_completo()

if __name__ == '__main__':
    main()
