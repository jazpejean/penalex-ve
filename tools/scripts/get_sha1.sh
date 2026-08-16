#!/bin/bash

# Script para obtener SHA-1 fingerprint para Google Sign-In
# Creado por Kiro para Penalex VE

set -e

echo "🔑 Obteniendo SHA-1 fingerprint para Google Sign-In..."
echo ""

# Verificar que estamos en el directorio correcto
if [ ! -d "android" ]; then
    echo "❌ Error: No se encontró el directorio android"
    echo "   Asegúrate de ejecutar este script desde /home/jeanjazpe/Desktop/Penalex_VE"
    exit 1
fi

cd android

echo "⏳ Ejecutando ./gradlew signingReport..."
echo "   (Esto puede tomar unos minutos...)"
echo ""

# Ejecutar gradlew y filtrar resultados
./gradlew signingReport 2>&1 | grep -A 3 "Variant: debug" | grep SHA1

echo ""
echo "✅ SHA-1 obtenido exitosamente"
echo ""
echo "📝 Próximos pasos:"
echo "   1. Copia el SHA-1 de arriba"
echo "   2. Ve a: https://console.firebase.google.com/"
echo "   3. Selecciona el proyecto: penalex-ve"
echo "   4. Ve a: Configuración del proyecto → Tu app Android"
echo "   5. Click en 'Agregar huella digital'"
echo "   6. Pega el SHA-1"
echo "   7. Descarga el nuevo google-services.json"
echo "   8. Reemplázalo en: android/app/google-services.json"
echo ""

cd ..
