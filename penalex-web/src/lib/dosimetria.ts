// Port exacto de lib/logic/dosimetria_engine.dart + lib/models/delito.dart
// Reglas: Arts. 86, 87, 88, 94, 98 CP y 375 COPP.
// - Concurso real solo presidios (Art. 86): pena mayor + 2/3 de las demás.
// - Concurso real mixto (Art. 87): prisiones -> presidio (1 presidio = 2 prisión),
//   luego fórmula de presidios.
// - Concurso real solo prisiones (Art. 88): pena mayor + 1/2 de las demás.
// - Concurso ideal (Art. 98): solo la pena más grave.
// - Tope absoluto 30 años (Art. 94): ANTES de la rebaja por admisión.
// - Admisión de hechos (Art. 375 COPP): sobre la pena final (ya topada).

export type GradoEjecucion = "consumado" | "frustrado" | "tentativa";
export type TipoConcurso = "real" | "ideal";
export type TipoPena = "presidio" | "prision";

export interface AjusteAdicional {
  nombre: string;
  esAgravante: boolean;
  fraccion: number;
}

export interface Delito {
  id: string;
  nombre: string;
  penaMin: number; // años
  penaMax: number; // años
  gradoEjecucion: GradoEjecucion;
  fraccionEjecucion: number;
  participacionEspecifica: string;
  delitoContinuado: boolean;
  fraccionContinuidad: number; // default 1/6
  modificadorManual: number; // años, 0 = ninguno
  tipoPena: TipoPena;
  montoMulta: number;
  ajustesAdicionales: AjusteAdicional[];
}

export interface ResultadoConcurso {
  total: number;
  pasos: string[];
  topeAplicado: boolean;
  articuloAplicado: string;
}

export interface PasoCalculo {
  descripcion: string;
  resultado: string;
  pena_actual: number;
}

// ---------------------------------------------------------------------------
// Utilidades de formato (idénticas al Dart)
// ---------------------------------------------------------------------------

/** 360 días al año (convención del motor). */
export function convertToYMD(totalYears: number): { anos: number; meses: number; dias: number } {
  if (totalYears <= 0) return { anos: 0, meses: 0, dias: 0 };
  const totalDias = Math.round(totalYears * 360);
  let anos = Math.floor(totalDias / 360);
  let meses = Math.floor((totalDias % 360) / 30);
  let dias = totalDias % 30;
  if (meses === 12) {
    anos += 1;
    meses = 0;
  }
  return { anos, meses, dias };
}

export function formatYMD(totalYears: number): string {
  const { anos, meses, dias } = convertToYMD(totalYears);
  return `${anos} años, ${meses} meses y ${dias} días`;
}

export function formatNumero(valor: number): string {
  if (valor === Math.trunc(valor)) return valor.toFixed(0);
  return valor.toFixed(2);
}

// ---------------------------------------------------------------------------
// PenaUtils.formatPena (mirror exacto de lib/utils/pena_utils.dart)
// Años de 360 días, mes de 30; normaliza dias==30→meses++, meses==12→años++.
// Salida con singular/plural. <=0 → "0 años"; todo cero → "0 días".
// ---------------------------------------------------------------------------

export function formatPena(totalYears: number): string {
  const totalDias = Math.round(totalYears * 360);
  let anios = Math.floor(totalDias / 360);
  let meses = Math.floor((totalDias % 360) / 30);
  let dias = totalDias % 30;
  if (dias === 30) {
    meses += 1;
    dias = 0;
  }
  if (meses === 12) {
    anios += 1;
    meses = 0;
  }
  if (anios <= 0 && meses <= 0 && dias <= 0) return "0 días";
  if (anios <= 0 && meses <= 0) return `${dias} ${dias === 1 ? "día" : "días"}`;
  if (anios <= 0 && dias <= 0) return `${meses} ${meses === 1 ? "mes" : "meses"}`;
  if (meses <= 0 && dias <= 0) return `${anios} ${anios === 1 ? "año" : "años"}`;
  const partes: string[] = [];
  if (anios > 0) partes.push(`${anios} ${anios === 1 ? "año" : "años"}`);
  if (meses > 0) partes.push(`${meses} ${meses === 1 ? "mes" : "meses"}`);
  if (dias > 0) partes.push(`${dias} ${dias === 1 ? "día" : "días"}`);
  return partes.join(", ");
}

// ---------------------------------------------------------------------------
// Cómputo de pena (mirror exacto de lib/pages/computo_page.dart)
// ---------------------------------------------------------------------------

/** Diferencia comercial 360/30: meses de 30 días, sin normalizar days==30. */
export function diferenciaComercial(
  desde: Date,
  hasta: Date
): { anos: number; meses: number; dias: number } {
  let years = hasta.getFullYear() - desde.getFullYear();
  let months = hasta.getMonth() - desde.getMonth();
  let days = hasta.getDate() - desde.getDate();
  if (days < 0) {
    months -= 1;
    days += 30;
  }
  if (months < 0) {
    years -= 1;
    months += 12;
  }
  return { anos: years, meses: months, dias: days };
}

export function formatearDuracion(anos: number, meses: number, dias: number): string {
  return `${anos} años, ${meses} meses, ${dias} días`;
}

/** Suma una pena (en años, 360/30) a una fecha. Igual que _sumarPena. */
export function sumarPena(desde: Date, penaEnAnios: number): Date {
  const totalDias = Math.round(penaEnAnios * 360);
  const anios = Math.floor(totalDias / 360);
  const resto = totalDias % 360;
  const meses = Math.floor(resto / 30);
  const dias = resto % 30;
  let fecha = new Date(desde.getFullYear() + anios, desde.getMonth(), desde.getDate());
  fecha = new Date(fecha.getFullYear(), fecha.getMonth() + meses, fecha.getDate());
  fecha = new Date(fecha.getFullYear(), fecha.getMonth(), fecha.getDate() + dias);
  return fecha;
}

export function formatearFecha(fecha: Date): string {
  const d = fecha.getDate().toString().padStart(2, "0");
  const m = (fecha.getMonth() + 1).toString().padStart(2, "0");
  return `${d}/${m}/${fecha.getFullYear()}`;
}

/** Parsea dd/mm/aaaa → Date | null. */
export function parsearFecha(texto: string): Date | null {
  const partes = texto.split("/");
  if (partes.length !== 3) return null;
  const dia = parseInt(partes[0], 10);
  const mes = parseInt(partes[1], 10);
  const anio = parseInt(partes[2], 10);
  if (isNaN(dia) || isNaN(mes) || isNaN(anio)) return null;
  const d = new Date(anio, mes - 1, dia);
  if (
    d.getFullYear() !== anio ||
    d.getMonth() !== mes - 1 ||
    d.getDate() !== dia
  )
    return null;
  return d;
}

/** Máscara dd/mm/aaaa: solo dígitos, '/' en índices 2 y 4, máx 10 chars. */
export function aplicarMascaraFecha(texto: string): string {
  const digitos = texto.replace(/[^0-9]/g, "");
  let out = digitos.slice(0, 8);
  if (out.length > 4) out = out.slice(0, 4) + "/" + out.slice(4);
  if (out.length > 2) out = out.slice(0, 2) + "/" + out.slice(2);
  return out.slice(0, 10);
}

function fraccionTexto(valor: number): string {
  const EPS = 0.001;
  if (Math.abs(valor - 1 / 6) < EPS) return "1/6";
  if (Math.abs(valor - 1 / 4) < EPS) return "1/4";
  if (Math.abs(valor - 1 / 3) < EPS) return "1/3";
  if (Math.abs(valor - 0.5) < EPS) return "1/2";
  if (Math.abs(valor - 2 / 3) < EPS) return "2/3";
  return formatNumero(valor);
}

/** Exportado para la UI (desglose de fracciones). */
export { fraccionTexto };

/** Parsea "1/3", "0.5", "0,5" a número. Igual que _parseFraccion en Dart. */
export function parseFraccion(text: string): number {
  const t = text.replace(",", ".");
  if (t.includes("/")) {
    const parts = t.split("/");
    if (parts.length === 2) {
      const num = parseFloat(parts[0]);
      const den = parseFloat(parts[1]);
      if (!isNaN(num) && !isNaN(den) && den !== 0) return num / den;
    }
  }
  const v = parseFloat(t);
  return isNaN(v) ? 0 : v;
}

export type UnidadTiempo = "años" | "meses" | "días";

/** Convierte valor+unidad a años (igual a actualizarPenaDesdeCampos). */
export function aAnios(valor: number, unidad: UnidadTiempo): number {
  if (unidad === "meses") return valor / 12;
  if (unidad === "días") return valor / 360;
  return valor;
}

// ---------------------------------------------------------------------------
// Delito: pena individualizada (mirror exacto de Delito.calcularPenaIndividualizada)
// ---------------------------------------------------------------------------

export function terminoMedio(d: Delito): number {
  return (d.penaMin + d.penaMax) / 2;
}

/** 1 día de presidio = 2 días de prisión -> prisión / 2 = presidio. */
export function convertirAPresidio(d: Delito): number {
  const { pena } = calcularPenaIndividualizada(d);
  return d.tipoPena === "prision" ? pena / 2 : pena;
}

export function nombreTipoPena(d: Delito): string {
  return d.tipoPena === "presidio" ? "Presidio" : "Prisión";
}

export function calcularPenaIndividualizada(d: Delito): { pena: number; pasos: PasoCalculo[] } {
  const pasos: PasoCalculo[] = [];
  let pena = terminoMedio(d);
  pasos.push({ descripcion: "Término medio", resultado: formatNumero(pena), pena_actual: pena });

  // 1. Modificador manual (Arts. 74/77 CP): limitado a los extremos del tipo.
  if (d.modificadorManual !== 0) {
    const tipo = d.modificadorManual > 0 ? "AGRAVANTE" : "ATENUANTE";
    const nueva = pena + d.modificadorManual;
    if (nueva > d.penaMax) {
      pasos.push({
        descripcion: `Modificador ${tipo} (Arts. 74/77 CP) limitado al máximo legal`,
        resultado: `+${formatNumero(d.penaMax - pena)} años`,
        pena_actual: d.penaMax,
      });
      pena = d.penaMax;
    } else if (nueva < d.penaMin) {
      pasos.push({
        descripcion: `Modificador ${tipo} (Arts. 74/77 CP) limitado al mínimo legal`,
        resultado: `-${formatNumero(pena - d.penaMin)} años`,
        pena_actual: d.penaMin,
      });
      pena = d.penaMin;
    } else {
      pasos.push({
        descripcion: `Modificador ${tipo} (Arts. 74/77 CP)`,
        resultado: `${d.modificadorManual > 0 ? "+" : "-"}${formatNumero(Math.abs(d.modificadorManual))} años`,
        pena_actual: nueva,
      });
      pena = nueva;
    }
  }

  // 2. Ajustes de leyes especiales: multiplicativos, PUEDEN superar los límites.
  for (const a of d.ajustesAdicionales) {
    const cambio = pena * a.fraccion;
    if (a.esAgravante) {
      pena += cambio;
      pasos.push({
        descripcion: `Ajuste legal (ley especial): ${a.nombre}`,
        resultado: `+${formatNumero(cambio)} años`,
        pena_actual: pena,
      });
    } else {
      pena -= cambio;
      pasos.push({
        descripcion: `Ajuste legal (ley especial): ${a.nombre}`,
        resultado: `-${formatNumero(cambio)} años`,
        pena_actual: pena,
      });
    }
  }

  // 3. Grado de ejecución (Art. 82 CP): la rebaja PUEDE bajar del mínimo.
  if (d.gradoEjecucion !== "consumado") {
    const tipo = d.gradoEjecucion === "frustrado" ? "FRUSTRADO" : "TENTATIVA";
    const rebaja = pena * d.fraccionEjecucion;
    pena = pena * (1 - d.fraccionEjecucion);
    pasos.push({
      descripcion: `Rebaja por ${tipo}`,
      resultado: `-${formatNumero(rebaja)} años`,
      pena_actual: pena,
    });
  }

  // 4. Cómplice no necesario (Art. 84 CP): -50%, puede bajar del mínimo.
  if (d.participacionEspecifica === "Cómplice No Necesario") {
    const rebaja = pena * 0.5;
    pena = pena * 0.5;
    pasos.push({
      descripcion: "Rebaja por complicidad no necesaria (Art. 84 CP)",
      resultado: `-${formatNumero(rebaja)} años`,
      pena_actual: pena,
    });
  }

  // 5. Delito continuado (Art. 99 CP): el aumento PUEDE superar el máximo.
  if (d.delitoContinuado) {
    const aumento = pena * d.fraccionContinuidad;
    pena = pena * (1 + d.fraccionContinuidad);
    pasos.push({
      descripcion: "Aumento por delito continuado",
      resultado: `+${formatNumero(aumento)} años`,
      pena_actual: pena,
    });
  }

  pasos.push({ descripcion: "PENA FINAL", resultado: formatNumero(pena), pena_actual: pena });
  return { pena, pasos };
}

// ---------------------------------------------------------------------------
// Concurso (mirror exacto de DosimetriaEngine.calcularConcursoDetallado)
// ---------------------------------------------------------------------------

export function calcularConcursoDetallado(opts: {
  delitos: Delito[];
  concurso: TipoConcurso;
  admisionHechos: boolean;
  fraccionAdmision: number;
}): ResultadoConcurso {
  const { delitos, concurso, admisionHechos, fraccionAdmision } = opts;
  if (delitos.length === 0) {
    return { total: 0, pasos: ["Sin delitos para calcular"], topeAplicado: false, articuloAplicado: "" };
  }

  const pasos: string[] = [];
  const penas = delitos.map((d) => calcularPenaIndividualizada(d).pena);

  let penaBase: number;
  let articulo: string;

  if (concurso === "real" && delitos.length === 1) {
    articulo = "Delito único (sin concurso)";
    penaBase = penas[0];
    pasos.push(`Pena individualizada: ${formatYMD(penaBase)}`);
  } else if (concurso === "real") {
    const hayPresidio = delitos.some((d) => d.tipoPena === "presidio");
    const hayPrision = delitos.some((d) => d.tipoPena === "prision");

    if (hayPresidio && hayPrision) {
      // Art. 87 CP: convertir prisiones a presidio primero.
      articulo = "Art. 87 CP (Presidio + Prisión)";
      const convertidas = delitos.map((d) => convertirAPresidio(d));
      for (let i = 0; i < delitos.length; i++) {
        if (delitos[i].tipoPena === "prision") {
          pasos.push(`Conversión Art. 87 CP: prisión ${formatYMD(penas[i])} -> presidio ${formatYMD(convertidas[i])}`);
        }
      }
      convertidas.sort((a, b) => b - a);
      penaBase = convertidas[0];
      pasos.push(`Pena mayor (presidio): ${formatYMD(penaBase)}`);
      for (let i = 1; i < convertidas.length; i++) {
        const inc = convertidas[i] * (2 / 3);
        pasos.push(`+ 2/3 de ${formatYMD(convertidas[i])} = ${formatYMD(inc)}`);
        penaBase += inc;
      }
    } else if (hayPrision) {
      // Art. 88 CP: solo prisiones -> pena mayor + 1/2 de las demás.
      articulo = "Art. 88 CP (Prisión + Prisión)";
      penas.sort((a, b) => b - a);
      penaBase = penas[0];
      pasos.push(`Pena mayor (prisión): ${formatYMD(penaBase)}`);
      for (let i = 1; i < penas.length; i++) {
        const inc = penas[i] * 0.5;
        pasos.push(`+ 1/2 de ${formatYMD(penas[i])} = ${formatYMD(inc)}`);
        penaBase += inc;
      }
    } else {
      // Art. 86 CP: solo presidios -> pena mayor + 2/3 de las demás.
      articulo = "Art. 86 CP (Presidio + Presidio)";
      penas.sort((a, b) => b - a);
      penaBase = penas[0];
      pasos.push(`Pena mayor (presidio): ${formatYMD(penaBase)}`);
      for (let i = 1; i < penas.length; i++) {
        const inc = penas[i] * (2 / 3);
        pasos.push(`+ 2/3 de ${formatYMD(penas[i])} = ${formatYMD(inc)}`);
        penaBase += inc;
      }
    }
  } else {
    // Art. 98 CP: concurso ideal -> solo la pena más grave.
    articulo = "Art. 98 CP (Concurso Ideal)";
    penaBase = Math.max(...penas);
    pasos.push(`Pena más grave (Art. 98 CP): ${formatYMD(penaBase)}`);
  }

  // Tope absoluto 30 años (Art. 94 CP): SIEMPRE antes de la admisión.
  let topeAplicado = false;
  if (penaBase > 30.0) {
    pasos.push(`Tope de 30 años (Art. 94 CP): ${formatYMD(penaBase)} -> 30 años`);
    penaBase = 30.0;
    topeAplicado = true;
  }

  // Rebaja por admisión de hechos (Art. 375 COPP): sobre la pena final topada.
  if (admisionHechos) {
    const rebaja = penaBase * fraccionAdmision;
    pasos.push(`Rebaja por admisión de hechos (Art. 375 COPP, ${fraccionTexto(fraccionAdmision)}): -${formatYMD(rebaja)}`);
    penaBase = penaBase * (1 - fraccionAdmision);
  }

  pasos.push(`PENA DEFINITIVA: ${formatYMD(penaBase)}`);

  return { total: penaBase, pasos, topeAplicado, articuloAplicado: articulo };
}

/** API simple (compatibilidad): solo el total. */
export function calcularConcurso(opts: {
  delitos: Delito[];
  concurso: TipoConcurso;
  admisionHechos: boolean;
  fraccionAdmision: number;
}): number {
  return calcularConcursoDetallado(opts).total;
}