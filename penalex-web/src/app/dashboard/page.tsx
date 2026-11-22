import HeaderHome from "../../components/HeaderHome";
import RequiereSesion from "../../components/RequiereSesion";
import { cargarSentencias } from "../../lib/sentencias";
import ContenidoDashboard from "./ContenidoDashboard";
import type { SentenciaResumen } from "./types";

export const metadata = {
  title: "Mi panel | Penalex VE",
  description:
    "Panel profesional de Penalex VE: jurisprudencia, leyes, tribunales y cálculo de penas.",
  robots: { index: false, follow: false },
};

export default function DashboardPage() {
  // Sentencias más recientes del corpus (ordenadas por fecha de ingesta).
  let recientes: SentenciaResumen[] = [];
  try {
    const { sentencias } = cargarSentencias();
    recientes = [...sentencias]
      .sort((a, b) =>
        String(b.created_at ?? "").localeCompare(String(a.created_at ?? "")),
      )
      .slice(0, 6)
      .map((s) => ({
        slug: s.slug,
        num: s.num_sentencia || s.expediente || s.id,
        sala: s.sala,
        fecha: s.fecha,
        ponente: s.ponente,
        extracto: s.extracto || s.ratio_decidendi || s.decision || "",
        jurisprudencia: s.es_jurisprudencia === "true",
      }));
  } catch {
    recientes = [];
  }

  return (
    <div className="min-h-screen bg-[#f8fafc]">
      <HeaderHome />
      <RequiereSesion>
        <ContenidoDashboard recientes={recientes} />
      </RequiereSesion>
    </div>
  );
}
