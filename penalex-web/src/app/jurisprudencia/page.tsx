import type { Metadata } from "next";
import Link from "next/link";
import { cargarSentencias, nombreSala } from "@/lib/sentencias";

export const metadata: Metadata = {
  title: "Jurisprudencia Venezolana | Sentencias del TSJ | Penalex",
  description:
    "Más de 55.000 sentencias del Tribunal Supremo de Justicia de Venezuela: Sala Constitucional y Sala de Casación Penal. Búsqueda por ponente, materia, expediente y texto.",
  robots: { index: true, follow: true },
};

const SITIO = process.env.NEXT_PUBLIC_SITE_URL ?? "https://penalexve.com";

export default function PaginaIndiceJurisprudencia() {
  const datos = cargarSentencias();
  const sentencias = datos.sentencias;

  // Agrupar por sala y año para una navegación estable (no paginar 55K).
  const porSala: Record<string, number> = {};
  const porAnio: Record<string, number> = {};
  for (const s of sentencias) {
    const sala = s.sala.toUpperCase() || "TSJ";
    porSala[sala] = (porSala[sala] ?? 0) + 1;
    const anio = (s.fecha.match(/\d{4}/) ?? [s.anio || "—"])[0];
    porAnio[anio] = (porAnio[anio] ?? 0) + 1;
  }
  const salas = Object.entries(porSala).sort((a, b) => b[1] - a[1]);
  const anios = Object.entries(porAnio).sort((a, b) => b[0].localeCompare(a[0]));

  // Últimas sentencias (fecha desc — el JSON ya viene ordenado por fecha desc).
  const recientes = sentencias.slice(0, 20);

  const jsonLd = {
    "@context": "https://schema.org",
    "@type": "CollectionPage",
    name: "Jurisprudencia Venezolana",
    description: metadata.description,
    url: `${SITIO}/jurisprudencia`,
    isPartOf: { "@type": "WebSite", name: "Penalex VE", url: SITIO },
  };

  return (
    <main className="min-h-screen bg-[#f1f5f9] text-[#031f4e]">
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
      />

      <header className="bg-[#031f4e] text-white px-6 py-5">
        <div className="max-w-4xl mx-auto flex items-center justify-between">
          <Link href="/" className="text-sm font-bold tracking-wide">
            PENALEX<span className="text-[#c5a059]">VE</span>
          </Link>
          <span className="text-sm opacity-80">{datos.total.toLocaleString("es-VE")} sentencias</span>
        </div>
      </header>

      <div className="max-w-4xl mx-auto px-6 py-8">
        <p className="text-xs uppercase tracking-widest text-[#c5a059] font-semibold">
          Jurisprudencia venezolana
        </p>
        <h1 className="mt-2 text-3xl font-bold">
          Sentencias del Tribunal Supremo de Justicia
        </h1>
        <p className="mt-3 text-slate-600 leading-relaxed">
          {datos.total.toLocaleString("es-VE")} sentencias de fondo del TSJ venezolano,
          con texto completo y ratio decidendi. El buscador avanzado (por ponente,
          materia, expediente y texto) estará disponible próximamente.
        </p>

        {/* Navegación por sala */}
        <section className="mt-8">
          <h2 className="text-xl font-bold">Por sala</h2>
          <div className="mt-3 grid grid-cols-1 sm:grid-cols-2 gap-3">
            {salas.map(([sala, total]) => (
              <div key={sala} className="rounded-xl border border-slate-200 bg-white p-4">
                <p className="font-semibold">{nombreSala(sala.toLowerCase())}</p>
                <p className="text-sm text-slate-500 mt-1">
                  {total.toLocaleString("es-VE")} sentencias
                </p>
              </div>
            ))}
          </div>
        </section>

        {/* Navegación por año */}
        <section className="mt-8">
          <h2 className="text-xl font-bold">Por año</h2>
          <div className="mt-3 flex flex-wrap gap-2">
            {anios.map(([anio, total]) => (
              <span
                key={anio}
                className="rounded-full border border-slate-300 bg-white px-3 py-1 text-sm"
              >
                {anio} · {total.toLocaleString("es-VE")}
              </span>
            ))}
          </div>
        </section>

        {/* Recientes */}
        <section className="mt-10">
          <h2 className="text-xl font-bold">Sentencias recientes</h2>
          <ul className="mt-4 divide-y divide-slate-200 rounded-xl border border-slate-200 bg-white">
            {recientes.map((s) => (
              <li key={s.slug} className="px-5 py-4">
                <Link
                  href={`/jurisprudencia/${s.slug}`}
                  className="block hover:bg-slate-50"
                >
                  <p className="font-semibold text-[#031f4e]">
                    {s.num_sentencia || s.expediente || s.id} · {nombreSala(s.sala)}
                  </p>
                  <p className="mt-1 text-sm text-slate-500">
                    {s.fecha}
                    {s.ponente ? ` · ${s.ponente}` : ""}
                  </p>
                  {s.extracto && (
                    <p className="mt-1 text-sm text-slate-600 line-clamp-2">{s.extracto}</p>
                  )}
                </Link>
              </li>
            ))}
          </ul>
        </section>
      </div>
    </main>
  );
}