"use client";

import Link from "next/link";

// El header no ofrece sesión: la web es pública mientras las herramientas
// que la requieran no estén en producción.
export default function Navbar() {
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
          <Link
            href="/dosimetria"
            className="rounded-md bg-[#031f4e] px-4 py-1.5 text-sm font-semibold text-white hover:bg-[#06305f]"
          >
            Dosimetría
          </Link>
        </div>
      </div>
    </header>
  );
}