import fs from 'fs';

const MAPA_FILE = './mapa_urls.json';
const OUTPUT_FILE = './leyes_penales_seleccionadas.json';

if (!fs.existsSync(MAPA_FILE)) {
    console.log(`\x1b[31m[!] No se encuentra ${MAPA_FILE}.\x1b[0m`);
    process.exit(1);
}

const mapa = JSON.parse(fs.readFileSync(MAPA_FILE, 'utf-8'));

function normalizar(txt) {
    return (txt || '').toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '').trim();
}

const REGLAS = [
    { id: 'CRBV', cat: 'Marco Constitucional', terms: ['constitucion de la republica bolivariana de venezuela'], not: ['ficha', 'aragua', 'carabobo', 'anzoategui', 'monagas', 'apure'] },
    { id: 'CP', cat: 'Código Sustantivo', terms: ['codigo penal'], not: ['militar', 'procesal', 'ficha', 'proyecto'] },
    { id: 'COPP', cat: 'Código Procesal', terms: ['codigo organico procesal penal'], not: ['ficha'] },
    { id: 'COJM', cat: 'Justicia Militar', terms: ['codigo organico de justicia militar'], not: ['ficha'] },
    { id: 'COPEN', cat: 'Penitenciario', terms: ['codigo organico penitenciario'], not: ['ficha'] },
    { id: 'LOCDOFT', cat: 'Delincuencia Organizada', terms: ['ley organica contra la delincuencia organizada', 'delincuencia organizada y financiamiento'], not: ['ficha', 'normativa', 'registro', 'convencion'] },
    { id: 'LOD', cat: 'Drogas', terms: ['ley organica de drogas'], not: ['ficha', 'reconocimiento', 'boton'] },
    { id: 'LCSE', cat: 'Secuestro y Extorsión', terms: ['contra el secuestro y la extorsion', 'secuestro y la extorsion'], not: ['ficha'] },
    { id: 'LCC', cat: 'Corrupción', terms: ['ley contra la corrupcion'], not: ['ficha', 'convencion'] },
    { id: 'LOED', cat: 'Extinción de Dominio', terms: ['ley organica de extincion de dominio'], not: ['ficha'] },
    { id: 'LCCO', cat: 'Odio', terms: ['contra el odio, por la convivencia', 'contra el odio'], not: ['ficha'] },
    { id: 'LHRVA', cat: 'Vehículos', terms: ['hurto y robo de vehiculos'], not: ['ficha'] },
    { id: 'LECDI', cat: 'Delitos Informáticos', terms: ['delitos informaticos'], not: ['ficha', 'proveedores', 'sistemas'] },
    { id: 'LDCAM', cat: 'Armas y Desarme', terms: ['ley para el desarme y control de armas'], not: ['ficha', 'reglamento', 'convencion'] },
    { id: 'LOSDMVLV', cat: 'Violencia de Género', terms: ['mujeres a una vida libre de violencia'], not: ['ficha', 'normas', 'reglamento'] },
    { id: 'LOPNNA', cat: 'Responsabilidad Penal Adolescentes', terms: ['proteccion de ninos, ninas y adolescentes', 'lopnna'], not: ['ficha', 'lineamientos', 'ordenanza', 'carabobo', 'sistema'] },
    { id: 'LPVTSP', cat: 'Protección Sujetos Procesales', terms: ['proteccion de victimas, testigos', 'proteccion de victimas y testigos'], not: ['ficha'] },
    { id: 'LPST', cat: 'Derechos Humanos / Tortura', terms: ['sancionar la tortura', 'prevenir y sancionar la tortura'], not: ['ficha', 'convencion'] },
    { id: 'LCTP', cat: 'Trata de Personas', terms: ['trata de personas'], not: ['ficha'] },
    { id: 'LOCDR', cat: 'Discriminación Racial', terms: ['discriminacion racial'], not: ['ficha', 'mecanismos', 'comites'] },
    { id: 'LPA', cat: 'Penal Ambiental', terms: ['ley penal del ambiente'], not: ['ficha'] },
    { id: 'LPPAG', cat: 'Actividad Ganadera', terms: ['actividad ganadera'], not: ['ficha'] },
    { id: 'LOI', cat: 'Identificación', terms: ['ley organica de identificacion'], not: ['ficha', 'reglamento'] },
    { id: 'LEFPI', cat: 'Policía de Investigación', terms: ['estatuto de la funcion de la policia de investigacion'], not: ['ficha', 'capitulos', 'reforma parcial', 'normas'] },
    { id: 'LSDC', cat: 'Contrabando', terms: ['delito de contrabando'], not: ['ficha'] },
    { id: 'LOTSJ', cat: 'Poder Judicial (TSJ)', terms: ['ley organica del tribunal supremo de justicia'], not: ['ficha', 'reformada'] },
    { id: 'LOPJ', cat: 'Poder Judicial', terms: ['ley organica del poder judicial'], not: ['ficha', 'distincion', 'reconocimiento'] },
    { id: 'LOMP', cat: 'Ministerio Público', terms: ['ley organica del ministerio publico'], not: ['ficha', 'reglamento', 'jubilaciones'] },
    { id: 'LODP', cat: 'Defensa Pública', terms: ['ley organica de la defensa publica'], not: ['ficha', 'reglamento', 'concurso', 'instructivo'] }
];

const resultado = [];

for (const r of REGLAS) {
    const candidatas = mapa.filter(item => {
        const tit = normalizar(item.titulo);
        const slug = normalizar(item.slug);
        const texto = `${tit} ${slug}`;

        if (tit.includes('derogada') || tit.includes('derogado')) return false;
        if (r.not.some(n => texto.includes(normalizar(n)))) return false;
        return r.terms.some(t => texto.includes(normalizar(t)));
    });

    if (candidatas.length > 0) {
        // Priorizar versiones con [Vigente] o la entrada más completa
        candidatas.sort((a, b) => {
            const aV = a.titulo.includes('[Vigente]') ? 1 : 0;
            const bV = b.titulo.includes('[Vigente]') ? 1 : 0;
            return bV - aV;
        });

        resultado.push({
            id: r.id,
            categoria: r.cat,
            titulo: candidatas[0].titulo,
            slug: candidatas[0].slug,
            url: candidatas[0].url
        });
    } else {
        resultado.push({
            id: r.id,
            categoria: r.cat,
            titulo: r.id,
            slug: 'no-encontrada',
            url: 'PENDIENTE'
        });
    }
}

fs.writeFileSync(OUTPUT_FILE, JSON.stringify(resultado, null, 2), 'utf-8');

console.clear();
console.log(`\x1b[32m✔ Clasificación completada con éxito.\x1b[0m`);
console.log(`📄 Archivo: ${OUTPUT_FILE}`);
console.log(`📊 Leyes listas: ${resultado.filter(x => x.url !== 'PENDIENTE').length}/${REGLAS.length}\n`);
console.table(resultado.map(r => ({ ID: r.id, Categoria: r.categoria, Titulo: r.titulo.slice(0, 48), Estado: r.url === 'PENDIENTE' ? '❌' : '✔ OK' })));
