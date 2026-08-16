#!/bin/bash

# Script para generar APK sin ejecutar Flutter en modo debug
# Ideal para PCs con bajos recursos
# Creado por Kiro para Penalex VE

set -e

echo "📦 Generando APK de Penalex VE..."
echo ""
echo "⚠️  Esto tomará unos minutos pero NO consumirá tantos recursos como flutter run"
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
echo "🔨 Compilando APK de debug..."
echo "   (Esto puede tardar 5-10 minutos en la primera vez)"
echo ""

flutter build apk --debug

echo ""
echo "✅ ¡APK generado exitosamente!"
echo ""
echo "📍 Ubicación del APK:"
echo "   $(pwd)/build/app/outputs/flutter-apk/app-debug.apk"
echo ""
echo "📱 Para instalarlo:"
echo ""
echo "   Opción 1 - Conectar teléfono por USB:"
echo "     1. Conecta tu teléfono Android"
echo "     2. Habilita 'Depuración USB'"
echo "     3. Ejecuta: adb install build/app/outputs/flutter-apk/app-debug.apk"
echo ""
echo "   Opción 2 - Transferir manualmente:"
echo "     1. Copia el APK a tu teléfono (por cable, Bluetooth, etc.)"
echo "     2. Abre el APK en tu teléfono"
echo "     3. Acepta instalar desde fuentes desconocidas"
echo ""
echo "   Opción 3 - Subir a Google Drive:"
echo "     1. Sube el APK a Google Drive"
echo "     2. Descárgalo desde tu teléfono"
echo "     3. Instálalo"
echo ""

# Mostrar tamaño del APK
APK_SIZE=$(du -h build/app/outputs/flutter-apk/app-debug.apk | cut -f1)
echo "📊 Tamaño del APK: $APK_SIZE"
echo ""
