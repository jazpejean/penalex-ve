#!/usr/bin/env python3
"""
Scraper de IAJuriss usando su API de Supabase
Obtiene las 643 leyes con URLs reales para descarga
"""
import requests
import json
import csv
from pathlib import Path

# Configuración de IAJuriss Supabase
SUPABASE_URL = "https://khtepgjieasapanfxjft.supabase.co"
SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtodGVwZ2ppZWFzYXBhbmZ4amZ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAxNDY3MzgsImV4cCI6MjA4NTcyMjczOH0.qt3TTd4EniWQevrm0XuxW0H8hsOx1-AIG8u6744mERk"

# Directorios
OUTPUT_DIR = Path("tools/data/csvs")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

print("=" * 80)
print("⚖️  SCRAPER DE LEYES VENEZOLANAS - IAJuriss (vía Supabase)")
print("=" * 80)

def obtener_leyes():
    """Obtiene todas las leyes desde la API de Supabase de IAJuriss"""
    
    url = f"{SUPABASE_URL}/rest/v1/leyes_venezolanas"
    
    headers = {
        'apikey': SUPABASE_ANON_KEY,
        'authorization': f'Bearer {SUPABASE_ANON_KEY}',
        'accept': 'application/json',
        'accept-profile': 'public',
        'prefer': 'count=exact',
        'user-agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36'
    }
    
    # Seleccionar campos relevantes
    params = {
        'select': 'id,nombre,codigo_principal,gaceta_oficial,area_derecho,esta_vigente,nombre_archivo,ruta_archivo_pdf',
        'order': 'nombre.asc'
    }
    
    print(f"\n📡 Consultando API de IAJuriss Supabase...")
    print(f"   URL: {url}")
    
    try:
        response = requests.get(url, headers=headers, params=params)
        response.raise_for_status()
        
        # Obtener el conteo total del header
        content_range = response.headers.get('content-range', '')
        if content_range:
            total = content_range.split('/')[-1]
            print(f"   ✅ Total de leyes: {total}")
        
        leyes = response.json()
        print(f"   ✅ Descargadas: {len(leyes)} leyes")
        
        return leyes
        
    except requests.exceptions.RequestException as e:
        print(f"   ❌ Error: {e}")
        return []

def construir_url_pdf(nombre_archivo):
    """Construye la URL completa del PDF"""
    if not nombre_archivo:
        return None
    
    # Si ya es URL completa, retornarla
    if nombre_archivo.startswith('http'):
        return nombre_archivo
    
    # Construir URL desde el nombre de archivo
    # Formato: https://iajuriss.com/docs/leyes/{archivo}.pdf
    if not nombre_archivo.endswith('.pdf'):
        nombre_archivo = f"{nombre_archivo}.pdf"
    
    return f"https://iajuriss.com/docs/leyes/{nombre_archivo}"

def buscar_ley_por_keywords(leyes, keywords):
    """Busca una ley que contenga las keywords en nombre o código"""
    keywords_lower = [k.lower() for k in keywords]
    
    for ley in leyes:
        nombre = ley.get('nombre', '').lower()
        codigo = ley.get('codigo_principal', '').lower()
        
        # Si todas las keywords están presentes
        if all(kw in nombre or kw in codigo for kw in keywords_lower):
            return ley
    
    return None

def guardar_csv(leyes, filename):
    """Guarda las leyes en CSV"""
    csv_path = OUTPUT_DIR / filename
    
    with open(csv_path, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=[
            'id', 'nombre', 'codigo_principal', 'gaceta_oficial', 'area_derecho', 
            'esta_vigente', 'nombre_archivo', 'url_pdf'
        ])
        writer.writeheader()
        
        for ley in leyes:
            writer.writerow({
                'id': ley.get('id'),
                'nombre': ley.get('nombre'),
                'codigo_principal': ley.get('codigo_principal'),
                'gaceta_oficial': ley.get('gaceta_oficial'),
                'area_derecho': ley.get('area_derecho'),
                'esta_vigente': ley.get('esta_vigente'),
                'nombre_archivo': ley.get('nombre_archivo'),
                'url_pdf': construir_url_pdf(ley.get('nombre_archivo'))
            })
    
    print(f"   💾 CSV guardado: {csv_path}")
    return csv_path

def guardar_json(leyes, filename):
    """Guarda las leyes en JSON"""
    json_path = OUTPUT_DIR / filename
    
    # Agregar URLs completas
    for ley in leyes:
        ley['url_pdf'] = construir_url_pdf(ley.get('nombre_archivo'))
    
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(leyes, f, ensure_ascii=False, indent=2)
    
    print(f"   💾 JSON guardado: {json_path}")
    return json_path

# ============================================================================
# BÚSQUEDA DE LAS 15 LEYES QUE FALLARON
# ============================================================================

LEYES_BUSCADAS = [
    {'codigo': 'CP', 'keywords': ['código', 'penal']},
    {'codigo': 'COPP', 'keywords': ['código', 'procesal', 'penal']},
    {'codigo': 'LOSDMVLV', 'keywords': ['mujeres', 'violencia']},
    {'codigo': 'LOD', 'keywords': ['drogas']},
    {'codigo': 'LCDOFT', 'keywords': ['delincuencia', 'organizada']},
    {'codigo': 'LCSE', 'keywords': ['secuestro', 'extorsión']},
    {'codigo': 'LHRVA', 'keywords': ['hurto', 'robo', 'vehículos']},
    {'codigo': 'LDCAM', 'keywords': ['desarme', 'armas']},
    {'codigo': 'LPVT', 'keywords': ['protección', 'víctimas', 'testigos']},
    {'codigo': 'LECDI', 'keywords': ['delitos', 'informáticos']},
    {'codigo': 'LCTPTIM', 'keywords': ['trata', 'personas']},
    {'codigo': 'LORPA', 'keywords': ['responsabilidad', 'penal', 'adolescente']},
    {'codigo': 'LOPNNA', 'keywords': ['niños', 'niñas', 'adolescentes']},
    {'codigo': 'LOCC', 'keywords': ['corrupción']},
    {'codigo': 'MUCC', 'keywords': ['cadena', 'custodia']},
]

if __name__ == "__main__":
    
    # Obtener todas las leyes
    leyes = obtener_leyes()
    
    if not leyes:
        print("\n❌ No se pudieron obtener las leyes")
        exit(1)
    
    # Guardar archivos completos
    print(f"\n💾 Guardando archivos...")
    guardar_csv(leyes, 'leyes_iajuriss_completo.csv')
    guardar_json(leyes, 'leyes_iajuriss_completo.json')
    
    # Buscar las 15 leyes específicas
    print(f"\n{'='*80}")
    print("🔍 BUSCANDO LAS 15 LEYES SELECCIONADAS PARA PENALEX")
    print(f"{'='*80}\n")
    
    leyes_encontradas = []
    leyes_no_encontradas = []
    
    for busqueda in LEYES_BUSCADAS:
        codigo = busqueda['codigo']
        keywords = busqueda['keywords']
        
        print(f"🔎 Buscando: {codigo} ({', '.join(keywords)})")
        
        ley = buscar_ley_por_keywords(leyes, keywords)
        
        if ley:
            url_pdf = construir_url_pdf(ley.get('nombre_archivo'))
            print(f"   ✅ ENCONTRADA: {ley.get('nombre')[:60]}")
            print(f"      Archivo: {ley.get('nombre_archivo')}")
            print(f"      URL: {url_pdf}")
            
            leyes_encontradas.append({
                'codigo_penalex': codigo,
                'nombre': ley.get('nombre'),
                'codigo_iajuriss': ley.get('codigo_principal'),
                'nombre_archivo': ley.get('nombre_archivo'),
                'url_pdf': url_pdf,
                'esta_vigente': ley.get('esta_vigente'),
                'area_derecho': ley.get('area_derecho')
            })
        else:
            print(f"   ⚠️  NO ENCONTRADA")
            leyes_no_encontradas.append(codigo)
        
        print()
    
    # Guardar leyes encontradas
    if leyes_encontradas:
        print(f"{'='*80}")
        print(f"✅ RESULTADO: {len(leyes_encontradas)}/15 leyes encontradas")
        print(f"{'='*80}\n")
        
        json_path = OUTPUT_DIR / 'leyes_penalex_seleccionadas.json'
        with open(json_path, 'w', encoding='utf-8') as f:
            json.dump(leyes_encontradas, f, ensure_ascii=False, indent=2)
        print(f"💾 Leyes para PENALEX guardadas: {json_path}\n")
        
        # Mostrar tabla resumen
        print("📋 RESUMEN:\n")
        for ley in leyes_encontradas:
            print(f"   {ley['codigo_penalex']:<12} → {ley['nombre_archivo']}")
    
    if leyes_no_encontradas:
        print(f"\n⚠️  NO ENCONTRADAS ({len(leyes_no_encontradas)}):")
        for codigo in leyes_no_encontradas:
            print(f"   - {codigo}")
        print(f"\n   (Buscar manualmente en: https://iajuriss.com/leyes)")
    
    print("\n" + "=" * 80)
    print("✅ SCRAPING COMPLETADO")
    print("=" * 80)
    print(f"\nArchivos generados:")
    print(f"   1. leyes_iajuriss_completo.csv (todas las {len(leyes)} leyes)")
    print(f"   2. leyes_iajuriss_completo.json (todas las {len(leyes)} leyes)")
    print(f"   3. leyes_penalex_seleccionadas.json ({len(leyes_encontradas)} leyes)")
    print("=" * 80 + "\n")
