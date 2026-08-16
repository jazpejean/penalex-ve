#!/usr/bin/env python3
"""
Script para eliminar concordancias y referencias cruzadas de los JSONs
Autor: PENALEX VE
Fecha: 2026-08-13
"""

import json
import re
from pathlib import Path

def limpiar_concordancias(texto):
    """Elimina concordancias y referencias cruzadas del texto"""
    if not texto:
        return texto
    
    # Patrones de basura a eliminar
    patrones = [
        # Concordancias más comunes
        r'Concordancia\s+adicional\s*[A-Z]{2,6}\s+artículo\s+\d+[\w\s]*',
        r'Concordancia\s+adicional[^.]*',
        # Referencias cruzadas con múltiples códigos
        r'[A-Z]{2,6}\s+artículo\s+\d+(?:\s+[A-Z]{2,6}\s+artículo\s+\d+)*\s*$',
        # Ver también y similares
        r'Ver\s+también:?[^.]*',
        r'Artículos?\s+relacionados?:?[^.]*',
        r'Referencias?\s+cruzadas?:?[^.]*',
        # Gacetas oficiales
        r'Gaceta\s+Oficial\s+N[oº°]?\s*\d+[^.]*',
        r'G\.O\.\s+N[oº°]?\s*\d+[^.]*',
        r'Publicado\s+en:?[^.]*',
    ]
    
    texto_limpio = texto
    for patron in patrones:
        texto_limpio = re.sub(patron, '', texto_limpio, flags=re.IGNORECASE)
    
    # Normalizar espacios
    texto_limpio = re.sub(r'\s+', ' ', texto_limpio)
    texto_limpio = texto_limpio.strip()
    
    return texto_limpio

def limpiar_json_recursivo(obj):
    """Limpia concordancias recursivamente en el JSON"""
    if isinstance(obj, dict):
        return {k: limpiar_json_recursivo(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [limpiar_json_recursivo(item) for item in obj]
    elif isinstance(obj, str):
        return limpiar_concordancias(obj)
    return obj

def procesar_archivo(ruta_json):
    """Procesa un archivo JSON eliminando concordancias"""
    print(f"🔧 Procesando: {ruta_json.name}")
    
    try:
        with open(ruta_json, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        # Contar cuántas concordancias hay
        texto_original = json.dumps(data, ensure_ascii=False)
        concordancias_antes = len(re.findall(r'Concordancia\s+adicional', texto_original, re.IGNORECASE))
        
        if concordancias_antes == 0:
            print(f"   ℹ️ Sin concordancias")
            return False
        
        print(f"   🗑️ Encontradas {concordancias_antes} concordancias")
        
        # Limpiar recursivamente
        data_limpia = limpiar_json_recursivo(data)
        
        # Guardar
        with open(ruta_json, 'w', encoding='utf-8') as f:
            json.dump(data_limpia, f, ensure_ascii=False, indent=2)
        
        print(f"   ✅ Limpiado exitosamente")
        return True
        
    except Exception as e:
        print(f"   ❌ Error: {e}")
        return False

def main():
    leyes_dir = Path('../leyes_json')
    
    if not leyes_dir.exists():
        print(f"❌ Directorio no encontrado: {leyes_dir}")
        return
    
    print(f"\n{'='*70}")
    print("🧹 LIMPIANDO CONCORDANCIAS Y REFERENCIAS CRUZADAS")
    print(f"{'='*70}\n")
    
    archivos_json = list(leyes_dir.glob('*.json'))
    
    if not archivos_json:
        print("ℹ️ No se encontraron archivos JSON")
        return
    
    total = len(archivos_json)
    modificados = 0
    
    for json_file in archivos_json:
        if procesar_archivo(json_file):
            modificados += 1
    
    print(f"\n{'='*70}")
    print(f"📊 RESUMEN:")
    print(f"   Total archivos: {total}")
    print(f"   Modificados: {modificados}")
    print(f"   Sin cambios: {total - modificados}")
    print(f"{'='*70}\n")

if __name__ == '__main__':
    main()
