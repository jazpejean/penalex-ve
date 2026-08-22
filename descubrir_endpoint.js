import fs from 'fs';

const cuentas = JSON.parse(fs.readFileSync('./cuentas_puter.json', 'utf-8'));
const token = cuentas[0].token;

async function descubrir() {
  console.log("1. Leyendo SDK oficial de Puter (js.puter.com/v2)...");
  const resSdk = await fetch("https://js.puter.com/v2/");
  const sdkCode = await resSdk.text();

  // Buscar fragmentos clave en el SDK
  const matchAiChat = sdkCode.match(/ai\s*:\s*\{[\s\S]{1,400}?chat\s*:\s*function[\s\S]{1,600}?\}/i);
  if (matchAiChat) {
    console.log("✔ Fragmento de ai.chat encontrado en el SDK:\n", matchAiChat[0].slice(0, 300));
  }

  // Rutas candidatas basadas en el backend de Puter
  const candidatos = [
    {
      url: "https://api.puter.com/drivers/call",
      body: {
        interface: "chat-completion",
        driver: "claude-3-5-sonnet",
        method: "complete",
        args: { messages: [{ role: "user", content: "Hola responde 'OK'" }] }
      }
    },
    {
      url: "https://api.puter.com/drivers/call",
      body: {
        interface: "puter-chat-completion",
        driver: "claude-3-5-sonnet",
        method: "complete",
        args: { messages: [{ role: "user", content: "Hola responde 'OK'" }] }
      }
    },
    {
      url: "https://api.puter.com/ai/chat",
      body: {
        messages: [{ role: "user", content: "Hola responde 'OK'" }],
        model: "claude-3-5-sonnet"
      }
    },
    {
      url: "https://api.puter.com/ai/chat",
      body: {
        prompt: "Hola responde 'OK'",
        model: "claude-3-5-sonnet"
      }
    },
    {
      url: "https://api.puter.com/v2/ai/chat",
      body: {
        messages: [{ role: "user", content: "Hola responde 'OK'" }],
        model: "claude-3-5-sonnet"
      }
    }
  ];

  console.log("\n2. Probando endpoints candidatos con tu token...");
  for (const c of candidatos) {
    try {
      const r = await fetch(c.url, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${token}`
        },
        body: JSON.stringify(c.body)
      });

      const txt = await r.text();
      console.log(`[HTTP ${r.status}] -> ${c.url} (${JSON.stringify(c.body).slice(0, 60)}...)`);
      console.log(`   Respuesta: ${txt.slice(0, 120)}\n`);
      
      if (r.ok) {
        console.log(`\x1b[32m✔ ENDPOINT CORRECTO ENCONTRADO:\x1b[0m ${c.url}`);
        break;
      }
    } catch (e) {
      console.log(`[Error de red] ${c.url}: ${e.message}`);
    }
  }
}

descubrir();
