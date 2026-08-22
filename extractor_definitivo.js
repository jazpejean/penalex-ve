import fs from 'fs';
import path from 'path';

const BASE_URL = 'https://pandectasdigital.blogspot.com';
const DIR_HTML = './leyes_html_bruto';
const DIR_JSON = './leyes_estructuradas';

if (!fs.existsSync(DIR_HTML)) fs.mkdirSync(DIR_HTML, { recursive: true });
if (!fs.existsSync(DIR_JSON)) fs.mkdirSync(DIR_JSON, { recursive: true });

const CATALOGO = [
    { id: 'CRBV', nombre: 'Constitución de la República Bolivariana de Venezuela', tokens: ['constitucion', 'republica', 'bolivariana'] },
    { id: 'CP', nombre: 'Código Penal', tokens: ['codigo', 'penal'] },
    { id: 'COPP', nombre: 'Código Orgánico Procesal Penal', tokens: ['codigo', 'organico', 'procesal', 'penal'] },
    { id: 'COJM', nombre: 'Código Orgánico de Justicia Militar', tokens: ['justicia', 'militar'] },
    { id: 'COPEN', nombre: 'Código Orgánico Penitenciario', tokens: ['organico', 'penitenciario'] },
    { id: 'LOCDOFT', nombre: 'Ley Orgánica contra la Delincuencia Organizada y Financiamiento al Terrorismo', tokens: ['delincuencia', 'organizada'] },
    { id: 'LOD', nombre: 'Ley Orgánica de Drogas', tokens: ['organica', 'drogas'] },
    { id: 'LCSE', nombre: 'Ley contra el Secuestro y la Extorsión', tokens: ['secuestro', 'extorsion'] },
    { id: 'LCC', nombre: 'Ley contra la Corrupción', tokens: ['contra', 'corrupcion'] },
    { id: 'LOED', nombre: 'Ley Orgánica de Extinción de Dominio', tokens: ['extincion', 'dominio'] },
    { id: 'LCCO', nombre: 'Ley Constitucional contra el Odio', tokens: ['contra', 'odio'] },
    { id: 'LHRVA', nombre: 'Ley sobre el Hurto y Robo de Vehículos Automotores', tokens: ['hurto', 'robo', 'vehiculos'] },
    { id: 'LECDI', nombre: 'Ley Especial contra los Delitos Informáticos', tokens: ['delitos', 'informaticos'] },
    { id: 'LDCAM', nombre: 'Ley para el Desarme y Control de Armas y Municiones', tokens: ['desarme', 'armas'] },
    { id: 'LOSDMVLV', nombre: 'Ley Orgánica sobre el Derecho de las Mujeres a una Vida Libre de Violencia', tokens: ['mujeres', 'violencia'] },
    { id: 'LOPNNA', nombre: 'Ley Orgánica para la Protección de Niños, Niñas y Adolescentes', tokens: ['ninos', 'adolescentes'] },
    { id: 'LPVTSP', nombre: 'Ley para la Protección de Víctimas, Testigos y Demás Sujetos Procesales', tokens: ['proteccion', 'victimas', 'testigos'] },
    { id: 'LPST', nombre: 'Ley para Prevenir y Sancionar la Tortura', tokens: ['prevenir', 'sancionar', 'tortura'] },
    { id: 'LCTP', nombre: 'Ley contra la Trata de Personas', tokens: ['trata', 'personas'] },
    { id: 'LOCDR', nombre: 'Ley Orgánica contra la Discriminación Racial', tokens: ['discriminacion', 'racial'] },
    { id: 'LPA', nombre: 'Ley Penal del Ambiente', tokens: ['penal', 'ambiente'] },
    { id: 'LPPAG', nombre: 'Ley Penal de Protección a la Actividad Ganadera', tokens: ['actividad', 'ganadera'] },
    { id: 'LOI', nombre: 'Ley Orgánica de Identificación', tokens: ['organica', 'identificacion'] },
    { id: 'LEFPI', nombre: 'Ley del Estatuto de la Función de la Policía de Investigación', tokens: ['policia', 'investigacion'] },
    { id: 'LSDC', nombre: 'Ley sobre el Delito de Contrabando', tokens: ['delito', 'contrabando'] },
    { id: 'LOTSJ', nombre: 'Ley Orgánica del Tribunal Supremo de Justicia', tokens: ['tribunal', 'supremo', 'justicia'] },
    { id: 'LOPJ', nombre: 'Ley Orgánica del Poder Judicial', tokens: ['organica', 'poder', 'judicial'] },
    { id: 'LOMP', nombre: 'Ley Orgánica del Ministerio Público', tokens: ['organica', 'ministerio', 'publico'] },
    { id: 'LODP', nombre: 'Ley Orgánica de la Defensa Pública', tokens: ['organica', 'defensa', 'publica'] }
];

function normalizar(t) {
    return (t || '')
        .toLowerCase()
        .normalize('NFD')
        .replace(/[\u0300-\u036f]/g, '')
        .replace(/[^a-z0-9\s]/g, ' ')
        .replace(/\s+/g, ' ')
        .trim();
}

function parsearArticulos(html) {
    const texto = html
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

async function descargarTodoElFeed(tipo) {
    let startIndex = 1;
    let acumulados = [];
    const maxPorLote = 150;

    console.log(`\x1b[36m📥 Descargando histórico completo de /${tipo}...\x1b[0m`);

    while (true) {
        const url = `${BASE_URL}/feeds/${tipo}/default?alt=json&start-index=${startIndex}&max-results=${maxPorLote}`;
        let res;
        try {
            res = await fetch(url);
        } catch {
            await new Promise(r => setTimeout(r, 1000));
            continue;
        }

        if (!res.ok) break;
        const data = await res.json();
        const entries = data.feed?.entry || [];
        const totalDisponibles = parseInt(data.feed?.openSearch$totalResults?.$t || '0', 10);

        if (entries.length === 0) break;
        acumulados = acumulados.concat(entries);

        console.log(`   → Progreso: ${acumulados.length} / ${totalDisponibles || '?'}`);

        if (acumulados.length >= totalDisponibles || entries.length < maxPorLote) break;
        startIndex += maxPorLote;
        await new Promise(r => setTimeout(r, 200));
    }

    return acumulados;
}

async function ejecutar() {
    console.clear();
    console.log(`\x1b[34m====================================================\x1b[0m`);
    console.log(`\x1b[34m   EXTRACTOR DEFINITIVO: RASTREO EXHAUSTIVO         \x1b[0m`);
    console.log(`\x1b[34m====================================================\x1b[0m\n`);

    const posts = await descargarTodoElFeed('posts');
    const pages = await descargarTodoElFeed('pages');
    const universo = [...posts, ...pages];

    console.log(`\n\x1b[32m✔ Total de entradas indexadas: ${universo.length}\x1b[0m\n`);

    for (const item of CATALOGO) {
        console.log(`\x1b[36m🔍 Analizando:\x1b[0m ${item.nombre}...`);

        // Filtro por coincidencia de tokens
        const coincidencias = universo.filter(doc => {
            const tituloNorm = normalizar(doc.title?.$t || '');
            const linkNorm = normalizar(doc.link?.find(l => l.rel === 'alternate')?.href || '');
            const textoTotal = `${tituloNorm} ${linkNorm}`;
            return item.tokens.every(token => textoTotal.includes(normalizar(token)));
        });

        if (coincidencias.length === 0) {
            console.log(`   \x1b[33m[!] No encontrada en el corpus descargado.\x1b[0m`);
            continue;
        }

        // Ordenar por longitud de contenido descendente para tomar el texto íntegro
        coincidencias.sort((a, b) => {
            const lenA = (a.content?.$t || a.summary?.$t || '').length;
            const lenB = (b.content?.$t || b.summary?.$t || '').length;
            return lenB - lenA;
        });

        const docElegido = coincidencias[0];
        const html = docElegido.content?.$t || docElegido.summary?.$t || '';
        const articulos = parsearArticulos(html);

        // Guardar archivo HTML en bruto
        fs.writeFileSync(path.join(DIR_HTML, `${item.id}.html`), html, 'utf-8');

        // Guardar estructura en JSON
        const jsonFinal = {
            id_norma: item.id,
            titulo: docElegido.title?.$t?.trim() || item.nombre,
            total_articulos: articulos.length,
            articulos: articulos,
            url_origen: docElegido.link?.find(l => l.rel === 'alternate')?.href || ''
        };

        fs.writeFileSync(path.join(DIR_JSON, `${item.id}.json`), JSON.stringify(jsonFinal, null, 2), 'utf-8');

        const pesoKb = (Buffer.byteLength(html, 'utf-8') / 1024).toFixed(1);
        console.log(`   \x1b[32m✔ Guardado:\x1b[0m ${item.id} | Peso: ${pesoKb} KB | Artículos: \x1b[1m\x1b[33m${articulos.length}\x1b[0m`);
    }

    console.log(`\n\x1b[32m✔ EXTRACCIÓN Y PARSEO FINALIZADOS CON ÉXITO.\x1b[0m\n`);
}

ejecutar();
