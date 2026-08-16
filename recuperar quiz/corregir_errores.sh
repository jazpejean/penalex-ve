#!/bin/bash
# Script para corregir errores críticos de Flutter

echo "🔧 Corrigiendo errores críticos..."

cd /home/jeanjazpe/Desktop/Penalex_VE

# 1. Restaurar archivo corrupto desde git
echo "1️⃣ Restaurando repositorio_jurisprudencia_screen.dart..."
git checkout HEAD -- lib/pages/repositorio_jurisprudencia_screen.dart
if [ $? -eq 0 ]; then
    echo "   ✅ Restaurado exitosamente"
else
    echo "   ⚠️  No se pudo restaurar. Intentar manualmente:"
    echo "      git checkout lib/pages/repositorio_jurisprudencia_screen.dart"
fi

# 2. Verificar errores restantes
echo ""
echo "2️⃣ Verificando errores restantes..."
flutter analyze 2>&1 | grep -E "error •|warning •" | wc -l | xargs echo "   Errores encontrados:"

echo ""
echo "✅ Correcciones aplicadas"
echo ""
echo "📊 Para ver errores críticos solamente:"
echo "   flutter analyze | grep 'error •'"
echo ""
echo "🚀 Para compilar:"
echo "   flutter run"
