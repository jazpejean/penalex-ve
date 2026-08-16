#!/usr/bin/env python3
"""
Scraper Simple de Jurisprudencia TSJ Venezuela
Solo usa librerías estándar de Python (sin BeautifulSoup)
Autor: Penalex VE
Fecha: 2026-07-31
"""

import urllib.request
import ssl
import json
import re
from datetime import datetime
import time

# Crear contexto SSL que ignore verificación (TSJ tiene certificado vencido)
ssl_context = ssl.create_default_context()
ssl_context.check_hostname = False
ssl_context.verify_mode = ssl.CERT_NONE

class ScraperTSJSimple:
    def __init__(self):
        self.sentencias = []
        self.user_agent = 'Mozilla/5.0 (PenalexVE Educational Research Bot)'
    
    def fetch_url(self, url):
        """Descarga contenido de una URL ignorando SSL"""
        req = urllib.request.Request(url, headers={'User-Agent': self.user_agent})
        
        try:
            with urllib.request.urlopen(req, context=ssl_context, timeout=15) as response:
                return response.read().decode('utf-8', errors='ignore')
        except Exception as e:
            return None
    
    def parsear_sentencia_html(self, html, info_base):
        """Extrae información de la sentencia desde el HTML"""
        # Limpiar HTML básico
        texto = re.sub(r'<script[^>]*>.*?</script>', '', html, flags=re.DOTALL)
        texto = re.sub(r'<style[^>]*>.*?</style>', '', texto, flags=re.DOTALL)
        texto = re.sub(r'<[^>]+>', ' ', texto)
        texto = re.sub(r'\s+', ' ', texto).strip()
        
        # Extraer información clave
        sentencia = {
            'url': info_base['url'],
            'sala': info_base['sala'],
            'sala_nombre': info_base['sala_nombre'],
            'numero': info_base['numero'],
            'tribunal': 'TSJ Venezuela',
            'fecha_extraccion': datetime.now().isoformat()
        }
        
        # Intentar extraer magistrado ponente
        match_ponente = re.search(r'[Mm]agistrado[a]?\s+[Pp]onente[:\s]+([A-ZÁÉÍÓÚÑ][a-záéíóúñ\s]+)', texto)
        if match_ponente:
            sentencia['magistrado_ponente'] = match_ponente.group(1).strip()[:100]
        
        # Intentar extraer fecha
        match_fecha = re.search(r'(\d{1,2})\s+de\s+(\w+)\s+de\s+(\d{4})', texto)
        if match_fecha:
            dia, mes_nombre, año = match_fecha.groups()
            sentencia['fecha'] = f"{año}-{mes_nombre}-{dia}"
        
        # Intentar extraer expediente
        match_exp = re.search(r'[Ee]xpediente[:\s]+([A-Z0-9\-\.]+)', texto)
        if match_exp:
            sentencia['expediente'] = match_exp.group(1).strip()[:50]
        
        # Extraer resumen (primeros 500 caracteres relevantes)
        inicio_texto = texto.find('SENTENCIA') if 'SENTENCIA' in texto else 0
        sentencia['resumen'] = texto[inicio_texto:inicio_texto+500].strip()
        
        # Guardar contenido completo (primeros 5000 caracteres)
        sentencia['contenido'] = texto[:5000]
        
        return sentencia
    
    def scrape_url_directa(self, url):
        """Descarga una sentencia desde URL directa"""
        print(f"🔗 Descargando: {url}")
        
        # Extraer información de la URL
        match = re.search(r'/decisiones/(\w+)/(\w+)/(.+)$', url)
        if not match:
            print("   ❌ URL no tiene formato esperado")
            return False
        
        sala, mes, archivo = match.groups()
        
        info_base = {
            'url': url,
            'sala': sala,
            'sala_nombre': f'Sala {sala.upper()}',
            'mes': mes,
            'numero': archivo.split('-')[0] if '-' in archivo else archivo.replace('.HTM', ''),
        }
        
        contenido = self.fetch_url(url)
        if contenido:
            sentencia = self.parsear_sentencia_html(contenido, info_base)
            if sentencia:
                self.sentencias.append(sentencia)
                print(f"   ✅ Sentencia #{len(self.sentencias)} agregada")
                return True
        
        print("   ❌ No se pudo descargar")
        return False
    
    def scrape_urls_lista(self, urls):
        """Descarga múltiples URLs de una lista"""
        print(f"\n🚀 Descargando {len(urls)} URLs...")
        print("=" * 70)
        
        exitos = 0
        for i, url in enumerate(urls, 1):
            print(f"\n[{i}/{len(urls)}] ", end="")
            
            if self.scrape_url_directa(url):
                exitos += 1
            
            # Rate limiting
            if i % 5 == 0:
                time.sleep(2)
        
        print(f"\n\n✅ Proceso completado")
        print(f"📊 Éxito: {exitos}/{len(urls)} ({exitos*100//len(urls)}%)")
    
    def guardar_json(self, filename='jurisprudencia_tsj.json'):
        """Guarda sentencias en JSON"""
        if not self.sentencias:
            print("\n⚠️  No hay sentencias para guardar")
            return
        
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(self.sentencias, f, indent=2, ensure_ascii=False)
        
        print(f"\n💾 Guardado en: {filename}")
        print(f"📊 Total sentencias: {len(self.sentencias)}")


def main():
    print("=" * 70)
    print("🇻🇪 SCRAPER TSJ VENEZUELA - Versión Simple")
    print("=" * 70)
    
    scraper = ScraperTSJSimple()
    
    # Lista de URLs de ejemplo (basadas en el patrón que funciona)
    # Estas son URLs reales del TSJ que deberías poder modificar
    urls_ejemplo = [
        "http://historico.tsj.gob.ve/decisiones/scp/marzo/128-200302-020028.HTM",
        # Agregar más URLs aquí...
    ]
    
    print("\n📋 OPCIONES:")
    print("1. Descargar URLs de ejemplo (1 sentencia)")
    print("2. Ingresar URLs manualmente")
    print("3. Cargar URLs desde archivo .txt")
    
    try:
        opcion = input("\nSelecciona opción (1-3): ").strip()
        
        if opcion == "1":
            scraper.scrape_urls_lista(urls_ejemplo)
        
        elif opcion == "2":
            print("\n📝 Ingresa URLs (una por línea, línea vacía para terminar):")
            urls = []
            while True:
                url = input("URL: ").strip()
                if not url:
                    break
                urls.append(url)
            
            if urls:
                scraper.scrape_urls_lista(urls)
            else:
                print("⚠️  No se ingresaron URLs")
        
        elif opcion == "3":
            filename = input("Nombre del archivo .txt: ").strip()
            try:
                with open(filename, 'r') as f:
                    urls = [line.strip() for line in f if line.strip()]
                scraper.scrape_urls_lista(urls)
            except FileNotFoundError:
                print(f"❌ Archivo no encontrado: {filename}")
        
        else:
            print("❌ Opción inválida")
            return
        
        # Guardar resultados
        if scraper.sentencias:
            scraper.guardar_json()
            
            # Generar archivo para importar a Firestore
            print("\n" + "=" * 70)
            print("📦 IMPORTACIÓN A FIRESTORE")
            print("=" * 70)
            print("\n1. Ve a Firebase Console → Firestore Database")
            print("2. Selecciona la colección 'sentencias'")
            print("3. Importa el archivo 'jurisprudencia_tsj.json'")
            print("\nO usa el siguiente formato para importación por lotes:")
            
            # Generar formato Firebase
            firebase_format = []
            for s in scraper.sentencias:
                firebase_format.append({
                    'id': f"tsj_{s['numero']}_{s['sala']}",
                    'data': s
                })
            
            with open('jurisprudencia_tsj_firebase.json', 'w', encoding='utf-8') as f:
                json.dump(firebase_format, f, indent=2, ensure_ascii=False)
            
            print("✅ Formato Firebase guardado en: jurisprudencia_tsj_firebase.json")
        
    except KeyboardInterrupt:
        print("\n\n⚠️  Interrumpido por usuario")
        scraper.guardar_json()
    except Exception as e:
        print(f"\n❌ Error: {e}")
        scraper.guardar_json()


if __name__ == "__main__":
    main()
