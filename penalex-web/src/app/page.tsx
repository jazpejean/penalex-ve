import Link from "next/link";
import type { Metadata } from "next";
import Icono, { type NombreIcono } from "../components/Icono";
import HeaderHome from "../components/HeaderHome";

// Home en construcción: noindex selectivo (solo /sentencias/** se indexa).
export const metadata: Metadata = {
  robots: { index: false, follow: false },
};

const AZUL = "#031F4E";

// Catálogo real de Penalex (nombres y descripciones de la app)
const PRODUCTOS: Array<{
  num: string;
  icono: NombreIcono;
  title: string;
  tagline: string;
  description: string;
  cta: string;
  enWeb: boolean;
}> = [
  {
    num: "01",
    icono: "estrella",
    title: "Ulpiano · Asistente Legal",
    tagline: "Tu equipo de estrategas legales",
    description:
      "Consulta, redacta, analiza y calcula con IA. Detecta vicios procesales en autos y sentencias, y responde siempre con fuentes verificables: artículos de ley y sentencias del TSJ.",
    cta: "Hablar con Ulpiano",
    enWeb: false,
  },
  {
    num: "02",
    icono: "documento",
    title: "Redactor de Documentos",
    tagline: "Escritos con estilo forense",
    description:
      "Genera escritos legales profesionales (demandas, recursos, solicitudes) con asistencia guiada de IA. De 2 a 3 horas de trabajo a 15 minutos.",
    cta: "Redactar un escrito",
    enWeb: false,
  },
  {
    num: "03",
    icono: "calculadora",
    title: "Dosimetría Penal",
    tagline: "Cálculo técnico de penas",
    description:
      "Pena individualizada, concurso de delitos (Arts. 86, 87, 88 y 98 CP), admisión de hechos (Art. 375 COPP) y cómputo de lapsos con fecha de cumplimiento. Disponible en la web.",
    cta: "Iniciar cálculo",
    enWeb: true,
  },
  {
    num: "04",
    icono: "libro",
    title: "Legislación Penal",
    tagline: "Marco legal venezolano",
    description:
      "Constitución, Código Penal, COPP y leyes especiales íntegros, verificados contra fuentes oficiales. Disponible en la web.",
    cta: "Explorar leyes",
    enWeb: true,
  },
  {
    num: "05",
    icono: "balanza",
    title: "Jurisprudencia",
    tagline: "Sentencias y doctrina",
    description:
      "Consulta fallos relevantes de los tribunales venezolanos para fundamentar cada decisión con rigor.",
    cta: "Ver jurisprudencia",
    enWeb: false,
  },
  {
    num: "06",
    icono: "reloj",
    title: "Calculadora de Prescripción",
    tagline: "Arts. 108 y 112 CP",
    description:
      "Calcula el término de prescripción de la acción penal o de la pena con el texto exacto del Código Penal: término, fecha exacta y días restantes. Cálculo determinístico, sin IA.",
    cta: "Calcular prescripción",
    enWeb: false,
  },
  {
    num: "07",
    icono: "calendario",
    title: "Agenda Judicial",
    tagline: "Organiza tus audiencias",
    description:
      "Registro de actos procesales y recordatorios, con calculadora de lapsos procesales.",
    cta: "Ir a mi agenda",
    enWeb: false,
  },
  {
    num: "08",
    icono: "chat",
    title: "Glosario Jurídico",
    tagline: "Definiciones claras",
    description:
      "Aclara términos y conceptos del derecho penal venezolano.",
    cta: "Ver glosario",
    enWeb: false,
  },
];

export default function HomePage() {
  return (
    <>
      {/* Header: menú + sesión real (cliente) */}
      <HeaderHome />

      <main className="flex-1">
        {/* Hero: texto editorial + mockup real del producto */}
        <section className="relative overflow-hidden border-b border-[#e2e8f0]">
          <div
            className="pointer-events-none absolute inset-0"
            style={{
              background:
                "radial-gradient(800px 420px at 85% -10%, rgba(197,160,89,0.14), transparent), radial-gradient(700px 400px at 0% 110%, rgba(3,31,78,0.06), transparent)",
            }}
          />
          <div className="relative mx-auto grid max-w-6xl items-center gap-12 px-4 py-16 lg:grid-cols-[1.1fr_0.9fr] lg:py-24">
            {/* Texto */}
            <div>
              <p className="flex items-center gap-2 text-xs font-semibold uppercase tracking-[0.25em] text-[#9a7a34]">
                <span className="h-px w-8 bg-[#9a7a34]" />
                Plataforma del derecho penal venezolano
              </p>
              <h1 className="serif mt-6 text-4xl font-bold leading-[1.08] text-[#031F4E] sm:text-5xl lg:text-6xl">
                El derecho penal venezolano, con{" "}
                <span className="relative whitespace-nowrap">
                  <span className="text-[#9a7a34]">precisión de ley</span>
                  <span className="absolute -bottom-1 left-0 h-[3px] w-full bg-[#C5A059]/70" />
                </span>
              </h1>
              <p className="mt-7 max-w-xl text-lg leading-relaxed text-slate-600">
                Asistencia de IA con fuentes verificables, dosimetría penal
                técnica, redacción de escritos y corpus legal completo en una
                sola plataforma para la autoridad judicial, el abogado y el
                estudiante de derecho.
              </p>
              <div className="mt-9 flex flex-wrap items-center gap-3">
                <Link
                  href="/sentencias"
                  className="rounded-lg bg-[#031F4E] px-6 py-3 text-sm font-bold text-white hover:bg-[#06305f]"
                >
                  Buscar sentencias
                </Link>
                <Link
                  href="/leyes"
                  className="rounded-md border border-[#e2e8f0] bg-white px-7 py-3.5 text-sm font-semibold text-[#031F4E] hover:bg-[#f1f5f9]"
                >
                  Explorar leyes
                </Link>
              </div>
              <div className="mt-10 grid max-w-lg grid-cols-3 divide-x divide-[#e2e8f0] border-y border-[#e2e8f0] py-4">
                {[
                  { v: "53", t: "leyes íntegras" },
                  { v: "6.416", t: "artículos indexados" },
                  { v: "100%", t: "fuentes verificadas" },
                ].map((m) => (
                  <div key={m.t} className="px-4 first:pl-0">
                    <div className="serif text-2xl font-bold text-[#031F4E]">
                      {m.v}
                    </div>
                    <div className="mt-0.5 text-[11px] uppercase tracking-wide text-slate-500">
                      {m.t}
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Captura real de la app */}
            <div className="relative mx-auto w-full max-w-[320px]">
              <div className="absolute -inset-6 rounded-[36px] bg-gradient-to-br from-[#C5A059]/25 to-transparent blur-2xl" />
              <div className="relative overflow-hidden rounded-[30px] border-[6px] border-[#0F172A] shadow-2xl shadow-[#031F4E]/30">
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img
                  src="/producto/app-inicio.png"
                  alt="Penalex VE en Android"
                  className="block w-full"
                />
              </div>
            </div>
          </div>
        </section>

        {/* Ulpiano — feature destacada (fiel a la tarjeta estrella de la app) */}
        <section className="mx-auto max-w-6xl px-4 py-16">
          <div
            className="rounded-[24px] border-2 border-[#C5A059] p-6 sm:p-10"
            style={{
              background: "linear-gradient(135deg, #1E293B 0%, #0F172A 100%)",
              boxShadow: "0 20px 60px rgba(3,31,78,0.22)",
            }}
          >
            <div className="flex flex-col gap-8 lg:flex-row lg:items-center">
              <div className="flex-1">
                <div className="flex items-center gap-3">
                  <span className="rounded-md bg-[#C5A059] px-2.5 py-1 text-[11px] font-bold uppercase tracking-wider text-[#0F172A]">
                    Nuevo
                  </span>
                  <span className="text-sm font-semibold text-[#C5A059]">
                    Ulpiano · Asistente Legal
                  </span>
                </div>
                <h2 className="serif mt-4 text-3xl font-bold text-white sm:text-4xl">
                  Tu equipo de estrategas legales
                </h2>
                <p className="mt-4 max-w-2xl text-base leading-relaxed text-slate-300">
                  Pregúntale a Ulpiano: detecta si quieres consultar, redactar,
                  analizar, calcular o citar, y responde siempre con fuentes
                  verificables: artículos de ley y sentencias del TSJ.
                </p>
                <ul className="mt-6 grid gap-3 text-sm text-slate-200 sm:grid-cols-2">
                  {[
                    { i: "lupa" as NombreIcono, t: "Consulta con citas verificables" },
                    { i: "editar" as NombreIcono, t: "Redacta escritos con estilo forense" },
                    { i: "documento" as NombreIcono, t: "Analiza autos y detecta vicios procesales" },
                    { i: "calculadora" as NombreIcono, t: "Calcula dosimetría y lapsos" },
                  ].map((f) => (
                    <li key={f.t} className="flex items-center gap-3">
                      <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg border border-[#C5A059]/40 bg-[#C5A059]/15 text-[#C5A059]">
                        <Icono nombre={f.i} size={15} />
                      </span>
                      {f.t}
                    </li>
                  ))}
                </ul>
              </div>
              <div className="lg:w-[340px]">
                <Link
                  href="/sentencias"
                  className="flex w-full items-center justify-center gap-3 rounded-xl bg-[#C5A059] py-4 text-base font-bold text-[#0F172A] transition hover:bg-[#E9C86A]"
                >
                  Hablar con Ulpiano
                  <Icono nombre="chat" size={19} />
                </Link>
                <p className="mt-3 text-center text-[11px] text-slate-400">
                  Disponible en la app móvil · próximamente en la web
                </p>
              </div>
            </div>
          </div>
        </section>

        {/* En producción: capturas reales de la web */}
        <section className="border-t border-[#e2e8f0] bg-white py-16">
          <div className="mx-auto max-w-6xl px-4">
            <div className="max-w-2xl">
              <p className="text-xs font-semibold uppercase tracking-[0.2em] text-[#9a7a34]">
                En producción
              </p>
              <h2 className="serif mt-4 text-3xl font-bold text-[#031F4E] sm:text-4xl">
                El buscador, las leyes y los tribunales, hoy
              </h2>
              <p className="mt-4 text-base leading-relaxed text-slate-600">
                Cuatro herramientas abiertas al público, con datos reales del
                país. No son maquetas: son capturas de la plataforma en vivo.
              </p>
            </div>
            <div className="mt-8 grid gap-4 sm:grid-cols-2">
              {[
                {
                  img: "/producto/web-sentencias.png",
                  t: "Buscador de jurisprudencia",
                  d: "Más de 55.000 sentencias, búsqueda semántica y filtros avanzados",
                  href: "/sentencias",
                },
                {
                  img: "/producto/web-leyes.png",
                  t: "Leyes",
                  d: "53 leyes íntegras y 6.416 artículos verificados",
                  href: "/leyes",
                },
                {
                  img: "/producto/web-tribunales.png",
                  t: "Tribunales",
                  d: "868 tribunales penales con mapa y circuito",
                  href: "/tribunales",
                },
                {
                  img: "/producto/web-blog.png",
                  t: "Blog · Nulidad Absoluta",
                  d: "Análisis escritos con el mismo RAG, con fuente",
                  href: "/articulos",
                },
              ].map((x) => (
                <Link
                  key={x.t}
                  href={x.href}
                  className="group overflow-hidden rounded-2xl border border-[#e2e8f0] bg-white shadow-sm transition hover:shadow-lg"
                >
                  {/* eslint-disable-next-line @next/next/no-img-element */}
                  <img
                    src={x.img}
                    alt={x.t}
                    className="h-48 w-full object-cover object-top"
                  />
                  <div className="p-4">
                    <div className="text-sm font-bold text-[#031F4E]">
                      {x.t}
                    </div>
                    <div className="mt-1 text-xs leading-relaxed text-slate-500">
                      {x.d}
                    </div>
                  </div>
                </Link>
              ))}
            </div>
          </div>
        </section>

        {/* Catálogo de productos */}
        <section className="border-t border-[#e2e8f0] py-16">
          <div className="mx-auto max-w-6xl px-4">
            <div className="max-w-2xl">
              <p className="text-xs font-semibold uppercase tracking-[0.2em] text-[#9a7a34]">
                Nuestros productos
              </p>
              <h2 className="serif mt-4 text-3xl font-bold text-[#031F4E] sm:text-4xl">
                Todo el arsenal jurídico en un solo ecosistema
              </h2>
              <p className="mt-4 text-slate-600">
                Doce herramientas profesionales. Las mismas de la app, con la
                misma cuenta y los mismos estándares de rigor.
              </p>
            </div>
            <div className="mt-10 grid gap-5 sm:grid-cols-2 lg:grid-cols-4">
              {PRODUCTOS.map((p) => (
                <div
                  key={p.num}
                  className="flex flex-col rounded-2xl border border-[#e2e8f0] bg-white p-6 transition hover:border-[#C5A059]/60 hover:shadow-lg hover:shadow-[#031F4E]/5"
                >
                  <div className="flex items-center justify-between">
                    <span className="serif text-xs font-bold text-[#9a7a34]/70">
                      {p.num}
                    </span>
                    <span className="flex h-10 w-10 items-center justify-center rounded-xl border border-[#C5A059]/40 bg-[#eef2f8] text-[#031F4E]">
                      <Icono nombre={p.icono} size={19} />
                    </span>
                  </div>
                  <h3 className="mt-4 text-[15px] font-bold leading-snug text-[#031F4E]">
                    {p.title}
                  </h3>
                  <p className="mt-1 text-[10px] font-semibold uppercase tracking-wide text-[#9a7a34]">
                    {p.tagline}
                  </p>
                  <p className="mt-3 flex-1 text-[13px] leading-relaxed text-slate-600">
                    {p.description}
                  </p>
                  <div className="mt-5 border-t border-[#e2e8f0] pt-4">
                    {p.enWeb ? (
                      <Link
                        href={p.num === "03" ? "/dosimetria" : "/leyes"}
                        className="text-xs font-bold text-[#031F4E] hover:text-[#9a7a34]"
                      >
                        {p.cta} →
                      </Link>
                    ) : (
                      <span className="text-[11px] font-medium text-slate-400">
                        En la app · próximamente en la web
                      </span>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* Rigor jurídico */}
        <section className="border-t border-[#e2e8f0] bg-white py-16">
          <div className="mx-auto grid max-w-6xl gap-10 px-4 md:grid-cols-2">
            <div>
              <p className="text-xs font-semibold uppercase tracking-[0.2em] text-[#9a7a34]">
                Rigor jurídico
              </p>
              <h2 className="serif mt-4 text-3xl font-bold text-[#031F4E]">
                Cálculos verificables, no aproximaciones
              </h2>
              <p className="mt-4 leading-relaxed text-slate-600">
                Cada pena se calcula con el método del término medio, las
                rebajas por ejecución y participación, el delito continuado, las
                atenuantes y agravantes, el concurso real o ideal con tope de 30
                años y la admisión de hechos, todo con su fundamento legal.
              </p>
            </div>
            <div className="rounded-2xl border border-[#e2e8f0] bg-[#fafcff] p-6">
              <div className="serif text-sm font-bold text-[#9a7a34]">
                Fundamentos aplicados
              </div>
              <ul className="mt-4 space-y-2.5 text-sm text-slate-700">
                {[
                  "Art. 37 CP · Término medio",
                  "Arts. 80 y 82 CP · Frustración y tentativa",
                  "Arts. 83 y 84 CP · Participación",
                  "Art. 99 CP · Delito continuado",
                  "Arts. 86, 87, 88 y 98 CP · Concurso",
                  "Art. 94 CP · Tope de 30 años",
                  "Art. 375 COPP · Admisión de hechos",
                  "Arts. 108 y 112 CP · Prescripción",
                ].map((a) => (
                  <li key={a} className="flex items-center gap-2.5">
                    <Icono nombre="gavel" size={12} className="shrink-0 text-[#9a7a34]" />
                    {a}
                  </li>
                ))}
              </ul>
            </div>
          </div>
        </section>

        {/* Mapa de Tribunales */}
        <section className="border-t border-[#e2e8f0] bg-white py-16">
          <div className="mx-auto max-w-6xl px-4">
            <p className="text-xs font-semibold uppercase tracking-[0.2em] text-[#9a7a34]">
              Catálogo oficial del TSJ
            </p>
            <h2 className="serif mt-4 text-3xl font-bold text-[#031F4E]">
              Mapa de Tribunales Penales
            </h2>
            <p className="mt-4 max-w-2xl leading-relaxed text-slate-600">
              Ubica los 868 tribunales penales de primera y segunda instancia
              de todo el país: control, juicio, ejecución y apelación, con su
              sede, estado y función exactos.
            </p>
            <div className="mt-8">
              <Link
                href="/tribunales"
                className="inline-flex items-center gap-2 rounded-md bg-[#031F4E] px-6 py-3 text-sm font-semibold text-white hover:bg-[#06305f]"
              >
                Abrir el mapa
                <Icono nombre="mapa" size={15} />
              </Link>
            </div>
          </div>
        </section>

        {/* Blog Nulidad Absoluta */}
        <section className="border-t border-[#e2e8f0] bg-[#fafcff] py-16">
          <div className="mx-auto grid max-w-6xl items-center gap-10 px-4 md:grid-cols-[1.2fr_0.8fr]">
            <div>
              <p className="text-xs font-semibold uppercase tracking-[0.2em] text-[#9a7a34]">
                Blog jurídico
              </p>
              <h2 className="serif mt-4 text-3xl font-bold text-[#031F4E]">
                Nulidad Absoluta
              </h2>
              <p className="mt-4 leading-relaxed text-slate-600">
                Doctrina y análisis del derecho procesal penal venezolano:
                nulidades como garantía, jurisprudencia y comentarios escritos
                para jueces, abogados y estudiantes.
              </p>
              <div className="mt-8">
                <Link
                  href="/articulos"
                  className="inline-flex items-center gap-2 rounded-md bg-[#031F4E] px-6 py-3 text-sm font-semibold text-white hover:bg-[#06305f]"
                >
                  Leer el blog
                  <Icono nombre="flecha" size={15} />
                </Link>
              </div>
            </div>
            <div className="rounded-2xl border border-[#e2e8f0] bg-white p-6 shadow-sm">
              <div className="flex items-center gap-2 border-b border-[#e2e8f0] pb-3">
                <span className="flex h-8 w-8 items-center justify-center rounded-md bg-[#eef2f8] text-[#031F4E]">
                  <Icono nombre="documento" size={15} />
                </span>
                <div>
                  <div className="text-sm font-bold text-[#031F4E]">
                    Nulidad Absoluta
                  </div>
                  <div className="text-[11px] text-slate-500">
                    penalexve.com/articulos
                  </div>
                </div>
              </div>
              <ul className="mt-3 space-y-3 text-sm text-slate-700">
                <li className="flex items-start gap-2">
                  <Icono nombre="gavel" size={12} className="mt-1 shrink-0 text-[#9a7a34]" />
                  ¿Qué es la nulidad absoluta en el proceso penal venezolano?
                </li>
                <li className="flex items-start gap-2">
                  <Icono nombre="gavel" size={12} className="mt-1 shrink-0 text-[#9a7a34]" />
                  La nulidad como garantía: por qué el proceso debe respetar la ley
                </li>
              </ul>
            </div>
          </div>
        </section>

        {/* CTA final */}
        <section className="relative overflow-hidden border-t border-[#e2e8f0]">
          <div
            className="pointer-events-none absolute inset-0"
            style={{
              background:
                "radial-gradient(600px 300px at 50% 0%, rgba(197,160,89,0.12), transparent)",
            }}
          />
          <div className="relative mx-auto max-w-6xl px-4 py-20 text-center">
            <h2 className="serif mx-auto max-w-3xl text-3xl font-bold text-[#031F4E] sm:text-4xl">
              Toma decisiones fundamentadas en la ley exacta
            </h2>
            <p className="mx-auto mt-4 max-w-xl text-slate-600">
              Crea tu cuenta profesional y accede a todas las herramientas con
              tu sesión de la app.
            </p>
            <div className="mt-8 flex flex-wrap items-center justify-center gap-3">
              <Link href="/sentencias" className="rounded-lg bg-[#031F4E] px-6 py-3 text-sm font-bold text-white hover:bg-[#06305f]">Buscar sentencias</Link>
              <Link
                href="/sentencias"
                className="rounded-md border border-[#e2e8f0] bg-white px-8 py-3.5 text-sm font-semibold text-[#031F4E] hover:bg-[#f1f5f9]"
              >
                Buscar sentencias
              </Link>
            </div>
          </div>
        </section>
      </main>

      {/* Footer institucional */}
      <footer className="border-t-4 border-[#C5A059] bg-[#0B1120]">
        {/* Franja superior de marca */}
        <div className="border-b border-[#1E293B]">
          <div className="mx-auto flex max-w-6xl flex-wrap items-center justify-between gap-4 px-4 py-6">
            {/* Logo real en contenedor blanco */}
            <span className="inline-flex items-center rounded-lg bg-white px-4 py-2 shadow-lg">
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img
                src="/producto/logo-horizontal.png"
                alt="Penalex VE"
                className="h-8 w-auto object-contain"
              />
            </span>
            <div className="flex items-center gap-3 text-[11px] uppercase tracking-widest text-[#C5A059]">
              <span className="h-px w-10 bg-[#C5A059]/40" />
              Derecho penal venezolano con precisión de ley
              <span className="h-px w-10 bg-[#C5A059]/40" />
            </div>
          </div>
        </div>

        {/* Columnas */}
        <div className="mx-auto grid max-w-6xl gap-10 px-4 py-12 md:grid-cols-[1.4fr_1fr_1fr_1.2fr]">
          {/* Marca */}
          <div>
            <p className="max-w-xs text-sm leading-relaxed text-slate-400">
              Plataforma profesional del derecho penal venezolano: dosimetría
              con fundamento legal, corpus legal verificado y asistencia de IA
              con fuentes citables. Para la autoridad judicial, el abogado y el
              estudiante.
            </p>
            <div className="mt-5 flex items-center gap-2 text-[11px] text-slate-500">
              <Icono nombre="candado" size={13} className="text-[#C5A059]" />
              Sesión única con tu cuenta de la app (Firebase)
            </div>
          </div>

          {/* Productos */}
          <div>
            <div className="text-xs font-bold uppercase tracking-[0.2em] text-[#C5A059]">
              Productos
            </div>
            <ul className="mt-4 space-y-2.5 text-sm">
              <li>
                <Link href="/sentencias" className="flex items-center gap-2 text-slate-400 hover:text-white">
                  <Icono nombre="estrella" size={13} className="shrink-0 text-[#C5A059]" />
                  Ulpiano · Asistente Legal
                </Link>
              </li>
              <li>
                <Link href="/dosimetria" className="flex items-center gap-2 text-slate-400 hover:text-white">
                  <Icono nombre="calculadora" size={13} className="shrink-0 text-[#C5A059]" />
                  Dosimetría Penal
                </Link>
              </li>
              <li>
                <Link href="/leyes" className="flex items-center gap-2 text-slate-400 hover:text-white">
                  <Icono nombre="libro" size={13} className="shrink-0 text-[#C5A059]" />
                  Legislación Penal
                </Link>
              </li>
              <li>
                <Link href="/tribunales" className="flex items-center gap-2 text-slate-400 hover:text-white">
                  <Icono nombre="mapa" size={13} className="shrink-0 text-[#C5A059]" />
                  Mapa de Tribunales
                </Link>
              </li>
              <li>
                <span className="flex items-center gap-2 text-slate-500">
                  <Icono nombre="documento" size={13} className="shrink-0 text-[#C5A059]" />
                  Redactor de Documentos
                </span>
              </li>
              <li>
                <span className="flex items-center gap-2 text-slate-500">
                  <Icono nombre="reloj" size={13} className="shrink-0 text-[#C5A059]" />
                  Calculadora de Prescripción
                </span>
              </li>
            </ul>
          </div>

          {/* Plataforma */}
          <div>
            <div className="text-xs font-bold uppercase tracking-[0.2em] text-[#C5A059]">
              Plataforma
            </div>
            <ul className="mt-4 space-y-2.5 text-sm text-slate-400">
              <li>
                <Link href="/sentencias" className="flex items-center gap-2 hover:text-white">
                  <Icono nombre="usuario" size={13} className="shrink-0 text-[#C5A059]" />
                  Buscar sentencias
                </Link>
              </li>
              <li>
                <Link href="/sentencias" className="flex items-center gap-2 hover:text-white">
                  <Icono nombre="correo" size={13} className="shrink-0 text-[#C5A059]" />
                  Buscar sentencias
                </Link>
              </li>
              <li>
                <Link href="/" className="flex items-center gap-2 hover:text-white">
                  <Icono nombre="gavel" size={13} className="shrink-0 text-[#C5A059]" />
                  Inicio
                </Link>
              </li>
              <li className="flex items-center gap-2 text-slate-500">
                <Icono nombre="balanza" size={13} className="shrink-0 text-[#C5A059]" />
                Jurisprudencia
              </li>
              <li className="flex items-center gap-2 text-slate-500">
                <Icono nombre="calendario" size={13} className="shrink-0 text-[#C5A059]" />
                Agenda Judicial
              </li>
            </ul>
          </div>

          {/* Blog + contacto */}
          <div>
            <div className="text-xs font-bold uppercase tracking-[0.2em] text-[#C5A059]">
              Blog jurídico
            </div>
            <a
              href="/articulos"
              className="group mt-4 block rounded-xl border border-[#1E293B] bg-[#0F172A] p-4 transition hover:border-[#C5A059]/50"
            >
              <div className="flex items-center justify-between">
                <span className="text-sm font-bold text-white group-hover:text-[#C5A059]">
                  Nulidad Absoluta
                </span>
                <Icono nombre="flecha" size={14} className="text-[#C5A059] transition group-hover:translate-x-0.5" />
              </div>
              <p className="mt-1.5 text-[11px] leading-relaxed text-slate-500">
                Doctrina y análisis del proceso penal venezolano.
              </p>
              <div className="mt-2 text-[10px] text-slate-600">
                penalexve.com/articulos
              </div>
            </a>
            <div className="mt-5 flex items-center gap-2 text-[11px] text-slate-500">
              <Icono nombre="chat" size={13} className="shrink-0 text-[#C5A059]" />
              Asistencia técnica en la app
            </div>
          </div>
        </div>

        {/* Aviso legal y copyright */}
        <div className="border-t border-[#1E293B]">
          <div className="mx-auto max-w-6xl px-4 py-5">
            <p className="text-[11px] leading-relaxed text-slate-600">
              Penalex VE es una herramienta de asistencia técnica para el
              cálculo de penas y la consulta de fuentes legales. Los resultados
              no sustituyen el criterio del juez ni el análisis del defensor.
              Leyes verificadas contra fuentes oficiales venezolanas.
            </p>
            <div className="mt-3 flex flex-wrap items-center justify-between gap-3">
              <span className="text-[11px] text-slate-600">
                © {new Date().getFullYear()} Penalex VE · Dosimetría Penal Venezolana
              </span>
              <span className="flex items-center gap-1.5 text-[11px] text-slate-600">
                <Icono nombre="gavel" size={11} className="text-[#C5A059]" />
                Caracas, Venezuela
              </span>
            </div>
          </div>
        </div>
      </footer>
    </>
  );
}