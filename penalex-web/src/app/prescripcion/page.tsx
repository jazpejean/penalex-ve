"use client";

// Calculadora de prescripción penal (arts. 108 y 112 del Código Penal).
// Misma lógica que la app móvil (PrescripcionService).
import { useState } from "react";
import Link from "next/link";
import HeaderHome from "../../components/HeaderHome";

type Modo = "accion" | "pena";

interface Resultado {
  titulo: string;
  anios: number;
  meses: number;
  fundamento: string;
  fecha: string;
}

function sumarAniosMeses(base: Date, anios: number, meses: number): Date {
  const d = new Date(base.getTime());
  d.setFullYear(d.getFullYear() + anios);
  d.setMonth(d.getMonth() + meses);
  return d;
}

function formatear(d: Date): string {
  return d.toLocaleDateString("es-VE", {
    day: "2-digit",
    month: "long",
    year: "numeric",
  });
}

export default function PrescripcionPage() {
  const [modo, setModo] = useState<Modo>("accion");
  const [pena, setPena] = useState("");
  const [fecha, setFecha] = useState("");
  const [error, setError] = useState("");
  const [resultado, setResultado] = useState<Resultado | null>(null);

  function calcular() {
    setError("");
    setResultado(null);
    const valor = parseFloat(pena.replace(",", "."));
    if (!isFinite(valor) || valor <= 0) {
      setError("Ingresa la pena en años (ej. 12.5).");
      return;
    }
    if (!fecha) {
      setError("Indica la fecha del hecho (o de la última actuación).");
      return;
    }
    const base = new Date(fecha + "T12:00:00");
    if (isNaN(base.getTime())) {
      setError("La fecha no es válida.");
      return;
    }

    let anios = 0;
    let meses = 0;
    let fundamento = "";

    if (modo === "pena") {
      const total = valor * 1.5;
      anios = Math.floor(total);
      meses = Math.round((total - anios) * 12);
      fundamento =
        "Art. 112, numeral 1 del Código Penal (tiempo igual a la condena más la mitad).";
    } else if (valor > 10) {
      anios = 15;
      fundamento = "Art. 108, numeral 1 del Código Penal (presidio o prisión de más de 10 años).";
    } else if (valor > 7) {
      anios = 10;
      fundamento = "Art. 108, numeral 2 del Código Penal (más de 7 años y hasta 10).";
    } else if (valor > 3) {
      anios = 7;
      fundamento = "Art. 108, numeral 3 del Código Penal (más de 3 años y hasta 7).";
    } else if (valor > 1) {
      anios = 5;
      fundamento = "Art. 108, numeral 4 del Código Penal (más de 1 año y hasta 3).";
    } else {
      anios = 3;
      fundamento = "Art. 108, numeral 5 del Código Penal (un año o menos).";
    }

    const vence = sumarAniosMeses(base, anios, meses);
    setResultado({
      titulo: [anios > 0 ? `${anios} ${anios === 1 ? "año" : "años"}` : "", meses > 0 ? `${meses} ${meses === 1 ? "mes" : "meses"}` : ""]
        .filter(Boolean)
        .join(" "),
      anios,
      meses,
      fundamento,
      fecha: formatear(vence),
    });
  }

  return (
    <div className="min-h-screen bg-[#f8fafc]">
      <HeaderHome />
      <main className="mx-auto max-w-3xl px-4 py-10">
        <nav className="text-xs text-slate-500">
          <Link href="/" className="text-[#031F4E]">Inicio</Link> · Prescripción
        </nav>
        <h1 className="mt-3 font-serif text-3xl font-bold text-[#031F4E] sm:text-4xl">
          Calculadora de prescripción penal
        </h1>
        <p className="mt-3 text-sm leading-relaxed text-slate-600">
          Calcula el término de prescripción de la acción penal (art. 108) o de
          la pena (art. 112) del Código Penal venezolano y la fecha en que se
          completa, contada desde el día del hecho (art. 109).
        </p>

        <div className="mt-6 rounded-2xl border border-slate-200 bg-white p-6">
          <div className="flex flex-wrap gap-2">
            {(
              [
                ["accion", "Acción penal (art. 108)"],
                ["pena", "Pena (art. 112)"],
              ] as [Modo, string][]
            ).map(([valor, etiqueta]) => (
              <button
                key={valor}
                onClick={() => {
                  setModo(valor);
                  setResultado(null);
                }}
                className={`rounded-lg px-4 py-2 text-sm font-semibold ${
                  modo === valor
                    ? "bg-[#031F4E] text-white"
                    : "border border-slate-200 text-slate-600 hover:bg-slate-50"
                }`}
              >
                {etiqueta}
              </button>
            ))}
          </div>

          <div className="mt-5 grid grid-cols-1 gap-4 sm:grid-cols-2">
            <label className="block">
              <span className="text-xs font-bold uppercase tracking-wide text-slate-500">
                {modo === "pena"
                  ? "Pena impuesta (años)"
                  : "Pena máxima del delito (años)"}
              </span>
              <input
                value={pena}
                onChange={(e) => setPena(e.target.value)}
                inputMode="decimal"
                placeholder="Ej. 12.5"
                className="mt-1 w-full rounded-lg border border-slate-200 px-3 py-2.5 text-sm outline-none focus:border-[#031F4E]"
              />
            </label>
            <label className="block">
              <span className="text-xs font-bold uppercase tracking-wide text-slate-500">
                Fecha del hecho
              </span>
              <input
                type="date"
                value={fecha}
                onChange={(e) => setFecha(e.target.value)}
                className="mt-1 w-full rounded-lg border border-slate-200 px-3 py-2.5 text-sm outline-none focus:border-[#031F4E]"
              />
            </label>
          </div>

          <button
            onClick={calcular}
            className="mt-5 w-full rounded-lg bg-[#C5A059] px-4 py-3 text-sm font-bold text-[#031F4E] hover:brightness-105"
          >
            Calcular prescripción
          </button>

          {error ? (
            <p className="mt-4 rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-600">
              {error}
            </p>
          ) : null}

          {resultado ? (
            <div className="mt-5 rounded-xl border border-[#E9C86A] bg-[#FBF2DD] p-5">
              <p className="text-xs font-bold uppercase tracking-wide text-[#9a7a34]">
                Término de prescripción
              </p>
              <p className="mt-1 font-serif text-3xl font-bold text-[#031F4E]">
                {resultado.titulo}
              </p>
              <p className="mt-3 text-sm text-slate-700">
                <strong>Fecha de prescripción:</strong> {resultado.fecha}
              </p>
              <p className="mt-2 text-xs leading-relaxed text-slate-600">
                {resultado.fundamento}
              </p>
            </div>
          ) : null}
        </div>

        <p className="mt-4 text-xs leading-relaxed text-slate-500">
          Cálculo orientativo. La prescripción se interrumpe por los actos que
          señala el artículo 110 del Código Penal; verifica siempre el
          expediente y la jurisprudencia aplicable.
        </p>
      </main>
    </div>
  );
}
