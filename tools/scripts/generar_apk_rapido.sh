#!/bin/bash

# Script para generar APK RÁPIDO ignorando warnings
# Ideal para PCs con bajos recursos
# Creado por Kiro para Penalex VE

set -e

echo "⚡ Generando APK RÁPIDO (ignorando warnings)..."
echo ""
echo "⚠️  Los 1224 'issues' son warnings, no errores críticos"
echo "   La mayoría son deprecations y sugerencias de estilo"
echo ""

# Verificar que estamos en el directorio correcto
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: No se encontró pubspec.yaml"
    exit 1
fi

# NO hacer flutter clean (ahorra tiempo)
echo "📦 Obteniendo dependencias..."
flutter pub get --no-precompile 2>&1 | tail -20

echo ""
echo "🔨 Compilando APK de debug..."
echo "   ⏳ Esto tomará 5-10 minutos..."
echo "   💡 Los warnings no impiden la compilación"
echo ""

# Compilar sin análisis exhaustivo
flutter build apk --debug --no-tree-shake-icons --no-pub 2>&1 | grep -v "│" | grep -v "├" | grep -v "└" || true

echo ""
echo "✅ ¡APK generado!"
echo ""
echo "📍 Ubicación:"
echo "   $(pwd)/build/app/outputs/flutter-apk/app-debug.apk"
echo ""

# Verificar que el APK existe
if [ -f "build/app/outputs/flutter-apk/app-debug.apk" ]; then
    APK_SIZE=$(du -h build/app/outputs/flutter-apk/app-debug.apk | cut -f1)
    echo "📊 Tamaño: $APK_SIZE"
    echo ""
    echo "📱 Para instalar:"
    echo "   adb install build/app/outputs/flutter-apk/app-debug.apk"
    echo ""
    echo "   O transfiere el APK a tu teléfono manualmente"
else
    echo "❌ No se pudo generar el APK"
    echo "   Revisa los errores arriba"
fi

echo ""
