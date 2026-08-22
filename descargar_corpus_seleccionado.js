import fs from 'fs';
import path from 'path';

const LISTA_FILE = './leyes_penales_seleccionadas.json';
const DIR_HTML = './leyes_html_bruto';
const DIR_JSON = './leyes_estructuradas';

if (!fs.existsSync(DIR_HTML)) fs.mkdirSync(DIR_HTML, { recursive: true });
if (!fs.existsSync(DIR_JSON)) fs.mkdirSync(DIR_JSON, { recursive: true });

const lista = JSON.parse(fs.readFileSync(LISTA_FILE, 'utf-8'));

function extraerCuerpo(html) {
    const match = html.match(/<div[^>]*class=['"][^'"]*post-body[^'"]*['"][^>]*>([\s\S]*?)<\/div>\s*<div[^>]*class=['"][^'"]*post-footer/i) 
               || html.match(/<div[^>]*class=['"][^'"]*post-body[^'"]*['"][^>]*>([\s\S]*?)<\/div>/i);
    return match ? match[1] : html;
}

function parsearArticulos(htmlBruto) {
    const texto = htmlBruto
        .replace(/<\/(p|div|tr|td|li|h[1-6]|table|blockquote)>/gi, '\n')
        .replace(/<br\s*[\/]?>/gi, '\n')
        .replace(/<[^>]+>/g, ' ')
        .replace(/&nbsp;/g, ' ')
        .replace(/&quot;/g, '"')
        .replace(/&amp;/g, '&');

    const lineas = texto.split('\n').map(l => l.trim()).filter(Boolean);
    const articulos = [];
    let artActual = null;

    const regexArt = /^(?:art[ií]culo|art\.)\s*([0-9]+(?:\s*(?:bis|ter|quater|[A-Z\-°º]))*)[\.\s\:\-\–\—]*(.*)$/i;

    for (const linea of lineas) {
        const m = linea.match(regexArt);
        if (m) {
            const num = m[1].replace(/[^0-9A-Za-z]/g, '').trim();
            if (num.length > 0 && num.length <= 6) {
                if (artActual) articulos.push(artActual);
                artActual = {
                    numero: num,
                    epigrafe: m[2].trim(),
                    contenido: ""
                };
                continue;
            }
        }
        if (artActual) {
            artActual.contenido += (artActual.contenido ? " " : "") + linea;
        }
    }
    if (artActual) articulos.push(artActual);
    return articulos;
}

async function ejecutar() {
    console.clear();
    console.log(`\x1b[34m====================================================\x1b[0m`);
    console.log(`\x1b[34m   DESCARGANDO CORPUS PENAL VENEZOLANO SELECCIONADO \x1b[0m`);
    console.log(`\x1b[34m====================================================\x1b[0m\n`);

    for (const ley of lista) {
        process.stdout.write(`[${ley.id}] ${ley.titulo.slice(0, 40)}... `);

        try {
            const res = await fetch(ley.url, { headers: { 'User-Agent': 'Mozilla/5.0' } });
            if (!res.ok) {
                console.log(`\x1b[31mHTTP ${res.status}\x1b[0m`);
                continue;
            }

            const html = await res.text();
            const cuerpo = extraerCuerpo(html);
            const articulos = parsearArticulos(cuerpo);

            fs.writeFileSync(path.join(DIR_HTML, `${ley.id}.html`), cuerpo, 'utf-8');

            const salida = {
                id: ley.id,
                categoria: ley.categoria,
                titulo: ley.titulo,
                url: ley.url,
                total_articulos: articulos.length,
                articulos: articulos
            };

            fs.writeFileSync(path.join(DIR_JSON, `${ley.id}.json`), JSON.stringify(salida, null, 2), 'utf-8');

            const pesoKb = (Buffer.byteLength(cuerpo, 'utf-8') / 1024).toFixed(1);
            console.log(`\x1b[32m✔ OK\x1b[0m (${pesoKb} KB) -> \x1b[1m\x1b[33m${articulos.length} arts\x1b[0m`);

        } catch (e) {
            console.log(`\x1b[31m[Error] ${e.message}\x1b[0m`);
        }

        await new Promise(r => setTimeout(r, 200));
    }

    console.log(`\n\x1b[32m✔ PROCESO FINALIZADO.\x1b[0m`);
    console.log(`📁 JSONs listos en: ${DIR_JSON}/\n`);
}

ejecutar();
