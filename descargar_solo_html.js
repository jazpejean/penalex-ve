import fs from 'fs';
import path from 'path';

const DIR_HTML = './leyes_html';
if (!fs.existsSync(DIR_HTML)) fs.mkdirSync(DIR_HTML, { recursive: true });

const FUENTES = [
  { id: "COPP", nombre: "Codigo_Organico_Procesal_Penal", url: "https://pandectasdigital.blogspot.com/2021/09/codigo-organico-procesal-penal.html" },
  { id: "COJM", nombre: "Codigo_Organico_Justicia_Militar", url: "https://pandectasdigital.blogspot.com/2021/09/codigo-organico-de-justicia-militar.html" },
  { id: "COPEN", nombre: "Codigo_Organico_Penitenciario", url: "https://pandectasdigital.blogspot.com/2021/09/codigo-organico-penitenciario.html" },
  { id: "LOCDOFT", nombre: "Ley_Organica_Delincuencia_Organizada", url: "https://pandectasdigital.blogspot.com/2016/08/ley-organica-contra-la-delincuencia.html" },
  { id: "LCSE", nombre: "Ley_Secuestro_y_Extorsion", url: "https://pandectasdigital.blogspot.com/2017/03/ley-contra-el-secuestro-y-la-extorsion.html" },
  { id: "LOED", nombre: "Ley_Extincion_de_Dominio", url: "https://pandectasdigital.blogspot.com/2023/04/ley-organica-de-extincion-de-dominio.html" },
  { id: "LCCO", nombre: "Ley_Constitucional_Contra_el_Odio", url: "https://pandectasdigital.blogspot.com/2017/11/ley-constitucional-contra-el-odio-por.html" },
  { id: "LHRVA", nombre: "Ley_Hurto_Robo_Vehiculos", url: "https://pandectasdigital.blogspot.com/2016/09/ley-sobre-el-hurto-y-robo-de-vehiculos.html" },
  { id: "LDCAM", nombre: "Ley_Desarme_y_Control_Armas", url: "https://pandectasdigital.blogspot.com/2016/08/ley-para-el-desarme-y-control-de-armas.html" },
  { id: "LOSDMVLV", nombre: "Ley_Violencia_Mujeres", url: "https://pandectasdigital.blogspot.com/2021/12/ley-organica-sobre-el-derecho-de-las.html" },
  { id: "LPVTSP", nombre: "Ley_Proteccion_Victimas_y_Testigos", url: "https://pandectasdigital.blogspot.com/2021/09/ley-de-proteccion-de-victimas-testigos.html" },
  { id: "LPST", nombre: "Ley_Tortura_y_Tratos_Crueles", url: "https://pandectasdigital.blogspot.com/2017/02/ley-especial-para-prevenir-y-sancionar.html" },
  { id: "LOCDR", nombre: "Ley_Discriminacion_Racial", url: "https://pandectasdigital.blogspot.com/2021/10/ley-organica-contra-la-discriminacion.html" },
  { id: "LEFPI", nombre: "Ley_Estatuto_Policia_Investigacion", url: "https://pandectasdigital.blogspot.com/2026/02/ley-del-estatuto-de-la-funcion-de-la.html" },
  { id: "LSDC", nombre: "Ley_Delito_de_Contrabando", url: "https://pandectasdigital.blogspot.com/2016/09/ley-sobre-el-delito-de-contrabando.html" },
  { id: "LOTSJ", nombre: "Ley_Organica_TSJ", url: "https://pandectasdigital.blogspot.com/2026/05/ley-organica-del-tribunal-supremo-de.html" },
  { id: "LOPJ", nombre: "Ley_Organica_Poder_Judicial", url: "https://pandectasdigital.blogspot.com/2017/03/ley-organica-del-poder-judicial.html" },
  { id: "LOMP", nombre: "Ley_Organica_Ministerio_Publico", url: "https://pandectasdigital.blogspot.com/2016/09/ley-organica-del-ministerio-publico.html" },
  { id: "LODP", nombre: "Ley_Organica_Defensa_Publica", url: "https://pandectasdigital.blogspot.com/2022/05/ley-organica-de-la-defensa-publica.html" }
];

const CP_PARTES = [
  "https://pandectasdigital.blogspot.com/2005/04/codigo-penal-libro-segundo-titulo-x.html",
  "https://pandectasdigital.blogspot.com/2005/04/codigo-penal-libro-tercero-titulo-i.html",
  "https://pandectasdigital.blogspot.com/2022/04/codigo-penal-libro-tercero-titulo-ii.html",
  "https://pandectasdigital.blogspot.com/2005/04/codigo-penal-libro-tercero-titulo-iii.html",
  "https://pandectasdigital.blogspot.com/2005/04/codigo-penal-libro-tercero-titulo-iv.html"
];

function extraerCuerpo(html) {
  const match = html.match(/<div[^>]*class=['"][^'"]*post-body[^'"]*['"][^>]*>([\s\S]*?)<\/div>\s*<div[^>]*class=['"][^'"]*post-footer/i)
             || html.match(/<div[^>]*class=['"][^'"]*post-body[^'"]*['"][^>]*>([\s\S]*?)<\/div>/i);
  return match ? match[1] : html;
}

async function descargar() {
  console.clear();
  console.log("=== DESCARGANDO HTMLs EN BRUTO ===\n");

  // Descargar partes del Código Penal y unirlas en un solo archivo HTML
  process.stdout.write("Descargando Código Penal (CP.html)... ");
  let cpHtml = "";
  for (const u of CP_PARTES) {
    try {
      const r = await fetch(u, { headers: { 'User-Agent': 'Mozilla/5.0' } });
      if (r.ok) cpHtml += extraerCuerpo(await r.text()) + "\n<hr>\n";
    } catch {}
  }
  fs.writeFileSync(path.join(DIR_HTML, "CP_Codigo_Penal.html"), cpHtml, "utf-8");
  console.log(`OK (${(Buffer.byteLength(cpHtml, 'utf-8') / 1024).toFixed(1)} KB)`);

  // Descargar el resto de leyes
  for (const ley of FUENTES) {
    process.stdout.write(`Descargando ${ley.id} (${ley.nombre}.html)... `);
    try {
      const res = await fetch(ley.url, { headers: { 'User-Agent': 'Mozilla/5.0' } });
      if (!res.ok) {
        console.log(`HTTP ${res.status}`);
        continue;
      }
      const raw = await res.text();
      const body = extraerCuerpo(raw);
      fs.writeFileSync(path.join(DIR_HTML, `${ley.id}_${ley.nombre}.html`), body, "utf-8");
      console.log(`OK (${(Buffer.byteLength(body, 'utf-8') / 1024).toFixed(1)} KB)`);
    } catch (e) {
      console.log(`Error: ${e.message}`);
    }
    await new Promise(r => setTimeout(r, 150));
  }

  console.log(`\n✔ Descarga finalizada. Archivos listos en: ${DIR_HTML}/`);
}

descargar();
