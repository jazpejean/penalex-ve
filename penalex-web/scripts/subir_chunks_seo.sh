#!/usr/bin/env bash
# Sube a R2 todo lo que necesita el SEO de jurisprudencia:
#   1. Chunks de metadatos  → seo_chunks/NNN.json
#   2. Sitemaps + robots    → raíz: sitemap.xml, sitemap-jurisprudencia-*.xml, robots.txt
# Requiere: wrangler login (una vez) o CLOUDFLARE_API_TOKEN con acceso R2.
#
# Uso:  bash scripts/subir_chunks_seo.sh
set -e
cd "$(dirname "$0")/.."

BUCKET="penalex-ve-v2"
ORIGEN_CHUNKS="data/seo_chunks"
ORIGEN_SITEMAPS="data/sitemaps"

if ! command -v wrangler >/dev/null 2>&1; then
  echo "❌ wrangler no está instalado. Instala: npm i -g wrangler"
  exit 1
fi

if [ ! -d "$ORIGEN_CHUNKS" ] || [ ! -d "$ORIGEN_SITEMAPS" ]; then
  echo "❌ Faltan data/seo_chunks o data/sitemaps."
  echo "   Genera primero:"
  echo "     node scripts/generar_chunks_seo.mjs"
  echo "     node scripts/generar_sitemaps.mjs https://sentencias.penalexve.com"
  exit 1
fi

echo "=== Chunks de metadatos ($(ls "$ORIGEN_CHUNKS"/*.json | wc -l)) ==="
i=0
for f in "$ORIGEN_CHUNKS"/*.json; do
  nombre=$(basename "$f")
  wrangler r2 object put "$BUCKET/seo_chunks/$nombre" --file "$f" --remote >/dev/null 2>&1
  i=$((i + 1))
  if [ $((i % 20)) -eq 0 ]; then echo "  … $i"; fi
done
echo "  ✅ $i chunks en r2://$BUCKET/seo_chunks/"

echo "=== Sitemaps + robots.txt ==="
for f in "$ORIGEN_SITEMAPS"/sitemap.xml "$ORIGEN_SITEMAPS"/sitemap-jurisprudencia-1.xml \
         "$ORIGEN_SITEMAPS"/sitemap-jurisprudencia-2.xml "$ORIGEN_SITEMAPS"/sitemap-leyes.xml \
         "$ORIGEN_SITEMAPS"/robots.txt; do
  nombre=$(basename "$f")
  wrangler r2 object put "$BUCKET/$nombre" --file "$f" --remote >/dev/null 2>&1
  echo "  ✅ $nombre"
done

echo ""
echo "✅ Todo subido a r2://$BUCKET/"
echo "Verifica: wrangler r2 object get $BUCKET/seo_chunks/000.json | head"