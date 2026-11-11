"use client";

// Guard de sesión: las herramientas (/leyes, /dosimetria) solo son accesibles
// con la cuenta de Firebase, como en la app. Sin sesión → /login.
import { useEffect, useState, type ReactNode } from "react";
import { useRouter } from "next/navigation";
import { escucharAuth } from "../lib/firebase";

export default function RequiereSesion({ children }: { children: ReactNode }) {
  const router = useRouter();
  const [estado, setEstado] = useState<"cargando" | "sin" | "con">("cargando");

  useEffect(() => {
    const desuscribir = escucharAuth((u) => {
      setEstado(u ? "con" : "sin");
    });
    return desuscribir;
  }, []);

  useEffect(() => {
    if (estado === "sin") {
      router.replace("/login");
    }
  }, [estado, router]);

  if (estado === "con") {
    return <>{children}</>;
  }

  return (
    <div className="flex min-h-[60vh] items-center justify-center">
      <div className="text-center">
        <div className="mx-auto h-8 w-8 animate-spin rounded-full border-2 border-[#e2e8f0] border-t-[#031f4e]" />
        <p className="mt-4 text-sm text-slate-500">
          {estado === "sin"
            ? "Redirigiendo al inicio de sesión…"
            : "Verificando sesión…"}
        </p>
      </div>
    </div>
  );
}