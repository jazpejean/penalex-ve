"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { escucharAuth, cerrarSesion } from "../lib/firebase";

/** Header del home: menú (visible en móvil con hamburguesa) y estado real
 *  de la sesión. En móvil: logo + hamburguesa (las acciones de sesión viven
 *  dentro del menú desplegable para no saturar la barra). */
export default function HeaderHome() {
  const [user, setUser] = useState<{ email: string | null } | null>(null);
  const [menuAbierto, setMenuAbierto] = useState(false);

  useEffect(() => {
    return escucharAuth((u) => {
      setUser(u ? { email: u.email } : null);
    });
  }, []);

  // Cierra el menú al navegar y bloquea el scroll de fondo cuando está abierto.
  const cerrarMenu = () => setMenuAbierto(false);
  useEffect(() => {
    document.body.style.overflow = menuAbierto ? "hidden" : "";
    return () => {
      document.body.style.overflow = "";
    };
  }, [menuAbierto]);

  const cerrar = async () => {
    await cerrarSesion();
    setUser(null);
    cerrarMenu();
  };

  const NAV_PRINCIPAL = [
    { href: "/sentencias", label: "Jurisprudencias" },
    { href: "/leyes", label: "Leyes" },
    { href: "/articulos", label: "Blog · Nulidad Absoluta" },
  ];

  return (
    <header className="sticky top-0 z-40 border-b border-[#e2e8f0] bg-white/95 backdrop-blur">
      <div className="mx-auto flex max-w-6xl items-center justify-between px-4 py-2.5">
        <Link href="/" className="flex items-center" onClick={cerrarMenu}>
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img
            src="/producto/logo-horizontal.png"
            alt="Penalex VE"
            className="h-12 w-auto object-contain sm:h-14"
          />
        </Link>

        {/* Menú principal: visible en pantallas medianas y grandes */}
        <nav className="hidden items-center gap-1 md:flex" aria-label="Menú principal">
          {NAV_PRINCIPAL.map((i) => (
            <Link
              key={i.href}
              href={i.href}
              className="rounded-md px-3 py-2 text-sm font-medium text-slate-600 hover:bg-[#f1f5f9] hover:text-[#031F4E]"
            >
              {i.label}
            </Link>
          ))}
        </nav>

        {/* Acciones de sesión: solo en pantallas grandes (en móvil van en el menú) */}
        <div className="hidden items-center gap-2 md:flex">
          {user ? (
            <>
              <span className="max-w-[180px] truncate text-xs text-slate-500">
                {user.email}
              </span>
              <button
                onClick={cerrar}
                className="rounded-md border border-[#e2e8f0] px-3 py-2 text-sm font-medium text-slate-600 hover:bg-[#f1f5f9] hover:text-[#031F4E]"
              >
                Salir
              </button>
            </>
          ) : (
            <>
              <Link
                href="/login"
                className="rounded-md border border-[#e2e8f0] px-3 py-2 text-sm font-medium text-slate-600 hover:bg-[#f1f5f9] hover:text-[#031F4E]"
              >
                Iniciar sesión
              </Link>
              <Link
                href="/login?modo=registro"
                className="rounded-md bg-[#031F4E] px-3 py-2 text-sm font-semibold text-white hover:bg-[#06305f]"
              >
                Crear cuenta
              </Link>
            </>
          )}
        </div>

        {/* Hamburguesa (móvil): abre el menú */}
        <button
          onClick={() => setMenuAbierto(!menuAbierto)}
          aria-label={menuAbierto ? "Cerrar menú" : "Abrir menú"}
          aria-expanded={menuAbierto}
          className="rounded-md p-2 text-[#031F4E] hover:bg-[#f1f5f9] md:hidden"
        >
          <svg viewBox="0 0 24 24" className="h-6 w-6" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
            {menuAbierto ? (
              <path d="M6 6l12 12M18 6L6 18" />
            ) : (
              <path d="M4 7h16M4 12h16M4 17h16" />
            )}
          </svg>
        </button>
      </div>

      {/* Menú móvil desplegable: navegación + acciones de sesión */}
      {menuAbierto && (
        <nav className="border-t border-[#e2e8f0] bg-white px-4 pb-5 pt-3 md:hidden" aria-label="Menú móvil">
          <div className="flex flex-col gap-1">
            {NAV_PRINCIPAL.map((i) => (
              <Link
                key={i.href}
                href={i.href}
                onClick={cerrarMenu}
                className="rounded-md px-3 py-3 text-sm font-medium text-slate-700 hover:bg-[#f1f5f9] hover:text-[#031F4E]"
              >
                {i.label}
              </Link>
            ))}
          </div>
          <div className="mt-4 border-t border-[#e2e8f0] pt-4">
            {user ? (
              <div className="flex flex-col gap-2">
                <span className="truncate px-3 text-xs text-slate-500">{user.email}</span>
                <button
                  onClick={cerrar}
                  className="rounded-md border border-[#e2e8f0] px-3 py-3 text-sm font-medium text-slate-600 hover:bg-[#f1f5f9] hover:text-[#031F4E]"
                >
                  Salir
                </button>
              </div>
            ) : (
              <div className="flex flex-col gap-2">
                <Link
                  href="/login"
                  onClick={cerrarMenu}
                  className="rounded-md border border-[#e2e8f0] px-3 py-3 text-center text-sm font-medium text-slate-600 hover:bg-[#f1f5f9] hover:text-[#031F4E]"
                >
                  Iniciar sesión
                </Link>
                <Link
                  href="/login?modo=registro"
                  onClick={cerrarMenu}
                  className="rounded-md bg-[#031F4E] px-3 py-3 text-center text-sm font-semibold text-white hover:bg-[#06305f]"
                >
                  Crear cuenta
                </Link>
              </div>
            )}
          </div>
        </nav>
      )}
    </header>
  );
}