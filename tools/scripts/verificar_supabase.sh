#!/bin/bash

# Script rápido para verificar cuántos documentos hay en Supabase por tipo/sala

echo "🔍 VERIFICANDO SUPABASE..."
echo "=========================================="
echo ""

SUPABASE_URL="https://efxzcglhyosrxtafirhs.supabase.co"
ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVmeHpjZ2xoeW9zcnh0YWZpcmhzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY0MDMxODgsImV4cCI6MjEwMTk3OTE4OH0.LYkvBjiO1l11hnRZsYIuFf2ZaQ3ShP9sU43HYB5l4_0"

echo "📊 TOTAL DE DOCUMENTOS:"
curl -s "${SUPABASE_URL}/rest/v1/documentos?select=count" \
  -H "apikey: ${ANON_KEY}" \
  -H "Authorization: Bearer ${ANON_KEY}" \
  | jq '.[0].count'

echo ""
echo "📋 POR TIPO Y SALA:"
echo "=========================================="

# Sentencias Constitucionales
echo -n "Sentencias Constitucionales:    "
curl -s "${SUPABASE_URL}/rest/v1/documentos?tipo=eq.sentencia&sala=eq.constitucional&select=count" \
  -H "apikey: ${ANON_KEY}" \
  -H "Authorization: Bearer ${ANON_KEY}" \
  | jq -r '.[0].count // 0'

# Sentencias Penales
echo -n "Sentencias Penales:             "
curl -s "${SUPABASE_URL}/rest/v1/documentos?tipo=eq.sentencia&sala=eq.penal&select=count" \
  -H "apikey: ${ANON_KEY}" \
  -H "Authorization: Bearer ${ANON_KEY}" \
  | jq -r '.[0].count // 0'

# Sustanciación
echo -n "Sentencias Sustanciación:       "
curl -s "${SUPABASE_URL}/rest/v1/documentos?tipo=eq.sentencia&sala=eq.sustanciacion&select=count" \
  -H "apikey: ${ANON_KEY}" \
  -H "Authorization: Bearer ${ANON_KEY}" \
  | jq -r '.[0].count // 0'

# Jurisprudencia Penal
echo -n "Jurisprudencia Penal:           "
curl -s "${SUPABASE_URL}/rest/v1/documentos?tipo=eq.jurisprudencia&sala=eq.penal&select=count" \
  -H "apikey: ${ANON_KEY}" \
  -H "Authorization: Bearer ${ANON_KEY}" \
  | jq -r '.[0].count // 0'

# Jurisprudencia Constitucional
echo -n "Jurisprudencia Constitucional:  "
curl -s "${SUPABASE_URL}/rest/v1/documentos?tipo=eq.jurisprudencia&sala=eq.constitucional&select=count" \
  -H "apikey: ${ANON_KEY}" \
  -H "Authorization: Bearer ${ANON_KEY}" \
  | jq -r '.[0].count // 0'

# Resoluciones Sala Plena
echo -n "Resoluciones Sala Plena:        "
curl -s "${SUPABASE_URL}/rest/v1/documentos?tipo=eq.resoluciones&sala=eq.plena&select=count" \
  -H "apikey: ${ANON_KEY}" \
  -H "Authorization: Bearer ${ANON_KEY}" \
  | jq -r '.[0].count // 0'

echo ""
echo "=========================================="
echo ""
echo "📈 COMPARACIÓN CON DRIVE:"
echo "=========================================="
echo "Drive esperado (total):          73,345"
echo "  - Sala_Constitucional:         51,316"
echo "  - Sala_Penal:                  16,604"
echo "  - Sustanciacion:                  986"
echo "  - Juris Penal:                  3,714"
echo "  - Juris Constitucional:           725"
echo "  - Sala_Plena (resoluciones):      366  ← FALTAN"
echo ""
