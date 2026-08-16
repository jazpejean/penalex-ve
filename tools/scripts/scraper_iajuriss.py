#!/usr/bin/env python3
"""
Scraper IaJuriss - Sentencias TSJ Sala Penal y Constitucional
Extrae sentencias de www.iajuriss.com/biblioteca con rate limiting
"""

import requests
import time
import json
import re
from pathlib import Path
from datetime import datetime
from tqdm import tqdm
import random
from bs4 import BeautifulSoup

# ============================================================================
# CONFIGURACIÓN
# ============================================================================

# Directorios de salida
OUTPUT_DIR = Path("sentencias_iajuriss")
CHECKPOINT_FILE = OUTPUT_DIR / "checkpoint.json"

# Rate limiting (segundos entre requests)
DELAY_MIN = 10  # Mínimo
DELAY_MAX = 15  # Máximo (aleatorio para parecer humano)

# Salas a scrapear
SALAS_OBJETIVO = [
    'Penal',
    'Constitucional'
]

# Headers para simular navegador
USER_AGENTS = [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:121.0) Gecko/20100101 Firefox/121.0',
]

# URLs Base
BASE_URL = "https://www.iajuriss.com"
BIBLIOTECA_URL = f"{BASE_URL}/biblioteca"

# ============================================================================
# FUNCIONES AUXILIARES
# ============================================================================

def crear_directorios():
    """Crea estructura de directorios"""
    OUTPUT_DIR.mkdir(exist_ok=True)
    (OUTPUT_DIR / "json").mkdir(exist_ok=True)
    (OUTPUT_DIR / "logs").mkdir(exist_ok=True)
    (OUTPUT_DIR / "html").mkdir(exist_ok=True)

def obtener_headers():
    """Genera headers aleatorios para simular navegador"""
    return {
        'User-Agent': random.choice(USER_AGENTS),
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'es-VE,es;q=0.9,en;q=0.8',
        'Accept-Encoding': 'gzip, deflate, br',
        'Connection': 'keep-alive',
        'Upgrade-Insecure-Requests': '1',
        'Cache-Control': 'max-age=0',
        'Referer': BASE_URL
    }

def guardar_checkpoint(estado):
    """Guarda estado actual para poder resumir"""
    estado['ultimo_guardado'] = datetime.now().isoformat()
    with open(CHECKPOINT_FILE, 'w', encoding='utf-8') as f:
        json.dump(estado, f, ensure_ascii=False, indent=2)

def cargar_checkpoint():
    """Carga estado guardado"""
    if CHECKPOINT_FILE.exists():
        with open(CHECKPOINT_FILE, 'r', encoding='utf-8') as f:
            return json.load(f)
    return {
        'procesadas': [],
        'pendientes': [],
        'errores': [],
        'stats': {
            'total': 0,
            'exitos': 0,
            'fallos': 0,
            'omitidas': 0
        }
    }

def esperar_rate_limit():
    """Espera aleatoria entre requests"""
    delay = random.uniform(DELAY_MIN, DELAY_MAX)
    time.sleep(delay)

def limpiar_texto(texto):
    """Limpia texto extraído"""
    if not texto:
        return ""
    # Eliminar espacios múltiples
    texto = re.sub(r'\s+', ' ', texto)
    # Eliminar saltos de línea excesivos
    texto = re.sub(r'\n\s*\n+', '\n\n', texto)
    return texto.strip()

def generar_id_sentencia(sentencia):
    """Genera ID único para sentencia"""
    sala = re.sub(r'[^a-z0-9]+', '_', sentencia.get('sala', 'sin_sala').lower())
    numero = re.sub(r'[^a-z0-9]+', '_', sentencia.get('numero', 'sin_numero').lower())
    fecha = re.sub(r'[^a-z0-9]+', '_', sentencia.get('fecha', 'sin_fecha').lower())
    
    return f"{sala}_{numero}_{fecha}"

# ============================================================================
# SCRAPER PRINCIPAL
# ============================================================================

class ScraperIaJuriss:
    def __init__(self):
        self.session = requests.Session()
        self.checkpoint = cargar_checkpoint()
        
    def buscar_api_endpoint(self):
        """
        Intenta descubrir el endpoint API de IaJuriss
        """
        print("🔍 Buscando endpoint API...")
        
        # Posibles endpoints API
        posibles_apis = [
            f"{BASE_URL}/api/sentencias",
            f"{BASE_URL}/api/biblioteca",
            f"{BASE_URL}/api/jurisprudencia",
            f"{BASE_URL}/api/search",
            f"{BASE_URL}/sentencias",
        ]
        
        for api_url in posibles_apis:
            try:
                print(f"  Probando: {api_url}")
                response = self.session.get(
                    api_url,
                    headers=obtener_headers(),
                    timeout=10
                )
                
                if response.status_code == 200:
                    print(f"  ✅ Encontrado: {api_url}")
                    
                    # Guardar respuesta para análisis
                    log_file = OUTPUT_DIR / "logs" / f"api_response_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
                    with open(log_file, 'w', encoding='utf-8') as f:
                        try:
                            json.dump(response.json(), f, ensure_ascii=False, indent=2)
                        except:
                            f.write(response.text)
                    
                    return api_url, response
                    
            except Exception as e:
                continue
        
        print("  ❌ No se encontró API pública")
        return None, None
    
    def explorar_estructura_html(self):
        """
        Explora la estructura HTML de la biblioteca
        """
        print("\n🔍 Explorando estructura HTML...")
        
        try:
            response = self.session.get(
                BIBLIOTECA_URL,
                headers=obtener_headers(),
                timeout=30
            )
            
            if response.status_code != 200:
                print(f"❌ Error HTTP {response.status_code}")
                return None
            
            # Guardar HTML para análisis
            html_file = OUTPUT_DIR / "html" / "biblioteca_main.html"
            with open(html_file, 'w', encoding='utf-8') as f:
                f.write(response.text)
            
            print(f"✅ HTML guardado: {html_file}")
            
            # Parsear con BeautifulSoup
            soup = BeautifulSoup(response.text, 'html.parser')
            
            # Buscar scripts que puedan contener datos
            scripts = soup.find_all('script')
            print(f"📜 Scripts encontrados: {len(scripts)}")
            
            for i, script in enumerate(scripts):
                if script.string and ('sentencias' in script.string.lower() or 
                                     'biblioteca' in script.string.lower() or
                                     'api' in script.string.lower()):
                    script_file = OUTPUT_DIR / "logs" / f"script_{i}.js"
                    with open(script_file, 'w', encoding='utf-8') as f:
                        f.write(script.string)
                    print(f"  💾 Script relevante guardado: script_{i}.js")
            
            # Buscar elementos de datos
            data_elements = soup.find_all(attrs={'data-sentencia': True})
            print(f"📊 Elementos data-sentencia: {len(data_elements)}")
            
            # Buscar links a sentencias
            links = soup.find_all('a', href=re.compile(r'sentencia|jurisprudencia'))
            print(f"🔗 Links a sentencias: {len(links)}")
            
            return soup
            
        except Exception as e:
            print(f"❌ Error explorando HTML: {e}")
            return None
    
    def extraer_sentencias_desde_api(self, api_url):
        """
        Extrae sentencias usando API descubierta
        """
        print(f"\n📡 Extrayendo desde API: {api_url}")
        
        sentencias_extraidas = []
        
        # Intentar con parámetros de filtro
        params_opciones = [
            {'sala': 'Penal'},
            {'sala': 'Constitucional'},
            {'tipo': 'sentencia', 'sala': 'Penal'},
            {'tipo': 'sentencia', 'sala': 'Constitucional'},
        ]
        
        for params in params_opciones:
            try:
                print(f"  Probando filtro: {params}")
                
                response = self.session.get(
                    api_url,
                    params=params,
                    headers=obtener_headers(),
                    timeout=30
                )
                
                if response.status_code == 200:
                    data = response.json()
                    
                    # Intentar extraer lista de sentencias
                    if isinstance(data, list):
                        sentencias = data
                    elif isinstance(data, dict):
                        # Buscar llave que contenga las sentencias
                        sentencias = (data.get('sentencias') or 
                                    data.get('data') or 
                                    data.get('results') or
                                    data.get('items') or [])
                    else:
                        sentencias = []
                    
                    print(f"  ✅ Encontradas: {len(sentencias)} sentencias")
                    sentencias_extraidas.extend(sentencias)
                    
                    esperar_rate_limit()
                    
            except Exception as e:
                print(f"  ❌ Error con parámetros {params}: {e}")
                continue
        
        return sentencias_extraidas
    
    def procesar_sentencia(self, sentencia_raw):
        """
        Procesa y normaliza una sentencia extraída
        """
        try:
            # Normalizar estructura
            sentencia = {
                'id': sentencia_raw.get('id', ''),
                'numero': sentencia_raw.get('numero', sentencia_raw.get('number', '')),
                'fecha': sentencia_raw.get('fecha', sentencia_raw.get('date', '')),
                'sala': sentencia_raw.get('sala', sentencia_raw.get('chamber', '')),
                'ponente': sentencia_raw.get('ponente', sentencia_raw.get('speaker', '')),
                'extracto': sentencia_raw.get('extracto', sentencia_raw.get('summary', '')),
                'texto_completo': sentencia_raw.get('texto', sentencia_raw.get('text', '')),
                'delitos': sentencia_raw.get('delitos', sentencia_raw.get('crimes', [])),
                'articulos': sentencia_raw.get('articulos', sentencia_raw.get('articles', [])),
                'partes': sentencia_raw.get('partes', sentencia_raw.get('parties', {})),
                'tipo_proceso': sentencia_raw.get('tipo_proceso', ''),
                'fuente': 'IaJuriss',
                'url_fuente': sentencia_raw.get('url', ''),
                'procesado': datetime.now().isoformat()
            }
            
            # Filtrar solo Penal y Constitucional
            if sentencia['sala'] not in SALAS_OBJETIVO:
                return None
            
            return sentencia
            
        except Exception as e:
            print(f"❌ Error procesando sentencia: {e}")
            return None
    
    def guardar_sentencia(self, sentencia):
        """Guarda sentencia en JSON individual"""
        try:
            # Generar nombre archivo
            doc_id = generar_id_sentencia(sentencia)
            filename = f"{doc_id}.json"
            filepath = OUTPUT_DIR / "json" / filename
            
            with open(filepath, 'w', encoding='utf-8') as f:
                json.dump(sentencia, f, ensure_ascii=False, indent=2)
            
            return True
            
        except Exception as e:
            print(f"❌ Error guardando: {e}")
            return False
    
    def scrapear_con_selenium(self):
        """
        Fallback: usar Selenium si no hay API
        NOTA: Requiere instalación de selenium y chromedriver
        """
        print("\n🌐 Intentando scraping con Selenium...")
        print("⚠️  Requiere: pip install selenium")
        print("⚠️  Requiere: chromedriver instalado")
        
        try:
            from selenium import webdriver
            from selenium.webdriver.chrome.options import Options
            from selenium.webdriver.common.by import By
            from selenium.webdriver.support.ui import WebDriverWait
            from selenium.webdriver.support import expected_conditions as EC
            
            # Configurar Chrome headless
            chrome_options = Options()
            chrome_options.add_argument('--headless')
            chrome_options.add_argument('--no-sandbox')
            chrome_options.add_argument('--disable-dev-shm-usage')
            chrome_options.add_argument(f'user-agent={random.choice(USER_AGENTS)}')
            
            driver = webdriver.Chrome(options=chrome_options)
            
            print("✅ Selenium inicializado")
            
            # Navegar a biblioteca
            driver.get(BIBLIOTECA_URL)
            time.sleep(5)  # Esperar carga
            
            # Guardar HTML renderizado
            html_file = OUTPUT_DIR / "html" / "biblioteca_selenium.html"
            with open(html_file, 'w', encoding='utf-8') as f:
                f.write(driver.page_source)
            
            print(f"💾 HTML renderizado guardado: {html_file}")
            
            # Aquí iría la lógica específica de scraping
            # según la estructura del sitio
            
            driver.quit()
            
            return True
            
        except ImportError:
            print("❌ Selenium no instalado")
            print("   Ejecuta: pip install selenium")
            return False
        except Exception as e:
            print(f"❌ Error con Selenium: {e}")
            return False
    
    def ejecutar_scraping(self):
        """
        Ejecuta el proceso completo de scraping
        """
        print("\n" + "="*70)
        print("🚀 INICIANDO SCRAPING")
        print("="*70)
        
        # Paso 1: Buscar API
        api_url, api_response = self.buscar_api_endpoint()
        
        if api_url:
            # Extraer desde API
            sentencias_raw = self.extraer_sentencias_desde_api(api_url)
            
            print(f"\n📦 Total extraídas: {len(sentencias_raw)}")
            
            # Procesar y guardar
            for sentencia_raw in tqdm(sentencias_raw, desc="Procesando sentencias"):
                sentencia = self.procesar_sentencia(sentencia_raw)
                
                if sentencia:
                    if self.guardar_sentencia(sentencia):
                        self.checkpoint['stats']['exitos'] += 1
                        self.checkpoint['procesadas'].append(sentencia['id'])
                    else:
                        self.checkpoint['stats']['fallos'] += 1
                else:
                    self.checkpoint['stats']['omitidas'] += 1
                
                # Guardar checkpoint cada 10 sentencias
                if len(self.checkpoint['procesadas']) % 10 == 0:
                    guardar_checkpoint(self.checkpoint)
                
                esperar_rate_limit()
        
        else:
            # Paso 2: Explorar HTML
            soup = self.explorar_estructura_html()
            
            if soup:
                print("\n📋 ANÁLISIS MANUAL REQUERIDO")
                print("="*70)
                print("Archivos generados para análisis:")
                print(f"  - {OUTPUT_DIR / 'html' / 'biblioteca_main.html'}")
                print(f"  - {OUTPUT_DIR / 'logs' / 'script_*.js'}")
                print("\n🔍 Próximos pasos:")
                print("1. Revisar HTML guardado")
                print("2. Buscar estructura de datos en scripts JS")
                print("3. Identificar endpoint API o estructura HTML")
                print("4. Actualizar funciones de extracción")
                print("\n💡 ALTERNATIVA: Usar DevTools del navegador")
                print("   - Abrir iajuriss.com/biblioteca")
                print("   - DevTools → Network → buscar llamadas API")
                print("   - Copiar endpoint y estructura JSON")
                print("="*70)
            
            # Paso 3: Intentar Selenium
            print("\n¿Intentar con Selenium? (y/n): ", end='')
            # En modo automático, saltar
            # respuesta = input().lower()
            # if respuesta == 'y':
            #     self.scrapear_con_selenium()
        
        # Guardar checkpoint final
        guardar_checkpoint(self.checkpoint)
        
        # Generar reporte
        self.generar_reporte()
    
    def generar_reporte(self):
        """Genera reporte final de scraping"""
        self.checkpoint['stats']['total'] = (
            self.checkpoint['stats']['exitos'] + 
            self.checkpoint['stats']['fallos'] + 
            self.checkpoint['stats']['omitidas']
        )
        
        reporte_path = OUTPUT_DIR / "logs" / f"reporte_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        
        with open(reporte_path, 'w', encoding='utf-8') as f:
            json.dump(self.checkpoint, f, ensure_ascii=False, indent=2)
        
        print("\n" + "="*70)
        print("📊 REPORTE FINAL")
        print("="*70)
        print(f"Total procesadas: {self.checkpoint['stats']['total']}")
        print(f"✅ Éxitos: {self.checkpoint['stats']['exitos']}")
        print(f"❌ Errores: {self.checkpoint['stats']['fallos']}")
        print(f"⏭️  Omitidas (otras salas): {self.checkpoint['stats']['omitidas']}")
        print(f"📄 Reporte guardado: {reporte_path}")
        print(f"📁 Sentencias en: {OUTPUT_DIR / 'json'}")
        print("="*70)

# ============================================================================
# MAIN
# ============================================================================

def main():
    print("="*70)
    print("🔍 SCRAPER IAJURISS - SALA PENAL Y CONSTITUCIONAL")
    print("="*70)
    print(f"📁 Directorio salida: {OUTPUT_DIR}")
    print(f"⏱️  Rate limiting: {DELAY_MIN}-{DELAY_MAX} segundos")
    print(f"🎯 Salas objetivo: {', '.join(SALAS_OBJETIVO)}")
    print(f"📊 Objetivo: ~24,000 sentencias")
    print("="*70)
    
    # Crear directorios
    crear_directorios()
    
    # Inicializar scraper
    scraper = ScraperIaJuriss()
    
    # Ejecutar scraping
    scraper.ejecutar_scraping()

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n⚠️  Scraping interrumpido por usuario")
        print("💾 Checkpoint guardado - puedes reanudar después")
    except Exception as e:
        print(f"\n\n❌ Error fatal: {e}")
        import traceback
        traceback.print_exc()
