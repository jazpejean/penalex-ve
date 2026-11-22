/** Fila de sentencia tal como la pinta el panel (sin cargar el corpus en el cliente). */
export interface SentenciaResumen {
  slug: string;
  num: string;
  sala: string;
  fecha: string;
  ponente: string;
  extracto: string;
  jurisprudencia: boolean;
}
