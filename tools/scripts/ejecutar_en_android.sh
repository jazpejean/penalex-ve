#!/bin/bash

# Script para ejecutar Penalex VE en Android (evita problemas de Linux desktop)
# Creado por Kiro para Penalex VE

set -e

echo "📱 Ejecutando Penalex VE en Android..."
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
echo "📱 Dispositivos disponibles:"
flutter devices

echo ""
echo "🔍 Verificando dispositivos Android..."
ANDROID_DEVICES=$(flutter devices | grep -c "android" || echo "0")

if [ "$ANDROID_DEVICES" = "0" ]; then
    echo "⚠️  No hay dispositivos Android conectados"
    echo ""
    echo "📝 Para usar Android:"
    echo "   Opción 1 - Dispositivo físico:"
    echo "     1. Conecta tu teléfono Android por USB"
    echo "     2. Habilita 'Depuración USB' en las opciones de desarrollador"
    echo "     3. Ejecuta este script nuevamente"
    echo ""
    echo "   Opción 2 - Emulador:"
    echo "     1. Abre Android Studio"
    echo "     2. Tools → AVD Manager"
    echo "     3. Crea/inicia un emulador"
    echo "     4. Ejecuta este script nuevamente"
    echo ""
    echo "   Opción 3 - Instalar dependencias de Linux:"
    echo "     1. Ejecuta: ./instalar_dependencias.sh"
    echo "     2. Luego: flutter run"
    echo ""
    exit 1
fi

echo ""
echo "✅ Encontrados $ANDROID_DEVICES dispositivo(s) Android"
echo ""

# Si hay múltiples dispositivos, mostrar lista
if [ "$ANDROID_DEVICES" -gt "1" ]; then
    echo "⚠️  Hay múltiples dispositivos. Selecciona uno:"
    flutter devices
    echo ""
    echo "Ejecuta: flutter run -d <device-id>"
    exit 0
fi

# Ejecutar en Android
echo "🚀 Ejecutando en Android..."
echo "   Presiona 'r' para hot reload"
echo "   Presiona 'R' para hot restart"
echo "   Presiona 'q' para salir"
echo ""

flutter run -d android --verbose

