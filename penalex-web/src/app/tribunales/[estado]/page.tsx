import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import HeaderHome from "../../../components/HeaderHome";
import {
  listarEstadosTribunales,
  listarTribunalesPorEstado,
  slugEstado,
  tituloEstado,
} from "../../../lib/tribunales";

export const dynamicParams = false;

export async function generateStaticParams() {
  try {
    const estados = await listarEstadosTribunales();
    return estados.map((estado) => ({ estado: slugEstado(estado) }));
  } catch {
    return [];
  }
}

async function resolverEstado(slug: string): Promise<string | null> {
  try {
    const estados = await listarEstadosTribunales();
    return estados.find((e) => slugEstado(e) === slug) ?? null;
  } catch {
    return null;
  }
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ estado: string }>;
}): Promise<Metadata> {
  const { estado: slug } = await params;
  const estado = await resolverEstado(slug);
  if (!estado) {
    return { title: "Estado no encontrado | Penalex VE" };
  }
  const nombre = tituloEstado(estado);
  const titulo = `Tribunales penales del estado ${nombre}: control, juicio y ejecución`;
  const desc = `Directorio de tribunales penales del estado ${estado}: tribunal de control, juicio, ejecución y apelación, con sede, municipio y función.`;
  return {
    title: titulo,
    description: desc,
    alternates: { canonical: `https://penalexve.com/tribunales/${slug}` },
    openGraph: {
      title: titulo,
      description: desc,
      url: `https://penalexve.com/tribunales/${slug}`,
      type: "website",
      locale: "es_VE",
      siteName: "Penalex VE",
    },
  };
}

export default async function TribunalesEstadoPage({
  params,
}: {
  params: Promise<{ estado: string }>;
}) {
  const { estado: slug } = await params;
  const estado = await resolverEstado(slug);
  if (!estado) notFound();

  let tribunales: Awaited<ReturnType<typeof listarTribunalesPorEstado>> = [];
  try {
    tribunales = await listarTribunalesPorEstado(estado);
  } catch {
    tribunales = [];
  }

  const porMunicipio = new Map<string, typeof tribunales>();
  for (const t of tribunales) {
    const m = t.municipio?.trim() || "Sin municipio";
    if (!porMunicipio.has(m)) porMunicipio.set(m, []);
    porMunicipio.get(m)!.push(t);
  }
  const municipios = [...porMunicipio.keys()].sort((a, b) => a.localeCompare(b));

  const jsonLd = {
    "@context": "https://schema.org",
    "@type": "ItemList",
    name: `Tribunales penales del estado ${estado}`,
    numberOfItems: tribunales.length,
    itemListElement: tribunales.slice(0, 100).map((t, i) => ({
      "@type": "ListItem",
      position: i + 1,
      name: t.nombre,
      item: {
        "@type": "GovernmentOffice",
        name: t.nombre,
        address: {
          "@type": "PostalAddress",
          addressRegion: estado,
          addressLocality: t.municipio || undefined,
          addressCountry: "VE",
        },
      },
    })),
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
          <Link href="/" className="text-[#031F4E]">Inicio</Link> ·{" "}
          <Link href="/tribunales" className="text-[#031F4E]">Tribunales</Link> ·{" "}
          {tituloEstado(estado)}
        </nav>

        <h1 className="mt-3 text-3xl font-extrabold leading-tight text-[#031F4E] sm:text-4xl">
          Tribunales penales del estado {tituloEstado(estado)}
        </h1>
        <p className="mt-4 max-w-3xl text-[15px] leading-relaxed text-slate-600">
          {tribunales.length > 0
            ? `${tribunales.length} tribunales penales (materia penal) en el estado ${tituloEstado(estado)}, organizados por municipio, con su función (control, juicio, ejecución o apelación) y sede.`
            : `Directorio de tribunales penales del estado ${tituloEstado(estado)}.`}
        </p>

        {municipios.map((municipio) => (
          <section key={municipio} className="mt-8">
            <h2 className="text-lg font-bold text-[#031F4E]">{municipio}</h2>
            <div className="mt-3 space-y-2">
              {porMunicipio.get(municipio)!.map((t) => (
                <article
                  key={t.id}
                  className="rounded-xl border border-slate-200 bg-white px-4 py-3"
                >
                  <div className="flex flex-wrap items-start justify-between gap-2">
                    <h3 className="text-sm font-semibold text-[#031F4E]">
                      {t.nombre}
                    </h3>
                    {t.funcion ? (
                      <span className="rounded-full bg-[#eef2f8] px-2.5 py-0.5 text-[10px] font-bold uppercase tracking-wide text-[#031F4E]">
                        {t.funcion}
                      </span>
                    ) : null}
                  </div>
                  <p className="mt-1 text-xs text-slate-500">
                    {[t.sede, t.municipio, t.parroquia, t.despacho]
                      .filter((x) => x && String(x).trim().length > 0)
                      .join(" · ")}
                  </p>
                  {t.latitud != null && t.longitud != null ? (
                    <div className="mt-2 flex flex-wrap items-center gap-2">
                      <span className="font-mono text-[10px] text-slate-400">
                        {t.latitud.toFixed(5)}, {t.longitud.toFixed(5)}
                      </span>
                      <a
                        href={`https://www.google.com/maps?q=${t.latitud},${t.longitud}`}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="rounded-md bg-[#0F172A] px-2.5 py-1 text-[11px] font-semibold text-white hover:bg-[#1e293b]"
                      >
                        📍 Cómo llegar (Google Maps)
                      </a>
                    </div>
                  ) : null}
                </article>
              ))}
            </div>
          </section>
        ))}

        <div className="mt-10">
          <Link
            href="/tribunales"
            className="text-sm font-semibold text-[#031F4E] underline"
          >
            ← Volver al directorio nacional de tribunales
          </Link>
        </div>
      </main>
    </div>
  );
}
