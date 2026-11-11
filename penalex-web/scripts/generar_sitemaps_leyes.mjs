#!/usr/bin/env node
/**
 * Penalex VE — Genera el sitemap de la sección /leyes.
 *
 * Lee el manifest filtrado (data/leyes/manifest.json) y cada ley en
 * data/leyes/{slug}.json; produce:
 *   data/sitemaps/sitemap-leyes.xml   (leyes + artículos, un solo sitemap)
 *   data/sitemaps/sitemap.xml         (índice: jurisprudencia-1, -2, leyes)
 *   data/sitemaps/robots.txt          (Allow /sentencias/, /leyes/ + Sitemap)
 *
 * Las URLs son las canónicas: https://{dominio}/leyes/{slug} y
 * https://{dominio}/leyes/{slug}/articulos/{id}.
 *
 * Uso: node scripts/generar_sitemaps_leyes.mjs [dominio]
 *      dominio por defecto: https://penalexve.com
 */
import { readdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const DOMINIO = (process.argv[2] ?? "https://penalexve.com").replace(/\/+$/, "");
const DIR_LEYES = join(ROOT, "data", "leyes");
const DIR_SITEMAPS = join(ROOT, "data", "sitemaps");
const { mkdirSync } = await import("node:fs");
mkdirSync(DIR_SITEMAPS, { recursive: true });

/** Slug de un identificador de artículo (idéntico al worker). */
function slugArticulo(id) {
  const t = String(id || "").trim();
  if (/^\d+$/.test(t)) return t.replace(/^0+/, "") || "0";
  return t
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

function sitemapXml(items) {
  const cuerpo = items
    .map(
      (loc) =>
        `  <url>\n    <loc>${loc}</loc>\n    <changefreq>monthly</changefreq>\n    <priority>${loc.includes("/articulos/") ? "0.7" : "0.8"}</priority>\n  </url>`
    )
    .join("\n");
  return `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n${cuerpo}\n</urlset>\n`;
}

const manifest = JSON.parse(readFileSync(join(DIR_LEYES, "manifest.json"), "utf8"));
// La página raíz /leyes (índice indexable) va primero.
const urls = [`${DOMINIO}/leyes`];

for (const meta of manifest.leyes) {
  const base = `${DOMINIO}/leyes/${meta.slug}`;
  urls.push(base);

  const ruta = join(DIR_LEYES, `${meta.slug}.json`);
  let ley;
  try {
    ley = JSON.parse(readFileSync(ruta, "utf8"));
  } catch {
    console.warn(`⚠️ No se pudo leer ${meta.slug}.json; solo URL de la ley`);
    continue;
  }
  const usados = new Map();
  for (const bloque of ley.estructura || []) {
    for (const art of bloque.articulos || []) {
      let slug = slugArticulo(art.identificador);
      const n = usados.get(slug) || 0;
      usados.set(slug, n + 1);
      if (n > 0) slug = `${slug}-${n + 1}`;
      urls.push(`${base}/articulos/${slug}`);
    }
  }
}

writeFileSync(join(DIR_SITEMAPS, "sitemap-leyes.xml"), sitemapXml(urls));
console.log(`✅ sitemap-leyes.xml: ${urls.length} URLs (${manifest.leyes.length} leyes)`);

// ── sitemap.xml índice ──────────────────────────────────────────────────────
const sitemapIndex = `<?xml version="1.0" encoding="UTF-8"?>
<sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <sitemap><loc>${DOMINIO}/sitemap-jurisprudencia-1.xml</loc></sitemap>
  <sitemap><loc>${DOMINIO}/sitemap-jurisprudencia-2.xml</loc></sitemap>
  <sitemap><loc>${DOMINIO}/sitemap-leyes.xml</loc></sitemap>
</sitemapindex>
`;
writeFileSync(join(DIR_SITEMAPS, "sitemap.xml"), sitemapIndex);

// ── robots.txt ──────────────────────────────────────────────────────────────
// NOTA: la SPA /sentencias y /leyes ya llevan <meta robots=noindex>; NO se
// bloquean por Disallow porque /sentencias/* también contiene los HTML
// individuales indexables (los HTML de sentencias viven bajo /sentencias/...).
const robots = `User-agent: *
Allow: /sentencias/
Allow: /leyes/

Sitemap: ${DOMINIO}/sitemap.xml
`;
writeFileSync(join(DIR_SITEMAPS, "robots.txt"), robots);
console.log("✅ sitemap.xml (índice) y robots.txt regenerados");