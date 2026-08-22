import fs from 'fs';
import path from 'path';

const BASE_URL = 'https://pandectasdigital.blogspot.com';
const DIR_HTML = './leyes_html_bruto';
const DIR_JSON = './leyes_estructuradas';

if (!fs.existsSync(DIR_HTML)) fs.mkdirSync(DIR_HTML, { recursive: true });
if (!fs.existsSync(DIR_JSON)) fs.mkdirSync(DIR_JSON, { recursive: true });

const CATALOGO = [
    { query: 'Constitución de la República Bolivariana de Venezuela', id: 'CRBV' },
    { query: 'Código Penal', id: 'CP' },
    { query: 'Código Orgánico Procesal Penal', id: 'COPP' },
    { query: 'Código Orgánico de Justicia Militar', id: 'COJM' },
    { query: 'Código Orgánico Penitenciario', id: 'COPEN' },
    { query: 'Ley Orgánica contra la Delincuencia Organizada y Financiamiento al Terrorismo', id: 'LOCDOFT' },
    { query: 'Ley Orgánica de Drogas', id: 'LOD' },
    { query: 'Ley contra el Secuestro y la Extorsión', id: 'LCSE' },
    { query: 'Ley contra la Corrupción', id: 'LCC' },
    { query: 'Ley Orgánica de Extinción de Dominio', id: 'LOED' },
    { query: 'Ley Constitucional contra el Odio', id: 'LCCO' },
    { query: 'Ley sobre el Hurto y Robo de Vehículos Automotores', id: 'LHRVA' },
    { query: 'Ley Especial contra los Delitos Informáticos', id: 'LECDI' },
    { query: 'Ley para el Desarme y Control de Armas y Municiones', id: 'LDCAM' },
    { query: 'Ley Orgánica sobre el Derecho de las Mujeres a una Vida Libre de Violencia', id: 'LOSDMVLV' },
    { query: 'Ley Orgánica para la Protección de Niños, Niñas y Adolescentes', id: 'LOPNNA' },
    { query: 'Ley para la Protección de Víctimas, Testigos y Demás Sujetos Procesales', id: 'LPVTSP' },
    { query: 'Ley para Prevenir y Sancionar la Tortura', id: 'LPST' },
    { query: 'Ley contra la Trata de Personas', id: 'LCTP' },
    { query: 'Ley Orgánica contra la Discriminación Racial', id: 'LOCDR' },
    { query: 'Ley Penal del Ambiente', id: 'LPA' },
    { query: 'Ley Penal de Protección a la Actividad Ganadera', id: 'LPPAG' },
    { query: 'Ley Orgánica de Identificación', id: 'LOI' },
    { query: 'Ley del Estatuto de la Función de la Policía de Investigación', id: 'LEFPI' },
    { query: 'Ley sobre el Delito de Contrabando', id: 'LSDC' },
    { query: 'Ley Orgánica del Tribunal Supremo de Justicia', id: 'LOTSJ' },
    { query: 'Ley Orgánica del Poder Judicial', id: 'LOPJ' },
    { query: 'Ley Orgánica del Ministerio Público', id: 'LOMP' },
    { query: 'Ley Orgánica de la Defensa Pública', id: 'LODP' }
];

function extraerGaceta(html) {
    const match = html.match(/Gaceta\s+Oficial\s*(?:N[°ºo\.]*|\#)?\s*([0-9\.]+(?:\s*Extraordinario)?)/i);
    return match ? match[1].trim() : "No especificada";
}

// Extrae los artículos respetando la estructura real del HTML de Pandectas
function parsearArticulosDesdeHtml(html) {
    // Normalizar etiquetas a saltos de línea sin destruir el texto
    let texto = html
        .replace(/<\/(p|div|tr|td|li|h[1-6]|table|blockquote)>/gi, '\n')
        .replace(/<br\s*[\/]?>/gi, '\n')
        .replace(/<[^>]+>/g, ' ')
        .replace(/&nbsp;/g, ' ')
        .replace(/&quot;/g, '"')
        .replace(/&amp;/g, '&');

    const lineas = texto.split('\n').map(l => l.trim()).filter(Boolean);
    const articulos = [];
    let artActual = null;

    // Patrón flexible para artículos en Pandectas: "Artículo 1", "Art. 1°", "Artículo 110 bis"
    const regexArt = /^(?:Art[ií]culo\s+|Art\.\s*)([0-9]+(?:\s*(?:bis|ter|quater|[A-Za-z\-°º]))*)\s*[\.\-\:\–\—]?(.*)$/i;

    for (const linea of lineas) {
        const match = linea.match(regexArt);
        if (match) {
            if (artActual) articulos.push(artActual);
            artActual = {
                numero: match[1].replace(/[^0-9A-Za-z]/g, '').trim(),
                epigrafe: match[2].trim(),
                contenido: ""
            };
        } else if (artActual) {
            artActual.contenido += (artActual.contenido ? " " : "") + linea;
        }
    }
    if (artActual) articulos.push(artActual);
    return articulos;
}

async function buscarPostCompleto(query) {
    // max-results=1 y sin truncamiento para obtener el body original
    const url = `${BASE_URL}/feeds/posts/default?q=${encodeURIComponent(query)}&alt=json&max-results=3`;
    const res = await fetch(url);
    if (!res.ok) return null;
    const data = await res.json();
    const entradas = data.feed?.entry;
    if (!entradas || entradas.length === 0) return null;

    // Tomamos la entrada con mayor longitud de HTML para asegurar el texto completo
    entradas.sort((a, b) => {
        const lenA = (a.content?.$t || a.summary?.$t || '').length;
        const lenB = (b.content?.$t || b.summary?.$t || '').length;
        return lenB - lenA;
    });

    return entradas[0];
}

async function ejecutar() {
    console.clear();
    console.log(`\x1b[34m====================================================\x1b[0m`);
    console.log(`\x1b[34m   EXTRACTOR DE LEYES COMPLETAS (HTML REAL)         \x1b[0m`);
    console.log(`\x1b[34m====================================================\x1b[0m\n`);

    for (const item of CATALOGO) {
        console.log(`\x1b[36m🔍 Descargando:\x1b[0m ${item.query}...`);
        try {
            const entrada = await buscarPostCompleto(item.query);
            if (!entrada) {
                console.log(`   \x1b[33m[!] No encontrada en el feed.\x1b[0m`);
                continue;
            }

            const htmlCompleto = entrada.content?.$t || entrada.summary?.$t || '';
            const titulo = entrada.title?.$t?.trim() || item.query;
            const gaceta = extraerGaceta(htmlCompleto);

            // 1. Guardar el HTML en bruto tal cual está en el blog para verificación directa
            const rutaHtml = path.join(DIR_HTML, `${item.id}.html`);
            fs.writeFileSync(rutaHtml, htmlCompleto, 'utf-8');

            // 2. Parsear el articulado completo
            const articulos = parsearArticulosDesdeHtml(htmlCompleto);

            // 3. Guardar el JSON estructurado
            const jsonFinal = {
                id_norma: item.id,
                titulo: titulo,
                gaceta: gaceta,
                fecha_publicacion: entrada.published?.$t?.split('T')[0] || '',
                total_articulos: articulos.length,
                articulos: articulos,
                url_web: entrada.link?.find(l => l.rel === 'alternate')?.href || ''
            };

            const rutaJson = path.join(DIR_JSON, `${item.id}.json`);
            fs.writeFileSync(rutaJson, JSON.stringify(jsonFinal, null, 2), 'utf-8');

            const tamanoKb = (Buffer.byteLength(htmlCompleto, 'utf-8') / 1024).toFixed(1);
            console.log(`   \x1b[32m✔ Guardado:\x1b[0m ${item.id} | HTML: ${tamanoKb} KB | Artículos: \x1b[1m${articulos.length}\x1b[0m`);

        } catch (e) {
            console.log(`   \x1b[31m[ERROR]\x1b[0m ${e.message}`);
        }

        await new Promise(r => setTimeout(r, 400));
    }

    console.log(`\n\x1b[32m✔ PROCESO FINALIZADO.\x1b[0m`);
    console.log(`📁 HTMLs originales: ${DIR_HTML}/`);
    console.log(`📁 JSONs estructurados: ${DIR_JSON}/\n`);
}

ejecutar();
