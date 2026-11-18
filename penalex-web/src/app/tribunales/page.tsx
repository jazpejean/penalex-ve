import type { Metadata } from "next";
import Link from "next/link";
import HeaderHome from "../../components/HeaderHome";
import MapaTribunales from "../../components/MapaTribunales";
import {
  circunscripcionJudicial,
  listarTribunales,
  slugEstado,
} from "../../lib/tribunales";

export const metadata: Metadata = {
  title: "Tribunales Penales de Venezuela: directorio por circuito judicial",
  description:
    "Directorio de los circuitos judiciales penales de Venezuela y sus tribunales: control, juicio, ejecución y apelación, con sede, municipio y mapa interactivo por circuito.",
  alternates: { canonical: "https://penalexve.com/tribunales" },
  openGraph: {
    title: "Tribunales Penales de Venezuela: directorio por circuito judicial",
    description:
      "Los circuitos judiciales penales de Venezuela y sus tribunales, con sede y mapa interactivo.",
    url: "https://penalexve.com/tribunales",
    type: "website",
    locale: "es_VE",
    siteName: "Penalex VE",
  },
  twitter: {
    card: "summary",
    title: "Tribunales Penales de Venezuela por circuito judicial",
    description: "Circuitos judiciales penales y sus tribunales, con mapa.",
  },
};

export default async function TribunalesPage() {
  let tribunales: Awaited<ReturnType<typeof listarTribunales>> = [];
  try {
    tribunales = await listarTribunales();
  } catch {
    tribunales = [];
  }

  // Agrupa por CIRCUITO JUDICIAL (no por tribunal individual).
  const circuitos = new Map<
    string,
    { nombre: string; estado: string; total: number }
  >();
  for (const t of tribunales) {
    const nombre = circunscripcionJudicial(t);
    const actual = circuitos.get(nombre);
    if (actual) {
      actual.total += 1;
    } else {
      circuitos.set(nombre, { nombre, estado: t.estado, total: 1 });
    }
  }
  const listaCircuitos = [...circuitos.values()].sort((a, b) =>
    a.nombre.localeCompare(b.nombre),
  );
  const total = tribunales.length;

  const jsonLd = {
    "@context": "https://schema.org",
    "@type": "CollectionPage",
    name: "Tribunales Penales de Venezuela por circuito judicial",
    description:
      "Directorio de circuitos judiciales penales venezolanos y sus tribunales.",
    url: "https://penalexve.com/tribunales",
    inLanguage: "es",
    mainEntity: {
      "@type": "ItemList",
      numberOfItems: listaCircuitos.length,
      itemListElement: listaCircuitos.map((c, i) => ({
        "@type": "ListItem",
        position: i + 1,
        name: c.nombre,
        url: `https://penalexve.com/tribunales/${slugEstado(c.estado)}`,
      })),
    },
  };

  return (
    <div className="min-h-screen bg-[#f8fafc]">
      <HeaderHome />
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
      />
      <main className="mx-auto max-w-5xl px-4 py-10">
        <nav className="text-xs text-slate-500">
          <Link href="/" className="text-[#031F4E]">
            Inicio
          </Link>{" "}
          · Tribunales
        </nav>

        <h1 className="mt-3 text-3xl font-extrabold leading-tight text-[#031F4E] sm:text-4xl">
          Tribunales penales de Venezuela: directorio por circuito judicial
        </h1>
        <p className="mt-4 max-w-3xl text-[15px] leading-relaxed text-slate-600">
          Ubica los tribunales penales de primera y segunda instancia de todo el
          país agrupados por <strong>circuito judicial</strong>: control, juicio,
          ejecución y apelación. Cada circuito enlaza a su directorio de
          tribunales con sede, municipio, función y ubicación en el mapa.
        </p>
        <p className="mt-2 text-sm text-slate-500">
          {total > 0
            ? `${total} tribunales penales registrados en ${listaCircuitos.length} circuitos judiciales.`
            : "Directorio de circuitos judiciales penales venezolanos."}
        </p>

        <section className="mt-8">
          <h2 className="text-lg font-bold text-[#031F4E]">
            Circuitos judiciales penales
          </h2>
          <div className="mt-4 grid grid-cols-1 gap-3 sm:grid-cols-2">
            {listaCircuitos.map((c) => (
              <Link
                key={c.nombre}
                href={`/tribunales/${slugEstado(c.estado)}`}
                className="group flex items-start justify-between gap-3 rounded-xl border border-slate-200 bg-white px-4 py-3 transition hover:border-[#C5A059] hover:shadow-sm"
              >
                <span>
                  <span className="block text-sm font-semibold text-[#031F4E] group-hover:text-[#9a7a34]">
                    {c.nombre}
                  </span>
                  <span className="block text-[11px] text-slate-500">
                    {c.estado}
                  </span>
                </span>
                <span className="shrink-0 rounded-full bg-[#f1f5f9] px-2.5 py-0.5 text-xs font-bold text-slate-500">
                  {c.total}
                </span>
              </Link>
            ))}
          </div>
        </section>

        <section className="mt-10">
          <h2 className="text-lg font-bold text-[#031F4E]">
            Mapa interactivo por circuito judicial
          </h2>
          <p className="mt-2 text-sm text-slate-600">
            Cada marcador representa un circuito judicial con el número de
            tribunales que lo integran. Toca un circuito para ver su lista de
            tribunales y su ubicación.
          </p>
          <div className="mt-4 overflow-hidden rounded-2xl border border-slate-200 bg-white">
            <MapaTribunales />
          </div>
        </section>

        <section className="mt-10 rounded-2xl border border-slate-200 bg-white p-6">
          <h2 className="text-lg font-bold text-[#031F4E]">
            ¿Qué tribunal conoce tu causa?
          </h2>
          <p className="mt-2 text-sm leading-relaxed text-slate-600">
            En el proceso penal venezolano, el tribunal de control conoce la fase
            de investigación y la intermedia; el tribunal de juicio, el
            juzgamiento; el de ejecución, la ejecución de la pena. Las Cámaras de
            Apelación conocen de los recursos. Usa este directorio por circuito
            judicial para identificar el tribunal competente.
          </p>
        </section>
      </main>
    </div>
  );
}
