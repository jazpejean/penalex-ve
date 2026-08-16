#!/usr/bin/env python3
import json

with open('leyes_json/copp.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

# Contar artículos en título preliminar
preliminar = len(data.get('titulo_preliminar', {}).get('articulos', []))
print(f"Título Preliminar: {preliminar} artículos")

# Contar artículos en cada libro
total_libros = 0
for libro in data.get('libros', []):
    articulos_libro = 0
    for titulo in libro.get('titulos', []):
        for capitulo in titulo.get('capitulos', []):
            # Artículos directos del capítulo
            articulos_libro += len(capitulo.get('articulos', []))
            # Artículos en secciones
            for seccion in capitulo.get('secciones', []):
                articulos_libro += len(seccion.get('articulos', []))
    
    print(f"Libro {libro['numero']}: {articulos_libro} artículos")
    total_libros += articulos_libro

total = preliminar + total_libros
print(f"\nTOTAL: {total} artículos")
print(f"Esperado: 518 artículos")
print(f"Diferencia: {518 - total}")

# Verificar numeración
todos_numeros = []
for art in data.get('titulo_preliminar', {}).get('articulos', []):
    todos_numeros.append(art['numero'])

for libro in data.get('libros', []):
    for titulo in libro.get('titulos', []):
        for capitulo in titulo.get('capitulos', []):
            for art in capitulo.get('articulos', []):
                todos_numeros.append(art['numero'])
            for seccion in capitulo.get('secciones', []):
                for art in seccion.get('articulos', []):
                    todos_numeros.append(art['numero'])

todos_numeros.sort()
print(f"\nPrimer artículo: {todos_numeros[0]}")
print(f"Último artículo: {todos_numeros[-1]}")
print(f"Total artículos contados: {len(todos_numeros)}")

# Detectar saltos
for i in range(len(todos_numeros)-1):
    if todos_numeros[i+1] - todos_numeros[i] > 1:
        print(f"Salto detectado: del {todos_numeros[i]} al {todos_numeros[i+1]}")
