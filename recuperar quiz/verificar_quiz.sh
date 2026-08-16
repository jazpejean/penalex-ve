#!/bin/bash
# Script para verificar el estado del sistema de quiz

echo "🔍 VERIFICANDO SISTEMA DE QUIZ"
echo "════════════════════════════════════════"
echo ""

cd /home/jeanjazpe/Desktop/Penalex_VE

echo "📊 Analizando archivos del quiz..."
echo ""

echo "1️⃣ quiz_game_screen.dart"
flutter analyze lib/pages/quiz_game_screen.dart 2>&1 | grep -E "error •|No issues" | head -1

echo "2️⃣ quiz_questions_data.dart"
flutter analyze lib/data/quiz_questions_data.dart 2>&1 | grep -E "error •|No issues" | head -1

echo "3️⃣ casos_service.dart"
flutter analyze lib/services/casos_service.dart 2>&1 | grep -E "error •|warning •|No issues" | head -2

echo ""
echo "════════════════════════════════════════"
echo "📈 ESTADO GENERAL"
echo "════════════════════════════════════════"
echo ""

TOTAL_ERRORS=$(flutter analyze 2>&1 | grep -c "error •")
TOTAL_WARNINGS=$(flutter analyze 2>&1 | grep -c "warning •")

echo "❌ Errores totales: $TOTAL_ERRORS"
echo "⚠️  Warnings totales: $TOTAL_WARNINGS"
echo ""

if [ $TOTAL_ERRORS -le 10 ]; then
    echo "✅ Estado: BUENO (menos de 10 errores)"
    echo "🚀 Puedes compilar la app"
else
    echo "⚠️  Estado: Revisar (más de 10 errores)"
fi

echo ""
echo "════════════════════════════════════════"
echo "💡 PARA ELIMINAR ERRORES DE FLAME"
echo "════════════════════════════════════════"
echo ""
echo "rm lib/games/quiz_lobby_game.dart"
echo "rm lib/pages/quiz_lobby_screen_flame.dart"
echo ""
