import json

# Leer el JSON
with open('leyes_json/Reforma de la Ley Orgánica sobre el Derecho de la Mujer a una Vida Libre de Violencia.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

print("=" * 100)
print("VERIFICACIÓN EXHAUSTIVA: Ley Orgánica sobre el Derecho de la Mujer a una Vida Libre de Violencia")
print("=" * 100)

total_articulos = 0
articulos_detallados = []

for item in data['estructura_legal']:
    capitulo_nombre = item.get('capitulo', item.get('nombre', 'N/A'))
    nombre_completo = item.get('nombre', '')
    
    print(f"\n{capitulo_nombre}")
    if nombre_completo:
        print(f"  {nombre_completo}")
    print("-" * 100)
    
    articulos_en_capitulo = item.get('articulos', [])
    count_cap = 0
    
    for art in articulos_en_capitulo:
        numero = art.get('numero', 'SIN_NUMERO')
        titulo = art.get('titulo', 'Sin título')
        texto_preview = art.get('texto', '')[:80]
        
        total_articulos += 1
        count_cap += 1
        articulos_detallados.append({
            'numero': numero,
            'titulo': titulo,
            'capitulo': capitulo_nombre
        })
        
        print(f"  Art. {numero}: {titulo}")
    
    print(f"\n  → Artículos en este capítulo: {count_cap}")

print("\n" + "=" * 100)
print(f"TOTAL DE ARTÍCULOS: {total_articulos}")
print("=" * 100)

# Verificar numeración
print("\n" + "=" * 100)
print("VERIFICACIÓN DE SECUENCIA NUMÉRICA:")
print("=" * 100)

numeros_normales = []
numeros_especiales = []

for art_info in articulos_detallados:
    numero = art_info['numero']
    if isinstance(numero, int):
        numeros_normales.append(numero)
    elif isinstance(numero, str):
        # Si es string pero parece número
        if numero.replace('-', '').replace('A', '').replace('B', '').isdigit():
            try:
                num_base = int(numero.split('-')[0]) if '-' in str(numero) else int(numero.replace('A', '').replace('B', ''))
                numeros_normales.append(num_base)
            except:
                numeros_especiales.append(numero)
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

# Listado final ordenado
print("\n" + "=" * 100)
print("LISTADO COMPLETO DE ARTÍCULOS (en orden):")
print("=" * 100)
for i, art_info in enumerate(articulos_detallados, 1):
    print(f"{i}. Artículo {art_info['numero']}: {art_info['titulo']}")
