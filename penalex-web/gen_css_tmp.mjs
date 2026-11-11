import { compile } from 'tailwindcss';
import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';
const require = createRequire(import.meta.url);
const TW_DIR = path.dirname(require.resolve('tailwindcss/package.json'));

function recolectarClases(dir, acum) {
  if (!fs.existsSync(dir)) return;
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) recolectarClases(p, acum);
    else if (/\.(tsx|ts)$/.test(e.name)) {
      const src = fs.readFileSync(p, 'utf8');
      const m = src.matchAll(/className=\{?["'`]([^"'`]+)["'`]?\}?/g);
      for (const x of m) for (const c of x[1].split(/\s+/)) acum.add(c);
    }
  }
}
const clases = new Set();
recolectarClases('src/app', clases);
recolectarClases('src/components', clases);
console.log('clases:', clases.size);

const input = fs.readFileSync('src/app/globals.css', 'utf8');
// tailwind pasa id ya como ruta absoluta o 'tailwindcss' — logueamos
const resultado = await compile(input, {
  base: process.cwd(),
  loadStylesheet: async (id, base) => {
    let ruta = id;
    if (!path.isAbsolute(ruta)) {
      if (ruta.startsWith('tailwindcss/')) ruta = path.join(TW_DIR, ruta.slice('tailwindcss/'.length));
      else if (ruta === 'tailwindcss') ruta = path.join(TW_DIR, 'index.css');
      else ruta = path.resolve(base ?? process.cwd(), ruta);
    }
    try { return await fs.promises.readFile(ruta, 'utf8'); }
    catch (e) { console.log('FALLO read:', ruta); return ''; }
  },
});
const out = resultado.build([...clases]);
console.log('css bytes:', out.length);
fs.writeFileSync('/tmp/tw_completo.css', out);
