#!/bin/bash

# Script para ejecutar y probar la app
# Creado por Kiro para Penalex VE

set -e

echo "🧪 Preparando para ejecutar Penalex VE..."
echo ""

# Verificar que estamos en el directorio correcto
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: No se encontró pubspec.yaml"
    echo "   Asegúrate de ejecutar este script desde /home/jeanjazpe/Desktop/Penalex_VE"
    exit 1
fi

# Verificar Flutter
echo "📋 Verificando Flutter..."
if ! command -v flutter &> /dev/null; then
    echo "❌ Error: Flutter no está instalado o no está en el PATH"
    exit 1
fi

flutter --version
echo ""

# Limpiar build anterior
echo "🧹 Limpiando build anterior..."
flutter clean
echo ""

# Obtener dependencias
echo "📦 Obteniendo dependencias..."
flutter pub get
echo ""

# Listar dispositivos disponibles
echo "📱 Dispositivos disponibles:"
flutter devices
echo ""

# Ejecutar app
echo "🚀 Ejecutando app..."
echo "   Presiona Ctrl+C para detener"
echo ""
flutter run --verbose

