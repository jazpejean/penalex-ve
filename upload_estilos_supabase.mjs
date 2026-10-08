/**
 * Sube el banco de estilos (assets/estilos/**) a Supabase Storage (bucket
 * "estilos") preservando la estructura de categorías y regenera manifest.json.
 *
 * Supabase Storage rechaza acentos y paréntesis en las claves, así que las
 * claves del bucket se sanitizan (sin acentos) y el manifest conserva el
 * NOMBRE ORIGINAL para mostrar en la app:
 *   manifest.json = { categoria: [ { slug, nombre }, ... ] }
 *
 * La app intenta primero Supabase y cae a los assets locales si no hay red.
 *
 * Uso: node upload_estilos_supabase.mjs
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const SUPABASE_URL = 'https://efxzcglhyosrxtafirhs.supabase.co';
const SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVmeHpjZ2xoeW9zcnh0YWZpcmhzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4NjQwMzE4OCwiZXhwIjoyMTAxOTc5MTg4fQ.-c7sFMAIvR778_yv3b9TiIVtfoYOx48v3xC-czB_ZJg';
const BUCKET = 'estilos';
const ORIGEN = path.join(__dirname, 'assets', 'estilos');

async function req(method, url, body, contentType = 'application/json') {
  const res = await fetch(url, {
    method,
    headers: {
      Authorization: `Bearer ${SERVICE_KEY}`,
      'x-upsert': 'true',
      ...(contentType ? { 'Content-Type': contentType } : {}),
    },
    body,
  });
  return res;
}

/** Clave segura para Supabase Storage: sin acentos, sin paréntesis, espacios simples. */
function slugKey(name) {
  return name
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[()]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

/** Recorre assets/estilos y devuelve {rel, abs} de cada .txt */
function listarTextos(dir, base = '') {
  const out = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const rel = base ? `${base}/${entry.name}` : entry.name;
    if (entry.isDirectory()) {
      out.push(...listarTextos(path.join(dir, entry.name), rel));
    } else if (entry.name.endsWith('.txt')) {
      out.push({ rel, abs: path.join(dir, entry.name) });
    }
  }
  return out;
}

async function main() {
  // 1. Recrear bucket público desde cero (evita claves huérfanas).
  await req('DELETE', `${SUPABASE_URL}/storage/v1/bucket/${BUCKET}`);
  const bucketRes = await req(
    'POST',
    `${SUPABASE_URL}/storage/v1/bucket`,
    JSON.stringify({
      id: BUCKET,
      name: BUCKET,
      public: true,
      file_size_limit: 10485760,
      allowed_mime_types: ['text/plain', 'application/json'],
    }),
  );
  console.log(`bucket ${BUCKET}: HTTP ${bucketRes.status} ${(await bucketRes.text()).slice(0, 120)}`);

  // 2. Subir cada texto con clave sanitizada.
  const archivos = listarTextos(ORIGEN);
  let subidos = 0;
  for (const f of archivos) {
    const dir = f.rel.includes('/') ? path.posix.dirname(f.rel) : '';
    const slug = dir ? `${dir}/${slugKey(path.posix.basename(f.rel))}` : slugKey(f.rel);
    const raw = fs.readFileSync(f.abs);
    const upRes = await req(
      'POST',
      `${SUPABASE_URL}/storage/v1/object/${BUCKET}/${slug}`,
      raw,
      'text/plain',
    );
    if (upRes.ok) subidos++;
    else console.warn(`⚠️ falló ${slug}: HTTP ${upRes.status} ${(await upRes.text()).slice(0, 160)}`);
  }

  // 3. Manifest: { categoria: [ { slug, nombre } ] }.
  const manifest = {};
  for (const f of archivos) {
    const categoria = f.rel.includes('/') ? path.posix.dirname(f.rel) : '.';
    const slug = categoria === '.' ? slugKey(f.rel) : `${categoria}/${slugKey(path.posix.basename(f.rel))}`;
    if (!manifest[categoria]) manifest[categoria] = [];
    manifest[categoria].push({ slug, nombre: path.posix.basename(f.rel) });
  }
  for (const k of Object.keys(manifest)) {
    manifest[k].sort((a, b) => a.nombre.localeCompare(b.nombre, 'es'));
  }

  const manBody = JSON.stringify(manifest, null, 2);
  const manRes = await req(
    'POST',
    `${SUPABASE_URL}/storage/v1/object/${BUCKET}/manifest.json`,
    manBody,
    'application/json',
  );
  console.log(`manifest.json: HTTP ${manRes.status}`);
  fs.writeFileSync(path.join(__dirname, 'estilos_manifest_remoto.json'), manBody);

  const totalCategorias = Object.keys(manifest).length;
  console.log(`\n✅ Subidos ${subidos}/${archivos.length} estilos al bucket "${BUCKET}" (${totalCategorias} categorías)`);
  for (const k of Object.keys(manifest).sort()) {
    console.log(`  ${k === '.' ? '(raíz)' : k}: ${manifest[k].length} archivos`);
  }
}

main().catch((e) => {
  console.error('❌ Error:', e);
  process.exit(1);
});