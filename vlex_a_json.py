#!/usr/bin/env python3
"""Convierte HTML de vLex a JSON estructurado para Penalex_VE."""
import json, re, sys
from pathlib import Path
from bs4 import BeautifulSoup

def parsear_articulo(section):
    """Extrae un artículo de una <section class="article">."""
    num = section.get("data-article-number", "?")
    
    parrafos = []
    intro = None
    items = []
    paragrafos = []
    
    for child in section.children:
        if not hasattr(child, 'name') or child.name is None:
            continue
        if child.name == 'header' or (child.name == 'aside' and 'cited_by' in child.get('class', [])):
            continue
        
        if child.name in ('ol', 'ul'):
            # Numerales
            for li in child.find_all('li', recursive=False):
                val = li.get('value', '')
                texto = li.get_text(' ', strip=True)
                # Limpiar spans highlighted
                items.append({"numero": int(val) if val and val.isdigit() else val, "texto": texto})
            # El último párrafo antes de la lista es el intro
            if parrafos and not intro:
                intro = parrafos.pop()
        
        elif child.name == 'p':
            texto = child.get_text(' ', strip=True)
            if not texto:
                continue
            # Detectar parágrafos
            if re.match(r'^Par[aá]grafo\b', texto, re.I):
                m = re.match(r'^(Par[aá]grafo\s+\w+):?\s*(.*)', texto, re.I | re.DOTALL)
                if m:
                    paragrafos.append({"tipo": m.group(1).strip(), "texto": m.group(2).strip()})
                else:
                    paragrafos.append({"tipo": "Parágrafo", "texto": texto})
            else:
                parrafos.append(texto)
    
    art = {"numero": str(num)}
    
    if items:
        art["intro"] = intro or ""
        art["items"] = items
        if parrafos:
            art["parrafos_finales"] = parrafos
    else:
        art["contenido"] = "\n\n".join(parrafos)
    
    if paragrafos:
        art["paragrafos"] = paragrafos
    
    return art


def parsear_seccion(section, nivel=0):
    """Parsea recursivamente secciones (libros, títulos, capítulos)."""
    header = section.find('header', recursive=False)
    
    nombre = ""
    numero = ""
    if header:
        h1 = header.find('h1')
        h2 = header.find('h2')
        if h1:
            texto_h1 = h1.get_text(strip=True)
            # Extraer número de "LIBRO PRIMERO", "TÍTULO I", "CAPÍTULO II", etc.
            m = re.match(r'(?:LIBRO|T[IÍ]TULO|CAP[IÍ]TULO|SECCI[OÓ]N)\s+(.*)', texto_h1, re.I)
            if m:
                numero = m.group(1).strip()
            else:
                numero = texto_h1
        if h2:
            nombre = h2.get_text(strip=True)
    
    # Determinar tipo
    section_level = section.get('data-section-level', '')
    tipo_map = {'1': 'titulo', '2': 'titulo', '3': 'capitulo'}
    tipo = tipo_map.get(section_level, f'seccion_nivel_{section_level}' if section_level else 'seccion')
    
    # Detectar tipo por texto del h1
    if header:
        h1_text = header.find('h1').get_text(strip=True).upper() if header.find('h1') else ''
        if 'LIBRO' in h1_text:
            tipo = 'libro'
        elif 'TÍTULO' in h1_text or 'TITULO' in h1_text:
            tipo = 'titulo'
        elif 'CAPÍTULO' in h1_text or 'CAPITULO' in h1_text:
            tipo = 'capitulo'
        elif 'SECCIÓN' in h1_text or 'SECCION' in h1_text:
            tipo = 'seccion'
    
    nodo = {
        "tipo": tipo,
        "numero": numero,
        "nombre": nombre,
    }
    
    # Rangos de artículos
    art_min = section.get('data-article-number-min')
    art_max = section.get('data-article-number-max')
    if art_min:
        nodo["articuloDesde"] = int(art_min)
    if art_max:
        nodo["articuloHasta"] = int(art_max)
    
    hijos = []
    articulos = []
    preambulo_parrafos = []
    
    for child in section.children:
        if not hasattr(child, 'name') or child.name is None:
            continue
        
        if child.name == 'section':
            classes = child.get('class', [])
            if 'article' in classes:
                articulos.append(parsear_articulo(child))
            elif 'section' in classes:
                hijos.append(parsear_seccion(child, nivel + 1))
        elif child.name == 'p' and not articulos and not hijos:
            # Párrafos sueltos (preámbulo, disposiciones, etc.)
            texto = child.get_text(' ', strip=True)
            if texto:
                preambulo_parrafos.append(texto)
    
    if hijos:
        nodo["hijos"] = hijos
    if articulos:
        nodo["articulos"] = articulos
    if preambulo_parrafos:
        nodo["texto"] = "\n\n".join(preambulo_parrafos)
    
    return nodo


def convertir(ruta_html, nombre_ley=None, nombre_corto=None, output=None):
    """Convierte un HTML de vLex a JSON estructurado."""
    ruta = Path(ruta_html)
    if not ruta.exists():
        print(f"❌ No se encontró: {ruta}")
        return
    
    print(f"📄 Procesando: {ruta.name}")
    
    html = ruta.read_text(encoding='utf-8', errors='replace')
    soup = BeautifulSoup(html, 'html.parser')
    
    # Buscar todas las secciones de nivel superior
    secciones_raiz = soup.find_all('section', class_='section', recursive=False)
    
    if not secciones_raiz:
        # Si no hay secciones raíz directas, buscar en todo el documento
        secciones_raiz = soup.find_all('section', attrs={'data-section-level': '1'})
    
    if not secciones_raiz:
        # Último intento: todas las secciones con class="section"
        secciones_raiz = [s for s in soup.find_all('section', class_='section') 
                          if s.parent.name in ('body', 'div', 'html', '[document]') or s.parent == soup]
    
    estructura = []
    for sec in secciones_raiz:
        estructura.append(parsear_seccion(sec))
    
    # Contar artículos
    total_arts = sum(1 for _ in soup.find_all('section', class_='article'))
    
    # Detectar nombre si no se proporcionó
    if not nombre_ley:
        # Intentar del primer h1 o del nombre del archivo
        nombre_ley = ruta.stem.replace('_', ' ').replace('online viewer net', '').strip()
        if not nombre_ley or nombre_ley.startswith('('):
            nombre_ley = "Ley sin nombre"
    
    resultado = {
        "id": (nombre_corto or nombre_ley).lower().replace(' ', '_'),
        "nombre": nombre_ley,
        "nombreCorto": nombre_corto or "",
        "totalArticulos": total_arts,
        "estructura": estructura,
    }
    
    # Guardar
    salida = Path(output) if output else ruta.with_suffix('.json')
    salida.write_text(json.dumps(resultado, ensure_ascii=False, indent=2), encoding='utf-8')
    
    print(f"✅ {total_arts} artículos → {salida.name}")
    return resultado


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Uso: python3 vlex_a_json.py archivo.html [--nombre 'Código Penal'] [--corto CP] [--output salida.json]")
        print("\nEjemplos:")
        print('  python3 vlex_a_json.py "online_viewer_net (11).html" --nombre "Código Penal" --corto CP')
        print('  python3 vlex_a_json.py constitucion.html --nombre "CRBV" --corto CRBV')
        sys.exit(1)
    
    archivo = sys.argv[1]
    nombre = None
    corto = None
    output = None
    
    i = 2
    while i < len(sys.argv):
        if sys.argv[i] == '--nombre' and i + 1 < len(sys.argv):
            nombre = sys.argv[i + 1]; i += 2
        elif sys.argv[i] == '--corto' and i + 1 < len(sys.argv):
            corto = sys.argv[i + 1]; i += 2
        elif sys.argv[i] == '--output' and i + 1 < len(sys.argv):
            output = sys.argv[i + 1]; i += 2
        else:
            i += 1
    
    convertir(archivo, nombre, corto, output)
