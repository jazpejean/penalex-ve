import { init } from '@heyputer/puter.js/src/init.cjs';
import { execSync } from 'child_process';
import fs from 'fs';
import readline from 'readline';
import dotenv from 'dotenv';

dotenv.config();

const TOKEN = process.env.PUTER_API_KEY;
if (!TOKEN) {
  console.error('❌ FALTA PUTER_API_KEY en .env');
  process.exit(1);
}

const puter = init(TOKEN);
const CLAVE_HISTORIAL = 'historial_penalex_ve';
const HISTORIAL_FILE = 'HISTORIAL.md';

// ============================================================
// 0. CARGAR HISTORIAL DESDE PUTER KV (SI EXISTE)
// ============================================================

let historial = await puter.kv.get(CLAVE_HISTORIAL);
if (historial) {
  historial = JSON.parse(historial);
} else {
  // Si no hay historial en KV, intentar cargar desde archivo local
  try {
    const contenido = fs.readFileSync(HISTORIAL_FILE, 'utf-8');
    historial = [{ role: 'system', content: `Este es el contenido del archivo ${HISTORIAL_FILE}:\n${contenido}` }];
    await puter.kv.set(CLAVE_HISTORIAL, JSON.stringify(historial));
    console.log(`📂 Historial cargado desde ${HISTORIAL_FILE}`);
  } catch (e) {
    historial = [{ role: 'system', content: `No se encontró ${HISTORIAL_FILE}. El usuario está trabajando en Penalex VE.` }];
    await puter.kv.set(CLAVE_HISTORIAL, JSON.stringify(historial));
  }
}

// ============================================================
// 1. FUNCIONES LOCALES (directas, sin herramientas)
// ============================================================

function leerArchivoDirecto(nombre) {
  try {
    return fs.readFileSync(nombre, 'utf-8');
  } catch (e) {
    return `❌ Error: ${e.message}`;
  }
}

function escribirArchivoDirecto(nombre, contenido) {
  try {
    fs.writeFileSync(nombre, contenido, 'utf-8');
    return `✅ ${nombre} guardado.`;
  } catch (e) {
    return `❌ Error: ${e.message}`;
  }
}

function ejecutarComandoDirecto(comando) {
  try {
    const output = execSync(comando, { encoding: 'utf-8', timeout: 10000 });
    return output || '✅ Comando ejecutado sin salida.';
  } catch (e) {
    return `❌ Error: ${e.message}`;
  }
}

function guardarHistorialEnKV() {
  try {
    puter.kv.set(CLAVE_HISTORIAL, JSON.stringify(historial));
  } catch (e) {
    // Silencioso
  }
}

// ============================================================
// 2. PROCESAR ÓRDENES (sin IA para comandos básicos)
// ============================================================

async function procesarOrden(orden) {
  orden = orden.trim();

  // Leer archivo
  if (orden.match(/^(lee|muestra|mostrar|ver|cat)\s+/i)) {
    const archivo = orden.replace(/^(lee|muestra|mostrar|ver|cat)\s+/i, '').trim();
    const contenido = leerArchivoDirecto(archivo);
    console.log(`\n📄 ${archivo}:\n${contenido}`);
    historial.push({ role: 'user', content: orden });
    historial.push({ role: 'assistant', content: contenido });
    guardarHistorialEnKV();
    return contenido;
  }

  // Escribir archivo
  if (orden.match(/^(crea|escribe|guarda|modifica)\s+/i)) {
    const partes = orden.match(/^(crea|escribe|guarda|modifica)\s+([^\s]+)\s+con\s+(.*)/i);
    if (partes) {
      const archivo = partes[2];
      const contenido = partes[3];
      const resultado = escribirArchivoDirecto(archivo, contenido);
      console.log(`\n${resultado}`);
      historial.push({ role: 'user', content: orden });
      historial.push({ role: 'assistant', content: resultado });
      guardarHistorialEnKV();
      return resultado;
    }
    console.log('❌ Formato: "crea archivo.txt con [contenido]"');
    return 'Formato incorrecto.';
  }

  // Ejecutar comando
  if (orden.match(/^(ejecuta|corre|run)\s+/i)) {
    const comando = orden.replace(/^(ejecuta|corre|run)\s+/i, '').trim();
    const resultado = ejecutarComandoDirecto(comando);
    console.log(`\n💻 ${resultado}`);
    historial.push({ role: 'user', content: orden });
    historial.push({ role: 'assistant', content: resultado });
    guardarHistorialEnKV();
    return resultado;
  }

  // Comandos directos (ls, cat, etc.)
  if (orden.match(/^(ls|cat|grep|find|npm|flutter|git|python|node|pwd|echo|wc|tail|head|cd)\s/)) {
    const resultado = ejecutarComandoDirecto(orden);
    console.log(`\n💻 ${resultado}`);
    historial.push({ role: 'user', content: orden });
    historial.push({ role: 'assistant', content: resultado });
    guardarHistorialEnKV();
    return resultado;
  }

  // ============================================================
  // 3. SI NO ES UN COMANDO CONOCIDO, USAR IA (CON HISTORIAL)
  // ============================================================

  console.log('🤔 Pensando...');
  historial.push({ role: 'user', content: orden });

  try {
    const resp = await puter.ai.chat(historial, { model: 'claude-opus-5' });
    const texto = resp.message?.content?.[0]?.text || resp.message?.content || '⚠️ Sin respuesta';
    historial.push({ role: 'assistant', content: texto });
    guardarHistorialEnKV();
    console.log(`\n${texto}`);
    return texto;
  } catch (e) {
    console.error('❌ Error con IA:', e.message);
    return '⚠️ Error al procesar con IA.';
  }
}

// ============================================================
// 4. INTERFAZ INTERACTIVA
// ============================================================

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

async function loop() {
  console.clear();
  console.log('\n🔧 AGENTE DEFINITIVO (SIN HERRAMIENTAS ROTAS)');
  console.log('📂 ' + process.cwd());
  console.log(`📜 Historial cargado: ${historial.length} mensajes`);
  console.log('📝 Órdenes: "lee X", "crea X con Y", "ejecuta X", o lenguaje natural');
  console.log('🧹 Escribe "borrar memoria" para reiniciar.\n');

  const preguntar = () => {
    rl.question('> ', async (orden) => {
      if (orden.toLowerCase() === 'salir') {
        console.log('👋 ¡Hasta luego!');
        rl.close();
        return;
      }
      if (orden.toLowerCase() === 'borrar memoria') {
        historial = [];
        await puter.kv.set(CLAVE_HISTORIAL, JSON.stringify([]));
        console.log('🧹 Memoria borrada.');
        preguntar();
        return;
      }
      await procesarOrden(orden);
      preguntar();
    });
  };
  preguntar();
}

loop().catch(console.error);
