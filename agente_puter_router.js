import fs from 'fs';
import path from 'path';
import readline from 'readline';
import { execSync } from 'child_process';

const ARCHIVO_CUENTAS = './cuentas_puter.json';
const ARCHIVO_MEMORIA = './memoria_contexto.json';
const ARCHIVO_CONTEXTO_MD = './CONTEXTO.md';

const MODELO_AI = "claude-opus-5";

let cuentas = JSON.parse(fs.readFileSync(ARCHIVO_CUENTAS, 'utf-8'));
let indiceCuentaActual = 0;

let contextoProyecto = "";
if (fs.existsSync(ARCHIVO_CONTEXTO_MD)) {
  try {
    contextoProyecto = fs.readFileSync(ARCHIVO_CONTEXTO_MD, 'utf-8');
  } catch {}
}

let memoria = { historial_mensajes: [] };
if (fs.existsSync(ARCHIVO_MEMORIA)) {
  try {
    memoria = JSON.parse(fs.readFileSync(ARCHIVO_MEMORIA, 'utf-8'));
  } catch {}
}

function guardarMemoria() {
  fs.writeFileSync(ARCHIVO_MEMORIA, JSON.stringify(memoria, null, 2), 'utf-8');
}

function rotarCuenta() {
  indiceCuentaActual = (indiceCuentaActual + 1) % cuentas.length;
  return cuentas[indiceCuentaActual];
}

function formatearRespuestaTexto(contenido) {
  if (!contenido) return "";
  if (typeof contenido === 'string') return contenido;
  if (Array.isArray(contenido)) {
    return contenido.map(item => {
      if (typeof item === 'string') return item;
      if (item.text) return item.text;
      if (item.content) return formatearRespuestaTexto(item.content);
      return JSON.stringify(item);
    }).join('\n');
  }
  if (typeof contenido === 'object') {
    if (contenido.text) return formatearRespuestaTexto(contenido.text);
    if (contenido.content) return formatearRespuestaTexto(contenido.content);
    return JSON.stringify(contenido);
  }
  return String(contenido);
}

async function llamarPuter(token, messages, model = MODELO_AI) {
  const payload = {
    interface: "puter-chat-completion",
    driver: "ai-chat",
    test_mode: false,
    method: "complete",
    args: { messages, model },
    auth_token: token
  };

  const res = await fetch("https://api.puter.com/drivers/call", {
    method: "POST",
    headers: {
      "accept": "*/*",
      "content-type": "text/plain;actually=json",
      "user-agent": "puter-js/1.0",
      "origin": "https://puter.work",
      "referer": "https://puter.work/"
    },
    body: JSON.stringify(payload)
  });

  if (!res.ok) {
    const errText = await res.text();
    throw new Error(`HTTP ${res.status}: ${errText.slice(0, 100)}`);
  }

  const json = await res.json();
  const rawContent = json.result?.message?.content 
                  || json.message?.content 
                  || json.result?.text 
                  || json.result;
  
  return formatearRespuestaTexto(rawContent);
}

async function ejecutarLlamadaAI(messagesPayload) {
  let intentos = 0;
  while (intentos < cuentas.length) {
    const cuentaActual = cuentas[indiceCuentaActual];
    try {
      const respuesta = await llamarPuter(cuentaActual.token, messagesPayload);
      return { respuesta, cuentaId: cuentaActual.id };
    } catch (err) {
      console.log(`\x1b[33m[!] Cuenta ${cuentaActual.id} falló: ${err.message}. Rotando...\x1b[0m`);
      rotarCuenta();
      intentos++;
    }
  }
  throw new Error("Todas las cuentas registradas fallaron.");
}

async function procesarAcciones(respuesta) {
  let respuestaFinal = respuesta;
  let huboAccion = false;
  let feedbackSistema = "";

  // 1. Acción: Leer archivo
  const regexLeer = /\[LEER:\s*([^\]]+)\]/i;
  const matchLeer = respuesta.match(regexLeer);
  if (matchLeer) {
    huboAccion = true;
    const ruta = matchLeer[1].trim();
    console.log(`\n\x1b[36m⚡ [Herramienta]: Leyendo archivo "${ruta}"...\x1b[0m`);
    if (fs.existsSync(ruta)) {
      const contenido = fs.readFileSync(ruta, 'utf-8');
      feedbackSistema += `\n[CONTENIDO DE ${ruta}]:\n\`\`\`\n${contenido}\n\`\`\`\n`;
    } else {
      feedbackSistema += `\n[ERROR]: El archivo "${ruta}" no existe.\n`;
    }
  }

  // 2. Acción: Escribir / Modificar archivo
  const regexEscribir = /\[ESCRIBIR:\s*([^\]]+)\]\s*([\s\S]*?)\s*\[\/ESCRIBIR\]/i;
  const matchEscribir = respuesta.match(regexEscribir);
  if (matchEscribir) {
    huboAccion = true;
    const ruta = matchEscribir[1].trim();
    const contenido = matchEscribir[2];
    console.log(`\n\x1b[33m⚡ [Herramienta]: Escribiendo en "${ruta}"...\x1b[0m`);
    try {
      const dir = path.dirname(ruta);
      if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
      fs.writeFileSync(ruta, contenido, 'utf-8');
      feedbackSistema += `\n[SISTEMA]: Archivo "${ruta}" guardado y modificado exitosamente en el disco.\n`;
    } catch (e) {
      feedbackSistema += `\n[ERROR ESCRIBIENDO ${ruta}]: ${e.message}\n`;
    }
  }

  // 3. Acción: Ejecutar comando de consola
  const regexComando = /\[COMANDO:\s*([^\]]+)\]/i;
  const matchComando = respuesta.match(regexComando);
  if (matchComando) {
    huboAccion = true;
    const cmd = matchComando[1].trim();
    console.log(`\n\x1b[35m⚡ [Herramienta]: Ejecutando comando: ${cmd}...\x1b[0m`);
    try {
      const salida = execSync(cmd, { encoding: 'utf-8', timeout: 30000 });
      feedbackSistema += `\n[SALIDA COMANDO (${cmd})]:\n\`\`\`\n${salida || '(Comando ejecutado sin salida)'}\n\`\`\`\n`;
    } catch (e) {
      feedbackSistema += `\n[ERROR COMANDO (${cmd})]: ${e.stderr || e.message}\n`;
    }
  }

  return { huboAccion, feedbackSistema };
}

async function procesarMensaje(mensajeUsuario) {
  const messagesPayload = [
    {
      role: "system",
      content: `Eres un agente autónomo de ingeniería de software para el proyecto Penalex VE.
Contexto base del proyecto:
${contextoProyecto}

TIENES ACCESO REAL A LA MÁQUINA A TRAVÉS DE ESTAS HERRAMIENTAS:
1. Para leer un archivo: usa [LEER: ruta/al/archivo]
2. Para crear o sobreescribir un archivo con código: usa 
[ESCRIBIR: ruta/al/archivo]
contenido completo del archivo
[/ESCRIBIR]
3. Para ejecutar un comando bash en la terminal: usa [COMANDO: tu_comando_aqui]

Cuando el usuario te pida crear, modificar código o correr scripts, USA LAS HERRAMIENTAS DIRECTAMENTE en lugar de solo dar explicaciones.`
    },
    ...memoria.historial_mensajes.slice(-6),
    { role: "user", content: mensajeUsuario }
  ];

  let { respuesta, cuentaId } = await ejecutarLlamadaAI(messagesPayload);

  // Bucle de ejecución autónoma (hasta 3 iteraciones de herramientas por turno)
  let iteraciones = 0;
  while (iteraciones < 3) {
    const { huboAccion, feedbackSistema } = await procesarAcciones(respuesta);
    if (!huboAccion) break;

    messagesPayload.push({ role: "assistant", content: respuesta });
    messagesPayload.push({ role: "user", content: `[RESULTADO DEL SISTEMA]:\n${feedbackSistema}\nAnaliza el resultado y continúa o finaliza la tarea.` });

    const siguientePaso = await ejecutarLlamadaAI(messagesPayload);
    respuesta = siguientePaso.respuesta;
    cuentaId = siguientePaso.cuentaId;
    iteraciones++;
  }

  memoria.historial_mensajes.push({ role: "user", content: mensajeUsuario });
  memoria.historial_mensajes.push({ role: "assistant", content: respuesta });
  guardarMemoria();

  return { respuesta, cuentaId };
}

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

console.clear();
console.log(`\x1b[34m====================================================\x1b[0m`);
console.log(`\x1b[34m   AGENTE AUTÓNOMO CON ACCESO A TERMINAL Y DISCO   \x1b[0m`);
console.log(`\x1b[34m====================================================\x1b[0m`);
console.log(`⚡ Herramientas activas: Lectura [LEER], Escritura [ESCRIBIR] y Ejecución [COMANDO]\n`);

function preguntar() {
  rl.question('\x1b[1mTú:\x1b[0m ', async (entrada) => {
    const prompt = entrada.trim();
    if (!prompt) return preguntar();
    if (prompt.toLowerCase() === 'salir' || prompt.toLowerCase() === 'exit') {
      rl.close();
      return;
    }

    process.stdout.write('\x1b[36mEjecutando agente...\x1b[0m\r');
    try {
      const { respuesta, cuentaId } = await procesarMensaje(prompt);
      console.log(`\n\x1b[32m[Agente - Vía ${cuentaId}]:\x1b[0m\n${respuesta}\n`);
    } catch (e) {
      console.log(`\n\x1b[31m[Error]:\x1b[0m ${e.message}\n`);
    }
    preguntar();
  });
}

preguntar();
