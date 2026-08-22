import fs from 'fs';
import path from 'path';

const DIR_HTML = './leyes_html_bruto';
const DIR_JSON = './leyes_estructuradas';

if (!fs.existsSync(DIR_HTML)) fs.mkdirSync(DIR_HTML, { recursive: true });
if (!fs.existsSync(DIR_JSON)) fs.mkdirSync(DIR_JSON, { recursive: true });

// URLs exactas de Pandectas Digital
const LEYES = [
    { id: 'CRBV', nombre: 'Constitución de la República Bolivariana de Venezuela', url: 'https://pandectasdigital.blogspot.com/p/constitucion-de-la-republica.html' },
    { id: 'CP', nombre: 'Código Penal', url: 'https://pandectasdigital.blogspot.com/p/codigo-penal.html' },
    { id: 'COPP', nombre: 'Código Orgánico Procesal Penal', url: 'https://pandectasdigital.blogspot.com/p/codigo-organico-procesal-penal.html' },
    { id: 'COJM', nombre: 'Código Orgánico de Justicia Militar', url: 'https://pandectasdigital.blogspot.com/p/codigo-organico-de-justicia-militar.html' },
    { id: 'COPEN', nombre: 'Código Orgánico Penitenciario', url: 'https://pandectasdigital.blogspot.com/p/codigo-organico-penitenciario.html' },
    { id: 'LOCDOFT', nombre: 'Ley Orgánica contra la Delincuencia Organizada y Financiamiento al Terrorismo', url: 'https://pandectasdigital.blogspot.com/p/ley-organica-contra-la-delincuencia.html' },
    { id: 'LOD', nombre: 'Ley Orgánica de Drogas', url: 'https://pandectasdigital.blogspot.com/p/ley-organica-de-drogas.html' },
    { id: 'LCSE', nombre: 'Ley contra el Secuestro y la Extorsión', url: 'https://pandectasdigital.blogspot.com/p/ley-contra-el-secuestro-y-la-extorsion.html' },
    { id: 'LCC', nombre: 'Ley contra la Corrupción', url: 'https://pandectasdigital.blogspot.com/p/ley-contra-la-corrupcion.html' },
    { id: 'LOSDMVLV', nombre: 'Ley Orgánica sobre el Derecho de las Mujeres a una Vida Libre de Violencia', url: 'https://pandectasdigital.blogspot.com/p/ley-organica-sobre-el-derecho-de-las.html' },
    { id: 'LOPNNA', nombre: 'Ley Orgánica para la Protección de Niños, Niñas y Adolescentes', url: 'https://pandectasdigital.blogspot.com/p/lopnna.html' },
    { id: 'LECDI', nombre: 'Ley Especial contra los Delitos Informáticos', url: 'https://pandectasdigital.blogspot.com/p/ley-especial-contra-los-delitos.html' },
    { id: 'LDCAM', nombre: 'Ley para el Desarme y Control de Armas y Municiones', url: 'https://pandectasdigital.blogspot.com/p/ley-para-el-desarme-y-control-de-armas.html' },
    { id: 'LOTSJ', nombre: 'Ley Orgánica del Tribunal Supremo de Justicia', url: 'https://pandectasdigital.blogspot.com/p/ley-organica-del-tribunal-supremo-de.html' },
    { id: 'LOPJ', nombre: 'Ley Orgánica del Poder Judicial', url: 'https://pandectasdigital.blogspot.com/p/ley-organica-del-poder-judicial.html' },
    { id: 'LOMP', nombre: 'Ley Orgánica del Ministerio Público', url: 'https://pandectasdigital.blogspot.com/p/ley-organica-del-ministerio-publico.html' },
    { id: 'LODP', nombre: 'Ley Orgánica de la Defensa Pública', url: 'https://pandectasdigital.blogspot.com/p/ley-organica-de-la-defensa-publica.html' }
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

async function descargar() {
    console.clear();
    console.log(`\x1b[34m=== DESCARGA DIRECTA POR URL ===\x1b[0m\n`);

    for (const ley of LEYES) {
        process.stdout.write(`Descargando ${ley.id}... `);
        try {
            const res = await fetch(ley.url, { headers: { 'User-Agent': 'Mozilla/5.0' } });
            if (!res.ok) {
                console.log(`\x1b[31mError HTTP ${res.status}\x1b[0m`);
                continue;
            }

            const htmlPagina = await res.text();
            const htmlCuerpo = extraerCuerpoPost(htmlPagina);

            // Guardar HTML
            fs.writeFileSync(path.join(DIR_HTML, `${ley.id}.html`), htmlCuerpo, 'utf-8');

            // Parsear artículos
            const articulos = parsearArticulos(htmlCuerpo);

            // Guardar JSON estructurado
            const dataFinal = {
                id: ley.id,
                titulo: ley.nombre,
                url: ley.url,
                total_articulos: articulos.length,
                articulos: articulos
            };

            fs.writeFileSync(path.join(DIR_JSON, `${ley.id}.json`), JSON.stringify(dataFinal, null, 2), 'utf-8');

            console.log(`\x1b[32mOK\x1b[0m -> \x1b[1m${articulos.length} arts\x1b[0m`);
        } catch (err) {
            console.log(`\x1b[31m[Fallo] ${err.message}\x1b[0m`);
        }
        await new Promise(r => setTimeout(r, 250));
    }

    console.log(`\n\x1b[32m✔ Finalizado. Revisa '${DIR_HTML}' y '${DIR_JSON}'.\x1b[0m\n`);
}

descargar();
