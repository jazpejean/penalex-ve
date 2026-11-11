#!/usr/bin/env node
/**
 * Penalex VE — Sincroniza las leyes de Supabase Storage a R2 (penalex-ve-v2).
 *
 * El manifest público (Supabase Storage, bucket "leyes") lista las leyes;
 * este script selecciona SOLO las aprobadas para la sección web /leyes
 * (penal esencial + conexas al proceso penal + Constitución), descarga
 * cada JSON y los deja en data/leyes/ listos para subir a R2 como
 * leyes/{slug}.json (el worker las sirve desde ahí con SEO).
 *
 * Uso:  node scripts/sincronizar_leyes.mjs
 *       (requiere SUPABASE_URL en ../.env; el bucket es público, no hace
 *        falta la anon key, pero se lee del .env por si cambia el acceso)
 */
import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");

// Lee KEY=VALUE de un .env simple (sin dependencias).
function leerEnv(ruta) {
  const out = {};
  try {
    for (const linea of readFileSync(ruta, "utf8").split("\n")) {
      const m = linea.match(/^\s*([A-Z0-9_]+)\s*=\s*(.*?)\s*$/);
      if (!m) continue;
      out[m[1]] = m[2].replace(/^["']|["']$/g, "");
    }
  } catch {
    /* sin archivo: no pasa nada */
  }
  return out;
}

const env = { ...leerEnv(join(ROOT, "..", ".env")), ...process.env };

const SUPABASE_URL = (env.SUPABASE_URL || "").replace(/\/+$/, "");
if (!SUPABASE_URL) {
  console.error("❌ SUPABASE_URL no está en ../.env");
  process.exit(1);
}
const PUBLICO = `${SUPABASE_URL}/storage/v1/object/public/leyes`;

// ── Selección aprobada (por nombre EXACTO del manifest) ────────────────────
// Grupo A: penal esencial. Grupo B: conexas al proceso penal. + Constitución.
const SELECCION = new Set([
  // Constitución
  "Constitución 1999",
  // A — Penal esencial
  "Código Orgánico Procesal Penal",
  "Código Penal",
  "Ley Orgánica Sobre el Derecho de las Mujeres a una Vida Libre de Violencia",
  "Ley Orgánica para la Protección de Niños, Niñas y Adolescentes",
  "Ley Orgánica de Drogas",
  "Ley sobre el Hurto y Robo de Vehículos Automotores",
  "Ley Orgánica Contra la Delincuencia Organizada y Financiamiento al Terrorismo",
  "Ley Contra el Secuestro y la Extorsión",
  "Ley Especial contra los Delitos Informáticos",
  "Decreto con Rango, Valor y Fuerza de Ley del Cuerpo Nacional Contra la Corrupción",
  "Ley Contra La Corrupción",
  "Ley Especial para Prevenir y Sancionar la Tortura y Otros Tratos Crueles, Inhumanos o Degradantes",
  "Ley para el Desarme y Control de Armas y Municiones",
  "Reglamento de la Ley para el Desarme y Control de Armas y Municiones",
  "Ley Penal del Ambiente",
  "Ley Penal de Protección a la Actividad Ganadera",
  "Ley Contra la Estafa Inmobiliaria",
  "Ley para la Prevención y Erradicación del Abuso Sexual Contra Niñas, Niños y Adolescentes",
  "Ley para Sancionar los Crimenes, Desapariciones, Torturas y Otras Violaciones de los Derechos Humanos por Razones Políticas en el Período 1958-1998",
  "Ley De Registro De Antecedentes Penales",
  "Ley que Regula el Uso de la Telefonía Celular y la Internet en el Interior de los Establecimientos Penitenciarios",
  "Código Orgánico Penitenciario",
  "Código de Justicia Militar",
  "Ley del Estatuto de la Función de la Policia de Investigación",
  "Ley Orgánica del Servicio de la Policía de Investigación, el Cuerpo de Investigaciones Científicas, Penales y Criminalísticas y el Instituto Nacional de Medicina y Ciencias Forenses",
  "Ley sobre el Delito de Contrabando",
  "Reglamento del Servicio de Alguacilazgo de los Circuitos Judiciales Penales",
  // B — Conexas al proceso penal
  "Ley de Protección de Victimas, Testigos y Demas Sujetos Procesales",
  "Ley Orgánica del Ministerio Público",
  "Ley Orgánica de Reforma Parcial de la Ley Orgánica del Tribunal Supremo de Justicia",
  "Ley de Abogados",
  "Reglamento de la Ley de Abogados",
  "Código de Ética Profesional del Abogado Venezolano",
  "Ley Orgánica del Poder Judicial",
  "Ley Orgánica de la Defensa Pública",
  "Ley Orgánica de Amparo a la Libertad y Seguridad Personal",
  "Ley Orgánica de Amparo sobre Derechos y Garantías Constitucionales",
  "Ley Orgánica de Extinción de Dominio",
  "Ley del Estatuto de la Función Policial",
  "Ley Orgánica del Servicio de Policía y del Cuerpo de Policía Nacional Bolivariana",
  "Ley Orgánica de Seguridad de la Nación",
  "Ley de Carrera Judicial",
  "Código de Ética del Juez Venezolano y Jueza Venezolana",
  "Ley del Sistema de Justicia",
  "Decreto con Fuerza de Ley de Coordinación de Seguridad Ciudadana",
  "Ley Constitucional de la Comisión para la Verdad, la Justicia, la Paz y la Tranquilidad Pública",
  "Reglamento para el uso de la Cámara de Gesell de los Tribunales de Protección de Niños, Niñas y Adolescentes",
  // Revisión del usuario (relación penal o utilidad para el corpus):
  "Ley Orgánica Contra La Discriminación Racial", // delitos de discriminación racial
  "Ley Constitucional Contra El Odio, Por La Convivencia Pacífica Y La Tolerancia", // ilícitos por incitación al odio
  "Decreto con Rango, Valor y Fuerza de Ley Orgánica de Precios Justos", // delitos económicos: acaparamiento, especulación
  "Ley de Publicaciones Oficiales", // Gaceta Oficial: vigencia y publicación del corpus
  "Ley Sobre Protección a la Privacidad de las Comunicaciones", // derecho fundamental (art. 48 CRBV); ligada a interceptación del COPP
]);

const outDir = join(ROOT, "data", "leyes");
mkdirSync(outDir, { recursive: true });

async function main() {
  // 1) Manifest
  const mRes = await fetch(`${PUBLICO}/manifest.json`);
  if (!mRes.ok) throw new Error(`manifest HTTP ${mRes.status}`);
  const manifest = (await mRes.json()).leyes ?? [];
  console.log(`Manifest: ${manifest.length} leyes`);

  // 2) Seleccionar por nombre exacto; reportar las que no matcheen.
  const porNombre = new Map(manifest.map((l) => [l.nombre, l]));
  const seleccionadas = [];
  for (const nombre of SELECCION) {
    const meta = porNombre.get(nombre);
    if (!meta) {
      console.warn(`⚠️ No encontrada en manifest: "${nombre}"`);
      continue;
    }
    seleccionadas.push(meta);
  }
  seleccionadas.sort((a, b) => a.orden - b.orden);
  console.log(`Seleccionadas: ${seleccionadas.length} leyes`);
  const noListadas = manifest
    .filter((l) => !SELECCION.has(l.nombre))
    .map((l) => l.nombre);
  console.log(`Descartadas: ${noListadas.length} (no se descargan)`);

  // 3) Descargar cada ley seleccionada
  let totalArt = 0, totalBytes = 0;
  for (let i = 0; i < seleccionadas.length; i++) {
    const meta = seleccionadas[i];
    const res = await fetch(`${PUBLICO}/${meta.archivo}`);
    if (!res.ok) {
      console.error(`❌ ${meta.slug}: HTTP ${res.status}`);
      continue;
    }
    const buf = Buffer.from(await res.arrayBuffer());
    writeFileSync(join(outDir, `${meta.slug}.json`), buf);
    totalArt += meta.articulos || 0;
    totalBytes += buf.length;
    console.log(`  [${i + 1}/${seleccionadas.length}] ${meta.slug} (${meta.articulos} art, ${(buf.length / 1024).toFixed(0)} KB)`);
  }

  // 4) Manifest filtrado para el worker (lista de leyes públicas)
  writeFileSync(
    join(outDir, "manifest.json"),
    JSON.stringify(
      {
        generado: new Date().toISOString(),
        leyes: seleccionadas.map((l) => ({
          slug: l.slug,
          nombre: l.nombre,
          orden: l.orden,
          articulos: l.articulos,
        })),
      },
      null,
      2,
    )
  );

  console.log(`\n✅ ${seleccionadas.length} leyes · ${totalArt} artículos · ${(totalBytes / 1048576).toFixed(1)} MB → data/leyes/`);
}

main().catch((e) => {
  console.error("❌", e.message);
  process.exit(1);
});