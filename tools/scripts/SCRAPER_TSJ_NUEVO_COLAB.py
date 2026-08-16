# ============================================
# SCRAPER TSJ NUEVO SITIO - CON SELENIUM
# ============================================
# Scraper para el sitio moderno del TSJ:
# https://www.tsj.gob.ve/es/web/tsj/decisiones

print("=" * 60)
print("🔥 SCRAPER TSJ SITIO NUEVO - SELENIUM")
print("=" * 60)
print()

# 1. INSTALAR DEPENDENCIAS
print("📦 Instalando dependencias...")
!apt-get update -qq > /dev/null 2>&1
!apt-get install -y chromium-chromedriver -qq > /dev/null 2>&1
!pip install selenium beautifulsoup4 firebase-admin requests -q

print("✅ Dependencias instaladas")

# 2. IMPORTAR LIBRERÍAS
import json
import time
import random
import re
import os
from pathlib import Path
from datetime import datetime
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.chrome.options import Options
from bs4 import BeautifulSoup
from google.colab import drive, files
import firebase_admin
from firebase_admin import credentials, firestore
import requests
import urllib3
urllib3.disable_warnings()

# 3. MONTAR GOOGLE DRIVE
print("🔗 Montando Google Drive...")
try:
    if not os.path.exists('/content/drive/MyDrive'):
        drive.mount('/content/drive')
    print("✅ Google Drive montado")
except:
    print("⚠️  Continuando sin Drive")

# ============================================
# CONFIGURACIÓN
# ============================================

CARPETA_JSONS = "/content/drive/MyDrive/json_tsj_nuevo/"
CARPETA_HTML = "/content/htmls_tsj_nuevo"
ARCHIVO_PROGRESO = "/content/drive/MyDrive/progreso_scraper_tsj_nuevo.json"

os.makedirs(CARPETA_JSONS, exist_ok=True)
os.makedirs(CARPETA_HTML, exist_ok=True)

SALAS = {
    'SC': {
        'nombre': 'Sala Constitucional',
        'url': 'https://www.tsj.gob.ve/es/web/tsj/decisiones#1',
        'codigo': 'SC'
    },
    'SCP': {
        'nombre': 'Sala de Casación Penal',
        'url': 'https://www.tsj.gob.ve/es/web/tsj/decisiones#1',
        'codigo': 'SCP'
    }
}

# Firebase opcional
print("\n¿Deseas guardar en Firestore? (s/n)")
usar_firestore = input().lower() == 's'

db = None
if usar_firestore:
    print("📤 Sube firebase-credentials.json")
    uploaded = files.upload()
    cred_path = list(uploaded.keys())[0]
    
    try:
        app = firebase_admin.get_app()
        db = firestore.client()
        print("✅ Firebase OK")
    except ValueError:
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)
        db = firestore.client()
        print("✅ Firestore conectado")

# ============================================
# SISTEMA DE PROGRESO
# ============================================

def cargar_progreso():
    if os.path.exists(ARCHIVO_PROGRESO):
        try:
            with open(ARCHIVO_PROGRESO, 'r') as f:
                return json.load(f)
        except:
            return {"urls_procesadas": [], "total": 0}
    return {"urls_procesadas": [], "total": 0}

def guardar_progreso(progreso):
    try:
        progreso["ultima_actualizacion"] = datetime.now().isoformat()
        with open(ARCHIVO_PROGRESO, 'w') as f:
            json.dump(progreso, f, indent=2)
    except:
        pass

def marcar_procesada(progreso, url):
    if url not in progreso["urls_procesadas"]:
        progreso["urls_procesadas"].append(url)
        progreso["total"] = len(progreso["urls_procesadas"])
        guardar_progreso(progreso)

# ============================================
# CONFIGURAR SELENIUM
# ============================================

def crear_driver():
    """Crea un driver de Chrome configurado para Colab"""
    chrome_options = Options()
    chrome_options.add_argument('--headless')
    chrome_options.add_argument('--no-sandbox')
    chrome_options.add_argument('--disable-dev-shm-usage')
    chrome_options.add_argument('--disable-gpu')
    chrome_options.add_argument('--window-size=1920,1080')
    chrome_options.add_argument('--ignore-certificate-errors')
    chrome_options.add_argument('--allow-insecure-localhost')
    chrome_options.add_argument('user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36')
    
    driver = webdriver.Chrome(options=chrome_options)
    driver.set_page_load_timeout(30)
    
    return driver

# ============================================
# FUNCIONES DE SCRAPING
# ============================================

def esperar_carga(driver, timeout=10):
    """Espera a que la página cargue completamente"""
    try:
        WebDriverWait(driver, timeout).until(
            EC.presence_of_element_located((By.TAG_NAME, "body"))
        )
        time.sleep(2)
        return True
    except:
        return False

def obtener_urls_sentencias_pagina(driver):
    """Extrae todas las URLs de sentencias de la página actual"""
    urls = []
    
    try:
        # Esperar a que carguen las sentencias
        time.sleep(3)
        
        # Obtener el HTML
        html = driver.page_source
        soup = BeautifulSoup(html, 'html.parser')
        
        # Buscar enlaces a sentencias
        # El sitio puede usar diferentes patrones, probamos varios
        patrones = [
            {'tag': 'a', 'attrs': {'href': re.compile(r'/decisiones/')}},
            {'tag': 'a', 'attrs': {'class': re.compile(r'sentencia|decision', re.I)}},
            {'tag': 'a', 'attrs': {'href': re.compile(r'\.pdf$', re.I)}},
        ]
        
        for patron in patrones:
            enlaces = soup.find_all(**patron)
            for enlace in enlaces:
                href = enlace.get('href', '')
                if href:
                    # Construir URL completa
                    if href.startswith('http'):
                        url = href
                    elif href.startswith('/'):
                        url = f"https://www.tsj.gob.ve{href}"
                    else:
                        url = f"https://www.tsj.gob.ve/{href}"
                    
                    if url not in urls:
                        urls.append(url)
        
        # También buscar iframes que puedan contener las sentencias
        iframes = soup.find_all('iframe')
        for iframe in iframes:
            src = iframe.get('src', '')
            if src and ('decision' in src.lower() or 'sentencia' in src.lower()):
                if not src.startswith('http'):
                    src = f"https://www.tsj.gob.ve{src}"
                urls.append(src)
        
        return urls
        
    except Exception as e:
        print(f"   ⚠️ Error extrayendo URLs: {str(e)[:50]}")
        return []

def navegar_paginacion(driver, max_paginas=100):
    """Navega por todas las páginas de resultados"""
    todas_urls = []
    
    for pagina in range(1, max_paginas + 1):
        print(f"   📄 Página {pagina}...")
        
        # Extraer URLs de la página actual
        urls = obtener_urls_sentencias_pagina(driver)
        
        if urls:
            print(f"      ✅ {len(urls)} URLs encontradas")
            todas_urls.extend(urls)
        else:
            print(f"      ⚠️ No se encontraron URLs")
        
        # Buscar botón "Siguiente" o similar
        try:
            # Intentar varios selectores para el botón siguiente
            selectores_siguiente = [
                "//a[contains(text(), 'Siguiente')]",
                "//button[contains(text(), 'Siguiente')]",
                "//a[contains(@class, 'next')]",
                "//button[contains(@class, 'next')]",
                "//a[@rel='next']",
            ]
            
            boton_siguiente = None
            for selector in selectores_siguiente:
                try:
                    boton_siguiente = driver.find_element(By.XPATH, selector)
                    break
                except:
                    continue
            
            if boton_siguiente and boton_siguiente.is_enabled():
                boton_siguiente.click()
                time.sleep(3)
            else:
                print(f"   ℹ️  No hay más páginas")
                break
                
        except Exception as e:
            print(f"   ℹ️  Fin de paginación")
            break
    
    return todas_urls

def filtrar_por_sala(driver, sala_codigo):
    """Filtra las decisiones por sala"""
    try:
        # Buscar selector/filtro de sala
        # Esto depende de la estructura del sitio
        # Intentar varios métodos
        
        # Método 1: Dropdown/Select
        try:
            select_sala = driver.find_element(By.ID, "sala")
            select_sala.click()
            time.sleep(1)
            
            opcion = driver.find_element(By.XPATH, f"//option[contains(text(), '{sala_codigo}')]")
            opcion.click()
            time.sleep(2)
            return True
        except:
            pass
        
        # Método 2: Tabs/Pestañas
        try:
            tab = driver.find_element(By.XPATH, f"//a[contains(text(), '{sala_codigo}')]")
            tab.click()
            time.sleep(2)
            return True
        except:
            pass
        
        return False
        
    except Exception as e:
        print(f"   ⚠️ No se pudo filtrar por sala: {str(e)[:50]}")
        return False

def descargar_sentencia(url, session):
    """Descarga el contenido de una sentencia"""
    try:
        resp = session.get(url, timeout=20, verify=False)
        resp.raise_for_status()
        
        if len(resp.content) > 1000:
            return resp.text if 'html' in resp.headers.get('content-type', '').lower() else resp.content
        
        return None
        
    except:
        return None

def extraer_datos_sentencia(contenido, url, sala_codigo):
    """Extrae datos de una sentencia"""
    try:
        if isinstance(contenido, bytes):
            # Es un PDF, solo guardamos la URL
            return {
                'sala': sala_codigo,
                'url_tsj': url,
                'tipo_archivo': 'PDF',
                'fecha_scraping': datetime.now().isoformat()
            }
        
        # Es HTML, extraer datos
        soup = BeautifulSoup(contenido, 'html.parser')
        texto = soup.get_text(separator='\n', strip=True)
        
        # Extraer número
        numero_match = re.search(r'(?:Sentencia|N[°º]\.?\s*)?(\d+)', texto, re.I)
        numero = numero_match.group(1) if numero_match else ''
        
        # Extraer fecha
        fecha_match = re.search(r'(\d{1,2})[/-](\d{1,2})[/-](\d{4})', texto)
        if fecha_match:
            dia, mes, año = fecha_match.groups()
            fecha = f"{año}-{mes.zfill(2)}-{dia.zfill(2)}"
        else:
            fecha = ''
        
        # Extraer ponente
        ponente_match = re.search(r'Magistrado\s+Ponente[:\s]+([A-ZÁÉÍÓÚÑ\s\.]+)', texto, re.I)
        ponente = ponente_match.group(1).strip() if ponente_match else ''
        
        contenido_limpio = re.sub(r'\n\s*\n', '\n\n', texto)[:50000]
        
        return {
            'sala': sala_codigo,
            'numero_sentencia': numero,
            'fecha_sentencia': fecha,
            'ponente': ponente,
            'materia': 'Penal' if sala_codigo == 'SCP' else 'Constitucional',
            'url_tsj': url,
            'contenido_completo': contenido_limpio,
            'fecha_scraping': datetime.now().isoformat()
        }
        
    except Exception as e:
        print(f"      ⚠️ Error extrayendo datos: {str(e)[:50]}")
        return None

def guardar_sentencia(datos, contenido, sala_codigo):
    """Guarda sentencia en JSON y HTML"""
    try:
        numero = datos.get('numero_sentencia', 'sin_numero')
        fecha = datos.get('fecha_sentencia', 'sin_fecha').replace('-', '_')
        nombre_base = f"{sala_codigo}_{numero}_{fecha}"
        nombre_base = re.sub(r'[^a-zA-Z0-9_-]', '_', nombre_base)
        
        # Guardar JSON
        json_path = Path(CARPETA_JSONS) / f"{nombre_base}.json"
        with open(json_path, 'w', encoding='utf-8') as f:
            json.dump(datos, f, ensure_ascii=False, indent=2)
        
        # Guardar HTML/PDF
        if isinstance(contenido, str):
            html_path = Path(CARPETA_HTML) / f"{nombre_base}.html"
            with open(html_path, 'w', encoding='utf-8') as f:
                f.write(contenido)
        else:
            pdf_path = Path(CARPETA_HTML) / f"{nombre_base}.pdf"
            with open(pdf_path, 'wb') as f:
                f.write(contenido)
        
        # Firestore
        if db:
            try:
                db.collection('jurisprudencia_tsj_nuevo').document(nombre_base).set(datos)
            except:
                pass
        
        return True
        
    except Exception as e:
        print(f"      ❌ Error guardando: {str(e)[:50]}")
        return False

# ============================================
# PROCESO PRINCIPAL
# ============================================

def scrapear_sala(sala_info):
    """Scraper completo de una sala"""
    
    print(f"\n{'='*60}")
    print(f"📚 SCRAPEANDO: {sala_info['nombre']}")
    print(f"{'='*60}")
    
    progreso = cargar_progreso()
    driver = crear_driver()
    session = requests.Session()
    session.verify = False
    
    try:
        # Navegar al sitio
        print(f"🌐 Cargando {sala_info['url']}...")
        driver.get(sala_info['url'])
        
        if not esperar_carga(driver):
            print("❌ Error cargando el sitio")
            return
        
        # Filtrar por sala si es necesario
        filtrar_por_sala(driver, sala_info['codigo'])
        
        # Obtener todas las URLs navegando la paginación
        print("📄 Recopilando URLs de sentencias...")
        todas_urls = navegar_paginacion(driver, max_paginas=1000)
        
        # Eliminar duplicados
        todas_urls = list(set(todas_urls))
        
        print(f"\n📊 Total URLs únicas encontradas: {len(todas_urls)}")
        
        # Procesar cada URL
        total_procesadas = 0
        total_errores = 0
        
        for i, url in enumerate(todas_urls, 1):
            # Saltar si ya procesada
            if url in progreso["urls_procesadas"]:
                continue
            
            if i % 10 == 0:
                print(f"   📊 Procesando {i}/{len(todas_urls)}...")
            
            # Descargar
            contenido = descargar_sentencia(url, session)
            
            if not contenido:
                marcar_procesada(progreso, url)
                total_errores += 1
                continue
            
            # Extraer datos
            datos = extraer_datos_sentencia(contenido, url, sala_info['codigo'])
            
            if not datos:
                marcar_procesada(progreso, url)
                total_errores += 1
                continue
            
            # Guardar
            if guardar_sentencia(datos, contenido, sala_info['codigo']):
                total_procesadas += 1
                marcar_procesada(progreso, url)
            else:
                total_errores += 1
            
            # Pausa
            time.sleep(random.uniform(0.5, 1.5))
        
        print(f"\n{'='*60}")
        print(f"📊 RESUMEN {sala_info['nombre']}")
        print(f"{'='*60}")
        print(f"✅ Procesadas: {total_procesadas}")
        print(f"❌ Errores: {total_errores}")
        
    finally:
        driver.quit()

# ============================================
# EJECUTAR
# ============================================

print("\n🚀 INICIANDO SCRAPER DEL SITIO NUEVO")
print("=" * 60)

for codigo, info in SALAS.items():
    scrapear_sala(info)

print("\n" + "=" * 60)
print("🎉 SCRAPING COMPLETADO")
print("=" * 60)
print(f"📁 JSONs: {CARPETA_JSONS}")
print(f"📁 HTMLs: {CARPETA_HTML}")
print("=" * 60)
