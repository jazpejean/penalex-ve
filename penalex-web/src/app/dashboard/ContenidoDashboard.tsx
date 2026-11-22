"use client";

// Panel del usuario en la web. Recibe las sentencias recientes ya resueltas en
// el servidor para no cargar el corpus en el navegador.
import Link from "next/link";
import { useEffect, useState } from "react";
import { cerrarSesion, escucharAuth } from "../../lib/firebase";
import type { SentenciaResumen } from "./types";

const NOMBRES_SALAS: Record<string, string> = {
  scp: "Sala de Casación Penal del Tribunal Supremo de Justicia",
  scon: "Sala Constitucional del Tribunal Supremo de Justicia",
  scs: "Sala de Casación Social del Tribunal Supremo de Justicia",
  sca: "Sala Político-Administrativa del Tribunal Supremo de Justicia",
  scc: "Sala de Casación Civil del Tribunal Supremo de Justicia",
  se: "Sala Electoral del Tribunal Supremo de Justicia",
};

function nombreSala(codigo: string): string {
  return (
    NOMBRES_SALAS[(codigo || "").toLowerCase()] ??
    "Tribunal Supremo de Justicia de Venezuela"
  );
}

const HERRAMIENTAS = [
  {
    href: "/sentencias",
    titulo: "Jurisprudencia",
    detalle: "55.208 sentencias del TSJ con extracto y texto completo.",
    icono: "⚖️",
    etiqueta: "Web",
    web: true,
  },
  {
    href: "/leyes",
    titulo: "Biblioteca legal",
    detalle: "53 leyes penales y 6.416 artículos, con búsqueda por número o tema.",
    icono: "📚",
    etiqueta: "Web",
    web: true,
  },
  {
    href: "/tribunales",
    titulo: "Tribunales",
    detalle: "867 tribunales por circuito, con foto y enlace a Google Maps.",
    icono: "🗺️",
    etiqueta: "Web",
    web: true,
  },
  {
    href: "/dosimetria",
    titulo: "Dosimetría penal",
    detalle: "Pena individualizada con los artículos 37, 74, 77 y 80 del Código Penal.",
    icono: "🧮",
    etiqueta: "Web",
    web: true,
  },
  {
    href: "/prescripcion",
    titulo: "Prescripción",
    detalle: "Cálculo de la prescripción de la acción y de la pena (arts. 108 y 112).",
    icono: "⏳",
    etiqueta: "Web",
    web: true,
  },
  {
    href: "/lapsos",
    titulo: "Lapsos procesales",
    detalle: "Días hábiles, audiencias y vencimientos del proceso penal.",
    icono: "📅",
    etiqueta: "Web",
    web: true,
  },
  {
    href: "/buscar",
    titulo: "Búsqueda semántica",
    detalle: "Encuentra criterios por significado, no solo por palabra exacta.",
    icono: "🔎",
    etiqueta: "Web",
    web: true,
  },
  {
    href: "/articulos",
    titulo: "Análisis y doctrina",
    detalle: "Nulidad, dolo eventual, IA jurídica y alcabalas explicados.",
    icono: "📝",
    etiqueta: "Web",
    web: true,
  },
  {
    href: "#app",
    titulo: "Detector de vicios",
    detalle: "21 vicios procesales con norma, gravedad y acción procesal.",
    icono: "🛡️",
    etiqueta: "App",
    web: false,
  },
  {
    href: "#app",
    titulo: "Asistente Ulpiano",
    detalle: "Chat jurídico con RAG sobre jurisprudencia y leyes, citando fuentes.",
    icono: "🤖",
    etiqueta: "App",
    web: false,
  },
  {
    href: "#app",
    titulo: "Redactor de escritos",
    detalle: "Escritos forenses sobre el expediente, con editor de documentos.",
    icono: "✍️",
    etiqueta: "App",
    web: false,
  },
  {
    href: "#app",
    titulo: "Escáner con visión",
    detalle: "Lee autos y sentencias desde la foto, sin OCR impreciso.",
    icono: "📷",
    etiqueta: "App",
    web: false,
  },
  {
    href: "#app",
    titulo: "Quiz de carrera judicial",
    detalle: "Formación gamificada con rangos y certificado de ascenso.",
    icono: "🎓",
    etiqueta: "App",
    web: false,
  },
];

const ARTICULOS = [
  {
    href: "/articulos/alcabalas-puntos-de-control-venezuela",
    titulo: "Alcabalas y puntos de control en Venezuela",
    detalle: "El derecho a grabar, los requisitos de un punto de control y la prohibición del matraqueo.",
  },
  {
    href: "/articulos/dolo-eventual-venezuela",
    titulo: "¿Aceptar un riesgo te convierte en homicida?",
    detalle: "Cuándo un accidente se convierte en homicidio intencional y cómo distinguirlo.",
  },
  {
    href: "/articulos/ia-para-abogados-penalistas-en-venezuela-usos-y-limites-en-2026",
    titulo: "IA para abogados penalistas en Venezuela",
    detalle: "Qué tareas penales puede apoyar la inteligencia artificial y qué límites tiene.",
  },
  {
    href: "/articulos/la-nulidad-como-garantia",
    titulo: "La nulidad como garantía",
    detalle: "Por qué el proceso debe respetar la ley: la última barrera frente a la arbitrariedad.",
  },
];

export default function ContenidoDashboard({
  recientes,
}: {
  recientes: SentenciaResumen[];
}) {
  const [email, setEmail] = useState<string | null>(null);
  const [nombre, setNombre] = useState<string | null>(null);

  useEffect(() => {
    return escucharAuth((u) => {
      if (!u) {
        setEmail(null);
        setNombre(null);
        return;
      }
      setEmail(u.email);
      setNombre(
        u.displayName?.trim() || (u.email ? u.email.split("@")[0] : null),
      );
    });
  }, []);

  const saludo = nombre ? `Hola, ${nombre}` : "Hola";

  return (
    <main className="mx-auto max-w-6xl px-4 py-10">
      {/* Hero */}
      <div className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <p className="text-xs font-bold uppercase tracking-[0.22em] text-[#9a7a34]">
            Panel profesional
          </p>
          <h1 className="mt-2 font-serif text-3xl font-bold text-[#031F4E] sm:text-4xl">
            {saludo}
          </h1>
          <p className="mt-2 max-w-2xl text-sm text-slate-500">
            Tu centro de trabajo jurídico: consulta jurisprudencia, busca en el
            corpus legal, ubica tribunales y calcula penas desde un solo lugar.
          </p>
        </div>
        <Link
          href="/sentencias"
          className="rounded-lg bg-[#031F4E] px-4 py-2.5 text-sm font-semibold text-white hover:bg-[#06305f]"
        >
          Buscar jurisprudencia
        </Link>
      </div>

      {/* Métricas */}
      <div className="mt-8 grid grid-cols-2 gap-3 sm:grid-cols-4">
        {[
          { v: "55.208", l: "Sentencias" },
          { v: "53", l: "Leyes" },
          { v: "6.416", l: "Artículos" },
          { v: "867", l: "Tribunales" },
        ].map((m) => (
          <div
            key={m.l}
            className="rounded-xl border border-slate-200 bg-white px-4 py-3"
          >
            <div className="text-2xl font-extrabold text-[#031F4E]">{m.v}</div>
            <div className="mt-1 text-[11px] font-semibold uppercase tracking-wide text-slate-500">
              {m.l}
            </div>
          </div>
        ))}
      </div>

      {/* Herramientas */}
      <section className="mt-10">
        <div className="flex items-end justify-between gap-3">
          <h2 className="text-lg font-bold text-[#031F4E]">Herramientas</h2>
          <span className="text-xs text-slate-500">
            Todo el ecosistema en la web
          </span>
        </div>
        <div className="mt-4 grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {HERRAMIENTAS.map((h) => (
            <Link
              key={h.href}
              href={h.href}
              className="group flex flex-col rounded-2xl border border-slate-200 bg-white p-5 transition hover:border-[#C5A059] hover:shadow-sm"
            >
              <div className="flex items-start justify-between">
                <span className="text-2xl">{h.icono}</span>
                <span
                  className={
                    h.web
                      ? "rounded-full bg-[#f1f5f9] px-2.5 py-0.5 text-[10px] font-bold uppercase tracking-wide text-slate-500"
                      : "rounded-full bg-[#FBF2DD] px-2.5 py-0.5 text-[10px] font-bold uppercase tracking-wide text-[#9a7a34]"
                  }
                >
                  {h.etiqueta}
                </span>
              </div>
              <div className="mt-3 text-base font-bold text-[#031F4E] group-hover:text-[#9a7a34]">
                {h.titulo}
              </div>
              <p className="mt-1 flex-1 text-sm leading-relaxed text-slate-500">
                {h.detalle}
              </p>
              <span className="mt-3 text-xs font-bold text-[#9a7a34]">
                {h.web ? "Abrir →" : "Descargar app →"}
              </span>
            </Link>
          ))}

          <div className="flex flex-col rounded-2xl border border-dashed border-slate-300 bg-white/60 p-5">
            <div className="flex items-start justify-between">
              <span className="text-2xl">🛡️</span>
              <span className="rounded-full bg-slate-100 px-2.5 py-0.5 text-[10px] font-bold uppercase tracking-wide text-slate-400">
                Próximamente
              </span>
            </div>
            <div className="mt-3 text-base font-bold text-slate-500">
              Detector de vicios
            </div>
            <p className="mt-1 flex-1 text-sm leading-relaxed text-slate-400">
              21 vicios procesales con norma, gravedad y acción. Disponible hoy
              en la app móvil.
            </p>
          </div>
        </div>
      </section>

      {/* Sentencias recientes */}
      <section className="mt-12">
        <div className="flex items-end justify-between gap-3">
          <h2 className="text-lg font-bold text-[#031F4E]">
            Sentencias recientes
          </h2>
          <Link
            href="/sentencias"
            className="text-xs font-bold text-[#9a7a34] hover:underline"
          >
            Ver todas →
          </Link>
        </div>
        <div className="mt-4 divide-y divide-slate-200 rounded-2xl border border-slate-200 bg-white">
          {recientes.length === 0 ? (
            <p className="p-5 text-sm text-slate-500">
              No se pudieron cargar las sentencias recientes.
            </p>
          ) : (
            recientes.map((s) => (
              <article key={s.slug} className="p-5">
                <div className="flex flex-wrap items-start justify-between gap-3">
                  <div className="min-w-0">
                    <p className="font-semibold text-[#031F4E]">
                      {s.num} · {nombreSala(s.sala)}
                    </p>
                    <p className="mt-0.5 text-xs text-slate-500">
                      {s.fecha}
                      {s.ponente ? ` · ${s.ponente}` : ""}
                    </p>
                  </div>
                  {s.jurisprudencia ? (
                    <span className="rounded-full bg-[#C5A059] px-2.5 py-0.5 text-[10px] font-bold uppercase text-white">
                      Vinculante
                    </span>
                  ) : null}
                </div>
                {s.extracto ? (
                  <p className="mt-2 line-clamp-2 text-sm leading-relaxed text-slate-600">
                    {s.extracto}
                  </p>
                ) : null}
                <div className="mt-3 flex items-center gap-3">
                  <Link
                    href={`/sentencias/${s.slug}`}
                    className="rounded-md bg-[#031F4E] px-3 py-1.5 text-xs font-semibold text-white hover:bg-[#06305f]"
                  >
                    Abrir sentencia
                  </Link>
                  <Link
                    href={`/sentencias/${s.slug}`}
                    className="text-xs font-semibold text-[#9a7a34] hover:underline"
                  >
                    Leer resumen
                  </Link>
                </div>
              </article>
            ))
          )}
        </div>
      </section>

      {/* Análisis */}
      <section className="mt-12">
        <div className="flex items-end justify-between gap-3">
          <h2 className="text-lg font-bold text-[#031F4E]">
            Análisis y doctrina
          </h2>
          <Link
            href="/articulos"
            className="text-xs font-bold text-[#9a7a34] hover:underline"
          >
            Ver todos →
          </Link>
        </div>
        <div className="mt-4 grid grid-cols-1 gap-4 sm:grid-cols-2">
          {ARTICULOS.map((a) => (
            <Link
              key={a.href}
              href={a.href}
              className="group rounded-2xl border border-slate-200 bg-white p-5 transition hover:border-[#C5A059]"
            >
              <div className="text-sm font-bold text-[#031F4E] group-hover:text-[#9a7a34]">
                {a.titulo}
              </div>
              <p className="mt-1 text-sm leading-relaxed text-slate-500">
                {a.detalle}
              </p>
              <span className="mt-2 inline-block text-xs font-bold text-[#9a7a34]">
                Leer artículo →
              </span>
            </Link>
          ))}
        </div>
      </section>

      {/* Cuenta */}
      <section id="app" className="mt-12 grid grid-cols-1 gap-4 sm:grid-cols-2">
        <div className="rounded-2xl border border-slate-200 bg-white p-5">
          <h2 className="text-sm font-bold text-[#031F4E]">Tu cuenta</h2>
          <p className="mt-2 text-sm text-slate-500">
            {email
              ? `Sesión iniciada como ${email}. Es la misma cuenta que usas en la app móvil.`
              : "Sesión iniciada."}
          </p>
          <button
            onClick={() => cerrarSesion()}
            className="mt-4 rounded-md border border-slate-200 px-3 py-2 text-sm font-medium text-slate-600 hover:bg-slate-50"
          >
            Cerrar sesión
          </button>
        </div>
        <div className="rounded-2xl border border-slate-200 bg-white p-5">
          <h2 className="text-sm font-bold text-[#031F4E]">App móvil</h2>
          <p className="mt-2 text-sm text-slate-500">
            El detector de vicios, el redactor y el escáner con IA están en la
            app Android. La web cubre la consulta y el cálculo.
          </p>
          <Link
            href="/"
            className="mt-4 inline-block text-sm font-semibold text-[#9a7a34] hover:underline"
          >
            Volver al inicio →
          </Link>
        </div>
      </section>
    </main>
  );
}
