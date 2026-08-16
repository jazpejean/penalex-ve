#!/bin/bash

# Script para arreglar deprecaciones comunes de Flutter 3.x
# Creado por Kiro para Penalex VE

set -e

echo "🔧 Arreglando deprecaciones de Flutter 3.x..."
echo ""

# Verificar que estamos en el directorio correcto
if [ ! -d "lib" ]; then
    echo "❌ Error: No se encontró el directorio lib"
    exit 1
fi

echo "📝 Aplicando arreglos automáticos de Dart..."
dart fix --apply 2>&1 | tail -20

echo ""
echo "✅ Arreglos aplicados"
echo ""

echo "🔍 Verificando si quedan errores críticos..."
flutter analyze --no-congratulate 2>&1 | grep -i "error •" | head -10 || echo "✅ No hay errores críticos"

echo ""
echo "📊 Resumen:"
echo "──────────"
ERRORS=$(flutter analyze --no-congratulate 2>&1 | grep -c "error •" || echo "0")
WARNINGS=$(flutter analyze --no-congratulate 2>&1 | grep -c "warning •" || echo "0")

echo "❌ Errores: $ERRORS"
echo "⚠️  Warnings: $WARNINGS"
echo ""

if [ "$ERRORS" -gt "0" ]; then
    echo "🚨 Aún hay errores. Revisa el output de:"
    echo "   flutter analyze"
else
    echo "✅ No hay errores. Puedes compilar el APK:"
    echo "   ./generar_apk_rapido.sh"
fi

echo ""
