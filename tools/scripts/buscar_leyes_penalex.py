#!/usr/bin/env python3
"""
Busca las 15 leyes seleccionadas para PENALEX en la API de IAJuriss
Usa los campos reales: titulo_corto, nombre_archivo, etc.
"""
import requests
import json
from pathlib import Path

# Configuración de IAJuriss Supabase
SUPABASE_URL = "https://khtepgjieasapanfxjft.supabase.co"
SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtodGVwZ2ppZWFzYXBhbmZ4amZ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAxNDY3MzgsImV4cCI6MjA4NTcyMjczOH0.qt3TTd4EniWQevrm0XuxW0H8hsOx1-AIG8u6744mERk"

# Directorios
OUTPUT_DIR = Path("tools/data/csvs")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

print("=" * 80)
print("🔍 BUSCAR LEYES PARA PENALEX EN IAJURISS")
print("=" * 80)

# ============================================================================
# BÚSQUEDAS ESPECÍFICAS (15 leyes que fallaron)
# ============================================================================

LEYES_BUSCADAS = [
    {'codigo': 'CP', 'keywords': ['código penal', 'penal venezolano']},
    {'codigo': 'COPP', 'keywords': ['código orgánico procesal penal', 'procesal penal']},
    {'codigo': 'LOSDMVLV', 'keywords': ['mujeres', 'violencia', 'vida libre']},
    {'codigo': 'LOD', 'keywords': ['ley orgánica de drogas', 'drogas']},
    {'codigo': 'LCDOFT', 'keywords': ['delincuencia organizada', 'terrorismo']},
    {'codigo': 'LCSE', 'keywords': ['secuestro', 'extorsión']},
    {'codigo': 'LHRVA', 'keywords': ['hurto', 'robo', 'vehículos']},
    {'codigo': 'LDCAM', 'keywords': ['desarme', 'armas', 'municiones']},
    {'codigo': 'LPVT', 'keywords': ['protección', 'víctimas', 'testigos']},
    {'codigo': 'LECDI', 'keywords': ['delitos informáticos', 'informático']},
    {'codigo': 'LCTPTIM', 'keywords': ['trata de personas', 'tráfico', 'migrantes']},
    {'codigo': 'LORPA', 'keywords': ['responsabilidad penal', 'adolescente']},
    {'codigo': 'LOPNNA', 'keywords': ['niños', 'niñas', 'adolescentes', 'lopnna']},
    {'codigo': 'LOCC', 'keywords': ['contra la corrupción', 'corrupción']},
    {'codigo': 'MUCC', 'keywords': ['cadena de custodia', 'manual único']},
]

def obtener_todas_leyes():
    """Obtiene todas las leyes desde la API de Supabase"""
    
    url = f"{SUPABASE_URL}/rest/v1/leyes_venezolanas"
    
    headers = {
        'apikey': SUPABASE_ANON_KEY,
        'authorization': f'Bearer {SUPABASE_ANON_KEY}',
        'accept': 'application/json',
        'accept-profile': 'public',
    }
    
    params = {
        'select': 'id,titulo_oficial,titulo_corto,acronimo,nombre_archivo,esta_vigente,numero_articulos',
        'esta_vigente': 'eq.true',
        'order': 'titulo_oficial.asc'
    }
    
    print(f"\n📡 Consultando API de IAJuriss...")
    
    try:
        response = requests.get(url, headers=headers, params=params)
        response.raise_for_status()
        
        leyes = response.json()
        print(f"   ✅ Obtenidas: {len(leyes)} leyes vigentes")
        return leyes
        
    except Exception as e:
        print(f"   ❌ Error: {e}")
        return []

def buscar_ley(leyes, keywords):
    """Busca una ley que contenga las keywords"""
    keywords_lower = [k.lower() for k in keywords]
    
    for ley in leyes:
        titulo_oficial = (ley.get('titulo_oficial') or '').lower()
        titulo_corto = (ley.get('titulo_corto') or '').lower()
        acronimo = (ley.get('acronimo') or '').lower()
        
        texto_completo = f"{titulo_oficial} {titulo_corto} {acronimo}"
        
        # Si alguna keyword está presente
        for kw in keywords_lower:
            if kw in texto_completo:
                return ley
    
    return None

def construir_url_pdf(nombre_archivo):
    """Construye URL del PDF"""
    if not nombre_archivo:
        return None
    if not nombre_archivo.endswith('.pdf'):
        nombre_archivo = f"{nombre_archivo}.pdf"
    return f"https://iajuriss.com/docs/leyes/{nombre_archivo}"

# ============================================================================
# EJECUCIÓN
# ============================================================================

if __name__ == "__main__":
    
    # Obtener todas las leyes vigentes
    leyes = obtener_todas_leyes()
    
    if not leyes:
        print("\n❌ No se pudieron obtener las leyes")
        exit(1)
    
    print(f"\n{'='*80}")
    print("🔎 BUSCANDO LAS 15 LEYES PARA PENALEX")
    print(f"{'='*80}\n")
    
    leyes_encontradas = []
    leyes_no_encontradas = []
    
    for busqueda in LEYES_BUSCADAS:
        codigo = busqueda['codigo']
        keywords = busqueda['keywords']
        
        print(f"🔍 {codigo:<12} → Buscando: {', '.join(keywords[:2])}")
        
        ley = buscar_ley(leyes, keywords)
        
        if ley:
            url_pdf = construir_url_pdf(ley.get('nombre_archivo'))
            titulo = ley.get('titulo_corto') or ley.get('titulo_oficial')
            
            print(f"   ✅ ENCONTRADA: {titulo[:55]}")
            print(f"   📄 Archivo: {ley.get('nombre_archivo')}")
            print(f"   🔗 URL: {url_pdf}\n")
            
            leyes_encontradas.append({
                'codigo_penalex': codigo,
                'id_iajuriss': ley.get('id'),
                'titulo': titulo,
                'acronimo': ley.get('acronimo'),
                'nombre_archivo': ley.get('nombre_archivo'),
                'url_pdf': url_pdf,
                'numero_articulos': ley.get('numero_articulos'),
                'esta_vigente': ley.get('esta_vigente')
            })
        else:
            print(f"   ⚠️  NO ENCONTRADA\n")
            leyes_no_encontradas.append(codigo)
    
    # Guardar resultados
    print(f"{'='*80}")
    print(f"✅ RESULTADO: {len(leyes_encontradas)}/15 leyes encontradas")
    print(f"{'='*80}\n")
    
    if leyes_encontradas:
        json_path = OUTPUT_DIR / 'leyes_penalex_encontradas.json'
        with open(json_path, 'w', encoding='utf-8') as f:
            json.dump(leyes_encontradas, f, ensure_ascii=False, indent=2)
        print(f"💾 Guardado en: {json_path}\n")
        
        print("📋 RESUMEN:\n")
        for ley in leyes_encontradas:
            print(f"   {ley['codigo_penalex']:<12} {ley['nombre_archivo']:<45} {ley['numero_articulos']:>4} arts")
    
    if leyes_no_encontradas:
        print(f"\n⚠️  NO ENCONTRADAS ({len(leyes_no_encontradas)}):")
        for codigo in leyes_no_encontradas:
            print(f"   - {codigo}")
        print(f"\n💡 Buscar manualmente en: https://iajuriss.com/leyes")
    
    print("\n" + "=" * 80)
