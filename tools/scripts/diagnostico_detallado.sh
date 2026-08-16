#!/bin/bash
# ============================================================================
# Diagnóstico Detallado - Analiza formato específico de cada ley problemática
# ============================================================================

TXT_DIR="tools/data/leyes/textos"
JSON_DIR="tools/data/leyes/estructurado"

echo "================================================================================"
echo "🔬 DIAGNÓSTICO DETALLADO POR LEY"
echo "================================================================================"
echo ""

# Función para analizar una ley específica
diagnosticar_ley() {
    local codigo=$1
    local txt_file="$TXT_DIR/${codigo}.txt"
    
    if [ ! -f "$txt_file" ]; then
        echo "❌ Archivo no encontrado: $txt_file"
        return
    fi
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📄 LEY: $codigo"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Mostrar primeras 3 menciones de "Artículo"
    echo "🔍 Primeras 3 menciones de 'Artículo' en el texto:"
    echo ""
    grep -n -i "artículo" "$txt_file" | head -3
    echo ""
    
    # Contar diferentes patrones
    echo "📊 Conteo por diferentes patrones:"
    echo ""
    
    # Patrón 1: Artículo seguido de número (con o sin punto)
    count1=$(grep -oi "artículo [0-9]" "$txt_file" | wc -l)
    echo "  Patrón 'Artículo [0-9]': $count1"
    
    # Patrón 2: Artículo seguido de número con punto
    count2=$(grep -oi "artículo [0-9]*\." "$txt_file" | wc -l)
    echo "  Patrón 'Artículo [0-9]*.': $count2"
    
    # Patrón 3: Con saltos de línea (Artículo\n[número])
    count3=$(grep -A1 -i "^artículo$" "$txt_file" | grep -E "^[0-9]+$" | wc -l)
    echo "  Patrón 'Artículo\\n[número]': $count3"
    
    # Patrón 4: Artículos únicos (eliminando duplicados)
    count4=$(grep -oi "artículo [0-9]\+" "$txt_file" | sed 's/artículo //i' | sort -u | wc -l)
    echo "  Artículos únicos: $count4"
    
    echo ""
    
    # Mostrar 5 primeros números de artículos encontrados
    echo "🔢 Primeros 5 números de artículos detectados:"
    echo ""
    grep -oi "artículo [0-9]\+" "$txt_file" | sed 's/artículo //i' | head -5 | nl
    echo ""
    
    # Verificar artículos extraídos por el parser
    json_file="$JSON_DIR/${codigo}.json"
    if [ -f "$json_file" ]; then
        extraidos=$(jq '.ley.num_articulos' "$json_file")
        echo "✅ Parser extrajo: $extraidos artículos"
        echo ""
        echo "📋 Primeros 5 artículos en JSON:"
        jq -r '.articulos[0:5] | .[] | "\(.numero): \(.titulo // "Sin título")"' "$json_file"
    else
        echo "❌ JSON no encontrado: $json_file"
    fi
    
    echo ""
}

# Diagnosticar leyes problemáticas
echo "🎯 Analizando leyes con problemas..."
echo ""

diagnosticar_ley "CP"
diagnosticar_ley "LCDOFT"
diagnosticar_ley "LOCC"
diagnosticar_ley "LOPNNA"

echo "================================================================================"
echo "✅ Diagnóstico completado"
echo "================================================================================"
