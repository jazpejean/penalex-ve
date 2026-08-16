# ============================================
# EXTRACTOR TSJ COMPLETO - V2.0
# ============================================
# Mejoras:
# - Crea ficha completa con toda la info
# - Busca en Google las sentencias sin URL
# - Guarda contenido en Firestore
# - Publica HTML en Firebase Hosting

# ============================================
# IMPORTANTE: ANTES DE EJECUTAR
# ============================================
# 1. Asegúrate de estar en una sesión de Colab CON CUENTA DE GOOGLE
# 2. Cuando pida permisos para Drive, acepta TODOS
# 3. Si falla el montaje de Drive:
#    - Runtime → Restart runtime
#    - Ejecuta de nuevo desde el inicio

print("=" * 60)
print("🚀 EXTRACTOR TSJ COMPLETO V2.0")
print("=" * 60)
print()
print("📋 Requisitos:")
print("   ✓ Cuenta de Google activa")
print("   ✓ Archivos JSON en Google Drive")
print("   ✓ Credenciales de Firebase")
print()
print("🔄 Iniciando proceso...")
print("=" * 60)
print()

# 1. INSTALAR DEPENDENCIAS
print("📦 Instalando dependencias...")
!pip install requests beautifulsoup4 firebase-admin googlesearch-python -q
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
from googlesearch import search

# 3. MONTAR GOOGLE DRIVE CON MÚLTIPLES REINTENTOS
print("🔗 Montando Google Drive...")

def montar_drive_con_reintentos(max_intentos=3):
    """Monta Drive con reintentos automáticos"""
    for intento in range(1, max_intentos + 1):
        try:
            # Verificar si ya está montado
            if os.path.exists('/content/drive/MyDrive'):
                print("✅ Google Drive ya estaba montado")
                return True
            
            # Intentar montar
            print(f"   Intento {intento}/{max_intentos}...")
            drive.mount('/content/drive', force_remount=(intento > 1))
            
            # Verificar montaje exitoso
            if os.path.exists('/content/drive/MyDrive'):
                print("✅ Google Drive montado correctamente")
                return True
            else:
                print(f"   ⚠️ Montaje incompleto, reintentando...")
                time.sleep(2)
                
        except Exception as e:
            if intento < max_intentos:
                print(f"   ⚠️ Fallo en intento {intento}: {str(e)[:50]}...")
                print(f"   🔄 Reintentando en 3 segundos...")
                time.sleep(3)
            else:
                print(f"\n❌ ERROR: No se pudo montar Google Drive después de {max_intentos} intentos")
                print("\n💡 SOLUCIONES:")
                print("   1. Runtime → Restart runtime")
                print("   2. Ejecuta solo la celda de montaje")
                print("   3. Autoriza cuando aparezca el popup")
                print("   4. Cierra sesión de Google y vuelve a entrar")
                return False
    
    return False

# Intentar montar Drive
if not montar_drive_con_reintentos():
    raise SystemExit("❌ No se pudo montar Google Drive")

# Verificar carpeta JSON
print("\n🔍 Verificando carpeta de JSONs...")
if not os.path.exists('/content/drive/MyDrive/json'):
    print()
    print("⚠️  CARPETA 'json' NO ENCONTRADA")
    print()
    print("📋 CREANDO ESTRUCTURA...")
    os.makedirs('/content/drive/MyDrive/json', exist_ok=True)
    print("✅ Carpeta 'json' creada en Drive")
    print()
    print("📤 ACCIÓN REQUERIDA:")
    print("   1. Abre tu Google Drive")
    print("   2. Ve a la carpeta 'json'")
    print("   3. Sube tus archivos JSON de sentencias")
    print("   4. Ejecuta este script de nuevo")
    print()
    raise SystemExit("⏸️ Esperando archivos JSON...")

# Contar archivos JSON
json_count = len([f for f in os.listdir('/content/drive/MyDrive/json') if f.endswith('.json')])

if json_count == 0:
    print("⚠️  La carpeta 'json' está vacía")
    print()
    print("📤 Sube archivos JSON de sentencias a:")
    print("   Google Drive → json/")
    print()
    raise SystemExit("⏸️ No hay archivos para procesar")

print(f"✅ {json_count} archivos JSON encontrados")

# ============================================
# CONFIGURACIÓN
# ============================================

RUTA_JSONS = "/content/drive/MyDrive/json/"
CARPETA_HTML = "/content/htmls_tsj"
ARCHIVO_PROGRESO = "/content/drive/MyDrive/progreso_tsj.json"

os.makedirs(CARPETA_HTML, exist_ok=True)

# 🔥 CONFIGURACIÓN FIREBASE
FIREBASE_TOKEN = "1//056NFsh7FbdMzCgYIARAAGAUSNwF-L9IrvBPDBp1dxA5XGYDUH7jaCu2tCwDn2dpMKV3Wsii_c0ucX-2nZ1IveOlWr8LrYBvA2Tw"
LOGO_URL = "https://historico.tsj.gob.ve/graficos/encabezadotsj.jpg"

# 📤 SUBIR ARCHIVO DE CREDENCIALES FIREBASE
print("📤 Sube el archivo firebase-credentials.json")
uploaded = files.upload()
cred_path = list(uploaded.keys())[0]

# Inicializar Firebase Admin (verificar si ya existe)
try:
    # Intentar obtener la app existente
    app = firebase_admin.get_app()
    print("✅ Firebase ya estaba inicializado, reutilizando conexión")
    db = firestore.client()
except ValueError:
    # No existe, inicializar nueva app
    cred = credentials.Certificate(cred_path)
    firebase_admin.initialize_app(cred)
    db = firestore.client()
    print("✅ Firestore conectado (nueva conexión)")

# ============================================
# SISTEMA DE PROGRESO INTELIGENTE
# ============================================

def cargar_progreso():
    """Carga progreso existente o inicia desde cero"""
    if os.path.exists(ARCHIVO_PROGRESO):
        try:
            with open(ARCHIVO_PROGRESO, 'r', encoding='utf-8') as f:
                progreso = json.load(f)
                print(f"� Progreso previo encontrado: {len(progreso.get('procesados', []))} sentencias procesadas")
                return progreso
        except:
            print("⚠️  Archivo de progreso corrupto, iniciando desde cero")
            return {"procesados": [], "ultimo": None, "total_procesados": 0, "fecha_inicio": datetime.now().isoformat()}
    else:
        print("🆕 Primera ejecución: iniciando desde cero")
        return {"procesados": [], "ultimo": None, "total_procesados": 0, "fecha_inicio": datetime.now().isoformat()}

def guardar_progreso(progreso):
    """Guarda progreso con backup automático"""
    try:
        # Actualizar timestamp
        progreso["ultima_actualizacion"] = datetime.now().isoformat()
        
        # Guardar principal
        with open(ARCHIVO_PROGRESO, 'w', encoding='utf-8') as f:
            json.dump(progreso, f, ensure_ascii=False, indent=2)
        
        # Backup cada 10 sentencias
        if len(progreso.get("procesados", [])) % 10 == 0:
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            backup_path = ARCHIVO_PROGRESO.replace('.json', f'_backup_{timestamp}.json')
            with open(backup_path, 'w', encoding='utf-8') as f:
                json.dump(progreso, f, ensure_ascii=False, indent=2)
            
    except Exception as e:
        print(f"⚠️  Error guardando progreso: {e}")

def marcar_como_procesado(progreso, nombre_archivo, exitoso=True):
    """Marca un archivo como procesado"""
    if nombre_archivo not in progreso["procesados"]:
        progreso["procesados"].append(nombre_archivo)
        progreso["ultimo"] = nombre_archivo
        progreso["total_procesados"] = len(progreso["procesados"])
        
        # Estadísticas
        if "exitosos" not in progreso:
            progreso["exitosos"] = 0
        if "fallidos" not in progreso:
            progreso["fallidos"] = 0
            
        if exitoso:
            progreso["exitosos"] += 1
        else:
            progreso["fallidos"] += 1
        
        guardar_progreso(progreso)

def obtener_pendientes(json_files, progreso):
    """Devuelve archivos pendientes (no procesados)"""
    procesados = set(progreso.get("procesados", []))
    pendientes = [f for f in json_files if f.name not in procesados]
    return pendientes

def mostrar_estadisticas(json_files, progreso, es_resumen_final=False):
    """Muestra estadísticas del progreso"""
    total = len(json_files)
    procesados = len(progreso.get("procesados", []))
    pendientes = total - procesados
    porcentaje = (procesados / total * 100) if total > 0 else 0
    exitosos = progreso.get("exitosos", 0)
    fallidos = progreso.get("fallidos", 0)

    print("\n" + "=" * 60)
    if es_resumen_final:
        print("📊 RESUMEN FINAL")
    else:
        print("📊 ESTADÍSTICAS DE PROGRESO")
    print("=" * 60)
    print(f"📁 Total de sentencias: {total}")
    print(f"✅ Procesadas: {procesados} ({porcentaje:.1f}%)")
    print(f"   ├─ Exitosas: {exitosos}")
    print(f"   └─ Fallidas: {fallidos}")
    print(f"⏳ Pendientes: {pendientes}")
    
    if progreso.get("ultimo"):
        print(f"� Último procesado: {progreso['ultimo']}")
    
    if progreso.get("fecha_inicio"):
        print(f"🕐 Inicio: {progreso['fecha_inicio'][:19]}")
    
    if progreso.get("ultima_actualizacion"):
        print(f"� Última actualización: {progreso['ultima_actualizacion'][:19]}")
    
    print("=" * 60)

# ============================================
# BÚSQUEDA EN GOOGLE
# ============================================

def buscar_sentencia_en_tsj_directo(data):
    """Busca directamente en los índices del TSJ sin usar Google"""
    try:
        sala = data.get('sala', '').strip()
        numero = data.get('numero_sentencia', '').strip()
        fecha = data.get('fecha_sentencia', '').strip()
        
        if not (sala and numero and fecha):
            return None
        
        # Extraer año y mes de la fecha
        try:
            año = fecha.split('-')[0]
            mes = fecha.split('-')[1]
            meses = ['', 'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
                    'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre']
            mes_nombre = meses[int(mes)]
        except:
            año = ''
            mes_nombre = ''
        
        # Mapeo de salas a códigos del TSJ
        sala_codes = {
            'SCP': 'scp',
            'SCC': 'scc', 
            'SC': 'sc',
            'SPA': 'spa',
            'SCPP': 'scpp',
            'CSJ': 'csj',
            'PENAL': 'scp',
            'CONSTITUCIONAL': 'scc',
            'POLÍTICO': 'spa'
        }
        
        sala_code = sala_codes.get(sala.upper(), sala.lower())
        
        # ESTRATEGIA 1: Patrones comunes de URL del TSJ
        patrones_url = [
            f"https://historico.tsj.gob.ve/decisiones/{sala_code}/{mes_nombre}/{año}/{numero}.HTML",
            f"https://historico.tsj.gob.ve/decisiones/{sala_code}/{año}/{mes_nombre}-{año}/{numero}.HTML",
            f"https://historico.tsj.gob.ve/decisiones/{sala_code}/{año}/{numero}.HTML",
            f"https://historico.tsj.gob.ve/decisiones/{sala_code}/{mes_nombre}/{año}/RC-{numero}.HTML",
            f"https://historico.tsj.gob.ve/decisiones/{sala_code}/{mes_nombre}/{año}/rc{numero}.HTML",
            f"https://historico.tsj.gob.ve/decisiones/{sala_code}/{año}/rc{numero}.HTML",
        ]
        
        print(f"   🔍 Buscando en TSJ directo ({sala_code}, {mes_nombre}/{año}, #{numero})")
        
        session = requests.Session()
        session.verify = False
        
        for i, url_test in enumerate(patrones_url, 1):
            try:
                # Verificar si existe la URL
                resp = session.head(url_test, timeout=5, allow_redirects=True)
                
                if resp.status_code == 200:
                    print(f"   ✅ ENCONTRADO (patrón {i}): {url_test}")
                    return url_test
                    
            except:
                continue
        
        # ESTRATEGIA 2: Buscar en el índice de la sala específica
        try:
            indice_url = f"https://historico.tsj.gob.ve/decisiones/{sala_code}/{año}/"
            resp = session.get(indice_url, timeout=10)
            
            if resp.status_code == 200:
                # Buscar enlaces que contengan el número de sentencia
                soup = BeautifulSoup(resp.text, 'html.parser')
                enlaces = soup.find_all('a', href=True)
                
                for enlace in enlaces:
                    href = enlace['href']
                    if numero in href or numero in enlace.get_text():
                        url_completa = f"https://historico.tsj.gob.ve{href}" if href.startswith('/') else href
                        print(f"   ✅ ENCONTRADO en índice: {url_completa}")
                        return url_completa
        except:
            pass
        
        print(f"   ❌ No encontrado en TSJ directo")
        return None
        
    except Exception as e:
        print(f"   ⚠️ Error en búsqueda TSJ: {str(e)[:50]}")
        return None


def buscar_sentencia_en_google(data, max_intentos=3):
    """Busca la sentencia - PRIMERO TSJ DIRECTO, luego Google"""
    
    # PRIMERO: Intentar búsqueda directa en TSJ (más rápido y confiable)
    url_tsj = buscar_sentencia_en_tsj_directo(data)
    if url_tsj:
        return url_tsj
    
    # SEGUNDO: Búsqueda en Google como respaldo
    try:
        sala = data.get('sala', '').strip()
        numero = data.get('numero_sentencia', '').strip()
        fecha = data.get('fecha_sentencia', '').strip()
        
        # Búsqueda con requests directamente (sin googlesearch)
        try:
            print(f"   🔍 Buscando en Google...")
            search_url = f"https://www.google.com/search?q=site:historico.tsj.gob.ve+{sala}+sentencia+{numero}"
            
            headers = {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            }
            
            resp = requests.get(search_url, headers=headers, timeout=10)
            
            if resp.status_code == 200:
                # Buscar URLs en el HTML de resultados
                urls_encontradas = re.findall(r'https://historico\.tsj\.gob\.ve/decisiones/[^"<>\s&]+', resp.text)
                
                for url in urls_encontradas:
                    if '/decisiones/' in url and '.HTML' in url.upper():
                        print(f"   ✅ ENCONTRADO en Google: {url}")
                        return url
        except Exception as e:
            print(f"   ⚠️ Google falló: {str(e)[:30]}")
        
        print("   ❌ NO ENCONTRADO")
        return None
        
    except Exception as e:
        print(f"   ❌ Error: {e}")
        return None

# ============================================
# EXTRACCIÓN Y CORRECCIÓN HTML
# ============================================

def extraer_sala_del_html(html):
    try:
        soup = BeautifulSoup(html, 'html.parser')
        texto = soup.get_text(separator='\n', strip=True)
        
        match = re.search(r'(?:SALA|EN SALA)\s*([A-ZÁÉÍÓÚÑ\s]+)', texto, re.I)
        if match:
            sala = match.group(1).strip()
            sala = re.sub(r'\s+', ' ', sala).strip()
            return sala
        
        return "Sala Desconocida"
    except:
        return "Sala Desconocida"

def extraer_contenido_texto(html):
    """Extrae el texto limpio de la sentencia para Firestore"""
    try:
        soup = BeautifulSoup(html, 'html.parser')
        
        # Remover scripts y estilos
        for script in soup(["script", "style"]):
            script.decompose()
        
        texto = soup.get_text(separator='\n', strip=True)
        
        # Limpiar texto
        texto = re.sub(r'\n\s*\n', '\n\n', texto)
        texto = re.sub(r' +', ' ', texto)
        
        return texto.strip()
    except:
        return ""

def corregir_html(html, sala_nombre):
    # 1. Corregir logo
    html = re.sub(
        r'src="[^"]*encabezadotsj\.jpg[^"]*"',
        f'src="{LOGO_URL}"',
        html,
        flags=re.I
    )
    
    # 2. Corregir sala
    patron_sala = r'(<p class="MsoNormal"[^>]*>\s*<b[^>]*><span[^>]*>SALA DE</span></b><b[^>]*><span[^>]*>)\s*([A-ZÁÉÍÓÚÑ\s]+)(</span></b>\s*</p>)'
    
    if re.search(patron_sala, html, re.I):
        html = re.sub(patron_sala, rf'\g<1> {sala_nombre}\g<3>', html, flags=re.I | re.DOTALL)
    
    return html

def descargar_html(url):
    """Descarga HTML con reintentos"""
    max_intentos = 3
    
    for intento in range(1, max_intentos + 1):
        try:
            session = requests.Session()
            headers = {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            }
            
            # Establecer sesión
            session.get('https://historico.tsj.gob.ve', headers=headers, verify=False, timeout=30)
            time.sleep(1)
            
            # Descargar HTML
            resp = session.get(url, headers=headers, verify=False, timeout=30)
            resp.raise_for_status()
            
            # Verificar que sea HTML válido
            if len(resp.text) < 500:
                raise Exception("HTML muy corto, posiblemente inválido")
            
            return resp.text
            
        except Exception as e:
            print(f"   ⚠️  Intento {intento}/{max_intentos} fallido: {e}")
            if intento < max_intentos:
                time.sleep(3)
            else:
                print(f"   ❌ Fallo definitivo descargando HTML")
                return None

# ============================================
# CREAR FICHA HTML COMPLETA
# ============================================

def crear_ficha_html(data, url_tsj, nombre_archivo_html_original):
    """Crea una ficha HTML completa con toda la información"""
    
    # Extraer datos del JSON
    sala = data.get('sala', 'N/A')
    numero = data.get('numero_sentencia', 'N/A')
    fecha = data.get('fecha_sentencia', 'N/A')
    ponente = data.get('ponente', 'N/A')
    tipo = data.get('tipo_sentencia', 'N/A')
    partes = data.get('partes', 'N/A')
    delito = data.get('delito', 'N/A')
    materia = data.get('materia', 'N/A')
    decision = data.get('decision', 'N/A')
    resumen = data.get('resumen', 'N/A')
    
    # URL del HTML original publicado en Firebase Hosting
    url_html_completo = f"https://penalex-ve.web.app/{nombre_archivo_html_original}"
    
    html = f"""<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Sentencia {numero} - {sala}</title>
    <style>
        body {{
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            max-width: 900px;
            margin: 40px auto;
            padding: 20px;
            background: #f5f5f5;
        }}
        .ficha {{
            background: white;
            border-radius: 8px;
            padding: 30px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }}
        h1 {{
            color: #1a237e;
            border-bottom: 3px solid #1a237e;
            padding-bottom: 10px;
        }}
        .metadata {{
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 15px;
            margin: 20px 0;
        }}
        .campo {{
            padding: 10px;
            background: #f9f9f9;
            border-left: 4px solid #1a237e;
        }}
        .label {{
            font-weight: bold;
            color: #555;
            font-size: 0.9em;
        }}
        .valor {{
            margin-top: 5px;
            color: #222;
        }}
        .resumen {{
            background: #e3f2fd;
            padding: 20px;
            border-radius: 5px;
            margin: 20px 0;
        }}
        .enlaces {{
            display: flex;
            gap: 15px;
            margin: 30px 0;
        }}
        .btn {{
            flex: 1;
            padding: 12px 20px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            text-decoration: none;
            text-align: center;
            font-weight: bold;
            display: inline-block;
        }}
        .btn-ver {{
            background: #4caf50;
            color: white;
        }}
        .btn-ver:hover {{
            background: #45a049;
        }}
        .btn-tsj {{
            background: #1976d2;
            color: white;
        }}
        .btn-tsj:hover {{
            background: #1565c0;
        }}
        .footer {{
            text-align: center;
            margin-top: 40px;
            padding-top: 20px;
            border-top: 1px solid #ddd;
            color: #777;
            font-size: 0.9em;
        }}
    </style>
</head>
<body>
    <div class="ficha">
        <h1>📜 Sentencia del Tribunal Supremo de Justicia</h1>
        
        <div class="metadata">
            <div class="campo">
                <div class="label">Sala</div>
                <div class="valor">{sala}</div>
            </div>
            
            <div class="campo">
                <div class="label">Número de Sentencia</div>
                <div class="valor">{numero}</div>
            </div>
            
            <div class="campo">
                <div class="label">Fecha</div>
                <div class="valor">{fecha}</div>
            </div>
            
            <div class="campo">
                <div class="label">Ponente</div>
                <div class="valor">{ponente}</div>
            </div>
            
            <div class="campo">
                <div class="label">Tipo de Sentencia</div>
                <div class="valor">{tipo}</div>
            </div>
            
            <div class="campo">
                <div class="label">Materia</div>
                <div class="valor">{materia}</div>
            </div>
        </div>
        
        <div class="campo" style="margin: 20px 0;">
            <div class="label">Partes</div>
            <div class="valor">{partes}</div>
        </div>
        
        <div class="campo" style="margin: 20px 0;">
            <div class="label">Delito</div>
            <div class="valor">{delito}</div>
        </div>
        
        <div class="campo" style="margin: 20px 0;">
            <div class="label">Decisión</div>
            <div class="valor">{decision}</div>
        </div>
        
        <div class="resumen">
            <div class="label">📋 Resumen</div>
            <div class="valor" style="margin-top: 10px;">{resumen}</div>
        </div>
        
        <div class="enlaces">
            <a href="{url_html_completo}" class="btn btn-ver" target="_blank">
                📄 Ver Sentencia Completa
            </a>
            <a href="{url_tsj}" class="btn btn-tsj" target="_blank">
                🔗 Fuente Original TSJ
            </a>
        </div>
        
        <div class="footer">
            <p><strong>PenalexVE</strong> - Dosimetría Penal Venezolana</p>
            <p>Circuito Judicial Penal Los Teques</p>
        </div>
    </div>
</body>
</html>"""
    
    return html

# ============================================
# GUARDAR EN FIRESTORE
# ============================================

def guardar_en_firestore(data, url_tsj, contenido_texto, url_html):
    """Guarda la sentencia en Firestore"""
    try:
        # ID único para la sentencia - USAR NOMBRE DEL ARCHIVO JSON
        # Esto garantiza que cada JSON tenga su propio documento
        nombre_archivo = data.get('_nombre_archivo', 'desconocido')
        if nombre_archivo == 'desconocido':
            # Fallback: construir ID desde los datos
            doc_id = f"{data.get('sala', 'X')}_{data.get('numero_sentencia', '0')}_{data.get('fecha_sentencia', 'sin_fecha')}"
            doc_id = re.sub(r'[^a-zA-Z0-9_-]', '_', doc_id)
        else:
            # Usar el nombre del archivo JSON sin extensión como ID único
            doc_id = nombre_archivo.replace('.json', '').replace('.', '_')
        
        # Documento para Firestore
        documento = {
            # Metadatos básicos
            'sala': data.get('sala', ''),
            'numero_sentencia': data.get('numero_sentencia', ''),
            'fecha_sentencia': data.get('fecha_sentencia', ''),
            'ponente': data.get('ponente', ''),
            'tipo_sentencia': data.get('tipo_sentencia', ''),
            'materia': data.get('materia', ''),
            
            # Información del caso
            'partes': data.get('partes', ''),
            'delito': data.get('delito', ''),
            'decision': data.get('decision', ''),
            'resumen': data.get('resumen', ''),
            
            # URLs
            'url_tsj_original': url_tsj,
            'url_ficha_penalex': url_html,
            
            # Contenido completo para IAs
            'contenido_completo': contenido_texto[:50000],  # Limitar a 50k caracteres
            
            # Metadata
            'fecha_indexacion': firestore.SERVER_TIMESTAMP,
            'fuente': 'TSJ Venezuela',
            'indexado_por': 'PenalexVE Scraper v2.0',
            'archivo_json_origen': nombre_archivo
        }
        
        # Guardar en Firestore
        db.collection('jurisprudencia').document(doc_id).set(documento)
        
        print(f"   💾 Guardado en Firestore: {doc_id}")
        return True
        
    except Exception as e:
        print(f"   ❌ Error guardando en Firestore: {e}")
        return False

# ============================================
# PROCESAR JSON
# ============================================

def procesar_json(ruta_json, progreso):
    """Procesa un JSON completo - BUSCA EN GOOGLE SI NO HAY URL"""
    
    try:
        with open(ruta_json, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except Exception as e:
        print(f"   ❌ Error leyendo JSON: {e}")
        return None
    
    # Guardar nombre del archivo en data para Firestore
    data['_nombre_archivo'] = ruta_json.name
    
    print(f"\n📄 {ruta_json.name}")
    
    # 1. Obtener URL del TSJ
    url_tsj = data.get('url_tsj') or ''
    url_tsj = url_tsj.strip() if url_tsj else ''
    html_original = None
    url_origen = None
    
    # ESTRATEGIA 1: Probar URL existente
    if url_tsj:
        print(f"   🔗 Probando URL del JSON...")
        html_original = descargar_html(url_tsj)
        if html_original:
            url_origen = "JSON original"
            print(f"   ✅ URL del JSON funciona")
    
    # ESTRATEGIA 2: Búsqueda obligatoria en Google si falla o no existe URL
    if not html_original:
        if url_tsj:
            print("   ⚠️  URL del JSON no funciona")
        else:
            print("   ⚠️  Sin url_tsj en JSON")
        
        print("   🔍 INICIANDO BÚSQUEDA EN GOOGLE (OBLIGATORIA)...")
        url_google = buscar_sentencia_en_google(data)
        
        if url_google:
            print(f"   🎯 Probando URL de Google...")
            html_original = descargar_html(url_google)
            
            if html_original:
                url_tsj = url_google
                url_origen = "Google Search"
                
                # Actualizar JSON con URL encontrada
                data['url_tsj'] = url_google
                data['url_origen'] = 'google_search'
                data['url_original_fallida'] = url_tsj if url_tsj else 'sin_url'
                
                try:
                    with open(ruta_json, 'w', encoding='utf-8') as f:
                        json.dump(data, f, ensure_ascii=False, indent=2)
                    print(f"   💾 JSON actualizado con URL de Google")
                except:
                    pass
    
    # ESTRATEGIA 3: Si aún no hay HTML, registrar y continuar
    if not html_original:
        print(f"   ❌ SENTENCIA NO DISPONIBLE - Sin acceso al HTML")
        print(f"      Sala: {data.get('sala', 'N/A')}")
        print(f"      Número: {data.get('numero_sentencia', 'N/A')}")
        print(f"      Fecha: {data.get('fecha_sentencia', 'N/A')}")
        
        # Crear registro en Firestore como "no disponible"
        try:
            # Usar nombre del archivo como ID único
            doc_id = f"NO_DISPONIBLE_{ruta_json.stem}"
            
            db.collection('jurisprudencia_no_disponible').document(doc_id).set({
                'sala': data.get('sala', ''),
                'numero_sentencia': data.get('numero_sentencia', ''),
                'fecha_sentencia': data.get('fecha_sentencia', ''),
                'motivo': 'HTML no accesible desde TSJ ni Google',
                'fecha_intento': firestore.SERVER_TIMESTAMP,
                'url_intentada': url_tsj if url_tsj else 'ninguna',
                'archivo_json_origen': ruta_json.name
            })
            print(f"   📝 Registrado en colección 'no_disponible'")
        except:
            pass
        
        marcar_como_procesado(progreso, ruta_json.name, exitoso=False)
        return None
    
    # 3. PROCESAR HTML EXITOSAMENTE OBTENIDO
    print(f"   ✅ HTML obtenido desde: {url_origen}")
    
    # Extraer sala y contenido
    sala_nombre = data.get('sala') or extraer_sala_del_html(html_original)
    contenido_texto = extraer_contenido_texto(html_original)
    print(f"   📝 Sala: {sala_nombre}")
    print(f"   📄 Contenido: {len(contenido_texto)} caracteres")
    
    # 4. Corregir HTML original
    html_corregido = corregir_html(html_original, sala_nombre)
    
    # 5. Guardar HTML original corregido
    nombre_base = Path(ruta_json).stem
    nombre_html_original = f"{nombre_base}.html"
    ruta_html_original = Path(CARPETA_HTML) / nombre_html_original
    
    with open(ruta_html_original, 'w', encoding='utf-8') as f:
        f.write(html_corregido)
    
    # 6. Crear ficha HTML completa
    nombre_html_ficha = f"{nombre_base}_ficha.html"
    url_html_publicado = f"https://penalex-ve.web.app/{nombre_html_ficha}"
    
    ficha_html = crear_ficha_html(data, url_tsj, nombre_html_original)
    
    ruta_html_ficha = Path(CARPETA_HTML) / nombre_html_ficha
    with open(ruta_html_ficha, 'w', encoding='utf-8') as f:
        f.write(ficha_html)
    
    print(f"   ✅ Sentencia completa: {nombre_html_original}")
    print(f"   ✅ Ficha: {nombre_html_ficha}")
    
    # 7. Guardar en Firestore
    guardar_en_firestore(data, url_tsj, contenido_texto, url_html_publicado)
    
    # 8. Marcar como procesado EXITOSAMENTE
    marcar_como_procesado(progreso, ruta_json.name, exitoso=True)
    
    return ruta_html_ficha

# ============================================
# CREAR INDEX.HTML
# ============================================

def crear_index_html():
    """Crea index con fichas (no originales)"""
    archivos = list(Path(CARPETA_HTML).glob("*.html"))
    archivos = [f for f in archivos if f.name != "index.html" and not f.name.endswith("_original.html")]
    
    html = """<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PenalexVE - Jurisprudencia del TSJ</title>
    <style>
        body {
            font-family: 'Segoe UI', sans-serif;
            margin: 0;
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            border-radius: 10px;
            padding: 40px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
        }
        h1 {
            color: #1a237e;
            text-align: center;
            margin-bottom: 10px;
        }
        .stats {
            text-align: center;
            color: #666;
            margin-bottom: 30px;
        }
        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
            gap: 20px;
        }
        .card {
            background: #f9f9f9;
            padding: 20px;
            border-radius: 8px;
            border-left: 4px solid #1976d2;
            transition: transform 0.2s, box-shadow 0.2s;
        }
        .card:hover {
            transform: translateY(-5px);
            box-shadow: 0 5px 20px rgba(0,0,0,0.15);
        }
        .card a {
            text-decoration: none;
            color: #1976d2;
            font-weight: bold;
            display: block;
        }
        .card a:hover {
            color: #0d47a1;
        }
        .footer {
            text-align: center;
            margin-top: 40px;
            padding-top: 20px;
            border-top: 2px solid #ddd;
            color: #777;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>⚖️ PenalexVE - Jurisprudencia del TSJ</h1>
        <div class="stats">
            <p><strong>""" + str(len(archivos)) + """</strong> sentencias disponibles</p>
        </div>
        
        <div class="grid">
"""
    
    for archivo in sorted(archivos):
        nombre = archivo.stem.replace('_', ' ').title()
        html += f"""            <div class="card">
                <a href="{archivo.name}">📜 {nombre}</a>
            </div>
"""
    
    html += """        </div>
        
        <div class="footer">
            <p><strong>PenalexVE</strong> - Dosimetría Penal Venezolana</p>
            <p>Circuito Judicial Penal Los Teques</p>
        </div>
    </div>
</body>
</html>"""
    
    ruta_index = Path(CARPETA_HTML) / "index.html"
    with open(ruta_index, 'w', encoding='utf-8') as f:
        f.write(html)
    
    print(f"\n✅ index.html creado con {len(archivos)} fichas")

# ============================================
# SUBIR A FIREBASE
# ============================================

def subir_a_firebase():
    print("\n🚀 SUBIENDO A FIREBASE HOSTING...")
    
    archivos = list(Path(CARPETA_HTML).glob("*.html"))
    if not archivos:
        print("❌ No hay archivos para subir")
        return False
    
    print(f"📁 Subiendo {len(archivos)} archivos...")
    
    !npm install -g firebase-tools > /dev/null 2>&1
    
    with open('/content/firebase.json', 'w') as f:
        f.write('{"hosting":{"public":"/content/htmls_tsj","ignore":["firebase.json","**/.*"]}}')
    
    !firebase deploy --only hosting --project penalex-ve --token {FIREBASE_TOKEN}
    
    return True

# ============================================
# MAIN
# ============================================

print("🚀 EXTRACTOR TSJ COMPLETO V2.0 - DESDE CERO")
print("=" * 60)

json_files = list(Path(RUTA_JSONS).glob("*.json"))
print(f"📁 Total JSONs encontrados: {len(json_files)}")

if not json_files:
    print("❌ No hay archivos JSON en la carpeta")
    raise SystemExit

# Cargar progreso (siempre vacío - inicia desde cero)
progreso = cargar_progreso()
mostrar_estadisticas(json_files, progreso)

# Obtener TODOS los archivos (ignora progreso previo)
pendientes = obtener_pendientes(json_files, progreso)

print("\n" + "=" * 60)
print("⚠️  MODO: PROCESAMIENTO COMPLETO DESDE CERO")
print("=" * 60)
print(f"📋 Se procesarán TODOS los {len(pendientes)} archivos JSON")
print("🔍 Búsqueda en Google ACTIVADA para sentencias sin URL")
print("💾 Todos los resultados se guardarán en Firestore")
print("=" * 60)

respuesta = input("\n¿Continuar con el procesamiento completo? (s/n): ")
if respuesta.lower() != 's':
    print("❌ Cancelado por el usuario")
    raise SystemExit

print("\n� INICIANDO PROCESAMIENTO COMPLETO...")
print("=" * 60)

# Definir archivos a procesar
print(f"\n📋 Opciones de procesamiento:")
print(f"   1 = Procesar SOLO pendientes ({len(pendientes)})")
print(f"   2 = Reprocesar las {len(progreso.get('procesados', []))} ya procesadas (para Firestore)")
print(f"   3 = Procesar TODAS desde cero (borrar progreso)")

try:
    opcion = int(input("   Selecciona opción: "))
except:
    opcion = 1

if opcion == 2:
    # Reprocesar las que ya se procesaron (para subirlas a Firestore)
    print(f"\n🔄 REPROCESANDO {len(progreso.get('procesados', []))} sentencias para Firestore...")
    procesados_nombres = set(progreso.get('procesados', []))
    archivos_a_procesar = [f for f in json_files if f.name in procesados_nombres]
    # No marcar como procesados de nuevo, solo actualizar Firestore
elif opcion == 3:
    # Borrar progreso y procesar todo
    if os.path.exists(ARCHIVO_PROGRESO):
        os.remove(ARCHIVO_PROGRESO)
        print("✅ Progreso eliminado")
    progreso = cargar_progreso()
    pendientes = obtener_pendientes(json_files, progreso)
    archivos_a_procesar = pendientes[:1000] if len(pendientes) > 1000 else pendientes
else:
    # Procesar solo pendientes (opción por defecto)
    archivos_a_procesar = pendientes[:1000] if len(pendientes) > 1000 else pendientes

print(f"📊 Se procesarán {len(archivos_a_procesar)} sentencias")

total_exitosos = 0
total_fallidos = 0
inicio_tiempo = time.time()

for i, json_file in enumerate(archivos_a_procesar, 1):
    porcentaje = (i / len(archivos_a_procesar)) * 100
    print(f"\n📊 [{i}/{len(archivos_a_procesar)}] - {porcentaje:.1f}%")
    
    resultado = procesar_json(json_file, progreso)
    
    if resultado:
        total_exitosos += 1
    else:
        total_fallidos += 1
    
    # Mostrar progreso cada 5 sentencias
    if i % 5 == 0:
        print(f"\n   📈 Progreso parcial: {total_exitosos} exitosas, {total_fallidos} fallidas")
    
    # Pausa entre requests para evitar bloqueos
    if i < len(archivos_a_procesar):
        pausa = random.uniform(3, 6)
        time.sleep(pausa)

tiempo_total = time.time() - inicio_tiempo

# RESUMEN FINAL DE ESTA EJECUCIÓN
print("\n" + "=" * 60)
print("🎉 EJECUCIÓN COMPLETADA")
print("=" * 60)
print(f"✅ Exitosas en esta ejecución: {total_exitosos}")
print(f"❌ Fallidas en esta ejecución: {total_fallidos}")
print(f"⏱️  Tiempo total: {tiempo_total/60:.2f} minutos")
if len(archivos_a_procesar) > 0:
    print(f"⚡ Promedio: {tiempo_total/len(archivos_a_procesar):.1f}s por sentencia")
print(f"📂 HTMLs guardados en: {CARPETA_HTML}")

# ESTADÍSTICAS GLOBALES
mostrar_estadisticas(json_files, progreso, es_resumen_final=True)

pendientes_restantes = obtener_pendientes(json_files, progreso)

if pendientes_restantes:
    print(f"\n⚠️  AÚN QUEDAN {len(pendientes_restantes)} SENTENCIAS PENDIENTES")
    print("   💡 Ejecuta el script de nuevo para continuar donde quedaste")
else:
    print(f"\n🎉 ¡TODAS LAS SENTENCIAS HAN SIDO PROCESADAS!")

if total_exitosos > 0:
    print("\n🔥 CREANDO INDEX Y PREPARANDO FIREBASE...")
    crear_index_html()
    
    respuesta = input("\n¿Subir a Firebase Hosting AHORA? (s/n): ")
    if respuesta.lower() == 's':
        subir_a_firebase()
        print(f"\n🌐 Sitio publicado: https://penalex-ve.web.app")
        print(f"📚 Firestore: Consulta la colección 'jurisprudencia'")
        print(f"⚠️  Sentencias no disponibles: colección 'jurisprudencia_no_disponible'")
    else:
        print("\n💡 Puedes subir más tarde con Firebase CLI:")
        print("   firebase deploy --only hosting --project penalex-ve")
else:
    print("\n⚠️  No se procesaron sentencias exitosamente en esta ejecución")

print("\n✅ SCRIPT FINALIZADO")
print("=" * 60)
