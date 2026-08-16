#!/bin/bash

echo "========================================="
echo "  COMPILACIÓN PENALEX VE"
echo "  Calculadora de Dosimetría Penal"
echo "========================================="
echo ""

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

cd /home/jeanjazpe/Desktop/Penalex_VE

echo -e "${YELLOW}[1/4] Limpiando build anterior...${NC}"
flutter clean
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Error en flutter clean${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Clean completado${NC}"
echo ""

echo -e "${YELLOW}[2/4] Obteniendo dependencias...${NC}"
flutter pub get
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Error obteniendo dependencias${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Dependencias obtenidas${NC}"
echo ""

echo -e "${YELLOW}[3/4] Analizando código...${NC}"
echo "(Esto puede tardar varios minutos...)"
flutter analyze --no-fatal-infos
if [ $? -ne 0 ]; then
    echo -e "${YELLOW}⚠️  Hay warnings pero continuaremos${NC}"
fi
echo ""

echo -e "${YELLOW}[4/4] Compilando APK Debug...${NC}"
echo "(Esto tomará varios minutos en PC con recursos limitados...)"
flutter build apk --debug --verbose
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Error compilando APK${NC}"
    echo ""
    echo "Si el error es ApiException(10), necesitas:"
    echo "1. Ir a Firebase Console"
    echo "2. Agregar SHA-1: 4A:D2:43:83:36:1B:09:27:65:F5:D3:DC:AF:D1:3A:D9:1C:55:83:EB"
    echo "3. Descargar nuevo google-services.json"
    echo "4. Reemplazar en android/app/google-services.json"
    exit 1
fi
echo -e "${GREEN}✅ APK compilado exitosamente!${NC}"
echo ""

# Mostrar ubicación del APK
APK_PATH="build/app/outputs/flutter-apk/app-debug.apk"
if [ -f "$APK_PATH" ]; then
    echo "========================================="
    echo -e "${GREEN}📱 APK generado en:${NC}"
    echo "$APK_PATH"
    echo ""
    SIZE=$(du -h "$APK_PATH" | cut -f1)
    echo "Tamaño: $SIZE"
    echo "========================================="
else
    echo -e "${RED}⚠️  APK no encontrado en la ubicación esperada${NC}"
fi

echo ""
echo "Para compilar APK Release (más pequeño y optimizado):"
echo "  flutter build apk --release"
echo ""
