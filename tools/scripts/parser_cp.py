#!/usr/bin/env python3
r"""
Parser especializado para CP (Código Penal)

PROBLEMA DETECTADO:
- Títulos de jerarquía (LIBRO, TÍTULO, CAPÍTULO) están en múltiples líneas
- Parser general solo captura primera línea, truncando el título completo

ESTRUCTURA CP:
- LIBRO PRIMERO / SEGUNDO / TERCERO
- TÍTULO I, II, III...
- CAPÍTULO I, II, III...
- Artículo 1, 2, 3... (546 artículos)

SOLUCIÓN:
- Detectar inicio de título de jerarquía
- Capturar líneas siguientes hasta encontrar próximo elemento estructural
- Consolidar título completo antes de parsear artículos
"""
import re
import json
from pathlib import Path

def limpiar_texto(texto):
    """Limpia el texto extraído"""
    texto = re.sub(r'\n{3,}', '\n\n', texto)
    texto = re.sub(r' {2,}', ' ', texto)
    return texto.strip()

def extraer_estructura_cp(texto):
    """
    Extrae estructura jerárquica del Código Penal
    
    Jerarquía:
    1. LIBRO PRIMERO/SEGUNDO/TERCERO
    2. TÍTULO I/II/III
    3. CAPÍTULO I/II/III  
    4. Artículo 1/2/3
    
    El problema: títulos pueden estar en múltiples líneas
    """
    articulos = []
    
    # Procesar línea por línea
    lineas = texto.split('\n')
    
    # Estado del parser
    libro_actual = None
    titulo_actual = None
    capitulo_actual = None
    articulo_actual = None
    contenido_actual = []
    
    # Patterns
    patron_libro = r'^LIBRO\s+(PRIMERO|SEGUNDO|TERCERO|CUARTO|[IVX]+)'
    patron_titulo = r'^TÍTULO\s+([IVX]+|[0-9]+)'
    patron_capitulo = r'^CAPÍTULO\s+([IVX]+|[0-9]+)'
    patron_articulo = r'^Artículo\s+(\d+)[°º]?\.?\s*(.*)$'
    
    i = 0
    while i < len(lineas):
        linea = lineas[i].strip()
        
        # LIBRO (puede tener título multi-línea)
        if re.match(patron_libro, linea):
            libro_match = re.match(patron_libro, linea)
            libro_num = libro_match.group(1)
            
            # Capturar título del libro (puede estar en líneas siguientes)
            titulo_libro = linea
            j = i + 1
            while j < len(lineas) and j < i + 5:  # Máximo 5 líneas
                siguiente = lineas[j].strip()
                # Si es otro elemento estructural, parar
                if re.match(patron_titulo, siguiente) or \
                   re.match(patron_capitulo, siguiente) or \
                   re.match(patron_articulo, siguiente) or \
                   re.match(patron_libro, siguiente):
                    break
                # Si es texto descriptivo, agregarlo
                if siguiente and not siguiente.isupper():
                    break
                if siguiente:
                    titulo_libro += " " + siguiente
                j += 1
            
            libro_actual = {
                'tipo': 'LIBRO',
                'numero': libro_num,
                'titulo': titulo_libro.strip()
            }
            i = j - 1
        
        # TÍTULO (puede tener título multi-línea)
        elif re.match(patron_titulo, linea):
            titulo_match = re.match(patron_titulo, linea)
            titulo_num = titulo_match.group(1)
            
            # Capturar título completo
            titulo_completo = linea
            j = i + 1
            while j < len(lineas) and j < i + 5:
                siguiente = lineas[j].strip()
                if re.match(patron_capitulo, siguiente) or \
                   re.match(patron_articulo, siguiente) or \
                   re.match(patron_titulo, siguiente) or \
                   re.match(patron_libro, siguiente):
                    break
                if siguiente and siguiente[0].islower():  # Línea continuación
                    titulo_completo += " " + siguiente
                elif siguiente and len(siguiente) > 3:  # Otra línea del título
                    titulo_completo += " " + siguiente
                j += 1
            
            titulo_actual = {
                'tipo': 'TITULO',
                'numero': titulo_num,
                'titulo': titulo_completo.strip()
            }
            i = j - 1
        
        # CAPÍTULO (puede tener título multi-línea)
        elif re.match(patron_capitulo, linea):
            capitulo_match = re.match(patron_capitulo, linea)
            capitulo_num = capitulo_match.group(1)
            
            # Capturar título completo
            capitulo_completo = linea
            j = i + 1
            while j < len(lineas) and j < i + 5:
                siguiente = lineas[j].strip()
                if re.match(patron_articulo, siguiente) or \
                   re.match(patron_capitulo, siguiente) or \
                   re.match(patron_titulo, siguiente) or \
                   re.match(patron_libro, siguiente):
                    break
                if siguiente and siguiente[0].islower():
                    capitulo_completo += " " + siguiente
                elif siguiente and len(siguiente) > 3:
                    capitulo_completo += " " + siguiente
                j += 1
            
            capitulo_actual = {
                'tipo': 'CAPITULO',
                'numero': capitulo_num,
                'titulo': capitulo_completo.strip()
            }
            i = j - 1
        
        # ARTÍCULO
        elif re.match(patron_articulo, linea):
            # Guardar artículo anterior
            if articulo_actual:
                articulos.append({
                    'numero': articulo_actual['numero'],
                    'titulo': articulo_actual['titulo'],
                    'contenido': limpiar_texto('\n'.join(contenido_actual)),
                    'libro': libro_actual['titulo'] if libro_actual else None,
                    'titulo_seccion': titulo_actual['titulo'] if titulo_actual else None,
                    'capitulo': capitulo_actual['titulo'] if capitulo_actual else None
                })
            
            # Nuevo artículo
            art_match = re.match(patron_articulo, linea)
            articulo_actual = {
                'numero': art_match.group(1),
                'titulo': art_match.group(2).strip()
            }
            contenido_actual = []
        
        # Contenido del artículo
        else:
            if articulo_actual and linea:
                contenido_actual.append(linea)
        
        i += 1
    
    # No olvidar último artículo
    if articulo_actual:
        articulos.append({
            'numero': articulo_actual['numero'],
            'titulo': articulo_actual['titulo'],
            'contenido': limpiar_texto('\n'.join(contenido_actual)),
            'libro': libro_actual['titulo'] if libro_actual else None,
            'titulo_seccion': titulo_actual['titulo'] if titulo_actual else None,
            'capitulo': capitulo_actual['titulo'] if capitulo_actual else None
        })
    
    return articulos

def parsear_cp(txt_path):
    """Procesa CP.txt con lógica especializada"""
    
    print("=" * 80)
    print("📝 PARSER CP - Especializado")
    print("=" * 80)
    
    codigo = txt_path.stem
    
    # Leer texto
    with open(txt_path, 'r', encoding='utf-8') as f:
        texto = f.read()
    
    print(f"\n📚 {codigo}")
    print(f"   📄 Texto: {len(texto):,} caracteres")
    
    # Extraer artículos con jerarquía
    articulos = extraer_estructura_cp(texto)
    
    print(f"   ✅ Artículos extraídos: {len(articulos)}")
    
    if articulos:
        primero = articulos[0]['numero']
        ultimo = articulos[-1]['numero']
        print(f"   📊 Rango: Artículo {primero} → Artículo {ultimo}")
    
    # Verificar títulos multi-línea capturados
    con_jerarquia = [a for a in articulos if a.get('libro') or a.get('titulo_seccion') or a.get('capitulo')]
    print(f"   🏛️  Artículos con jerarquía: {len(con_jerarquia)}")
    
    # Metadata
    ley_data = {
        'codigo': codigo,
        'num_articulos': len(articulos),
        'caracteres_totales': len(texto),
        'tiene_jerarquia': len(con_jerarquia) > 0,
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
    txt_path = Path("tools/data/leyes/textos/CP.txt")
    
    if not txt_path.exists():
        print(f"❌ Error: No se encontró {txt_path}")
        exit(1)
    
    resultado = parsear_cp(txt_path)
    
    print(f"\n📊 Resultado final:")
    print(f"   Artículos totales: {resultado['num_articulos']}")
    print(f"   Con jerarquía: {resultado['tiene_jerarquia']}")
    print(f"   Esperado: 546 artículos")
    
    if resultado['num_articulos'] == 546:
        print("\n   ✅ PERFECTO: Cantidad exacta alcanzada")
    else:
        diferencia = 546 - resultado['num_articulos']
        print(f"\n   ⚠️  Diferencia: {diferencia:+d} artículos")
