// penalex-auth-bridge: traduce la sesión de Firebase a una sesión de Supabase.
//
// Recibe el ID token de Firebase, lo verifica (RS256 contra los certificados
// públicos de Firebase) y firma un JWT de Supabase con la MISMA identidad
// (sub = uid de Firebase, rol authenticated). La app lo usa con
// `supabase.auth.signInWithToken(jwt)` para que Supabase sepa quién es el
// usuario y el RLS aplique las políticas por `auth.uid()`.
//
// Env: FIREBASE_PROJECT_ID, SUPABASE_JWT_SECRET.

const CERT_URL =
  'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com';

let certsCache = { data: null, at: 0 };

function json(status, body) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
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

    if (request.method === 'GET' && url.pathname === '/health') {
      return json(200, { ok: true });
    }

    return json(404, { error: 'no encontrado' });
  },
};