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

// ============================================================
// FUNCIONES DIRECTAS (sin herramientas ni Function Calling)
// ============================================================

function leerArchivo(nombre) {
  try {
    return fs.readFileSync(nombre, 'utf-8');
  } catch (e) {
    return `❌ Error: ${e.message}`;
  }
}

function escribirArchivo(nombre, contenido) {
  try {
    fs.writeFileSync(nombre, contenido, 'utf-8');
    return `✅ Archivo '${nombre}' guardado.`;
  } catch (e) {
    return `❌ Error: ${e.message}`;
  }
}

function ejecutarComando(comando) {
  try {
    const output = execSync(comando, { encoding: 'utf-8', timeout: 10000 });
    return output || '✅ Comando ejecutado sin salida.';
  } catch (e) {
    return `❌ Error: ${e.message}`;
  }
}

// ============================================================
// INTERPRETAR ÓRDENES EN LENGUAJE NATURAL (SIN TECNICISMO)
// ============================================================

async function procesarOrden(orden) {
  orden = orden.trim();

  // 1. "lee X" o "muestra X" o "cat X"
  const leerMatch = orden.match(/^(lee|muestra|mostrar|ver|cat)\s+(.+)/i);
  if (leerMatch) {
    const archivo = leerMatch[2];
    console.log(`📄 Leyendo ${archivo}...`);
    const contenido = leerArchivo(archivo);
    console.log(contenido);
    return contenido;
  }

  // 2. "crea X con Y" o "escribe X con Y"
  const crearMatch = orden.match(/^(crea|escribe|guarda|modifica)\s+([^\s]+)\s+con\s+(.+)/i);
  if (crearMatch) {
    const archivo = crearMatch[2];
    const contenido = crearMatch[3];
    console.log(`✍️ Escribiendo ${archivo}...`);
    const resultado = escribirArchivo(archivo, contenido);
    console.log(resultado);
    return resultado;
  }

  // 3. "ejecuta X" o "corre X" o "run X"
  const ejecutarMatch = orden.match(/^(ejecuta|corre|run)\s+(.+)/i);
  if (ejecutarMatch) {
    const comando = ejecutarMatch[2];
    console.log(`💻 Ejecutando: ${comando}`);
    const resultado = ejecutarComando(comando);
    console.log(resultado);
    return resultado;
  }

  // 4. Comandos directos (ls, cat, grep, etc.)
  if (orden.match(/^(ls|cat|grep|find|npm|flutter|git|python|node|pwd|echo|wc|tail|head|cd)\s/)) {
    console.log(`💻 Ejecutando: ${orden}`);
    const resultado = ejecutarComando(orden);
    console.log(resultado);
    return resultado;
  }

  // 5. Si no es un comando conocido, usar IA (con historial en la nube)
  console.log('🤔 Interpretando con IA...');
  const historial = await puter.kv.get(CLAVE_HISTORIAL) || '[]';
  const ctx = JSON.parse(historial);
  ctx.push({ role: 'user', content: orden });
  const resp = await puter.ai.chat(ctx, { model: 'claude-opus-5' });
  const texto = resp.message?.content?.[0]?.text || resp.message?.content || '⚠️ Sin respuesta';
  ctx.push({ role: 'assistant', content: texto });
  await puter.kv.set(CLAVE_HISTORIAL, JSON.stringify(ctx));
  console.log(texto);
  return texto;
}

// ============================================================
// INTERFAZ
// ============================================================

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

async function loop() {
  console.clear();
  console.log('\n🤖 AGENTE FINAL (sin copiar/pegar)');
  console.log('📂 ' + process.cwd());
  console.log('📝 Órdenes: "lee X", "crea X con Y", "ejecuta X", o lenguaje natural');
  console.log('🧹 Escribe "borrar memoria" para reiniciar.\n');

  const preguntar = () => {
    rl.question('> ', async (orden) => {
      if (orden.toLowerCase() === 'salir') {
        console.log('👋 Chao');
        rl.close();
        return;
      }
      if (orden.toLowerCase() === 'borrar memoria') {
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
