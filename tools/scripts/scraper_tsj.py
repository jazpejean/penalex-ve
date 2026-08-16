#!/usr/bin/env python3
"""
Scraper de Jurisprudencia TSJ Venezuela
Autor: Penalex VE
Fecha: 2026-07-28

IMPORTANTE: Solo para uso educativo y con fines de investigación legal.
Respetar rate limiting y términos de servicio.
"""

import requests
import time
import json
from bs4 import BeautifulSoup
from datetime import datetime
import urllib3

# Deshabilitar advertencias SSL (TSJ tiene certificado inválido)
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

class ScraperTSJ:
    def __init__(self):
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'PenalexVE Educational Research Bot/1.0'
        })
        self.sentencias = []
        
    def extraer_vlex(self, max_sentencias=100):
        """Extrae índice de sentencias desde vLex"""
        print("🔍 Extrayendo índice de vLex...")
        base_url = "https://vlexvenezuela.com/source/5621"
        
        try:
            response = self.session.get(base_url, timeout=10)
            soup = BeautifulSoup(response.text, 'html.parser')
            
            # Buscar todas las sentencias en la página
            sentencias = soup.find_all('div', class_='resultado') or \
                        soup.find_all('a', href=lambda x: x and 'sentencia' in x.lower())
            
            print(f"✅ Encontradas {len(sentencias)} sentencias en vLex")
            
            for i, item in enumerate(sentencias[:max_sentencias]):
                if i > 0 and i % 10 == 0:
                    print(f"   Procesadas {i}/{max_sentencias}...")
                    time.sleep(2)  # Rate limiting
                
                # Extraer información
                texto = item.get_text() if hasattr(item, 'get_text') else str(item)
                
                sentencia_info = self._parsear_sentencia_vlex(texto)
                if sentencia_info:
                    self.sentencias.append(sentencia_info)
            
            print(f"✅ Total extraídas: {len(self.sentencias)}")
            return self.sentencias
            
        except Exception as e:
            print(f"❌ Error extrayendo de vLex: {e}")
            return []
    
    def _parsear_sentencia_vlex(self, texto):
        """Extrae datos de una sentencia desde texto de vLex"""
        try:
            # Formato típico: "Sentencia nº 014 de Tribunal Supremo..., Sala de Casación Penal, 12-02-2026"
            import re
            
            # Extraer número
            match_numero = re.search(r'[Ss]entencia n[º°]\s*(\d+)', texto)
            numero = match_numero.group(1) if match_numero else None
            
            # Extraer sala
            salas = {
                'Casación Penal': 'scp',
                'Constitucional': 'scon',
                'Casación Civil': 'scc',
                'Casación Social': 'scs',
                'Político Administrativa': 'spa'
            }
            
            sala = None
            sala_nombre = None
            for nombre, codigo in salas.items():
                if nombre in texto:
                    sala = codigo
                    sala_nombre = nombre
                    break
            
            # Extraer fecha (formato: dd-mm-yyyy)
            match_fecha = re.search(r'(\d{1,2})-(\d{1,2})-(\d{4})', texto)
            if match_fecha:
                dia, mes, año = match_fecha.groups()
                fecha = f"{año}-{mes.zfill(2)}-{dia.zfill(2)}"
            else:
                fecha = None
            
            # Extraer resumen (texto después de la fecha)
            partes = texto.split(str(match_fecha.group(0))) if match_fecha else [texto]
            resumen = partes[1].strip()[:500] if len(partes) > 1 else texto[:500]
            
            if numero and sala and fecha:
                return {
                    'numero': numero,
                    'sala': sala,
                    'sala_nombre': sala_nombre,
                    'fecha': fecha,
                    'resumen': resumen,
                    'tribunal': 'TSJ'
                }
            
        except Exception as e:
            print(f"⚠️  Error parseando: {e}")
        
        return None
    
    def construir_url_tsj(self, sentencia):
        """Construye URL del TSJ basándose en metadatos"""
        # Patrones encontrados:
        # http://historico.tsj.gob.ve/decisiones/scp/marzo/128-200302-020028.HTM
        # http://www.tsj.gob.ve/decisiones/scon/marzo/190-26313-2013-12-0115.HTML
        
        fecha_obj = datetime.strptime(sentencia['fecha'], '%Y-%m-%d')
        meses = {
            1: 'enero', 2: 'febrero', 3: 'marzo', 4: 'abril',
            5: 'mayo', 6: 'junio', 7: 'julio', 8: 'agosto',
            9: 'septiembre', 10: 'octubre', 11: 'noviembre', 12: 'diciembre'
        }
        mes = meses[fecha_obj.month]
        
        # Intentar varios formatos de URL
        posibles_urls = [
            f"http://historico.tsj.gob.ve/decisiones/{sentencia['sala']}/{mes}/{sentencia['numero']}.HTM",
            f"http://www.tsj.gob.ve/decisiones/{sentencia['sala']}/{mes}/{sentencia['numero']}.HTML",
            f"http://historico.tsj.gob.ve/decisiones/{sentencia['sala']}/{mes}/{sentencia['numero']}.HTML",
        ]
        
        return posibles_urls
    
    def verificar_url_tsj(self, url):
        """Verifica si una URL del TSJ existe (ignorando SSL)"""
        try:
            response = self.session.head(url, verify=False, timeout=5)
            return response.status_code == 200
        except:
            return False
    
    def descargar_contenido_tsj(self, sentencia):
        """Intenta descargar el contenido completo desde TSJ"""
        urls_posibles = self.construir_url_tsj(sentencia)
        
        for url in urls_posibles:
            try:
                response = self.session.get(url, verify=False, timeout=10)
                if response.status_code == 200:
                    # Limpiar encoding
                    response.encoding = 'utf-8'
                    soup = BeautifulSoup(response.text, 'html.parser')
                    
                    # Extraer texto completo
                    texto_completo = soup.get_text()
                    
                    sentencia['url_tsj'] = url
                    sentencia['contenido_completo'] = texto_completo[:5000]  # Primeros 5000 chars
                    return True
                    
            except Exception as e:
                continue
        
        return False
    
    def guardar_json(self, filename='jurisprudencia_tsj.json'):
        """Guarda las sentencias en archivo JSON"""
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(self.sentencias, f, indent=2, ensure_ascii=False)
        
        print(f"\n💾 Guardado en {filename}")
        print(f"📊 Total sentencias: {len(self.sentencias)}")
    
    def ejecutar(self, max_sentencias=100):
        """Ejecuta el scraping completo"""
        print("🚀 Iniciando scraper de TSJ Venezuela")
        print("=" * 60)
        
        # Paso 1: Extraer índice de vLex
        self.extraer_vlex(max_sentencias)
        
        if not self.sentencias:
            print("❌ No se pudieron extraer sentencias")
            return
        
        # Paso 2: Intentar obtener contenido del TSJ (opcional)
        print("\n🔗 Intentando vincular con TSJ (esto puede tardar)...")
        exitos = 0
        
        for i, sentencia in enumerate(self.sentencias[:20]):  # Solo primeras 20
            if i > 0 and i % 5 == 0:
                print(f"   Procesadas {i}/20...")
                time.sleep(3)  # Rate limiting
            
            if self.descargar_contenido_tsj(sentencia):
                exitos += 1
        
        print(f"✅ URLs del TSJ encontradas: {exitos}/20")
        
        # Paso 3: Guardar resultados
        self.guardar_json()
        
        print("\n✅ Proceso completado")
        print("📁 Importa el archivo JSON a Firebase manualmente")


def main():
    """Función principal"""
    scraper = ScraperTSJ()
    
    # Configuración
    MAX_SENTENCIAS = 100  # Cambia esto según necesites
    
    try:
        scraper.ejecutar(MAX_SENTENCIAS)
    except KeyboardInterrupt:
        print("\n⚠️  Interrumpido por usuario")
        scraper.guardar_json()
    except Exception as e:
        print(f"\n❌ Error fatal: {e}")
        scraper.guardar_json()


if __name__ == "__main__":
    main()
