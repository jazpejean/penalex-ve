#!/bin/bash

# Script para instalar GStreamer (necesario para audioplayers_linux)
# Creado por Kiro para Penalex VE

set -e

echo "🎵 Instalando GStreamer para soporte de audio..."
echo ""

echo "📥 Instalando librerías de GStreamer..."
sudo apt install -y libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev

echo ""
echo "✅ GStreamer instalado correctamente"
echo ""
echo "🎯 Ahora puedes ejecutar:"
echo "   flutter run"
echo ""
