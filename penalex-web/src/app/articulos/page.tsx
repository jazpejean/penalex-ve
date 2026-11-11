import Image from "next/image";
import Link from "next/link";
import HeaderHome from "../../components/HeaderHome";

// Identidad Penalex: azul #031F4E + dorado #C5A059 (tema claro)
const AZUL = "#031F4E";

// Array de pruebas del listado de artículos del blog Nulidad Absoluta.
// El artículo de IA jurídica es de ejemplo (pendiente de publicación);
// el de nulidad como garantía enlaza al artículo real del blog.
const ARTICULOS: Array<{
  etiqueta: string;
  titulo: string;
  extracto: string;
  imagen: string;
  enlace: string;
}> = [
  {
    etiqueta: "Garantías · Libertad personal",
    titulo: "Alcabalas y puntos de control en Venezuela: tus derechos en un retén",
    extracto:
      "El derecho a grabar, los requisitos de un punto de control, la libertad personal y la prohibición del matraqueo. Guía práctica con COPP, Constitución y la Resolución 047391 y 109.",
    imagen: "/articulos/portada-alcabalas.png",
    enlace: "https://penalexve.com/articulos/alcabalas-puntos-de-control-venezuela.html",
  },
  {
    etiqueta: "Parte general · Tipicidad subjetiva",
    titulo: "¿Aceptar un riesgo te convierte en homicida? Dolo eventual en Venezuela",
    extracto:
      "Cuándo un accidente se convierte en homicidio intencional y cómo distinguirlo de la culpa consciente. Con citas textuales del TSJ y la ruta procesal para defenderse.",
    imagen: "/articulos/portada-dolo-eventual.png",
    enlace: "https://penalexve.com/articulos/dolo-eventual-venezuela.html",
  },
  {
    etiqueta: "Tecnología · Análisis",
    titulo: "IA para abogados penalistas en Venezuela: usos y límites en 2026",
    extracto:
      "Qué tareas penales puede apoyar la inteligencia artificial, cómo revisar sus resultados y qué límites tener presentes en Venezuela, con fundamento en las garantías del proceso.",
    imagen: "/articulos/portada-ia.png",
    enlace: "https://penalexve.com/articulos/ia-para-abogados-penalistas-en-venezuela-usos-y-limites-en-2026.html",
  },
  {
    etiqueta: "Garantías · Derechos fundamentales",
    titulo: "La nulidad como garantía: por qué el proceso debe respetar la ley",
    extracto:
      "La nulidad procesal no es un tecnicismo: es la última barrera frente al ejercicio arbitrario de la acción penal. Un análisis sobre su fundamento constitucional.",
    imagen: "/articulos/portada-nulidad.png",
    enlace: "https://penalexve.com/articulos/la-nulidad-como-garantia.html",
  },
];

export default function ArticulosPage() {
  return (
    <>
      {/* Navbar: header estándar responsivo (menú + sesión) */}
      <HeaderHome />

      <main className="flex-1">
        {/* Hero: cabecera del blog */}
        <section className="bg-[#F8F9FA]">
          <div className="mx-auto max-w-4xl px-4 py-16 text-center">
            <p className="text-xs font-bold uppercase tracking-[0.3em] text-[#C5A059]">
              Análisis y doctrina
            </p>
            <h1 className="serif mt-5 text-5xl font-bold text-[#031F4E]">
              Nulidad Absoluta
            </h1>
            <p className="mx-auto mt-5 max-w-2xl text-lg leading-relaxed text-[#4B5563]">
              Análisis del derecho procesal penal venezolano: la nulidad como
              garantía, la doctrina y la jurisprudencia.
            </p>
          </div>
        </section>

        {/* Grid de artículos */}
        <section className="mx-auto max-w-7xl px-4 py-14">
          <div className="grid grid-cols-1 gap-8 md:grid-cols-3">
            {ARTICULOS.map((a) => (
              <Link
                key={a.titulo}
                href={a.enlace}
                target="_blank"
                rel="noopener noreferrer"
                className="group overflow-hidden rounded-2xl border border-gray-100 bg-white shadow-sm transition-all hover:shadow-xl"
              >
                {/* Imagen superior */}
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img
                  src={a.imagen}
                  alt={a.titulo}
                  className="h-56 w-full object-cover transition-transform duration-300 group-hover:scale-[1.03]"
                />
                <div className="p-6">
                  {/* Etiqueta dorada */}
                  <span className="text-xs font-bold uppercase tracking-wide text-[#C5A059]">
                    {a.etiqueta}
                  </span>
                  {/* Título en serif */}
                  <h2 className="serif mt-3 text-xl font-bold leading-snug text-[#031F4E] group-hover:text-[#C5A059]">
                    {a.titulo}
                  </h2>
                  {/* Extracto */}
                  <p className="mt-3 text-sm leading-relaxed text-[#4B5563]">
                    {a.extracto}
                  </p>
                  {/* Botón final */}
                  <span className="mt-5 inline-flex items-center gap-2 rounded-lg bg-[#031F4E] px-4 py-2.5 text-sm font-semibold text-white transition-colors group-hover:bg-[#C5A059] group-hover:text-[#0F172A]">
                    Leer artículo
                    <svg viewBox="0 0 20 20" className="h-4 w-4" fill="currentColor" aria-hidden="true">
                      <path fillRule="evenodd" d="M7.21 14.77a.75.75 0 0 1 .02-1.06L11.17 10 7.23 6.29a.75.75 0 1 1 1.04-1.08l4.5 4.25a.75.75 0 0 1 0 1.08l-4.5 4.25a.75.75 0 0 1-1.06-.02z" clipRule="evenodd" />
                    </svg>
                  </span>
                </div>
              </Link>
            ))}
          </div>
        </section>
      </main>

      {/* Footer institucional (mismo del sitio) */}
      <footer className="border-t-4 border-[#C5A059] bg-[#0B1120]">
        <div className="border-b border-[#1E293B]">
          <div className="mx-auto flex max-w-6xl flex-wrap items-center justify-between gap-4 px-4 py-6">
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
              Blog jurídico del proceso penal venezolano
              <span className="h-px w-10 bg-[#C5A059]/40" />
            </div>
          </div>
        </div>
        <div className="mx-auto grid max-w-6xl gap-10 px-4 py-12 md:grid-cols-[1.4fr_1fr_1fr]">
          <div>
            <p className="max-w-xs text-sm leading-relaxed text-slate-400">
              Nulidad Absoluta es el blog jurídico de Penalex VE: análisis del
              proceso penal venezolano, la nulidad como garantía, doctrina y
              jurisprudencia para jueces, abogados y estudiantes.
            </p>
          </div>
          <div>
            <div className="text-xs font-bold uppercase tracking-[0.2em] text-[#C5A059]">
              Plataforma
            </div>
            <ul className="mt-4 space-y-2.5 text-sm">
              <li>
                <Link href="/" className="text-slate-400 transition hover:text-white">
                  Penalex VE
                </Link>
              </li>
              <li>
                <Link href="/login" className="text-slate-400 transition hover:text-white">
                  Iniciar sesión
                </Link>
              </li>
              <li>
                <Link href="/leyes" className="text-slate-400 transition hover:text-white">
                  Legislación Penal
                </Link>
              </li>
            </ul>
          </div>
          <div>
            <div className="text-xs font-bold uppercase tracking-[0.2em] text-[#C5A059]">
              Blog
            </div>
            <ul className="mt-4 space-y-2.5 text-sm">
              <li>
                <Link href="/articulos" className="text-slate-400 transition hover:text-white">
                  Artículos
                </Link>
              </li>
              <li>
                <Link href="/" className="text-slate-400 transition hover:text-white">
                  Inicio
                </Link>
              </li>
            </ul>
          </div>
        </div>
        <div className="border-t border-[#1E293B]">
          <div className="mx-auto max-w-6xl px-4 py-5">
            <div className="flex flex-wrap items-center justify-between gap-3">
              <span className="text-[11px] text-slate-600">
                © {new Date().getFullYear()} Penalex VE · Nulidad Absoluta
              </span>
              <span className="text-[11px] text-slate-600">
                Blog de análisis; no sustituye el criterio judicial.
              </span>
            </div>
          </div>
        </div>
      </footer>
    </>
  );
}