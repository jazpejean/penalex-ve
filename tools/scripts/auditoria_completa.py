#!/usr/bin/env python3
"""
Auditoría completa de las 16 leyes
Detecta duplicados, reformas, y problemas de parsing
"""
import re
import json
from pathlib import Path

TXT_DIR = Path("tools/data/leyes/textos")
JSON_DIR = Path("tools/data/leyes/estructurado")

def auditar_ley(codigo):
    """Audita una ley específica"""
    
    txt_path = TXT_DIR / f"{codigo}.txt"
    json_path = JSON_DIR / f"{codigo}.json"
    
    if not txt_path.exists():
        return None
    
    # Leer texto
    with open(txt_path, 'r', encoding='utf-8') as f:
        texto = f.read()
    
    # Contar artículos en TXT
    articulos_txt = len(re.findall(r'^Artículo', texto, re.MULTILINE))
    
    # Contar artículos únicos
    matches = re.findall(r'^Artículo\s+(\d+)', texto, re.MULTILINE)
    articulos_unicos = len(set(matches))
    
    # Detectar reformas
    reformas = len(re.findall(r'Se\s+(modifica|agrega|deroga)', texto, re.IGNORECASE))
    
    # Leer JSON
    articulos_json = 0
    if json_path.exists():
        with open(json_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
            articulos_json = data.get('num_articulos', 0)
    
    # Calcular diferencias
    diff_txt_json = articulos_json - articulos_txt
    diff_unicos_json = articulos_json - articulos_unicos
    
    # Diagnóstico
    problemas = []
    
    if reformas > 10:
        problemas.append(f"🚨 {reformas} reformas detectadas (posibles duplicados)")
    
    if diff_txt_json > 10:
        problemas.append(f"🚨 JSON tiene {diff_txt_json} artículos de MÁS")
    
    if diff_txt_json < -10:
        problemas.append(f"🚨 JSON tiene {abs(diff_txt_json)} artículos de MENOS")
    
    if articulos_txt != articulos_unicos and articulos_unicos > 0:
        duplicados = articulos_txt - articulos_unicos
        problemas.append(f"⚠️  {duplicados} duplicados en TXT")
    
    return {
        'codigo': codigo,
        'txt_total': articulos_txt,
        'txt_unicos': articulos_unicos,
        'json': articulos_json,
        'reformas': reformas,
        'problemas': problemas,
        'necesita_parser': len(problemas) > 0
    }

def main():
    print("=" * 80)
    print("🔬 AUDITORÍA COMPLETA - 16 LEYES PENALES VENEZOLANAS")
    print("=" * 80)
    
    leyes = [
        'CEA', 'COP', 'COPP', 'CP', 'CRBV', 'LCDOFT', 'LCSE', 
        'LDCAM', 'LECDI', 'LHRVA', 'LOA', 'LOCC', 'LOD', 
        'LOPNNA', 'LOSDMVLV', 'LPVT'
    ]
    
    resultados = []
    
    for codigo in leyes:
        resultado = auditar_ley(codigo)
        if resultado:
            resultados.append(resultado)
    
    # Separar por estado
    con_parser = ['CP', 'LOCC', 'LOPNNA']
    con_problemas = [r for r in resultados if r['necesita_parser'] and r['codigo'] not in con_parser]
    sin_problemas = [r for r in resultados if not r['necesita_parser']]
    
    # Mostrar resultados
    print("\n✅ LEYES CON PARSER ESPECIALIZADO (3):")
    print("-" * 80)
    for r in [r for r in resultados if r['codigo'] in con_parser]:
        print(f"{r['codigo']:<12} TXT:{r['txt_total']:>4}  Únicos:{r['txt_unicos']:>4}  JSON:{r['json']:>4}  Reformas:{r['reformas']:>3}")
    
    print("\n🔴 LEYES QUE NECESITAN PARSER ESPECIALIZADO ({}):\n".format(len(con_problemas)))
    print("-" * 80)
    for r in con_problemas:
        print(f"\n📌 {r['codigo']}")
        print(f"   TXT: {r['txt_total']} | Únicos: {r['txt_unicos']} | JSON: {r['json']} | Reformas: {r['reformas']}")
        for problema in r['problemas']:
            print(f"   {problema}")
    
    print(f"\n✅ LEYES SIN PROBLEMAS ({len(sin_problemas)}):")
    print("-" * 80)
    for r in sin_problemas:
        print(f"{r['codigo']:<12} TXT:{r['txt_total']:>4}  JSON:{r['json']:>4}  {'✓' if r['txt_total'] == r['json'] else '⚠'}")
    
    # Resumen
    print("\n" + "=" * 80)
    print("📊 RESUMEN")
    print("=" * 80)
    print(f"✅ Con parser especializado: {len(con_parser)} leyes")
    print(f"🔴 Necesitan parser: {len(con_problemas)} leyes")
    print(f"✅ Sin problemas: {len(sin_problemas)} leyes")
    print(f"📈 Total artículos JSON: {sum(r['json'] for r in resultados):,}")
    
    if con_problemas:
        print("\n🎯 PRÓXIMOS PASOS:")
        print("   Crear parsers especializados para:")
        for r in con_problemas:
            print(f"   - {r['codigo']}")
    else:
        print("\n🎉 ¡PERFECCIÓN ABSOLUTA ALCANZADA!")
    
    print("=" * 80 + "\n")

if __name__ == "__main__":
    main()
