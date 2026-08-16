# ============================================
# GENERAR EMBEDDINGS DESDE CLOUDFLARE TXT
# Para ejecutar en Google Colab
# ============================================

!pip install requests supabase deepseek -q

import requests
import json
from supabase import create_client, Client
import time
from datetime import datetime

# ============================================
# CONFIGURACIÓN
# ============================================

SUPABASE_URL = "https://efxzcglhyosrxtafirhs.supabase.co"
SUPABASE_SERVICE_KEY = "TU_SERVICE_ROLE_KEY_AQUI"  # ⚠️ NUNCA la anon key, usa service_role
DEEPSEEK_API_KEY = "sk-0a9f652b7fd549db937ca806959ab6c1"

supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)

# ============================================
# FUNCIONES
# ============================================

def generar_embedding(texto):
    """Genera embedding con DeepSeek"""
    try:
        # Limitar a 8000 caracteres
        texto_limitado = texto[:8000]
        
        response = requests.post(
            'https://api.deepseek.com/v1/embeddings',
            headers={
                'Authorization': f'Bearer {DEEPSEEK_API_KEY}',
                'Content-Type': 'application/json',
            },
            json={
                'model': 'deepseek-embedding',
                'input': texto_limitado
            },
            timeout=30
        )
        
        if response.status_code == 200:
            data = response.json()
            embedding = data['data'][0]['embedding']
            return embedding
        else:
            print(f"    ❌ Error API: {response.status_code}")
            return None
            
    except Exception as e:
        print(f"    ❌ Error: {e}")
        return None

def procesar_documento(doc):
    """Descarga TXT de Cloudflare y genera embedding"""
    try:
        doc_id = doc['id']
        numero = doc.get('numero', 'sin_numero')
        url_txt = doc.get('url_txt')
        
        # Si no tiene url_txt, intentar con extracto
        if not url_txt:
            extracto = doc.get('extracto', '')
            if not extracto or len(extracto) < 100:
                print(f"  ⚠️  {numero}: Sin URL de TXT ni extracto suficiente")
                return False
            
            # Usar extracto directamente
            print(f"  📝 {numero}: Usando extracto...")
            embedding = generar_embedding(extracto)
            
            if not embedding:
                return False
            
            # Guardar
            supabase.table('documentos').update({
                'embedding': embedding
            }).eq('id', doc_id).execute()
            
            print(f"  ✅ {numero}: Completado (desde extracto)")
            return True
        
        # Descargar TXT de Cloudflare
        print(f"  📥 {numero}: Descargando TXT...")
        txt_response = requests.get(url_txt, timeout=30)
        
        if txt_response.status_code != 200:
            print(f"  ❌ {numero}: Error descargando ({txt_response.status_code})")
            # Fallback: usar extracto
            extracto = doc.get('extracto', '')
            if extracto and len(extracto) >= 100:
                embedding = generar_embedding(extracto)
                if embedding:
                    supabase.table('documentos').update({
                        'embedding': embedding
                    }).eq('id', doc_id).execute()
                    print(f"  ✅ {numero}: Completado (fallback a extracto)")
                    return True
            return False
        
        contenido = txt_response.text
        
        if len(contenido) < 100:
            print(f"  ⚠️  {numero}: TXT muy corto ({len(contenido)} chars)")
            return False
        
        # Generar embedding
        print(f"  🤖 {numero}: Generando embedding...")
        embedding = generar_embedding(contenido)
        
        if not embedding:
            return False
        
        # Guardar en Supabase
        print(f"  💾 {numero}: Guardando...")
        supabase.table('documentos').update({
            'embedding': embedding
        }).eq('id', doc_id).execute()
        
        print(f"  ✅ {numero}: Completado")
        return True
        
    except Exception as e:
        print(f"  ❌ {numero}: Error - {e}")
        return False

# ============================================
# PROCESO PRINCIPAL
# ============================================

print("=" * 60)
print("🚀 GENERACIÓN DE EMBEDDINGS PARA BÚSQUEDA SEMÁNTICA")
print("=" * 60)
print(f"📅 Inicio: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
print()

offset = 0
batch_size = 50
total_exitosos = 0
total_fallidos = 0
inicio = time.time()

while True:
    print(f"\n📦 Obteniendo lote desde {offset}...")
    
    # Obtener documentos sin embedding
    try:
        response = supabase.table('documentos')\
            .select('id, numero, url_txt, extracto')\
            .is_('embedding', None)\
            .range(offset, offset + batch_size - 1)\
            .execute()
        
        documentos = response.data
    except Exception as e:
        print(f"❌ Error obteniendo documentos: {e}")
        break
    
    if not documentos:
        print("✅ Todos los documentos procesados")
        break
    
    print(f"📋 Procesando {len(documentos)} documentos...\n")
    
    for i, doc in enumerate(documentos, 1):
        numero = doc.get('numero', 'sin_numero')
        print(f"[{i}/{len(documentos)}] {numero}...")
        
        if procesar_documento(doc):
            total_exitosos += 1
        else:
            total_fallidos += 1
        
        # Rate limit: 1 segundo entre requests
        time.sleep(1)
    
    offset += batch_size
    
    # Mostrar progreso cada lote
    tiempo_transcurrido = time.time() - inicio
    print(f"\n📊 Progreso parcial:")
    print(f"   ✅ Exitosos: {total_exitosos}")
    print(f"   ❌ Fallidos: {total_fallidos}")
    print(f"   ⏱️  Tiempo: {tiempo_transcurrido/60:.1f} minutos")

# ============================================
# RESUMEN FINAL
# ============================================

tiempo_total = time.time() - inicio

print("\n" + "=" * 60)
print("🎉 PROCESO COMPLETADO")
print("=" * 60)
print(f"✅ Exitosos: {total_exitosos}")
print(f"❌ Fallidos: {total_fallidos}")
print(f"📊 Total procesados: {total_exitosos + total_fallidos}")
print(f"⏱️  Tiempo total: {tiempo_total/60:.1f} minutos")
print(f"⚡ Promedio: {tiempo_total/(total_exitosos + total_fallidos):.1f}s por documento")
print("=" * 60)

# Verificar resultado
print("\n🔍 Verificando resultado en Supabase...")
try:
    resultado = supabase.table('documentos')\
        .select('id', count='exact')\
        .not_.is_('embedding', None)\
        .execute()
    
    total_con_embedding = resultado.count
    print(f"✅ Total documentos con embedding: {total_con_embedding}")
except Exception as e:
    print(f"❌ Error verificando: {e}")

print(f"\n📅 Fin: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
print("=" * 60)
