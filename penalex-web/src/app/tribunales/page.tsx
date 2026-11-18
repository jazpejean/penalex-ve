import type { Metadata } from "next";
import Link from "next/link";
import HeaderHome from "../../components/HeaderHome";
import MapaTribunales from "../../components/MapaTribunales";

export const metadata: Metadata = {
  title: "Tribunales Penales de Venezuela: busca tu tribunal por circuito y estado",
  description:
    "Busca cualquier tribunal penal de Venezuela por nombre, sede, municipio o circuito judicial. Fichas con foto, coordenadas y enlace a Google Maps.",
  alternates: { canonical: "https://penalexve.com/tribunales" },
  openGraph: {
    title: "Tribunales Penales de Venezuela: busca tu tribunal",
    description:
      "Directorio buscable de tribunales penales venezolanos con foto, sede y cómo llegar.",
    url: "https://penalexve.com/tribunales",
    type: "website",
    locale: "es_VE",
    siteName: "Penalex VE",
  },
  twitter: {
    card: "summary",
    title: "Tribunales Penales de Venezuela: busca tu tribunal",
    description: "Busca por nombre, sede, municipio o circuito judicial.",
  },
};

const jsonLd = {
  "@context": "https://schema.org",
  "@type": "CollectionPage",
  name: "Tribunales Penales de Venezuela",
  description:
    "Directorio buscable de tribunales penales venezolanos por circuito judicial, con foto y ubicación.",
  url: "https://penalexve.com/tribunales",
  inLanguage: "es",
  isPartOf: { "@type": "WebSite", name: "Penalex VE", url: "https://penalexve.com" },
};

export default function TribunalesPage() {
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
          Tribunales penales de Venezuela: busca el tuyo
        </h1>
        <p className="mt-4 max-w-3xl text-[15px] leading-relaxed text-slate-600">
          Escribe el nombre del tribunal, la sede, el municipio o el circuito
          judicial (por ejemplo, <strong>Los Teques</strong>,{" "}
          <strong>Barlovento</strong> o <strong>Miranda</strong>) y verás la lista
          de resultados con su foto, función, coordenadas y el enlace directo a
          Google Maps.
        </p>
        <p className="mt-2 text-sm text-slate-500">
          867 tribunales penales registrados en todo el país.
        </p>

        <section className="mt-6">
          <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white">
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
            Apelación conocen de los recursos. Usa el buscador para ubicar el
            tribunal por su circuito judicial.
          </p>
        </section>

        <section className="mt-6">
          <h2 className="text-sm font-bold text-[#031F4E]">
            Directorio por estado
          </h2>
          <p className="mt-1 text-xs text-slate-500">
            También puedes explorar el directorio completo de un estado.
          </p>
          <div className="mt-3 flex flex-wrap gap-2">
            {[
              ["Distrito Capital", "distrito-capital"],
              ["Miranda", "bolivariano-de-miranda"],
              ["Zulia", "zulia"],
              ["Carabobo", "carabobo"],
              ["Aragua", "aragua"],
              ["Lara", "lara"],
              ["Anzoátegui", "anzoategui"],
              ["Táchira", "tachira"],
            ].map(([nombre, slug]) => (
              <Link
                key={slug}
                href={`/tribunales/${slug}`}
                className="rounded-full border border-slate-200 bg-white px-3 py-1.5 text-xs font-semibold text-[#031F4E] hover:border-[#C5A059]"
              >
                {nombre}
              </Link>
            ))}
          </div>
        </section>
      </main>
    </div>
  );
}
