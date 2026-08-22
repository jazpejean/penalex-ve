import { init } from '@heyputer/puter.js/src/init.cjs';
import { exec } from 'child_process';
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
// 1. FUNCIONES LOCALES (directas, sin tool_calls)
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
    return `✅ ${nombre} guardado.`;
  } catch (e) {
    return `❌ Error: ${e.message}`;
  }
}

function ejecutarComando(comando) {
  return new Promise((resolve) => {
    console.log(`\n⚠️  Ejecutar: ${comando}`);
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout
    });
    rl.question('¿Confirmar? (s/n): ', (r) => {
      rl.close();
      if (r.toLowerCase() !== 's') {
        resolve('⏹️ Cancelado.');
        return;
      }
      exec(comando, (error, stdout, stderr) => {
        if (error) resolve(`❌ ${error.message}\n${stderr}`);
        else resolve(stdout || stderr || '✅ OK');
      });
    });
  });
}

// ============================================================
// 2. INTERPRETAR ÓRDENES EN LENGUAJE NATURAL
// ============================================================

async function procesarOrden(orden) {
  orden = orden.trim();

  // Caso: "lee archivo.txt"
  if (orden.match(/^(lee|muestra|mostrar|ver|cat)\s+/i)) {
    const archivo = orden.replace(/^(lee|muestra|mostrar|ver|cat)\s+/i, '').trim();
    const contenido = leerArchivo(archivo);
    console.log(`\n📄 ${archivo}:\n${contenido}`);
    return `Leído ${archivo}`;
  }

  // Caso: "crea archivo.txt con contenido ..."
  if (orden.match(/^(crea|escribe|guarda|modifica)\s+/i)) {
    const partes = orden.match(/^(crea|escribe|guarda|modifica)\s+([^\s]+)\s+con\s+(.*)/i);
    if (partes) {
      const archivo = partes[2];
      const contenido = partes[3];
      const resultado = escribirArchivo(archivo, contenido);
      console.log(`\n${resultado}`);
      return resultado;
    }
    // Si no tiene "con ...", preguntamos
    console.log('❌ Formato: "crea archivo.txt con [contenido]"');
    return 'Formato incorrecto.';
  }

  // Caso: "ejecuta comando"
  if (orden.match(/^(ejecuta|corre|run)\s+/i)) {
    const comando = orden.replace(/^(ejecuta|corre|run)\s+/i, '').trim();
    const resultado = await ejecutarComando(comando);
    console.log(`\n💻 ${resultado}`);
    return resultado;
  }

  // Caso: comando directo (empieza con comando de sistema)
  if (orden.match(/^(ls|cat|grep|find|npm|flutter|git|python|node)\s/)) {
    const resultado = await ejecutarComando(orden);
    console.log(`\n💻 ${resultado}`);
    return resultado;
  }

  // Si no es un comando conocido, usar IA para interpretar
  console.log('🤔 Interpretando con IA...');
  return await preguntarAI(orden);
}

async function preguntarAI(orden) {
  const historial = await puter.kv.get(CLAVE_HISTORIAL);
  const ctx = historial ? JSON.parse(historial) : [];

  ctx.push({ role: 'user', content: orden });
  const resp = await puter.ai.chat(ctx, { model: 'claude-opus-5' });
  const texto = resp.message?.content?.[0]?.text || resp.message?.content || '⚠️ Sin respuesta';
  ctx.push({ role: 'assistant', content: texto });
  await puter.kv.set(CLAVE_HISTORIAL, JSON.stringify(ctx));
  return texto;
}

// ============================================================
// 3. INTERFAZ
// ============================================================

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

async function loop() {
  console.clear();
  console.log('\n🤖 AGENTE SIMPLE');
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
