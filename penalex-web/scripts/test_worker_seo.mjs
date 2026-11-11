#!/usr/bin/env node
/**
 * Test local del worker SEO (sin Cloudflare): stub de HTMLRewriter + R2.
 * Verifica que /html/* inyecta title/meta/canonical/JSON-LD en un HTML real.
 *
 * Uso: node scripts/test_worker_seo.mjs
 */
import { readFileSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");

// ---- Stub de HTMLRewriter (solo el caso que usa el worker: on('head')) ----
class El {
  constructor(tag) {
    this.tag = tag;
    this.contenido = "";
  }
  append(html) {
    this.contenido += html;
  }
}
class Rewriter {
  on(selector, handlers) {
    this.selector = selector;
    this.handlers = handlers;
    return this;
  }
  transform(response) {
    return Promise.resolve(response).then((r) => r.text().then((html) => {
      const el = new El(this.selector);
      this.handlers.element(el);
      // Inserta el contenido del head antes de </head>
      const nuevo = html.replace("</head>", el.contenido + "</head>");
      return new Response(nuevo, { headers: { "content-type": "text/html; charset=utf-8" } });
    }));
  }
}
globalThis.HTMLRewriter = Rewriter;

// ---- Stub de R2 ----
const chunksDir = join(ROOT, "data", "seo_chunks");
const chunkCache = new Map();
const r2Stub = {
  async get(key) {
    if (key.startsWith("seo_chunks/")) {
      const nombre = key.split("/")[1];
      const ruta = join(chunksDir, nombre);
      try {
        const txt = readFileSync(ruta, "utf8");
        return { async text() { return txt; } };
      } catch {
        return null;
      }
    }
    // HTML real de una sentencia (descargado del bucket público para el test)
    if (key === "html/scon/2004/2061-090904-02-0595.html") {
      const txt = readFileSync("/tmp/real_sentencia.html", "utf8");
      return { size: txt.length, async text() { return txt; }, async arrayBuffer() { return Buffer.from(txt); } };
    }
    // HTML en blanco (defecto de la fuente TSJ): debe responder 404
    if (key === "html/scp/2010/0000-0000-00-0000.html") {
      return { size: 500, async text() { return "<html><head></head><body></body></html>"; }, async arrayBuffer() { return Buffer.from("<html><head></head><body></body></html>"); } };
    }
    return null;
  },
};

// ---- Importar el módulo real ----
const { servirHtmlConSeo } = await import(
  new URL(`file://${ROOT}/../worker-auth-bridge/src/seo_jurisprudencia.js`)
);

// ---- HTML de sentencia real (estilo Word, sin metadatos) ----
// Se usa el archivo descargado: /tmp/real_sentencia.html
// (la URL real incluye el prefijo html/: html/scon/2004/2061-090904-02-0595.html)

const env = {
  R2_JURISPRUDENCIA: r2Stub,
  SITIO_JURISPRUDENCIA: "https://penalexve.com",
};

const url = new URL("https://penalexve.com/sentencias/scon/2004/2061-090904-02-0595.html");
const res = await servirHtmlConSeo(env, url);

if (res.status === 404) {
  console.error("❌ 404: no encontró el HTML (el stub no sirve html/, solo seo_chunks/)");
  process.exit(1);
}

const texto = await res.text();

// ---- Aserciones ----
const checks = [
  ["<title>", /<title>Sentencia Nº 2061[^<]*Sala Constitucional[^<]*<\/title>/],
  ["meta description", /<meta name="description" content="[^"]+">/],
  ["canonical ruta /sentencias/", /<link rel="canonical" href="https:\/\/penalexve\.com\/sentencias\/scon\/2004\/2061-090904-02-0595\.html">/],
  ["JSON-LD LegalCase", /"@type"\s*:\s*"LegalCase"/],
  ["JSON-LD court", /"@type"\s*:\s*"Court"/],
  ["JSON-LD judge (ponente)", /Pedro Rafael Rondón Haaz/],
  ["JSON-LD datePublished", /2004-09-09/],
  ["og:locale", /og:locale" content="es_VE"/],
];

let fallos = 0;
for (const [nombre, re] of checks) {
  const ok = re.test(texto);
  console.log(`${ok ? "✅" : "❌"} ${nombre}`);
  if (!ok) fallos++;
}

if (fallos > 0) {
  console.error(`\n❌ ${fallos} comprobaciones fallaron. HTML generado:\n---\n${texto.slice(0, 1500)}`);
  process.exit(1);
}

console.log(`\n✅ Worker SEO validado: inyección correcta (${texto.length} bytes de salida)`);

// ---- Test del HTML en blanco: debe responder 404 ----
const urlBlanco = new URL("https://penalexve.com/sentencias/scp/2010/0000-0000-00-0000.html");
const resBlanco = await servirHtmlConSeo(env, urlBlanco);
if (resBlanco.status !== 404) {
  console.error(`❌ HTML en blanco debería dar 404, dio ${resBlanco.status}`);
  process.exit(1);
}
console.log("✅ HTML en blanco rechazado con 404 (no se indexa)");