# ============================================
# EXTRACTOR TSJ V3 - MEJORADO
# ============================================
# Mejoras V3:
# - Ficha solo con enlace al TSJ (no duplica HTML)
# - HTML original publicado en Firebase Hosting
# - Botón "Ver Sentencia Completa" apunta a Firebase
# - Todo el contenido en Firestore para IAs
# - Búsqueda en Google para sentencias sin URL
# - Extracción y publicación del HTML encontrado

# 1. INSTALAR DEPENDENCIAS
!pip install requests beautifulsoup4 firebase-admin googlesearch-python -q

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

# 3. MONTAR GOOGLE DRIVE
drive.mount('/content/drive')

# ============================================
# CONFIGURACIÓN
# ============================================

RUTA_JSONS = "/content/drive/MyDrive/json/"
CARPETA_HTML = "/content/htmls_tsj"
ARCHIVO_PROGRESO = "/content/drive/MyDrive/progreso_tsj.json"

os.makedirs(CARPETA_HTML, exist_ok=True)

# 🔥 CONFIGURACIÓN FIREBASE
FIREBASE_TOKEN = "1//056NFsh7FbdMzCgYIARAAGAUSNwF-L9IrvBPDBp1dxA5XGYDUH7jaCu2tCwDn2dpMKV3Wsii_c0ucX-2nZ1IveOlWr8LrYBvA2Tw"
FIREBASE_URL_BASE = "https://penalex-ve.web.app"
LOGO_URL = "https://historico.tsj.gob.ve/graficos/encabezadotsj.jpg"
