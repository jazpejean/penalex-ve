#!/bin/bash

echo "🚀 Compilando Penalex VE APK Debug..."
echo ""

cd /home/jeanjazpe/Desktop/Penalex_VE

echo "1️⃣ Limpiando build anterior..."
flutter clean

echo ""
echo "2️⃣ Obteniendo dependencias..."
flutter pub get

echo ""
echo "3️⃣ Compilando APK Debug..."
flutter build apk --debug

echo ""
echo "✅ Proceso completado!"
echo ""
echo "📱 APK ubicado en:"
echo "   build/app/outputs/flutter-apk/app-debug.apk"
echo ""
echo "Para instalar en tu dispositivo:"
echo "   adb install build/app/outputs/flutter-apk/app-debug.apk"
