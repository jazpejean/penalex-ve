import json
import re

def parsear_ley(texto_completo):
    # Dividir en líneas
    lineas = texto_completo.splitlines()
    
    # Estructura principal
    ley = {
        "nombre": "Ley Orgánica para la Protección de Niños, Niñas y Adolescentes",
        "exposicion_motivos": "",
        "titulos": [],
        "disposiciones_transitorias": [],
        "disposiciones_finales": []
    }
    
    # Variables de estado
    titulo_actual = None
    capitulo_actual = None
    seccion_actual = None
    articulo_actual = None
    estado = "INICIO"  # Puede ser: INICIO, EXPOSICION, TITULO, CAPITULO, SECCION, ARTICULO
    buffer_texto = ""
    in_exposicion = False
    in_transitorias = False
    in_finales = False
    
    # Patrones
    patron_titulo = re.compile(r'^TÍTULO\s+([IVXLCDM]+)\s*[–\-]?\s*(.*)$', re.IGNORECASE)
    patron_capitulo = re.compile(r'^CAPÍTULO\s+([IVXLCDM]+)\s*[–\-]?\s*(.*)$', re.IGNORECASE)
    patron_seccion = re.compile(r'^SECCIÓN\s+(PRIMERA|SEGUNDA|TERCERA|CUARTA|QUINTA|SEXTA|SÉPTIMA|OCTAVA|NOVENA|DÉCIMA|UNDÉCIMA|DUODÉCIMA|DÉCIMO\s+\w+|ÚNICA)\s*[–\-]?\s*(.*)$', re.IGNORECASE)
    patron_articulo = re.compile(r'^ARTÍCULO\s+(\d+[A-Z]?\.?)\s*[–\-]?\s*(.*)$', re.IGNORECASE)
    patron_derogado = re.compile(r'DEROGADO', re.IGNORECASE)
    patron_parrafo = re.compile(r'^Parágrafo\s+(Primero|Segundo|Tercero|Cuarto|Quinto|Único)\s*[:.]?\s*(.*)$', re.IGNORECASE)
    patron_literal = re.compile(r'^([a-z])\)\s*(.*)$')
    
    def limpiar(linea):
        # Eliminar caracteres de control y basura al inicio
        linea = re.sub(r'^[^\w\s]+\s*', '', linea)
        return linea.strip()
    
    def guardar_articulo():
        nonlocal articulo_actual, seccion_actual, capitulo_actual
        if articulo_actual:
            # Si hay sección, agregar a la sección
            if seccion_actual:
                seccion_actual["articulos"].append(articulo_actual)
            # Si no hay sección pero hay capítulo, agregar directamente al capítulo
            elif capitulo_actual:
                if "articulos" not in capitulo_actual:
                    capitulo_actual["articulos"] = []
                capitulo_actual["articulos"].append(articulo_actual)
            # Si no hay capítulo (raro), agregar al título o raíz
            else:
                # Fallback: agregar al último contenedor disponible
                pass
            articulo_actual = None
    
    for linea_raw in lineas:
        linea = limpiar(linea_raw)
        if not linea:
            continue
        
        # --- DETECTAR SECCIONES ESPECIALES ---
        if re.search(r'EXPOSICIÓN DE MOTIVOS', linea, re.IGNORECASE):
            in_exposicion = True
            continue
        if re.search(r'DISPOSICIONES TRANSITORIAS', linea, re.IGNORECASE):
            in_transitorias = True
            in_exposicion = False
            continue
        if re.search(r'DISPOSICIONES FINALES', linea, re.IGNORECASE):
            in_finales = True
            in_transitorias = False
            continue
        
        if in_exposicion:
            ley["exposicion_motivos"] += linea + " "
            continue
        if in_transitorias:
            ley["disposiciones_transitorias"].append(linea)
            continue
        if in_finales:
            ley["disposiciones_finales"].append(linea)
            continue
        
        # --- DETECTAR TÍTULO ---
        m_titulo = patron_titulo.match(linea)
        if m_titulo:
            guardar_articulo()  # Guardar el artículo actual si existe
            num = m_titulo.group(1)
            nom = m_titulo.group(2)
            titulo_actual = {
                "numero": num,
                "nombre": nom,
                "capitulos": []
            }
            ley["titulos"].append(titulo_actual)
            capitulo_actual = None
            seccion_actual = None
            continue
        
        # --- DETECTAR CAPÍTULO ---
        m_capitulo = patron_capitulo.match(linea)
        if m_capitulo:
            guardar_articulo()
            if titulo_actual is None:
                # Si no hay título, crear uno genérico (no debería pasar)
                titulo_actual = {"numero": "0", "nombre": "Sin título", "capitulos": []}
                ley["titulos"].append(titulo_actual)
            num = m_capitulo.group(1)
            nom = m_capitulo.group(2)
            capitulo_actual = {
                "numero": num,
                "nombre": nom,
                "secciones": []
            }
            titulo_actual["capitulos"].append(capitulo_actual)
            seccion_actual = None
            continue
        
        # --- DETECTAR SECCIÓN ---
        m_seccion = patron_seccion.match(linea)
        if m_seccion:
            guardar_articulo()
            if capitulo_actual is None:
                # Si no hay capítulo, crear uno genérico dentro del título actual
                if titulo_actual is None:
                    titulo_actual = {"numero": "0", "nombre": "Sin título", "capitulos": []}
                    ley["titulos"].append(titulo_actual)
                capitulo_actual = {"numero": "0", "nombre": "Sin capítulo", "secciones": []}
                titulo_actual["capitulos"].append(capitulo_actual)
            nom = m_seccion.group(1) + (" " + m_seccion.group(2) if m_seccion.group(2) else "")
            seccion_actual = {
                "nombre": nom,
                "articulos": []
            }
            capitulo_actual["secciones"].append(seccion_actual)
            continue
        
        # --- DETECTAR ARTÍCULO ---
        m_articulo = patron_articulo.match(linea)
        if m_articulo:
            guardar_articulo()
            num = m_articulo.group(1).rstrip('.')
            nom = m_articulo.group(2)
            # Si no hay sección, y no hay capítulo, crear capítulo y sección por defecto
            if capitulo_actual is None:
                if titulo_actual is None:
                    titulo_actual = {"numero": "0", "nombre": "Sin título", "capitulos": []}
                    ley["titulos"].append(titulo_actual)
                capitulo_actual = {"numero": "0", "nombre": "Sin capítulo", "secciones": []}
                titulo_actual["capitulos"].append(capitulo_actual)
            # Si no hay sección, crear una sección genérica dentro del capítulo actual
            if seccion_actual is None:
                seccion_actual = {"nombre": "Sección única", "articulos": []}
                capitulo_actual["secciones"].append(seccion_actual)
            
            if patron_derogado.search(linea):
                articulo_actual = {
                    "numero": num,
                    "titulo": "DEROGADO",
                    "contenido": "Artículo derogado.",
                    "parrafos": [],
                    "literales": []
                }
            else:
                articulo_actual = {
                    "numero": num,
                    "titulo": nom,
                    "contenido": "",
                    "parrafos": [],
                    "literales": []
                }
            continue
        
        # --- DENTRO DE UN ARTÍCULO ---
        if articulo_actual:
            m_parrafo = patron_parrafo.match(linea)
            if m_parrafo:
                tipo_parr = m_parrafo.group(1)
                texto_parr = m_parrafo.group(2)
                articulo_actual["parrafos"].append({
                    "tipo": "Parágrafo",
                    "nombre": tipo_parr,
                    "texto": texto_parr
                })
                continue
            
            m_literal = patron_literal.match(linea)
            if m_literal:
                letra = m_literal.group(1)
                texto_lit = m_literal.group(2)
                articulo_actual["literales"].append({
                    "letra": letra,
                    "texto": texto_lit
                })
                continue
            
            # Texto normal del artículo
            if articulo_actual["contenido"]:
                articulo_actual["contenido"] += " " + linea
            else:
                articulo_actual["contenido"] = linea
    
    # Al final, guardar el último artículo si existe
    guardar_articulo()
    
    return ley


if __name__ == "__main__":
    # Leer el archivo de texto (asegúrate de que se llame 'LOPNNA.txt' y esté en el directorio)
    with open("LOPNNA.txt", "r", encoding="utf-8") as f:
        texto = f.read()
    
    # Parsear
    resultado = parsear_ley(texto)
    
    # Guardar JSON
    with open("LOPNNA_estructurada.json", "w", encoding="utf-8") as f:
        json.dump(resultado, f, indent=2, ensure_ascii=False)
    
    # Contar artículos para validar
    def contar_articulos(objeto):
        count = 0
        if isinstance(objeto, dict):
            if "articulos" in objeto:
                count += len(objeto["articulos"])
            for clave, valor in objeto.items():
                if isinstance(valor, list):
                    for item in valor:
                        count += contar_articulos(item)
                elif isinstance(valor, dict):
                    count += contar_articulos(valor)
        return count
    
    total = contar_articulos(resultado)
    print(f"✅ JSON generado correctamente. Total de artículos procesados: {total}")
