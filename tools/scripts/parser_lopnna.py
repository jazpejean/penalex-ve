#!/usr/bin/env python3
r"""
Parser especializado para LOPNNA (Ley Orgánica para la Protección de Niños, Niñas y Adolescentes)

ESTRUCTURA DETECTADA:
- Artículos numerados: 1-683 (formato: "Artículo 123")
- Artículos con letra: 683-A, 683-B, 683-C (formato: "Artículo 683 -A")
- Total esperado: 686 artículos

PROBLEMAS RESUELTOS:
- Parser general solo captura \d+, perdiendo artículos con letras
- Regex actualizado: (\d+(?:\s*-[A-Z])?) captura ambos formatos
"""
import re
import json
from pathlib import Path

def limpiar_texto(texto):
    """Limpia el texto extraído"""
    texto = re.sub(r'\n{3,}', '\n\n', texto)  # Saltos múltiples
    texto = re.sub(r' {2,}', ' ', texto)      # Espacios múltiples
    return texto.strip()

def extraer_articulos_lopnna(texto):
    """
    Extrae artículos de LOPNNA incluyendo variantes con letras
    
    Estrategia simple:
    - Dividir texto por líneas que empiezan con "Artículo"
    - Cada match es un artículo nuevo
    - Capturar todo hasta el siguiente "Artículo"
    """
    articulos = []
    
    # FILTRO: Encontrar donde empieza la ley consolidada
    match_titulo = re.search(r'\nTÍTULO I\b', texto)
    
    if match_titulo:
        inicio_ley = match_titulo.start()
        print(f"   🔍 Ley consolidada empieza en posición: {inicio_ley:,}")
        texto_consolidado = texto[inicio_ley:]
    else:
        print(f"   ⚠️  No se encontró 'TÍTULO I', parseando texto completo")
        texto_consolidado = texto
    
    # Buscar todos los artículos con regex simple
    # Solo buscar el encabezado, luego extraer contenido manualmente
    patron_header = r'^Artículo\s+(\d+(?:\s*-[A-Z])?)[°º]?\s*\.?\s*[-–—]?\s*(.+?)$'
    
    lineas = texto_consolidado.split('\n')
    articulo_actual = None
    contenido_actual = []
    
    for linea in lineas:
        match = re.match(patron_header, linea.strip())
        
        if match:
            # Guardar artículo anterior si existe
            if articulo_actual:
                numero_normalizado = re.sub(r'\s+-', '-', articulo_actual['numero'])
                contenido_completo = '\n'.join(contenido_actual)
                titulo = articulo_actual['titulo']
                
                # Detectar derogados: puede estar en título o primeras líneas de contenido
                es_derogado = 'DEROGADO' in titulo.upper() or 'DEROGADO' in contenido_completo[:100]
                
                articulos.append({
                    'numero': numero_normalizado,
                    'numero_raw': articulo_actual['numero'],
                    'titulo': titulo,
                    'contenido': limpiar_texto(contenido_completo),
                    'es_derogado': es_derogado
                })
            
            # Iniciar nuevo artículo
            articulo_actual = {
                'numero': match.group(1).strip(),
                'titulo': match.group(2).strip()
            }
            contenido_actual = []
        else:
            # Agregar línea al contenido del artículo actual
            if articulo_actual and linea.strip():
                contenido_actual.append(linea.strip())
    
    # No olvidar el último artículo
    if articulo_actual:
        numero_normalizado = re.sub(r'\s+-', '-', articulo_actual['numero'])
        contenido_completo = '\n'.join(contenido_actual)
        titulo = articulo_actual['titulo']
        
        # Detectar derogados: puede estar en título o primeras líneas de contenido
        es_derogado = 'DEROGADO' in titulo.upper() or 'DEROGADO' in contenido_completo[:100]
        
        articulos.append({
            'numero': numero_normalizado,
            'numero_raw': articulo_actual['numero'],
            'titulo': titulo,
            'contenido': limpiar_texto(contenido_completo),
            'es_derogado': es_derogado
        })
    
    return articulos

def parsear_lopnna(txt_path):
    """Procesa LOPNNA.txt con lógica especializada"""
    
    print("=" * 80)
    print("📝 PARSER LOPNNA - Especializado")
    print("=" * 80)
    
    codigo = txt_path.stem
    
    # Leer texto
    with open(txt_path, 'r', encoding='utf-8') as f:
        texto = f.read()
    
    print(f"\n📚 {codigo}")
    print(f"   📄 Texto: {len(texto):,} caracteres")
    
    # Extraer artículos con regex especializado
    articulos = extraer_articulos_lopnna(texto)
    
    print(f"   ✅ Artículos extraídos: {len(articulos)}")
    
    # Verificar rango esperado
    if articulos:
        primero = articulos[0]['numero']
        ultimo = articulos[-1]['numero']
        print(f"   📊 Rango: Artículo {primero} → Artículo {ultimo}")
    
    # Contar artículos con letras
    con_letra = [a for a in articulos if '-' in a['numero']]
    print(f"   🔤 Artículos con letra: {len(con_letra)}")
    if con_letra:
        print(f"      Ejemplos: {', '.join([a['numero'] for a in con_letra[:5]])}")
    
    # Contar derogados
    derogados = [a for a in articulos if a.get('es_derogado', False)]
    print(f"   ❌ Artículos derogados: {len(derogados)}")
    if derogados and len(derogados) <= 20:
        print(f"      Lista: {', '.join([a['numero'] for a in derogados])}")
    
    # Contar vigentes
    vigentes = [a for a in articulos if not a.get('es_derogado', False)]
    print(f"   ✅ Artículos vigentes: {len(vigentes)}")
    
    # Metadata
    derogados = [a for a in articulos if a.get('es_derogado', False)]
    vigentes = [a for a in articulos if not a.get('es_derogado', False)]
    con_letra = [a for a in articulos if '-' in a['numero']]
    
    ley_data = {
        'codigo': codigo,
        'num_articulos': len(articulos),
        'num_articulos_vigentes': len(vigentes),
        'num_articulos_derogados': len(derogados),
        'caracteres_totales': len(texto),
        'tiene_articulos_letrados': len(con_letra) > 0,
        'articulos_letrados': [a['numero'] for a in con_letra],
        'articulos_derogados': [a['numero'] for a in derogados],
        'articulos': articulos
    }
    
    # Guardar JSON
    output_dir = Path("tools/data/leyes/estructurado")
    output_dir.mkdir(parents=True, exist_ok=True)
    output_path = output_dir / f"{codigo}.json"
    
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(ley_data, f, ensure_ascii=False, indent=2)
    
    print(f"   💾 Guardado: {output_path}")
    
    print("\n" + "=" * 80)
    print("✅ PROCESAMIENTO COMPLETADO")
    print("=" * 80)
    
    return ley_data

if __name__ == "__main__":
    txt_path = Path("tools/data/leyes/textos/LOPNNA.txt")
    
    if not txt_path.exists():
        print(f"❌ Error: No se encontró {txt_path}")
        exit(1)
    
    resultado = parsear_lopnna(txt_path)
    
    print(f"\n📊 Resultado final:")
    print(f"   Artículos totales: {resultado['num_articulos']}")
    print(f"   Artículos vigentes: {resultado['num_articulos_vigentes']}")
    print(f"   Artículos derogados: {resultado['num_articulos_derogados']}")
    print(f"   Artículos con letra: {len(resultado['articulos_letrados'])}")
    
    # Validación: estructura esperada de LOPNNA
    # - Artículos 1-685 con algunos derogados
    # - Artículos letrados: 683-A, 683-B, 683-C (3 artículos)
    # - Total artículos (incluyendo derogados): aproximadamente 688
    
    if resultado['num_articulos'] >= 685:
        print("\n   ✅ PERFECTO: Estructura completa capturada")
        print(f"   ✅ Artículos letrados encontrados: {', '.join(resultado['articulos_letrados'])}")
    else:
        diferencia = 688 - resultado['num_articulos']
        print(f"\n   ⚠️  Diferencia: {diferencia:+d} artículos")
        print("   ℹ️  Revisar si hay más artículos letrados o formato especial")
