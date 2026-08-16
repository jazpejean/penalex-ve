#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Scraper de Sentencias TSJ Venezuela
Extrae sentencias de todas las salas del Tribunal Supremo de Justicia
"""

import requests
from bs4 import BeautifulSoup
import json
import time
import re
from datetime import datetime
from urllib.parse import urljoin
import os

# Configuración
BASE_URL = "https://historico.tsj.gob.ve"
OUTPUT_DIR = "sentencias_tsj"
DELAY_ENTRE_REQUESTS = 2  # segundos

# Salas del TSJ
SALAS = {
    'penal': 'Sala Penal',
    'constitucional': 'Sala Constitucional',
    'politicoadministrativa': 'Sala Político-Administrativa',
    'electoral': 'Sala Electoral',
    'social': 'Sala Social',
    'civil': 'Sala Civil',
    'tplen': 'Sala Plena'
}

MESES = [
    'enero', 'febrero', 'marzo', 'abril',
    'mayo', 'junio', 'julio', 'agosto',
    'septiembre', 'octubre', 'noviembre', 'diciembre'
]

# Headers para simular navegador
HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
    'Accept-Language': 'es-ES,es;q=0.9,en;q=0.8',
}


class TSJScraper:
    def __init__(self):
        self.session = requests.Session()
        self.session.headers.update(HEADERS)
        self.estadisticas = {
            'salas_procesadas': 0,
            'meses_procesados': 0,
            'sentencias_extraidas': 0,
            'errores': 0
        }
    
    def scrape_mes_sala(self, sala_codigo, sala_nombre, mes, anio):
        """
        Extrae todas las sentencias de una sala en un mes específico
        """
        url = f"{BASE_URL}/{sala_codigo}/{mes}/"
        print(f"\n📅 Procesando: {sala_nombre} - {mes.title()} {anio}")
        print(f"   URL: {url}")
        
        try:
            response = self.session.get(url, timeout=15)
            response.raise_for_status()
            
            soup = BeautifulSoup(response.content, 'html.parser')
            
            # Buscar enlaces a sentencias
            enlaces = self._extraer_enlaces_sentencias(soup, url)
            
            print(f"   ✅ Encontrados {len(enlaces)} enlaces")
            
            sentencias = []
            for i, enlace in enumerate(enlaces, 1):
                print(f"   📄 Extrayendo {i}/{len(enlaces)}: {enlace['titulo']}")
                
                sentencia = self._extraer_sentencia(enlace['url'], sala_nombre, mes, anio)
                if sentencia:
                    sentencias.append(sentencia)
                    self.estadisticas['sentencias_extraidas'] += 1
                
                time.sleep(DELAY_ENTRE_REQUESTS)
            
            self.estadisticas['meses_procesados'] += 1
            return sentencias
            
        except requests.exceptions.RequestException as e:
            print(f"   ❌ Error accediendo a {url}: {e}")
            self.estadisticas['errores'] += 1
            return []
    
    def _extraer_enlaces_sentencias(self, soup, base_url):
        """
        Extrae todos los enlaces a sentencias de la página del mes
        """
        enlaces = []
        
        # Buscar enlaces en la página (ajustar selectores según HTML real)
        for link in soup.find_all('a', href=True):
            href = link['href']
            texto = link.get_text(strip=True)
            
            # Filtrar solo enlaces a sentencias (ajustar pattern según TSJ)
            if any(palabra in href.lower() for palabra in ['sentencia', 'decisiones', '.html', '.php']):
                url_completa = urljoin(base_url, href)
                
                if url_completa not in [e['url'] for e in enlaces]:
                    enlaces.append({
                        'url': url_completa,
                        'titulo': texto or 'Sin título'
                    })
        
        return enlaces
    
    def _extraer_sentencia(self, url, sala, mes, anio):
        """
        Extrae los datos de una sentencia individual
        """
        try:
            response = self.session.get(url, timeout=15)
            response.raise_for_status()
            
            soup = BeautifulSoup(response.content, 'html.parser')
            texto_completo = soup.get_text(separator='\n', strip=True)
            
            # Extraer campos
            sentencia = {
                'url': url,
                'sala': sala,
                'mes': mes,
                'anio': anio,
                'numero': self._extraer_numero(texto_completo),
                'fecha': self._extraer_fecha(texto_completo),
                'expediente': self._extraer_expediente(texto_completo),
                'ponente': self._extraer_ponente(texto_completo),
                'delitos': self._extraer_delitos(texto_completo),
                'tipo_decision': self._extraer_tipo_decision(texto_completo),
                'partes': self._extraer_partes(texto_completo),
                'articulos_citados': self._extraer_articulos(texto_completo),
                'extracto': self._extraer_extracto(texto_completo),
                'texto_completo': texto_completo,
                'scraped_at': datetime.now().isoformat()
            }
            
            return sentencia
            
        except Exception as e:
            print(f"      ⚠️ Error extrayendo {url}: {e}")
            self.estadisticas['errores'] += 1
            return None
    
    def _extraer_numero(self, texto):
        """Extrae número de sentencia"""
        patterns = [
            r'Sentencia\s+N[°º\.]\s*(\d+)',
            r'Decisión\s+N[°º\.]\s*(\d+)',
            r'N[°º]\s*(\d+)',
        ]
        
        for pattern in patterns:
            match = re.search(pattern, texto, re.IGNORECASE)
            if match:
                return match.group(1)
        
        return "S/N"
    
    def _extraer_fecha(self, texto):
        """Extrae fecha de sentencia"""
        pattern = r'(\d{1,2})\s+de\s+(\w+)\s+de\s+(\d{4})'
        match = re.search(pattern, texto, re.IGNORECASE)
        
        if match:
            dia, mes, anio = match.groups()
            return f"{dia}/{mes}/{anio}"
        
        return None
    
    def _extraer_expediente(self, texto):
        """Extrae número de expediente"""
        patterns = [
            r'Expediente\s+N[°º\.]\s*([A-Z0-9\-\.]+)',
            r'Exp\.\s*([A-Z0-9\-\.]+)',
        ]
        
        for pattern in patterns:
            match = re.search(pattern, texto, re.IGNORECASE)
            if match:
                return match.group(1).strip()
        
        return None
    
    def _extraer_ponente(self, texto):
        """Extrae magistrado ponente"""
        patterns = [
            r'Ponente:\s*([A-ZÁÉÍÓÚÑ][a-záéíóúñ]+(?:\s+[A-ZÁÉÍÓÚÑ][a-záéíóúñ]+){1,3})',
            r'Magistrad[oa]\s+Ponente:\s*([A-ZÁÉÍÓÚÑ\s\.]+)',
        ]
        
        for pattern in patterns:
            match = re.search(pattern, texto, re.IGNORECASE | re.MULTILINE)
            if match:
                return match.group(1).strip()
        
        return None
    
    def _extraer_delitos(self, texto):
        """Extrae delitos mencionados"""
        delitos_venezolanos = [
            'homicidio', 'homicidio calificado', 'homicidio culposo',
            'robo', 'robo agravado', 'robo en grado de frustración',
            'hurto', 'hurto calificado',
            'lesiones', 'lesiones graves', 'lesiones leves',
            'violación', 'abuso sexual',
            'secuestro', 'secuestro express',
            'extorsión',
            'estafa', 'estafa agravada',
            'narcotráfico', 'tráfico de drogas',
            'porte ilícito de arma', 'porte ilícito',
            'legitimación de capitales', 'lavado de dinero',
            'corrupción', 'peculado',
            'trata de personas',
            'violencia de género', 'violencia contra la mujer',
            'resistencia a la autoridad',
            'asociación para delinquir'
        ]
        
        texto_lower = texto.lower()
        encontrados = []
        
        for delito in delitos_venezolanos:
            if delito in texto_lower:
                if delito not in encontrados:
                    encontrados.append(delito.title())
        
        return encontrados
    
    def _extraer_tipo_decision(self, texto):
        """Extrae tipo de decisión"""
        tipos = {
            'casación': ['casación', 'casa', 'anula', 'anulación'],
            'amparo': ['amparo', 'tutela'],
            'apelación': ['apelación', 'apela', 'revoca', 'revocatoria'],
            'revisión': ['revisión'],
            'nulidad': ['nulidad', 'declara nulo'],
            'inadmisible': ['inadmisible', 'inadmisibilidad'],
            'desiste': ['desiste', 'desistimiento'],
        }
        
        texto_lower = texto.lower()
        
        for tipo, palabras in tipos.items():
            if any(palabra in texto_lower for palabra in palabras):
                return tipo.title()
        
        return "No especificado"
    
    def _extraer_partes(self, texto):
        """Extrae partes del proceso"""
        partes = {}
        
        # Buscar acusado/imputado
        pattern_acusado = r'(?:acusad[oa]|imputad[oa])[:\s]+([A-ZÁÉÍÓÚÑ][a-záéíóúñ]+(?:\s+[A-ZÁÉÍÓÚÑ][a-záéíóúñ]+)*)'
        match = re.search(pattern_acusado, texto, re.IGNORECASE)
        if match:
            partes['acusado'] = match.group(1).strip()
        
        # Buscar víctima
        pattern_victima = r'víctima[:\s]+([A-ZÁÉÍÓÚÑ][a-záéíóúñ]+(?:\s+[A-ZÁÉÍÓÚÑ][a-záéíóúñ]+)*)'
        match = re.search(pattern_victima, texto, re.IGNORECASE)
        if match:
            partes['victima'] = match.group(1).strip()
        
        return partes
    
    def _extraer_articulos(self, texto):
        """Extrae artículos legales citados"""
        articulos = []
        
        # Patrones para diferentes formatos de artículos
        patterns = [
            r'art[íi]culo\s+(\d+)[°º\.]?\s+(?:del\s+)?([A-Z][a-záéíóúñ\s]+)',
            r'art[\.]\s+(\d+)[°º\.]?\s+(?:del\s+)?([A-Z][a-záéíóúñ\s]+)',
            r'artículos?\s+(\d+)\s+y\s+(\d+)',
        ]
        
        for pattern in patterns:
            matches = re.finditer(pattern, texto, re.IGNORECASE)
            for match in matches:
                articulo = match.group(0).strip()
                if articulo not in articulos:
                    articulos.append(articulo)
        
        return articulos[:10]  # Limitar a 10 más relevantes
    
    def _extraer_extracto(self, texto):
        """Extrae extracto relevante de la sentencia"""
        # Buscar inicio relevante
        inicio_markers = ['SENTENCIA', 'DECISIÓN', 'VISTO', 'Expediente']
        inicio_pos = -1
        
        for marker in inicio_markers:
            pos = texto.upper().find(marker)
            if pos > -1 and (inicio_pos == -1 or pos < inicio_pos):
                inicio_pos = pos
        
        if inicio_pos > -1:
            extracto = texto[inicio_pos:inicio_pos + 800]
        else:
            extracto = texto[:800]
        
        return extracto.strip()
    
    def scrape_anio_completo(self, anio, salas_objetivo=None):
        """
        Extrae todas las sentencias de un año completo
        """
        if salas_objetivo is None:
            salas_objetivo = SALAS.keys()
        
        print(f"\n{'='*60}")
        print(f"🚀 INICIANDO SCRAPING TSJ - AÑO {anio}")
        print(f"{'='*60}")
        print(f"Salas a procesar: {', '.join(salas_objetivo)}")
        print(f"Meses: {len(MESES)}")
        print(f"Total combinaciones: {len(salas_objetivo) * len(MESES)}")
        
        # Crear directorio de salida
        os.makedirs(OUTPUT_DIR, exist_ok=True)
        
        todas_sentencias = []
        
        for sala_codigo in salas_objetivo:
            sala_nombre = SALAS[sala_codigo]
            
            print(f"\n{'='*60}")
            print(f"📂 PROCESANDO: {sala_nombre}")
            print(f"{'='*60}")
            
            sentencias_sala = []
            
            for mes in MESES:
                sentencias_mes = self.scrape_mes_sala(
                    sala_codigo,
                    sala_nombre,
                    mes,
                    anio
                )
                
                sentencias_sala.extend(sentencias_mes)
                
                # Guardar progreso por mes
                if sentencias_mes:
                    archivo_mes = os.path.join(
                        OUTPUT_DIR,
                        f"tsj_{anio}_{sala_codigo}_{mes}.json"
                    )
                    with open(archivo_mes, 'w', encoding='utf-8') as f:
                        json.dump(sentencias_mes, f, ensure_ascii=False, indent=2)
                    
                    print(f"   💾 Guardado: {archivo_mes}")
            
            # Guardar consolidado por sala
            if sentencias_sala:
                archivo_sala = os.path.join(
                    OUTPUT_DIR,
                    f"tsj_{anio}_{sala_codigo}_completo.json"
                )
                with open(archivo_sala, 'w', encoding='utf-8') as f:
                    json.dump(sentencias_sala, f, ensure_ascii=False, indent=2)
                
                print(f"\n✅ {sala_nombre}: {len(sentencias_sala)} sentencias")
            
            todas_sentencias.extend(sentencias_sala)
            self.estadisticas['salas_procesadas'] += 1
            
            time.sleep(5)  # Pausa entre salas
        
        # Guardar consolidado total
        if todas_sentencias:
            archivo_total = os.path.join(
                OUTPUT_DIR,
                f"tsj_{anio}_COMPLETO.json"
            )
            with open(archivo_total, 'w', encoding='utf-8') as f:
                json.dump(todas_sentencias, f, ensure_ascii=False, indent=2)
            
            print(f"\n{'='*60}")
            print(f"✅ TOTAL: {len(todas_sentencias)} sentencias extraídas")
            print(f"💾 Archivo: {archivo_total}")
        
        return todas_sentencias
    
    def imprimir_estadisticas(self):
        """Imprime estadísticas finales"""
        print(f"\n{'='*60}")
        print(f"📊 ESTADÍSTICAS FINALES")
        print(f"{'='*60}")
        print(f"Salas procesadas: {self.estadisticas['salas_procesadas']}")
        print(f"Meses procesados: {self.estadisticas['meses_procesados']}")
        print(f"✅ Sentencias extraídas: {self.estadisticas['sentencias_extraidas']}")
        print(f"❌ Errores: {self.estadisticas['errores']}")
        print(f"{'='*60}\n")


def main():
    """Función principal"""
    import argparse
    
    parser = argparse.ArgumentParser(description='Scraper de Sentencias TSJ Venezuela')
    parser.add_argument('--anio', type=int, default=2024, help='Año a procesar (default: 2024)')
    parser.add_argument('--sala', type=str, help='Sala específica a procesar (opcional)')
    parser.add_argument('--test', action='store_true', help='Modo test: solo procesa enero de Sala Penal')
    
    args = parser.parse_args()
    
    scraper = TSJScraper()
    
    try:
        if args.test:
            print("🧪 MODO TEST: Solo Sala Penal - Enero")
            sentencias = scraper.scrape_mes_sala('penal', 'Sala Penal', 'enero', args.anio)
            print(f"\n✅ Test completado: {len(sentencias)} sentencias")
        
        elif args.sala:
            if args.sala in SALAS:
                scraper.scrape_anio_completo(args.anio, salas_objetivo=[args.sala])
            else:
                print(f"❌ Sala '{args.sala}' no válida. Opciones: {', '.join(SALAS.keys())}")
        
        else:
            scraper.scrape_anio_completo(args.anio)
        
        scraper.imprimir_estadisticas()
        
    except KeyboardInterrupt:
        print("\n\n⚠️ Proceso interrumpido por el usuario")
        scraper.imprimir_estadisticas()


if __name__ == "__main__":
    main()
