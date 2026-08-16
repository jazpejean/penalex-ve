#!/usr/bin/env python3
"""
Parser Inteligente de Leyes Venezolanas
Detecta automáticamente: LIBRO → TÍTULO → CAPÍTULO → SECCIÓN → Artículo
"""
import re
import json
from pathlib import Path
from collections import defaultdict

TXT_DIR = Path("tools/data/leyes/textos")
OUTPUT_DIR = Path("tools/data/leyes/estructurado")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

print("=" * 80)
print("🧠 PARSER INTELIGENTE - LEYES VENEZOLANAS")
print("=" * 80)

# Mapeo de nombres de leyes
NOMBRES_LEYES = {
    'CRBV': 'Constitución de la República Bolivariana de Venezuela',
    'CP': 'Código Penal',
    'COPP': 'Código Orgánico Procesal Penal',
    'LOA': 'Ley Orgánica de Amparo sobre Derechos y Garantías Constitucionales',
    'LOSDMVLV': 'Ley Orgánica sobre el Derecho de las Mujeres a una Vida Libre de Violencia',
    'LOD': 'Ley Orgánica de Drogas',
    'LCDOFT': 'Ley Orgánica contra la Delincuencia Organizada y Financiamiento al Terrorismo',
    'LCSE': 'Ley Contra el Secuestro y la Extorsión',
    'LHRVA': 'Ley sobre Hurto y Robo de Vehículos Automotores',
    'LDCAM': 'Ley de Armas y Explosivos',
    'LPVT': 'Ley de Protección de Víctimas, Testigos y demás Sujetos Procesales',
    'LECDI': 'Ley Especial contra los Delitos Informáticos',
    'LOPNNA': 'Ley Orgánica para la Protección de Niños, Niñas y Adolescentes',
    'LOCC': 'Ley Orgánica contra la Corrupción',
    'CEA': 'Código de Ética Profesional del Abogado Venezolano',
    'COP': 'Código Orgánico Penitenciario'
}

class ParserLey:
    """Parser inteligente para diferentes estructuras de leyes"""
    
    def __init__(self, texto, codigo):
        self.texto = texto
        self.codigo = codigo
        self.lineas = texto.split('\n')
        
    def limpiar_texto(self, texto):
        """Limpia espacios y saltos de línea"""
        texto = re.sub(r'\s+', ' ', texto)
        return texto.strip()
    
    def detectar_numero(self, texto):
        """Detecta números romanos o arábigos"""
        # Romanos
        romanos = r'\b(I{1,3}|IV|V|VI{0,3}|IX|X{1,3}|XL|L|LX{0,3}|XC|C{1,3})\b'
        if re.search(romanos, texto, re.IGNORECASE):
            match = re.search(romanos, texto, re.IGNORECASE)
            return match.group(1).upper()
        
        # Arábigos
        arabigo = re.search(r'\b(\d+)[°ºª]?\b', texto)
        if arabigo:
            return arabigo.group(1)
        
        # Único
        if re.search(r'\bÚNICO\b', texto, re.IGNORECASE):
            return 'ÚNICO'
        
        return None
    
    def extraer_secciones(self):
        """Extrae jerarquía de secciones"""
        secciones = []
        seccion_actual = None
        nivel_stack = []  # Stack para mantener jerarquía
        orden = 0
        
        # Patrones para detectar secciones
        patrones = [
            (r'^LIBRO\s+(PRIMERO|SEGUNDO|TERCERO|CUARTO|I{1,3}|IV|V|I?VI{0,3}|IX|X|\d+)', 'LIBRO', 1),
            (r'^TÍTULO\s+(PRIMERO|SEGUNDO|TERCERO|I{1,3}|IV|V|I?VI{0,3}|IX|X|\d+)', 'TITULO', 2),
            (r'^CAPÍTULO\s+(PRIMERO|SEGUNDO|TERCERO|ÚNICO|I{1,3}|IV|V|I?VI{0,3}|IX|X|\d+)', 'CAPITULO', 3),
            (r'^SECCIÓN\s+(PRIMERA|SEGUNDA|TERCERA|ÚNICA|I{1,3}|IV|V|I?VI{0,3}|IX|X|\d+)', 'SECCION', 4),
        ]
        
        for i, linea in enumerate(self.lineas):
            linea_limpia = self.limpiar_texto(linea)
            
            if not linea_limpia:
                continue
            
            # Buscar coincidencias con patrones
            for patron, tipo, nivel in patrones:
                match = re.match(patron, linea_limpia, re.IGNORECASE)
                
                if match:
                    orden += 1
                    numero = self.detectar_numero(linea_limpia)
                    
                    # Extraer título (siguiente línea o resto de la línea)
                    titulo = re.sub(patron, '', linea_limpia, flags=re.IGNORECASE).strip()
                    if not titulo and i + 1 < len(self.lineas):
                        titulo = self.limpiar_texto(self.lineas[i + 1])
                    
                    # Limpiar título de caracteres especiales
                    titulo = re.sub(r'^[:\-–—]\s*', '', titulo)
                    titulo = self.limpiar_texto(titulo)
                    
                    # Determinar parent_id según jerarquía
                    parent_id = None
                    
                    # Limpiar stack de niveles superiores o iguales
                    nivel_stack = [s for s in nivel_stack if s['nivel'] < nivel]
                    
                    # El parent es el último del stack
                    if nivel_stack:
                        parent_id = nivel_stack[-1]['id']
                    
                    seccion = {
                        'id': f"{self.codigo}_S{orden}",
                        'parent_id': parent_id,
                        'tipo': tipo,
                        'numero': numero,
                        'titulo': titulo[:200] if titulo else f"{tipo} {numero}",
                        'nivel': nivel,
                        'orden': orden
                    }
                    
                    secciones.append(seccion)
                    nivel_stack.append({'id': seccion['id'], 'nivel': nivel})
                    break
        
        return secciones
    
    def extraer_articulos(self, secciones):
        """Extrae artículos y los asocia a secciones"""
        articulos = []
        articulos_vistos = set()  # Para evitar duplicados
        
        # PASO 1: Limpiar formato roto (número en línea separada)
        # "Artículo\n1\n." → "Artículo 1."
        texto_limpio = re.sub(
            r'(Artículo|Art\.?)\s*\n+\s*(\d+(?:-[A-Z])?)\s*\n+\s*\.?',
            r'\1 \2.',
            self.texto,
            flags=re.IGNORECASE
        )
        
        # PASO 2: Patrón ESTRICTO para capturar artículos
        # Solo al inicio de línea o después de \n\n
        # Captura: Artículo 1, Artículo 1., Artículo 493-A, etc.
        patron_articulo = r'(?:^|\n\n)[ \t]*(Artículo|Art\.?)\s+(\d+(?:-[A-Z])?|ÚNICO)[°º]?\.?\s*[-–—]?\s*'
        
        matches = list(re.finditer(patron_articulo, texto_limpio, re.MULTILINE | re.IGNORECASE))
        
        if not matches:
            print(f"   ⚠️  No se detectaron artículos con patrón estricto")
            return self.extraer_articulos_alternativos()
        
        print(f"   ✅ Patrón estricto detectado: {len(matches)} coincidencias")
        
        # Crear índice de posiciones de secciones
        secciones_pos = []
        for seccion in secciones:
            # Buscar posición aproximada de la sección en el texto
            patron_seccion = re.escape(seccion['titulo'][:50])
            match_seccion = re.search(patron_seccion, self.texto, re.IGNORECASE)
            if match_seccion:
                secciones_pos.append({
                    'id': seccion['id'],
                    'pos': match_seccion.start()
                })
        
        # Ordenar secciones por posición
        secciones_pos.sort(key=lambda x: x['pos'])
        
        for i, match in enumerate(matches):
            numero = match.group(2)  # Ahora el grupo 2 tiene el número
            
            # Evitar duplicados
            if numero in articulos_vistos:
                continue
            articulos_vistos.add(numero)
            
            # Capturar contenido hasta el siguiente artículo
            inicio = match.end()
            fin = matches[i + 1].start() if i + 1 < len(matches) else len(texto_limpio)
            contenido = texto_limpio[inicio:fin]
            
            # Limpiar contenido
            contenido = self.limpiar_texto(contenido)
            
            # Limitar tamaño (máx 8000 caracteres por artículo)
            if len(contenido) > 8000:
                contenido = contenido[:8000] + " [...]"
            
            # Si el contenido es muy corto, puede ser error (mínimo 20 caracteres)
            if len(contenido) < 20:
                articulos_vistos.remove(numero)  # Liberar para siguiente intento
                continue
            
            # Detectar título del artículo (primera línea si está en mayúsculas o negrita)
            titulo = None
            primera_linea = contenido.split('.')[0] if '.' in contenido else None
            if primera_linea and len(primera_linea) < 100:
                if primera_linea.isupper() or primera_linea[0].isupper():
                    titulo = primera_linea.strip()
            
            # Determinar a qué sección pertenece
            seccion_id = None
            pos_articulo = match.start()
            
            for j in range(len(secciones_pos) - 1, -1, -1):
                if pos_articulo >= secciones_pos[j]['pos']:
                    seccion_id = secciones_pos[j]['id']
                    break
            
            # Extraer keywords simples
            keywords = self.extraer_keywords(contenido)
            
            articulo = {
                'numero': numero,
                'titulo': titulo,
                'contenido': contenido,
                'seccion_id': seccion_id,
                'orden': i + 1,
                'keywords': keywords
            }
            
            articulos.append(articulo)
        
        return articulos
    
    def extraer_articulos_alternativos(self):
        """Extracción alternativa cuando no hay patrón estándar"""
        articulos = []
        parrafos = [p.strip() for p in self.texto.split('\n\n') if len(p.strip()) > 100]
        
        for i, parrafo in enumerate(parrafos[:200], 1):
            contenido = self.limpiar_texto(parrafo)
            if len(contenido) > 5000:
                contenido = contenido[:5000] + "..."
            
            articulos.append({
                'numero': str(i),
                'titulo': None,
                'contenido': contenido,
                'seccion_id': None,
                'orden': i,
                'keywords': self.extraer_keywords(contenido)
            })
        
        return articulos
    
    def extraer_keywords(self, texto):
        """Extrae palabras clave simples"""
        # Palabras comunes a ignorar
        stopwords = {'el', 'la', 'de', 'que', 'en', 'los', 'las', 'del', 'al', 'por', 'para', 'con', 'una', 'un'}
        
        # Extraer palabras de más de 5 letras
        palabras = re.findall(r'\b[a-záéíóúñ]{6,}\b', texto.lower())
        
        # Contar frecuencia
        freq = defaultdict(int)
        for palabra in palabras:
            if palabra not in stopwords:
                freq[palabra] += 1
        
        # Top 5 más frecuentes
        top_keywords = sorted(freq.items(), key=lambda x: x[1], reverse=True)[:5]
        return [k[0] for k in top_keywords]
    
    def parsear(self):
        """Parsea la ley completa"""
        print(f"\n📚 {self.codigo} - {NOMBRES_LEYES.get(self.codigo, 'Ley desconocida')}")
        print(f"   📄 Texto: {len(self.texto):,} caracteres")
        
        # Extraer estructura
        secciones = self.extraer_secciones()
        print(f"   📂 Secciones: {len(secciones)}")
        
        # Mostrar jerarquía detectada
        if secciones:
            tipos = defaultdict(int)
            for s in secciones:
                tipos[s['tipo']] += 1
            estructura = ' → '.join([f"{count} {tipo}" for tipo, count in sorted(tipos.items(), key=lambda x: x[1], reverse=True)])
            print(f"   🏗️  Estructura: {estructura}")
        
        # Extraer artículos
        articulos = self.extraer_articulos(secciones)
        print(f"   📋 Artículos: {len(articulos)}")
        
        # Estadísticas
        arts_con_seccion = sum(1 for a in articulos if a['seccion_id'])
        if arts_con_seccion:
            print(f"   🔗 Artículos asignados: {arts_con_seccion}/{len(articulos)}")
        
        return {
            'ley': {
                'codigo': self.codigo,
                'nombre': NOMBRES_LEYES.get(self.codigo, 'Ley desconocida'),
                'num_articulos': len(articulos),
                'num_secciones': len(secciones),
                'caracteres': len(self.texto)
            },
            'secciones': secciones,
            'articulos': articulos
        }

# ============================================================================
# EJECUCIÓN
# ============================================================================

def procesar_todas_leyes():
    """Procesa todas las leyes"""
    txt_files = sorted(TXT_DIR.glob("*.txt"))
    
    print(f"\n📋 {len(txt_files)} leyes para procesar\n")
    
    resultados = []
    total_articulos = 0
    total_secciones = 0
    
    for txt_path in txt_files:
        codigo = txt_path.stem
        
        # Leer texto
        with open(txt_path, 'r', encoding='utf-8') as f:
            texto = f.read()
        
        # Parsear
        parser = ParserLey(texto, codigo)
        resultado = parser.parsear()
        
        # Guardar JSON estructurado
        output_path = OUTPUT_DIR / f"{codigo}.json"
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(resultado, f, ensure_ascii=False, indent=2)
        
        print(f"   💾 Guardado: {output_path.name}")
        
        resultados.append(resultado['ley'])
        total_articulos += resultado['ley']['num_articulos']
        total_secciones += resultado['ley']['num_secciones']
    
    # Resumen final
    print("\n" + "=" * 80)
    print("✅ PROCESAMIENTO COMPLETADO")
    print("=" * 80)
    
    print(f"\n📊 Resumen Global:\n")
    print(f"   Leyes procesadas: {len(resultados)}")
    print(f"   Total artículos: {total_articulos:,}")
    print(f"   Total secciones: {total_secciones:,}")
    print(f"   Promedio artículos/ley: {total_articulos // len(resultados)}")
    
    print(f"\n📚 Detalle por ley:\n")
    for ley in sorted(resultados, key=lambda x: x['num_articulos'], reverse=True):
        print(f"   {ley['codigo']:<12} {ley['num_articulos']:>4} arts  {ley['num_secciones']:>3} secs  {ley['nombre'][:45]}")
    
    print(f"\n📁 Archivos JSON en: {OUTPUT_DIR}")
    print("=" * 80 + "\n")
    
    # Guardar resumen general
    resumen_path = OUTPUT_DIR / "_resumen.json"
    with open(resumen_path, 'w', encoding='utf-8') as f:
        json.dump({
            'total_leyes': len(resultados),
            'total_articulos': total_articulos,
            'total_secciones': total_secciones,
            'leyes': resultados
        }, f, ensure_ascii=False, indent=2)
    
    print(f"💾 Resumen guardado: {resumen_path}\n")

if __name__ == "__main__":
    procesar_todas_leyes()
