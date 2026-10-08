// backfill_ratio.mjs — Extrae el ratio decidendi (criterio de la sala) de forma
// DETERMINÍSTICA (sin IA, $0) y lo guarda en Supabase.
//
// Uso:  node --env-file=.env backfill_ratio.mjs [LIMITE_OPCIONAL]
//   ej:  node --env-file=.env backfill_ratio.mjs 500   (probar con 500 primero)
//
// Es idempotente: solo procesa filas con ratio_decidendi NULL.

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_KEY;

if (!SUPABASE_URL || !SUPABASE_SERVICE_KEY) {
  console.error('❌ Faltan SUPABASE_URL / SUPABASE_SERVICE_KEY en .env');
  process.exit(1);
}

const CONCURRENCIA = 6;
const PAGE_SIZE = 1000;
const TIMEOUT_TXT = 12000;
const MAX_CHARS = 4000;

const LIMITE = process.argv[2] ? parseInt(process.argv[2], 10) : null;

const headers = {
  apikey: SUPABASE_SERVICE_KEY,
  Authorization: `Bearer ${SUPABASE_SERVICE_KEY}`,
};

function recortar(s) {
  const t = s.replace(/\s+/g, ' ').trim();
  if (t.length <= MAX_CHARS) return t;
  const corte = t.lastIndexOf('. ', MAX_CHARS);
  if (corte > MAX_CHARS * 0.5) return t.slice(0, corte + 1).trim();
  return t.slice(0, MAX_CHARS).trim();
}

function extraerRatio(txt) {
  const i = /(CONSIDERACIONES? PARA DECIDIR|MOTIVA[CÇ]I[OÓ]N(?: PARA DECIDIR)?|LA SALA PARA DECIDIR OBSERVA|DE LA MOTIVACI[OÓ]N|RAZONES PARA DECIDIR|DE LA COMPETENCIA|PUNTO (?:ÚNICO|UNICO)|CONSIDERANDO)/i.exec(txt);
  if (i) {
    const desde = i.index + i[0].length;
    const resto = txt.slice(desde);
    const f = /(DISPOSITIVA|POR LAS RAZONES ANTES EXPUESTAS|EN VIRTUD DE LAS CONSIDERACIONES|EN FUERZA DE LO ANTERIOR|ADMINISTRANDO JUSTICIA|SE DECLARA)/i.exec(resto);
    const hasta = f ? desde + f.index : Math.min(desde + 8000, txt.length);
    const bloque = txt.slice(desde, hasta).trim();
    if (bloque.length > 150) return recortar(bloque);
  }

  const frases = txt.match(/[^.]*\b(?:la Sala|esta Sala|este Tribunal|esta Corte|esta Alzada)\b[^.]*(?:considera|observa|establece|señala|sostiene|advierte|ha señalado|ha establecido|ha sostenido|es criterio|ha sido criterio)[^.]*\./gi);
  if (frases && frases.length) {
    return recortar(frases.slice(0, 10).join(' '));
  }

  const ini = Math.floor(txt.length * 0.20);
  const fin = Math.floor(txt.length * 0.75);
  return recortar(txt.slice(ini, fin));
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
  // Total exacto (para el progreso). Si no se obtiene, se muestra '?'.
  let total = LIMITE ?? null;
  if (total == null) {
    try {
      const headRes = await fetch(
        `${SUPABASE_URL}/rest/v1/documentos?select=id&ratio_decidendi=is.null&limit=1`,
        { headers: { ...headers, Prefer: 'count=exact' } },
      );
      const cr = headRes.headers.get('content-range') || '';
      total = parseInt(cr.split('/')[1], 10) || null;
    } catch {
      total = null;
    }
  }

  console.log(`📚 Sentencias pendientes: ${total ?? '?'}`);

  let offset = 0;
  let ok = 0, errores = 0;
  const t0 = Date.now();

  while (true) {
    const pageLimit = LIMITE ? Math.min(PAGE_SIZE, LIMITE - offset) : PAGE_SIZE;
    if (pageLimit <= 0) break;
    const url = `${SUPABASE_URL}/rest/v1/documentos?select=id,url_txt&ratio_decidendi=is.null&limit=${pageLimit}&offset=${offset}`;
    const page = await fetch(url, { headers }).then((r) => r.json());
    if (!Array.isArray(page) || page.length === 0) break;

    await runPool(page, CONCURRENCIA, async (doc) => {
      if (!doc.url_txt) return;
      try {
        const txt = await fetch(doc.url_txt, { signal: AbortSignal.timeout(TIMEOUT_TXT) }).then((r) => r.text());
        const ratio = extraerRatio(txt);
        if (!ratio) return;
        const patch = await fetch(`${SUPABASE_URL}/rest/v1/documentos?id=eq.${encodeURIComponent(doc.id)}`, {
          method: 'PATCH',
          headers: { ...headers, 'Content-Type': 'application/json', Prefer: 'return=minimal' },
          body: JSON.stringify({ ratio_decidendi: ratio }),
        });
        if (patch.ok) ok++;
        else errores++;
      } catch {
        errores++;
      }
    });

    offset += page.length;
    const elapsed = (Date.now() - t0) / 1000;
    const rate = offset / Math.max(1, elapsed);
    const pct = total ? ((offset / total) * 100).toFixed(1) : '-';
    const eta = total ? Math.round(Math.max(0, (total - offset) / Math.max(0.001, rate)) / 60) : null;
    console.log(
      `⏱ ${offset}${total ? '/' + total : ''} (${pct}%) · ok=${ok} · err=${errores} · ${rate.toFixed(0)}/s` +
      (eta != null ? ` · ETA ${eta} min` : ''),
    );
  }

  console.log(`\n✅ Terminado. ok=${ok} · errores=${errores}`);
}

main().catch((e) => {
  console.error('❌ Error:', e);
  process.exit(1);
});
