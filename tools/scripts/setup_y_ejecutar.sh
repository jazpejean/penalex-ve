#!/bin/bash

echo "🔧 Configurando entorno virtual..."
echo ""

# Crear entorno virtual
python3 -m venv venv

# Activar entorno virtual
source venv/bin/activate

# Instalar dependencias
echo "📦 Instalando dependencias..."
pip install supabase boto3 python-dotenv

echo ""
echo "🚀 Ejecutando auditoría..."
echo ""

# Ejecutar script
python auditoria_completa_local.py

echo ""
echo "✅ Completado!"
