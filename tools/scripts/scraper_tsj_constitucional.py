#!/usr/bin/env python3
"""
Scraper TSJ Sala Constitucional
Extrae sentencias directamente desde historico.tsj.gob.ve
"""

import requests
from bs4 import BeautifulSoup
import time
import json
import re
from pathlib import Path
from datetime import datetime
from tqdm import tqdm
import random

# ============================================================================
# CONFIGURACIÓN
# ============================================================================

# URLs Base TSJ
BASE_URL = "http://historico.tsj.gob.ve"
SALA_CONSTITUCIONAL_BASE = f"{BASE_URL}/decisiones/scon"

# Directorios
OUTPUT_DIR = Path("sentencias_tsj_constitucional")
CHECKPOINT_FILE = OUTPUT_DIR / "checkpoint.json"

# Rate limiting (segundos)
DELAY_MIN = 10
DELAY_MAX = 15

# Años a scrapear
ANIO_INICIO = 2000
ANIO_FIN = 2026

# User Agents
USER_AGENTS = [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
]

# ============================================================================
# FUNCIONES
# ============================================================================

def crear_directorios():
    OUTPUT_DIR.mkdir(exist_ok=True)
    (OUTPUT_DIR / "json").mkdir(exist_ok=True)
    (OUTPUT_DIR / "logs").mkdir(exist_ok=True)
    (OUTPUT_DIR / "html").mkdir(exist_ok=True)

def obtener_headers():
    return {
        'User-Agent': random.choice(USER_AGENTS),
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'es-VE,es;q=0.9,en;q=0.8',
        'Connection': 'keep-alive'
    }

def guardar_checkpoint(estado):
    estado['ultimo_guardado'] = datetime.now().isoformat()
    with open(CHECKPOINT_FILE, 'w', encoding='utf-8') as f:
        json.dump(estado, f, ensure_ascii=False, indent=2)

def cargar_checkpoint():
    if CHECKPOINT_FILE.exists():
        with open(CHECKPOINT_FILE, 'r', encoding='utf-8') as f:
            return json.load(f)
    return {
        'procesadas': [],
        'anios_completados': [],
        'stats': {'total': 0, 'exitos': 0, 'fallos': 0}
    }

def esperar_rate_limit():
    delay = random.uniform(DELAY_MIN, DELAY_MAX)
    time.sleep(delay)

def limpiar_texto(texto):
    if not texto:
        return ""
    texto = re.sub(r'\s+', ' ', texto)
    texto = re.sub(r'\n\s*\n+', '\n\n', texto)
    return texto.strip()

def generar_id_sentencia(numero, fecha, anio):
    numero_clean = re.sub(r'[^a-z0-9]+', '_', str(numero).lower())
    fecha_clean = re.sub(r'[^a-z0-9]+', '_', str(fecha).lower())
    return f"sc_{numero_clean}_{fecha_clean}_{anio}"

# ============================================================================
# SCRAPER
# ============================================================================

class ScraperTSJConstitucional:
    def __init__(self):
        self.session = requests.Session()
        self.checkpoint = cargar_checkpoint()
        
    def obtener_urls_anio(self, anio):
        """
        Obtiene URLs de sentencias para un año específico
        Prueba diferentes estructuras de URL del TSJ
        """
        urls_posibles = [
            f"{SALA_CONSTITUCIONAL_BASE}/{anio}/",
            f"{BASE_URL}/scon/{anio}/",
            f"{BASE_URL}/decisiones/scon/",
        ]
        
        for url_base in urls_posibles:
            try:
                response = self.session.get(
                    url_base,
                    headers=obtener_headers(),
                    timeout=30
                )
                
                if response.status_code == 200:
                    print(f"  ✅ Estructura encontrada: {url_base}")
                    
                    soup = BeautifulSoup(response.text, 'html.parser')
                    
                    # Buscar links a sentencias
                    links = []
                    
                    # Patrón 1: Links con "sentencia", "decision" o números
                    for a in soup.find_all('a', href=True):
                        href = a['href']
                        if any(kw in href.lower() for kw in ['sentencia', 'decision', 'sc']):
                            if href.startswith('http'):
                                links.append(href)
                            else:
                                links.append(BASE_URL + href if not href.startswith('/') else BASE_URL + href)
                    
                    # Patrón 2: Buscar en tablas
                    for table in soup.find_all('table'):
                        for a in table.find_all('a', href=True):
                            href = a['href']
                            if href.startswith('http'):
                                links.append(href)
                            else:
                                links.append(BASE_URL + href if not href.startswith('/') else BASE_URL + href)
                    
                    # Eliminar duplicados
                    links = list(set(links))
                    
                    if links:
                        # Guardar HTML para análisis
                        html_file = OUTPUT_DIR / "html" / f"indice_{anio}.html"
                        with open(html_file, 'w', encoding='utf-8') as f:
                            f.write(response.text)
                        
                        return links
                        
            except Exception as e:
                continue
        
        return []
    
    def extraer_sentencia_desde_url(self, url):
        """
        Extrae contenido de una sentencia desde su URL
        """
        try:
            response = self.session.get(
                url,
                headers=obtener_headers(),
                timeout=30
            )
            
            if response.status_code != 200:
                return None
            
            soup = BeautifulSoup(response.text, 'html.parser')
            
            # Extraer texto completo
            # Intentar diferentes selectores
            contenido = None
            
            # Método 1: Buscar div principal
            for selector in ['#contenido', '.sentencia', '.decision', 'article', 'main']:
                elem = soup.select_one(selector)
                if elem:
                    contenido = elem.get_text()
                    break
            
            # Método 2: Buscar por contenido extenso
            if not contenido:
                for elem in soup.find_all(['div', 'article', 'section']):
                    texto = elem.get_text()
                    if len(texto) > 1000:  # Sentencia típica es larga
                        contenido = texto
                        break
            
            # Método 3: Todo el body
            if not contenido:
                body = soup.find('body')
                if body:
                    contenido = body.get_text()
            
            if not contenido:
                return None
            
            contenido = limpiar_texto(contenido)
            
            # Extraer metadata del texto
            numero = self.extraer_numero(contenido)
            fecha = self.extraer_fecha(contenido)
            ponente = self.extraer_ponente(contenido)
            
            sentencia = {
                'numero': numero,
                'fecha': fecha,
                'anio': fecha.split('-')[0] if fecha and '-' in fecha else '',
                'sala': 'Constitucional',
                'ponente': ponente,
                'texto_completo': contenido[:50000],  # Limitar tamaño
                'extracto': contenido[:500] + '...',
                'url_tsj': url,
                'fuente': 'TSJ Histórico',
                'procesado': datetime.now().isoformat()
            }
            
            return sentencia
            
        except Exception as e:
            print(f"    ❌ Error extrayendo {url}: {e}")
            return None
    
    def extraer_numero(self, texto):
        """Extrae número de sentencia del texto"""
        patrones = [
            r'[Nn]º?\s*(\d+)',
            r'[Ss]entencia\s+[Nn]º?\s*(\d+)',
            r'[Ee]xpediente\s+[Nn]º?\s*(\d+-?\d*)',
        ]
        
        for patron in patrones:
            match = re.search(patron, texto[:500])
            if match:
                return match.group(1)
        
        return 'sin_numero'
    
    def extraer_fecha(self, texto):
        """Extrae fecha de sentencia del texto"""
        patrones = [
            r'(\d{1,2})\s+de\s+(\w+)\s+de\s+(\d{4})',
            r'(\d{1,2})/(\d{1,2})/(\d{4})',
            r'(\d{4})-(\d{2})-(\d{2})',
        ]
        
        meses = {
            'enero': '01', 'febrero': '02', 'marzo': '03',
            'abril': '04', 'mayo': '05', 'junio': '06',
            'julio': '07', 'agosto': '08', 'septiembre': '09',
            'octubre': '10', 'noviembre': '11', 'diciembre': '12'
        }
        
        for patron in patrones:
            match = re.search(patron, texto[:1000], re.IGNORECASE)
            if match:
                if 'de' in patron:  # Formato largo
                    dia, mes, anio = match.groups()
                    mes_num = meses.get(mes.lower(), '01')
                    return f"{anio}-{mes_num}-{dia.zfill(2)}"
                else:
                    return '-'.join(match.groups())
        
        return 'sin_fecha'
    
    def extraer_ponente(self, texto):
        """Extrae nombre del ponente del texto"""
        patrones = [
            r'[Pp]onente:\s*([A-ZÁÉÍÓÚÑ][a-záéíóúñ]+(?:\s+[A-ZÁÉÍÓÚÑ][a-záéíóúñ]+)+)',
            r'[Mm]agistrado\s+[Pp]onente:\s*([A-ZÁÉÍÓÚÑ][a-záéíóúñ]+(?:\s+[A-ZÁÉÍÓÚÑ][a-záéíóúñ]+)+)',
        ]
        
        for patron in patrones:
            match = re.search(patron, texto[:2000])
            if match:
                return match.group(1).strip()
        
        return 'No especificado'
    
    def guardar_sentencia(self, sentencia):
        """Guarda sentencia en JSON"""
        try:
            doc_id = generar_id_sentencia(
                sentencia['numero'],
                sentencia['fecha'],
                sentencia['anio']
            )
            
            filepath = OUTPUT_DIR / "json" / f"{doc_id}.json"
            
            with open(filepath, 'w', encoding='utf-8') as f:
                json.dump(sentencia, f, ensure_ascii=False, indent=2)
            
            return True
            
        except Exception as e:
            print(f"    ❌ Error guardando: {e}")
            return False
    
    def scrapear_anio(self, anio):
        """Scrapea todas las sentencias de un año"""
        print(f"\n{'='*70}")
        print(f"📅 PROCESANDO AÑO: {anio}")
        print(f"{'='*70}")
        
        # Obtener URLs de sentencias
        print(f"🔍 Buscando sentencias de {anio}...")
        urls = self.obtener_urls_anio(anio)
        
        if not urls:
            print(f"  ⚠️  No se encontraron sentencias para {anio}")
            return
        
        print(f"  ✅ Encontradas {len(urls)} URLs")
        
        # Procesar cada URL
        with tqdm(urls, desc=f"Año {anio}") as pbar:
            for url in pbar:
                # Evitar duplicados
                if url in self.checkpoint['procesadas']:
                    self.checkpoint['stats']['total'] += 1
                    continue
                
                # Extraer sentencia
                sentencia = self.extraer_sentencia_desde_url(url)
                
                if sentencia:
                    if self.guardar_sentencia(sentencia):
                        self.checkpoint['stats']['exitos'] += 1
                        self.checkpoint['procesadas'].append(url)
                    else:
                        self.checkpoint['stats']['fallos'] += 1
                else:
                    self.checkpoint['stats']['fallos'] += 1
                
                self.checkpoint['stats']['total'] += 1
                
                # Checkpoint cada 10 sentencias
                if len(self.checkpoint['procesadas']) % 10 == 0:
                    guardar_checkpoint(self.checkpoint)
                
                # Rate limiting
                esperar_rate_limit()
                
                pbar.set_postfix({
                    'exitos': self.checkpoint['stats']['exitos'],
                    'fallos': self.checkpoint['stats']['fallos']
                })
        
        self.checkpoint['anios_completados'].append(anio)
        guardar_checkpoint(self.checkpoint)
    
    def ejecutar(self):
        """Ejecuta scraping completo"""
        print("="*70)
        print("🏛️  SCRAPER TSJ - SALA CONSTITUCIONAL")
        print("="*70)
        print(f"📁 Output: {OUTPUT_DIR}")
        print(f"⏱️  Rate limit: {DELAY_MIN}-{DELAY_MAX} seg")
        print(f"📅 Años: {ANIO_INICIO}-{ANIO_FIN}")
        print("="*70)
        
        # Scrapear cada año
        for anio in range(ANIO_INICIO, ANIO_FIN + 1):
            if anio in self.checkpoint['anios_completados']:
                print(f"\n⏭️  Año {anio} ya completado, omitiendo...")
                continue
            
            self.scrapear_anio(anio)
        
        # Reporte final
        print("\n" + "="*70)
        print("📊 REPORTE FINAL")
        print("="*70)
        print(f"Total procesadas: {self.checkpoint['stats']['total']:,}")
        print(f"✅ Éxitos: {self.checkpoint['stats']['exitos']:,}")
        print(f"❌ Errores: {self.checkpoint['stats']['fallos']:,}")
        print(f"📁 Sentencias en: {OUTPUT_DIR / 'json'}")
        print("="*70)

# ============================================================================
# MAIN
# ============================================================================

def main():
    crear_directorios()
    
    scraper = ScraperTSJConstitucional()
    scraper.ejecutar()

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n⚠️  Scraping interrumpido")
        print("💾 Checkpoint guardado - ejecuta de nuevo para continuar")
    except Exception as e:
        print(f"\n\n❌ Error fatal: {e}")
        import traceback
        traceback.print_exc()
