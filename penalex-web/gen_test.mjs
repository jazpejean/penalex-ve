import { compile } from 'tailwindcss';
import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';
const require = createRequire(import.meta.url);
const TW_DIR = path.dirname(require.resolve('tailwindcss/package.json'));

// Test mínimo: solo @import tailwindcss
const resultado = await compile('@import "tailwindcss";', {
  base: process.cwd(),
  loadStylesheet: async (id, base) => {
    let ruta = id;
    if (!path.isAbsolute(ruta)) {
      if (ruta === 'tailwindcss' || ruta === 'tailwindcss/index.css') ruta = path.join(TW_DIR, 'index.css');
      else if (ruta.startsWith('tailwindcss/')) ruta = path.join(TW_DIR, ruta.slice('tailwindcss/'.length));
      else ruta = path.resolve(base ?? process.cwd(), ruta);
    }
    try { return await fs.promises.readFile(ruta, 'utf8'); }
    catch { return ''; }
  },
});
const out = resultado.build(['max-w-6xl','bg-white','sticky','rounded-md']);
console.log('test OK, bytes:', out.length);
console.log('contiene max-w-6xl:', out.includes('max-w-6xl'));
fs.writeFileSync('/tmp/tw_test.css', out);
