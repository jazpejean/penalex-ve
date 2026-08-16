#!/usr/bin/env python3
import json

# Cargar notebook base
with open('Scraper_Leyes_Estructura_Colab.ipynb', 'r') as f:
    nb = json.load(f)

# CELDA 1: Instalar dependencias
nb['cells'].append({
    "cell_type": "markdown",
    "source": ["## 📥 CELDA 1: Instalar Dependencias"],
    "metadata": {"id": "celda1-title"}
})

nb['cells'].append({
    "cell_type": "code",
    "source": [
        "print('📦 Instalando PyMuPDF para extraer texto de PDFs...\\n')\n",
        "!pip install -q PyMuPDF\n",
        "print('✅ Dependencias instaladas\\n')\n",
        "print('   - PyMuPDF: Extracción de texto desde PDF')\n",
        "print('   - requests: Ya viene con Colab')\n",
        "print('   - json, re: Librerías estándar de Python')"
    ],
    "metadata": {"id": "celda1-code"},
    "execution_count": None,
    "outputs": []
})

# CELDA 2: Explorar API
nb['cells'].append({
    "cell_type": "markdown",
    "source": ["## 🔍 CELDA 2: Explorar API de IaJuriss"],
    "metadata": {"id": "celda2-title"}
})

nb['cells'].append({
    "cell_type": "code",
    "source": [
        "import requests\n",
        "import json\n",
        "\n",
        "# API de IaJuriss (Supabase)\n",
        "BASE_URL = 'https://khtepgjieasapanfxjft.supabase.co/rest/v1'\n",
        "API_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtodGVwZ2ppZWFzYXBhbmZ4amZ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAxNDY3MzgsImV4cCI6MjA4NTcyMjczOH0.qt3TTd4EniWQevrm0XuxW0H8hsOx1-AIG8u6744mERk'\n",
        "\n",
        "headers = {\n",
        "    'apikey': API_KEY,\n",
        "    'Authorization': f'Bearer {API_KEY}'\n",
        "}\n",
        "\n",
        "print('=' * 70)\n",
        "print('🔍 EXPLORANDO API DE IAJURISS')\n",
        "print('=' * 70)\n",
        "print()\n",
        "\n",
        "# Obtener primeras 10 leyes\n",
        "response = requests.get(\n",
        "    f'{BASE_URL}/leyes_venezolanas',\n",
        "    headers=headers,\n",
        "    params={\n",
        "        'select': 'id,titulo_corto,numero_articulos,nombre_archivo',\n",
        "        'limit': 10,\n",
        "        'esta_vigente': 'eq.true'\n",
        "    }\n",
        ")\n",
        "\n",
        "if response.status_code == 200:\n",
        "    leyes = response.json()\n",
        "    print(f'✅ API conectada - {len(leyes)} leyes obtenidas\\n')\n",
        "    \n",
        "    print('📚 Primeras 10 leyes:')\n",
        "    print('-' * 70)\n",
        "    for ley in leyes:\n",
        "        print(f\"  {ley['id']:5d} | {ley['titulo_corto'][:50]:50s} | Arts: {ley.get('numero_articulos', '?')}\")\n",
        "        if ley.get('nombre_archivo'):\n",
        "            print(f\"         📄 PDF: {ley['nombre_archivo']}\")\n",
        "    \n",
        "    print()\n",
        "    print('✅ Exploración completada')\n",
        "else:\n",
        "    print(f'❌ Error {response.status_code}: {response.text}')"
    ],
    "metadata": {"id": "celda2-code"},
    "execution_count": None,
    "outputs": []
})

# Guardar notebook
with open('Scraper_Leyes_Estructura_Colab.ipynb', 'w') as f:
    json.dump(nb, f, indent=1)

print('✅ Notebook actualizado con 2 celdas')
