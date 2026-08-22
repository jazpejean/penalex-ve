import fs from 'fs';
import path from 'path';

const BASE_URL = 'https://pandectasdigital.blogspot.com';
const OUTPUT_DIR = './leyes_penales_vigentes';
const JSON_CONSOLIDADO = './corpus_penal_vigente.json';

if (!fs.existsSync(OUTPUT_DIR)) {
    fs.mkdirSync(OUTPUT_DIR, { recursive: true });
}

// Catálogo normativo penal vigente a rastrear
const CATALOGO_OBJETIVO = [
    { clave: 'Constitucion', query: 'Constitución de la República Bolivariana de Venezuela', id: 'CRBV' },
    { clave: 'Codigo Penal', query: 'Código Penal', id: 'CP' },
    { clave: 'Codigo Organico Procesal Penal', query: 'Código Orgánico Procesal Penal', id: 'COPP' },
    { clave: 'Codigo Organico de Justicia Militar', query: 'Código Orgánico de Justicia Militar', id: 'COJM' },
    { clave: 'Codigo Organico Penitenciario', query: 'Código Orgánico Penitenciario', id: 'COPEN' },
    { clave: 'Delincuencia Organizada', query: 'Ley Orgánica contra la Delincuencia Organizada y Financiamiento al Terrorismo', id: 'LOCDOFT' },
    { clave: 'Drogas', query: 'Ley Orgánica de Drogas', id: 'LOD' },
    { clave: 'Secuestro y la Extorsion', query: 'Ley contra el Secuestro y la Extorsión', id: 'LCSE' },
    { clave: 'Corrupcion', query: 'Ley contra la Corrupción', id: 'LCC' },
    { clave: 'Extincion de Dominio', query: 'Ley Orgánica de Extinción de Dominio', id: 'LOED' },
    { clave: 'contra el Odio', query: 'Ley Constitucional contra el Odio', id: 'LCCO' },
    { clave: 'Hurto y Robo de Vehiculos', query: 'Ley sobre el Hurto y Robo de Vehículos Automotores', id: 'LHRVA' },
    { clave: 'Delitos Informaticos', query: 'Ley Especial contra los Delitos Informáticos', id: 'LECDI' },
    { clave: 'Desarme y Control de Armas', query: 'Ley para el Desarme y Control de Armas y Municiones', id: 'LDCAM' },
    { clave: 'Mujeres a una Vida Libre de Violencia', query: 'Ley Orgánica sobre el Derecho de las Mujeres a una Vida Libre de Violencia', id: 'LOSDMVLV' },
    { clave: 'Proteccion de Ninos, Ninas y Adolescentes', query: 'Ley Orgánica para la Protección de Niños, Niñas y Adolescentes', id: 'LOPNNA' },
    { clave: 'Proteccion de Victimas, Testigos', query: 'Ley para la Protección de Víctimas, Testigos y Demás Sujetos Procesales', id: 'LPVTSP' },
    { clave: 'Prevenir y Sancionar la Tortura', query: 'Ley para Prevenir y Sancionar la Tortura', id: 'LPST' },
    { clave: 'Trata de Personas', query: 'Ley contra la Trata de Personas', id: 'LCTP' },
    { clave: 'Discriminacion Racial', query: 'Ley Orgánica contra la Discriminación Racial', id: 'LOCDR' },
    { clave: 'Penal del Ambiente', query: 'Ley Penal del Ambiente', id: 'LPA' },
    { clave: 'Precios Justos', query: 'Ley Orgánica de Precios Justos', id: 'LOPJ_SANCIONES' },
    { clave: 'Actividad Ganadera', query: 'Ley Penal de Protección a la Actividad Ganadera', id: 'LPPAG' },
    { clave: 'Identificacion', query: 'Ley Orgánica de Identificación', id: 'LOI' },
    { clave: 'Policia de Investigacion', query: 'Ley del Estatuto de la Función de la Policía de Investigación', id: 'LEFPI' },
    { clave: 'Contrabando', query: 'Ley sobre el Delito de Contrabando', id: 'LSDC' },
    // Leyes Orgánicas Institucionales
    { clave: 'Tribunal Supremo de Justicia', query: 'Ley Orgánica del Tribunal Supremo de Justicia', id: 'LOTSJ' },
    { clave: 'Poder Judicial', query: 'Ley Orgánica del Poder Judicial', id: 'LOPJ' },
    { clave: 'Ministerio Publico', query: 'Ley Orgánica del Ministerio Público', id: 'LOMP' },
    { clave: 'Defensa Publica', query: 'Ley Orgánica de la Defensa Pública', id: 'LODP' }
];

function normalizar(txt) {
    return (txt || '')
        .toLowerCase()
        .normalize('NFD')
        .replace(/[\u0300-\u036f]/g, '')
        .replace(/[^a-z0-9\s]/g, ' ')
        .replace(/\s+/g, ' ')
        .trim();
}

function extraerGaceta(html) {
    const match = html.match(/Gaceta\s+Oficial\s*(?:N[°ºo\.]*|\#)?\s*([0-9\.]+(?:\s*Extraordinario)?)/i);
    return match ? match[1].trim() : "No especificada";
}

function segmentarArticulos(htmlBruto) {
    const texto = htmlBruto
        .replace(/<\/(p|div|tr|li|h[1-6])>/gi, '\n')
        .replace(/<br\s*[\/]?>/gi, '\n')
        .replace(/<[^>]+>/g, ' ')
        .replace(/&nbsp;/g, ' ')
        .replace(/&quot;/g, '"')
        .replace(/&amp;/g, '&');

    const lineas = texto.split('\n').map(l => l.trim()).filter(Boolean);
    const articulos = [];
    let actual = null;

    const regexArt = /^(?:Art[ií]culo\s+|Art\.\s*)([0-9]+[A-Za-z\-°º]*)\s*[\.\-\:\–\—]?(.*)$/i;

    for (const linea of lineas) {
        const m = linea.match(regexArt);
        if (m) {
            if (actual) articulos.push(actual);
            actual = {
                numero: m[1].replace(/[^0-9A-Za-z]/g, ''),
                epigrafe: m[2].trim(),
                contenido: ""
            };
        } else if (actual) {
            actual.contenido += (actual.contenido ? " " : "") + linea;
        }
    }
    if (actual) articulos.push(actual);
    return articulos;
}

async function buscarEnFeed(queryTexto) {
    const url = `${BASE_URL}/feeds/posts/default?q=${encodeURIComponent(queryTexto)}&alt=json&max-results=5`;
    try {
        const res = await fetch(url);
        if (!res.ok) return [];
        const data = await res.json();
        return data.feed?.entry || [];
    } catch {
        return [];
    }
}

async function ejecutar() {
    console.clear();
    console.log(`\x1b[34m====================================================\x1b[0m`);
    console.log(`\x1b[34m   EXTRACTOR SELECTIVO DE LEYES PENALES VIGENTES    \x1b[0m`);
    console.log(`\x1b[34m====================================================\x1b[0m\n`);

    const leyesProcesadas = [];

    for (const item of CATALOGO_OBJETIVO) {
        console.log(`\x1b[36m🔍 Localizando:\x1b[0m ${item.query}...`);
        const entradas = await buscarEnFeed(item.query);

        if (entradas.length === 0) {
            console.log(`   \x1b[33m[!] Sin coincidencia directa para: ${item.id}\x1b[0m`);
            continue;
        }

        // Se selecciona la primera entrada (la más reciente/actualizada devuelta por el feed)
        const entrada = entradas[0];
        const titulo = entrada.title?.$t?.trim() || item.query;
        const htmlBruto = entrada.content?.$t || entrada.summary?.$t || '';
        const gaceta = extraerGaceta(htmlBruto);
        const articulos = segmentarArticulos(htmlBruto);
        const urlOrigen = entrada.link?.find(l => l.rel === 'alternate')?.href || '';

        const docFinal = {
            id_norma: item.id,
            titulo: titulo,
            gaceta_oficial: gaceta,
            fecha_publicacion: entrada.published?.$t?.split('T')[0] || '',
            total_articulos: articulos.length,
            articulos: articulos,
            fuente: urlOrigen
        };

        const archivoSalida = path.join(OUTPUT_DIR, `${item.id}.json`);
        fs.writeFileSync(archivoSalida, JSON.stringify(docFinal, null, 2), 'utf-8');
        leyesProcesadas.push(docFinal);

        console.log(`   \x1b[32m✔ Guardado:\x1b[0m ${item.id} (${articulos.length} artículos segmentados)`);
        await new Promise(r => setTimeout(r, 300));
    }

    fs.writeFileSync(JSON_CONSOLIDADO, JSON.stringify(leyesProcesadas, null, 2), 'utf-8');

    console.log(`\n\x1b[32m====================================================\x1b[0m`);
    console.log(`\x1b[32m✔ EXTRACCIÓN Y SEGMENTACIÓN COMPLETADA\x1b[0m`);
    console.log(`📁 Directorio individual: ${OUTPUT_DIR}/`);
    console.log(`📄 Corpus consolidado: ${JSON_CONSOLIDADO}`);
    console.log(`📊 Leyes vigentes procesadas: ${leyesProcesadas.length}/${CATALOGO_OBJETIVO.length}`);
    console.log(`\x1b[32m====================================================\x1b[0m\n`);
}

ejecutar();
