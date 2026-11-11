import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Penalex VE | Plataforma de Derecho Penal Venezolano",
  description:
    "Dosimetría penal, corpus legal completo, concurso de delitos y cómputo de lapsos. Herramientas profesionales para la autoridad judicial venezolana.",
  icons: {
    icon: [
      { url: "/producto/icono.png", sizes: "any", type: "image/png" },
      { url: "/favicon.ico", sizes: "any" },
    ],
    apple: "/producto/apple-icon.png",
  },
  // NOTA SEO: el noindex ya NO es global. Cada sección controla su propia
  // indexación: la home (en construcción) tiene noindex en su página, y
  // /jurisprudencia/** es lo indexable (landings SEO por sentencia).
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="es" className="h-full antialiased">
      <body className="min-h-full flex flex-col bg-[#f1f5f9] text-[#031f4e]">
        {children}
      </body>
    </html>
  );
}