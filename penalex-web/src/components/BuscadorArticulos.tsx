"use client";

import { useCallback, useState } from "react";
import { listarLeyes, obtenerLey, type LeyEstructura } from "../lib/supabase";
import Icono from "./Icono";

// ---------------------------------------------------------------------------
// Tipos (mirror de RegistroArticulo / ResultadoLey de la app)
// ---------------------------------------------------------------------------

interface RegistroArticulo {
  slug: string;
  leyNombre: string;
  identificador: string;
  tipoNorma: string;
  encabezado?: string | null;
  texto: string;
  numeralesLiterales: string[];
  paragrafos: string[];
  estado: string;
}

interface ResultadoLey {
  registro: RegistroArticulo;
  puntaje: number;
  extracto: string;
}

// Caché de sesión del índice plano
let _indice: RegistroArticulo[] | null = null;
let _indicePromise: Promise<RegistroArticulo[]> | null = null;

// ---------------------------------------------------------------------------
// Utilidades (mirror de la app: _sinAcentos, _puntuar, _extracto, _detectarLey)
// ---------------------------------------------------------------------------

function _sinAcentos(s: string): string {
  const map: Record<string, string> = {
    á: "a", à: "a", ä: "a", â: "a",
    é: "e", è: "e", ë: "e", ê: "e",
    í: "i", ì: "i", ï: "i", î: "i",
    ó: "o", ò: "o", ö: "o", ô: "o",
    ú: "u", ù: "u", ü: "u", û: "u",
    ñ: "n", ç: "c",
  };
  return s
    .toLowerCase()
    .split("")
    .map((c) => map[c] ?? c)
    .join("");
}

function _contar(texto: string, termino: string): number {
  if (!termino) return 0;
  let count = 0;
  let idx = texto.indexOf(termino);
  while (idx !== -1) {
    count++;
    idx = texto.indexOf(termino, idx + termino.length);
  }
  return count;
}

function _extracto(
  texto: string,
  terminos: string[],
  consulta: string
): string {
  const textoNorm = _sinAcentos(texto);
  let pos = -1;
  for (const t of terminos) {
    pos = textoNorm.indexOf(_sinAcentos(t));
    if (pos !== -1) break;
  }
  if (pos === -1) pos = textoNorm.indexOf(_sinAcentos(consulta));
  if (pos === -1) {
    return texto.length > 180 ? `${texto.substring(0, 180)}…` : texto;
  }
  const inicio = Math.max(0, pos - 60);
  const fin = Math.min(texto.length, pos + 120);
  let ex = texto.substring(inicio, fin);
  if (inicio > 0) ex = `…${ex}`;
  if (fin < texto.length) ex = `${ex}…`;
  return ex;
}

function _puntuar(
  reg: RegistroArticulo,
  numeros: Set<string>,
  palabras: Set<string>
): number {
  const texto = _sinAcentos(
    [reg.encabezado ?? "", reg.texto, ...reg.numeralesLiterales, ...reg.paragrafos].join(" ")
  );
  const encabezado = _sinAcentos(reg.encabezado ?? "");
  const leyNombre = _sinAcentos(reg.leyNombre);
  const identificador = _sinAcentos(reg.identificador);

  let score = 0;

  // 1) Coincidencia exacta de número de artículo: prioridad máxima.
  for (const n of numeros) {
    if (identificador === n) {
      score += 100;
    } else if (n.length >= 2 && identificador.includes(n)) {
      score += 6;
    }
  }

  // 2) Palabras clave en encabezado / nombre de ley / texto.
  for (const p of palabras) {
    if (!p) continue;
    score += _contar(encabezado, p) * 4.0;
    score += _contar(leyNombre, p) * 3.0;
    score += _contar(texto, p) * 1.0;
  }

  return score;
}

function _detectarLey(consulta: string, leyesUnicas: Set<string>): string | null {
  const stopwords = new Set([
    "articulo", "articulos", "art", "del", "de", "la", "el", "los", "las",
    "segun", "conforme",
  ]);
  const alias: Record<string, string> = {
    copp: "procesal penal",
    crbv: "constitucion",
    constitucion: "constitucion",
    lopnna: "lopnna",
    violencia: "violencia",
    "codigo penal": "codigo penal",
    cp: "codigo penal",
  };

  const qnorm = _sinAcentos(consulta.toLowerCase()).trim();

  for (const [key, val] of Object.entries(alias)) {
    if (qnorm.includes(key)) {
      const frag = _sinAcentos(val);
      for (const nombre of leyesUnicas) {
        if (_sinAcentos(nombre).includes(frag)) return nombre;
      }
    }
  }

  const tokens = qnorm
    .split(/[^a-z0-9]+/)
    .filter((t) => t && !/^\d+$/.test(t) && !stopwords.has(t));
  if (tokens.length === 0) return null;

  const frase = tokens.join(" ");
  for (const nombre of leyesUnicas) {
    if (_sinAcentos(nombre).includes(frase)) return nombre;
  }

  const palabras = new Set(tokens.filter((t) => t.length >= 4));
  if (palabras.size === 0) return null;
  let mejor: string | null = null;
  let mejorScore = 0;
  for (const nombre of leyesUnicas) {
    const n = _sinAcentos(nombre);
    let score = 0;
    for (const p of palabras) if (n.includes(p)) score++;
    if (score > mejorScore) {
      mejorScore = score;
      mejor = nombre;
    }
  }
  return mejorScore >= 1 ? mejor : null;
}

// ---------------------------------------------------------------------------
// Construcción del índice (descarga todas las leyes, con progreso)
// ---------------------------------------------------------------------------

async function _garantizarIndice(
  onProgress?: (actual: number, total: number) => void
): Promise<RegistroArticulo[]> {
  if (_indice) return _indice;
  if (_indicePromise) return _indicePromise;

  _indicePromise = (async () => {
    const leyes = await listarLeyes();
    const registros: RegistroArticulo[] = [];
    const total = leyes.length;
    for (let i = 0; i < total; i++) {
      const meta = leyes[i];
      onProgress?.(i + 1, total);
      try {
        const ley: LeyEstructura = await obtenerLey(meta.slug);
        for (const bloque of ley.estructura ?? []) {
          for (const art of bloque.articulos ?? []) {
            registros.push({
              slug: meta.slug,
              leyNombre: ley.ley_nombre ?? meta.nombre,
              identificador: art.identificador ?? "",
              tipoNorma: art.tipo_norma ?? "Artículo",
              encabezado: art.encabezado ?? null,
              texto: art.texto_principal ?? "",
              numeralesLiterales: [],
              paragrafos: [],
              estado: "vigente",
            });
          }
        }
      } catch {
        // ley no disponible: se omite
      }
    }
    _indice = registros;
    return registros;
  })();

  try {
    return await _indicePromise;
  } finally {
    _indicePromise = null;
  }
}

// ---------------------------------------------------------------------------
// Componente: botón + modal "Consultar artículos" (fiel al sheet de la app)
// ---------------------------------------------------------------------------

export default function BuscadorArticulos({ conTexto = false }: { conTexto?: boolean }) {
  const [abierto, setAbierto] = useState(false);
  const [query, setQuery] = useState("");
  const [resultados, setResultados] = useState<ResultadoLey[]>([]);
  const [buscando, setBuscando] = useState(false);
  const [consultado, setConsultado] = useState(false);
  const [progreso, setProgreso] = useState("");
  const [articulo, setArticulo] = useState<ResultadoLey | null>(null);

  const buscar = useCallback(
    async (q: string) => {
      const consulta = q.trim();
      if (!consulta) return;
      setBuscando(true);
      setConsultado(true);
      setProgreso("");

      const indice = await _garantizarIndice((actual, total) => {
        if (actual % 5 === 0) setProgreso(`Indexando leyes ${actual}/${total}…`);
      });

      const numeros = new Set(
        [...consulta.matchAll(/\d+/g)].map((m) => m[0])
      );
      const palabras = new Set(
        consulta
          .split(/[\s,.;:()\-–—]+/)
          .map(_sinAcentos)
          .filter((t) => t && !/^\d+$/.test(t))
      );

      const leyesUnicas = new Set(indice.map((r) => r.leyNombre));
      const leyDetectada = _detectarLey(consulta, leyesUnicas);

      const res: ResultadoLey[] = [];
      for (const reg of indice) {
        if (leyDetectada && reg.leyNombre !== leyDetectada) continue;
        const score = _puntuar(reg, numeros, palabras);
        if (score > 0) {
          res.push({
            registro: reg,
            puntaje: score,
            extracto: _extracto(
              [reg.encabezado ?? "", reg.texto, ...reg.numeralesLiterales, ...reg.paragrafos].join(" "),
              [...palabras],
              consulta
            ),
          });
        }
      }
      res.sort((a, b) => b.puntaje - a.puntaje);
      setResultados(res.slice(0, 40));
      setBuscando(false);
    },
    []
  );

  return (
    <>
      <button
        onClick={() => {
          setAbierto(true);
          setQuery("");
          setResultados([]);
          setConsultado(false);
        }}
        className={`${conTexto ? "flex items-center gap-2 rounded-md bg-[#031f4e] px-4 py-2 text-sm font-semibold text-white hover:bg-[#06305f]" : "rounded-md border border-[#e2e8f0] px-3 py-1.5 text-[#031f4e] hover:bg-[#f1f5f9]"}`}
        title="Consultar artículos de las leyes"
      >
        <Icono nombre="lupa" size={conTexto ? 16 : 17} />
        {conTexto && "Buscar artículo"}
      </button>

      {/* Modal buscador */}
      {abierto && (
        <div className="fixed inset-0 z-50 flex items-end justify-center bg-black/60 sm:items-center">
          <div className="flex h-[85vh] w-full max-w-lg flex-col rounded-t-2xl border border-[#e2e8f0] bg-white sm:rounded-2xl">
            {/* Mango */}
            <div className="mx-auto mt-3 h-1 w-10 rounded-full bg-[#e2e8f0]" />

            {/* Título */}
            <div className="flex items-center justify-between px-5 pt-3">
              <h2 className="text-lg font-bold text-[#031f4e]">Consultar artículos</h2>
              <button
                onClick={() => setAbierto(false)}
                className="text-slate-400 hover:text-[#031f4e]"
              >
                ✕
              </button>
            </div>

            {/* Campo de búsqueda */}
            <div className="px-4 pt-3 pb-4">
              <input
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === "Enter") buscar(query);
                }}
                autoFocus
                placeholder="Buscar por artículo, delito o tema (ej. 406, homicidio)"
                className="w-full rounded-xl border border-[#e2e8f0] bg-[#f1f5f9] px-4 py-3 text-[15px] text-[#031f4e] placeholder:text-slate-400 focus:border-[#C5A059] focus:outline-none"
              />
            </div>

            {/* Cuerpo */}
            <div className="flex-1 overflow-y-auto px-2 pb-4">
              {buscando ? (
                <div className="flex flex-col items-center justify-center py-12">
                  <span className="h-8 w-8 animate-spin rounded-full border-2 border-[#C5A059]/30 border-t-[#C5A059]" />
                  <span className="mt-4 text-sm text-slate-500">
                    {progreso || "Buscando…"}
                  </span>
                </div>
              ) : !consultado ? (
                <div className="flex flex-col items-center justify-center py-12 px-8 text-center">
                  <Icono nombre="libro" size={56} className="text-[#C5A059]" />
                  <p className="mt-4 text-sm leading-relaxed text-slate-500">
                    Escribe un término legal o el número de un artículo y toca
                    "Buscar" en el teclado.
                  </p>
                </div>
              ) : resultados.length === 0 ? (
                <div className="flex flex-col items-center justify-center py-12">
                  <Icono nombre="lupa" size={56} className="text-slate-500" />
                  <span className="mt-4 text-sm text-slate-500">Sin resultados</span>
                </div>
              ) : (
                resultados.map((r, i) => {
                  const esArticulo = r.registro.tipoNorma === "Artículo";
                  const titulo = esArticulo
                    ? `Art. ${r.registro.identificador}`
                    : r.registro.tipoNorma;
                  return (
                    <button
                      key={i}
                      onClick={() => setArticulo(r)}
                      className="mb-2 w-full rounded-xl border border-[#e2e8f0] bg-white p-3.5 text-left hover:border-[#C5A059]/60 hover:shadow-sm"
                    >
                      <div className="flex items-center gap-2">
                        <span className="rounded-md bg-[#eef2f8] px-2 py-0.5 text-[10px] font-bold text-[#9a7a34]">
                          {r.registro.leyNombre}
                        </span>
                        <span className="flex-1 truncate text-[15px] font-bold text-[#031f4e]">
                          {titulo}
                        </span>
                        <span className="text-[#C5A059]">›</span>
                      </div>
                      {r.registro.encabezado && (
                        <div className="mt-1.5 text-[13px] font-semibold text-slate-700">
                          {r.registro.encabezado}
                        </div>
                      )}
                      <div className="mt-1 text-[13px] leading-snug text-slate-500">
                        {r.extracto}
                      </div>
                    </button>
                  );
                })
              )}
            </div>
          </div>
        </div>
      )}

      {/* Modal artículo (fiel a articulo_ley_sheet.dart) */}
      {articulo && (
        <div className="fixed inset-0 z-[60] flex items-end justify-center bg-black/60 sm:items-center">
          <div className="flex h-[85vh] w-full max-w-lg flex-col rounded-t-2xl border border-[#e2e8f0] bg-white sm:rounded-2xl">
            <div className="mx-auto mt-3 h-1 w-10 rounded-full bg-[#e2e8f0]" />
            <div className="flex items-center gap-3 px-5 pt-3 pb-3">
              <span className="rounded-lg bg-[#C5A059] px-2.5 py-1 text-sm font-bold text-[#0F172A]">
                {articulo.registro.tipoNorma === "Artículo"
                  ? `Artículo ${articulo.registro.identificador}`
                  : articulo.registro.tipoNorma}
              </span>
              <span className="flex-1 truncate text-[13px] text-slate-500">
                {articulo.registro.leyNombre}
              </span>
              <button
                onClick={() => setArticulo(null)}
                className="text-slate-400 hover:text-[#031f4e]"
              >
                ✕
              </button>
            </div>
            <div className="h-px bg-[#e2e8f0]" />
            <div className="flex-1 overflow-y-auto px-5 py-4">
              {articulo.registro.encabezado && (
                <div className="text-[17px] font-bold leading-snug text-[#031f4e]">
                  {articulo.registro.encabezado}
                </div>
              )}
              <div className="mt-3 text-[15px] leading-relaxed text-justify text-[#334155]">
                {articulo.registro.texto}
              </div>
            </div>
          </div>
        </div>
      )}
    </>
  );
}