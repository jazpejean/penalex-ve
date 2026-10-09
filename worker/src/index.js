/**
 * Penalex — Generador de casos del quiz (Cloudflare Worker).
 *
 * Motor principal: Workers AI (cuota gratuita diaria de 10.000 neuronas).
 * Respaldo: DeepSeek API (solo si Workers AI falla o se agota la cuota).
 *
 * Fuentes de contexto (datos reales del proyecto):
 *  - Leyes        -> Supabase Storage (bucket 'leyes', JSON estructurado).
 *  - Sentencias   -> Cloudflare R2 (bucket 'penalex-jurisprudencia', texto plano).
 *
 * Rutas:
 *  - GET  /health        -> estado del worker.
 *  - POST /generar       -> { cantidad, tramo, dificultad } genera un lote y lo
 *                           sube a quiz/pendientes/ (staging, espera validación).
 *  - CRON 03:00 UTC      -> generación proactiva (20 casos, round-robin de tramos).
 *
 * Protección: POST requiere header `x-api-key` igual a la var QUIZ_API_KEY.
 */
const SISTEMA = `Eres un examinador de derecho penal venezolano de máximo rigor. Generas casos hipotéticos para un quiz profesional dirigido a abogados, jueces y estudiantes.

REGLAS OBLIGATORIAS:
1. Escenario fáctico concreto (personas ficticias, lugares, montos, cantidades, fechas). NUNCA preguntas teóricas: siempre de APLICACIÓN (¿qué delito se configura? ¿qué pena corresponde? ¿qué decide el tribunal? ¿qué tipo de concurso hay?).
2. Incluye SIEMPRE un objeto "variables" con 2 a 4 listas de valores intercambiables (nombres, montos, gramos, lugares) para que la app personalice la pregunta por usuario.
3. Si la respuesta depende de un umbral legal, incluye "parametro_umbral": { "variable": "gramos", "umbral": 5000, "respuesta_bajo": "...", "respuesta_alto": "..." } con los valores EXACTOS de la ley (ej. menor cuantía art. 149 LOD: hasta 5000 g; montos de hurto art. 453 CP).
4. Exactamente 4 opciones con distractores REALISTAS (penas vecinas, artículo erróneo, concurso mal aplicado, tentativa/consumado invertidos).
5. La "fundamentacion" DEBE citar artículos EXACTOS que existan en el corpus de leyes adjunto (números correctos). Si el caso admite jurisprudencia, cita sentencias del corpus de referencia con su número y sala.
6. "dificultad": 1 = identificación directa; 2 = un matiz (tentativa, participación, atenuante, pena); 3 = análisis complejo (concurso, agravantes, contraste jurisprudencial).
7. "tramo" es un número del 1 al 5 según el corpus adjunto.
8. TEMAS POR TRAMO (el escenario DEBE pertenecer al tema del tramo solicitado):
   - tramo 1: teoría del delito APLICADA a delitos del Código Penal (tentativa, participación, concurso, penas, prescripción, agravantes/atenuantes).
   - tramo 2: delitos contra las personas (homicidio, lesiones, amenazas, abuso sexual...).
   - tramo 3: delitos contra la propiedad (hurto, robo, estafa, apropiación...).
   - tramo 4: COPP (proceso penal: audiencias, medidas cautelares, recursos, nulidades).
   - tramo 5: leyes especiales (drogas, armas, niños/niñas/adolescentes, corrupción, secuestro, delitos informáticos).
   Los escenarios de drogas pertenecen SIEMPRE al tramo 5; los escenarios procesales al tramo 4.
9. "contextoNarrativo" DEBE contener los términos clave del artículo citado tal como aparecen en el corpus (p. ej. art. 405: "intencionalmente"; art. 453: "abusando de la confianza"). Usa esas palabras EN EL ESCENARIO, no solo en la fundamentación.
10. La opción correcta debe declarar la pena EXACTA del artículo citado según el corpus ("de doce a dieciocho años" → "12 a 18 años"; "de cuatro años a ocho años" → "4 a 8 años"). Los distractores con penas deben usar valores DIFERENTES de la pena legal del artículo.

RESPONDE ÚNICAMENTE JSON con esta forma EXACTA:
{"casos": [{"contextoNarrativo": "...", "opciones": ["a","b","c","d"], "respuestaCorrecta": 0, "fundamentacion": "...", "articulos": ["Art. 405 Código Penal"], "sentencias": [], "dificultad": 2, "tramo": 1, "variables": {"nombre": ["...", "..."], "gramos": [4800, 5200]}, "parametro_umbral": null}]}`;

function json(respuesta, status = 200) {
  return new Response(JSON.stringify(respuesta), {
    status,
    headers: { 'content-type': 'application/json; charset=utf-8' },
  });
}

// ---------------------------------------------------------------------------
// Supabase Storage (REST) — leyes (lectura) y quiz/pendientes (escritura)
// ---------------------------------------------------------------------------

async function listarArchivos(env, bucket) {
  const res = await fetch(`${env.SUPABASE_URL}/storage/v1/object/list/${bucket}`, {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      apikey: env.SUPABASE_SERVICE_KEY,
      authorization: `Bearer ${env.SUPABASE_SERVICE_KEY}`,
    },
    body: JSON.stringify({ prefix: '', limit: 200, offset: 0 }),
  });
  if (!res.ok) throw new Error(`list ${bucket}: HTTP ${res.status}`);
  return res.json();
}

async function descargarObjeto(env, bucket, path) {
  const res = await fetch(`${env.SUPABASE_URL}/storage/v1/object/${bucket}/${path}`, {
    headers: {
      apikey: env.SUPABASE_SERVICE_KEY,
      authorization: `Bearer ${env.SUPABASE_SERVICE_KEY}`,
    },
  });
  if (!res.ok) throw new Error(`download ${path}: HTTP ${res.status}`);
  return res.text();
}

async function subirObjeto(env, bucket, path, contenido, contentType = 'application/json') {
  const res = await fetch(`${env.SUPABASE_URL}/storage/v1/object/${bucket}/${path}`, {
    method: 'POST',
    headers: {
      'content-type': contentType,
      apikey: env.SUPABASE_SERVICE_KEY,
      authorization: `Bearer ${env.SUPABASE_SERVICE_KEY}`,
      'x-upsert': 'true',
    },
    body: contenido,
  });
  if (!res.ok) throw new Error(`upload ${path}: HTTP ${res.status}`);
  return res;
}

/** Texto de artículos de una ley — agnóstico de esquema.
 * Soporta el esquema del bucket de Supabase ({ley_nombre, estructura:
 * [{articulos: [{identificador, encabezado, texto_principal,
 * numerales_literales, paragrafos, nota_jurisprudencial}]}]}) y el esquema
 * local ({secciones, articulos: [{numero_texto, parrafos}]}). */
function articulosTexto(ley, maxChars) {
  const aTexto = (x) =>
    typeof x === 'string' ? x : (x?.texto ?? x?.texto_principal ?? '');

  if (Array.isArray(ley.estructura)) {
    const out = [];
    for (const bloque of ley.estructura) {
      for (const a of bloque.articulos ?? []) {
        const cuerpo = [
          a.encabezado,
          a.texto_principal,
          ...(a.numerales_literales ?? []),
          ...(a.paragrafos ?? []),
        ]
          .map(aTexto)
          .filter(Boolean)
          .join(' ');
        let linea = `Artículo ${a.identificador}: ${cuerpo}`;
        if (a.nota_jurisprudencial) {
          linea += `\n  [Nota jurisprudencial: ${aTexto(a.nota_jurisprudencial)}]`;
        }
        out.push(linea);
      }
    }
    return out.join('\n').slice(0, maxChars);
  }

  // Esquema local: {secciones, articulos:[{numero_texto, parrafos}]}.
  const secciones = ley.secciones ?? [];
  const out = [];
  for (const a of ley.articulos ?? []) {
    const parrafos = (a.parrafos ?? []).map(aTexto).join(' ');
    const sec = secciones.find((s) => s.id === a.seccion_id);
    const titulo = sec && sec.titulo ? ` — ${sec.titulo}` : '';
    out.push(`Artículo ${a.numero_texto}${titulo}: ${parrafos}`);
  }
  return out.join('\n').slice(0, maxChars);
}

/** Selecciona la(s) ley(es) del tramo. Devuelve contexto para el modelo (cap)
 * y corpus COMPLETO para el validador (las citas deben existir aunque el
 * artículo quede fuera del resumen). */
async function cargarLeyes(env, tramo) {
  try {
    const archivos = (await listarArchivos(env, 'leyes'))
      .map((f) => f.name)
      .filter((n) => n.endsWith('.json'));

    const elegir = (filtros, extras = []) => {
      const encontrado = filtros
        .map((f) => archivos.find((n) => n.includes(f)))
        .find(Boolean);
      return encontrado ? [encontrado] : extras;
    };

    let nombres;
    switch (tramo) {
      case 4:
        nombres = elegir(['copp'], [archivos[0]]);
        break;
      case 5:
        nombres = elegir(
          ['ley-organica-de-drogas', 'ley-organica-para-la-proteccion-de-ninos'],
          archivos.filter((n) => !n.includes('codigo-penal') && !n.includes('copp') && !n.includes('crbv') && !n.includes('penitenciario')),
        );
        break;
      default:
        nombres = elegir(['codigo-penal'], [archivos[0]]);
    }

    let contexto = '';
    let completo = '';
    const leyesParseadas = [];
    for (const nombre of nombres) {
      const ley = JSON.parse(await descargarObjeto(env, 'leyes', nombre));
      const textoCompleto = articulosTexto(ley, 500000);
      completo += `\n=== ${ley.nombre ?? nombre} ===\n` + textoCompleto;
      contexto += `\n=== ${ley.nombre ?? nombre} ===\n` + textoCompleto.slice(0, 6000);
      leyesParseadas.push({
        nombre: ley.nombre ?? nombre,
        archivo: nombre,
        articulos: extraerArticulos(ley),
      });
    }
    // Precomputar tokens distintivos por ley UNA sola vez (evita O(n²) por
    // caso, que excede el límite de CPU de Workers → error 1102).
    for (const l of leyesParseadas) {
      prepararLey(l);
    }
    return {
      contexto: contexto.slice(0, 12000),
      completo: completo.slice(0, 500000),
      leyes: leyesParseadas,
    };
  } catch (e) {
    const err = `(no se pudo cargar el corpus de leyes: ${e.message})`;
    return { contexto: err, completo: err, leyes: [] };
  }
}

/** Lista plana de artículos {numero, texto} (esquema agnóstico). */
function extraerArticulos(ley) {
  const out = [];
  const aTexto = (x) => (typeof x === 'string' ? x : (x?.texto ?? x?.texto_principal ?? ''));
  if (Array.isArray(ley.estructura)) {
    for (const bloque of ley.estructura) {
      for (const a of bloque.articulos ?? []) {
        const cuerpo = [
          a.encabezado,
          a.texto_principal,
          ...(a.numerales_literales ?? []),
          ...(a.paragrafos ?? []),
        ]
          .map(aTexto)
          .filter(Boolean)
          .join(' ');
        out.push({
          numero: String(a.identificador ?? ''),
          texto: normalizarEspacios(cuerpo),
          nota: a.nota_jurisprudencial ? aTexto(a.nota_jurisprudencial) : null,
        });
      }
    }
  } else {
    for (const a of ley.articulos ?? []) {
      const parrafos = (a.parrafos ?? []).map(aTexto).join(' ');
      out.push({
        numero: String(a.numero_texto ?? ''),
        texto: normalizarEspacios(parrafos),
        nota: null,
      });
    }
  }
  return out;
}

/** Muestra 1-2 sentencias del R2 como referencia de estilo jurisprudencial.
 * Primero el scrapeo nuevo (penalex-ve-v2, html/scon/...) y si está vacío,
 * el anterior (penalex-ve, html/jurisprudencias/...). Ambos son copias HTML
 * fieles del TSJ; se extrae texto plano quitando etiquetas. */
async function cargarSentencias(env) {
  try {
    let out = '';
    const fuentes = [
      { binding: env.SENTENCIAS, nombre: 'v2' },
      { binding: env.SENTENCIAS_ANTERIORES, nombre: 'v1' },
    ];
    for (const fuente of fuentes) {
      if (!fuente.binding || out) continue;
      const lista = await fuente.binding.list({ limit: 60 });
      const htmls = (lista.objects ?? [])
        .filter((o) => o.key.endsWith('.html'))
        .slice(0, 2);
      for (const o of htmls) {
        const obj = await fuente.binding.get(o.key);
        if (obj) {
          const crudo = await obj.text();
          const texto = crudo
            .replace(/<script[\s\S]*?<\/script>/gi, ' ')
            .replace(/<[^>]+>/g, ' ')
            .replace(/\s+/g, ' ')
            .trim();
          out += `[${fuente.nombre}: ${o.key}]\n${texto.slice(0, 700)}\n---\n`;
        }
      }
    }
    return out || '(corpus de sentencias sin muestras disponibles)';
  } catch (e) {
    return `(sin acceso al corpus de sentencias: ${e.message})`;
  }
}

// ---------------------------------------------------------------------------
// Generación: Workers AI (gratis) -> DeepSeek (respaldo)
// ---------------------------------------------------------------------------

// Stub SOLO para desarrollo local (env.AI_STUB): valida el pipeline completo
// (parseo -> validación -> subida) sin llamar a ningún modelo. No usar en prod.
const STUB_CASOS = {
  casos: [
    {
      contextoNarrativo:
        'Un hombre es aprehendido por la policía al salir de un local comercial con mercancía valorada en 4.500 bolívares que acababa de sustraer. Declara que lo hizo por necesidad y devuelve la mercancía antes del juicio.',
      opciones: [
        'Hurto simple consumado (art. 453 CP): responde en su totalidad',
        'Hurto frustrado: se aplica la mitad de la pena (art. 82 CP)',
        'No responde: devolvió la mercancía',
        'Solo responde por el valor: falta, no delito',
      ],
      respuestaCorrecta: 0,
      fundamentacion:
        'El hurto se consumó al salir del local con la mercancía (art. 453 CP); la devolución posterior no deshace el delito, aunque puede valorarse como atenuante (art. 74 CP) o reparación del daño.',
      articulos: ['Art. 453 Código Penal', 'Art. 74 Código Penal'],
      sentencias: [],
      dificultad: 2,
      tramo: 1,
      variables: { nombre: ['Juan', 'María'], monto: [4500, 7200] },
      parametro_umbral: null,
    },
    {
      contextoNarrativo:
        'Tres personas planean un hurto. Una vigila desde el vehículo mientras las otras dos entran a un local y sustraen mercancía por 4.500 bolívares. Solo se detiene al vigilante.',
      opciones: [
        'El vigilante es cómplice (art. 84 CP): mitad de la pena',
        'El vigilante es autor material del hurto (art. 453 CP)',
        'El vigilante no responde: no entró al local',
        'El vigilante responde por agavillamiento (art. 286 CP)',
      ],
      respuestaCorrecta: 0,
      fundamentacion:
        'El vigilante cooperó en la ejecución sin ejecutar el hecho: es cómplice necesario según el artículo 84 del Código Penal, con la mitad de la pena del hurto (art. 453 CP).',
      articulos: ['Art. 84 Código Penal', 'Art. 453 Código Penal'],
      sentencias: [],
      dificultad: 3,
      tramo: 1,
      variables: { nombre: ['Luis', 'Ana'], monto: [4500, 7200] },
      parametro_umbral: null,
    },
  ],
};

async function llamarWorkersAI(env, prompt) {
  if (env.AI_STUB) return { texto: JSON.stringify(STUB_CASOS), modelo: 'stub-local (prueba)' };
  const modelos = [env.AI_MODEL, env.AI_MODEL_FALLBACK].filter(Boolean);
  let ultimo = null;
  for (const modelo of modelos) {
    try {
      const res = await env.AI.run(modelo, {
        messages: [
          { role: 'system', content: SISTEMA },
          { role: 'user', content: prompt },
        ],
        response_format: { type: 'json_object' },
        temperature: 0.85,
        // Workers AI trunca la salida por defecto (256 tokens) — se necesita
        // máximo para que el JSON de N casos complete.
        max_tokens: 8000,
      });
      // Workers AI (qwen/llama) responde en formato OpenAI-compatible:
      // { choices: [{ message: { content } }] }. Se soportan varias formas.
      const texto =
        typeof res === 'string'
          ? res
          : res?.choices?.[0]?.message?.content ??
            res?.response ??
            res?.output ??
            '';
      if (texto && texto.length > 50) return { texto, modelo };
      // Diagnóstico: la llamada "funcionó" pero la respuesta es vacía/corta.
      throw new Error(`respuesta vacía de ${modelo}: ${JSON.stringify(res).slice(0, 300)}`);
    } catch (e) {
      ultimo = e;
    }
  }
  throw ultimo ?? new Error('Workers AI falló');
}

async function llamarDeepSeek(env, prompt) {
  const res = await fetch('https://api.deepseek.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      authorization: `Bearer ${env.DEEPSEEK_API_KEY}`,
    },
    body: JSON.stringify({
      model: 'deepseek-chat',
      messages: [
        { role: 'system', content: SISTEMA },
        { role: 'user', content: prompt },
      ],
      response_format: { type: 'json_object' },
      temperature: 0.85,
      max_tokens: 8000,
    }),
  });
  if (!res.ok) throw new Error(`DeepSeek HTTP ${res.status}`);
  const j = await res.json();
  return { texto: j.choices[0].message.content, modelo: 'deepseek-chat (respaldo)' };
}

function extraerJson(texto) {
  const inicio = texto.indexOf('{');
  const fin = texto.lastIndexOf('}');
  if (inicio < 0 || fin <= inicio) throw new Error('JSON no encontrado en la respuesta');
  const obj = JSON.parse(texto.slice(inicio, fin + 1));
  if (Array.isArray(obj.casos)) return obj.casos;
  if (Array.isArray(obj)) return obj;
  throw new Error('la respuesta no contiene "casos"');
}

// ---------------------------------------------------------------------------
// Validación (cero margen): estructura + citas contra el corpus + heurísticas
// ---------------------------------------------------------------------------

function validarCaso(c, corpusText, tramo) {
  const errores = [];
  if (!c || typeof c !== 'object') return { valido: false, errores: ['no es objeto'] };
  if (!c.contextoNarrativo || c.contextoNarrativo.length < 40) errores.push('contexto corto');
  if (!Array.isArray(c.opciones) || c.opciones.length !== 4) errores.push('opciones != 4');
  if (
    !Number.isInteger(c.respuestaCorrecta) ||
    c.respuestaCorrecta < 0 ||
    c.respuestaCorrecta > 3
  ) errores.push('respuestaCorrecta inválida');
  if (!c.fundamentacion || c.fundamentacion.length < 25) errores.push('fundamentación corta');
  if (!Array.isArray(c.articulos) || c.articulos.length === 0) errores.push('sin artículos');

  // Tema del escenario vs tramo (evita casos de drogas en tramo 1, etc.).
  const tema = `${c.contextoNarrativo ?? ''} ${c.opciones?.join(' ') ?? ''}`.toLowerCase();
  const temaDrogas = /drog|estupefaciente|gramos de|psicotróp|narco/.test(tema);
  const temaProcesal = /audiencia|recurso de|medida cautelar|imputado|acusaci|juicio oral|detención preventiva|nulidad/.test(tema);
  const temaPatrimonial = /hurto|robo|estafa|apropiac|fraude|abigeato/.test(tema);
  const temaPersonas = /homicidio|lesion(es)?|violaci|abuso sexual|integridad fisica|amenaza de muerte/.test(tema);
  if (temaDrogas && tramo !== 5) errores.push('tema de drogas pero tramo != 5');
  if (temaProcesal && tramo !== 4) errores.push('tema procesal pero tramo != 4');
  if (temaPatrimonial && tramo === 2) errores.push('delito patrimonial pero tramo 2 (personas)');
  if (temaPersonas && tramo === 3) errores.push('delito contra personas pero tramo 3 (propiedad)');

  // Las citas deben existir en el corpus de leyes.
  // TODO (validador Dart, Fase 2): validar la cita por LEY concreta (ej. si el
  // caso cita "Art. 453 Código Penal" pero el corpus del tramo es COPP, el
  // número 453 existe en ambos → falsos positivos). El validador en Dart debe
  // mapear "Código Penal"/"COPP"/"Ley" al corpus correcto.
  const citas = (c.articulos ?? []).map(String).join(' ');
  for (const m of citas.matchAll(/(\d{1,4})/g)) {
    const n = m[1];
    const existe = new RegExp(`Art(ícul|icul)?o\\s*[.:]?\\s*${n}\\b`, 'i').test(corpusText);
    if (!existe) {
      errores.push(`artículo ${n} no encontrado en el corpus`);
      break; // basta un artículo falso para rechazar
    }
  }

  // Personalización por usuario (anti-compartir respuestas).
  const v = c.variables;
  if (!v || typeof v !== 'object' || Object.keys(v).length < 2) {
    errores.push('sin variables de personalización');
  }

  // Heurística de dificultad (la IA puede subetiquetar).
  const texto = `${c.contextoNarrativo ?? ''} ${c.fundamentacion ?? ''}`.toLowerCase();
  if ((c.articulos?.length ?? 0) >= 2 || /concurso|agravante|tentativa|participaci/.test(texto)) {
    c.dificultad = Math.max(c.dificultad ?? 1, 2);
  }
  if (/concurso (real|ideal)|agravante/.test(texto)) c.dificultad = 3;
  c.dificultad = c.dificultad ?? 1;

  return { valido: errores.length === 0, errores };
}

// ---------------------------------------------------------------------------
// Validación FUERTE (port del validador Dart — mismas reglas, cero error):
// fundamentación literal, firma de elementos, ambigüedad y penas desde el
// corpus. Solo pasan los casos que el gate Dart aprobaría.
// ---------------------------------------------------------------------------

const ACENTOS = { 'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u', 'ñ': 'n' };
const STOPWORDS = new Set([
  'de', 'la', 'el', 'los', 'las', 'del', 'para', 'por', 'con', 'sin', 'que',
  'se', 'su', 'sus', 'un', 'una', 'unos', 'unas', 'al', 'lo', 'le', 'les',
  'en', 'es', 'y', 'o', 'a', 'no', 'si', 'como', 'pero', 'cual', 'cuales',
  'cuando', 'donde', 'este', 'esta', 'estos', 'estas', 'todo', 'toda',
  'todos', 'todas', 'cada', 'entre', 'sobre', 'hasta', 'desde', 'contra',
  'durante', 'solo', 'sola', 'segundo', 'segunda', 'primer', 'primera',
  'tercer', 'tercera', 'tambien', 'asi', 'aun', 'ya', 'muy', 'ser', 'estar',
  'haber', 'tener', 'hacer', 'podra', 'podran', 'sera', 'seran', 'debe',
  'deben', 'debera', 'deberan', 'puede', 'pueden', 'pudiera', 'pudieran',
  'responde', 'responden', 'aplica', 'aplican', 'sanciona', 'sancionan',
  'establece', 'establecen', 'dispone', 'disponen', 'previene', 'previenen',
  'comete', 'cometen', 'incurre', 'incurren', 'art', 'articulo', 'articulos',
  'correspondera', 'corresponde', 'corresponden', 'anos', 'anios',
]);

const NUMEROS = {
  cero: 0, uno: 1, dos: 2, tres: 3, cuatro: 4, cinco: 5, seis: 6, siete: 7,
  ocho: 8, nueve: 9, diez: 10, once: 11, doce: 12, trece: 13, catorce: 14,
  quince: 15, dieciseis: 16, diecisiete: 17, dieciocho: 18, diecinueve: 19,
  veinte: 20, veintiuno: 21, veintidos: 22, veintitres: 23, veinticuatro: 24,
  veinticinco: 25, veintiseis: 26, veintisiete: 27, veintiocho: 28,
  veintinueve: 29, treinta: 30, cuarenta: 40, cincuenta: 50, sesenta: 60,
  setenta: 70, ochenta: 80, noventa: 90,
};

function normalizarTexto(t) {
  return t.toLowerCase().replace(/[áéíóúüñ]/g, (c) => ACENTOS[c] ?? c);
}
function normalizarEspacios(t) {
  return String(t ?? '').replace(/\s+/g, ' ').trim();
}
function tokenizar(t) {
  return normalizarTexto(t)
    .split(/[^a-z0-9]+/)
    .filter((w) => w.length >= 4 && !STOPWORDS.has(w));
}
function numerosADigitos(t) {
  return normalizarTexto(t).replace(/\b(cero|uno|dos|tres|cuatro|cinco|seis|siete|ocho|nueve|diez|once|doce|trece|catorce|quince|dieciseis|diecisiete|dieciocho|diecinueve|veinte|veintiuno|veintidos|veintitres|veinticuatro|veinticinco|veintiseis|veintisiete|veintiocho|veintinueve|treinta|cuarenta|cincuenta|sesenta|setenta|ochenta|noventa)\b/g, (w) => String(NUMEROS[w] ?? w));
}
function rangosDePena(texto) {
  const norm = numerosADigitos(texto);
  const resultados = [];
  const vistos = new Set();
  for (const p of [
    /de\s+(\d{1,3})\s*(?:anos|anios)?\s+(?:a|y)\s+(\d{1,3})\s*(?:anos|anios)/g,
    /(?<!\d)(\d{1,3})\s*(?:anos|anios)?\s+(?:a|y)\s+(\d{1,3})\s*(?:anos|anios)/g,
  ]) {
    for (const m of norm.matchAll(p)) {
      const par = [parseInt(m[1], 10), parseInt(m[2], 10)];
      const clave = par.join('-');
      if (!vistos.has(clave)) {
        vistos.add(clave);
        resultados.push(par);
      }
    }
  }
  return resultados;
}
function rangoCoincide(a, b, tol = 1) {
  return Math.abs(a[0] - b[0]) <= tol && Math.abs(a[1] - b[1]) <= tol;
}

/** Tokens distintivos de un artículo dentro de su ley (frecuencia documental).
 * Con prepararLey() se precomputan una vez y se guardan en ley.distintivos. */
function tokensDistintivos(ley, articulo) {
  const cached = ley.distintivos?.get(articulo.numero);
  if (cached) return cached;
  const tokensArt = new Set(tokenizar(articulo.texto));
  if (tokensArt.size === 0) return new Set();
  const total = ley.articulos.length;
  const umbral = Math.min(20, Math.max(2, Math.ceil(total * 0.08)));
  const presentes = {};
  for (const a of ley.articulos) {
    for (const t of new Set(tokenizar(a.texto))) {
      presentes[t] = (presentes[t] ?? 0) + 1;
    }
  }
  return new Set([...tokensArt].filter((t) => (presentes[t] ?? 0) < umbral));
}

/** Precomputa la tabla de frecuencia documental y los tokens distintivos. */
function prepararLey(ley) {
  const presentes = {};
  for (const a of ley.articulos) {
    for (const t of new Set(tokenizar(a.texto))) {
      presentes[t] = (presentes[t] ?? 0) + 1;
    }
  }
  const umbral = Math.min(20, Math.max(2, Math.ceil(ley.articulos.length * 0.08)));
  const distintivos = new Map();
  for (const a of ley.articulos) {
    const tokensArt = new Set(tokenizar(a.texto));
    distintivos.set(
      a.numero,
      new Set([...tokensArt].filter((t) => (presentes[t] ?? 0) < umbral)),
    );
  }
  ley.distintivos = distintivos;
}

/** Busca la ley del corpus para una cita ("Art. 405 Código Penal"). */
function leyParaCita(leyes, citaSinNumero) {
  const norm = normalizarTexto(citaSinNumero);
  const busca = (frag) => {
    const f = normalizarTexto(frag);
    return leyes.find((l) => normalizarTexto(l.nombre).includes(f) || normalizarTexto(l.archivo).includes(f));
  };
  if (norm.includes('procesal penal') || norm.includes('copp')) return busca('copp');
  if (norm.includes('penal') && norm.includes('codigo')) return busca('codigo-penal');
  if (norm.includes('drogas')) return busca('drogas');
  if (norm.includes('nino') || norm.includes('adolescente')) return busca('proteccion-de-ninos');
  if (norm.includes('corrupcion')) return busca('corrupcion');
  if (norm.includes('secuestro')) return busca('secuestro');
  if (norm.includes('informatico')) return busca('informaticos');
  if (norm.includes('delincuencia organizada')) return busca('delincuencia-organizada');
  if (norm.includes('violencia')) return busca('violencia');
  return busca(citaSinNumero.trim().split(' ')[0]);
}

/**
 * Refuerza un caso generado: (1) fundamentación 100% literal del corpus
 * (se descarta la paráfrasis de la IA), (2) verifica firma de elementos,
 * (3) ambigüedad contra alternativas relevantes, (4) penas vs corpus.
 * Devuelve { ok, errores, caso } — caso ya reforzado si ok.
 */
function reforzarCaso(caso, leyes) {
  const errores = [];
  const contexto = caso.contextoNarrativo ?? '';
  // La firma y la ambigüedad se evalúan sobre el ESCENARIO (lo que ve el
  // usuario), nunca sobre las opciones (que se construyen después).
  const tokensEscenario = new Set(tokenizar(contexto));
  let fundamentacionFinal = '';
  let opcionesFinales = null;
  let respuestaFinal = null;

  for (const cita of caso.articulos ?? []) {
    const m = String(cita).match(/art\.?\s*([\d\-\.]+)/i);
    if (!m) {
      errores.push(`cita sin número: "${cita}"`);
      continue;
    }
    const numCita = m[1].split(/[-.]/)[0];
    const sinNumero = String(cita).replace(/art\.?\s*[\d\-\.]+/i, '');
    const ley = leyParaCita(leyes, sinNumero);
    if (!ley) {
      errores.push(`ley no encontrada: "${cita}"`);
      continue;
    }
    const articulo = ley.articulos.find((a) => a.numero === numCita);
    if (!articulo) {
      errores.push(`art. ${numCita} no existe en ${ley.nombre}`);
      continue;
    }

    // 1. Fundamentación literal (se construye DESDE el corpus).
    let citaLiteral = `Artículo ${articulo.numero} ${ley.nombre}: ${articulo.texto}`;
    if (articulo.nota) citaLiteral += `\n\nNota jurisprudencial: ${articulo.nota}`;
    fundamentacionFinal += (fundamentacionFinal ? '\n\n' : '') + citaLiteral;

    // 2. Firma de elementos (≥1 token distintivo del artículo en el escenario).
    const distintivos = tokensDistintivos(ley, articulo);
    const coinciden = [...distintivos].filter((t) => tokensEscenario.has(t)).length;
    if (coinciden < 1) {
      errores.push(`firma insuficiente para art. ${numCita}: 0 tokens distintivos en el escenario`);
    }

    // 3. Pregunta Tipo A (el artículo declara una pena): las opciones se
    //    CONSTRUYEN desde el corpus — la correcta es el rango legal del
    //    artículo y los distractores son rangos REALES de otros artículos.
    //    Cero error por construcción: la IA no escribe ninguna opción.
    const rangosArt = rangosDePena(articulo.texto);
    if (rangosArt.length && !opcionesFinales) {
      const construidas = construirOpcionesPena(ley, articulo, rangosArt[0]);
      if (construidas) {
        opcionesFinales = construidas.opciones;
        respuestaFinal = construidas.respuestaCorrecta;
      }
    }

    // 4. Ambigüedad (contra alternativas relevantes, con las opciones FINALES).
    const opcionesTexto = (opcionesFinales ?? caso.opciones ?? []).join(' ');
    const rangosOpcionesTodos = (opcionesFinales ?? caso.opciones ?? [])
      .flatMap(rangosDePena);
    for (const otro of ley.articulos) {
      if (otro.numero === articulo.numero) continue;
      const rangosOtro = rangosDePena(otro.texto);
      const esRelevante =
        opcionesTexto.includes(otro.numero) ||
        rangosOpcionesTodos.some((r) => (rangosOtro.length ? [rangosOtro[0]] : []).some((e) => rangoCoincide(r, e)));
      if (!esRelevante) continue;
      const d = tokensDistintivos(ley, otro);
      const match = [...d].filter((t) => tokensEscenario.has(t)).length;
      if (match >= 3) {
        errores.push(`escenario ambiguo: también encaja con art. ${otro.numero} (${ley.nombre})`);
        break;
      }
    }

    // 5. Tipo B (sin pena, p. ej. COPP): se conservan las opciones del modelo
    //    y se verifican contra el artículo (rango si lo hubiera).
    if (!rangosArt.length) {
      const opciones = caso.opciones ?? [];
      const respuesta = caso.respuestaCorrecta;
      const rangosOpciones = opciones.map(rangosDePena);
      for (let i = 0; i < opciones.length; i++) {
        if (i === respuesta) continue;
        for (const r of rangosOpciones[i]) {
          if (rangosArt.some((e) => rangoCoincide(r, e))) {
            errores.push(`distractor ${i} repite la pena legal del art. ${numCita}`);
            break;
          }
        }
      }
    }
  }

  if (errores.length === 0) {
    caso.fundamentacion = fundamentacionFinal.slice(0, 1200);
    if (opcionesFinales) {
      caso.opciones = opcionesFinales;
      caso.respuestaCorrecta = respuestaFinal;
    }
  }
  return { ok: errores.length === 0, errores, caso };
}

/** Construye las 4 opciones de pena desde el corpus: la correcta es el rango
 * del artículo; los distractores son rangos reales de otros artículos de la
 * misma ley (ordenados: 1 cercano, 1 lejano, 1 intermedio). Devuelve
 * { opciones, respuestaCorrecta } o null si no hay suficientes rangos. */
function construirOpcionesPena(ley, articulo, correcto) {
  const tipo = /presidio/i.test(articulo.texto) ? 'Presidio' : 'Prisión';
  const vistos = new Set([correcto.join('-')]);
  const pool = [];
  for (const a of ley.articulos) {
    if (a.numero === articulo.numero) continue;
    const r = rangosDePena(a.texto);
    // Excluir también los rangos a ±1 año del correcto (indistinguibles para
    // el usuario; el gate Dart los rechaza con la misma tolerancia).
    if (r.length && !rangoCoincide(r[0], correcto) && !vistos.has(r[0].join('-'))) {
      vistos.add(r[0].join('-'));
      pool.push(r[0]);
    }
  }
  const dist = (r) => Math.abs(r[0] - correcto[0]) + Math.abs(r[1] - correcto[1]);
  pool.sort((x, y) => dist(x) - dist(y));
  const distractores = [];
  if (pool.length) distractores.push(pool[0]);
  if (pool.length > 2) distractores.push(pool[pool.length - 1]);
  if (pool.length > 3) distractores.push(pool[Math.floor(pool.length / 2)]);
  let fallback = 1;
  while (distractores.length < 3) {
    const v = [
      Math.max(0, correcto[0] - fallback * 2),
      Math.max(1, correcto[1] - fallback * 2),
    ];
    if (!vistos.has(v.join('-')) && !rangoCoincide(v, correcto)) {
      vistos.add(v.join('-'));
      distractores.push(v);
    }
    fallback++;
  }
  const texto = (r) => `${tipo} de ${r[0]} a ${r[1]} años`;
  const opciones = [texto(correcto), ...distractores.map(texto)];
  // Barajar con semilla del día (el usuario recibe las opciones en distinto
  // orden cada día; el índice correcto se conserva).
  const idx = [0, 1, 2, 3];
  const dia = Math.floor(Date.now() / 86400000);
  for (let i = 3; i > 0; i--) {
    const j = (i + dia) % (i + 1);
    [idx[i], idx[j]] = [idx[j], idx[i]];
  }
  return {
    opciones: idx.map((i) => opciones[i]),
    respuestaCorrecta: idx.indexOf(0),
  };
}

// ---------------------------------------------------------------------------
// Selección PREVIA de artículos (inversión "respuesta primero"): el worker
// elige el fundamento legal verificable; la IA solo escribe el escenario.
// ---------------------------------------------------------------------------

const TEMAS_POR_TRAMO = {
  1: null, // cualquier delito del CP con pena (teoría del delito)
  2: /homicidio|muerte|lesion|amenaza|abuso sexual|violencia|integridad/i,
  3: /hurto|robo|estafa|apropiac|fraude|abigeato/i,
  4: null, // COPP: cualquier artículo procesal
  5: /droga|estupefaciente|trafico|tenencia|gramos/i,
};

/** Selecciona artículos candidatos verificables para el tramo. */
function seleccionarCandidatos(leyes, tramo, cantidad) {
  const tema = TEMAS_POR_TRAMO[tramo] ?? null;
  const ley = leyes[0]; // la ley principal del tramo (CP / COPP / LOD)
  if (!ley) return [];
  const candidatos = [];
  const dia = Math.floor(Date.now() / 86400000);
  for (let i = 0; i < ley.articulos.length; i++) {
    const a = ley.articulos[i];
    if (!a.texto || a.texto.length < 80) continue;
    const distintivos = ley.distintivos?.get(a.numero) ?? new Set();
    if (distintivos.size < 3) continue; // sin firma suficiente, no es verificable
    if (tema && !tema.test(a.texto)) continue;
    if (tramo === 4 && rangosDePena(a.texto).length > 0) continue; // COPP no es penas
    if (tramo !== 4 && tramo !== 5 && rangosDePena(a.texto).length === 0) {
      continue; // sustantivo: preferir artículos con pena (pregunta Tipo A)
    }
    candidatos.push({ ley, articulo: a, cita: `Art. ${a.numero} ${ley.nombre}` });
  }
  // Barajar con semilla del día (variedad sin repetir el mismo orden).
  for (let i = candidatos.length - 1; i > 0; i--) {
    const j = (i + dia) % (i + 1);
    [candidatos[i], candidatos[j]] = [candidatos[j], candidatos[i]];
  }
  return candidatos.slice(0, Math.min(cantidad, candidatos.length));
}

/** Prompt v3: un artículo fijo por caso; la IA solo decora el escenario. */
function construirPromptPorArticulos(candidatos, sentenciasCtx) {
  const bloques = candidatos
    .map((c, i) => {
      const d = c.ley.distintivos?.get(c.articulo.numero) ?? new Set();
      const tokens = [...d].slice(0, 8).join(', ');
      const rangos = rangosDePena(c.articulo.texto);
      const penalidad = rangos.length
        ? `Penalidad legal (la opción correcta DEBE declararla exactamente, p. ej. "12 a 18 años"): ${rangos.map((r) => `${r[0]} a ${r[1]} años`).join(' o ')}`
        : 'La opción correcta DEBE declarar la regla exacta del artículo (sin penas).';
      return `CASO ${i + 1} — aplica EXACTAMENTE este artículo:\n` +
        `Artículo ${c.articulo.numero} ${c.ley.nombre}: ${c.articulo.texto.slice(0, 260)}\n` +
        `Términos clave que DEBEN aparecer en el escenario: ${tokens}\n` +
        penalidad;
    })
    .join('\n\n');

  return `Genera EXACTAMENTE ${candidatos.length} casos hipotéticos. CADA caso aplica ÚNICAMENTE el artículo asignado a su número de CASO (el CASO 1 aplica el artículo del CASO 1, el CASO 2 el del CASO 2, etc.; no cites ningún otro artículo: el sistema lo fija). El escenario debe ser una aplicación fáctica concreta del artículo y DEBE contener sus términos clave. Las opciones: la correcta con la pena/regla exacta del artículo; los distractores con penas/reglas CLARAMENTE diferentes.

${bloques}

SENTENCIAS DE REFERENCIA (opcional, solo si el artículo admite cita jurisprudencial):
${(sentenciasCtx ?? '').slice(0, 1500)}`;
}

async function generarLote(env, { cantidad, tramo, dificultad }) {
  const tramoOk = [1, 2, 3, 4, 5].includes(tramo) ? tramo : 1;
  const leyes = await cargarLeyes(env, tramoOk);
  const sentenciasCtx = await cargarSentencias(env);
  const candidatos = seleccionarCandidatos(leyes.leyes, tramoOk, cantidad);

  const prompt = construirPromptPorArticulos(candidatos, sentenciasCtx);

  let resultado;
  let errorAi = null;
  try {
    resultado = await llamarWorkersAI(env, prompt);
  } catch (e) {
    errorAi = e.message;
    try {
      resultado = await llamarDeepSeek(env, prompt);
    } catch (e2) {
      return {
        error: 'Workers AI y DeepSeek fallaron',
        ai_error: errorAi,
        deepseek_error: e2.message,
      };
    }
  }

  let casos;
  try {
    casos = extraerJson(resultado.texto);
  } catch (e) {
    // El modelo respondió con JSON inválido: devolver el fragmento ayuda al
    // diagnóstico (p. ej. salida truncada por max_tokens).
    return {
      error: `JSON inválido del modelo: ${e.message}`,
      modelo: resultado.modelo,
      ai_error: errorAi,
      fragmento: (resultado.texto ?? '').slice(0, 300),
    };
  }
  const validos = [];
  const rechazados = [];
  for (let i = 0; i < casos.length; i++) {
    const c = casos[i];
    const r = validarCaso(c, leyes.completo, tramoOk);
    if (!r.valido) {
      rechazados.push({ contexto: (c.contextoNarrativo ?? '').slice(0, 60), errores: r.errores });
      continue;
    }
    // El artículo ES el candidato pre-seleccionado (respuesta primero).
    c.articulos = [candidatos[i]?.cita ?? c.articulos?.[0] ?? ''];
    // Validación FUERTE (mismas reglas que el gate Dart): literal + firma +
    // ambigüedad + penas. Solo lo que aprueba llega a pendientes/.
    const fuerte = reforzarCaso(c, leyes.leyes);
    if (fuerte.ok) {
      c.tramo = tramoOk;
      validos.push(fuerte.caso);
    } else {
      rechazados.push({ contexto: (c.contextoNarrativo ?? '').slice(0, 60), errores: fuerte.errores });
    }
  }

  let lote = null;
  if (validos.length > 0) {
    lote = `lote_${Date.now()}.json`;
    await subirObjeto(env, 'quiz', `pendientes/${lote}`, JSON.stringify(validos));
  }

  return {
    tramo: tramoOk,
    modelo: resultado.modelo,
    ai_error: errorAi,
    generados: casos.length,
    validados: validos.length,
    rechazados: rechazados.length,
    razones: rechazados.slice(0, 5),
    lote,
    pendientes: `quiz/pendientes/${lote ?? '—'}`,
  };
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (request.method === 'GET' && (url.pathname === '/' || url.pathname === '/health')) {
      return json({
        ok: true,
        nombre: 'penalex-quiz-generador',
        motor: 'Workers AI (cuota gratuita) + DeepSeek (respaldo)',
        estado: 'vivo',
      });
    }

    if (request.method === 'POST' && url.pathname === '/generar') {
      if (request.headers.get('x-api-key') !== env.QUIZ_API_KEY) {
        return json({ error: 'no autorizado' }, 401);
      }
      let body;
      try {
        body = await request.json();
      } catch {
        return json({ error: 'JSON inválido' }, 400);
      }
      const cantidad = Math.min(Math.max(parseInt(body.cantidad ?? '5', 10) || 5, 1), 20);
      const tramo = parseInt(body.tramo ?? '1', 10) || 1;
      const dificultad = body.dificultad ? parseInt(body.dificultad, 10) : null;
      try {
        return json(await generarLote(env, { cantidad, tramo, dificultad }));
      } catch (e) {
        return json({ error: e.message }, 500);
      }
    }

    return json({ error: 'ruta no encontrada' }, 404);
  },

  async scheduled(_event, env) {
    // Round-robin de tramos por día: lunes tramo 1 ... viernes tramo 5.
    const tramo = (Math.floor(Date.now() / 86400000) % 5) + 1;
    await generarLote(env, { cantidad: 20, tramo, dificultad: null });
  },
};