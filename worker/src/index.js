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
    for (const nombre of nombres) {
      const ley = JSON.parse(await descargarObjeto(env, 'leyes', nombre));
      const textoCompleto = articulosTexto(ley, 500000);
      completo += `\n=== ${ley.nombre ?? nombre} ===\n` + textoCompleto;
      contexto += `\n=== ${ley.nombre ?? nombre} ===\n` + textoCompleto.slice(0, 6000);
    }
    return { contexto: contexto.slice(0, 12000), completo: completo.slice(0, 500000) };
  } catch (e) {
    const err = `(no se pudo cargar el corpus de leyes: ${e.message})`;
    return { contexto: err, completo: err };
  }
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
  const temaPersonas = /homicidio|lesiones|amenaz|violaci|abuso sexual|integridad/.test(tema);
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
// Flujo principal
// ---------------------------------------------------------------------------

async function generarLote(env, { cantidad, tramo, dificultad }) {
  const tramoOk = [1, 2, 3, 4, 5].includes(tramo) ? tramo : 1;
  const leyes = await cargarLeyes(env, tramoOk);
  const sentenciasCtx = await cargarSentencias(env);

  const prompt = `Genera EXACTAMENTE ${cantidad} casos hipotéticos para el TRAMO ${tramoOk} (${tramoOk === 4 ? 'procesal penal — COPP' : tramoOk === 5 ? 'leyes especiales' : 'derecho penal sustantivo'})${dificultad ? ` con dificultad ${dificultad}` : ' con dificultades variadas (1-3)'}.

CORPUS DE LEYES (solo de aquí puedes citar artículos):
${leyes.contexto}

SENTENCIAS DE REFERENCIA (estilo jurisprudencial; cita solo si existe):
${sentenciasCtx.slice(0, 2000)}`;

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
  for (const c of casos) {
    const r = validarCaso(c, leyes.completo, tramoOk);
    if (r.valido) {
      c.tramo = tramoOk;
      validos.push(c);
    } else {
      rechazados.push({ contexto: (c.contextoNarrativo ?? '').slice(0, 60), errores: r.errores });
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