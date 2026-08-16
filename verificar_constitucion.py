import json

# Leer el JSON de la Constitución
with open('leyes_json/Constitucion_sin_enmienda.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

print("=" * 100)
print("VERIFICACIÓN EXHAUSTIVA: Constitución de la República Bolivariana de Venezuela (1999)")
print("=" * 100)

total_articulos = 0
articulos_detallados = []

# Iterar sobre la estructura legal
for titulo in data['estructura_legal']:
    tipo = titulo.get('tipo', '')
    
    # Si es el preámbulo, no contarlo como artículo
    if tipo == 'preambulo':
        print("\nPREÁMBULO: ✓")
        continue
    
    titulo_num = titulo.get('titulo', 'N/A')
    titulo_nombre = titulo.get('nombre', '')
    
    print(f"\n{titulo_num}: {titulo_nombre}")
    print("=" * 100)
    
    # Si el título tiene artículos directos (sin capítulos)
    if 'articulos' in titulo and titulo['articulos']:
        for art in titulo['articulos']:
            numero = art.get('numero', 'SIN_NUMERO')
            texto_preview = art.get('texto', '')[:60]
            
            total_articulos += 1
            articulos_detallados.append({
                'numero': numero,
                'titulo': titulo_num,
                'ubicacion': f"{titulo_num} (directo)"
            })
            print(f"  Artículo {numero}: {texto_preview}...")
    
    # Si el título tiene capítulos
    if 'capitulos' in titulo:
        for cap in titulo['capitulos']:
            cap_num = cap.get('capitulo', 'N/A')
            cap_nombre = cap.get('nombre', '')
            
            print(f"\n  {cap_num}: {cap_nombre}")
            print("  " + "-" * 96)
            
            # Si el capítulo tiene artículos directos
            if 'articulos' in cap and cap['articulos']:
                for art in cap['articulos']:
                    numero = art.get('numero', 'SIN_NUMERO')
                    texto_preview = art.get('texto', '')[:60]
                    
                    total_articulos += 1
                    articulos_detallados.append({
                        'numero': numero,
                        'titulo': titulo_num,
                        'ubicacion': f"{titulo_num} > {cap_num}"
                    })
                    print(f"    Art. {numero}: {texto_preview}...")
            
            # Si el capítulo tiene secciones
            if 'secciones' in cap:
                for seccion in cap['secciones']:
                    secc_num = seccion.get('seccion', 'N/A')
                    secc_nombre = seccion.get('nombre', '')
                    
                    print(f"\n    {secc_num}: {secc_nombre}")
                    
                    # Artículos dentro de la sección
                    if 'articulos' in seccion:
                        for art in seccion['articulos']:
                            numero = art.get('numero', 'SIN_NUMERO')
                            texto_preview = art.get('texto', '')[:60]
                            
                            total_articulos += 1
                            articulos_detallados.append({
                                'numero': numero,
                                'titulo': titulo_num,
                                'ubicacion': f"{titulo_num} > {cap_num} > {secc_num}"
                            })
                            print(f"      Art. {numero}: {texto_preview}...")

print("\n" + "=" * 100)
print(f"TOTAL DE ARTÍCULOS: {total_articulos}")
print("=" * 100)

# Verificar secuencia numérica
print("\nVERIFICACIÓN DE SECUENCIA NUMÉRICA:")
numeros_normales = []
numeros_especiales = []

for art_info in articulos_detallados:
    numero = art_info['numero']
    if isinstance(numero, int):
        numeros_normales.append(numero)
    elif isinstance(numero, str):
        if numero.isdigit():
            numeros_normales.append(int(numero))
        else:
            numeros_especiales.append(numero)
    else:
        numeros_especiales.append(numero)

numeros_normales = sorted(set(numeros_normales))

print(f"\nPrimer artículo: {numeros_normales[0] if numeros_normales else 'N/A'}")
print(f"Último artículo: {numeros_normales[-1] if numeros_normales else 'N/A'}")
print(f"Rango esperado: 1 a {numeros_normales[-1] if numeros_normales else 'N/A'}")

# Verificar huecos en la secuencia
if numeros_normales:
    faltantes = []
    for i in range(1, numeros_normales[-1] + 1):
        if i not in numeros_normales:
            faltantes.append(i)
    
    if faltantes:
        print(f"\n⚠ ARTÍCULOS FALTANTES EN LA SECUENCIA: {faltantes}")
    else:
        print("\n✓ Secuencia numérica COMPLETA (sin huecos del 1 al último)")

if numeros_especiales:
    print(f"\nARTÍCULOS CON NUMERACIÓN ESPECIAL: {numeros_especiales}")

# Estadísticas por título
print("\n" + "=" * 100)
print("DESGLOSE POR TÍTULOS:")
print("=" * 100)

titulos_count = {}
for art in articulos_detallados:
    titulo = art['titulo']
    if titulo not in titulos_count:
        titulos_count[titulo] = 0
    titulos_count[titulo] += 1

for titulo, count in titulos_count.items():
    print(f"{titulo}: {count} artículos")

print("\n" + "=" * 100)
print("ESTRUCTURA DE LA CONSTITUCIÓN:")
print("=" * 100)
print(f"Documento: {data.get('documento', 'N/A')}")
print(f"Versión: {data.get('version', 'N/A')}")
