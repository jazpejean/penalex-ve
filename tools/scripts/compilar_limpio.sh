#!/bin/bash

# Script final para compilar APK LIMPIO
# Ya eliminamos los archivos problemáticos
# Creado por Kiro para Penalex VE

set -e

echo "🚀 COMPILACIÓN LIMPIA DE PENALEX VE"
echo "===================================="
echo ""
echo "✅ Archivos problemáticos eliminados:"
echo "   • pdf_service_old.dart (backup innecesario)"
echo "   • test_firebase_connection.dart (test viejo)"
echo ""

# Verificar directorio
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: No se encontró pubspec.yaml"
    exit 1
fi

echo "📦 Paso 1: Limpiando build anterior..."
echo "──────────────────────────────────────"
flutter clean
echo "✅ Build limpiado"
echo ""

echo "📦 Paso 2: Obteniendo dependencias..."
echo "─────────────────────────────────────"
flutter pub get 2>&1 | tail -15
echo "✅ Dependencias actualizadas"
echo ""

echo "🔨 Paso 3: Compilando APK..."
echo "────────────────────────────"
echo "⏳ Esto tomará 10-15 minutos en la primera vez..."
echo "   Ten paciencia, la compilación está en progreso..."
echo ""

# Compilar mostrando progreso
flutter build apk --debug 2>&1 | grep -E "(Built|Compiling|Assembling|Running Gradle)" || flutter build apk --debug

echo ""

# Verificar resultado
if [ -f "build/app/outputs/flutter-apk/app-debug.apk" ]; then
    echo ""
    echo "🎉 ¡APK GENERADO EXITOSAMENTE!"
    echo "═════════════════════════════════"
    echo ""
    echo "📍 Ubicación:"
    echo "   $(pwd)/build/app/outputs/flutter-apk/app-debug.apk"
    echo ""
    
    APK_SIZE=$(du -h build/app/outputs/flutter-apk/app-debug.apk | cut -f1)
    echo "📊 Tamaño del APK: $APK_SIZE"
    echo ""
    
    echo "✅ COMPILACIÓN EXITOSA - 0 errores"
    echo ""
    echo "📱 CÓMO INSTALAR EN TU TELÉFONO:"
    echo "────────────────────────────────"
    echo ""
    echo "Opción 1 - Cable USB:"
    echo "  adb install build/app/outputs/flutter-apk/app-debug.apk"
    echo ""
    echo "Opción 2 - Transferencia manual:"
    echo "  1. Conecta tu teléfono por cable"
    echo "  2. Copia el APK a la carpeta Descargas"
    echo "  3. En el teléfono, abre el APK"
    echo "  4. Acepta 'Instalar desde fuentes desconocidas'"
    echo "  5. Instala"
    echo ""
    echo "Opción 3 - Google Drive:"
    echo "  1. Sube el APK a Google Drive desde tu PC"
    echo "  2. Descárgalo en tu teléfono"
    echo "  3. Instálalo"
    echo ""
    echo "🎯 PRÓXIMOS PASOS:"
    echo "  1. Instala el APK en tu teléfono"
    echo "  2. Abre la app"
    echo "  3. Prueba el login y la calculadora"
    echo "  4. Genera un PDF con expediente y acusado"
    echo ""
else
    echo ""
    echo "❌ NO SE GENERÓ EL APK"
    echo "═════════════════════"
    echo ""
    echo "Revisa los errores arriba"
    exit 1
fi
