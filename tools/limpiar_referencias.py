#!/usr/bin/env python3
"""
Script para eliminar referencias a sitios web de los JSONs
Autor: PENALEX VE
Fecha: 2026-08-13
"""

import json
import os
from pathlib import Path

def limpiar_json(ruta_json):
    """Elimina referencias a sitios web del JSON"""
    print(f"🔧 Limpiando: {os.path.basename(ruta_json)}")
    
    with open(ruta_json, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    modificado = False
    
    # Limpiar metadata
    if 'metadata' in data:
        if 'fuente' in data['metadata']:
            del data['metadata']['fuente']
            modificado = True
        
        # Agregar advertencia legal si no existe
        if 'advertencia_legal' not in data['metadata']:
            data['metadata']['advertencia_legal'] = 'Contenido de referencia informativa. Verificar con Gaceta Oficial para uso legal.'
            modificado = True
    
    # Limpiar URLs de artículos
    if 'estructura' in data:
        for articulo in data['estructura']:
            if 'url' in articulo:
                del articulo['url']
                modificado = True
    
    # Para JSONs antiguos con array directo
    elif isinstance(data, list):
        for articulo in data:
            if 'url' in articulo:
                del articulo['url']
                modificado = True
    
    if modificado:
        # Guardar cambios
        with open(ruta_json, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        print(f"   ✅ Limpiado exitosamente")
    else:
        print(f"   ℹ️ No requiere cambios")
    
    return modificado

def main():
    leyes_dir = Path('../leyes_json')
    
    if not leyes_dir.exists():
        print(f"❌ Directorio no encontrado: {leyes_dir}")
        return
    
    print(f"\n{'='*70}")
    print("🧹 LIMPIANDO REFERENCIAS DE SITIOS WEB")
    print(f"{'='*70}\n")
    
    archivos_json = list(leyes_dir.glob('*.json'))
    
    if not archivos_json:
        print("ℹ️ No se encontraron archivos JSON")
        return
    
    total = len(archivos_json)
    modificados = 0
    
    for json_file in archivos_json:
        try:
            if limpiar_json(json_file):
                modificados += 1
        except Exception as e:
            print(f"   ❌ Error: {e}")
    
    print(f"\n{'='*70}")
    print(f"📊 RESUMEN:")
    print(f"   Total archivos: {total}")
    print(f"   Modificados: {modificados}")
    print(f"   Sin cambios: {total - modificados}")
    print(f"{'='*70}\n")

if __name__ == '__main__':
    main()
