import json

# Leer el JSON del Código Penal
with open('leyes_json/codigo penal.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

print("=" * 100)
print("VERIFICACIÓN EXHAUSTIVA: Código Penal de la República Bolivariana de Venezuela")
print("=" * 100)

total_articulos = 0
articulos_lista = []

# Iterar sobre los libros
for libro in data.get('libros', []):
    libro_num = libro.get('numero', 'N/A')
    libro_nombre = libro.get('nombre', '')
    
    print(f"\nLIBRO {libro_num}: {libro_nombre}")
    print("=" * 100)
    
    # Iterar sobre los títulos
    for titulo in libro.get('titulos', []):
        titulo_num = titulo.get('numero', 'N/A')
        titulo_nombre = titulo.get('nombre', '')
        
        print(f"\n  TÍTULO {titulo_num}: {titulo_nombre}")
        print("  " + "-" * 96)
        
        # Artículos directos en el título (sin capítulos)
        if 'articulos' in titulo and titulo['articulos']:
            for art in titulo['articulos']:
                numero = art.get('numero', 'SIN_NUMERO')
                total_articulos += 1
                articulos_lista.append(numero)
                print(f"    Art. {numero}")
        
        # Iterar sobre los capítulos
        for cap in titulo.get('capitulos', []):
            cap_num = cap.get('numero', 'N/A')
            cap_nombre = cap.get('nombre', '')
            
            print(f"\n    Capítulo {cap_num}: {cap_nombre}")
            
            # Artículos del capítulo
            for art in cap.get('articulos', []):
                numero = art.get('numero', 'SIN_NUMERO')
                total_articulos += 1
                articulos_lista.append(numero)
                print(f"      Art. {numero}")

print("\n" + "=" * 100)
print(f"TOTAL DE ARTÍCULOS: {total_articulos}")
print("=" * 100)

# Verificar secuencia numérica
print("\nVERIFICACIÓN DE SECUENCIA NUMÉRICA:")

numeros_normales = []
numeros_especiales = []

for num in articulos_lista:
    if isinstance(num, int):
        numeros_normales.append(num)
    elif isinstance(num, str):
        # Verificar si es un número con letras (ej: "126-A")
        if '-' in str(num):
            numeros_especiales.append(num)
        elif num.replace('.', '').isdigit():
            try:
                numeros_normales.append(int(num))
            except:
                numeros_especiales.append(num)
        else:
            numeros_especiales.append(num)
    else:
        numeros_especiales.append(num)

numeros_normales = sorted(set(numeros_normales))

if numeros_normales:
    print(f"\nPrimer artículo: {numeros_normales[0]}")
    print(f"Último artículo: {numeros_normales[-1]}")
    print(f"Rango esperado: 1 a {numeros_normales[-1]}")
    
    # Verificar huecos
    faltantes = []
    for i in range(1, numeros_normales[-1] + 1):
        if i not in numeros_normales:
            faltantes.append(i)
    
    if faltantes:
        print(f"\n⚠ ARTÍCULOS FALTANTES EN LA SECUENCIA: {faltantes}")
        print(f"Total de huecos: {len(faltantes)}")
    else:
        print("\n✓ Secuencia numérica COMPLETA (sin huecos)")

if numeros_especiales:
    print(f"\nARTÍCULOS CON NUMERACIÓN ESPECIAL: {numeros_especiales}")

# Resumen
print("\n" + "=" * 100)
print("RESUMEN:")
print("=" * 100)
print(f"Código: {data.get('codigo', 'N/A')}")
print(f"Total de Libros: {len(data.get('libros', []))}")
print(f"Total de Artículos: {total_articulos}")
print(f"Artículos numerados: {len(numeros_normales)}")
print(f"Artículos especiales: {len(numeros_especiales)}")
