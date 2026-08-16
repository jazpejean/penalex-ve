# ============================================
# SCRAPER TSJ COMPLETO - TODAS LAS SENTENCIAS
# ============================================
# Scraper que extrae TODAS las sentencias de:
# - Sala de Casación Penal (SCP)
# - Sala Constitucional (SCC)
# Desde 1999 hasta la actualidad

print("=" * 60)
print("🔥 SCRAPER TSJ COMPLETO - TODAS LAS SENTENCIAS")
print("=" * 60)
print()
print("📋 Salas a procesar:")
print("   ✓ Sala de Casación Penal (SCP)")
print("   ✓ Sala Constitucional (SCC)")
print()
print("🔄 Iniciando proceso...")
print("=" * 60)
print()

# 1. INSTALAR DEPENDENCIAS
print("📦 Instalando dependencias...")
!pip install requests beautifulsoup4 firebase-admin -q
print("✅ Dependencias instaladas")

# 2. IMPORTAR LIBRERÍAS
import json
import requests
from bs4 import BeautifulSoup
import re
from pathlib import Path
import os
import time
import random
from google.colab import drive, files
from datetime import datetime
import firebase_admin
from firebase_admin import credentials, firestore
import urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# 3. MONTAR GOOGLE DRIVE
print("🔗 Montando Google Drive...")
try:
    if not os.path.exists('/content/drive/MyDrive'):
        drive.mount('/content/drive')
    print("✅ Google Drive montado")
except:
    print("⚠️  Error montando Drive, continuando sin guardado en Drive")

# ============================================
# CONFIGURACIÓN
# ============================================

CARPETA_JSONS = "/content/drive/MyDrive/json_tsj_completo/"
CARPETA_HTML = "/content/htmls_tsj_completo"
ARCHIVO_PROGRESO = "/content/drive/MyDrive/progreso_scraper_tsj.json"
LOGO_URL = "https://historico.tsj.gob.ve/graficos/encabezadotsj.jpg"

os.makedirs(CARPETA_JSONS, exist_ok=True)
os.makedirs(CARPETA_HTML, exist_ok=True)

# Años a scrapear (desde 1999 hasta 2026)
AÑOS = list(range(1999, 2027))

MESES = {
    '01': 'enero', '02': 'febrero', '03': 'marzo', '04': 'abril',
    '05': 'mayo', '06': 'junio', '07': 'julio', '08': 'agosto',
    '09': 'septiembre', '10': 'octubre', '11': 'noviembre', '12': 'diciembre'
}

SALAS = {
    'scp': 'Sala de Casación Penal',
    'scc': 'Sala Constitucional'
}

# 🔥 CONFIGURACIÓN FIREBASE (OPCIONAL)
print("\n¿Deseas guardar en Firestore? (s/n)")
usar_firestore = input().lower() == 's'

db = None
if usar_firestore:
    print("📤 Sube el archivo firebase-credentials.json")
    uploaded = files.upload()
    cred_path = list(uploaded.keys())[0]
    
    try:
        app = firebase_admin.get_app()
        db = firestore.client()
        print("✅ Firebase reutilizado")
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
            return {"urls_procesadas": [], "total": 0, "fecha_inicio": datetime.now().isoformat()}
    return {"urls_procesadas": [], "total": 0, "fecha_inicio": datetime.now().isoformat()}

def guardar_progreso(progreso):
    try:
        progreso["ultima_actualizacion"] = datetime.now().isoformat()
        with open(ARCHIVO_PROGRESO, 'w') as f:
            json.dump(progreso, f, ensure_ascii=False, indent=2)
    except:
        pass

def marcar_procesada(progreso, url):
    if url not in progreso["urls_procesadas"]:
        progreso["urls_procesadas"].append(url)
        progreso["total"] = len(progreso["urls_procesadas"])
        guardar_progreso(progreso)

# ============================================
# FUNCIONES DE SCRAPING
# ============================================

def obtener_urls_del_indice(sala_code, año, mes_numero=None):
    """Obtiene todas las URLs de sentencias de un índice"""
    urls_encontradas = []
    
    session = requests.Session()
    session.verify = False
    
    # Construir URLs de índices posibles
    if mes_numero:
        mes_nombre = MESES.get(mes_numero, '')
        posibles_indices = [
            f"https://historico.tsj.gob.ve/decisiones/{sala_code}/{mes_nombre}/{año}/",
            f"https://historico.tsj.gob.ve/decisiones/{sala_code}/{año}/{mes_nombre}/",
            f"https://historico.tsj.gob.ve/decisiones/{sala_code}/{año}/{mes_nombre}-{año}/",
        ]
    else:
        posibles_indices = [
            f"https://historico.tsj.gob.ve/decisiones/{sala_code}/{año}/",
        ]
    
    for indice_url in posibles_indices:
        try:
            resp = session.get(indice_url, timeout=15)
            
            if resp.status_code == 200:
                soup = BeautifulSoup(resp.text, 'html.parser')
                
                # Buscar todos los enlaces a sentencias (.HTML)
                for enlace in soup.find_all('a', href=True):
                    href = enlace['href']
                    
                    # Filtrar solo enlaces a sentencias
                    if '.HTML' in href.upper() or '.htm' in href.lower():
                        # Construir URL completa
                        if href.startswith('http'):
                            url_completa = href
                        elif href.startswith('/'):
                            url_completa = f"https://historico.tsj.gob.ve{href}"
                        else:
                            url_completa = f"{indice_url.rstrip('/')}/{href}"
                        
                        if url_completa not in urls_encontradas:
                            urls_encontradas.append(url_completa)
                
                if urls_encontradas:
                    print(f"   ✅ {len(urls_encontradas)} sentencias en {indice_url}")
                    return urls_encontradas
                    
        except Exception as e:
            continue
    
    return urls_encontradas

def extraer_datos_sentencia(html, url, sala_code):
    """Extrae los datos de una sentencia desde el HTML"""
    try:
        soup = BeautifulSoup(html, 'html.parser')
        texto = soup.get_text(separator='\n', strip=True)
        
        # Extraer número de sentencia
        numero_match = re.search(r'(?:Sentencia|SENTENCIA)\s*(?:N[°º]?\.?\s*)?(\d+)', texto, re.I)
        numero = numero_match.group(1) if numero_match else ''
        
        # Extraer fecha
        fecha_match = re.search(r'(\d{1,2})\s+de\s+(\w+)\s+de\s+(\d{4})', texto, re.I)
        if fecha_match:
            dia = fecha_match.group(1).zfill(2)
            mes_texto = fecha_match.group(2).lower()
            año = fecha_match.group(3)
            
            # Convertir mes a número
            meses_rev = {v: k for k, v in MESES.items()}
            mes = meses_rev.get(mes_texto, '01')
            fecha = f"{año}-{mes}-{dia}"
        else:
            fecha = ''
        
        # Extraer ponente
        ponente_match = re.search(r'Magistrado\s+Ponente[:\s]+([A-ZÁÉÍÓÚÑ\s\.]+)', texto, re.I)
        ponente = ponente_match.group(1).strip() if ponente_match else ''
        
        # Extraer partes (buscar patrón común)
        partes = ''
        if 'recurrente' in texto.lower() or 'acusado' in texto.lower():
            partes_match = re.search(r'(?:recurrente|acusado)[:\s]+([^\n]{10,100})', texto, re.I)
            if partes_match:
                partes = partes_match.group(1).strip()
        
        # Extraer delito
        delito = ''
        delito_match = re.search(r'delito\s+de\s+([^\n]{5,50})', texto, re.I)
        if delito_match:
            delito = delito_match.group(1).strip()
        
        # Extraer contenido completo limpio
        contenido_limpio = re.sub(r'\n\s*\n', '\n\n', texto)
        contenido_limpio = re.sub(r' +', ' ', contenido_limpio)
        
        # Construir objeto JSON
        datos = {
            'sala': sala_code.upper(),
            'numero_sentencia': numero,
            'fecha_sentencia': fecha,
            'ponente': ponente,
            'tipo_sentencia': '',
            'materia': 'Penal' if sala_code == 'scp' else 'Constitucional',
            'partes': partes,
            'delito': delito,
            'decision': '',
            'resumen': '',
            'url_tsj': url,
            'contenido_completo': contenido_limpio[:50000],
            'fecha_scraping': datetime.now().isoformat(),
            'fuente': 'Scraper TSJ Directo'
        }
        
        return datos
        
    except Exception as e:
        print(f"      ⚠️ Error extrayendo datos: {str(e)[:50]}")
        return None

def descargar_sentencia(url):
    """Descarga el HTML de una sentencia"""
    try:
        session = requests.Session()
        session.verify = False
        
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        }
        
        resp = session.get(url, headers=headers, timeout=20)
        resp.raise_for_status()
        
        if len(resp.text) > 500:
            return resp.text
        
        return None
        
    except Exception as e:
        return None

def corregir_html(html):
    """Corrige el logo del HTML"""
    html = re.sub(
        r'src="[^"]*encabezadotsj\.jpg[^"]*"',
        f'src="{LOGO_URL}"',
        html,
        flags=re.I
    )
    return html

def guardar_sentencia(datos, html_corregido, sala_code):
    """Guarda la sentencia en JSON, HTML y Firestore"""
    try:
        # Crear nombre de archivo único
        numero = datos['numero_sentencia'] or 'sin_numero'
        fecha = datos['fecha_sentencia'].replace('-', '_') if datos['fecha_sentencia'] else 'sin_fecha'
        nombre_base = f"{sala_code}_{numero}_{fecha}"
        nombre_base = re.sub(r'[^a-zA-Z0-9_-]', '_', nombre_base)
        
        # 1. Guardar JSON
        json_path = Path(CARPETA_JSONS) / f"{nombre_base}.json"
        with open(json_path, 'w', encoding='utf-8') as f:
            json.dump(datos, f, ensure_ascii=False, indent=2)
        
        # 2. Guardar HTML
        html_path = Path(CARPETA_HTML) / f"{nombre_base}.html"
        with open(html_path, 'w', encoding='utf-8') as f:
            f.write(html_corregido)
        
        # 3. Guardar en Firestore (si está habilitado)
        if db:
            try:
                doc_id = nombre_base
                db.collection('jurisprudencia_tsj').document(doc_id).set(datos)
            except:
                pass
        
        return True
        
    except Exception as e:
        print(f"      ❌ Error guardando: {str(e)[:50]}")
        return False

# ============================================
# PROCESO PRINCIPAL
# ============================================

def scrapear_sala_completa(sala_code, sala_nombre):
    """Scraper completo de una sala"""
    
    print(f"\n{'='*60}")
    print(f"📚 SCRAPEANDO: {sala_nombre}")
    print(f"{'='*60}")
    
    progreso = cargar_progreso()
    total_procesadas = 0
    total_errores = 0
    
    for año in AÑOS:
        print(f"\n📅 AÑO {año}")
        
        # Intentar obtener índice anual completo
        urls = obtener_urls_del_indice(sala_code, año)
        
        # Si no hay índice anual, intentar mes por mes
        if not urls:
            for mes_num in MESES.keys():
                urls_mes = obtener_urls_del_indice(sala_code, año, mes_num)
                urls.extend(urls_mes)
                time.sleep(0.5)
        
        if not urls:
            print(f"   ⚠️ No se encontraron sentencias para {año}")
            continue
        
        print(f"   📊 Total URLs encontradas: {len(urls)}")
        
        # Procesar cada URL
        for i, url in enumerate(urls, 1):
            # Saltar si ya fue procesada
            if url in progreso["urls_procesadas"]:
                continue
            
            if i % 10 == 0:
                print(f"      Procesando {i}/{len(urls)}...")
            
            # Descargar sentencia
            html = descargar_sentencia(url)
            
            if not html:
                marcar_procesada(progreso, url)
                total_errores += 1
                continue
            
            # Extraer datos
            datos = extraer_datos_sentencia(html, url, sala_code)
            
            if not datos:
                marcar_procesada(progreso, url)
                total_errores += 1
                continue
            
            # Corregir HTML
            html_corregido = corregir_html(html)
            
            # Guardar
            if guardar_sentencia(datos, html_corregido, sala_code):
                total_procesadas += 1
                marcar_procesada(progreso, url)
            else:
                total_errores += 1
            
            # Pausa para no saturar el servidor
            time.sleep(random.uniform(0.5, 1.5))
        
        print(f"   ✅ {año} completado")
    
    print(f"\n{'='*60}")
    print(f"📊 RESUMEN {sala_nombre}")
    print(f"{'='*60}")
    print(f"✅ Procesadas: {total_procesadas}")
    print(f"❌ Errores: {total_errores}")
    print(f"📁 JSONs: {CARPETA_JSONS}")
    print(f"📁 HTMLs: {CARPETA_HTML}")

# ============================================
# EJECUTAR SCRAPER
# ============================================

print("\n🚀 INICIANDO SCRAPER COMPLETO DEL TSJ")
print("=" * 60)

for sala_code, sala_nombre in SALAS.items():
    scrapear_sala_completa(sala_code, sala_nombre)

print("\n" + "=" * 60)
print("🎉 SCRAPING COMPLETADO")
print("=" * 60)
print(f"📁 Archivos guardados en:")
print(f"   - JSONs: {CARPETA_JSONS}")
print(f"   - HTMLs: {CARPETA_HTML}")
if db:
    print(f"   - Firestore: Colección 'jurisprudencia_tsj'")
print("=" * 60)
