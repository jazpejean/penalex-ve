#!/bin/bash

echo "🔍 Ejecutando auditoría completa..."
echo ""
echo "📦 Instalando dependencias..."
pip3 install supabase boto3 python-dotenv -q

echo ""
echo "🚀 Ejecutando script..."
python3 auditoria_completa_local.py > auditoria_resultado.txt 2>&1

echo ""
echo "✅ Auditoría completada!"
echo ""
echo "📄 Resultado guardado en: auditoria_resultado.txt"
echo ""
echo "Para ver el resultado:"
echo "  cat auditoria_resultado.txt"
echo ""
