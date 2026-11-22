"use client";

// Dashboard del usuario en la web: mismo punto de entrada que la app móvil.
// Solo accesible con sesión (RequiereSesion redirige a /login).
import Link from "next/link";
import { useEffect, useState } from "react";
import HeaderHome from "../../components/HeaderHome";
import RequiereSesion from "../../components/RequiereSesion";
import { escucharAuth } from "../../lib/firebase";

type Usuario = { email: string | null; nombre: string | null };

const HERRAMIENTAS = [
  {
    href: "/jurisprudencia",
    titulo: "Jurisprudencia",
    detalle: "55.208 sentencias del TSJ con extracto y texto completo.",
    icono: "⚖️",
    destacada: false,
  },
  {
    href: "/leyes",
    titulo: "Biblioteca legal",
    detalle: "53 leyes penales y 6.416 artículos con búsqueda.",
    icono: "📚",
    destacada: false,
  },
  {
    href: "/tribunales",
    titulo: "Tribunales",
    detalle: "867 tribunales por circuito, con mapa y Google Maps.",
    icono: "🗺️",
    destacada: false,
  },
  {
    href: "/dosimetria",
    titulo: "Dosimetría",
    detalle: "Cálculo de pena con los artículos 37, 74, 77 y 80.",
    icono: "🧮",
    destacada: false,
  },
  {
    href: "/articulos",
    titulo: "Análisis y doctrina",
    detalle: "Artículos sobre nulidad, dolo eventual, IA y alcabalas.",
    icono: "📝",
    destacada: false,
  },
];

export default function DashboardPage() {
  return (
    <RequiereSesion>
      <ContenidoDashboard />
    </RequiereSesion>
  );
}

function ContenidoDashboard() {
  const [usuario, setUsuario] = useState<Usuario>({ email: null, nombre: null });

  useEffect(() => {
    return escucharAuth((u) => {
      if (!u) {
        setUsuario({ email: null, nombre: null });
        return;
      }
      const nombre =
        u.displayName?.trim() ||
        (u.email ? u.email.split("@")[0] : null);
      setUsuario({ email: u.email, nombre });
    });
  }, []);

  const saludo = usuario.nombre ? `Hola, ${usuario.nombre}` : "Hola";

  return (
    <div className="min-h-screen bg-[#f8fafc]">
      <HeaderHome />
      <main className="mx-auto max-w-6xl px-4 py-10">
        {/* Encabezado */}
        <div className="flex flex-wrap items-end justify-between gap-4">
          <div>
            <p className="text-xs font-bold uppercase tracking-[0.2em] text-[#9a7a34]">
              Panel profesional
            </p>
            <h1 className="mt-2 font-serif text-3xl font-bold text-[#031F4E] sm:text-4xl">
              {saludo}
            </h1>
            <p className="mt-2 text-sm text-slate-500">
              Tu centro de trabajo: jurisprudencia, leyes, tribunales y cálculo
              de penas en un solo lugar.
            </p>
          </div>
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
              <div className="text-2xl font-extrabold text-[#031F4E]">
                {m.v}
              </div>
              <div className="mt-1 text-[11px] font-semibold uppercase tracking-wide text-slate-500">
                {m.l}
              </div>
            </div>
          ))}
        </div>

        {/* Herramientas */}
        <section className="mt-10">
          <h2 className="text-lg font-bold text-[#031F4E]">
            Herramientas
          </h2>
          <div className="mt-4 grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {HERRAMIENTAS.map((h) => (
              <Link
                key={h.href}
                href={h.href}
                className="group rounded-2xl border border-slate-200 bg-white p-5 transition hover:border-[#C5A059] hover:shadow-sm"
              >
                <div className="text-2xl">{h.icono}</div>
                <div className="mt-3 text-base font-bold text-[#031F4E] group-hover:text-[#9a7a34]">
                  {h.titulo}
                </div>
                <p className="mt-1 text-sm leading-relaxed text-slate-500">
                  {h.detalle}
                </p>
                <span className="mt-3 inline-block text-xs font-bold text-[#9a7a34]">
                  Abrir →
                </span>
              </Link>
            ))}

            {/* Próximamente */}
            <div className="rounded-2xl border border-dashed border-slate-300 bg-white/60 p-5">
              <div className="text-2xl">🛡️</div>
              <div className="mt-3 text-base font-bold text-slate-500">
                Detector de vicios
              </div>
              <p className="mt-1 text-sm leading-relaxed text-slate-400">
                Disponible en la app móvil. La versión web está en camino.
              </p>
              <span className="mt-3 inline-block text-xs font-bold text-slate-400">
                Próximamente
              </span>
            </div>
          </div>
        </section>

        {/* Cuenta */}
        <section className="mt-10 rounded-2xl border border-slate-200 bg-white p-5">
          <h2 className="text-sm font-bold text-[#031F4E]">Tu cuenta</h2>
          <p className="mt-2 text-sm text-slate-500">
            {usuario.email
              ? `Sesión iniciada como ${usuario.email}. La misma cuenta que usas en la app móvil.`
              : "Sesión iniciada."}
          </p>
        </section>
      </main>
    </div>
  );
}
