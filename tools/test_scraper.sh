#!/bin/bash
# Script de prueba rápida del scraper

echo "🧪 Test del Scraper de Leyes Venezolanas"
echo "========================================"
echo ""

# Verificar Python
echo "1️⃣ Verificando Python..."
if command -v python3 &> /dev/null; then
    python3 --version
    echo "✅ Python instalado"
else
    echo "❌ Python no encontrado. Instalar con: sudo apt install python3"
    exit 1
fi

# Crear entorno virtual si no existe
if [ ! -d "venv" ]; then
    echo ""
    echo "2️⃣ Creando entorno virtual..."
    python3 -m venv venv
    echo "✅ Entorno virtual creado"
fi

# Activar entorno virtual
echo ""
echo "3️⃣ Activando entorno virtual..."
source venv/bin/activate
echo "✅ Entorno activado"

# Instalar dependencias
echo ""
echo "4️⃣ Instalando dependencias..."
pip install -q -r requirements_scraper.txt
echo "✅ Dependencias instaladas"

# Listar leyes disponibles
echo ""
echo "5️⃣ Leyes disponibles para scraping:"
echo "-----------------------------------"
python scraper_leyes_ve.py --listar

# Preguntar si quiere hacer prueba
echo ""
read -p "¿Quieres scrappear una ley de prueba? (LCDOFT) [s/N]: " respuesta

if [[ "$respuesta" =~ ^[Ss]$ ]]; then
    echo ""
    echo "6️⃣ Scrappeando LCDOFT (prueba)..."
    python scraper_leyes_ve.py --ley lcdoft
    
    echo ""
    echo "7️⃣ Verificando JSON generado..."
    if [ -f "../leyes_json/lcdoft_scraped.json" ]; then
        articulos=$(python3 -c "import json; data=json.load(open('../leyes_json/lcdoft_scraped.json')); print(sum(len(c.get('articulos', [])) for t in data['estructura'] for c in t.get('capitulos', [])))")
        echo "✅ JSON generado correctamente"
        echo "📊 Total de artículos extraídos: $articulos"
        echo ""
        echo "Archivo: ../leyes_json/lcdoft_scraped.json"
    else
        echo "❌ No se generó el archivo JSON"
    fi
else
    echo "Prueba omitida."
fi

echo ""
echo "🎉 Test completado!"
echo ""
echo "Próximos pasos:"
echo "1. Scrappear todas las leyes: python scraper_leyes_ve.py --todas"
echo "2. Ver documentación completa: cat README_SCRAPER.md"
echo ""
