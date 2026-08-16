#!/bin/bash

# Script completo para compilar APK
# 1. Arregla deprecaciones
# 2. Verifica errores
# 3. Compila APK
# Creado por Kiro para Penalex VE

set -e

echo "🚀 Proceso completo de compilación de APK"
echo "=========================================="
echo ""

# Verificar que estamos en el directorio correcto
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: No se encontró pubspec.yaml"
    exit 1
fi

# Paso 1: Arreglar deprecaciones automáticamente
echo "📝 PASO 1: Arreglando deprecaciones..."
echo "──────────────────────────────────────"
dart fix --apply 2>&1 | tail -10
echo "✅ Arreglos aplicados"
echo ""

# Paso 2: Verificar errores críticos
echo "🔍 PASO 2: Verificando errores críticos..."
echo "──────────────────────────────────────────"
ERROR_COUNT=$(flutter analyze --no-congratulate 2>&1 | grep -c "error •" || echo "0")

if [ "$ERROR_COUNT" -gt "0" ]; then
    echo "❌ Se encontraron $ERROR_COUNT errores:"
    flutter analyze --no-congratulate 2>&1 | grep "error •" | head -20
    echo ""
    echo "🛑 No se puede compilar con errores"
    echo "   Revisa los errores arriba"
    exit 1
else
    echo "✅ No hay errores críticos"
fi
echo ""

# Paso 3: Obtener dependencias
echo "📦 PASO 3: Obteniendo dependencias..."
echo "────────────────────────────────────"
flutter pub get 2>&1 | tail -10
echo "✅ Dependencias actualizadas"
echo ""

# Paso 4: Compilar APK
echo "🔨 PASO 4: Compilando APK..."
echo "────────────────────────────"
echo "⏳ Esto puede tomar 10-15 minutos..."
echo "   Ten paciencia..."
echo ""

flutter build apk --debug 2>&1 | grep -v "│" | grep -v "├" | grep -v "└" | tail -30

echo ""

# Verificar que el APK se generó
if [ -f "build/app/outputs/flutter-apk/app-debug.apk" ]; then
    echo "✅ ¡APK GENERADO EXITOSAMENTE!"
    echo ""
    echo "📍 Ubicación:"
    echo "   $(pwd)/build/app/outputs/flutter-apk/app-debug.apk"
    echo ""
    
    APK_SIZE=$(du -h build/app/outputs/flutter-apk/app-debug.apk | cut -f1)
    echo "📊 Tamaño: $APK_SIZE"
    echo ""
    
    echo "📱 Para instalar en tu teléfono:"
    echo "──────────────────────────────"
    echo ""
    echo "   Opción 1 - Con cable USB:"
    echo "     adb install build/app/outputs/flutter-apk/app-debug.apk"
    echo ""
    echo "   Opción 2 - Manualmente:"
    echo "     1. Copia el APK a tu teléfono"
    echo "     2. Abre el archivo APK"
    echo "     3. Acepta instalar desde fuentes desconocidas"
    echo ""
    echo "   Opción 3 - Google Drive:"
    echo "     1. Sube el APK a Google Drive"
    echo "     2. Descárgalo en tu teléfono"
    echo "     3. Instala"
    echo ""
else
    echo "❌ No se pudo generar el APK"
    echo "   Revisa los errores arriba"
    exit 1
fi

echo "🎉 ¡PROCESO COMPLETADO!"
echo ""
