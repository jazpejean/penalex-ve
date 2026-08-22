import fs from 'fs';

const BASE_URL = 'https://pandectasdigital.blogspot.com';
const ARCHIVO_SALIDA = './mapa_urls.json';

async function obtenerIndiceTipo(tipo) {
    let startIndex = 1;
    let lista = [];
    const maxPorLote = 100;

    console.log(`\x1b[36m📥 Extrayendo histórico completo de ${tipo}...\x1b[0m`);

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
        const total = parseInt(data.feed?.openSearch$totalResults?.$t || '0', 10);

        if (entries.length === 0) break;

        for (const e of entries) {
            const enlace = e.link?.find(l => l.rel === 'alternate')?.href || '';
            const slug = enlace ? enlace.split('/').pop().replace('.html', '') : '';
            lista.push({
                tipo,
                titulo: e.title?.$t?.trim() || '',
                slug: slug,
                url: enlace
            });
        }

        console.log(`   → ${lista.length} / ${total || '?'}`);

        if (lista.length >= total) break;
        startIndex += entries.length; // Avanzar exactamente por las entradas recibidas
        await new Promise(r => setTimeout(r, 100));
    }

    return lista;
}

async function ejecutar() {
    console.clear();
    console.log(`\x1b[34m=== GENERADOR DE MAPA DE URLs COMPLETO ===\x1b[0m\n`);

    // Las páginas estáticas contienen los Códigos principales
    const pages = await obtenerIndiceTipo('pages');
    // Los posts contienen las leyes orgánicas y reformas
    const posts = await obtenerIndiceTipo('posts');
    
    const total = [...pages, ...posts];

    fs.writeFileSync(ARCHIVO_SALIDA, JSON.stringify(total, null, 2), 'utf-8');

    console.log(`\n\x1b[32m✔ Mapa generado con éxito en: ${ARCHIVO_SALIDA}\x1b[0m`);
    console.log(`📊 Total de URLs indexadas: ${total.length}\n`);
}

ejecutar();
