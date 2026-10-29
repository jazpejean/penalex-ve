// penalex-auth-bridge: traduce la sesión de Firebase a una sesión de Supabase.
//
// Recibe el ID token de Firebase, lo verifica (RS256 contra los certificados
// públicos de Firebase) y firma un JWT de Supabase con la MISMA identidad
// (sub = uid de Firebase, rol authenticated). La app lo usa con
// `supabase.auth.signInWithToken(jwt)` para que Supabase sepa quién es el
// usuario y el RLS aplique las políticas por `auth.uid()`.
//
// También expone POST /buscar/semantica: búsqueda semántica sobre Qdrant
// Cloud (colecciones sentencias_chunks y doctrinas_vectores, 1024 dims,
// embeddings bge-m3 de Workers AI). Las credenciales de Qdrant y de
// Cloudflare viven SOLO aquí (secrets del worker); el APK nunca las ve.
//
// Env: FIREBASE_PROJECT_ID, SUPABASE_JWT_SECRET (auth).
// Env: QDRANT_URL, QDRANT_API_KEY, CF_AI_ACCOUNT_ID, CF_AI_API_KEY (semántica).
//   - QDRANT_URL: https://<cluster>.aws.cloud.qdrant.io:6333
//   - CF_AI_API_KEY: token de Workers AI (Bearer) para bge-m3.

const CERT_URL =
  'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com';

const MODELO_EMBEDDING = '@cf/baai/bge-m3';

let certsCache = { data: null, at: 0 };

function json(status, body) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

// Log auxiliar (solo visible en las trazas del worker; sin secretos).
function debug(msg) {
  // eslint-disable-next-line no-console
  console.log('[super-buscador] ' + msg);
}

function b64urlToBytes(s) {
  const b = s.replace(/-/g, '+').replace(/_/g, '/');
  const padded = b + '='.repeat((4 - (b.length % 4)) % 4);
  const bin = atob(padded);
  return Uint8Array.from(bin, (c) => c.charCodeAt(0));
}

function decodePart(s) {
  return JSON.parse(new TextDecoder().decode(b64urlToBytes(s)));
}

function pemToSpki(pem) {
  const b64 = pem.replace(/-----[^-]+-----/g, '').replace(/\s+/g, '');
  return b64urlToBytes(b64.replace(/\+/g, '-').replace(/\//g, '_'));
}

async function getCerts() {
  if (certsCache.data && Date.now() - certsCache.at < 5 * 60 * 1000) {
    return certsCache.data;
  }
  const res = await fetch(CERT_URL);
  if (!res.ok) throw new Error('certificados Firebase HTTP ' + res.status);
  const data = await res.json();
  certsCache = { data, at: Date.now() };
  return data;
}

async function verifyFirebase(idToken, env) {
  const parts = idToken.split('.');
  if (parts.length !== 3) throw new Error('formato de token inválido');
  const header = decodePart(parts[0]);
  const payload = decodePart(parts[1]);
  const project = env.FIREBASE_PROJECT_ID;

  if (payload.aud !== project) throw new Error('aud no coincide con el proyecto');
  if (payload.iss !== 'https://securetoken.google.com/' + project) {
    throw new Error('iss no coincide con el proyecto');
  }
  if (typeof payload.exp !== 'number' || payload.exp * 1000 < Date.now()) {
    throw new Error('token expirado');
  }
  if (!payload.sub) throw new Error('token sin sub');

  const certs = await getCerts();
  const key = certs[header.kid];
  if (!key) throw new Error('kid desconocido (certificados rotados?)');

  const cryptoKey = await crypto.subtle.importKey(
    'spki',
    pemToSpki(key),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['verify'],
  );
  const ok = await crypto.subtle.verify(
    'RSASSA-PKCS1-v1_5',
    cryptoKey,
    b64urlToBytes(parts[2]),
    new TextEncoder().encode(parts[0] + '.' + parts[1]),
  );
  if (!ok) throw new Error('firma inválida');

  return {
    uid: payload.sub,
    email: payload.email ?? null,
    nombre: payload.name ?? null,
    foto: payload.picture ?? null,
  };
}

function b64urlJson(o) {
  return btoa(JSON.stringify(o))
    .replace(/=+$/, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');
}

async function mintSupabaseJwt(user, env) {
  const secret = env.SUPABASE_JWT_SECRET;
  if (!secret || secret.length < 16) throw new Error('SUPABASE_JWT_SECRET no configurada');
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: 'HS256', typ: 'JWT' };
  const payload = {
    sub: user.uid,
    aud: 'authenticated',
    role: 'authenticated',
    iat: now,
    exp: now + 3600,
    app_metadata: { provider: 'firebase', user_id: user.uid },
    user_metadata: {
      firebase: true,
      email: user.email,
      nombre: user.nombre,
      foto: user.foto,
    },
  };
  const data = b64urlJson(header) + '.' + b64urlJson(payload);
  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const sig = await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(data));
  const sigB64 = btoa(String.fromCharCode(...new Uint8Array(sig)))
    .replace(/=+$/, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');
  return data + '.' + sigB64;
}

// ---------------------------------------------------------------------------
// Búsqueda semántica (Qdrant + Workers AI bge-m3)
// ---------------------------------------------------------------------------

/** Genera el embedding 1024-d de un texto con Workers AI (bge-m3). */
async function generarEmbedding(env, texto) {
  const url =
    'https://api.cloudflare.com/client/v4/accounts/' +
    env.CF_AI_ACCOUNT_ID +
    '/ai/v1/embeddings';
  const res = await fetch(url, {
    method: 'POST',
    headers: {
      Authorization: 'Bearer ' + env.CF_AI_API_KEY,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ model: MODELO_EMBEDDING, input: [texto] }),
  });
  if (!res.ok) throw new Error('embedding HTTP ' + res.status);
  const data = await res.json();
  // La API REST de Workers AI devuelve { object, data: [...] }.
  const vec = data?.data?.[0]?.embedding;
  if (!Array.isArray(vec)) throw new Error('respuesta de embedding inválida');
  return vec;
}

/** Consulta top-k de Qdrant con filtro opcional de payload. */
async function buscarQdrant(env, coleccion, vector, filtro, limite) {
  const body = { vector, limit: limite, with_payload: true };
  if (filtro) body.filter = filtro;
  const res = await fetch(
    env.QDRANT_URL.replace(/\/+$/, '') + '/collections/' + coleccion + '/points/search',
    {
      method: 'POST',
      headers: {
        'api-key': env.QDRANT_API_KEY,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body),
    },
  );
  if (!res.ok) throw new Error('Qdrant HTTP ' + res.status);
  return (await res.json())?.result ?? [];
}

/** Filtro de Qdrant por sala y/o año (payload string, igual que el scraper). */
function filtroPayload(sala, anio) {
  const must = [];
  if (sala) must.push({ key: 'sala', match: { value: sala } });
  if (anio) must.push({ key: 'anio', match: { value: String(anio) } });
  return must.length ? { must } : null;
}

/**
 * POST /buscar/semantica
 * Body: { query, categoria, sala?, anio?, limite? }
 *   categoria: 'sentencia' | 'jurisprudencia' | 'resolucion' | 'doctrina'
 * Devuelve: { resultados: [{ documento_id, score, texto_chunk, sala, anio,
 *   fuente, doctrina_id? }] }
 */
async function buscarSemantica(env, body) {
  const query = typeof body.query === 'string' ? body.query.trim().slice(0, 300) : '';
  if (!query) return { resultados: [] };

  const categoria = body.categoria === 'doctrina' ? 'doctrina' : 'sentencia';
  const sala = typeof body.sala === 'string' ? body.sala.trim().toLowerCase() : '';
  const anio = body.anio != null ? String(body.anio) : '';
  const limite = Math.min(Math.max(parseInt(body.limite ?? '30', 10) || 30, 5), 60);

  // Colección según categoría: doctrinas van a su propia colección; el resto
  // (sentencia, jurisprudencia, resolución) viven en sentencias_chunks.
  const coleccion = categoria === 'doctrina' ? 'doctrinas_vectores' : 'sentencias_chunks';

  const vector = await generarEmbedding(env, query);

  let hits;
  const filtro = filtroPayload(sala, anio);
  if (filtro) {
    try {
      hits = await buscarQdrant(env, coleccion, vector, filtro, limite);
    } catch (e) {
      // Qdrant exige un índice keyword para filtrar por payload; si aún no
      // existe (HTTP 400 "Index required but not found"), hacemos fallback:
      // búsqueda sin filtro con un lote mayor y filtramos localmente.
      debug('filtro Qdrant no disponible (' + e.message + '); fallback local');
      const bruto = await buscarQdrant(env, coleccion, vector, null, 60);
      hits = bruto
        .filter((h) => {
          const p = h.payload ?? {};
          if (sala && String(p.sala ?? '').toLowerCase() !== sala) return false;
          if (anio && String(p.anio ?? '') !== anio) return false;
          return true;
        })
        .slice(0, limite);
    }
  } else {
    hits = await buscarQdrant(env, coleccion, vector, null, limite);
  }

  // Devolver solo lo útil para el RRF en la app (id de documento + score).
  return {
    resultados: hits.map((h) => {
      const p = h.payload ?? {};
      return {
        documento_id: p.documento_id ?? null,
        doctrina_id: p.doctrina_id ?? null,
        score: h.score ?? 0,
        texto_chunk: p.texto_chunk ?? '',
        sala: p.sala ?? '',
        anio: p.anio ?? '',
        fuente: p.fuente ?? '',
      };
    }),
  };
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (request.method === 'POST' && url.pathname === '/auth/bridge') {
      try {
        const body = await request.json();
        const idToken = typeof body.idToken === 'string' ? body.idToken : '';
        if (!idToken) return json(400, { error: 'idToken requerido' });
        const user = await verifyFirebase(idToken, env);
        const token = await mintSupabaseJwt(user, env);
        return json(200, { token });
      } catch (e) {
        return json(401, { error: 'token inválido: ' + e.message });
      }
    }

    if (request.method === 'POST' && url.pathname === '/buscar/semantica') {
      try {
        const body = await request.json();
        return json(200, await buscarSemantica(env, body));
      } catch (e) {
        return json(500, { error: 'semántica falló: ' + e.message });
      }
    }

    if (request.method === 'GET' && url.pathname === '/health') {
      return json(200, { ok: true });
    }

    return json(404, { error: 'no encontrado' });
  },
};