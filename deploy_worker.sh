#!/usr/bin/env bash
# Despliega el worker "penalex-quiz-generador" a Cloudflare Workers.
#
# Requisitos: añadir a .env (raíz del repo) dos líneas:
#   CLOUDFLARE_API_TOKEN=<token con permisos: Workers Scripts:Edit + R2>
#   CLOUDFLARE_ACCOUNT_ID=<tu account id de Cloudflare>
#
# El motor principal es Workers AI (cuota gratuita de 10.000 neuronas/día);
# DeepSeek queda como respaldo (secret). La clave QUIZ_API_KEY (para llamar a
# POST /generar) se genera nueva en cada deploy si no está en .env.
set -euo pipefail
cd "$(dirname "$0")/worker"

# Lectura segura del .env: extrae solo las claves que necesitamos (sin
# "source", porque valores como "Penalex VE" romperían el parsing).
get_env() {
  grep -E "^${1}=" ../.env | head -1 | cut -d= -f2- \
    | sed -e 's/^["'\'']//' -e 's/["'\'']$//' -e 's/\r$//' || true
}

CLOUDFLARE_API_TOKEN="$(get_env CLOUDFLARE_API_TOKEN)"
CLOUDFLARE_ACCOUNT_ID="$(get_env CLOUDFLARE_ACCOUNT_ID)"
SUPABASE_URL="$(get_env SUPABASE_URL)"
SUPABASE_ANON_KEY="$(get_env SUPABASE_ANON_KEY)"
SUPABASE_SERVICE_KEY="$(get_env SUPABASE_SERVICE_KEY)"
DEEPSEEK_API_KEY="$(get_env DEEPSEEK_API_KEY)"
QUIZ_API_KEY="$(get_env QUIZ_API_KEY)"

: "${CLOUDFLARE_API_TOKEN:?Falta CLOUDFLARE_API_TOKEN en .env}"
: "${CLOUDFLARE_ACCOUNT_ID:?Falta CLOUDFLARE_ACCOUNT_ID en .env}"
: "${SUPABASE_URL:?Falta SUPABASE_URL en .env}"
: "${SUPABASE_ANON_KEY:?Falta SUPABASE_ANON_KEY en .env}"
: "${SUPABASE_SERVICE_KEY:?Falta SUPABASE_SERVICE_KEY en .env}"

export CLOUDFLARE_API_TOKEN CLOUDFLARE_ACCOUNT_ID

# 1. Desplegar (vars no secretas; si no hay QUIZ_API_KEY en .env, se genera una)
QUIZ_API_KEY="${QUIZ_API_KEY:-$(openssl rand -hex 16)}"
if [ -z "${QUIZ_API_KEY:-}" ]; then
  echo "QUIZ_API_KEY generada: ${QUIZ_API_KEY}" >&2
fi
npx wrangler deploy \
  --var "SUPABASE_URL:${SUPABASE_URL}" \
  --var "SUPABASE_ANON_KEY:${SUPABASE_ANON_KEY}" \
  --var "QUIZ_API_KEY:${QUIZ_API_KEY}"

# 2. Secretos (service key + DeepSeek como respaldo)
echo "${SUPABASE_SERVICE_KEY}" | npx wrangler secret put SUPABASE_SERVICE_KEY
echo "${DEEPSEEK_API_KEY}" | npx wrangler secret put DEEPSEEK_API_KEY

echo ""
echo "✅ Worker desplegado. Comprobación rápida:"
echo "   curl https://penalex-quiz-generador.<subdominio>.workers.dev/health"
echo ""
echo "🔑 Guarda QUIZ_API_KEY: ${QUIZ_API_KEY}"
echo "   (se usa en el header x-api-key para POST /generar; p. ej. el panel de validación)"