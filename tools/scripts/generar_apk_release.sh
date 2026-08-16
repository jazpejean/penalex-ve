#!/bin/bash

# Script para generar APK de release (optimizado y firmado)
# Creado por Kiro para Penalex VE

set -e

echo "🚀 Generando APK de RELEASE (optimizado)..."
echo ""
echo "⚠️  Este APK estará optimizado y será más pequeño"
echo ""

# Verificar que estamos en el directorio correcto
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: No se encontró pubspec.yaml"
    exit 1
fi

# Limpiar build anterior
echo "🧹 Limpiando build anterior..."
flutter clean

echo ""
echo "📦 Obteniendo dependencias..."
flutter pub get

echo ""
echo "🔨 Compilando APK de release..."
echo "   (Esto puede tardar 10-15 minutos)"
echo "   ⏳ Ten paciencia, Flutter está optimizando el código..."
echo ""

flutter build apk --release

echo ""
echo "✅ ¡APK de RELEASE generado exitosamente!"
echo ""
echo "📍 Ubicación del APK:"
echo "   $(pwd)/build/app/outputs/flutter-apk/app-release.apk"
echo ""

# Mostrar tamaño del APK
APK_SIZE=$(du -h build/app/outputs/flutter-apk/app-release.apk | cut -f1)
echo "📊 Tamaño del APK: $APK_SIZE"
echo ""

echo "📱 Este APK está listo para:"
echo "   ✅ Instalarse en cualquier dispositivo Android"
echo "   ✅ Compartirse con usuarios finales"
echo "   ✅ Subirse a la Play Store (después de firmarlo adecuadamente)"
echo ""
echo "💡 Para instalarlo en tu teléfono:"
echo "   adb install build/app/outputs/flutter-apk/app-release.apk"
echo ""
echo "   O transfiérelo manualmente a tu teléfono"
echo ""
