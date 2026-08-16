#!/bin/bash

# Script para instalar dependencias de Flutter en Linux
# Creado por Kiro para Penalex VE

set -e

echo "📦 Instalando dependencias de Flutter para Linux..."
echo ""

# Actualizar repositorios
echo "🔄 Actualizando repositorios..."
sudo apt update

echo ""
echo "📥 Instalando CMake y dependencias..."
sudo apt install -y cmake ninja-build pkg-config

echo ""
echo "📥 Instalando dependencias de GTK3..."
sudo apt install -y libgtk-3-dev libblkid-dev liblzma-dev

echo ""
echo "📥 Instalando dependencias adicionales..."
sudo apt install -y clang libglu1-mesa-dev

echo ""
echo "📥 Instalando GStreamer (necesario para audio/video)..."
sudo apt install -y libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev

echo ""
echo "✅ ¡Todas las dependencias instaladas!"
echo ""
echo "🎯 Próximos pasos:"
echo "   1. Ejecuta: flutter doctor -v"
echo "   2. Verifica que Linux esté habilitado"
echo "   3. Si prefieres Android, conecta un dispositivo o emulador"
echo "   4. Ejecuta: flutter run"
echo ""
