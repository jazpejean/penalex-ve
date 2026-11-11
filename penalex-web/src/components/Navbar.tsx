"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { escucharAuth, cerrarSesion } from "../lib/firebase";

// Las herramientas no se exponen en el header: el acceso es solo con sesión
// (RequiereSesion redirige a /login), igual que en la app.
export default function Navbar() {
  const [user, setUser] = useState<{ email: string | null } | null>(null);

  useEffect(() => {
    return escucharAuth((u) => {
      setUser(u ? { email: u.email } : null);
    });
  }, []);

  return (
    <header className="sticky top-0 z-40 border-b border-[#e2e8f0] bg-white/90 backdrop-blur">
      <div className="mx-auto flex max-w-6xl items-center justify-between px-4 py-3">
        {/* Marca: logo horizontal real */}
        <Link href="/" className="flex items-center">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img
            src="/producto/logo-horizontal.png"
            alt="Penalex VE"
            className="h-14 w-auto object-contain"
          />
        </Link>

        {/* Acción */}
        <div className="flex items-center gap-2">
          {user ? (
            <>
              <span className="hidden text-xs text-slate-500 md:block">
                {user.email}
              </span>
              <button
                onClick={() => cerrarSesion()}
                className="rounded-md border border-[#e2e8f0] px-3 py-1.5 text-sm text-slate-600 hover:bg-[#f1f5f9]"
              >
                Salir
              </button>
            </>
          ) : (
            <Link
              href="/login"
              className="rounded-md bg-[#031f4e] px-4 py-1.5 text-sm font-semibold text-white hover:bg-[#06305f]"
            >
              Iniciar sesión
            </Link>
          )}
        </div>
      </div>
    </header>
  );
}