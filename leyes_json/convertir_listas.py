import json
import re

# Patrones de párrafos finales que pueden aparecer sin doble salto
PATRONES_PARRAFO = [
    r'Parágrafo Único:',
    r'Parágrafo Primero:',
    r'Parágrafo Segundo:',
    r'Parágrafo Tercero:',
    r'Parágrafo Cuarto:',
    r'En ningún caso',
    r'En caso de que',
]

def separar_parrafos_finales(texto):
    """Si el texto contiene un patrón de párrafo final, lo separa y devuelve (texto_item, lista_parrafos)"""
    for patron in PATRONES_PARRAFO:
        match = re.search(patron, texto)
        if match:
            # Cortar en la posición del patrón
            pos = match.start()
            texto_item = texto[:pos].strip()
            resto = texto[pos:].strip()
            # Dividir el resto en párrafos separados por punto y aparte? mejor conservar como array de un solo elemento
            # Pero si hay varios parágrafos, separarlos por saltos de línea o por patrones
            parrafos = [resto]
            # También podría haber múltiples parágrafos separados por punto y aparte, pero mejor mantenerlo simple
            return texto_item, parrafos
    return texto, []

def transformar_articulo(art):
    if 'texto' in art:
        clave = 'texto'
    elif 'contenido' in art:
        clave = 'contenido'
    else:
        return art

    if 'intro' in art or 'items' in art:
        # Ya tiene estructura, pero puede tener párrafos finales dentro de items
        # Reparar: revisar el último ítem
        if 'items' in art and len(art['items']) > 0:
            ultimo = art['items'][-1]
            if 'texto' in ultimo:
                texto_original = ultimo['texto']
                texto_limpio, parrafos = separar_parrafos_finales(texto_original)
                if parrafos:
                    ultimo['texto'] = texto_limpio
                    # Si el artículo ya tiene parrafos_finales, concatenar; si no, crearlo
                    if 'parrafos_finales' in art:
                        art['parrafos_finales'] = parrafos + art['parrafos_finales']
                    else:
                        art['parrafos_finales'] = parrafos
        return art

    # Si no tiene estructura, aplicar transformación normal (ya está hecho)
    # Pero aquí no llegará porque ya está estructurado
    return art

def procesar_estructura(obj):
    if isinstance(obj, dict):
        if 'numero' in obj and ('texto' in obj or 'contenido' in obj):
            return transformar_articulo(obj)
        else:
            nuevo_dict = {}
            for k, v in obj.items():
                nuevo_dict[k] = procesar_estructura(v)
            return nuevo_dict
    elif isinstance(obj, list):
        return [procesar_estructura(item) for item in obj]
    else:
        return obj

if __name__ == "__main__":
    archivo_entrada = "codigo penal_transformada_PERFECTA_v4.json"
    archivo_salida = "codigo penal_transformada_PERFECTA_v5.json"

    try:
        with open(archivo_entrada, 'r', encoding='utf-8') as f:
            datos = json.load(f)

        datos_corregidos = procesar_estructura(datos)

        with open(archivo_salida, 'w', encoding='utf-8') as f:
            json.dump(datos_corregidos, f, ensure_ascii=False, indent=2)

        print(f"✅ Corrección completada. Archivo: {archivo_salida}")
    except FileNotFoundError:
        print(f"❌ Error: No se encontró '{archivo_entrada}'")
    except Exception as e:
        print(f"❌ Error: {e}")
