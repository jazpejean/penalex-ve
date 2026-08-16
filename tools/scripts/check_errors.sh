#!/bin/bash

# Script para verificar errores específicos en dosimetria_page.dart

echo "=== Limpiando caché de Flutter ==="
flutter clean 2>&1 | tail -5

echo ""
echo "=== Ejecutando pub get ==="
flutter pub get 2>&1 | tail -10

echo ""
echo "=== Analizando solo dosimetria_page.dart ==="
dart analyze lib/pages/dosimetria_page.dart 2>&1 | head -50

echo ""
echo "=== Contando errores totales ==="
flutter analyze 2>&1 | grep -c "error •"

echo ""
echo "===  Intentando compilación rápida ==="
flutter build apk --debug --no-tree-shake-icons 2>&1 | tail -20
