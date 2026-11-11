import Link from "next/link";
import Navbar from "../../components/Navbar";
import BuscadorArticulos from "../../components/BuscadorArticulos";
import Icono from "../../components/Icono";
import { listarLeyes } from "../../lib/supabase";

export default async function LeyesPage() {
  let leyes: Array<{ slug: string; nombre: string; orden: number }> = [];
  let error = "";
  try {
    // El manifest ya trae las leyes ordenadas por relevancia (campo `orden`).
    leyes = await listarLeyes();
  } catch (e) {
    error = e instanceof Error ? e.message : String(e);
  }

  return (
    <>
      <Navbar />
      <main className="mx-auto w-full max-w-6xl flex-1 px-4 py-10">
        <div className="flex flex-wrap items-end justify-between gap-4 border-b border-[#e2e8f0] pb-6">
          <div>
            <p className="text-xs font-semibold uppercase tracking-[0.2em] text-[#9a7a34]">
              Legislación
            </p>
            <h1 className="serif mt-3 text-4xl font-bold text-[#031f4e]">
              Corpus legal venezolano
            </h1>
            <p className="mt-3 max-w-2xl text-sm leading-relaxed text-slate-600">
              {leyes.length > 0
                ? `${leyes.length} leyes íntegras con párrafos, encabezados y notas jurisprudenciales, verificadas contra las fuentes oficiales.`
                : "Cargando corpus legal…"}
            </p>
          </div>
          {/* Buscador de artículos (portado de la app) */}
          <div className="flex items-center gap-2">
            <BuscadorArticulos conTexto />
          </div>
        </div>

        {error && (
          <div className="mt-6 rounded-lg border border-red-300 bg-red-50 p-4 text-sm text-red-600">
            No se pudo cargar el índice de leyes: {error}
          </div>
        )}

        <div className="mt-8 grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
          {leyes.map((l) => (
            <Link
              key={l.slug}
              href={`/leyes/${l.slug}`}
              className="group rounded-xl border border-[#e2e8f0] bg-white p-4 shadow-sm transition hover:border-[#c5a059]/60 hover:shadow-md"
            >
              <div className="flex items-start justify-between gap-2">
                <h2 className="text-sm font-semibold leading-snug text-[#031f4e] group-hover:text-[#9a7a34]">
                  {l.nombre}
                </h2>
                <span className="text-[#9a7a34] opacity-0 transition group-hover:opacity-100">
                  →
                </span>
              </div>
              <div className="mt-2 text-[11px] font-semibold uppercase tracking-wide text-slate-400">
                Orden {l.orden === 999 ? "-" : l.orden}
              </div>
            </Link>
          ))}
        </div>
      </main>
    </>
  );
}