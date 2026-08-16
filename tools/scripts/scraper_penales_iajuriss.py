#!/usr/bin/env python3
"""
Scraper IaJuriss - SOLO Sentencias Penales
Usa API Supabase con filtro materia=Penal
"""

import requests
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

BASE_API_URL = "https://khtepgjieasapanfxjft.supabase.co/rest/v1/sentencias_tsj"

# Headers actualizados (válidos)
SUPABASE_HEADERS = {
    'apikey': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtodGVwZ2ppZWFzYXBhbmZ4amZ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAxNDY3MzgsImV4cCI6MjA4NTcyMjczOH0.qt3TTd4EniWQevrm0XuxW0H8hsOx1-AIG8u6744mERk',
    'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtodGVwZ2ppZWFzYXBhbmZ4amZ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAxNDY3MzgsImV4cCI6MjA4NTcyMjczOH0.qt3TTd4EniWQevrm0XuxW0H8hsOx1-AIG8u6744mERk',
    'Content-Type': 'application/json',
    'accept-profile': 'public',
    'Prefer': 'count=exact',
    'Origin': 'https://iajuriss.com',
    'Referer': 'https://iajuriss.com/'
}

OUTPUT_DIR = Path("sentencias_penales")
CHECKPOINT_FILE = OUTPUT_DIR / "checkpoint.json"

# Rate limiting
DELAY_MIN = 2
DELAY_MAX = 5

# Paginación
LIMIT_POR_PAGINA = 100

# ============================================================================
# FUNCIONES
# ============================================================================

def crear_directorios():
    OUTPUT_DIR.mkdir(exist_ok=True)
    (OUTPUT_DIR / "json").mkdir(exist_ok=True)
    (OUTPUT_DIR / "logs").mkdir(exist_ok=True)

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
        'ultima_pagina': 0,
        'stats': {'exitos': 0, 'fallos': 0, 'omitidas': 0}
    }

def generar_id_sentencia(sentencia):
    numero = sentencia.get('numero', 'sin_numero')
    fecha = sentencia.get('fecha', 'sin_fecha')
    
    numero_clean = re.sub(r'[^a-z0-9]+', '_', str(numero).lower())
    fecha_clean = re.sub(r'[^a-z0-9]+', '_', str(fecha).lower())
    
    return f"penal_{numero_clean}_{fecha_clean}"

# ============================================================================
# SCRAPER
# ============================================================================

class ScraperPenales:
    def __init__(self):
        self.session = requests.Session()
        self.session.headers.update(SUPABASE_HEADERS)
        self.checkpoint = cargar_checkpoint()
        
    def obtener_total(self):
        """Cuenta total de sentencias penales"""
        print("🔍 Contando sentencias penales...\n")
        
        try:
            params = {
                'select': 'id',
                'materia': 'eq.Penal',
                'limit': 1
            }
            
            response = self.session.get(BASE_API_URL, params=params, timeout=30)
            
            if response.status_code == 200:
                # Total en header Content-Range
                content_range = response.headers.get('Content-Range', '0-0/0')
                total = int(content_range.split('/')[-1])
                
                print(f"✅ Total sentencias penales: {total:,}")
                print(f"⏱️  Tiempo estimado: {total * 3 / 3600:.1f} horas\n")
                
                return total
            else:
                print(f"❌ Error HTTP {response.status_code}")
                return 0
                
        except Exception as e:
            print(f"❌ Error: {e}")
            return 0
    
    def extraer_pagina(self, offset):
        """Extrae una página de sentencias"""
        try:
            params = {
                'select': '*',
                'materia': 'eq.Penal',
                'order': 'fecha_sentencia.desc.nullslast',
                'offset': offset,
                'limit': LIMIT_POR_PAGINA
            }
            
            response = self.session.get(BASE_API_URL, params=params, timeout=30)
            return response.json() if response.status_code == 200 else []
                
        except:
            return []
    
    def guardar_sentencia(self, sentencia):
        """Guarda sentencia en JSON"""
        try:
            doc_id = generar_id_sentencia(sentencia)
            filepath = OUTPUT_DIR / "json" / f"{doc_id}.json"
            
            with open(filepath, 'w', encoding='utf-8') as f:
                json.dump(sentencia, f, ensure_ascii=False, indent=2)
            
            return True
        except:
            return False
    
    def scrapear(self, total):
        """Extrae todas las sentencias penales"""
        print(f"{'='*70}")
        print(f"📂 EXTRAYENDO SENTENCIAS PENALES")
        print(f"{'='*70}\n")
        
        offset = self.checkpoint['ultima_pagina']
        print(f"Total: {total:,} | Continuando desde: {offset:,}\n")
        
        with tqdm(total=total, initial=offset, desc="Penales", unit="sent") as pbar:
            while offset < total:
                # Extraer página
                sentencias = self.extraer_pagina(offset)
                
                if not sentencias:
                    break
                
                # Procesar cada sentencia
                for sent_raw in sentencias:
                    sentencia = {
                        'id': sent_raw.get('id'),
                        'numero': sent_raw.get('numero_sentencia', ''),
                        'fecha': sent_raw.get('fecha_sentencia', ''),
                        'anio': sent_raw.get('anio', ''),
                        'sala': sent_raw.get('sala_codigo', ''),
                        'materia': 'Penal',
                        'tipo_recurso': sent_raw.get('tipo_recurso', ''),
                        'decision': sent_raw.get('decision', ''),
                        'ponente': sent_raw.get('magistrado_ponente', ''),
                        'resumen': sent_raw.get('resumen', ''),
                        'palabras_clave': sent_raw.get('palabras_clave', []),
                        'titulo': sent_raw.get('titulo', ''),
                        'url_pdf': sent_raw.get('url_pdf_iajuriss', ''),
                        'url_tsj': sent_raw.get('url_tsj_original', ''),
                        'fuente': 'IaJuriss (Supabase)',
                        'procesado': datetime.now().isoformat()
                    }
                    
                    doc_id = generar_id_sentencia(sentencia)
                    
                    # Evitar duplicados
                    if doc_id in self.checkpoint['procesadas']:
                        self.checkpoint['stats']['omitidas'] += 1
                        continue
                    
                    # Guardar
                    if self.guardar_sentencia(sentencia):
                        self.checkpoint['stats']['exitos'] += 1
                        self.checkpoint['procesadas'].append(doc_id)
                    else:
                        self.checkpoint['stats']['fallos'] += 1
                    
                    pbar.update(1)
                
                # Actualizar offset
                offset += len(sentencias)
                self.checkpoint['ultima_pagina'] = offset
                
                # Guardar checkpoint
                guardar_checkpoint(self.checkpoint)
                
                # Rate limiting
                time.sleep(random.uniform(DELAY_MIN, DELAY_MAX))
                
                # Si retornó menos del límite, terminamos
                if len(sentencias) < LIMIT_POR_PAGINA:
                    break
    
    def ejecutar(self):
        """Ejecuta scraping completo"""
        print("="*70)
        print("🚀 SCRAPER SENTENCIAS PENALES - IAJURISS")
        print("="*70)
        print(f"📁 Output: {OUTPUT_DIR}")
        print(f"⏱️  Rate limit: {DELAY_MIN}-{DELAY_MAX} seg")
        print(f"🎯 Filtro: materia=Penal")
        print("="*70 + "\n")
        
        # Obtener total
        total = self.obtener_total()
        
        if total == 0:
            print("❌ No se pudo obtener total de sentencias")
            return
        
        # Scrapear
        self.scrapear(total)
        
        # Reporte
        print("\n" + "="*70)
        print("📊 REPORTE FINAL")
        print("="*70)
        print(f"✅ Éxitos: {self.checkpoint['stats']['exitos']:,}")
        print(f"❌ Errores: {self.checkpoint['stats']['fallos']:,}")
        print(f"⏭️  Omitidas: {self.checkpoint['stats']['omitidas']:,}")
        print(f"📁 Directorio: {OUTPUT_DIR / 'json'}")
        print("="*70)
        
        # Guardar reporte
        reporte_path = OUTPUT_DIR / "logs" / f"reporte_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        with open(reporte_path, 'w', encoding='utf-8') as f:
            json.dump(self.checkpoint, f, ensure_ascii=False, indent=2)
        
        print(f"📄 Reporte: {reporte_path}")

# ============================================================================
# MAIN
# ============================================================================

def main():
    crear_directorios()
    scraper = ScraperPenales()
    scraper.ejecutar()

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n⚠️  Interrumpido - checkpoint guardado")
    except Exception as e:
        print(f"\n\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
