import { init } from '@heyputer/puter.js/src/init.cjs';
import { exec } from 'child_process';
import fs from 'fs';
import readline from 'readline';

const PUTER_TOKEN = process.env.PUTER_TOKEN || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6InYyIn0.eyJ0IjoidCIsInYiOiIyIiwidG9rZW5fdWlkIjoiYjIyM2ViYjctNWViMC00ZTc4LTkzNDktNzBhYzllMjBmNzU2IiwidXUiOiI2M0VJYnpVYVI1aTU4Vmhtcys4UXFnPT0iLCJzdSI6Imt4ZTJGR3dzVDdHK2h3WXRaNk9Yb0E9PSIsImFpIjoiNjNFSWJ6VWFSNWk1OFZobXMrOFFxZz09IiwiZnVsbF9hY2Nlc3MiOnRydWUsImlhdCI6MTc4NzMzNjc0NH0.UW9UDGeIRxSq8pXyhO_uHHNMgErdFnNzAiYIFLN2b4k';

const puter = init(PUTER_TOKEN);
const SESSION_KEY = 'antigravity_cli_session';
const MODELO_IA = 'claude-opus-5';

const SYSTEM_PROMPT = `Eres Antigravity CLI, un agente autónomo de terminal en Linux/Lubuntu.
Tienes acceso al disco local y comandos de shell.

Cuando necesites inspeccionar el sistema, escribir código o ejecutar órdenes, responde usando EXACTAMENTE esta sintaxis en una línea dedicada:
TOOL: <herramienta> <argumentos>

Herramientas disponibles:
- TOOL: leerArchivo <ruta>
- TOOL: modificarCodigo <ruta> | <contenido>
- TOOL: listarDirectorio <ruta>
- TOOL: ejecutarComando <comando>

Ejemplos:
TOOL: leerArchivo ./HISTORIAL.md
TOOL: listarDirectorio .
TOOL: ejecutarComando ls -la

Si no requieres herramientas, responde directamente al usuario.`;

// --- HERRAMIENTAS LOCALES ---
function leerArchivo(rutaArchivo) {
    try {
        const ruta = rutaArchivo.trim();
        if (!fs.existsSync(ruta)) return `[FS ERROR] No existe: ${ruta}`;
        return fs.readFileSync(ruta, 'utf-8') || "(Archivo vacío)";
    } catch (err) {
        return `[FS ERROR] ${err.message}`;
    }
}

function modificarCodigo(args) {
    try {
        const partes = args.split('|');
        const ruta = partes[0].trim();
        const contenido = partes.slice(1).join('|');
        fs.writeFileSync(ruta, contenido, 'utf-8');
        return `[FS] Archivo '${ruta}' guardado exitosamente.`;
    } catch (err) {
        return `[FS ERROR] ${err.message}`;
    }
}

function listarDirectorio(ruta) {
    try {
        const dir = (ruta || '.').trim();
        return fs.readdirSync(dir).join('\n') || "(Directorio vacío)";
    } catch (err) {
        return `[FS ERROR] ${err.message}`;
    }
}

function ejecutarComando(comando) {
    return new Promise((resolve) => {
        console.log(`\x1b[33m⚡ [SHELL]\x1b[0m ${comando}`);
        exec(comando, { maxBuffer: 1024 * 1024 * 10 }, (error, stdout, stderr) => {
            if (error) {
                resolve(`[CMD ERROR] ${error.message}\n${stderr || ''}`);
            } else {
                resolve(stdout || stderr || "(Sin salida)");
            }
        });
    });
}

// --- NORMALIZADOR DE RESPUESTA PUTER ---
function extraerTextoPuter(raw) {
    if (!raw) return "";
    if (typeof raw === 'string') return raw;
    if (raw.text) return raw.text;
    if (raw.message?.content) {
        if (typeof raw.message.content === 'string') return raw.message.content;
        if (Array.isArray(raw.message.content)) {
            return raw.message.content.map(b => b.text || '').join('\n');
        }
    }
    if (raw.result) return extraerTextoPuter(raw.result);
    return JSON.stringify(raw);
}

// --- PERSISTENCIA PUTER KV ---
async function cargarHistorial() {
    try {
        const raw = await puter.kv.get(SESSION_KEY);
        if (!raw) return `${SYSTEM_PROMPT}\n\n`;
        return typeof raw === 'string' ? raw : JSON.stringify(raw);
    } catch {
        return `${SYSTEM_PROMPT}\n\n`;
    }
}

async function guardarHistorial(contexto) {
    try {
        await puter.kv.set(SESSION_KEY, contexto);
    } catch (e) {
        console.error(`\x1b[31m[KV ERROR]\x1b[0m ${e.message}`);
    }
}

// --- CICLO CONVERSACIONAL ---
async function procesarEntrada(ordenUsuario, contextoRef) {
    contextoRef.texto += `\nUsuario: ${ordenUsuario}\nAgente:`;

    try {
        let loops = 5;
        while (loops > 0) {
            loops--;

            const rawResponse = await puter.ai.chat(contextoRef.texto, {
                model: MODELO_IA
            });

            const respuesta = extraerTextoPuter(rawResponse);

            if (respuesta.includes("TOOL:")) {
                const lineaTool = respuesta.split('\n').find(l => l.trim().startsWith("TOOL:"));
                const match = lineaTool.replace("TOOL:", "").trim();
                const firstSpace = match.indexOf(" ");
                const toolName = firstSpace === -1 ? match : match.substring(0, firstSpace);
                const toolArgs = firstSpace === -1 ? "" : match.substring(firstSpace + 1);

                console.log(`\x1b[36m⚙ [TOOL]\x1b[0m ${toolName} ${toolArgs}`);

                let toolResult = "";
                if (toolName === "leerArchivo") toolResult = leerArchivo(toolArgs);
                else if (toolName === "modificarCodigo") toolResult = modificarCodigo(toolArgs);
                else if (toolName === "listarDirectorio") toolResult = listarDirectorio(toolArgs);
                else if (toolName === "ejecutarComando") toolResult = await ejecutarComando(toolArgs);
                else toolResult = `Herramienta desconocida: ${toolName}`;

                console.log(`\x1b[90m${toolResult.slice(0, 250)}${toolResult.length > 250 ? '...' : ''}\x1b[0m\n`);

                contextoRef.texto += ` ${respuesta}\nSistema (Resultado Tool): ${toolResult}\nAgente:`;
            } else {
                console.log(`\n\x1b[35m[ANTIGRAVITY]\x1b[0m\n${respuesta.trim()}\n`);
                contextoRef.texto += ` ${respuesta}\n`;
                break;
            }
        }

        await guardarHistorial(contextoRef.texto);
    } catch (err) {
        console.error(`\x1b[31m[ERROR]\x1b[0m ${err.message}`);
    }
}

// --- REPL ---
async function iniciarCLI() {
    console.clear();
    console.log(`\x1b[1m\x1b[34m====================================================\x1b[0m`);
    console.log(`\x1b[1m\x1b[34m       ANTIGRAVITY CLI v1.0 [Claude Opus 5]         \x1b[0m`);
    console.log(`\x1b[1m\x1b[34m====================================================\x1b[0m`);
    console.log(`Comandos: \x1b[33m/clear\x1b[0m (borrar memoria), \x1b[33m/exit\x1b[0m (salir)\n`);

    const contextoRef = { texto: await cargarHistorial() };
    console.log(`\x1b[90mMemoria sincronizada con Puter KV.\x1b[0m\n`);

    const rl = readline.createInterface({
        input: process.stdin,
        output: process.stdout,
        prompt: '\x1b[1m\x1b[32mantigravity>\x1b[0m '
    });

    rl.prompt();

    rl.on('line', async (line) => {
        const input = line.trim();
        if (!input) {
            rl.prompt();
            return;
        }

        if (input === '/exit' || input === 'exit') {
            rl.close();
            process.exit(0);
        }

        if (input === '/clear') {
            await puter.kv.del(SESSION_KEY);
            contextoRef.texto = `${SYSTEM_PROMPT}\n\n`;
            console.log("\x1b[32m✔ Memoria reiniciada.\x1b[0m\n");
            rl.prompt();
            return;
        }

        rl.pause();
        await procesarEntrada(input, contextoRef);
        rl.resume();
        rl.prompt();
    });
}

iniciarCLI();
