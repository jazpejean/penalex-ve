// backfill_resumen.mjs — Genera el resumen_ia (Tesis Jurisprudencial estilo
// Rionero) usando la API de Gemini (Google AI Studio / Vertex) y lo guarda en
// Supabase. Cada fila se genera UNA sola vez (idempotente).
//
// Soporta tanto claves de AI Studio (AIza...) como tokens OAuth/GCP (AQ...).

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_KEY;
const GEMINI_MODEL = process.env.GEMINI_MODEL || 'gemini-2.0-flash';
const DELAY_MS = parseInt(process.env.GEMINI_DELAY_MS || '4500', 10);

if (!SUPABASE_URL || !SUPABASE_SERVICE_KEY) {
  console.error('❌ Faltan SUPABASE_URL / SUPABASE_SERVICE_KEY en .env');
  process.exit(1);
}

// ---------------------------------------------------------------------------
// Cargar claves de Gemini (varias)
// ---------------------------------------------------------------------------
const claves = [];
function agregar(k) {
  const s = (k || '').trim();
  if (s && !claves.includes(s)) claves.push(s);
}
if (process.env.GEMINI_API_KEYS) {
  process.env.GEMINI_API_KEYS.split(',').forEach(agregar);
}
for (let i = 1; i <= 50; i++) {
  const k = process.env[`GEMINI_API_KEY_${i}`];
  if (!k) break;
  agregar(k);
}
agregar(process.env.GEMINI_API_KEY);

if (claves.length === 0) {
  console.error('❌ No hay claves de Gemini. Añade GEMINI_API_KEYS (separadas por coma) o GEMINI_API_KEY en .env');
  console.error('   Obténlas en https://aistudio.google.com/apikey');
  process.exit(1);
}

console.log(`🔑 ${claves.length} clave(s) / token(s) de Gemini cargado(s)`);

// Rotación con enfriamiento por rate-limit.
let cursor = 0;
const cooldownHasta = new Map(); // clave -> timestamp

function siguienteClave() {
  const ahora = Date.now();
  for (let i = 0; i < claves.length; i++) {
    const idx = (cursor + i) % claves.length;
    const k = claves[idx];
    if (ahora >= (cooldownHasta.get(k) || 0)) {
      cursor = (idx + 1) % claves.length;
      return k;
    }
  }
  let mejor = claves[0];
  let mejorHasta = Infinity;
  for (const k of claves) {
    const hasta = cooldownHasta.get(k) || 0;
    if (hasta < mejorHasta) {
      mejorHasta = hasta;
      mejor = k;
    }
  }
  return mejor;
}

function enfriar(clave, ms = 65000) {
  cooldownHasta.set(clave, Date.now() + ms);
}

const CONCURRENCIA = 1; // un solo hilo para respetar el límite gratuito
const PAGE_SIZE = 500;
const MAX_CHARS = 4000;
const LIMITE = process.argv[2] ? parseInt(process.argv[2], 10) : null;

const headersSupabase = {
  apikey: SUPABASE_SERVICE_KEY,
  Authorization: `Bearer ${SUPABASE_SERVICE_KEY}`,
};

function recortar(s) {
  const t = (s || '').replace(/\s+/g, ' ').trim();
  if (t.length <= MAX_CHARS) return t;
  const corte = t.lastIndexOf('. ', MAX_CHARS);
  if (corte > MAX_CHARS * 0.5) return t.slice(0, corte + 1).trim();
  return t.slice(0, MAX_CHARS).trim();
}

const PROMPT = `Eres un redactor de fichas jurisprudenciales penales venezolanas. A partir del RATIO DECIDENDI, redacta UNA TESIS JURISPRUDENCIAL (máxima penal de autoridad) de 3 a 5 líneas, densa y contundente, sin relleno ni encabezados. Usa fórmulas imperativas o descriptivas de alto nivel técnico penal, por ejemplo: "Estaremos en presencia de...", "Las Cortes de Apelaciones deben...", "La omisión de pronunciamiento sobre...", "No constituye violación del debido proceso...". No uses comillas, no cites número de sentencia. Responde SOLO con el párrafo.

RATIO DECIDENDI:
`;

// URL y cabeceras dinámicas según si es clave AIza o token OAuth (AQ...)
const obtenerConfigPeticion = (clave) => {
  const esApiToken = clave.startsWith('AIza');
  const url = esApiToken
    ? `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${clave}`
    : `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent`;

  const headers = { 'Content-Type': 'application/json' };
  if (!esApiToken) {
    headers['Authorization'] = `Bearer ${clave}`;
  }
  return { url, headers };
};

async function generarTesis(texto) {
  const maxIntentos = claves.length * 3 + 3;
  for (let intento = 1; intento <= maxIntentos; intento++) {
    const clave = siguienteClave();
    const { url, headers } = obtenerConfigPeticion(clave);

    const resp = await fetch(url, {
      method: 'POST',
      headers,
      body: JSON.stringify({
        contents: [{ parts: [{ text: PROMPT + texto }] }],
        generationConfig: { temperature: 0.3, maxOutputTokens: 350 },
      }),
    });

    if (resp.status === 429 || resp.status === 503 || resp.status === 500) {
      enfriar(clave);
      const espera = Math.min(intento * 4000, 20000);
      console.warn(`  ⚠️ ${resp.status} en credencial [${clave.slice(-6)}], rotando + ${Math.round(espera / 1000)}s`);
      await new Promise((r) => setTimeout(r, espera));
      continue;
    }
    if (!resp.ok) {
      const body = await resp.text().catch(() => '');
      throw new Error(`Gemini HTTP ${resp.status}: ${body.slice(0, 160)}`);
    }
    const data = await resp.json();
    const out = data?.candidates?.[0]?.content?.parts?.[0]?.text || '';
    return out.trim();
  }
  throw new Error('Gemini: demasiados reintentos por rate limit en todas las credenciales');
}

async function runPool(items, concurrency, worker) {
  let idx = 0;
  const runners = Array.from({ length: Math.min(concurrency, items.length) }, async () => {
    while (idx < items.length) {
      const i = idx++;
      await worker(items[i]);
    }
  });
  await Promise.all(runners);
}

async function main() {
  let total = LIMITE ?? null;
  if (total == null) {
    try {
      const headRes = await fetch(
        `${SUPABASE_URL}/rest/v1/documentos?select=id&or=(resumen_ia.is.null,resumen_ia.eq.)&limit=1`,
        { headers: { ...headersSupabase, Prefer: 'count=exact' } },
      );
      const cr = headRes.headers.get('content-range') || '';
      total = parseInt(cr.split('/')[1], 10) || null;
    } catch {
      total = null;
    }
  }

  console.log(`🤖 Modelo: ${GEMINI_MODEL} · delay ${DELAY_MS} ms`);
  console.log(`📚 Sentencias pendientes de resumen: ${total ?? '?'}`);

  let offset = 0;
  let ok = 0;
  let errores = 0;
  const t0 = Date.now();

  while (true) {
    const pageLimit = LIMITE ? Math.min(PAGE_SIZE, LIMITE - offset) : PAGE_SIZE;
    if (pageLimit <= 0) break;
    const url =
      `${SUPABASE_URL}/rest/v1/documentos?select=id,ratio_decidendi,extracto,resumen_ia` +
      `&or=(resumen_ia.is.null,resumen_ia.eq.)&limit=${pageLimit}&offset=${offset}`;
    const page = await fetch(url, { headers: headersSupabase }).then((r) => r.json());
    if (!Array.isArray(page) || page.length === 0) break;

    await runPool(page, CONCURRENCIA, async (doc) => {
      if (doc.resumen_ia && doc.resumen_ia.trim()) return;
      const fuente = doc.ratio_decidendi || doc.extracto || '';
      if (!fuente.trim()) return;

      try {
        const tesis = await generarTesis(recortar(fuente));
        if (!tesis) return;
        const patch = await fetch(
          `${SUPABASE_URL}/rest/v1/documentos?id=eq.${encodeURIComponent(doc.id)}`,
          {
            method: 'PATCH',
            headers: { ...headersSupabase, 'Content-Type': 'application/json', Prefer: 'return=minimal' },
            body: JSON.stringify({ resumen_ia: tesis }),
          },
        );
        if (patch.ok) ok++;
        else errores++;
      } catch (e) {
        errores++;
        if (errores <= 5) console.warn('  ⚠️ Error:', (e && e.message) || e);
      }
      if (DELAY_MS > 0) await new Promise((r) => setTimeout(r, DELAY_MS));
    });

    offset += page.length;
    const elapsed = (Date.now() - t0) / 1000;
    const rate = offset / Math.max(1, elapsed);
    const pct = total ? ((offset / total) * 100).toFixed(1) : '-';
    const eta = total ? Math.round(Math.max(0, (total - offset) / Math.max(0.001, rate)) / 60) : null;
    console.log(
      `⏱ ${offset}${total ? '/' + total : ''} (${pct}%) · ok=${ok} · err=${errores} · ${rate.toFixed(1)}/min` +
        (eta != null ? ` · ETA ${eta} min` : ''),
    );
  }

  console.log(`\n✅ Terminado. ok=${ok} · errores=${errores}`);
}

main().catch((e) => {
  console.error('❌ Error:', e);
  process.exit(1);
});
