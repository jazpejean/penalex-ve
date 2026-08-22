import fs from 'fs';
import path from 'path';

const SITEMAP_URL = 'https://pandectasdigital.blogspot.com/sitemap.xml';
const DIR_HTML = './leyes_html_bruto';
const DIR_JSON = './leyes_estructuradas';

if (!fs.existsSync(DIR_HTML)) fs.mkdirSync(DIR_HTML, { recursive: true });
if (!fs.existsSync(DIR_JSON)) fs.mkdirSync(DIR_JSON, { recursive: true });

const CATALOGO = [
    { id: 'CRBV', nombre: 'Constitución', match: ['constitucion'] },
    { id: 'CP', nombre: 'Código Penal', match: ['codigo-penal'] },
    { id: 'COPP', nombre: 'Código Orgánico Procesal Penal', match: ['codigo-organico-procesal-penal'] },
    { id: 'COJM', nombre: 'Justicia Militar', match: ['justicia-militar'] },
    { id: 'COPEN', nombre: 'Penitenciario', match: ['penitenciario'] },
    { id: 'LOCDOFT', nombre: 'Delincuencia Organizada', match: ['delincuencia-organizada'] },
    { id: 'LOD', nombre: 'Drogas', match: ['drogas'] },
    { id: 'LCSE', nombre: 'Secuestro y Extorsión', match: ['secuestro'] },
    { id: 'LCC', nombre: 'Corrupción', match: ['corrupcion'] },
    { id: 'LOED', nombre: 'Extinción de Dominio', match: ['extincion-de-dominio'] },
    { id: 'LCCO', nombre: 'Odio', match: ['odio'] },
    { id: 'LHRVA', nombre: 'Hurto y Robo Vehículos', match: ['vehiculos'] },
    { id: 'LECDI', nombre: 'Delitos Informáticos', match: ['delitos-informaticos'] },
    { id: 'LDCAM', nombre: 'Desarme y Armas', match: ['armas', 'desarme'] },
    { id: 'LOSDMVLV', nombre: 'Violencia contra la Mujer', match: ['violencia', 'mujeres'] },
    { id: 'LOPNNA', nombre: 'LOPNNA', match: ['lopnna', 'ninos'] },
    { id: 'LPVTSP', nombre: 'Protección Víctimas y Testigos', match: ['victimas'] },
    { id: 'LPST', nombre: 'Tortura', match: ['tortura'] },
    { id: 'LCTP', nombre: 'Trata de Personas', match: ['trata'] },
    { id: 'LOCDR', nombre: 'Discriminación Racial', match: ['discriminacion'] },
    { id: 'LPA', nombre: 'Penal del Ambiente', match: ['ambiente'] },
    { id: 'LPPAG', nombre: 'Actividad Ganadera', match: ['ganadera'] },
    { id: 'LOI', nombre: 'Identificación', match: ['identificacion'] },
    { id: 'LEFPI', nombre: 'Policía de Investigación', match: ['policia-de-investigacion'] },
    { id: 'LSDC', nombre: 'Contrabando', match: ['contrabando'] },
    { id: 'LOTSJ', nombre: 'TSJ', match: ['tribunal-supremo'] },
    { id: 'LOPJ', nombre: 'Poder Judicial', match: ['poder-judicial'] },
    { id: 'LOMP', nombre: 'Ministerio Público', match: ['ministerio-publico'] },
    { id: 'LODP', nombre: 'Defensa Pública', match: ['defensa-publica'] }
];

function extraerCuerpoPost(html) {
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

    const regexArt = /^(?:art[ií]culo\s+|art\.\s*)([0-9]+(?:\s*(?:bis|ter|quater|[a-z\-°º\.]))*)\s*[\.\-\:\–\—]?(.*)$/i;

    for (const linea of lineas) {
        const m = linea.match(regexArt);
        if (m) {
            if (artActual) articulos.push(artActual);
            artActual = {
                numero: m[1].replace(/[^0-9A-Za-z]/g, '').trim(),
                epigrafe: m[2].trim(),
                contenido: ""
            };
        } else if (artActual) {
            artActual.contenido += (artActual.contenido ? " " : "") + linea;
        }
    }
    if (artActual) articulos.push(artActual);
    return articulos;
}

async function obtenerUrlsSitemap() {
    console.log(`\x1b[36mDescargando sitemap del sitio...\x1b[0m`);
    const res = await fetch(SITEMAP_URL);
    if (!res.ok) throw new Error(`Error ${res.status} al leer sitemap.`);
    const xml = await res.text();
    const urls = [];
    const regexLoc = /<loc>(https?:\/\/[^<]+)<\/loc>/g;
    let match;
    while ((match = regexLoc.exec(xml)) !== null) {
        urls.push(match[1]);
    }
    console.log(`\x1b[32m✔ ${urls.length} URLs reales encontradas en el sitemap.\x1b[0m\n`);
    return urls;
}

async function ejecutar() {
    console.clear();
    console.log(`\x1b[34m=== EXTRACCIÓN AUTOMÁTICA MEDIANTE SITEMAP REAL ===\x1b[0m\n`);

    try {
        const urlsDisponibles = await obtenerUrlsSitemap();

        for (const ley of CATALOGO) {
            process.stdout.write(`Buscando ${ley.id} (${ley.nombre})... `);

            // Buscar coincidencia en las URLs reales registradas en el sitemap
            const urlReal = urlsDisponibles.find(u => {
                const urlLower = u.toLowerCase();
                return ley.match.some(m => urlLower.includes(m.toLowerCase()));
            });

            if (!urlReal) {
                console.log(`\x1b[33mNo encontrada en sitemap\x1b[0m`);
                continue;
            }

            const res = await fetch(urlReal, { headers: { 'User-Agent': 'Mozilla/5.0' } });
            if (!res.ok) {
                console.log(`\x1b[31mHTTP ${res.status}\x1b[0m`);
                continue;
            }

            const html = await res.text();
            const cuerpo = extraerCuerpoPost(html);
            const articulos = parsearArticulos(cuerpo);

            // Guardar HTML
            fs.writeFileSync(path.join(DIR_HTML, `${ley.id}.html`), cuerpo, 'utf-8');

            // Guardar JSON
            const dataFinal = {
                id: ley.id,
                titulo: ley.nombre,
                url: urlReal,
                total_articulos: articulos.length,
                articulos: articulos
            };

            fs.writeFileSync(path.join(DIR_JSON, `${ley.id}.json`), JSON.stringify(dataFinal, null, 2), 'utf-8');

            console.log(`\x1b[32mOK\x1b[0m -> \x1b[1m${articulos.length} arts\x1b[0m (\x1b[36m${urlReal.split('/').pop()}\x1b[0m)`);
            await new Promise(r => setTimeout(r, 200));
        }

        console.log(`\n\x1b[32m✔ Finalizado. Revisa las carpetas '${DIR_HTML}' y '${DIR_JSON}'.\x1b[0m\n`);
    } catch (e) {
        console.error(`\x1b[31m[ERROR]\x1b[0m ${e.message}`);
    }
}

ejecutar();
