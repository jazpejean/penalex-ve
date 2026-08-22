import fs from 'fs';

const BASE_URL = 'https://www.ley.com.ve';
const INDICE_URL = 'https://www.ley.com.ve/lopnna/lopnna';
const ARCHIVO_SALIDA = './LOPNNA_completa.html';

function extraerCuerpo(html) {
  // Extrae el contenedor principal del artículo descartando menús y cabeceras del sitio
  const match = html.match(/<article[^>]*>([\s\S]*?)<\/article>/i)
             || html.match(/<main[^>]*>([\s\S]*?)<\/main>/i)
             || html.match(/<div[^>]*class=['"][^'"]*(?:entry-content|content|cuerpo)[^'"]*['"][^>]*>([\s\S]*?)<\/div>/i);
  return match ? match[1] : html;
}

async function ejecutar() {
  console.clear();
  console.log("=== DESCARGANDO LOPNNA ÍNTEGRA DESDE LEY.COM.VE ===\n");

  console.log("1. Obteniendo índice general...");
  const resIndice = await fetch(INDICE_URL, {
    headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)' }
  });

  if (!resIndice.ok) {
    console.log(`Error HTTP al cargar el índice: ${resIndice.status}`);
    process.exit(1);
  }

  const htmlIndice = await resIndice.text();

  // Buscar todos los enlaces a artículos (/lopnna/...) dentro del índice
  const regexLinks = /href=['"](\/lopnna\/[^'"]+)['"]/gi;
  const links = [];
  let match;

  while ((match = regexLinks.exec(htmlIndice)) !== null) {
    const ruta = match[1];
    if (ruta !== '/lopnna/lopnna' && !links.includes(ruta)) {
      links.push(ruta);
    }
  }

  console.log(`✔ Se encontraron ${links.length} secciones/artículos en el índice.\n`);

  let htmlTotal = `<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Ley Orgánica para la Protección de Niños, Niñas y Adolescentes (LOPNNA)</title>
  <style>
    body { font-family: sans-serif; line-height: 1.6; max-width: 900px; margin: 40px auto; padding: 0 20px; }
    hr { margin: 30px 0; border: 0; border-top: 1px solid #ccc; }
  </style>
</head>
<body>
<h1>Ley Orgánica para la Protección de Niños, Niñas y Adolescentes (LOPNNA)</h1>
`;

  let cont = 0;
  for (const ruta of links) {
    cont++;
    const urlArticulo = `${BASE_URL}${ruta}`;
    process.stdout.write(`[${cont}/${links.length}] Descargando ${ruta}... `);

    try {
      const res = await fetch(urlArticulo, {
        headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)' }
      });

      if (!res.ok) {
        console.log(`HTTP ${res.status}`);
        continue;
      }

      const raw = await res.text();
      const cuerpo = extraerCuerpo(raw);

      htmlTotal += `\n<!-- INICIO SECCION: ${ruta} -->\n`;
      htmlTotal += `<div class="seccion-ley">\n${cuerpo}\n</div>\n<hr/>\n`;

      console.log("OK");
    } catch (e) {
      console.log(`Error: ${e.message}`);
    }

    await new Promise(r => setTimeout(r, 120));
  }

  htmlTotal += `\n</body>\n</html>`;

  fs.writeFileSync(ARCHIVO_SALIDA, htmlTotal, 'utf-8');
  console.log(`\n✔ Descarga completa. Archivo guardado en: ${ARCHIVO_SALIDA} (${(Buffer.byteLength(htmlTotal, 'utf-8') / 1024).toFixed(1)} KB)`);
}

ejecutar();
