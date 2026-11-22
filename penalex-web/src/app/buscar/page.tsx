"use client";

// Búsqueda semántica sobre el corpus (worker /buscar/semantica).
import { useState } from "react";
import Link from "next/link";
import HeaderHome from "../../components/HeaderHome";

const WORKER =
  process.env.NEXT_PUBLIC_WORKER_URL ??
  "https://penalex-auth-bridge.ignaciojazpe47.workers.dev";

interface Hit {
  documento_id: string | null;
  score: number;
  texto_chunk: string;
  sala: string;
  anio: string;
  fuente: string;
  ley: string | null;
  articulo: string | null;
  encabezado: string | null;
  titulo: string | null;
}

const SALAS: Record<string, string> = {
  scp: "Casación Penal",
  scon: "Constitucional",
  scs: "Casación Social",
  sca: "Político-Administrativa",
  scc: "Casación Civil",
  se: "Electoral",
};

export default function BuscarPage() {
  const [consulta, setConsulta] = useState("");
  const [resultados, setResultados] = useState<Hit[]>([]);
  const [cargando, setCargando] = useState(false);
  const [error, setError] = useState("");
  const [buscado, setBuscado] = useState(false);

  async function buscar(e: React.FormEvent) {
    e.preventDefault();
    const q = consulta.trim();
    if (q.length < 3) {
      setError("Escribe al menos 3 caracteres.");
      return;
    }
    setError("");
    setCargando(true);
    setBuscado(true);
    try {
      const res = await fetch(`${WORKER}/buscar/semantica`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ query: q, limite: 20 }),
      });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const data = (await res.json()) as { resultados?: Hit[] };
      setResultados(data.resultados ?? []);
    } catch (err) {
      setError(
        "No se pudo completar la búsqueda semántica. Intenta de nuevo en unos segundos.",
      );
      console.error(err);
      setResultados([]);
    } finally {
      setCargando(false);
    }
  }

  return (
    <div className="min-h-screen bg-[#f8fafc]">
      <HeaderHome />
      <main className="mx-auto max-w-4xl px-4 py-10">
        <nav className="text-xs text-slate-500">
          <Link href="/" className="text-[#031F4E]">Inicio</Link> · Búsqueda
          semántica
        </nav>
        <h1 className="mt-3 font-serif text-3xl font-bold text-[#031F4E] sm:text-4xl">
          Búsqueda semántica
        </h1>
        <p className="mt-3 text-sm leading-relaxed text-slate-600">
          Encuentra criterios por su significado, no solo por palabras exactas.
          Ejemplo: “detención sin orden judicial”, “prueba ilícita”,
          “prescripción de la acción”.
        </p>

        <form onSubmit={buscar} className="mt-6 flex flex-col gap-2 sm:flex-row">
          <input
            value={consulta}
            onChange={(e) => setConsulta(e.target.value)}
            placeholder="Describe lo que buscas…"
            className="w-full rounded-lg border border-slate-200 bg-white px-4 py-3 text-sm outline-none focus:border-[#031F4E]"
          />
          <button
            type="submit"
            disabled={cargando}
            className="rounded-lg bg-[#031F4E] px-6 py-3 text-sm font-bold text-white hover:bg-[#06305f] disabled:opacity-60"
          >
            {cargando ? "Buscando…" : "Buscar"}
          </button>
        </form>

        {error ? (
          <p className="mt-4 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-600">
            {error}
          </p>
        ) : null}

        {buscado && !cargando && !error ? (
          <p className="mt-6 text-xs font-semibold uppercase tracking-wide text-slate-500">
            {resultados.length} resultado(s)
          </p>
        ) : null}

        <div className="mt-3 space-y-3">
          {resultados.map((h, i) => (
            <article
              key={`${h.documento_id ?? i}-${i}`}
              className="rounded-xl border border-slate-200 bg-white p-5"
            >
              <div className="flex flex-wrap items-center gap-2">
                {h.sala ? (
                  <span className="rounded-full bg-[#031F4E] px-2.5 py-0.5 text-[10px] font-bold uppercase text-white">
                    {SALAS[h.sala.toLowerCase()] ?? h.sala}
                  </span>
                ) : null}
                {h.anio ? (
                  <span className="rounded-full bg-slate-100 px-2.5 py-0.5 text-[10px] font-bold text-slate-500">
                    {h.anio}
                  </span>
                ) : null}
                {h.ley ? (
                  <span className="rounded-full bg-[#FBF2DD] px-2.5 py-0.5 text-[10px] font-bold text-[#9a7a34]">
                    {h.ley}
                    {h.articulo ? ` · Art. ${h.articulo}` : ""}
                  </span>
                ) : null}
                <span className="ml-auto text-[10px] font-semibold text-slate-400">
                  similitud {(h.score * 100).toFixed(0)}%
                </span>
              </div>
              {h.titulo || h.encabezado ? (
                <h2 className="mt-2 text-sm font-bold text-[#031F4E]">
                  {h.titulo || h.encabezado}
                </h2>
              ) : null}
              <p className="mt-2 text-sm leading-relaxed text-slate-600">
                {h.texto_chunk}
              </p>
            </article>
          ))}
        </div>

        {buscado && !cargando && resultados.length === 0 && !error ? (
          <p className="mt-6 rounded-xl border border-slate-200 bg-white p-5 text-sm text-slate-500">
            Sin resultados para esa consulta. Prueba con otras palabras o con un
            concepto jurídico más amplio.
          </p>
        ) : null}
      </main>
    </div>
  );
}
