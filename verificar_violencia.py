import json

# Leer el JSON de la ley de violencia
with open('leyes_json/Reforma de la Ley Orgánica sobre el Derecho de la Mujer a una Vida Libre de Violencia.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

print("=" * 80)
print("VERIFICACIÓN: Ley Orgánica sobre el Derecho de la Mujer a una Vida Libre de Violencia")
print("=" * 80)

# Contar artículos totales
total_articles = 0
articles_list = []

for item in data['estructura_legal']:
    tipo = item.get('tipo', '')
    
    if tipo == 'titulo':
        titulo_num = item.get('numero', 'N/A')
        titulo_texto = item.get('texto', 'N/A')
        print(f"\n{tipo.upper()} {titulo_num}: {titulo_texto}")
        
        for cap in item.get('capitulos', []):
            cap_num = cap.get('numero', 'N/A')
            cap_texto = cap.get('texto', 'N/A')
            print(f"  CAPÍTULO {cap_num}: {cap_texto}")
            
            for art in cap.get('articulos', []):
                if 'numero' in art:
                    articles_list.append(art['numero'])
                    total_articles += 1
                    print(f"    - Artículo {art['numero']}")
                elif 'texto' in art or 'titulo' in art:
                    # Artículo sin número explícito
                    total_articles += 1
                    desc = art.get('texto', art.get('titulo', 'SIN DESCRIPCIÓN'))
                    print(f"    - Artículo (sin número): {desc[:50]}...")
                    articles_list.append(f"SIN_NUM_{total_articles}")

print("\n" + "=" * 80)
print(f"TOTAL DE ARTÍCULOS ENCONTRADOS: {total_articles}")
print("=" * 80)

# Verificar secuencia numérica
print("\nVERIFICACIÓN DE SECUENCIA NUMÉRICA:")
numeric_articles = [a for a in articles_list if isinstance(a, (int, str)) and str(a).isdigit()]
numeric_articles = sorted([int(a) for a in numeric_articles])

if numeric_articles:
    print(f"Primer artículo: {numeric_articles[0]}")
    print(f"Último artículo: {numeric_articles[-1]}")
    
    # Verificar huecos
    missing = []
    for i in range(numeric_articles[0], numeric_articles[-1] + 1):
        if i not in numeric_articles:
            missing.append(i)
    
    if missing:
        print(f"\nARTÍCULOS FALTANTES EN LA SECUENCIA: {missing}")
    else:
        print("\n✓ Secuencia numérica completa (sin huecos)")

# Buscar artículos especiales (con letras, bis, etc)
special_articles = [a for a in articles_list if not (isinstance(a, (int, str)) and str(a).replace('-', '').isdigit())]
if special_articles:
    print(f"\nARTÍCULOS ESPECIALES: {special_articles}")
