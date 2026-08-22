import fs from 'fs';

const BASE = 'https://www.ley.com.ve';
const INICIO = 'https://www.ley.com.ve/lopnna/lopnna';
const SALIDA = './LOPNNA_completa.html';

const visitados = new Set();
const urlsArticulos = new Set();
const colaCategorias = [INICIO];

function esRutaValida(url) {
  if (!url.startsWith('/lopnna/')) return false;
  if (url.match(/\.(css|js|png|jpg|jpeg|gif|ico|svg|woff2?|ttf)(\?.*)?$/i)) return false;
  if (url.includes('/media/') || url.includes('/templates/')) return false;
  return true;
}

function extraerCuerpo(html) {
  const match = html.match(/<article[^>]*>([\s\S]*?)<\/article>/i)
             || html.match(/<div[^>]*itemprop=['"]articleBody['"][^>]*>([\s\S]*?)<\/div>/i)
             || html.match(/<div[^>]*class=['"][^'"]*com-content-article__body[^'"]*['"][^>]*>([\s\S]*?)<\/div>/i)
             || html.match(/<main[^>]*>([\s\S]*?)<\/main>/i);
  return match ? match[1] : html;
}

async function explorar() {
  console.clear();
  console.log("=== RASTREANDO ÍNDICE Y ARTÍCULOS DE LA LOPNNA ===\n");

  while (colaCategorias.length > 0) {
    const actual = colaCategorias.shift();
    if (visitados.has(actual)) continue;
    visitados.add(actual);

    process.stdout.write(`Explorando índice: ${actual}... `);
    try {
      const res = await fetch(actual.startsWith('http') ? actual : `${BASE}${actual}`, {
        headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)' }
      });
      if (!res.ok) {
        console.log(`HTTP ${res.status}`);
        continue;
      }

      const html = await res.text();
      const regexHref = /href=['"](\/lopnna\/[^'"]+)['"]/gi;
      let m;
      let nuevos = 0;

      while ((m = regexHref.exec(html)) !== null) {
        const ruta = m[1].split('#')[0];
        if (!esRutaValida(ruta)) continue;

        if (ruta.includes('articulo') || ruta.includes('disposicion')) {
          urlsArticulos.add(ruta);
        } else if (!visitados.has(ruta) && !colaCategorias.includes(ruta)) {
          colaCategorias.push(ruta);
          nuevos++;
        }
      }
      console.log(`OK (${urlsArticulos.size} artículos detectados)`);
    } catch (e) {
      console.log(`Error: ${e.message}`);
    }
    await new Promise(r => setTimeout(r, 60));
  }

  console.log(`\n✔ Rastreo completado. Total de artículos a descargar: ${urlsArticulos.size}\n`);

  let htmlDoc = `<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Ley Orgánica para la Protección de Niños, Niñas y Adolescentes (LOPNNA)</title>
  <style>
    body { font-family: sans-serif; line-height: 1.6; max-width: 900px; margin: 40px auto; padding: 0 20px; }
    .articulo-caja { margin-bottom: 25px; padding-bottom: 20px; border-bottom: 1px solid #ddd; }
  </style>
</head>
<body>
<h1>Ley Orgánica para la Protección de Niños, Niñas y Adolescentes (LOPNNA)</h1>
`;

  const listaFinal = Array.from(urlsArticulos).sort((a, b) => {
    const numA = parseInt((a.match(/\d+/) || [0])[0], 10);
    const numB = parseInt((b.match(/\d+/) || [0])[0], 10);
    return numA - numB;
  });

  let i = 0;
  for (const ruta of listaFinal) {
    i++;
    process.stdout.write(`[${i}/${listaFinal.length}] Descargando ${ruta}... `);
    try {
      const res = await fetch(`${BASE}${ruta}`, {
        headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)' }
      });
      if (!res.ok) {
        console.log(`HTTP ${res.status}`);
        continue;
      }
      const raw = await res.text();
      const contenido = extraerCuerpo(raw);
      htmlDoc += `\n<div class="articulo-caja" data-url="${ruta}">\n${contenido}\n</div>\n`;
      console.log("OK");
    } catch (err) {
      console.log(`Error: ${err.message}`);
    }
    await new Promise(r => setTimeout(r, 80));
  }

  htmlDoc += `\n</body>\n</html>`;
  fs.writeFileSync(SALIDA, htmlDoc, 'utf-8');

  console.log(`\n✔ Documento HTML unificado generado en: ${SALIDA} (${(Buffer.byteLength(htmlDoc, 'utf-8') / 1024).toFixed(1)} KB)`);
}

explorar();
