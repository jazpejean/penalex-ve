"use client";

import { useMemo, useState } from "react";
import Navbar from "../../components/Navbar";
import RequiereSesion from "../../components/RequiereSesion";
import {
  calcularConcursoDetallado,
  calcularPenaIndividualizada,
  convertToYMD,
  formatYMD,
  formatPena,
  fraccionTexto,
  parseFraccion,
  terminoMedio,
  diferenciaComercial,
  formatearDuracion,
  sumarPena,
  formatearFecha,
  parsearFecha,
  aplicarMascaraFecha,
  type Delito,
  type TipoConcurso,
  type GradoEjecucion,
  type TipoPena,
  type AjusteAdicional,
} from "../../lib/dosimetria";
import BuscadorArticulos from "../../components/BuscadorArticulos";
import Icono from "../../components/Icono";

const GRADOS_PARTICIPACION = [
  "Autor",
  "Coautor",
  "Cooperador Inmediato",
  "Cómplice Necesario",
  "Cómplice No Necesario",
];

const AZUL = "#0F172A";
const ORO = "#C5A059";

function delitoVacio(id: number): Delito {
  return {
    id: String(id),
    nombre: "",
    penaMin: 0,
    penaMax: 0,
    gradoEjecucion: "consumado",
    fraccionEjecucion: 0,
    participacionEspecifica: "Autor",
    delitoContinuado: false,
    fraccionContinuidad: 1 / 6,
    modificadorManual: 0,
    tipoPena: "prision",
    montoMulta: 0,
    ajustesAdicionales: [],
  };
}

// ---------------------------------------------------------------------------
// Stepper fiel al dosimetria_stepper.dart
// ---------------------------------------------------------------------------
function Stepper({ pasoActual }: { pasoActual: number }) {
  const pasos = ["DELITOS", "CONCURSO", "CÓMPUTO"];
  return (
    <div className="mt-6 mb-2 flex items-center">
      {pasos.map((p, i) => {
        const num = i + 1;
        const completado = num < pasoActual;
        const activo = num === pasoActual;
        const resaltado = completado || activo;
        return (
          <div key={p} className="flex flex-1 items-center">
            <div
              className={`flex items-center gap-1.5 rounded-full border px-2.5 py-1.5 ${
                resaltado
                  ? "border-[#C5A059] bg-[#0F172A]"
                  : "border-[#e2e8f0] bg-[#f1f5f9]"
              }`}
            >
              <span
                className={`flex h-4 w-4 items-center justify-center text-[10px] font-extrabold ${
                  completado ? "text-[#C5A059]" : "text-[#C5A059]"
                }`}
              >
                {completado ? "✓" : num}
              </span>
              <span
                className={`text-[9px] font-extrabold tracking-wide ${
                  resaltado ? "text-[#C5A059]" : "text-slate-500"
                }`}
              >
                {p}
              </span>
            </div>
            {i < pasos.length - 1 && (
              <div
                className={`mx-2 h-0.5 flex-1 ${
                  num < pasoActual ? "bg-[#c5a059]" : "bg-[#334155]"
                }`}
              />
            )}
          </div>
        );
      })}
    </div>
  );
}

// ---------------------------------------------------------------------------
// PenaInputRow: TRES campos (Años/Meses/Días) — fiel a _PenaInputRow de la app
// ---------------------------------------------------------------------------
function PenaInputRow({
  label,
  anios,
  meses,
  dias,
  onChanged,
  onInfo,
}: {
  label: string;
  anios: number;
  meses: number;
  dias: number;
  onChanged: (anios: number, meses: number, dias: number) => void;
  onInfo?: () => void;
}) {
  // Entrada en dígitos por campo; combinación: totalDias = a*360 + m*30 + d
  const setCampo = (campo: "anios" | "meses" | "dias", v: number) => {
    const na = campo === "anios" ? v : anios;
    const nm = campo === "meses" ? v : meses;
    const nd = campo === "dias" ? v : dias;
    onChanged(na, nm, nd);
  };
  const campo =
    "w-full rounded-md border border-[#e2e8f0] bg-[#F1F5F9] px-2 py-2 text-center text-sm font-semibold text-[#0F172A] focus:border-[#c5a059] focus:outline-none";
  const etiqueta = "text-[10px] uppercase tracking-wide text-slate-500";
  return (
    <div>
      <div className="flex items-center gap-2">
        <span className="text-xs font-medium text-slate-500">{label}</span>
        {onInfo && (
          <button
            onClick={onInfo}
            className="text-[#C5A059]"
            title="Información"
          >
            ⓘ
          </button>
        )}
      </div>
      <div className="mt-1 grid grid-cols-3 gap-2">
        <div>
          <input
            type="number"
            min={0}
            value={anios || ""}
            placeholder="0"
            onChange={(e) => setCampo("anios", Math.max(0, parseInt(e.target.value || "0", 10)))}
            className={campo}
          />
          <div className={etiqueta}>años</div>
        </div>
        <div>
          <input
            type="number"
            min={0}
            value={meses || ""}
            placeholder="0"
            onChange={(e) => setCampo("meses", Math.max(0, parseInt(e.target.value || "0", 10)))}
            className={campo}
          />
          <div className={etiqueta}>meses</div>
        </div>
        <div>
          <input
            type="number"
            min={0}
            value={dias || ""}
            placeholder="0"
            onChange={(e) => setCampo("dias", Math.max(0, parseInt(e.target.value || "0", 10)))}
            className={campo}
          />
          <div className={etiqueta}>días</div>
        </div>
      </div>
    </div>
  );
}

// Convierte años/meses/días (360/30) a años decimales (igual que la app)
function aAniosDesdeAMD(anios: number, meses: number, dias: number): number {
  return (anios * 360 + meses * 30 + dias) / 360;
}

// ---------------------------------------------------------------------------
// Formulario de delito (fiel al _buildDelitoForm de Flutter)
// ---------------------------------------------------------------------------
function DelitoForm({
  delito,
  idx,
  update,
  quitar,
  solo,
}: {
  delito: Delito;
  idx: number;
  update: (idx: number, patch: Partial<Delito>) => void;
  quitar: (idx: number) => void;
  solo: boolean;
}) {
  const penaInd = calcularPenaIndividualizada(delito);
  const [tipoMod, setTipoMod] = useState<"atenuante" | "agravante">(
    delito.modificadorManual < 0 ? "atenuante" : "agravante"
  );
  const [modAnios, setModAnios] = useState(0);
  const [modMeses, setModMeses] = useState(0);
  const [modDias, setModDias] = useState(0);
  const [nombreAjuste, setNombreAjuste] = useState("");
  const [esAgravanteAjuste, setEsAgravanteAjuste] = useState(true);
  const [fraccionAjuste, setFraccionAjuste] = useState("1/3");
  const [mostrarNuevoAjuste, setMostrarNuevoAjuste] = useState(false);
  const [infoModal, setInfoModal] = useState<{ titulo: string; mensaje: string } | null>(null);
  const info = (titulo: string, mensaje: string) => setInfoModal({ titulo, mensaje });

  const ymdMin = convertToYMD(delito.penaMin);
  const ymdMax = convertToYMD(delito.penaMax);

  const onPenaMin = (a: number, m: number, d: number) =>
    update(idx, { penaMin: aAniosDesdeAMD(a, m, d) });
  const onPenaMax = (a: number, m: number, d: number) =>
    update(idx, { penaMax: aAniosDesdeAMD(a, m, d) });

  const onMod = (a: number, m: number, d: number) => {
    setModAnios(a); setModMeses(m); setModDias(d);
    const anios = aAniosDesdeAMD(a, m, d);
    update(idx, { modificadorManual: tipoMod === "atenuante" ? -anios : anios });
  };

  const setTipo = (t: "atenuante" | "agravante") => {
    setTipoMod(t);
    const abs = Math.abs(delito.modificadorManual);
    update(idx, { modificadorManual: t === "atenuante" ? -abs : abs });
  };

  const agregarAjuste = () => {
    const f = parseFraccion(fraccionAjuste);
    if (!nombreAjuste.trim() || f === 0) return;
    const a: AjusteAdicional = {
      nombre: nombreAjuste.trim(),
      esAgravante: esAgravanteAjuste,
      fraccion: f,
    };
    update(idx, { ajustesAdicionales: [...delito.ajustesAdicionales, a] });
    setNombreAjuste("");
    setFraccionAjuste("1/3");
    setMostrarNuevoAjuste(false);
  };

  const eliminarAjuste = (i: number) =>
    update(idx, { ajustesAdicionales: delito.ajustesAdicionales.filter((_, j) => j !== i) });

  const sel =
    "w-full rounded-md border border-[#e2e8f0] bg-[#F1F5F9] px-3 py-2 text-sm text-[#0F172A] focus:border-[#c5a059] focus:outline-none";
  const chip = (activo: boolean) =>
    `rounded-md border px-2 py-1.5 text-xs font-semibold ${
      activo
        ? "border-[#c5a059] bg-[#c5a059]/15 text-[#C5A059]"
        : "border-[#e2e8f0] text-slate-500 hover:bg-[#f1f5f9]"
    }`;

  return (
    <div className="rounded-xl border border-[#c5a059]/40 bg-white p-5 shadow-lg">
      <div className="flex items-center justify-between">
        <h2 className="text-sm font-extrabold tracking-wider text-[#0F172A]">
          DELITO {idx + 1}
        </h2>
        <div className="flex items-center gap-1.5 rounded-full bg-[#F1F5F9] px-3 py-1">
          <span className="text-[10px] text-[#C5A059]">⚖</span>
          <span className="text-[11px] font-extrabold text-[#C5A059]">
            {formatYMD(penaInd.pena)}
          </span>
        </div>
      </div>

      {/* Nombre */}
      <div className="mt-4">
        <label className="text-xs font-medium text-slate-500">Nombre del delito</label>
        <div className="mt-1 flex items-center gap-2">
          <input
            value={delito.nombre}
            onChange={(e) => update(idx, { nombre: e.target.value })}
            placeholder='Ej: Homicidio calificado (Art. 406 CPV)'
            className={sel}
          />
          <button
            onClick={() => info(
              "Base legal del tipo penal",
              'Indique el nombre del delito conforme al Código Penal o leyes especiales.\n\nEjemplo: "Homicidio Calificado" (Art. 406 CPV).'
            )}
            className="shrink-0 text-[#C5A059]"
            title="Información"
          >
            ⓘ
          </button>
        </div>
      </div>

      {/* Tipo de pena */}
      <div className="mt-3">
        <label className="text-xs font-medium text-slate-500">Tipo de pena</label>
        <div className="mt-1 grid grid-cols-2 gap-2">
          {(
            [
              ["presidio", "Presidio"],
              ["prision", "Prisión"],
            ] as [TipoPena, string][]
          ).map(([val, label]) => (
            <button
              key={val}
              onClick={() => {
                update(idx, { tipoPena: val });
                info(
                  val === "presidio" ? "Presidio" : "Prisión",
                  val === "presidio"
                    ? "Pena privativa de libertad con trabajos forzados. Se caracteriza por imponer al condenado la obligación de realizar labores durante el cumplimiento de la condena.\n\nUtilizado para delitos graves en el Código Penal Venezolano."
                    : "Pena privativa de libertad sin trabajos forzados. El condenado cumple la pena sin obligación de realizar labores específicas.\n\nEn caso de concurso real con presidio, esta pena será convertida conforme al Art. 87 CP (1 año de presidio equivale a 2 años de prisión)."
                );
              }}
              className={chip(delito.tipoPena === val)}
            >
              {label}
            </button>
          ))}
        </div>
      </div>

      {/* Pena mínima / máxima (3 campos A/M/D) */}
      <div className="mt-4 space-y-4">
        <PenaInputRow
          label="PENA MÍNIMA"
          anios={ymdMin.anos}
          meses={ymdMin.meses}
          dias={ymdMin.dias}
          onChanged={onPenaMin}
          onInfo={() => info("Pena mínima", "Límite inferior de la pena establecida en la ley.")}
        />
        <PenaInputRow
          label="PENA MÁXIMA"
          anios={ymdMax.anos}
          meses={ymdMax.meses}
          dias={ymdMax.dias}
          onChanged={onPenaMax}
          onInfo={() => info("Pena máxima", "Límite superior de la pena establecida en la ley.")}
        />
      </div>

      {/* Término medio */}
      <div className="mt-4 rounded-lg border border-[#c5a059]/30 bg-[#c5a059]/10 px-3 py-2.5">
        <div className="flex items-center justify-between">
          <span className="text-xs font-medium text-slate-600">
            Término medio (Art. 37 CP):
          </span>
          <span className="text-sm font-bold text-[#b45309]">
            {formatYMD(terminoMedio(delito))}
          </span>
        </div>
      </div>

      {/* Ajustes adicionales */}
      <div className="mt-4">
        <h3 className="text-[11px] font-extrabold tracking-wide text-slate-600">
          AJUSTES ADICIONALES
        </h3>
        {delito.ajustesAdicionales.map((a, i) => (
          <div
            key={i}
            className="mt-2 flex items-center justify-between rounded-md border border-[#e2e8f0] bg-[#F1F5F9] px-3 py-2"
          >
            <div className="text-sm text-slate-200">
              {a.nombre}{" "}
              <span className={a.esAgravante ? "text-red-400" : "text-emerald-400"}>
                ({a.esAgravante ? "+" : "-"}
                {fraccionTexto(a.fraccion)})
              </span>
            </div>
            <button
              onClick={() => eliminarAjuste(i)}
              className="text-xs text-red-500 hover:text-red-400"
            >
              ✕
            </button>
          </div>
        ))}
        <button
          onClick={() => setMostrarNuevoAjuste(!mostrarNuevoAjuste)}
          className="mt-2 rounded-md border border-[#c5a059]/50 px-3 py-1.5 text-xs font-semibold text-[#C5A059] hover:bg-[#c5a059]/10"
        >
          {mostrarNuevoAjuste ? "− Cerrar" : "+ Agregar ajuste"}
        </button>
        {mostrarNuevoAjuste && (
          <div className="mt-2 space-y-2 rounded-md border border-[#e2e8f0] bg-[#F1F5F9] p-3">
            <input
              value={nombreAjuste}
              onChange={(e) => setNombreAjuste(e.target.value)}
              placeholder="Nombre (ej: Aumento por autoridad)"
              className={sel}
            />
            <div className="flex gap-2">
              <button
                onClick={() => setEsAgravanteAjuste(true)}
                className={chip(esAgravanteAjuste)}
              >
                Agravante (+ fracción)
              </button>
              <button
                onClick={() => setEsAgravanteAjuste(false)}
                className={chip(!esAgravanteAjuste)}
              >
                Atenuante (− fracción)
              </button>
            </div>
            <input
              value={fraccionAjuste}
              onChange={(e) => setFraccionAjuste(e.target.value)}
              placeholder="Fracción (ej: 1/3, 1/2, 1/4)"
              className={sel}
            />
            <div className="text-xs text-slate-500">
              Valor: {fraccionTexto(parseFraccion(fraccionAjuste))}
            </div>
            <button
              onClick={agregarAjuste}
              className="w-full rounded-md bg-[#c5a059] px-3 py-1.5 text-xs font-bold text-[#0F172A] hover:bg-[#e9c86a]"
            >
              Agregar
            </button>
          </div>
        )}
      </div>

      {/* AJUSTES LEGALES */}
      <div className="mt-4">
        <h3 className="text-[11px] font-extrabold tracking-wide text-slate-600">
          AJUSTES LEGALES
        </h3>

        {/* Grado de ejecución */}
        <div className="mt-2">
          <label className="text-xs font-medium text-slate-500">Grado de ejecución</label>
          <div className="mt-1 grid grid-cols-3 gap-2">
            {(
              [
                ["consumado", "Consumado"],
                ["frustrado", "Frustrado"],
                ["tentativa", "Tentativa"],
              ] as [GradoEjecucion, string][]
            ).map(([val, label]) => (
              <button
                key={val}
                onClick={() => {
                  update(idx, {
                    gradoEjecucion: val,
                    fraccionEjecucion:
                      val === "frustrado" ? 1 / 3 : val === "tentativa" ? 0.5 : 0,
                  });
                  info(
                    val === "consumado"
                      ? "Delito Consumado"
                      : val === "frustrado"
                        ? "Delito Frustrado (Arts. 80 y 82 CP)"
                        : "Tentativa (Arts. 80 y 82 CP)",
                    val === "consumado"
                      ? "Se produce cuando el agente ha ejecutado la totalidad de los actos necesarios para la realización del tipo penal y se ha verificado el resultado lesivo. En este supuesto, la pena a aplicar es la que establece la ley para el delito en su extensión íntegra."
                      : val === "frustrado"
                        ? "Ocurre cuando el agente practica todo lo necesario para la consumación del delito, pero esta no se verifica por causas independientes a su voluntad. La pena aplicable será la del delito consumado rebajada en una tercera parte (1/3)."
                        : "Se configura cuando el agente inicia la ejecución del delito mediante actos directos, pero no realiza todo lo necesario para su consumación por causas ajenas a su control. La pena se rebaja entre la mitad (1/2) y las dos terceras partes (2/3)."
                  );
                }}
                className={chip(delito.gradoEjecucion === val)}
              >
                {label}
              </button>
            ))}
          </div>
          {delito.gradoEjecucion === "tentativa" && (
            <div className="mt-2">
              <div className="text-xs text-slate-500">
                Rebaja (tentativa): {fraccionTexto(delito.fraccionEjecucion)}
              </div>
              {/* Slider con snap a [0.5, 2/3] como la app */}
              <input
                type="range"
                min={0.5}
                max={2 / 3}
                step={1 / 6}
                value={delito.fraccionEjecucion}
                onChange={(e) =>
                  update(idx, { fraccionEjecucion: parseFloat(e.target.value) })
                }
                className="mt-1 w-full accent-[#c5a059]"
              />
              <div className="flex justify-between text-[10px] text-slate-500">
                <span>1/2</span>
                <span>2/3</span>
              </div>
            </div>
          )}
        </div>

        {/* Participación */}
        <div className="mt-3">
          <label className="text-xs font-medium text-slate-500">Grado de participación</label>
          <select
            value={delito.participacionEspecifica}
            onChange={(e) => {
              update(idx, { participacionEspecifica: e.target.value });
              info(
                e.target.value === "Cómplice No Necesario"
                  ? "Cómplice No Necesario (Art. 84 CP)"
                  : "Autoría y Participación (Art. 83 CP)",
                e.target.value === "Cómplice No Necesario"
                  ? "Se refiere a quienes coadyuvan en la ejecución del delito mediante instrucciones, suministros o auxilio secundario no indispensable. La pena correspondiente al autor principal se rebajará a la mitad (1/2) para este grado de participación."
                  : "Se aplica la pena íntegra del delito al Autor, Coautor y Cooperador Inmediato, por ser piezas esenciales en la ejecución del hecho. Igualmente, el Cómplice Necesario recibe la misma pena al prestar un auxilio sin el cual no habría sido posible el acto."
              );
            }}
            className={`${sel} mt-1`}
          >
            {GRADOS_PARTICIPACION.map((g) => (
              <option key={g} value={g}>
                {g}
              </option>
            ))}
          </select>
        </div>

        {/* Delito continuado */}
        <div className="mt-3 flex items-center justify-between">
          <label className="text-sm text-slate-200">Delito continuado</label>
          <input
            type="checkbox"
            checked={delito.delitoContinuado}
            onChange={(e) => {
              update(idx, { delitoContinuado: e.target.checked });
              if (e.target.checked)
                info(
                  "Delito Continuado (Art. 99 CP)",
                  "Varias violaciones de la misma disposición legal, cometidas en diferentes fechas pero bajo una misma resolución criminal, se consideran un solo hecho punible. Se toma la pena del delito más grave (término medio) y se aumenta entre una sexta parte (1/6) y la mitad (1/2)."
                );
            }}
            className="h-4 w-4 accent-[#c5a059]"
          />
        </div>
        {delito.delitoContinuado && (
          <div className="mt-2">
            <div className="text-xs text-slate-500">
              Aumento (Art. 99 CP): +{fraccionTexto(delito.fraccionContinuidad)}
            </div>
            {/* Slider con snap [1/6, 1/4, 1/3, 0.5] como la app */}
            <input
              type="range"
              min={1 / 6}
              max={0.5}
              step={1 / 12}
              value={delito.fraccionContinuidad}
              onChange={(e) =>
                update(idx, { fraccionContinuidad: parseFloat(e.target.value) })
              }
              className="mt-1 w-full accent-[#c5a059]"
            />
            <div className="flex justify-between text-[10px] text-slate-500">
              <span>1/6</span>
              <span>1/4</span>
              <span>1/3</span>
              <span>1/2</span>
            </div>
          </div>
        )}
      </div>

      {/* Atenuantes / Agravantes */}
      <div className="mt-4">
        <h3 className="text-[11px] font-extrabold tracking-wide text-slate-600">
          ATENUANTES / AGRAVANTES (Arts. 74 y 77 CP)
        </h3>
        <div className="mt-2 grid grid-cols-2 gap-2">
          <button
            onClick={() => setTipo("atenuante")}
            className={chip(tipoMod === "atenuante")}
          >
            Atenuante (−)
          </button>
          <button
            onClick={() => setTipo("agravante")}
            className={chip(tipoMod === "agravante")}
          >
            Agravante (+)
          </button>
        </div>
        <div className="mt-3">
          <div className="text-xs font-medium text-slate-500">Cantidad</div>
          <div className="mt-1 grid grid-cols-3 gap-2">
            <input
              type="number"
              min={0}
              value={modAnios || ""}
              placeholder="0"
              onChange={(e) => onMod(Math.max(0, parseInt(e.target.value || "0", 10)), modMeses, modDias)}
              className="w-full rounded-md border border-[#e2e8f0] bg-[#F1F5F9] px-2 py-2 text-center text-sm text-[#0F172A]"
            />
            <input
              type="number"
              min={0}
              value={modMeses || ""}
              placeholder="0"
              onChange={(e) => onMod(modAnios, Math.max(0, parseInt(e.target.value || "0", 10)), modDias)}
              className="w-full rounded-md border border-[#e2e8f0] bg-[#F1F5F9] px-2 py-2 text-center text-sm text-[#0F172A]"
            />
            <input
              type="number"
              min={0}
              value={modDias || ""}
              placeholder="0"
              onChange={(e) => onMod(modAnios, modMeses, Math.max(0, parseInt(e.target.value || "0", 10)))}
              className="w-full rounded-md border border-[#e2e8f0] bg-[#F1F5F9] px-2 py-2 text-center text-sm text-[#0F172A]"
            />
          </div>
          <div className="mt-1 grid grid-cols-3 text-center text-[10px] uppercase tracking-wide text-slate-500">
            <span>años</span>
            <span>meses</span>
            <span>días</span>
          </div>
        </div>
        <button
          onClick={() =>
            info(
              "Atenuantes (Art. 74 CP) y Agravantes (Art. 77 CP)",
              "Atenuantes: circunstancias que reducen la responsabilidad penal (como la falta de intención proporcional al daño o la minoridad). Su presencia obliga al juez a mover la pena desde el término medio hacia el límite mínimo.\n\nAgravantes: circunstancias que aumentan la punibilidad debido a la mayor peligrosidad del agente o la forma de ejecución (alevosía, ensañamiento, reincidencia). Su presencia obliga al juez a mover la pena desde el término medio hacia el límite máximo."
            )
          }
          className="mt-2 text-[10px] font-semibold text-[#C5A059]"
        >
          ⓘ ¿Qué son atenuantes y agravantes?
        </button>
      </div>

      {/* Pena individualizada */}
      <div className="mt-4 rounded-lg border border-[#c5a059]/50 bg-[#F1F5F9] px-4 py-3">
        <div className="text-[10px] font-extrabold uppercase tracking-widest text-[#C5A059]">
          Pena individualizada
        </div>
        <div className="mt-1 text-lg font-black text-[#C5A059]">
          {formatYMD(penaInd.pena)}
        </div>
      </div>

      {!solo && (
        <button
          onClick={() => quitar(idx)}
          className="mt-3 text-xs font-semibold text-red-400 hover:text-red-300"
        >
          Eliminar este delito
        </button>
      )}

      {/* Modal de información */}
      {infoModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4">
          <div className="w-full max-w-md rounded-2xl border border-[#e2e8f0] bg-white p-6 shadow-2xl">
            <h3 className="serif text-base font-bold text-[#0F172A]">
              {infoModal.titulo}
            </h3>
            <p className="mt-3 whitespace-pre-line text-sm leading-relaxed text-slate-600">
              {infoModal.mensaje}
            </p>
            <button
              onClick={() => setInfoModal(null)}
              className="mt-5 rounded-md bg-[#c5a059] px-4 py-2 text-sm font-semibold text-[#0F172A] hover:bg-[#e9c86a]"
            >
              Entendido
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

// ---------------------------------------------------------------------------
// Datos del cómputo (paso 3)
// ---------------------------------------------------------------------------
interface DatosComputo {
  expediente: string;
  acusado: string;
  sinDetenido: boolean;
  fechaDetencion: Date | null;
  fechaCondena: Date | null;
  usarFechaActual: boolean;
  fechaDetencionTexto: string;
  fechaCondenaTexto: string;
}

interface CalculoGuardado {
  nombre: string;
  delitos: Delito[];
  concurso: TipoConcurso;
  admisionHechos: boolean;
  fraccionAdmision: number;
  guardadoEn: string;
}

export default function DosimetriaPage() {
  const [paso, setPaso] = useState<1 | 2 | 3>(1);
  const [delitos, setDelitos] = useState<Delito[]>([delitoVacio(1)]);

  const [concurso, setConcurso] = useState<TipoConcurso>("real");
  const [seleccion, setSeleccion] = useState<boolean[]>([true]);
  const [admision, setAdmision] = useState(false);
  const [fraccionAdmision, setFraccionAdmision] = useState(1 / 3);
  const [verDesglose, setVerDesglose] = useState(false);

  const [computo, setComputo] = useState<DatosComputo>({
    expediente: "",
    acusado: "",
    sinDetenido: false,
    fechaDetencion: null,
    fechaCondena: null,
    usarFechaActual: true,
    fechaDetencionTexto: "",
    fechaCondenaTexto: "",
  });

  // Modales y avisos
  const [modalGuardar, setModalGuardar] = useState(false);
  const [modalCargar, setModalCargar] = useState(false);
  const [modalEliminar, setModalEliminar] = useState<number | null>(null);
  const [nombreGuardar, setNombreGuardar] = useState("");
  const [toast, setToast] = useState<{ texto: string; tipo: "ok" | "err" } | null>(null);
  const avisar = (texto: string, tipo: "ok" | "err" = "ok") => {
    setToast({ texto, tipo });
    setTimeout(() => setToast(null), 2800);
  };

  const update = (idx: number, patch: Partial<Delito>) =>
    setDelitos((prev) => prev.map((d, i) => (i === idx ? { ...d, ...patch } : d)));

  const agregar = () => {
    setDelitos((p) => [...p, delitoVacio(p.length + 1)]);
    setSeleccion((s) => [...s, true]);
  };
  const quitar = (idx: number) => {
    setDelitos((p) => (p.length > 1 ? p.filter((_, i) => i !== idx) : p));
    setSeleccion((s) => (s.length > 1 ? s.filter((_, i) => i !== idx) : s));
  };

  const seleccionActual = useMemo(
    () => delitos.map((_, i) => seleccion[i] ?? true),
    [delitos, seleccion]
  );
  const delitosSeleccionados = delitos.filter((_, i) => seleccionActual[i]);

  const resultado = calcularConcursoDetallado({
    delitos: delitosSeleccionados,
    concurso,
    admisionHechos: admision,
    fraccionAdmision,
  });

  const sumatoria = delitos.reduce(
    (acc, d) => acc + calcularPenaIndividualizada(d).pena,
    0
  );

  // Cómputo
  const computoCalculado = useMemo(() => {
    if (computo.sinDetenido || !computo.fechaDetencion) {
      return {
        tiempoDetenido: "No aplica",
        tiempoRestante: "No aplica",
        fechaCumplimiento: null as Date | null,
      };
    }
    const hasta: Date = computo.fechaCondena ?? new Date();
    const diff = diferenciaComercial(computo.fechaDetencion, hasta);
    const tiempoDetenido = formatearDuracion(diff.anos, diff.meses, diff.dias);
    const fechaCumplimiento = sumarPena(computo.fechaDetencion, resultado.total);
    const diffRest = diferenciaComercial(hasta, fechaCumplimiento);
    const tiempoRestante =
      hasta.getTime() > fechaCumplimiento.getTime()
        ? "0 años, 0 meses, 0 días"
        : formatearDuracion(diffRest.anos, diffRest.meses, diffRest.dias);
    return { tiempoDetenido, tiempoRestante, fechaCumplimiento };
  }, [computo, resultado.total]);

  const fechaCondenaMostrada = computo.usarFechaActual
    ? new Date()
    : computo.fechaCondena;

  // Guardar / cargar (localStorage unificado)
  const confirmarGuardar = () => {
    const nombre = nombreGuardar.trim();
    if (!nombre) return;
    const datos: CalculoGuardado = {
      nombre,
      delitos,
      concurso,
      admisionHechos: admision,
      fraccionAdmision,
      guardadoEn: new Date().toISOString(),
    };
    try {
      const prev = JSON.parse(localStorage.getItem("penalex_calculos") ?? "[]");
      prev.unshift(datos);
      if (prev.length > 50) prev.length = 50;
      localStorage.setItem("penalex_calculos", JSON.stringify(prev));
      setModalGuardar(false);
      setNombreGuardar("");
      avisar(`Cálculo "${nombre}" guardado`);
    } catch (e) {
      avisar(`Error: ${e}`, "err");
    }
  };

  const confirmarCargar = (idx: number) => {
    try {
      const prev = JSON.parse(localStorage.getItem("penalex_calculos") ?? "[]");
      const c = prev[idx];
      if (!c) return;
      setDelitos(c.delitos);
      setConcurso(c.concurso);
      setAdmision(c.admisionHechos);
      setFraccionAdmision(c.fraccionAdmision);
      setSeleccion(c.delitos.map(() => true));
      setPaso(1);
      setModalCargar(false);
      avisar(`"${c.nombre}" cargado`);
    } catch (e) {
      avisar(`Error: ${e}`, "err");
    }
  };

  const eliminarCalculo = (idx: number) => {
    try {
      const prev = JSON.parse(localStorage.getItem("penalex_calculos") ?? "[]");
      prev.splice(idx, 1);
      localStorage.setItem("penalex_calculos", JSON.stringify(prev));
      setModalEliminar(null);
      avisar("Cálculo eliminado");
    } catch (e) {
      avisar(`Error: ${e}`, "err");
    }
  };

  const copiarReporte = () => {
    const lineas = [
      "INFORME TÉCNICO DE DOSIMETRÍA JURÍDICA",
      "=====================================",
      `Expediente: ${computo.expediente || "S/N"}`,
      `Acusado(s): ${computo.acusado || "No especificado"}`,
      `FECHA CUMPLIMIENTO ESTIMADA:\n${
        computoCalculado.fechaCumplimiento
          ? formatearFecha(computoCalculado.fechaCumplimiento)
          : "Sin detención registrada"
      }`,
      `TIEMPO DETENIDO: ${computoCalculado.tiempoDetenido}`,
      `TIEMPO POR CUMPLIR: ${computoCalculado.tiempoRestante}`,
      "DELITOS PROCESADOS:",
      ...delitos.map((d) => {
        const p = calcularPenaIndividualizada(d);
        return `- ${d.nombre || "SIN ESPECIFICAR"}: pena ${formatPena(d.penaMin)} - ${formatPena(d.penaMax)} (término medio ${formatPena(terminoMedio(d))}) -> ${formatYMD(p.pena)}`;
      }),
      `CONCURSO APLICADO: ${resultado.articuloAplicado}`,
      ...resultado.pasos.map((s) => `  - ${s}`),
    ];
    navigator.clipboard
      .writeText(lineas.join("\n"))
      .then(() => avisar("Reporte copiado al portapapeles"))
      .catch((e) => avisar(`Error al copiar: ${e}`, "err"));
  };

  const imprimirReporte = () => {
    const cuerpo = `
    <h2>INFORME TÉCNICO DE DOSIMETRÍA JURÍDICA</h2>
    <p><b>Expediente:</b> ${computo.expediente || "S/N"} &nbsp; <b>Acusado(s):</b> ${computo.acusado || "No especificado"}</p>
    <p><b>Fecha de cumplimiento estimada:</b> ${computoCalculado.fechaCumplimiento ? formatearFecha(computoCalculado.fechaCumplimiento) : "Sin detención registrada"}</p>
    <p><b>Tiempo detenido:</b> ${computoCalculado.tiempoDetenido}<br><b>Tiempo por cumplir:</b> ${computoCalculado.tiempoRestante}</p>
    <h3>1. DELITOS PROCESADOS</h3>
    <table border="1" cellpadding="6" style="border-collapse:collapse;width:100%">
      <tr><th>#</th><th>Delito</th><th>Pena mín</th><th>Pena máx</th><th>Término medio</th></tr>
      ${delitos.map((d, i) => `<tr><td>${i + 1}</td><td>${d.nombre || "SIN ESPECIFICAR"}</td><td>${formatPena(d.penaMin)}</td><td>${formatPena(d.penaMax)}</td><td>${formatPena(terminoMedio(d))}</td></tr>`).join("")}
    </table>
    <h3>2. CONCURSO DE DELITOS</h3>
    <p><b>Tipo de concurso aplicado:</b> ${resultado.articuloAplicado}</p>
    <ul>${resultado.pasos.map((s) => `<li>${s}</li>`).join("")}</ul>
    ${admision ? `<h3>3. ADMISIÓN DE HECHOS (Art. 375 COPP)</h3><p>Rebaja aplicada: ${fraccionTexto(fraccionAdmision)}</p>` : ""}
    <h3>${admision ? "4" : "3"}. PENA DEFINITIVA A IMPONER</h3>
    <p style="font-size:22px"><b>${formatYMD(resultado.total)}</b></p>
    <h3>${admision ? "5" : "4"}. CÓMPUTO DE PENA</h3>
    ${computo.sinDetenido || !computo.fechaDetencion ? "<p>Sin detención registrada</p>" : `<table border="1" cellpadding="6" style="border-collapse:collapse">
      <tr><td><b>Fecha de detención</b></td><td>${formatearFecha(computo.fechaDetencion!)}</td></tr>
      ${!computo.usarFechaActual && computo.fechaCondena ? `<tr><td><b>Fecha de condena</b></td><td>${formatearFecha(computo.fechaCondena)}</td></tr>` : ""}
      <tr><td><b>Tiempo detenido</b></td><td>${computoCalculado.tiempoDetenido}</td></tr>
      <tr><td><b>Tiempo restante</b></td><td>${computoCalculado.tiempoRestante}</td></tr>
      ${computoCalculado.fechaCumplimiento ? `<tr><td><b>Fecha de cumplimiento estimada</b></td><td>${formatearFecha(computoCalculado.fechaCumplimiento)}</td></tr>` : ""}
    </table>`}
    <p style="font-size:11px;color:#666">Este informe es una herramienta de asistencia técnica generada automáticamente. El resultado aquí expresado constituye una estimación basada en los parámetros introducidos y no sustituye el criterio jurídico, la interpretación de la norma ni la valoración del juez de la causa. La individualización judicial de la pena debe ser expresa, motivada y matemáticamente verificable (Véase sentencia N° 268, de fecha 28-05-2025, Sala de Casación Penal del TSJ). El uso de esta herramienta es responsabilidad exclusiva del profesional del derecho.</p>
    <p style="font-size:11px">Penalex VE - Dosimetría Penal Venezolana · Conforme al Código Penal y Leyes Especiales</p>`;
    const w = window.open("", "_blank", "width=900,height=700");
    if (!w) return;
    w.document.write(
      `<html><head><title>Informe de Dosimetría | Penalex VE</title><style>body{font-family:Georgia,serif;padding:24px;color:#111}h2{color:#c5a059;letter-spacing:2px}h3{color:#0F172A;margin-top:24px}</style></head><body>${cuerpo}<script>window.print()<\/script></body></html>`
    );
    w.document.close();
  };

  const botonSiguiente =
    "w-full rounded-md bg-[#0F172A] px-4 py-3 text-sm font-bold text-white hover:bg-[#1e293b]";
  const botonSecundario =
    "w-full rounded-md border border-[#e2e8f0] px-4 py-3 text-sm font-bold text-slate-600 hover:bg-[#f1f5f9]";

  return (
    <RequiereSesion>
      <Navbar />
      <main className="mx-auto w-full max-w-3xl flex-1 px-4 py-8">
        <div className="flex items-center justify-between">
          <h1 className="serif text-3xl font-bold text-[#0F172A]">
            Dosimetría Penal
          </h1>
          <div className="flex gap-2">
            <button
              onClick={() => setModalCargar(true)}
              className="rounded-md border border-[#e2e8f0] px-3 py-1.5 text-sm text-slate-600 hover:bg-[#f1f5f9]"
              title="Cargar cálculo"
            >
              <Icono nombre="documento" size={17} />
            </button>
            <button
              onClick={() => {
                setDelitos([delitoVacio(1)]);
                setSeleccion([true]);
                setPaso(1);
                avisar("Cálculo restablecido");
              }}
              className="rounded-md border border-[#e2e8f0] px-3 py-1.5 text-sm text-slate-600 hover:bg-[#f1f5f9]"
              title="Restablecer"
            >
              <Icono nombre="reiniciar" size={17} />
            </button>
            <BuscadorArticulos />
          </div>
        </div>

        <Stepper pasoActual={paso} />

        {paso === 1 && (
          <>
            <div className="mt-4 space-y-4">
              {delitos.map((d, idx) => (
                <DelitoForm
                  key={d.id}
                  delito={d}
                  idx={idx}
                  update={update}
                  quitar={quitar}
                  solo={delitos.length === 1}
                />
              ))}
            </div>

            <div className="mt-4">
              <button
                onClick={agregar}
                className="w-full rounded-md border-2 border-dashed border-[#e2e8f0] px-4 py-3 text-sm font-bold text-slate-600 hover:border-[#c5a059]/60 hover:text-[#C5A059]"
              >
                + AGREGAR OTRO DELITO
              </button>
            </div>

            {/* Sumatoria (barra inferior fiel a la app) */}
            <div className="mt-6 rounded-xl border-[1.5px] border-[#0F172A] bg-white p-4">
              <div className="text-[10px] font-extrabold uppercase tracking-[0.2em] text-[#0F172A]">
                Sumatoria de penas
              </div>
              <div className="mt-1 text-lg font-black text-[#0F172A]">
                {formatYMD(Math.min(sumatoria, 30))}
                {sumatoria > 30 ? " (topada a 30 años)" : ""}
              </div>
            </div>

            <div className="mt-6 grid grid-cols-2 gap-3">
              <button className={botonSecundario} onClick={() => routerBack()}>
                ← REGRESAR
              </button>
              <button className={botonSiguiente} onClick={() => setPaso(2)}>
                SIGUIENTE →
              </button>
            </div>
          </>
        )}

        {paso === 2 && (
          <>
            {/* Tipo de concurso */}
            <section className="mt-4 rounded-xl border border-[#e2e8f0] bg-white p-5">
              <h2 className="text-[11px] font-extrabold uppercase tracking-wider text-slate-600">
                Tipo de concurso
              </h2>
              <div className="mt-3 grid grid-cols-2 gap-2">
                {(
                  [
                    ["real", "Concurso Real (Material)"],
                    ["ideal", "Concurso Ideal (Formal)"],
                  ] as [TipoConcurso, string][]
                ).map(([val, label]) => (
                  <button
                    key={val}
                    onClick={() => setConcurso(val)}
                    className={`rounded-md border px-3 py-2.5 text-sm font-semibold ${
                      concurso === val
                        ? "border-[#c5a059] bg-[#c5a059]/15 text-[#C5A059]"
                        : "border-[#e2e8f0] text-slate-500 hover:bg-[#f1f5f9]"
                    }`}
                  >
                    {label}
                  </button>
                ))}
              </div>
              <p className="mt-3 text-xs leading-relaxed text-slate-500">
                {concurso === "real"
                  ? "Varios delitos independientes por varias acciones. Se acumulan las penas (Arts. 86, 87, 88 CP) sin exceder el triple de la pena del delito más grave ni los 30 años."
                  : "Una sola acción infringe varias disposiciones. Se aplica solo la pena del delito más grave (Art. 98 CP)."}
              </p>
            </section>

            {resultado.articuloAplicado && (
              <div className="mt-4 rounded-xl border border-[#c5a059]/40 bg-[#c5a059]/10 p-4">
                <div className="text-[10px] font-bold uppercase tracking-wider text-[#C5A059]">
                  Artículo aplicable
                </div>
                <div className="mt-1 text-sm font-semibold text-[#0F172A]">
                  {resultado.articuloAplicado}
                </div>
              </div>
            )}

            {/* Delitos participantes */}
            <section className="mt-4 rounded-xl border border-[#e2e8f0] bg-white p-5">
              <h2 className="text-[11px] font-extrabold uppercase tracking-wider text-slate-600">
                Delitos participantes
              </h2>
              <div className="mt-2 divide-y divide-[#e2e8f0]">
                {delitos.map((d, i) => {
                  const pena = calcularPenaIndividualizada(d).pena;
                  return (
                    <label key={d.id} className="flex cursor-pointer items-start gap-3 py-3">
                      <input
                        type="checkbox"
                        checked={seleccionActual[i]}
                        onChange={(e) =>
                          setSeleccion((s) => {
                            const n = [...s];
                            n[i] = e.target.checked;
                            return n;
                          })
                        }
                        className="mt-1 h-4 w-4 accent-[#c5a059]"
                      />
                      <div className="flex-1">
                        <div className="text-sm font-semibold text-[#0F172A]">
                          {d.nombre || `Delito ${i + 1}`}
                        </div>
                        <div className="text-xs text-slate-500">
                          Pena: {formatYMD(pena)}
                        </div>
                      </div>
                    </label>
                  );
                })}
              </div>
            </section>

            {/* Admisión de hechos */}
            <section className="mt-4 rounded-xl border border-[#e2e8f0] bg-white p-5">
              <h2 className="text-[11px] font-extrabold uppercase tracking-wider text-slate-600">
                Admisión de hechos (Art. 375 COPP)
              </h2>
              <label className="mt-3 flex items-center gap-2 text-sm text-slate-200">
                <input
                  type="checkbox"
                  checked={admision}
                  onChange={(e) => setAdmision(e.target.checked)}
                  className="h-4 w-4 accent-[#c5a059]"
                />
                Aplicar admisión de hechos
              </label>
              {admision && (
                <div className="mt-3">
                  <div className="text-sm text-slate-600">
                    Rebaja: {fraccionTexto(fraccionAdmision)}
                  </div>
                  <div className="mt-2 flex gap-2">
                    {[1 / 3, 0.5].map((f) => (
                      <button
                        key={f}
                        onClick={() => setFraccionAdmision(f)}
                        className={`rounded-md border px-4 py-1.5 text-sm ${
                          fraccionAdmision === f
                            ? "border-[#c5a059] bg-[#c5a059]/15 text-[#C5A059]"
                            : "border-[#e2e8f0] text-slate-500"
                        }`}
                      >
                        {fraccionTexto(f)}
                      </button>
                    ))}
                  </div>
                </div>
              )}
            </section>

            {/* Resultado */}
            <section className="mt-6 rounded-2xl border-2 border-[#c5a059] bg-white p-6">
              <div className="flex items-center justify-center gap-2">
                <span className="text-xs font-bold uppercase tracking-wider text-[#C5A059]">
                  Pena definitiva
                </span>
                {resultado.topeAplicado && (
                  <span className="rounded-full bg-orange-100 px-2 py-0.5 text-[10px] font-bold text-orange-700">
                    TOPE 30 AÑOS (Art. 94 CP)
                  </span>
                )}
              </div>
              <div className="mt-2 text-center text-3xl font-black text-[#C5A059]">
                {formatYMD(resultado.total)}
              </div>
              <div className="mt-3 text-center text-xs text-slate-500">
                {resultado.articuloAplicado || "Delito único (sin concurso)"}
              </div>

              <button
                onClick={() => setVerDesglose(!verDesglose)}
                className="mx-auto mt-4 block text-xs font-bold uppercase tracking-wider text-[#C5A059] hover:text-[#C5A059]"
              >
                {verDesglose ? "▲ Ocultar desglose" : "▼ Ver desglose paso a paso"}
              </button>
              {verDesglose && (
                <div className="mt-3 max-h-64 space-y-1.5 overflow-y-auto rounded-lg border border-[#e2e8f0] bg-[#F1F5F9] p-4">
                  {resultado.pasos.map((p, i) => (
                    <p
                      key={i}
                      className={`text-xs leading-relaxed ${
                        i === resultado.pasos.length - 1
                          ? "font-bold text-[#C5A059]"
                          : "text-slate-500"
                      }`}
                    >
                      - {p}
                    </p>
                  ))}
                </div>
              )}
            </section>

            <div className="mt-6 grid grid-cols-2 gap-3">
              <button className={botonSecundario} onClick={() => setPaso(1)}>
                ← Anterior
              </button>
              <button className={botonSiguiente} onClick={() => setPaso(3)}>
                SIGUIENTE →
              </button>
            </div>
          </>
        )}

        {paso === 3 && (
          <ComputoPaso
            computo={computo}
            setComputo={setComputo}
            resultadoTotal={resultado.total}
            resultadoArticulo={resultado.articuloAplicado}
            delitos={delitos}
            resultado={resultado}
            admision={admision}
            fraccionAdmision={fraccionAdmision}
            computoCalculado={computoCalculado}
            fechaCondenaMostrada={fechaCondenaMostrada}
            guardarDatos={() => {
              setNombreGuardar("");
              setModalGuardar(true);
            }}
            imprimirReporte={imprimirReporte}
            copiarReporte={copiarReporte}
            irAtras={() => setPaso(2)}
            irInicio={() => setPaso(1)}
          />
        )}

        {/* Toast */}
        {toast && (
          <div
            className={`fixed bottom-6 left-1/2 z-[60] -translate-x-1/2 rounded-md px-4 py-2.5 text-sm font-semibold text-[#0F172A] shadow-lg ${
              toast.tipo === "ok" ? "bg-emerald-600" : "bg-red-600"
            }`}
          >
            {toast.texto}
          </div>
        )}

        {/* Modal guardar */}
        {modalGuardar && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4">
            <div className="w-full max-w-sm rounded-2xl border border-[#e2e8f0] bg-white p-6 shadow-2xl">
              <h3 className="serif text-base font-bold text-[#0F172A]">Guardar cálculo</h3>
              <input
                value={nombreGuardar}
                onChange={(e) => setNombreGuardar(e.target.value)}
                placeholder="Nombre del cálculo"
                autoFocus
                className="mt-3 w-full rounded-md border border-[#e2e8f0] bg-[#F1F5F9] px-3 py-2 text-sm text-[#0F172A] focus:border-[#c5a059] focus:outline-none"
              />
              <div className="mt-5 flex justify-end gap-2">
                <button
                  onClick={() => setModalGuardar(false)}
                  className="rounded-md px-4 py-2 text-sm font-medium text-slate-500 hover:bg-[#f1f5f9]"
                >
                  Cancelar
                </button>
                <button
                  onClick={confirmarGuardar}
                  disabled={!nombreGuardar.trim()}
                  className="rounded-md bg-[#c5a059] px-4 py-2 text-sm font-semibold text-[#0F172A] hover:bg-[#e9c86a] disabled:opacity-50"
                >
                  Guardar
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Modal cargar */}
        {modalCargar && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4">
            <div className="flex max-h-[80vh] w-full max-w-md flex-col rounded-2xl border border-[#e2e8f0] bg-white p-6 shadow-2xl">
              <div className="flex items-center justify-between">
                <h3 className="text-xs font-extrabold tracking-widest text-[#C5A059]">
                  CÁLCULOS GUARDADOS
                </h3>
                <button
                  onClick={() => setModalCargar(false)}
                  className="text-2xl leading-none text-slate-500 hover:text-[#0F172A]"
                >
                  ×
                </button>
              </div>
              <div className="mt-3 flex-1 space-y-2 overflow-y-auto">
                {(() => {
                  let lista: CalculoGuardado[] = [];
                  try {
                    lista = JSON.parse(localStorage.getItem("penalex_calculos") ?? "[]");
                  } catch {}
                  if (lista.length === 0)
                    return (
                      <div className="py-10 text-center">
                        <div className="text-5xl"><Icono nombre="documento" size={44} /></div>
                        <div className="mt-3 text-lg font-bold text-[#0F172A]">
                          No hay cálculos guardados
                        </div>
                        <div className="mt-1 text-sm text-slate-500">
                          Guarda tus cálculos desde la calculadora
                        </div>
                      </div>
                    );
                  return lista.map((c, i) => (
                    <div
                      key={i}
                      className="flex items-center justify-between rounded-lg border border-[#e2e8f0] bg-[#F1F5F9] p-3"
                    >
                      <button
                        onClick={() => confirmarCargar(i)}
                        className="flex flex-1 items-center gap-3 text-left"
                      >
                        <span className="flex h-10 w-10 items-center justify-center rounded-lg bg-[#c5a059]/15 text-lg">
                          <Icono nombre="calculadora" size={19} />
                        </span>
                        <span>
                          <span className="block text-sm font-bold text-[#0F172A]">
                            {c.nombre}
                          </span>
                          <span className="block text-xs text-slate-500">
                            {c.delitos?.length ?? 0} delito(s) ·{" "}
                            {c.guardadoEn
                              ? new Date(c.guardadoEn).toLocaleDateString("es-VE")
                              : ""}
                          </span>
                        </span>
                      </button>
                      <button
                        onClick={() => setModalEliminar(i)}
                        className="ml-2 text-red-500 hover:text-red-400"
                        title="Eliminar"
                      >
                        <Icono nombre="papelera" size={17} />
                      </button>
                    </div>
                  ));
                })()}
              </div>
            </div>
          </div>
        )}

        {/* Modal confirmar eliminación */}
        {modalEliminar !== null && (
          <div className="fixed inset-0 z-[70] flex items-center justify-center bg-black/60 p-4">
            <div className="w-full max-w-sm rounded-2xl border border-[#e2e8f0] bg-white p-6 shadow-2xl">
              <h3 className="serif text-base font-bold text-[#0F172A]">Eliminar cálculo</h3>
              <p className="mt-2 text-sm text-slate-500">
                ¿Estás seguro de que quieres eliminar este cálculo?
              </p>
              <div className="mt-5 flex justify-end gap-2">
                <button
                  onClick={() => setModalEliminar(null)}
                  className="rounded-md px-4 py-2 text-sm font-medium text-slate-500 hover:bg-[#f1f5f9]"
                >
                  Cancelar
                </button>
                <button
                  onClick={() => eliminarCalculo(modalEliminar)}
                  className="rounded-md bg-red-600 px-4 py-2 text-sm font-semibold text-[#0F172A] hover:bg-red-500"
                >
                  Eliminar
                </button>
              </div>
            </div>
          </div>
        )}
      </main>
    </RequiereSesion>
  );
}

// Navegación hacia atrás (usamos history si está disponible)
function routerBack() {
  if (typeof window !== "undefined" && window.history.length > 1) {
    window.history.back();
  }
}

// ---------------------------------------------------------------------------
// Paso 3: Cómputo (fiel al computo_page.dart)
// ---------------------------------------------------------------------------
function ComputoPaso({
  computo,
  setComputo,
  resultadoTotal,
  resultadoArticulo,
  delitos,
  resultado,
  admision,
  fraccionAdmision,
  computoCalculado,
  fechaCondenaMostrada,
  guardarDatos,
  imprimirReporte,
  copiarReporte,
  irAtras,
  irInicio,
}: {
  computo: DatosComputo;
  setComputo: React.Dispatch<React.SetStateAction<DatosComputo>>;
  resultadoTotal: number;
  resultadoArticulo: string;
  delitos: Delito[];
  resultado: { total: number; pasos: string[]; topeAplicado: boolean; articuloAplicado: string };
  admision: boolean;
  fraccionAdmision: number;
  computoCalculado: {
    tiempoDetenido: string;
    tiempoRestante: string;
    fechaCumplimiento: Date | null;
  };
  fechaCondenaMostrada: Date | null;
  guardarDatos: () => void;
  imprimirReporte: () => void;
  copiarReporte: () => void;
  irAtras: () => void;
  irInicio: () => void;
}) {
  const [errores, setErrores] = useState<{ detencion?: boolean; condena?: boolean }>({});

  const actualizarDetencion = (texto: string) => {
    const t = aplicarMascaraFecha(texto);
    setComputo((c) => ({ ...c, fechaDetencionTexto: t }));
    if (computo.sinDetenido) return;
    if (!t) {
      setComputo((c) => ({ ...c, fechaDetencion: null }));
      setErrores((e) => ({ ...e, detencion: false }));
      return;
    }
    const f = parsearFecha(t);
    if (!f || f.getTime() > Date.now()) {
      setErrores((e) => ({ ...e, detencion: true }));
      setComputo((c) => ({ ...c, fechaDetencion: null }));
      return;
    }
    setErrores((e) => ({ ...e, detencion: false }));
    setComputo((c) => ({ ...c, fechaDetencion: f }));
  };

  const actualizarCondena = (texto: string) => {
    const t = aplicarMascaraFecha(texto);
    setComputo((c) => ({ ...c, fechaCondenaTexto: t }));
    if (!t) {
      setComputo((c) => ({ ...c, fechaCondena: null }));
      setErrores((e) => ({ ...e, condena: false }));
      return;
    }
    const f = parsearFecha(t);
    if (!f) {
      setErrores((e) => ({ ...e, condena: true }));
      setComputo((c) => ({ ...c, fechaCondena: null }));
      return;
    }
    setErrores((e) => ({ ...e, condena: false }));
    setComputo((c) => ({ ...c, fechaCondena: f }));
  };

  const fechaDet = computo.fechaDetencion;
  const fechaCon = fechaCondenaMostrada;
  const campo =
    "w-full rounded-md border border-[#e2e8f0] bg-[#F1F5F9] px-3 py-2 text-sm text-[#0F172A] focus:border-[#c5a059] focus:outline-none";

  return (
    <div className="mt-4 space-y-4">
      {/* Datos del caso */}
      <section className="rounded-xl border border-[#e2e8f0] bg-white p-5">
        <h2 className="text-[11px] font-extrabold uppercase tracking-wider text-slate-600">
          DATOS DEL CASO
        </h2>
        <div className="mt-3 space-y-3">
          <div>
            <label className="text-xs font-medium text-slate-500">Nº de Expediente</label>
            <input
              value={computo.expediente}
              onChange={(e) => setComputo((c) => ({ ...c, expediente: e.target.value }))}
              placeholder="Ej: 123-2024"
              className={`${campo} mt-1`}
            />
          </div>
          <div>
            <label className="text-xs font-medium text-slate-500">Acusado(s) / Justiciable(s)</label>
            <input
              value={computo.acusado}
              onChange={(e) => setComputo((c) => ({ ...c, acusado: e.target.value }))}
              placeholder="Nombre completo del acusado"
              className={`${campo} mt-1`}
            />
          </div>
          <p className="text-[11px] italic text-slate-500">
            Estos datos aparecerán en el informe PDF
          </p>
        </div>
      </section>

      {/* Resultados (tarjeta navy de contraste, como en la app) */}
      <section className="rounded-2xl bg-gradient-to-br from-[#0F172A] to-[#1e293b] p-6 shadow-lg ring-1 ring-[#c5a059]/40">
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-full bg-[#c5a059]/20 ring-1 ring-[#c5a059]/50">
            <Icono nombre="fecha" size={20} className="text-[#c5a059]" />
          </div>
          <div>
            <div className="text-[10px] font-bold uppercase tracking-wider text-[#c5a059]">
              Fecha cumplimiento estimada
            </div>
            <div className="text-2xl font-black text-white">
              {computoCalculado.fechaCumplimiento
                ? formatearFecha(computoCalculado.fechaCumplimiento)
                : "Sin detención registrada"}
            </div>
          </div>
        </div>
        <div className="mt-4 border-t border-[#334155] pt-4">
          <div className="flex items-center justify-between py-1">
            <span className="flex items-center gap-2 text-sm text-slate-300">
              <Icono nombre="candado" size={15} className="text-[#c5a059]" />
              Tiempo detenido
            </span>
            <span className="text-sm font-semibold text-white">
              {computoCalculado.tiempoDetenido}
            </span>
          </div>
          <div className="flex items-center justify-between py-1">
            <span className="flex items-center gap-2 text-sm text-slate-300">
              <Icono nombre="reloj" size={15} className="text-[#c5a059]" />
              Tiempo por cumplir
            </span>
            <span className="text-sm font-bold text-[#e9c86a]">
              {computoCalculado.tiempoRestante}
            </span>
          </div>
        </div>
      </section>

      {/* Línea de tiempo */}
      <section className="rounded-xl border-2 border-[#c5a059]/50 bg-white p-5">
        <h2 className="text-[11px] font-extrabold uppercase tracking-wider text-[#C5A059]">
          LÍNEA DE TIEMPO DEL CÓMPUTO
        </h2>
        <div className="mt-4 grid grid-cols-3 gap-2 text-center">
          {[
            { label: "DETENCIÓN", fecha: fechaDet ? formatearFecha(fechaDet) : "—", valido: !!fechaDet },
            { label: "CONDENA", fecha: fechaCon ? formatearFecha(fechaCon) : "—", valido: !!fechaCon },
            {
              label: "CUMPLIMIENTO",
              fecha: computoCalculado.fechaCumplimiento
                ? formatearFecha(computoCalculado.fechaCumplimiento)
                : "—",
              valido: !!computoCalculado.fechaCumplimiento,
            },
          ].map((n, i) => (
            <div key={n.label}>
              <div
                className={`mx-auto flex h-9 w-9 items-center justify-center rounded-full border-2 text-xs font-bold ${
                  n.valido
                    ? "border-[#c5a059] bg-[#c5a059]/15 text-[#C5A059]"
                    : "border-[#e2e8f0] bg-[#F1F5F9] text-slate-500"
                }`}
              >
                {i + 1}
              </div>
              <div className={`mt-2 text-[10px] font-bold uppercase tracking-wide ${n.valido ? "text-[#C5A059]" : "text-slate-500"}`}>
                {n.label}
              </div>
              <div className="text-xs font-semibold text-[#0F172A]">{n.fecha}</div>
            </div>
          ))}
        </div>
      </section>

      {/* Fechas */}
      <section className="rounded-xl border border-[#e2e8f0] bg-white p-5">
        <h2 className="text-[11px] font-extrabold uppercase tracking-wider text-slate-600">
          FECHA DE DETENCIÓN
        </h2>
        <label className="mt-2 flex items-center gap-2 text-sm text-slate-200">
          <input
            type="checkbox"
            checked={computo.sinDetenido}
            onChange={(e) => {
              const s = e.target.checked;
              setComputo((c) => ({
                ...c,
                sinDetenido: s,
                fechaDetencion: s ? null : c.fechaDetencion,
                fechaDetencionTexto: s ? "" : c.fechaDetencionTexto,
              }));
            }}
            className="h-4 w-4 accent-[#c5a059]"
          />
          Sin detenido
        </label>
        {!computo.sinDetenido && (
          <div className="mt-2">
            <input
              value={computo.fechaDetencionTexto}
              onChange={(e) => actualizarDetencion(e.target.value)}
              placeholder="DD/MM/AAAA"
              className={`${campo} ${errores.detencion ? "border-red-500" : ""}`}
            />
            {errores.detencion && (
              <div className="mt-1 text-xs text-red-400">Fecha inválida</div>
            )}
          </div>
        )}

        <div className="mt-4 border-t border-[#e2e8f0] pt-4">
          <h2 className="text-[11px] font-extrabold uppercase tracking-wider text-slate-600">
            FECHA DE CONDENA
          </h2>
          <label className="mt-2 flex items-center gap-2 text-sm text-slate-200">
            <input
              type="checkbox"
              checked={computo.usarFechaActual}
              onChange={(e) => {
                const u = e.target.checked;
                setComputo((c) => ({
                  ...c,
                  usarFechaActual: u,
                  fechaCondena: u ? null : c.fechaCondena,
                  fechaCondenaTexto: u ? "" : c.fechaCondenaTexto,
                }));
              }}
              className="h-4 w-4 accent-[#c5a059]"
            />
            Usar fecha actual
          </label>
          {!computo.usarFechaActual && (
            <div className="mt-2">
              <input
                value={computo.fechaCondenaTexto}
                onChange={(e) => actualizarCondena(e.target.value)}
                placeholder="DD/MM/AAAA"
                className={`${campo} ${errores.condena ? "border-red-500" : ""}`}
              />
              {errores.condena && (
                <div className="mt-1 text-xs text-red-400">Fecha inválida</div>
              )}
            </div>
          )}
        </div>
      </section>

      {/* Acciones */}
      <section className="grid grid-cols-2 gap-2 sm:grid-cols-3">
        <button
          onClick={guardarDatos}
          className="flex items-center justify-center gap-2 rounded-md border border-[#e2e8f0] px-3 py-2 text-sm text-slate-600 hover:bg-[#f1f5f9]"
        >
          <Icono nombre="guardar" size={15} className="text-[#C5A059]" />
          Guardar Datos
        </button>
        <button
          onClick={imprimirReporte}
          className="flex items-center justify-center gap-2 rounded-md border border-[#e2e8f0] px-3 py-2 text-sm text-slate-600 hover:bg-[#f1f5f9]"
        >
          <Icono nombre="impresora" size={15} className="text-[#C5A059]" />
          PDF Descargar
        </button>
        <button
          onClick={copiarReporte}
          className="flex items-center justify-center gap-2 rounded-md border border-[#e2e8f0] px-3 py-2 text-sm text-slate-600 hover:bg-[#f1f5f9]"
        >
          <Icono nombre="copiar" size={15} className="text-[#C5A059]" />
          Copiar
        </button>
      </section>

      {/* Pena total resumen */}
      <section className="rounded-xl border border-[#e2e8f0] bg-white p-4 text-sm">
        <div className="flex justify-between">
          <span className="text-slate-500">Pena definitiva</span>
          <span className="font-bold text-[#C5A059]">{formatYMD(resultadoTotal)}</span>
        </div>
        <div className="mt-1 flex justify-between">
          <span className="text-slate-500">Concurso</span>
          <span className="font-semibold text-[#0F172A]">{resultadoArticulo}</span>
        </div>
      </section>

      <div className="grid grid-cols-2 gap-2">
        <button
          onClick={irAtras}
          className="rounded-md border border-[#e2e8f0] px-4 py-3 text-sm font-bold text-slate-600 hover:bg-[#f1f5f9]"
        >
          ← REGRESAR
        </button>
        <button
          onClick={irInicio}
          className="rounded-md bg-[#c5a059] px-4 py-3 text-sm font-bold text-[#0F172A] hover:bg-[#e9c86a]"
        >
          INICIO
        </button>
      </div>
    </div>
  );
}