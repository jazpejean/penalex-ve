"use client";

// Calculadora de lapsos procesales: cuenta días hábiles (lunes a viernes,
// excluyendo feriados nacionales fijos de Venezuela).
import { useState } from "react";
import Link from "next/link";
import HeaderHome from "../../components/HeaderHome";

// Feriados nacionales de fecha fija (mes-día). Carnaval y Semana Santa son
// móviles: se advierte al usuario que no están incluidos.
const FERIADOS_FIJOS: Array<[number, number]> = [
  [1, 1],
  [4, 19],
  [5, 1],
  [6, 24],
  [7, 5],
  [7, 24],
  [8, 3],
  [10, 12],
  [12, 24],
  [12, 25],
  [12, 31],
];

function esFeriado(d: Date): boolean {
  return FERIADOS_FIJOS.some(
    ([mes, dia]) => d.getMonth() + 1 === mes && d.getDate() === dia,
  );
}

function esHabil(d: Date): boolean {
  const dia = d.getDay(); // 0 domingo, 6 sábado
  return dia !== 0 && dia !== 6 && !esFeriado(d);
}

function sumarDiasHabiles(inicio: Date, dias: number): { fin: Date; saltados: string[] } {
  const d = new Date(inicio.getTime());
  const saltados: string[] = [];
  let contados = 0;
  let guardia = 0;
  while (contados < dias && guardia < 4000) {
    d.setDate(d.getDate() + 1);
    guardia++;
    if (esHabil(d)) {
      contados++;
    } else if (esFeriado(d)) {
      saltados.push(
        d.toLocaleDateString("es-VE", { day: "2-digit", month: "long" }),
      );
    }
  }
  return { fin: d, saltados };
}

function formatear(d: Date): string {
  return d.toLocaleDateString("es-VE", {
    weekday: "long",
    day: "2-digit",
    month: "long",
    year: "numeric",
  });
}

export default function LapsosPage() {
  const [inicio, setInicio] = useState("");
  const [dias, setDias] = useState("5");
  const [error, setError] = useState("");
  const [resultado, setResultado] = useState<{
    fin: string;
    saltados: string[];
  } | null>(null);

  function calcular() {
    setError("");
    setResultado(null);
    const n = parseInt(dias, 10);
    if (!inicio) {
      setError("Indica la fecha de inicio del lapso.");
      return;
    }
    if (!isFinite(n) || n < 1 || n > 120) {
      setError("Indica un número de días hábiles entre 1 y 120.");
      return;
    }
    const base = new Date(inicio + "T12:00:00");
    if (isNaN(base.getTime())) {
      setError("La fecha no es válida.");
      return;
    }
    if (!esHabil(base)) {
      setError(
        "La fecha de inicio cae en día no hábil (fin de semana o feriado). Elige un día hábil.",
      );
      return;
    }
    const { fin, saltados } = sumarDiasHabiles(base, n);
    setResultado({ fin: formatear(fin), saltados: saltados.slice(0, 6) });
  }

  return (
    <div className="min-h-screen bg-[#f8fafc]">
      <HeaderHome />
      <main className="mx-auto max-w-3xl px-4 py-10">
        <nav className="text-xs text-slate-500">
          <Link href="/" className="text-[#031F4E]">Inicio</Link> · Lapsos
        </nav>
        <h1 className="mt-3 font-serif text-3xl font-bold text-[#031F4E] sm:text-4xl">
          Calculadora de lapsos procesales
        </h1>
        <p className="mt-3 text-sm leading-relaxed text-slate-600">
          Cuenta días hábiles desde una fecha de inicio, excluyendo sábados,
          domingos y los feriados nacionales de fecha fija.
        </p>

        <div className="mt-6 rounded-2xl border border-slate-200 bg-white p-6">
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <label className="block">
              <span className="text-xs font-bold uppercase tracking-wide text-slate-500">
                Fecha de inicio
              </span>
              <input
                type="date"
                value={inicio}
                onChange={(e) => setInicio(e.target.value)}
                className="mt-1 w-full rounded-lg border border-slate-200 px-3 py-2.5 text-sm outline-none focus:border-[#031F4E]"
              />
            </label>
            <label className="block">
              <span className="text-xs font-bold uppercase tracking-wide text-slate-500">
                Días hábiles
              </span>
              <input
                value={dias}
                onChange={(e) => setDias(e.target.value)}
                inputMode="numeric"
                className="mt-1 w-full rounded-lg border border-slate-200 px-3 py-2.5 text-sm outline-none focus:border-[#031F4E]"
              />
            </label>
          </div>

          <button
            onClick={calcular}
            className="mt-5 w-full rounded-lg bg-[#C5A059] px-4 py-3 text-sm font-bold text-[#031F4E] hover:brightness-105"
          >
            Calcular vencimiento
          </button>

          {error ? (
            <p className="mt-4 rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-600">
              {error}
            </p>
          ) : null}

          {resultado ? (
            <div className="mt-5 rounded-xl border border-[#E9C86A] bg-[#FBF2DD] p-5">
              <p className="text-xs font-bold uppercase tracking-wide text-[#9a7a34]">
                Vence el
              </p>
              <p className="mt-1 text-2xl font-bold capitalize text-[#031F4E]">
                {resultado.fin}
              </p>
              {resultado.saltados.length > 0 ? (
                <p className="mt-3 text-xs leading-relaxed text-slate-600">
                  Feriados omitidos: {resultado.saltados.join(", ")}.
                </p>
              ) : null}
            </div>
          ) : null}
        </div>

        <p className="mt-4 text-xs leading-relaxed text-slate-500">
          No incluye Carnaval ni Semana Santa (fechas móviles) ni los días que
          el tribunal declare inhábiles. Confirma siempre en el calendario
          judicial.
        </p>
      </main>
    </div>
  );
}
