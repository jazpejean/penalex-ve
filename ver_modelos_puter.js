import fs from 'fs';

const cuentas = JSON.parse(fs.readFileSync('./cuentas_puter.json', 'utf-8'));
const token = cuentas[0].token;

// Lista de modelos a testear contra la API de Puter
const MODELOS = [
  // Anthropic / Opus / Sonnet / Haiku
  "claude-3-opus",
  "claude-opus-5",
  "claude-3-opus-20240229",
  "claude-3-5-opus",
  "claude-3-7-sonnet",
  "claude-3-5-sonnet",
  "claude-3-5-sonnet-20241022",
  "claude-3-haiku",
  
  // OpenAI
  "gpt-4o",
  "gpt-4o-mini",
  "gpt-4-turbo",
  "gpt-4",
  "o1",
  "o1-mini",
  "o3-mini",
  
  // DeepSeek & Otros
  "deepseek-chat",
  "deepseek-reasoner",
  "deepseek-r1",
  "gemini-2.0-flash",
  "gemini-1.5-pro",
  "gemini-1.5-flash",
  "mistral-large-latest"
];

async function probarModelo(modelo) {
  const payload = {
    interface: "puter-chat-completion",
    driver: "ai-chat",
    test_mode: false,
    method: "complete",
    args: {
      messages: [{ role: "user", content: "ping" }],
      model: modelo
    },
    auth_token: token
  };

  try {
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

    if (res.ok) {
      const json = await res.json();
      return { ok: true, detalle: "Activo / Respondiendo" };
    } else {
      const err = await res.json().catch(() => ({}));
      return { ok: false, detalle: err.message || `HTTP ${res.status}` };
    }
  } catch (e) {
    return { ok: false, detalle: e.message };
  }
}

async function ejecutar() {
  console.clear();
  console.log("=== COMPROBANDO CATÁLOGO DE MODELOS EN PUTER ===\n");
  
  const disponibles = [];

  for (const mod of MODELOS) {
    process.stdout.write(`Probando ${mod.padEnd(28, ' ')}... `);
    const res = await probarModelo(mod);
    
    if (res.ok) {
      console.log("\x1b[32m✔ DISPONIBLE\x1b[0m");
      disponibles.push(mod);
    } else {
      console.log(`\x1b[31m✖ NO (${res.detalle})\x1b[0m`);
    }
    await new Promise(r => setTimeout(r, 100));
  }

  console.log("\n================================================");
  console.log("\x1b[36mMODELOS ACTIVOS QUE PUEDES USAR AHORA MISMO:\x1b[0m");
  console.log("================================================");
  disponibles.forEach(m => console.log(` * ${m}`));
}

ejecutar();
