/**
 * Sube las leyes (JSON en tool/) a Supabase Storage y genera un manifest.json
 * con el orden de relevancia (Constitución → COPP → Código Penal → ... → resto).
 * Uso: node upload_leyes_supabase.mjs
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const SUPABASE_URL = 'https://efxzcglhyosrxtafirhs.supabase.co';
const SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVmeHpjZ2xoeW9zcnh0YWZpcmhzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4NjQwMzE4OCwiZXhwIjoyMTAxOTc5MTg4fQ.-c7sFMAIvR778_yv3b9TiIVtfoYOx48v3xC-czB_ZJg';
const BUCKET = 'leyes';

// Orden de relevancia (matchers sobre el slug, en orden de prioridad).
const ORDEN = [
  'crbv',
  'copp',
  'codigo-penal',
  'ley-de-violencia',
  'proteccion-de-ninos-ninas-y-adolescentes',
  'organica-de-drogas',
  'delincuencia-organizada',
  'secuestro-y-la-extorsion',
  'delitos-informaticos',
  'contra-la-corrupcion',
  'discriminacion-racial',
  'prevenir-y-sancionar-la-tortura',
  'desarme-y-control-de-armas',
  'penal-del-ambiente',
  'estafa-inmobiliaria',
  'abuso-sexual',
  'crimenes-desapariciones',
  'contra-el-odio',
  'privacidad-de-las-comunicaciones',
  'registro-de-antecedentes-penales',
  'telefonia-celular',
  'extinsion-de-dominio',
  'amparo-a-la-libertad',
  'amparo-sobre-derechos',
  'organico-penitenciario',
  'justicia-militar',
  'proteccion-de-victimas',
  'estatuto-de-la-funcion-policial',
  'estatuto-de-la-funcion-publica',
  'estatuto-de-la-funcion-de-la-policia-de-investigacion',
  'servicio-de-policia-de-investigacion',
  'ministerio-publico',
  'defensa-publica',
  'tribunal-supremo-de-justicia',
  'jurisdiccion-contencioso',
  'ley-de-abogados',
  'juramento-publico',
  'publicaciones-oficiales',
  'respeto-de-los-derechos-humanos',
];

function slugify(name) {
  return name
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

function ordenDe(slug) {
  for (let i = 0; i < ORDEN.length; i++) {
    if (slug.includes(ORDEN[i])) return i + 1;
  }
  return 999;
}

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

async function main() {
  // 1. Crear bucket público
  const bucketRes = await req(
    'POST',
    `${SUPABASE_URL}/storage/v1/bucket`,
    JSON.stringify({
      id: BUCKET,
      name: BUCKET,
      public: true,
      file_size_limit: 5242880,
      allowed_mime_types: ['application/json'],
    }),
  );
  const bucketBody = await bucketRes.text();
  console.log(`bucket ${BUCKET}: HTTP ${bucketRes.status} ${bucketBody.slice(0, 120)}`);

  // 2. Hacer público (por si ya existía como privado)
  await req(
    'PUT',
    `${SUPABASE_URL}/storage/v1/bucket/${BUCKET}`,
    JSON.stringify({ public: true, allowed_mime_types: ['application/json'] }),
  );

  const toolDir = path.join(__dirname, 'tool');
  const files = fs.readdirSync(toolDir).filter((f) => f.endsWith('.json'));

  const manifest = [];
  let uploaded = 0;

  for (const file of files) {
    const fullPath = path.join(toolDir, file);
    const raw = fs.readFileSync(fullPath);
    let nombre = file.replace(/\.json$/i, '');
    let nArticulos = 0;
    try {
      const data = JSON.parse(raw.toString('utf8'));
      if (data.ley_nombre) nombre = data.ley_nombre;
      nArticulos = (data.estructura || []).reduce(
        (acc, e) => acc + ((e.articulos || []).length),
        0,
      );
    } catch (e) {
      console.warn(`⚠️ no se pudo parsear ${file} para metadatos: ${e.message}`);
    }

    const slug = slugify(file.replace(/\.json$/i, ''));
    const uploadPath = `${slug}.json`;

    const upRes = await req(
      'POST',
      `${SUPABASE_URL}/storage/v1/object/${BUCKET}/${uploadPath}`,
      raw,
      'application/json',
    );
    if (upRes.ok) uploaded++;
    else console.warn(`⚠️ falló subida ${file}: HTTP ${upRes.status} ${(await upRes.text()).slice(0, 200)}`);

    manifest.push({
      slug,
      archivo: uploadPath,
      nombre,
      orden: ordenDe(slug),
      articulos: nArticulos,
      tamano: raw.length,
      url: `${SUPABASE_URL}/storage/v1/object/public/${BUCKET}/${uploadPath}`,
    });
  }

  manifest.sort((a, b) => a.orden - b.orden);

  const noOrden = manifest.filter((m) => m.orden === 999);
  if (noOrden.length) {
    console.warn('⚠️ leyes sin orden asignado (revisar ORDEN):', noOrden.map((m) => m.slug));
  }

  // 3. Subir manifest
  const manifestBody = JSON.stringify({ generado: new Date().toISOString(), total: manifest.length, leyes: manifest }, null, 2);
  const manRes = await req(
    'POST',
    `${SUPABASE_URL}/storage/v1/object/${BUCKET}/manifest.json`,
    manifestBody,
    'application/json',
  );
  console.log(`manifest.json: HTTP ${manRes.status}`);

  // Guardar copia local
  fs.writeFileSync(path.join(__dirname, 'leyes_manifest.json'), manifestBody);

  console.log(`\n✅ Subidas ${uploaded}/${files.length} leyes al bucket "${BUCKET}"`);
  console.log('Orden de relevancia:');
  manifest.forEach((m) => console.log(`  ${String(m.orden).padStart(2)}. ${m.nombre} (${m.articulos} arts)`));
}

main().catch((e) => {
  console.error('❌ Error:', e);
  process.exit(1);
});
