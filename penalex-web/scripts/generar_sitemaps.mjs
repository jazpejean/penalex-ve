#!/usr/bin/env node
/**
 * Penalex VE — Genera sitemaps estáticos de jurisprudencia para subir a R2.
 *
 * Lee data/sentencias.json y data/escaneo_r2.json (si existe; excluye las
 * sentencias en blanco/defectuosas de la fuente TSJ). Produce:
 *   data/sitemaps/sitemap-jurisprudencia-1.xml  (hasta 50.000 URLs)
 *   data/sitemaps/sitemap-jurisprudencia-2.xml  (resto)
 *   data/sitemaps/sitemap.xml                   (índice de sitemaps)
 *   data/sitemaps/robots.txt                    (Allow /sentencias/ + Sitemap)
 *
 * Las URLs usan la ruta pública canónica: https://{dominio}/sentencias/...
 * (el worker mapea /sentencias/* → key html/* del bucket).
 *
 * Uso: node scripts/generar_sitemaps.mjs [dominio]
 *      dominio por defecto: https://penalexve.com
 */
import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const DOMINIO = (process.argv[2] ?? "https://penalexve.com").replace(/\/+$/, "");
const LIMITE = 50000;

const payload = JSON.parse(readFileSync(join(ROOT, "data", "sentencias.json"), "utf8"));

// Excluir sentencias en blanco detectadas por el escaneo de R2.
const escaneoPath = join(ROOT, "data", "exclusiones_seo.json");
let excluidas = new Set();
try {
  const escaneo = JSON.parse(readFileSync(escaneoPath, "utf8"));
  // exclusiones_seo.json: { ausentes: [], en_blanco: [], ... }
  excluidas = new Set([...(escaneo.ausentes ?? []), ...(escaneo.en_blanco ?? [])]);
  if (excluidas.size > 0) {
    console.log(`⚠️ Excluyendo ${excluidas.size} sentencias en blanco (escaneo R2)`);
  }
} catch {
  console.log("ℹ️ Sin exclusiones_seo.json: no se excluyen sentencias en blanco");
}

// URL pública: https://dominio/sentencias/... (sin el prefijo html/ del key).
// encodeURI escapa espacios y caracteres no-ASCII del nombre real del archivo
// (p. ej. "2056-090904-03-1468 .html" → "...1468%20.html"); el worker
// decodifica %20 al resolver la key en R2.
const sentencias = payload.sentencias.filter((s) => !excluidas.has(s.r2_html_key));
const urls = sentencias.map((s) => {
  const ruta = String(s.r2_html_key).replace(/^html\//, "");
  return `${DOMINIO}/sentencias/${encodeURI(ruta)}`;
});

function sitemapXml(items) {
  const cuerpo = items
    .map(
      (loc) =>
        `  <url>\n    <loc>${loc}</loc>\n    <changefreq>monthly</changefreq>\n    <priority>0.6</priority>\n  </url>`
    )
    .join("\n");
  return `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n${cuerpo}\n</urlset>\n`;
}

const salida = join(ROOT, "data", "sitemaps");
mkdirSync(salida, { recursive: true });

// La página raíz /sentencias (buscador indexable) va primero en el sitemap 1.
const conRaiz = [`${DOMINIO}/sentencias`, ...urls];

writeFileSync(join(salida, "sitemap-jurisprudencia-1.xml"), sitemapXml(conRaiz.slice(0, LIMITE)));
writeFileSync(join(salida, "sitemap-jurisprudencia-2.xml"), sitemapXml(conRaiz.slice(LIMITE)));

const indexXml = `<?xml version="1.0" encoding="UTF-8"?>\n<sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n  <sitemap>\n    <loc>${DOMINIO}/sitemap-jurisprudencia-1.xml</loc>\n  </sitemap>\n  <sitemap>\n    <loc>${DOMINIO}/sitemap-jurisprudencia-2.xml</loc>\n  </sitemap>\n</sitemapindex>\n`;
writeFileSync(join(salida, "sitemap.xml"), indexXml);

const robots = `User-agent: *\nAllow: /sentencias/\nDisallow: /\n\nSitemap: ${DOMINIO}/sitemap.xml\n`;
writeFileSync(join(salida, "robots.txt"), robots);

const totalUrls = urls.length;
const partes = Math.ceil(totalUrls / LIMITE);
console.log(`✅ ${totalUrls} URLs (${payload.sentencias.length - totalUrls} excluidas) → ${partes} sitemaps + índice + robots.txt`);
console.log(`Dominio usado: ${DOMINIO}`);
console.log(`Ejemplo: ${urls[0]}`);
console.log(`  → subir a r2://penalex-jurisprudencia/ (raíz): sitemap.xml, sitemap-jurisprudencia-*.xml, robots.txt`);