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
// 1. HERRAMIENTAS LOCALES (con salida formateada)
// ============================================================

function leerArchivo(nombre) {
  try {
    const contenido = fs.readFileSync(nombre, 'utf-8');
    return `📄 CONTENIDO DE ${nombre}:\n\n${contenido}\n\n--- FIN ---`;
  } catch (e) {
    return `❌ No se pudo leer ${nombre}: ${e.message}`;
  }
}

function listarArchivos(ruta = '.') {
  try {
    const items = fs.readdirSync(ruta);
    const archivos = items.filter(i => fs.statSync(`${ruta}/${i}`).isFile());
    const directorios = items.filter(i => fs.statSync(`${ruta}/${i}`).isDirectory());
    let salida = `📁 Directorios en ${ruta}:\n`;
    directorios.forEach(d => salida += `  📂 ${d}\n`);
    salida += `\n📄 Archivos en ${ruta}:\n`;
    archivos.forEach(a => salida += `  📄 ${a}\n`);
    return salida;
  } catch (e) {
    return `❌ Error al listar ${ruta}: ${e.message}`;
  }
}

function buscarEnArchivos(patron, ruta = '.') {
  try {
    const { execSync } = await import('child_process');
    const resultado = execSync(`grep -r "${patron}" ${ruta} --include="*.dart" 2>/dev/null || true`, { encoding: 'utf-8' });
    if (!resultado.trim()) return `🔍 No se encontró "${patron}" en los archivos.`;
    return `🔍 RESULTADOS DE BÚSQUEDA PARA "${patron}":\n\n${resultado}`;
  } catch (e) {
    return `❌ Error en la búsqueda: ${e.message}`;
  }
}

function ejecutarComando(comando) {
  return new Promise((resolve) => {
    console.log(`\n⚠️  El agente quiere ejecutar: ${comando}`);
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout
    });
    rl.question('¿Confirmas? (s/n): ', (respuesta) => {
      rl.close();
      if (respuesta.toLowerCase() !== 's') {
        resolve('⏹️ Comando cancelado.');
        return;
      }
      exec(comando, (error, stdout, stderr) => {
        if (error) {
          resolve(`❌ Error: ${error.message}\n${stderr}`);
        } else {
          resolve(stdout || stderr || '✅ Comando ejecutado sin salida.');
        }
      });
    });
  });
}

function modificarCodigo(nombreArchivo, contenido) {
  try {
    fs.writeFileSync(nombreArchivo, contenido, 'utf-8');
    return `✅ Archivo '${nombreArchivo}' guardado con éxito.`;
  } catch (e) {
    return `❌ Error al guardar ${nombreArchivo}: ${e.message}`;
  }
}

// ============================================================
// 2. CONFIGURACIÓN DE HERRAMIENTAS PARA PUTER
// ============================================================

const herramientasPuter = [
  {
    name: "leerArchivo",
    description: "Lee el contenido de un archivo y lo muestra. Úsalo cuando el usuario pida ver, leer, mostrar o revisar un archivo.",
    parameters: {
      type: "object",
      properties: {
        nombre: { type: "string", description: "Ruta del archivo a leer (ej: lib/logic/dosimetria_engine.dart)" }
      },
      required: ["nombre"]
    }
  },
  {
    name: "listarArchivos",
    description: "Lista el contenido de una carpeta. Úsalo cuando el usuario pregunte qué archivos hay en una carpeta o quiera ver la estructura del proyecto.",
    parameters: {
      type: "object",
      properties: {
        ruta: { type: "string", description: "Ruta de la carpeta (opcional, por defecto '.')" }
      }
    }
  },
  {
    name: "buscarEnArchivos",
    description: "Busca un texto dentro de los archivos .dart del proyecto. Úsalo cuando el usuario pregunte dónde se usa algo o busque una palabra clave.",
    parameters: {
      type: "object",
      properties: {
        patron: { type: "string", description: "Texto a buscar (ej: 'termino medio', 'Art. 37')" },
        ruta: { type: "string", description: "Ruta donde buscar (opcional, por defecto '.')" }
      },
      required: ["patron"]
    }
  },
  {
    name: "ejecutarComando",
    description: "Ejecuta un comando en la terminal. Úsalo para comandos como 'ls', 'cat', 'grep', 'flutter', 'npm', 'git', etc. Siempre pide confirmación al usuario.",
    parameters: {
      type: "object",
      properties: {
        comando: { type: "string", description: "Comando exacto a ejecutar (ej: 'cat HISTORIAL.md', 'flutter pub get')" }
      },
      required: ["comando"]
    }
  },
  {
    name: "modificarCodigo",
    description: "Crea o modifica un archivo de código. Úsalo cuando el usuario pida crear, modificar, actualizar o escribir código en un archivo.",
    parameters: {
      type: "object",
      properties: {
        nombreArchivo: { type: "string", description: "Ruta del archivo a crear/modificar" },
        contenido: { type: "string", description: "Contenido completo que irá en el archivo" }
      },
      required: ["nombreArchivo", "contenido"]
    }
  }
];

// ============================================================
// 3. FUNCIÓN PRINCIPAL CON MEMORIA
// ============================================================

async function interactuarConAgente(ordenUsuario) {
  console.log(`\n👤 ${ordenUsuario}`);

  // Recuperar historial
  let historial = await puter.kv.get(CLAVE_HISTORIAL);
  historial = historial ? JSON.parse(historial) : [];

  // Borrar memoria
  if (ordenUsuario.toLowerCase().trim() === 'borrar memoria') {
    await puter.kv.set(CLAVE_HISTORIAL, JSON.stringify([]));
    console.log('🧹 Memoria borrada.');
    return;
  }

  // Agregar orden al historial
  historial.push({ role: "user", content: ordenUsuario });

  try {
    // Llamar a Puter con herramientas
    const respuesta = await puter.ai.chat(historial, {
      model: "claude-opus-5",
      tools: herramientasPuter,
      tool_choice: "auto"
    });

    // Procesar tool calls
    if (respuesta.tool_calls && respuesta.tool_calls.length > 0) {
      for (const llamada of respuesta.tool_calls) {
        const args = JSON.parse(llamada.arguments);
        let resultado = "";

        console.log(`🤖 Usando: ${llamada.name}`);

        switch (llamada.name) {
          case "leerArchivo":
            resultado = leerArchivo(args.nombre);
            break;
          case "listarArchivos":
            resultado = listarArchivos(args.ruta || '.');
            break;
          case "buscarEnArchivos":
            resultado = await buscarEnArchivos(args.patron, args.ruta || '.');
            break;
          case "ejecutarComando":
            resultado = await ejecutarComando(args.comando);
            break;
          case "modificarCodigo":
            resultado = modificarCodigo(args.nombreArchivo, args.contenido);
            break;
          default:
            resultado = `⚠️ Herramienta no implementada: ${llamada.name}`;
        }

        // Mostrar el resultado de la herramienta
        console.log(`\n${resultado}\n`);

        // Guardar resultado en el historial para contexto
        historial.push(respuesta.message);
        historial.push({
          role: "tool",
          tool_call_id: llamada.id,
          content: resultado
        });

        // Obtener respuesta final de la IA
        const respuestaFinal = await puter.ai.chat(historial, {
          model: "claude-opus-5"
        });

        const textoFinal = respuestaFinal.message.content?.[0]?.text || 
                           respuestaFinal.message.content || 
                           '⚠️ No se recibió respuesta de la IA.';
        console.log(`🤖 ${textoFinal}`);
        historial.push(respuestaFinal.message);

        // Guardar en la nube
        await puter.kv.set(CLAVE_HISTORIAL, JSON.stringify(historial));
        return;
      }
    } else {
      // Sin herramientas
      const texto = respuesta.message.content?.[0]?.text || 
                    respuesta.message.content || 
                    '⚠️ No se recibió respuesta.';
      console.log(`🤖 ${texto}`);
      historial.push(respuesta.message);
      await puter.kv.set(CLAVE_HISTORIAL, JSON.stringify(historial));
    }

  } catch (error) {
    console.error('❌ Error:', error.message);
    historial.push({ role: "system", content: `Error: ${error.message}` });
    await puter.kv.set(CLAVE_HISTORIAL, JSON.stringify(historial));
  }
}

// ============================================================
// 4. INTERFAZ INTERACTIVA
// ============================================================

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

async function bucle() {
  console.clear();
  console.log('\n🧠 AGENTE DEFINITIVO');
  console.log('📂 ' + process.cwd());
  console.log('☁️  Memoria en la nube (Puter KV)');
  console.log('📝 Escribe en lenguaje natural lo que necesites.');
  console.log('🧹 "borrar memoria" para reiniciar.');
  console.log('👋 "salir" para terminar.\n');

  const preguntar = () => {
    rl.question('💬 ¿Qué necesitas? ', async (orden) => {
      if (orden.toLowerCase() === 'salir') {
        console.log('👋 ¡Hasta luego!');
        rl.close();
        return;
      }
      await interactuarConAgente(orden);
      preguntar();
    });
  };

  preguntar();
}

bucle().catch(console.error);
