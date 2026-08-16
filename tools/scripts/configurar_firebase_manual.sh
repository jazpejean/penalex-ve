#!/bin/bash

# Script para configurar Firebase sin ejecutar la app
# Creado por Kiro para Penalex VE

set -e

echo "🔥 Configuración manual de Firebase para Penalex VE"
echo ""
echo "📋 Pasos a seguir:"
echo ""

echo "1️⃣  DESPLEGAR REGLAS DE FIRESTORE"
echo "────────────────────────────────────"
echo ""

# Verificar si firebase CLI está disponible
if command -v firebase &> /dev/null; then
    echo "✅ Firebase CLI encontrado"
    echo ""
    echo "Desplegando reglas..."
    firebase deploy --only firestore:rules
    echo ""
    echo "✅ Reglas desplegadas"
else
    echo "⚠️  Firebase CLI no encontrado"
    echo ""
    echo "Instálalo con: npm install -g firebase-tools"
    echo "Luego ejecuta: firebase login"
    echo "Y finalmente: firebase deploy --only firestore:rules"
fi

echo ""
echo "2️⃣  HABILITAR MÉTODOS DE AUTENTICACIÓN"
echo "────────────────────────────────────────"
echo ""
echo "Ve a: https://console.firebase.google.com/project/penalex-ve/authentication/providers"
echo ""
echo "✅ Habilita:"
echo "   • Email/Password"
echo "   • Google"
echo ""

echo ""
echo "3️⃣  CONFIGURAR SHA-1 PARA GOOGLE SIGN-IN"
echo "──────────────────────────────────────────"
echo ""

if [ -f "android/gradlew" ]; then
    echo "Obteniendo SHA-1..."
    echo ""
    cd android
    ./gradlew signingReport 2>&1 | grep SHA1 || echo "⚠️ No se pudo obtener SHA-1 automáticamente"
    cd ..
    echo ""
    echo "Copia el SHA-1 de arriba y agrégalo en:"
    echo "https://console.firebase.google.com/project/penalex-ve/settings/general/android:com.penalex.ve"
else
    echo "⚠️ No se encontró gradlew"
    echo ""
    echo "Obtén el SHA-1 manualmente:"
    echo "   cd android"
    echo "   ./gradlew signingReport"
fi

echo ""
echo "4️⃣  VERIFICAR DOMINIOS AUTORIZADOS"
echo "────────────────────────────────────"
echo ""
echo "Ve a: https://console.firebase.google.com/project/penalex-ve/authentication/settings"
echo ""
echo "✅ Verifica que existan:"
echo "   • localhost"
echo "   • penalex-ve.firebaseapp.com"
echo ""

echo ""
echo "5️⃣  CREAR USUARIO DE PRUEBA (OPCIONAL)"
echo "────────────────────────────────────────"
echo ""
echo "Ve a: https://console.firebase.google.com/project/penalex-ve/authentication/users"
echo ""
echo "✅ Click en 'Add user' y crea:"
echo "   Email: test@penalex.com"
echo "   Password: Test123456"
echo ""
echo "Luego verifica el email manualmente desde la consola"
echo ""

echo ""
echo "✅ CONFIGURACIÓN COMPLETADA"
echo "───────────────────────────"
echo ""
echo "🎯 Próximo paso:"
echo "   Genera el APK con: ./generar_apk.sh"
echo "   Instálalo en tu teléfono y prueba el login"
echo ""
