"use client";

import { Suspense, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { loginGoogle, loginEmail, registrarEmail, cerrarSesion } from "../../lib/firebase";
import Icono from "../../components/Icono";

// Azul institucional del logo de Penalex
const AZUL = "#031F4E";
const DORADO = "#C5A059";

// Traducción de errores Firebase — igual que _getFirebaseErrorMessage en la app
// Incluye códigos modernos (auth/invalid-credential, auth/invalid-login-credentials)
// y los clásicos (user-not-found, wrong-password).
function _firebaseError(mensaje: string): string {
  const e = mensaje.toLowerCase();
  if (e.includes("email-already-in-use"))
    return "Este correo ya está registrado. Intenta iniciar sesión o usa otra cuenta.";
  if (e.includes("invalid-email")) return "El correo electrónico no es válido.";
  if (e.includes("weak-password"))
    return "La contraseña es muy débil. Debe tener al menos 6 caracteres.";
  if (e.includes("network-request-failed") || e.includes("network_error"))
    return "Error de conexión. Revisa tu internet.";
  if (e.includes("user-not-found") || e.includes("invalid-credential") || e.includes("invalid-login-credentials") || e.includes("wrong-password") || e.includes("invalid_password"))
    return "Correo o contraseña incorrectos. Verifica tus datos e intenta de nuevo.";
  if (e.includes("too-many-requests"))
    return "Demasiados intentos. Espera un momento e intenta nuevamente.";
  if (e.includes("unauthorized-domain") || e.includes("unauthorized_domain"))
    return "Este dominio no está autorizado. Contacta al soporte de Penalex.";
  if (e.includes("operation-not-allowed") || e.includes("operation_not_allowed"))
    return "El inicio de sesión con correo no está habilitado. Usa Google o contacta al soporte.";
  if (e.includes("popup-blocked") || e.includes("popup_closed"))
    return "El popup se cerró o fue bloqueado. Permite ventanas emergentes e intenta de nuevo.";
  if (e.includes("cancelled") || e.includes("canceled") || e.includes("popup-closed"))
    return "Inicio de sesión cancelado.";
  return "Ocurrió un error inesperado. Intenta de nuevo.";
}

// Logo Google (SVG oficial de 4 colores, igual que el asset de la app)
function GoogleLogo() {
  return (
    <svg viewBox="0 0 24 24" className="h-6 w-6" aria-hidden>
      <path
        fill="#4285F4"
        d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92a5.06 5.06 0 0 1-2.2 3.32v2.77h3.57c2.08-1.92 3.27-4.74 3.27-8.1z"
      />
      <path
        fill="#34A853"
        d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84A11 11 0 0 0 12 23z"
      />
      <path
        fill="#FBBC05"
        d="M5.84 14.1a6.6 6.6 0 0 1 0-4.2V7.06H2.18a11 11 0 0 0 0 9.88l3.66-2.84z"
      />
      <path
        fill="#EA4335"
        d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15A11 11 0 0 0 12 1 11 11 0 0 0 2.18 7.06l3.66 2.84C6.71 7.31 9.14 5.38 12 5.38z"
      />
    </svg>
  );
}

function LoginContent() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const modoInicial =
    searchParams.get("modo") === "registro" ? "registro" : "login";
  const [modo, setModo] = useState<"login" | "registro">(modoInicial);

  // Login: correo + contraseña
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [verPassword, setVerPassword] = useState(false);

  // Registro: nombre + correo + contraseña + confirmación
  const [nombre, setNombre] = useState("");
  const [confirmar, setConfirmar] = useState("");
  const [verConfirmar, setVerConfirmar] = useState(false);

  const [error, setError] = useState("");
  const [cargando, setCargando] = useState(false);
  const [dialogo, setDialogo] = useState<{ titulo: string; mensaje: string; esError: boolean } | null>(null);

  async function conGoogle() {
    setCargando(true);
    setError("");
    try {
      const user = await loginGoogle();
      if (user && !user.emailVerified) {
        await cerrarSesion();
        setDialogo({
          titulo: "Correo no verificado",
          mensaje:
            "Tu cuenta de Google no tiene el correo verificado. Por favor, verifícalo antes de continuar.",
          esError: true,
        });
        return;
      }
      router.push("/");
    } catch (e) {
      setError(_firebaseError(e instanceof Error ? e.message : String(e)));
    } finally {
      setCargando(false);
    }
  }

  async function conEmail(e: React.FormEvent) {
    e.preventDefault();
    setError("");
    if (modo === "login") {
      if (!email.trim() || !email.includes("@")) {
        setError("Ingresa un correo electrónico válido");
        return;
      }
      if (!password) {
        setError("La contraseña no puede estar vacía");
        return;
      }
      setCargando(true);
      try {
        const user = await loginEmail(email.trim(), password);
        if (user && !user.emailVerified) {
          await cerrarSesion();
          setDialogo({
            titulo: "Correo no verificado",
            mensaje:
              "Por favor, revisa tu bandeja de entrada (y spam) para verificar tu correo antes de iniciar sesión.",
            esError: true,
          });
          return;
        }
        router.push("/");
      } catch (err) {
        setError(_firebaseError(err instanceof Error ? err.message : String(err)));
      } finally {
        setCargando(false);
      }
      return;
    }
    // Registro — validaciones iguales a _register() de la app
    if (!nombre.trim()) {
      setDialogo({ titulo: "Nombre requerido", mensaje: "Por favor, ingresa tu nombre completo.", esError: true });
      return;
    }
    if (!email.trim() || !email.includes("@")) {
      setDialogo({ titulo: "Correo inválido", mensaje: "Ingresa un correo electrónico válido.", esError: true });
      return;
    }
    if (!password) {
      setDialogo({ titulo: "Contraseña requerida", mensaje: "La contraseña no puede estar vacía.", esError: true });
      return;
    }
    if (password.length < 6) {
      setDialogo({ titulo: "Contraseña débil", mensaje: "La contraseña debe tener al menos 6 caracteres.", esError: true });
      return;
    }
    if (password !== confirmar) {
      setDialogo({ titulo: "Contraseñas no coinciden", mensaje: "Las contraseñas ingresadas no son iguales.", esError: true });
      return;
    }
    setCargando(true);
    try {
      await registrarEmail(email.trim(), password, nombre.trim());
      setDialogo({
        titulo: "¡Registro exitoso!",
        mensaje: "Revisa tu correo para verificar tu cuenta.",
        esError: false,
      });
    } catch (err) {
      setDialogo({
        titulo: "Error al registrarse",
        mensaje: _firebaseError(err instanceof Error ? err.message : String(err)),
        esError: true,
      });
    } finally {
      setCargando(false);
    }
  }

  const campoCls =
    "w-full rounded-xl border border-slate-300 bg-white py-3 pl-11 pr-11 text-base text-[#031F4E] placeholder:text-slate-400 focus:border-[#031F4E] focus:outline-none focus:ring-1 focus:ring-[#031F4E]/20";
  const labelCls = "mb-1 block text-[13px] font-medium text-[#031F4E]";
  const iconoCampo =
    "pointer-events-none absolute left-4 top-1/2 -translate-y-1/2 text-[#031F4E]/60";

  return (
    <main
      className="flex min-h-screen flex-col justify-center bg-[#F1F5F9] px-6"
      style={{ paddingTop: 24, paddingBottom: 30 }}
    >
      <div className="mx-auto w-full max-w-[420px]">
        {/* Volver al inicio */}
        <div className="mb-8 flex justify-center">
          <button
            onClick={() => router.push("/")}
            className="group flex items-center gap-2 rounded-full border border-[#e2e8f0] bg-white px-5 py-2 text-sm font-medium text-[#031F4E] hover:bg-[#031F4E] hover:text-white"
          >
            <Icono nombre="flecha" size={14} className="rotate-180 transition group-hover:-translate-x-0.5" />
            Volver al inicio
          </button>
        </div>
        {/* Marca institucional: logo vertical real */}
        <div className="flex justify-center">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img
            src="/producto/logo-vertical.png"
            alt="Penalex VE"
            className="h-36 w-auto object-contain"
          />
        </div>
        <div className="mt-6 text-center">
          <p className="text-lg text-[#475569]">
            {modo === "login"
              ? "Inicia sesión para continuar"
              : "Regístrate para comenzar"}
          </p>
        </div>

        {/* Error (igual al contenedor rojo de la app) */}
        {error && (
          <div className="mt-6 flex items-center gap-3 rounded-xl border border-red-200 bg-red-50 p-3">
            <Icono nombre="fecha" size={16} className="shrink-0 text-red-500" />
            <span className="text-sm text-red-500">{error}</span>
          </div>
        )}

        <form onSubmit={conEmail} className="mt-10 space-y-4">
          {modo === "registro" && (
            <div>
              <label className={labelCls}>Nombre completo</label>
              <div className="relative">
                <span className={iconoCampo}>
                  <Icono nombre="usuario" size={18} />
                </span>
                <input
                  value={nombre}
                  onChange={(e) => setNombre(e.target.value)}
                  placeholder="Nombre completo"
                  className={campoCls}
                />
              </div>
            </div>
          )}

          <div>
            <label className={labelCls}>Correo electrónico</label>
            <div className="relative">
              <span className={iconoCampo}>
                <Icono nombre="correo" size={18} />
              </span>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="Correo electrónico"
                className={campoCls}
              />
            </div>
          </div>

          <div>
            <label className={labelCls}>Contraseña</label>
            <div className="relative">
              <span className={iconoCampo}>
                <Icono nombre="candado" size={18} />
              </span>
              <input
                type={verPassword ? "text" : "password"}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="Contraseña"
                className={campoCls}
              />
              <button
                type="button"
                onClick={() => setVerPassword(!verPassword)}
                className="absolute right-4 top-1/2 -translate-y-1/2 text-[#031F4E]/50 hover:text-[#031F4E]"
                aria-label={verPassword ? "Ocultar contraseña" : "Mostrar contraseña"}
              >
                <Icono nombre={verPassword ? "ojo" : "ojo-off"} size={19} />
              </button>
            </div>
          </div>

          {modo === "registro" && (
            <div>
              <label className={labelCls}>Confirmar contraseña</label>
              <div className="relative">
                <span className={iconoCampo}>
                  <Icono nombre="candado" size={18} />
                </span>
                <input
                  type={verConfirmar ? "text" : "password"}
                  value={confirmar}
                  onChange={(e) => setConfirmar(e.target.value)}
                  placeholder="Confirmar contraseña"
                  className={campoCls}
                />
                <button
                  type="button"
                  onClick={() => setVerConfirmar(!verConfirmar)}
                  className="absolute right-4 top-1/2 -translate-y-1/2 text-[#031F4E]/50 hover:text-[#031F4E]"
                  aria-label={verConfirmar ? "Ocultar contraseña" : "Mostrar contraseña"}
                >
                  <Icono nombre={verConfirmar ? "ojo" : "ojo-off"} size={19} />
                </button>
              </div>
            </div>
          )}

          {modo === "login" && (
            <div className="flex justify-end">
              <button
                type="button"
                onClick={() => setDialogo({ titulo: "Recuperar contraseña", mensaje: "La recuperación de contraseña estará disponible en la próxima versión de la web. Por el momento, usa la app móvil.", esError: false })}
                className="text-sm font-medium text-[#031F4E] hover:underline"
              >
                ¿Olvidaste tu contraseña?
              </button>
            </div>
          )}

          <div className="pt-4">
            {cargando ? (
              <div className="flex h-[52px] items-center justify-center">
                <span className="h-6 w-6 animate-spin rounded-full border-2 border-[#031F4E]/20 border-t-[#031F4E]" />
              </div>
            ) : (
              <button
                type="submit"
                className="h-[52px] w-full rounded-xl bg-[#031F4E] text-base font-bold tracking-wide text-[#C5A059] hover:bg-[#06305f]"
              >
                {modo === "login" ? "INICIAR SESIÓN" : "CREAR CUENTA"}
              </button>
            )}
          </div>
        </form>

        {modo === "login" && (
          <div className="mt-4">
            <button
              onClick={conGoogle}
              disabled={cargando}
              className="flex h-[52px] w-full items-center justify-center gap-3 rounded-xl border-[1.5px] border-[#C5A059]/85 bg-white text-base text-[#031F4E] hover:bg-slate-50 disabled:opacity-60"
            >
              <GoogleLogo />
              Iniciar con Google
            </button>
          </div>
        )}

        <div className="mt-4 text-center">
          <span className="text-sm text-[#475569]">
            {modo === "login" ? "¿No tienes cuenta? " : "¿Ya tienes cuenta? "}
          </span>
          <button
            onClick={() => setModo(modo === "login" ? "registro" : "login")}
            className="text-sm font-bold text-[#031F4E] hover:underline"
          >
            {modo === "login" ? "Regístrate" : "Inicia sesión"}
          </button>
        </div>
      </div>

      {/* Diálogo (AlertDialog de la app) */}
      {dialogo && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
          <div className="w-full max-w-sm rounded-2xl bg-white p-6 shadow-xl">
            <h3 className="text-base font-bold text-[#031F4E]">{dialogo.titulo}</h3>
            <p className={`mt-2 text-sm ${dialogo.esError ? "text-red-500" : "text-[#475569]"}`}>
              {dialogo.mensaje}
            </p>
            <div className="mt-5 flex justify-end">
              <button
                onClick={() => {
                  setDialogo(null);
                  if (!dialogo.esError && modo === "registro") setModo("login");
                }}
                className="rounded-md text-sm font-semibold text-[#031F4E] hover:underline"
              >
                Entendido
              </button>
            </div>
          </div>
        </div>
      )}
    </main>
  );
}

export default function LoginPage() {
  return (
    <Suspense fallback={null}>
      <LoginContent />
    </Suspense>
  );
}