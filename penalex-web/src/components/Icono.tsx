// Iconografía institucional SVG — trazo fino, sin emojis.
// Usa currentColor para heredar el color del contexto.

export type NombreIcono =
  | "gavel"
  | "balanza"
  | "correo"
  | "candado"
  | "usuario"
  | "ojo"
  | "ojo-off"
  | "lupa"
  | "libro"
  | "calculadora"
  | "documento"
  | "editar"
  | "calendario"
  | "reloj"
  | "chat"
  | "escaneo"
  | "estrella"
  | "fecha"
  | "flecha"
  | "papelera"
  | "reiniciar"
  | "guardar"
  | "impresora"
  | "copiar"
  | "mapa";

export default function Icono({
  nombre,
  size = 20,
  className,
  strokeWidth = 1.7,
}: {
  nombre: NombreIcono;
  size?: number;
  className?: string;
  strokeWidth?: number;
}) {
  const s: React.CSSProperties = {
    width: size,
    height: size,
    color: "currentColor",
  };
  const line = {
    fill: "none",
    stroke: "currentColor",
    strokeWidth,
    strokeLinecap: "round" as const,
    strokeLinejoin: "round" as const,
  };

  switch (nombre) {
    case "gavel":
      // Martillo de juez (estilo Material, relleno)
      return (
        <svg viewBox="0 0 24 24" style={s} className={className} aria-hidden>
          <path
            fill="currentColor"
            d="M1 21h12v2H1v-2zM5.24 8.07l2.83-2.83L20.14 17.1l-2.83 2.83L5.24 8.07zM12.32 1l5.66 5.66-2.83 2.83-5.66-5.66L12.32 1zM3.83 9.48l5.66 5.66-2.83 2.83L1 12.31l2.83-2.83z"
          />
        </svg>
      );
    case "balanza":
      return (
        <svg viewBox="0 0 24 24" style={s} className={className} aria-hidden>
          <path
            fill="currentColor"
            d="M12 1 2 6v2h20V6L12 1zm-8 9h3v7H4v-7zm7 0h3v7h-3v-7zm6 0h3v7h-3v-7zM2 19h20v2H2v-2z"
          />
        </svg>
      );
    case "correo":
      return (
        <svg viewBox="0 0 24 24" style={s} className={className} aria-hidden>
          <rect x="2.5" y="5" width="19" height="14" rx="2" {...line} />
          <path d="M3 7.5l9 6.5 9-6.5" {...line} />
        </svg>
      );
    case "candado":
      return (
        <svg viewBox="0 0 24 24" style={s} className={className} aria-hidden>
          <rect x="4.5" y="10.5" width="15" height="10" rx="2" {...line} />
          <path d="M8 10.5V7a4 4 0 0 1 8 0v3.5" {...line} />
          <circle cx="12" cy="15.5" r="1.4" fill="currentColor" />
        </svg>
      );
    case "usuario":
      return (
        <svg viewBox="0 0 24 24" style={s} className={className} aria-hidden>
          <circle cx="12" cy="8" r="4" {...line} />
          <path d="M4.5 20.5c1-3.5 4-5 7.5-5s6.5 1.5 7.5 5" {...line} />
        </svg>
      );
    case "ojo":
      return (
        <svg viewBox="0 0 24 24" style={s} className={className} aria-hidden>
          <path d="M2.5 12S6 5.5 12 5.5 21.5 12 21.5 12 18 18.5 12 18.5 2.5 12 2.5 12z" {...line} />
          <circle cx="12" cy="12" r="3" {...line} />
        </svg>
      );
    case "ojo-off":
      return (
        <svg viewBox="0 0 24 24" style={s} className={className} aria-hidden>
          <path d="M4 4l16 16" {...line} />
          <path d="M10.6 6.1A10 10 0 0 1 12 6c6 0 9.5 6 9.5 6a17.5 17.5 0 0 1-2.4 3.2M6.6 6.9A16.8 16.8 0 0 0 2.5 12S6 18 12 18a9.7 9.7 0 0 0 4.4-1" {...line} />
          <path d="M9.9 9.9a3 3 0 0 0 4.2 4.2" {...line} />
        </svg>
      );
    case "lupa":
      return (
        <svg viewBox="0 0 24 24" style={s} className={className} aria-hidden>
          <circle cx="11" cy="11" r="7" {...line} />
          <path d="M21 21l-4.3-4.3" {...line} />
        </svg>
      );
    case "libro":
      return (
        <svg viewBox="0 0 24 24" style={s} className={className} aria-hidden>
          <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20" {...line} />
          <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z" {...line} />
        </svg>
      );
    case "calculadora":
      return (
        <svg viewBox="0 0 24 24" style={s} className={className} aria-hidden>
          <rect x="4.5" y="2.5" width="15" height="19" rx="2" {...line} />
          <rect x="7.5" y="5.5" width="9" height="4" rx="0.5" {...line} />
          <path d="M8 13h.01M12 13h.01M16 13h.01M8 17h.01M12 17h.01M16 17h.01" {...line} strokeWidth={2.2} />
        </svg>
      );
    case "documento":
      return (
        <svg viewBox="0 0 24 24" style={s} className={className} aria-hidden>
          <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" {...line} />
          <path d="M14 2v6h6" {...line} />
          <path d="M9 13h6M9 17h6" {...line} />
        </svg>
      );
    case "editar":
      return (
        <svg viewBox="0 0 24 24" style={s} className={className} aria-hidden>
          <path d="M11 4H5a2 2 0 0 0-2 2v13a2 2 0 0 0 2 2h13a2 2 0 0 0 2-2v-6" {...line} />
          <path d="M18.4 2.6a2.1 2.1 0 0 1 3 3L12 15l-4 1 1-4z" {...line} />
        </svg>
      );
    case "calendario":
      return (
        <svg viewBox="0 0 24 24" style={s} className={className} aria-hidden>
          <rect x="3" y="4.5" width="18" height="17" rx="2" {...line} />
          <path d="M16 2.5v4M8 2.5v4M3 10h18" {...line} />
        </svg>
      );
    case "reloj":
      return (
        <svg viewBox="0 0 24 24" style={s} className={className} aria-hidden>
          <circle cx="12" cy="12" r="9" {...line} />
          <path d="M12 7v5l3.5 2" {...line} />
        </svg>
      );
    case "chat":
      return (
        <svg viewBox="0 0 24 24" style={s} className={className} aria-hidden>
          <path d="M21 14.5a2 2 0 0 1-2 2H7.5L3 21V5.5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" {...line} />
          <path d="M8 10h8M8 13.5h5" {...line} />
        </svg>
      );
    case "escaneo":
      return (
        <svg viewBox="0 0 24 24" style={s} className={className} aria-hidden>
          <path d="M7 3H5a2 2 0 0 0-2 2v2M17 3h2a2 2 0 0 1 2 2v2M21 17v2a2 2 0 0 1-2 2h-2M7 21H5a2 2 0 0 1-2-2v-2M3 12h18" {...line} />
        </svg>
      );
    case "estrella":
      // Chispa (IA) — cuatro puntas
      return (
        <svg viewBox="0 0 24 24" style={s} className={className} aria-hidden>
          <path
            fill="currentColor"
            d="M12 2l2.4 7.2L22 12l-7.6 2.8L12 22l-2.4-7.2L2 12l7.6-2.8L12 2z"
          />
        </svg>
      );
    case "fecha":
      return (
        <svg viewBox="0 0 24 24" style={s} className={className} aria-hidden>
          <path d="M4 15c2-3 6-3 8 0s6 3 8 0v4H4z" {...line} />
          <path d="M4 8c2-3 6-3 8 0s6 3 8 0" {...line} />
        </svg>
      );
    case "flecha":
      return (
        <svg viewBox="0 0 24 24" style={s} className={className} aria-hidden>
          <path d="M5 12h14M13 6l6 6-6 6" {...line} />
        </svg>
      );
    case "papelera":
      return (
        <svg viewBox="0 0 24 24" style={s} className={className} aria-hidden>
          <path d="M4 7h16M9 7V5a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2M6.5 7l.8 12a2 2 0 0 0 2 1.9h5.4a2 2 0 0 0 2-1.9l.8-12M10 11v6M14 11v6" {...line} />
        </svg>
      );
    case "reiniciar":
      return (
        <svg viewBox="0 0 24 24" style={s} className={className} aria-hidden>
          <path d="M20 11A8 8 0 1 0 18.4 16" {...line} />
          <path d="M20 5v6h-6" {...line} />
        </svg>
      );
    case "guardar":
      return (
        <svg viewBox="0 0 24 24" style={s} className={className} aria-hidden>
          <path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z" {...line} />
          <path d="M17 21v-8H7v8M7 3v5h8" {...line} />
        </svg>
      );
    case "impresora":
      return (
        <svg viewBox="0 0 24 24" style={s} className={className} aria-hidden>
          <path d="M6 9V3h12v6" {...line} />
          <path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2" {...line} />
          <path d="M6 14h12v7H6z" {...line} />
        </svg>
      );
    case "copiar":
      return (
        <svg viewBox="0 0 24 24" style={s} className={className} aria-hidden>
          <rect x="8" y="8" width="12" height="12" rx="2" {...line} />
          <path d="M16 8V6a2 2 0 0 0-2-2H6a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2h2" {...line} />
        </svg>
      );
    case "mapa":
      return (
        <svg viewBox="0 0 24 24" style={s} className={className} aria-hidden>
          <path d="M9 4 3.5 6.5v13L9 17l6 3 5.5-2.5v-13L15 7l-6-3z" {...line} />
          <path d="M9 4v13M15 7v13" {...line} />
        </svg>
      );
  }
}