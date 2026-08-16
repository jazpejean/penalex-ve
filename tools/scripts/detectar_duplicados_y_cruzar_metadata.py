#!/usr/bin/env python3
"""
Detectar duplicados en índice R2 y cruzar con metadata CSV
"""
import os
import csv
from collections import defaultdict

print("=" * 80)
print("🔍 DETECTAR DUPLICADOS Y CRUZAR CON METADATA")
print("=" * 80)

# 1. Cargar índice R2 detectando duplicados
print("\n📂 Paso 1/3: Analizando índice R2...")
nombres_a_ids = defaultdict(list)

with open('indice_completo.csv', 'r', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    for row in reader:
        full_id = row['id']
        nombre = full_id.split('/')[-1].replace('.html', '').replace('.txt', '')
        nombres_a_ids[nombre].append(full_id)

# Detectar duplicados
duplicados = {nombre: ids for nombre, ids in nombres_a_ids.items() if len(ids) > 1}

print(f"✅ Total archivos únicos: {len(nombres_a_ids):,}")
print(f"⚠️  Archivos duplicados: {len(duplicados):,}")
print(f"   Total duplicados: {sum(len(ids) for ids in duplicados.values()):,}")

# Guardar duplicados
if duplicados:
    with open('archivos_duplicados_r2.csv', 'w', encoding='utf-8', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(['nombre_archivo', 'ruta_1', 'ruta_2', 'ruta_3', 'total_copias'])
        
        for nombre, rutas in sorted(duplicados.items()):
            row = [nombre] + rutas + [''] * (4 - len(rutas)) + [len(rutas)]
            writer.writerow(row)
    
    print(f"✅ Guardado en: archivos_duplicados_r2.csv")

# 2. Cargar metadata de los CSVs
print("\n📂 Paso 2/3: Cargando metadata de CSV...")
metadata_dict = {}
metadata_dir = 'Metadata'

if os.path.exists(metadata_dir):
    csv_files = [f for f in os.listdir(metadata_dir) if f.endswith('.csv')]
    print(f"✅ {len(csv_files)} archivos CSV encontrados")
    
    for csv_file in csv_files:
        filepath = os.path.join(metadata_dir, csv_file)
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                reader = csv.DictReader(f)
                for row in reader:
                    archivo = row.get('archivo', '').replace('.html', '').replace('.txt', '')
                    if archivo:
                        metadata_dict[archivo] = {
                            'fecha': row.get('fecha', ''),
                            'num_sentencia': row.get('num_sentencia', ''),
                            'expediente': row.get('expediente', ''),
                            'partes': row.get('partes', ''),
                            'ponente': row.get('ponente', ''),
                            'procedimiento': row.get('procedimiento', ''),
                            'decision': row.get('decision', ''),
                            'resumen': row.get('resumen', '')
                        }
        except Exception as e:
            print(f"   ⚠️  Error en {csv_file}: {e}")
    
    print(f"✅ {len(metadata_dict):,} registros de metadata cargados")
else:
    print(f"⚠️  Carpeta Metadata/ no encontrada")

# 3. Cruzar índice R2 con metadata
print("\n📊 Paso 3/3: Cruzando datos...")
ids_con_metadata = []
ids_sin_metadata = []

for nombre in nombres_a_ids.keys():
    if nombre in metadata_dict:
        for full_id in nombres_a_ids[nombre]:
            ids_con_metadata.append({
                'id_r2': full_id,
                'nombre': nombre,
                **metadata_dict[nombre]
            })
    else:
        for full_id in nombres_a_ids[nombre]:
            ids_sin_metadata.append({
                'id_r2': full_id,
                'nombre': nombre
            })

print(f"✅ {len(ids_con_metadata):,} archivos CON metadata")
print(f"⚠️  {len(ids_sin_metadata):,} archivos SIN metadata")

# Guardar archivos CON metadata
if ids_con_metadata:
    with open('archivos_con_metadata.csv', 'w', encoding='utf-8', newline='') as f:
        fieldnames = ['id_r2', 'nombre', 'fecha', 'num_sentencia', 'expediente', 'partes', 
                     'ponente', 'procedimiento', 'decision', 'resumen']
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(ids_con_metadata)
    print(f"✅ Guardado en: archivos_con_metadata.csv")

# Guardar archivos SIN metadata
if ids_sin_metadata:
    with open('archivos_sin_metadata.csv', 'w', encoding='utf-8', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=['id_r2', 'nombre'])
        writer.writeheader()
        writer.writerows(ids_sin_metadata)
    print(f"✅ Guardado en: archivos_sin_metadata.csv")

print("\n" + "=" * 80)
print("📊 RESUMEN")
print("=" * 80)
print(f"Total archivos R2:     {len(nombres_a_ids):,}")
print(f"Duplicados:            {len(duplicados):,}")
print(f"Con metadata:          {len(ids_con_metadata):,}")
print(f"Sin metadata:          {len(ids_sin_metadata):,}")
print("=" * 80 + "\n")
