#!/bin/bash
# ============================================================================
# Validación del Parser - Compara artículos reales vs extraídos
# ============================================================================

echo "================================================================================"
echo "🔍 VALIDACIÓN DEL PARSER DE ARTÍCULOS"
echo "================================================================================"
echo ""

TXT_DIR="tools/data/leyes/textos"
JSON_DIR="tools/data/leyes/estructurado"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

total_esperados=0
total_extraidos=0
total_correctos=0
total_incorrectos=0

echo "📋 Contando artículos reales en archivos TXT..."
echo ""

# Array para almacenar resultados
declare -A reales
declare -A extraidos

# Contar artículos reales en cada TXT
for txt_file in "$TXT_DIR"/*.txt; do
    if [ -f "$txt_file" ]; then
        codigo=$(basename "$txt_file" .txt)
        
        # Contar artículos únicos (números únicos) - PATRÓN MEJORADO
        # Captura: Artículo 1, Artículo 1., Artículo 493-A, etc.
        count=$(grep -oiE "Artículo [0-9]+(-[A-Z])?\.?" "$txt_file" | sed 's/Artículo //i' | sed 's/\.//' | sort -u | wc -l)
        reales[$codigo]=$count
        total_esperados=$((total_esperados + count))
    fi
done

# Ejecutar parser
echo "⚙️  Ejecutando parser..."
echo ""
python3 tools/scripts/parser_leyes_inteligente.py > /tmp/parser_output.log 2>&1

# Leer artículos extraídos de los JSON
for json_file in "$JSON_DIR"/*.json; do
    if [ -f "$json_file" ] && [[ ! "$json_file" =~ "_resumen.json" ]]; then
        codigo=$(basename "$json_file" .json)
        
        # Contar artículos en JSON usando jq
        count=$(jq '.ley.num_articulos' "$json_file" 2>/dev/null || echo "0")
        extraidos[$codigo]=$count
        total_extraidos=$((total_extraidos + count))
    fi
done

echo ""
echo "================================================================================"
echo "📊 RESULTADOS DE VALIDACIÓN"
echo "================================================================================"
echo ""
printf "%-12s %10s %10s %10s %s\n" "CÓDIGO" "REALES" "EXTRAÍDOS" "DIFF" "ESTADO"
echo "--------------------------------------------------------------------------------"

# Comparar resultados
for codigo in "${!reales[@]}"; do
    real=${reales[$codigo]}
    extra=${extraidos[$codigo]:-0}
    diff=$((extra - real))
    porcentaje=$(awk "BEGIN {printf \"%.1f\", ($extra/$real)*100}")
    
    # Determinar estado
    if [ $diff -eq 0 ]; then
        estado="${GREEN}✅ PERFECTO${NC}"
        total_correctos=$((total_correctos + 1))
    elif [ $diff -gt 0 ] && [ $diff -le 10 ]; then
        estado="${YELLOW}⚠️  +${diff} (${porcentaje}%)${NC}"
        total_incorrectos=$((total_incorrectos + 1))
    elif [ $diff -gt 10 ]; then
        estado="${RED}❌ +${diff} (${porcentaje}%)${NC}"
        total_incorrectos=$((total_incorrectos + 1))
    else
        estado="${RED}❌ ${diff} (${porcentaje}%)${NC}"
        total_incorrectos=$((total_incorrectos + 1))
    fi
    
    printf "%-12s %10d %10d %10d %b\n" "$codigo" "$real" "$extra" "$diff" "$estado"
done | sort -k2 -rn

echo "--------------------------------------------------------------------------------"
printf "%-12s %10d %10d %10d\n" "TOTAL" "$total_esperados" "$total_extraidos" "$((total_extraidos - total_esperados))"
echo ""
echo "================================================================================"
echo "📈 RESUMEN"
echo "================================================================================"
echo ""
echo "  Leyes analizadas:    ${#reales[@]}"
echo "  Artículos esperados: $total_esperados"
echo "  Artículos extraídos: $total_extraidos"
echo "  Diferencia:          $((total_extraidos - total_esperados))"
echo ""

if [ $total_correctos -eq ${#reales[@]} ]; then
    echo -e "  ${GREEN}✅ TODAS las leyes están perfectamente parseadas${NC}"
elif [ $total_correctos -gt 0 ]; then
    echo -e "  ${GREEN}✅ Correctas: $total_correctos${NC}"
    echo -e "  ${YELLOW}⚠️  Con diferencias: $total_incorrectos${NC}"
else
    echo -e "  ${RED}❌ TODAS las leyes tienen diferencias${NC}"
fi

echo ""
echo "================================================================================"

# Calcular precisión
precision=$(awk "BEGIN {printf \"%.1f\", ($total_extraidos/$total_esperados)*100}")
echo ""
echo "🎯 Precisión global: $precision%"
echo ""

# Recomendaciones
if [ $total_extraidos -gt $((total_esperados + 50)) ]; then
    echo "💡 Recomendación: El parser está capturando demasiados artículos."
    echo "   Posibles causas:"
    echo "   - Captura menciones de artículos dentro del texto"
    echo "   - Patrón regex demasiado permisivo"
    echo "   - No filtra duplicados correctamente"
fi

echo "================================================================================"
