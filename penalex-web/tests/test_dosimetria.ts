// Test de paridad del motor de dosimetría (web vs APK Dart).
import { calcularConcursoDetallado, convertToYMD, formatYMD } from "../src/lib/dosimetria.ts";

const base = {
  id: "1", nombre: "Delito", penaMin: 0, penaMax: 0, gradoEjecucion: "consumado",
  fraccionEjecucion: 0, participacionEspecifica: "Autor", delitoContinuado: false,
  fraccionContinuidad: 1 / 6, modificadorManual: 0, tipoPena: "prision",
  montoMulta: 0, ajustesAdicionales: [],
};

let fallos = 0;
function check(nombre: string, real: number, esperado: number) {
  const ok = Math.abs(real - esperado) < 1e-9;
  if (!ok) fallos++;
  console.log(`${ok ? "✅" : "❌"} ${nombre}: ${formatYMD(real)}${ok ? "" : ` (esperado ${formatYMD(esperado)})`}`);
}

// Caso 1: delito único prisión 4-8, consumado → término medio 6
check("único 4-8", calcularConcursoDetallado({
  delitos: [{ ...base, penaMin: 4, penaMax: 8 }], concurso: "real", admisionHechos: false, fraccionAdmision: 1 / 3,
}).total, 6);

// Caso 2: dos prisiones 4-8 y 6-12, real (Art 88): 9 + 1/2·6 = 12
check("Art 88 (prisión+prisión)", calcularConcursoDetallado({
  delitos: [{ ...base, penaMin: 4, penaMax: 8 }, { ...base, id: "2", penaMin: 6, penaMax: 12 }],
  concurso: "real", admisionHechos: false, fraccionAdmision: 1 / 3,
}).total, 12);

// Caso 3: presidio 20-30 + prisión 4-8, real mixto (Art 87): 25 + 2/3·(6/2) = 27
check("Art 87 (presidio+prisión)", calcularConcursoDetallado({
  delitos: [
    { ...base, penaMin: 20, penaMax: 30, tipoPena: "presidio" },
    { ...base, id: "2", penaMin: 4, penaMax: 8 },
  ],
  concurso: "real", admisionHechos: false, fraccionAdmision: 1 / 3,
}).total, 27);

// Caso 4: tope 30: presidio 30-35 → 32.5 → 30
const r4 = calcularConcursoDetallado({
  delitos: [{ ...base, penaMin: 30, penaMax: 35, tipoPena: "presidio" }],
  concurso: "real", admisionHechos: false, fraccionAdmision: 1 / 3,
});
check("tope 30 años", r4.total, 30);
if (!r4.topeAplicado) { fallos++; console.log("❌ tope no marcado"); }

// Caso 5: tope + admisión 1/3 → 30·(2/3) = 20
check("tope + admisión 1/3", calcularConcursoDetallado({
  delitos: [{ ...base, penaMin: 30, penaMax: 35, tipoPena: "presidio" }],
  concurso: "real", admisionHechos: true, fraccionAdmision: 1 / 3,
}).total, 20);

// Caso 6: concurso ideal → solo la mayor (9)
check("concurso ideal", calcularConcursoDetallado({
  delitos: [{ ...base, penaMin: 4, penaMax: 8 }, { ...base, id: "2", penaMin: 6, penaMax: 12 }],
  concurso: "ideal", admisionHechos: false, fraccionAdmision: 1 / 3,
}).total, 9);

// Caso 7: tentativa 1/2 sobre 6 → 3
check("tentativa 1/2", calcularConcursoDetallado({
  delitos: [{ ...base, penaMin: 4, penaMax: 8, gradoEjecucion: "tentativa", fraccionEjecucion: 1 / 2 }],
  concurso: "real", admisionHechos: false, fraccionAdmision: 1 / 3,
}).total, 3);

// Caso 8: frustrado 1/3 sobre 6 → 4
check("frustrado 1/3", calcularConcursoDetallado({
  delitos: [{ ...base, penaMin: 4, penaMax: 8, gradoEjecucion: "frustrado", fraccionEjecucion: 1 / 3 }],
  concurso: "real", admisionHechos: false, fraccionAdmision: 1 / 3,
}).total, 4);

// Caso 9: cómplice no necesario: 6 → 3
check("cómplice no necesario", calcularConcursoDetallado({
  delitos: [{ ...base, penaMin: 4, penaMax: 8, participacionEspecifica: "Cómplice No Necesario" }],
  concurso: "real", admisionHechos: false, fraccionAdmision: 1 / 3,
}).total, 3);

// Caso 10: delito continuado: 6 → 7
check("delito continuado +1/6", calcularConcursoDetallado({
  delitos: [{ ...base, penaMin: 4, penaMax: 8, delitoContinuado: true, fraccionContinuidad: 1 / 6 }],
  concurso: "real", admisionHechos: false, fraccionAdmision: 1 / 3,
}).total, 7);

// YMD
const ymd = convertToYMD(1.5);
console.log(`${ymd.anos === 1 && ymd.meses === 6 ? "✅" : "❌"} YMD 1.5 → ${JSON.stringify(ymd)}`);
if (ymd.anos !== 1 || ymd.meses !== 6) fallos++;

console.log(fallos === 0 ? "\n✅ TODOS LOS CASOS PASAN" : `\n❌ ${fallos} FALLOS`);
process.exit(fallos === 0 ? 0 : 1);