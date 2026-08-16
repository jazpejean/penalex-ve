#!/bin/bash

# Script de instalación de Docker y Supabase CLI
# Ejecuta este script con: bash install_supabase.sh

echo "=========================================="
echo "Instalación de Docker y Supabase CLI"
echo "=========================================="
echo ""

# Verificar si ya está instalado Docker
if command -v docker &> /dev/null; then
    echo "✓ Docker ya está instalado"
    docker --version
else
    echo "📦 Instalando Docker..."
    echo ""
    
    # 1. Actualizar el sistema
    echo "Actualizando el sistema..."
    sudo apt-get update
    
    # 2. Instalar dependencias
    echo "Instalando dependencias..."
    sudo apt-get install -y ca-certificates curl gnupg lsb-release
    
    # 3. Agregar llave GPG de Docker
    echo "Configurando repositorio de Docker..."
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    # 4. Configurar repositorio
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # 5. Instalar Docker
    echo "Instalando Docker Engine..."
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # 6. Agregar usuario al grupo docker
    echo "Agregando usuario al grupo docker..."
    sudo usermod -aG docker $USER
    
    # 7. Iniciar Docker
    echo "Iniciando servicio Docker..."
    sudo systemctl start docker
    sudo systemctl enable docker
    
    echo "✓ Docker instalado correctamente"
    docker --version
fi

echo ""
echo "=========================================="

# Verificar si ya está instalado Supabase CLI
if command -v supabase &> /dev/null; then
    echo "✓ Supabase CLI ya está instalado"
    supabase --version
else
    echo "📦 Instalando Supabase CLI..."
    echo ""
    
    # Descargar e instalar Supabase CLI
    cd /tmp
    echo "Descargando Supabase CLI..."
    curl -L https://github.com/supabase/cli/releases/latest/download/supabase_linux_amd64.tar.gz -o supabase.tar.gz
    
    echo "Extrayendo archivos..."
    tar -xzf supabase.tar.gz
    
    echo "Instalando en /usr/local/bin..."
    sudo mv supabase /usr/local/bin/
    
    echo "Limpiando archivos temporales..."
    rm supabase.tar.gz
    
    echo "✓ Supabase CLI instalado correctamente"
    supabase --version
fi

echo ""
echo "=========================================="
echo "¡Instalación completada!"
echo "=========================================="
echo ""
echo "IMPORTANTE: Necesitas cerrar sesión y volver a iniciar sesión"
echo "para que los cambios del grupo docker surtan efecto."
echo ""
echo "Después de reiniciar sesión, ejecuta:"
echo "  docker ps"
echo ""
echo "Si no te pide contraseña, puedes continuar con:"
echo "  cd /home/jeanjazpe/Desktop/Penalex_VE"
echo "  supabase init --yes"
echo "  supabase start"
echo ""
