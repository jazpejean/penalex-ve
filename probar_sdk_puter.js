import fs from 'fs';

const cuentas = JSON.parse(fs.readFileSync('./cuentas_puter.json', 'utf-8'));
const token = cuentas[0].token;

async function ejecutar() {
  console.log("1. Descargando SDK oficial de Puter...");
  const resSdk = await fetch("https://js.puter.com/v2/");
  const sdkCode = await resSdk.text();

  // Buscar definiciones de AI en el código fuente del SDK
  console.log("\n2. Extrayendo firmas de AI del SDK...");
  const matches = sdkCode.matchAll(/([a-zA-Z0-9_$]+)\s*=\s*\{\s*chat\s*:\s*function/g);
  for (const m of matches) {
    const idx = m.index;
    console.log("--- Bloque chat encontrado ---");
    console.log(sdkCode.slice(idx, idx + 400));
    console.log("------------------------------\n");
  }

  // Montar entorno mock de navegador
  global.window = global;
  global.document = {
    createElement: () => ({ setAttribute: () => {}, style: {} }),
    head: { appendChild: () => {} },
    body: { appendChild: () => {} },
    addEventListener: () => {},
    currentScript: { src: "https://js.puter.com/v2/" }
  };
  global.navigator = { userAgent: "Mozilla/5.0" };
  global.localStorage = {
    getItem: (k) => (k === "puter.auth_token" ? token : null),
    setItem: () => {},
    removeItem: () => {}
  };
  global.location = new URL("https://puter.com");

  // Interceptar fetch para registrar la petición exacta
  const fetchOriginal = global.fetch;
  global.fetch = async (url, options = {}) => {
    if (url.toString().includes("puter.com") && options.method === "POST") {
      console.log("\n\x1b[36m>>> PETICIÓN CAPTURADA DEL SDK <<<\x1b[0m");
      console.log(`URL: \x1b[33m${url}\x1b[0m`);
      console.log(`Headers:`, options.headers);
      console.log(`Body:`, options.body);
      console.log("\x1b[36m>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\x1b[0m\n");
    }
    return fetchOriginal(url, options);
  };

  console.log("3. Inicializando SDK en Node...");
  try {
    eval(sdkCode);
    console.log("✔ SDK inicializado. Objeto puter disponible:", typeof window.puter);

    if (window.puter) {
      window.puter.authToken = token;
      
      console.log("4. Ejecutando puter.ai.chat('Hola')...");
      const respuesta = await window.puter.ai.chat("Hola, responde solo 'CONECTADO'");
      console.log("\n\x1b[32m✔ RESPUESTA DE LA IA:\x1b[0m", respuesta);
    }
  } catch (err) {
    console.log("\x1b[31m[Error en ejecución]:\x1b[0m", err);
  }
}

ejecutar();
