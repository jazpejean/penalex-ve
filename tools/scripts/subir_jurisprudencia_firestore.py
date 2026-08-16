#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Sube sentencias procesadas a Firestore
Lee los JSON generados por procesar_pdfs_jurisprudencia.py
"""

import json
import time
import firebase_admin
from firebase_admin import credentials, firestore
from pathlib import Path
from tqdm import tqdm
from datetime import datetime

# ============================================================================
# CONFIGURACIÓN
# ============================================================================

SENTENCIAS_DIR = "sentencias_procesadas"
SERVICE_ACCOUNT_KEY = "firebase-adminsdk-key.json"  # Descargar de Firebase Console

# Colección en Firestore
COLLECTION_NAME = "sentencias_tsj"


def inicializar_firebase():
    """Inicializa Firebase Admin SDK"""
    try:
        cred = credentials.Certificate(SERVICE_ACCOUNT_KEY)
        firebase_admin.initialize_app(cred)
        db = firestore.client()
        print("✅ Firebase inicializado correctamente")
        return db
    except Exception as e:
        print(f"❌ Error inicializando Firebase: {e}")
        print(f"\n📝 Instrucciones:")
        print(f"1. Ve a Firebase Console → Configuración del proyecto")
        print(f"2. Pestaña 'Cuentas de servicio'")
        print(f"3. Click 'Generar nueva clave privada'")
        print(f"4. Guarda el archivo como '{SERVICE_ACCOUNT_KEY}'")
        return None


def generar_id_sentencia(sentencia):
    """Genera ID único para sentencia"""
    # Formato: sala-anio-numero
    sala = sentencia.get('sala', 'sin-sala').lower().replace(' ', '-')
    
    # Extraer año de la fecha
    fecha = sentencia.get('fecha', '')
    anio = 'sin-anio'
    if fecha:
        import re
        match = re.search(r'(\d{4})', fecha)
        if match:
            anio = match.group(1)
    
    numero = sentencia.get('numero', 'sin-numero')
    
    return f"{sala}-{anio}-{numero}"


def preparar_sentencia_firestore(sentencia):
    """Prepara sentencia para Firestore (limita tamaños, etc.)"""
    # Firestore tiene límite de 1MB por documento
    # Texto completo puede ser muy grande, guardarlo aparte o resumir
    
    doc = {
        'archivo_original': sentencia.get('archivo_original'),
        'numero': sentencia.get('numero'),
        'fecha': sentencia.get('fecha'),
        'expediente': sentencia.get('expediente'),
        'sala': sentencia.get('sala'),
        'ponente': sentencia.get('ponente'),
        'delitos': sentencia.get('delitos', []),
        'tipo_decision': sentencia.get('tipo_decision'),
        'partes': sentencia.get('partes', {}),
        'articulos_citados': sentencia.get('articulos_citados', [])[:10],  # Limitar
        'extracto': sentencia.get('extracto', '')[:2000],  # Limitar a 2000 chars
        
        # Metadata
        'longitud_texto': sentencia.get('longitud_texto', 0),
        'procesado_en': sentencia.get('procesado_en'),
        'subido_a_firestore': datetime.now().isoformat(),
        
        # Tags para búsqueda
        'anio': extraer_anio(sentencia.get('fecha')),
        'tiene_delitos': len(sentencia.get('delitos', [])) > 0,
        'tiene_ponente': bool(sentencia.get('ponente')),
    }
    
    # Guardar texto completo solo si es < 500KB
    texto_completo = sentencia.get('texto_completo', '')
    if len(texto_completo) < 500000:  # 500KB
        doc['texto_completo'] = texto_completo
    else:
        doc['texto_resumido'] = texto_completo[:100000]  # Primeros 100KB
        doc['texto_completo_url'] = None  # Opcional: subir a Storage
    
    return doc


def extraer_anio(fecha_str):
    """Extrae año de string de fecha"""
    if not fecha_str:
        return None
    
    import re
    match = re.search(r'(\d{4})', fecha_str)
    return int(match.group(1)) if match else None


def subir_sentencias(db, sentencias_dir, delay_segundos=10):
    """Sube todas las sentencias a Firestore con rate limiting"""
    sentencias_path = Path(sentencias_dir)
    
    # Buscar archivos JSON
    json_files = list(sentencias_path.glob('*.json'))
    
    # Excluir archivo consolidado
    json_files = [f for f in json_files if f.name != 'sentencias_todas.json']
    
    print(f"\n📂 Encontrados {len(json_files)} archivos JSON")
    print(f"⏱️  Delay configurado: {delay_segundos} segundos entre sentencias")
    
    tiempo_estimado = len(json_files) * delay_segundos / 60
    print(f"⏰ Tiempo estimado: {tiempo_estimado:.1f} minutos")
    
    if not json_files:
        print("❌ No se encontraron archivos JSON para subir")
        return
    
    stats = {
        'subidas_ok': 0,
        'errores': 0,
        'duplicados': 0
    }
    
    collection_ref = db.collection(COLLECTION_NAME)
    
    print("\n🚀 Iniciando subida...")
    
    for i, json_file in enumerate(tqdm(json_files, desc="Subiendo a Firestore"), 1):
        try:
            # Leer JSON
            with open(json_file, 'r', encoding='utf-8') as f:
                sentencia = json.load(f)
            
            # Generar ID
            doc_id = generar_id_sentencia(sentencia)
            
            # Verificar si ya existe
            doc_ref = collection_ref.document(doc_id)
            if doc_ref.get().exists:
                tqdm.write(f"⚠️  Ya existe: {doc_id}")
                stats['duplicados'] += 1
                continue
            
            # Preparar documento
            doc_data = preparar_sentencia_firestore(sentencia)
            
            # Subir a Firestore
            doc_ref.set(doc_data)
            
            stats['subidas_ok'] += 1
            
            # Rate limiting - esperar entre uploads
            if i < len(json_files):  # No esperar después del último
                time.sleep(delay_segundos)
        
        except Exception as e:
            tqdm.write(f"❌ Error en {json_file.name}: {e}")
            stats['errores'] += 1
            # Esperar incluso si hay error (para no saturar)
            time.sleep(delay_segundos)
    
    # Estadísticas
    print("\n" + "="*60)
    print("📊 ESTADÍSTICAS DE CARGA")
    print("="*60)
    print(f"Total archivos: {len(json_files)}")
    print(f"✅ Subidas exitosas: {stats['subidas_ok']}")
    print(f"⚠️  Duplicados (omitidos): {stats['duplicados']}")
    print(f"❌ Errores: {stats['errores']}")
    print("="*60)


def crear_indices(db):
    """Crea índices necesarios en Firestore"""
    print("\n📑 ÍNDICES NECESARIOS EN FIRESTORE:")
    print("="*60)
    print("Ve a Firebase Console → Firestore → Índices")
    print("Crea estos índices compuestos:")
    print("")
    print("1. Colección: sentencias_tsj")
    print("   - sala (Ascending)")
    print("   - anio (Descending)")
    print("   - numero (Descending)")
    print("")
    print("2. Colección: sentencias_tsj")
    print("   - delitos (Array-contains)")
    print("   - anio (Descending)")
    print("")
    print("3. Colección: sentencias_tsj")
    print("   - tipo_decision (Ascending)")
    print("   - anio (Descending)")
    print("="*60)


def main():
    """Función principal"""
    import argparse
    
    parser = argparse.ArgumentParser(description='Sube jurisprudencia a Firestore')
    parser.add_argument('--sentencias', default='sentencias_procesadas', 
                        help='Carpeta con JSONs procesados')
    parser.add_argument('--key', default='firebase-adminsdk-key.json',
                        help='Archivo de clave de servicio de Firebase')
    
    args = parser.parse_args()
    
    global SERVICE_ACCOUNT_KEY
    SERVICE_ACCOUNT_KEY = args.key
    
    print("🚀 SUBIR JURISPRUDENCIA A FIRESTORE")
    print("="*60)
    
    # Verificar que existan los JSON
    if not Path(args.sentencias).exists():
        print(f"❌ ERROR: No existe la carpeta '{args.sentencias}'")
        print(f"   Primero ejecuta: python procesar_pdfs_jurisprudencia.py")
        return
    
    # Verificar clave de servicio
    if not Path(SERVICE_ACCOUNT_KEY).exists():
        print(f"❌ ERROR: No existe '{SERVICE_ACCOUNT_KEY}'")
        print(f"\n📝 Obtén la clave de servicio:")
        print(f"   1. Firebase Console → Configuración → Cuentas de servicio")
        print(f"   2. 'Generar nueva clave privada'")
        print(f"   3. Guardar como '{SERVICE_ACCOUNT_KEY}'")
        return
    
    # Inicializar Firebase
    db = inicializar_firebase()
    if not db:
        return
    
    # Subir sentencias
    subir_sentencias(db, args.sentencias)
    
    # Mostrar info de índices
    crear_indices(db)
    
    print(f"\n✅ Proceso completado")
    print(f"🔗 Ver en: https://console.firebase.google.com")


if __name__ == "__main__":
    main()
