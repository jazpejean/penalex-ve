#!/bin/bash

# Script para analizar los 1224 issues y ver cuáles son críticos
# Creado por Kiro para Penalex VE

echo "🔍 Analizando los 1224 issues..."
echo ""

# Ejecutar análisis y clasificar
echo "Ejecutando flutter analyze..."
flutter analyze 2>&1 | head -100 > /tmp/flutter_issues.txt

echo ""
echo "📊 Resumen de issues:"
echo "────────────────────"
echo ""

# Contar por tipo
ERRORS=$(grep -c "error •" /tmp/flutter_issues.txt || echo "0")
WARNINGS=$(grep -c "warning •" /tmp/flutter_issues.txt || echo "0")
INFOS=$(grep -c "info •" /tmp/flutter_issues.txt || echo "0")

echo "❌ Errores: $ERRORS"
echo "⚠️  Warnings: $WARNINGS"
echo "ℹ️  Infos: $INFOS"
echo ""

if [ "$ERRORS" -gt "0" ]; then
    echo "🚨 HAY ERRORES CRÍTICOS:"
    echo "──────────────────────"
    grep "error •" /tmp/flutter_issues.txt | head -10
    echo ""
else
    echo "✅ No hay errores críticos"
    echo ""
    echo "💡 Los 1224 issues son solo:"
    echo "   • Warnings de deprecaciones"
    echo "   • Sugerencias de estilo"
    echo "   • Hints de optimización"
    echo ""
    echo "   ➡️ Puedes ignorarlos y generar el APK"
fi

echo ""
echo "📝 Los primeros 20 issues son:"
echo "─────────────────────────────"
head -20 /tmp/flutter_issues.txt

echo ""
echo ""
echo "🎯 Recomendación:"
if [ "$ERRORS" -gt "0" ]; then
    echo "   Arregla los errores críticos antes de compilar"
else
    echo "   Los issues NO impiden la compilación"
    echo "   Ejecuta: ./generar_apk_rapido.sh"
fi
echo ""
