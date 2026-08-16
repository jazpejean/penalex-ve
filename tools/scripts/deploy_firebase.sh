#!/bin/bash

# Script para desplegar configuración de Firebase
# Creado por Kiro para Penalex VE

set -e

echo "🔥 Desplegando configuración de Firebase..."
echo ""

# Verificar que estamos en el directorio correcto
if [ ! -f "firebase.json" ]; then
    echo "❌ Error: No se encontró firebase.json"
    echo "   Asegúrate de ejecutar este script desde /home/jeanjazpe/Desktop/Penalex_VE"
    exit 1
fi

# Verificar login en Firebase
echo "📋 Verificando autenticación de Firebase..."
if ! firebase projects:list &> /dev/null; then
    echo "⚠️  No estás logueado en Firebase"
    echo "   Ejecutando: firebase login"
    firebase login
fi

echo ""
echo "✅ Autenticación verificada"
echo ""

# Desplegar reglas de Firestore
echo "📤 Desplegando reglas de Firestore..."
firebase deploy --only firestore:rules

echo ""
echo "✅ Reglas de Firestore desplegadas exitosamente"
echo ""

# Mostrar información del proyecto
echo "📊 Información del proyecto:"
firebase projects:list | grep penalex-ve || echo "   Proyecto: penalex-ve"

echo ""
echo "🎉 ¡Despliegue completado!"
echo ""
echo "📝 Próximos pasos:"
echo "   1. Configura el SHA-1 para Google Sign-In (ejecuta: ./get_sha1.sh)"
echo "   2. Ejecuta la app (flutter run)"
echo ""
