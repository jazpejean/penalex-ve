#!/bin/bash
# Script para eliminar archivos experimentales de Flame que causan errores

echo "🔧 Eliminando archivos experimentales de Flame..."
echo ""

cd /home/jeanjazpe/Desktop/Penalex_VE

# Eliminar quiz_lobby_game.dart
if [ -f "lib/games/quiz_lobby_game.dart" ]; then
    rm lib/games/quiz_lobby_game.dart
    echo "✅ Eliminado: lib/games/quiz_lobby_game.dart"
else
    echo "⚠️  No encontrado: lib/games/quiz_lobby_game.dart"
fi

# Eliminar quiz_lobby_screen_flame.dart
if [ -f "lib/pages/quiz_lobby_screen_flame.dart" ]; then
    rm lib/pages/quiz_lobby_screen_flame.dart
    echo "✅ Eliminado: lib/pages/quiz_lobby_screen_flame.dart"
else
    echo "⚠️  No encontrado: lib/pages/quiz_lobby_screen_flame.dart"
fi

echo ""
echo "✅ Limpieza completada"
echo ""
echo "📊 Verificando errores restantes..."
flutter analyze 2>&1 | grep -c "error •" | xargs echo "Errores encontrados:"
echo ""
echo "🚀 Ahora puedes compilar:"
echo "   flutter run"
