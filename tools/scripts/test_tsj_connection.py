#!/usr/bin/env python3
"""
Test de conectividad con TSJ Venezuela
Solo usa librerías estándar de Python
"""

import urllib.request
import ssl
import json
from datetime import datetime

# Crear contexto SSL que ignore verificación
ssl_context = ssl.create_default_context()
ssl_context.check_hostname = False
ssl_context.verify_mode = ssl.CERT_NONE

def test_url(url, nombre):
    """Prueba acceso a una URL"""
    print(f"\n🔍 Probando: {nombre}")
    print(f"   URL: {url}")
    
    try:
        req = urllib.request.Request(
            url,
            headers={'User-Agent': 'Mozilla/5.0 (PenalexVE Research Bot)'}
        )
        
        with urllib.request.urlopen(req, context=ssl_context, timeout=10) as response:
            status = response.status
            content_type = response.headers.get('Content-Type', 'unknown')
            
            print(f"   ✅ Status: {status}")
            print(f"   📄 Content-Type: {content_type}")
            
            # Leer primeros 500 caracteres
            data = response.read(500).decode('utf-8', errors='ignore')
            print(f"   📝 Preview: {data[:100]}...")
            
            return True
            
    except urllib.error.HTTPError as e:
        print(f"   ❌ HTTP Error {e.code}: {e.reason}")
        return False
    except urllib.error.URLError as e:
        print(f"   ❌ URL Error: {e.reason}")
        return False
    except Exception as e:
        print(f"   ❌ Error: {e}")
        return False

def main():
    print("=" * 70)
    print("🇻🇪 TEST DE CONECTIVIDAD TSJ VENEZUELA")
    print("=" * 70)
    
    # URLs a probar
    urls_test = [
        ("http://www.tsj.gob.ve", "TSJ Página Principal"),
        ("http://historico.tsj.gob.ve", "TSJ Histórico"),
        ("http://historico.tsj.gob.ve/decisiones/scp/", "Sala Casación Penal"),
        ("http://historico.tsj.gob.ve/decisiones/scp/marzo/", "SCP Marzo"),
        # Ejemplo de sentencia real (si existe)
        ("http://historico.tsj.gob.ve/decisiones/scp/marzo/128-200302-020028.HTM", "Sentencia Ejemplo 1"),
    ]
    
    resultados = {}
    
    for url, nombre in urls_test:
        exito = test_url(url, nombre)
        resultados[nombre] = exito
    
    # Resumen
    print("\n" + "=" * 70)
    print("📊 RESUMEN")
    print("=" * 70)
    
    exitos = sum(1 for v in resultados.values() if v)
    total = len(resultados)
    
    for nombre, exito in resultados.items():
        estado = "✅ OK" if exito else "❌ FAIL"
        print(f"{estado} - {nombre}")
    
    print(f"\n📈 Tasa de éxito: {exitos}/{total} ({exitos*100//total}%)")
    
    if exitos > 0:
        print("\n✅ Hay conectividad con TSJ")
        print("💡 Puedes proceder con el scraping")
    else:
        print("\n❌ No hay conectividad con TSJ")
        print("💡 Posibles causas:")
        print("   • Certificado SSL expirado (normal en TSJ)")
        print("   • Firewall/proxy bloqueando")
        print("   • Sitio web caído temporalmente")
    
    # Guardar resultados
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"test_tsj_{timestamp}.json"
    
    with open(filename, 'w', encoding='utf-8') as f:
        json.dump({
            'timestamp': timestamp,
            'resultados': resultados,
            'tasa_exito': f"{exitos}/{total}"
        }, f, indent=2)
    
    print(f"\n💾 Resultados guardados en: {filename}")

if __name__ == "__main__":
    main()
