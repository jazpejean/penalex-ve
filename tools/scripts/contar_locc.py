import re

with open('/home/jeanjazpe/Desktop/Penalex_VE/tools/data/leyes/textos/LOCC.txt', 'r', encoding='utf-8') as f:
    texto = f.read()

# Contar todos los "Artículo X."
pattern = r'^Artículo\s*\n*(\d+)\s*\n*\.'
matches = re.findall(pattern, texto, re.MULTILINE)

print(f"Total artículos encontrados: {len(matches)}")
print(f"Primeros 10: {matches[:10]}")
print(f"Últimos 10: {matches[-10:]}")

# Contar solo las frases "Se modifica"
modificaciones = re.findall(r'Se modifica el artículo (\d+)', texto)
print(f"\nArtículos que modifican: {len(modificaciones)}")
print(f"Números modificados: {modificaciones[:20]}")

# Verificar estructura
print("\n--- PRIMEROS 500 CARACTERES ---")
print(texto[:500])
