#!/usr/bin/env python3
r"""
Parser Orquestador - Sistema de parsers especializados para leyes venezolanas

ARQUITECTURA:
- Detecta cada ley por su código
- Rutea a parser especializado si existe
- Usa parser general como fallback

PARSERS ESPECIALIZADOS:
1. parser_lopnna.py - LOPNNA (artículos letrados, duplicados reforma)
2. parser_cp.py - Código Penal (títulos multi-línea LIBRO/TÍTULO/CAPÍTULO)
3. parser_locc.py - LOCC (filtrar anuncios "Se modifica...")
4. [Más parsers según necesidad]

OBJETIVO:
- 100% precisión en 16 leyes (2,891 artículos)
- Cada parser optimizado para su formato específico
"""
import sys
from pathlib import Path

# Importar parsers especializados
try:
    from parser_lopnna import parsear_lopnna
    from parser_cp import parsear_cp
    from parser_locc import parsear_locc
except ImportError:
    print("⚠️  Algunos parsers especializados no se encontraron")
    print("   Asegúrate de estar en el directorio correcto")
    sys.exit(1)

# Importar parser general como fallback
try:
    from parser_articulos import procesar_ley
except ImportError:
    print("⚠️  Parser general no encontrado")
    procesar_ley = None

TXT_DIR = Path("tools/data/leyes/textos")
OUTPUT_DIR = Path("tools/data/leyes/estructurado")

# Mapeo: código ley → función parser especializado
PARSERS_ESPECIALIZADOS = {
    'LOPNNA': parsear_lopnna,
    'CP': parsear_cp,
    'LOCC': parsear_locc,
    # Agregar más según se creen
}

def detectar_parser(codigo_ley):
    """
    Detecta qué parser usar para cada ley
    
    Returns:
        - Parser especializado si existe
        - Parser general como fallback
        - None si no hay parser disponible
    """
    if codigo_ley in PARSERS_ESPECIALIZADOS:
        return PARSERS_ESPECIALIZADOS[codigo_ley]
    
    return procesar_ley  # Fallback a parser general

def parsear_todas_las_leyes():
    """Procesa todas las leyes con parsers especializados"""
    
    print("=" * 80)
    print("🎯 PARSER ORQUESTADOR - Sistema Especializado")
    print("=" * 80)
    
    txt_files = sorted(TXT_DIR.glob("*.txt"))
    
    print(f"\n📋 {len(txt_files)} leyes detectadas")
    print(f"🔧 {len(PARSERS_ESPECIALIZADOS)} parsers especializados disponibles")
    print(f"   {', '.join(PARSERS_ESPECIALIZADOS.keys())}\n")
    
    resultados = []
    total_articulos = 0
    
    for txt_path in txt_files:
        codigo = txt_path.stem
        parser = detectar_parser(codigo)
        
        if not parser:
            print(f"❌ {codigo}: No hay parser disponible")
            continue
        
        # Determinar tipo de parser
        if codigo in PARSERS_ESPECIALIZADOS:
            tipo_parser = "especializado"
            simbolo = "🎯"
        else:
            tipo_parser = "general"
            simbolo = "📄"
        
        print(f"\n{simbolo} {codigo} ({tipo_parser})")
        
        try:
            resultado = parser(txt_path)
            
            num_arts = resultado.get('num_articulos', 0)
            total_articulos += num_arts
            
            resultados.append({
                'codigo': codigo,
                'articulos': num_arts,
                'parser': tipo_parser
            })
            
            print(f"   ✅ {num_arts} artículos")
            
        except Exception as e:
            print(f"   ❌ Error: {str(e)}")
            resultados.append({
                'codigo': codigo,
                'articulos': 0,
                'parser': tipo_parser,
                'error': str(e)
            })
    
    # Resumen final
    print("\n" + "=" * 80)
    print("📊 RESUMEN FINAL")
    print("=" * 80)
    
    print(f"\n✅ Leyes procesadas: {len([r for r in resultados if 'error' not in r])}")
    print(f"❌ Leyes con error: {len([r for r in resultados if 'error' in r])}")
    print(f"📈 Total artículos: {total_articulos:,}")
    
    # Desglose por parser
    especializados = [r for r in resultados if r.get('parser') == 'especializado']
    generales = [r for r in resultados if r.get('parser') == 'general']
    
    print(f"\n🎯 Parsers especializados: {len(especializados)} leyes")
    for r in especializados:
        print(f"   {r['codigo']:<12} {r['articulos']:>4} artículos")
    
    print(f"\n📄 Parser general: {len(generales)} leyes")
    for r in generales:
        print(f"   {r['codigo']:<12} {r['articulos']:>4} artículos")
    
    # Objetivo
    print("\n" + "=" * 80)
    print("🎯 OBJETIVO: 2,891 artículos en 16 leyes")
    if total_articulos == 2891:
        print("✅ ¡PERFECTO! Objetivo alcanzado")
    else:
        diferencia = 2891 - total_articulos
        print(f"⚠️  Diferencia: {diferencia:+d} artículos")
    print("=" * 80 + "\n")
    
    return resultados

if __name__ == "__main__":
    import os
    
    # Cambiar al directorio raíz del proyecto
    script_dir = Path(__file__).parent
    project_root = script_dir.parent.parent
    os.chdir(project_root)
    
    print(f"📁 Directorio de trabajo: {os.getcwd()}\n")
    
    resultados = parsear_todas_las_leyes()
