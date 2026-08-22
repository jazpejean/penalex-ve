import fs from 'fs';
import path from 'path';

const BASE_URL = 'https://pandectasdigital.blogspot.com';
const OUTPUT_DIR = './leyes_penales_2000';
const JSON_CONSOLIDADO = './corpus_penal_venezuela.json';
const MAX_RESULTS = 150;
const FECHA_MINIMA = new Date('2000-01-01T00:00:00Z');

if (!fs.existsSync(OUTPUT_DIR)) {
    fs.mkdirSync(OUTPUT_DIR, { recursive: true });
}

// Diccionario de términos penales clave
const PALABRAS_CLAVE_PENAL = [
    'penal', 'delito', 'crimen', 'pena', 'imputad', 'acusad', 'sancion',
    'procesal penal', 'copp', 'drogas', 'estupefacient', 'corrupcion',
    'extorsion', 'secuestro', 'terrorismo', 'armas', 'violencia de genero',
    'delincuencia organizada', 'responsabilidad penal', 'presidio', 'prision'
];

function esMateriaPenal(titulo, contenido, categorias) {
    const textoCompleto = `${titulo} ${categorias.join(' ')} ${contenido.slice(0, 1500)}`.toLowerCase();
    return PALABRAS_CLAVE_PENAL.some(clave => textoCompleto.includes(clave));
}

function limpiarTexto(str) {
    return (str || '')
        .replace(/<[^>]+>/g, ' ') // Eliminar tags HTML
        .replace(/&nbsp;/g, ' ')
        .replace(/&quot;/g, '"')
        .replace(/&amp;/g, '&')
        .replace(/\s+/g, ' ')
        .trim();
}

function extraerGaceta(html) {
    const match = html.match(/Gaceta\s+Oficial\s+(?:N[°ºo\.]*|\#)?\s*([0-9\.]+(?:\s*Extraordinario)?)/i);
    return match ? match[1].trim() : "No especificada";
}

// Parsea el texto plano y segmenta artículo por artículo
function segmentarArticulos(htmlBruto) {
    // Normalizar saltos de línea donde hay etiquetas de bloque
    const textoNormalizado = htmlBruto
        .replace(/<\/(p|div|tr|li|h[1-6])>/gi, '\n')
        .replace(/<br\s*[\/]?>/gi, '\n')
        .replace(/<[^>]+>/g, '')
        .replace(/&nbsp;/g, ' ');

    const lineas = textoNormalizado.split('\n').map(l => l.trim()).filter(Boolean);
    const articulos = [];
    let articuloActual = null;

    const regexArticulo = /^(?:Art[ií]culo\s+|Art\.\s*)([0-9]+[A-Za-z\-°º]*)\s*[\.\-\:\–\—]?(.*)$/i;

    for (const linea of lineas) {
        const match = linea.match(regexArticulo);
        if (match) {
            if (articuloActual) {
                articulos.push(articuloActual);
            }
            articuloActual = {
                numero: match[1].replace(/[^0-9A-Za-z]/g, ''),
                epigrafe: match[2].trim(),
                contenido: ""
            };
        } else if (articuloActual) {
            articuloActual.contenido += (articuloActual.contenido ? " " : "") + linea;
        }
    }

    if (articuloActual) {
        articulos.push(articuloActual);
    }

    return articulos;
}

function sanitizarArchivo(nombre) {
    return nombre
        .toLowerCase()
        .replace(/[/\\?%*:|"<>]/g, '_')
        .replace(/\s+/g, '_')
        .replace(/_+/g, '_')
        .slice(0, 80);
}

async function procesarColeccion(tipoFeed) {
    let startIndex = 1;
    let resultados = [];

    console.log(`\x1b[36m🔍 Analizando ${tipoFeed} en Pandectas Digital...\x1b[0m`);

    while (true) {
        const url = `${BASE_URL}/feeds/${tipoFeed}/default?alt=json&start-index=${startIndex}&max-results=${MAX_RESULTS}`;
        const res = await fetch(url);
        if (!res.ok) break;

        const data = await res.json();
        const entradas = data.feed.entry;
        if (!entradas || entradas.length === 0) break;

        for (const item of entradas) {
            const fechaStr = item.published?.$t || item.updated?.$t;
            const fecha = new Date(fechaStr);

            // Filtrar por año >= 2000
            if (fecha < FECHA_MINIMA) continue;

            const titulo = limpiarTexto(item.title?.$t);
            const htmlBruto = item.content?.$t || item.summary?.$t || '';
            const categorias = item.category ? item.category.map(c => c.term) : [];

            if (esMateriaPenal(titulo, htmlBruto, categorias)) {
                const gaceta = extraerGaceta(htmlBruto);
                const articulos = segmentarArticulos(htmlBruto);

                resultados.push({
                    titulo,
                    gaceta,
                    fecha: fechaStr.split('T')[0],
                    categorias,
                    total_articulos: articulos.length,
                    articulos: articulos,
                    url_origen: item.link?.find(l => l.rel === 'alternate')?.href || ''
                });
            }
        }

        console.log(`   → ${resultados.length} leyes penales acumuladas (lote ${startIndex})...`);
        if (entradas.length < MAX_RESULTS) break;
        startIndex += MAX_RESULTS;
        await new Promise(r => setTimeout(r, 400));
    }

    return resultados;
}

async function ejecutar() {
    console.clear();
    console.log(`\x1b[34m====================================================\x1b[0m`);
    console.log(`\x1b[34m  EXTRACTOR PENAL ESTRUCTURADO (2000 - Presente)    \x1b[0m`);
    console.log(`\x1b[34m====================================================\x1b[0m\n`);

    const leyesPosts = await procesarColeccion('posts');
    const leyesPages = await procesarColeccion('pages');

    const corpus = [...leyesPosts, ...leyesPages];

    console.log(`\n\x1b[32m💾 Generando archivos individuales y corpus consolidado...\x1b[0m`);

    corpus.forEach((ley, idx) => {
        const nombreArchivo = `${String(idx + 1).padStart(3, '0')}_${sanitizarArchivo(ley.titulo)}.json`;
        fs.writeFileSync(path.join(OUTPUT_DIR, nombreArchivo), JSON.stringify(ley, null, 2), 'utf-8');
    });

    fs.writeFileSync(JSON_CONSOLIDADO, JSON.stringify(corpus, null, 2), 'utf-8');

    console.log(`\n\x1b[32m✔ EXTRACCIÓN Y PARSEO PENAL FINALIZADO\x1b[0m`);
    console.log(`📁 Directorio individual: ${OUTPUT_DIR}/`);
    console.log(`📄 Archivo consolidado: ${JSON_CONSOLIDADO}`);
    console.log(`📊 Leyes penales estructuradas: ${corpus.length}\n`);
}

ejecutar();
