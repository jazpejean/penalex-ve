"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import {
  listarTribunalesConUbicacion,
  listarEstadosTribunales,
  type Tribunal,
  circunscripcionJudicial,
} from "../lib/tribunales";

declare global {
  interface Window {
    L: any;
  }
}

function cargarLeaflet(): Promise<void> {
  return new Promise((resolve) => {
    if (window.L) return resolve();
    const css = document.createElement("link");
    css.rel = "stylesheet";
    css.href = "/leaflet/leaflet.css";
    document.head.appendChild(css);
    const js = document.createElement("script");
    js.src = "/leaflet/leaflet.js";
    js.onload = () => resolve();
    document.head.appendChild(js);
  });
}

const COLORES: Record<string, string> = {
  CONTROL: "#1d4ed8",
  JUICIO: "#6d28d9",
  EJECUCIÓN: "#c2410c",
  APELACIÓN: "#0f766e",
};

function colorFuncion(f: string | null | undefined): string {
  return COLORES[(f ?? "").toUpperCase()] ?? "#4b5563";
}

const circuitoDe = circunscripcionJudicial;

type Modo = "circuitos" | "tribunales";

export default function MapaTribunales() {
  const mapRef = useRef<HTMLDivElement>(null);
  const mapInstance = useRef<any>(null);
  const markersRef = useRef<any[]>([]);

  const [tribunales, setTribunales] = useState<Tribunal[]>([]);
  const [estados, setEstados] = useState<string[]>([]);
  const [cargando, setCargando] = useState(true);
  const [mapaActivo, setMapaActivo] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [modo, setModo] = useState<Modo>("circuitos");
  const [circuitoSel, setCircuitoSel] = useState<string | null>(null);

  const [busqueda, setBusqueda] = useState("");
  const [filtroEstado, setFiltroEstado] = useState("");
  const [filtroFuncion, setFiltroFuncion] = useState("");

  useEffect(() => {
    (async () => {
      try {
        const [tribs, est] = await Promise.all([
          listarTribunalesConUbicacion(),
          listarEstadosTribunales(),
        ]);
        setTribunales(tribs);
        setEstados(est);
      } catch (e: any) {
        setError(e?.message ?? "Error cargando tribunales");
      } finally {
        setCargando(false);
      }
    })();
  }, []);

  const funciones = useMemo(
    () =>
      [...new Set(tribunales.map((t) => t.funcion ?? "").filter(Boolean))].sort(),
    [tribunales],
  );

  const visibles = useMemo(() => {
    const q = busqueda.trim().toLowerCase();
    return tribunales.filter((t) => {
      if (q) {
        const haystack = [
          t.nombre,
          t.codigo,
          t.sede ?? "",
          t.municipio ?? "",
          t.estado,
          t.parroquia ?? "",
          circuitoDe(t),
        ]
          .join(" ")
          .toLowerCase();
        if (!haystack.includes(q)) return false;
      }
      if (filtroEstado && t.estado !== filtroEstado) return false;
      if (filtroFuncion && (t.funcion ?? "") !== filtroFuncion) return false;
      return true;
    });
  }, [tribunales, busqueda, filtroEstado, filtroFuncion]);

  const hayFiltros = Boolean(busqueda || filtroEstado || filtroFuncion);

  function limpiarFiltros() {
    setBusqueda("");
    setFiltroEstado("");
    setFiltroFuncion("");
    setCircuitoSel(null);
  }

  /** Grupos por circuito judicial con su centroide. */
  const circuitos = useMemo(() => {
    const grupos = new Map<string, Tribunal[]>();
    for (const t of visibles) {
      const c = circuitoDe(t);
      if (!grupos.has(c)) grupos.set(c, []);
      grupos.get(c)!.push(t);
    }
    const lista = [...grupos.entries()].map(([nombre, grupo]) => {
      const conGeo = grupo.filter((t) => t.latitud != null && t.longitud != null);
      const centro =
        conGeo.length > 0
          ? {
              lat:
                conGeo.reduce((a, t) => a + (t.latitud as number), 0) /
                conGeo.length,
              lng:
                conGeo.reduce((a, t) => a + (t.longitud as number), 0) /
                conGeo.length,
            }
          : null;
      return { nombre, grupo, centro };
    });
    return lista.sort((a, b) => a.nombre.localeCompare(b.nombre));
  }, [visibles]);

  const tribunalesDelCircuito = useMemo(
    () =>
      circuitoSel
        ? visibles.filter((t) => circuitoDe(t) === circuitoSel)
        : [],
    [visibles, circuitoSel],
  );

  useEffect(() => {
    if (!mapRef.current || !tribunales.length) return;
    let cancelled = false;

    (async () => {
      await cargarLeaflet();
      if (cancelled) return;
      const L = window.L;
      if (!mapInstance.current) {
        mapInstance.current = L.map(mapRef.current, {
          scrollWheelZoom: false,
          dragging: false,
          tap: true,
        }).setView([9.3, -66.2], 5.6);
        L.tileLayer("https://tile.openstreetmap.org/{z}/{x}/{y}.png", {
          attribution: "&copy; OpenStreetMap",
          maxZoom: 18,
        }).addTo(mapInstance.current);
      }
      markersRef.current.forEach((m) => mapInstance.current.removeLayer(m));
      markersRef.current = [];

      if (modo === "circuitos") {
        // Un marcador por CIRCUITO con su conteo (mucho más rápido y legible).
        for (const c of circuitos) {
          if (!c.centro) continue;
          const seleccionado = circuitoSel === c.nombre;
          const icono = L.divIcon({
            className: "",
            html: `
              <div style="display:flex;flex-direction:column;align-items:center;gap:2px;">
                <div style="width:26px;height:26px;border-radius:50%;background:${
                  seleccionado ? "#C5A059" : "#0F172A"
                };border:2.5px solid #fff;display:flex;align-items:center;justify-content:center;font-size:12px;box-shadow:0 2px 6px rgba(0,0,0,.35);"></div>
                <div style="background:#fff;border:1px solid ${
                  seleccionado ? "#C5A059" : "#0F172A"
                };border-radius:10px;font-size:10px;font-weight:800;color:${
                  seleccionado ? "#C5A059" : "#0F172A"
                };padding:0 5px;">${c.grupo.length}</div>
              </div>`,
            iconSize: [44, 60],
            iconAnchor: [22, 30],
          });
          const marker = L.marker([c.centro.lat, c.centro.lng], { icon: icono })
            .addTo(mapInstance.current)
            .on("click", () => {
              setCircuitoSel(c.nombre);
              mapInstance.current.setView([c.centro!.lat, c.centro!.lng], 8.2, {
                animate: true,
              });
            });
          markersRef.current.push(marker);
        }
      } else {
        // Modo tribunales: marcadores individuales con popup.
        const grupos = new Map<string, Tribunal[]>();
        for (const t of visibles) {
          if (t.latitud == null || t.longitud == null) continue;
          const clave = `${t.latitud.toFixed(4)},${t.longitud.toFixed(4)}`;
          if (!grupos.has(clave)) grupos.set(clave, []);
          grupos.get(clave)!.push(t);
        }
        const radio = 0.0016;
        for (const grupo of grupos.values()) {
          grupo.forEach((t, i) => {
            const ang = i * 2.399963;
            const d = radio * (0.4 + i * 0.22);
            const punto = [
              (t.latitud as number) + d * Math.cos(ang),
              (t.longitud as number) + d * Math.sin(ang),
            ];
            const icono = L.divIcon({
              className: "",
              html: `<div style="width:34px;height:34px;border-radius:50%;background:${colorFuncion(
                t.funcion,
              )};border:2px solid #fff;display:flex;align-items:center;justify-content:center;color:#fff;font-size:16px;box-shadow:0 2px 5px rgba(0,0,0,.3);"></div>`,
              iconSize: [34, 34],
              iconAnchor: [17, 17],
            });
            const marker = L.marker(punto, { icon: icono })
              .addTo(mapInstance.current)
              .bindPopup(
                `<strong>${t.nombre}</strong><br/>${[
                  t.funcion,
                  t.municipio,
                  t.sede,
                ]
                  .filter(Boolean)
                  .join(" · ")}`,
              );
            markersRef.current.push(marker);
          });
        }
      }
    })();

    return () => {
      cancelled = true;
    };
  }, [tribunales, visibles, circuitos, modo, circuitoSel]);

  function irATribunal(t: Tribunal) {
    if (t.latitud == null || t.longitud == null) return;
    setModo("tribunales");
    setTimeout(() => {
      mapInstance.current?.setView([t.latitud as number, t.longitud as number], 14);
    }, 150);
  }

  if (error) {
    return (
      <div className="p-6 text-sm text-red-600">
        No se pudieron cargar los tribunales: {error}
      </div>
    );
  }

  return (
    <div>
      {/* Buscador y filtros */}
      <div className="border-b border-slate-200 bg-white p-3">
        <div className="flex flex-col gap-2 sm:flex-row sm:items-center">
          <input
            value={busqueda}
            onChange={(e) => setBusqueda(e.target.value)}
            placeholder="Busca tu tribunal: nombre, sede, municipio o circuito (ej. Los Teques)…"
            className="w-full rounded-lg border border-slate-200 px-3 py-2 text-sm outline-none focus:border-[#031F4E]"
          />
          <select
            value={filtroEstado}
            onChange={(e) => setFiltroEstado(e.target.value)}
            className="rounded-lg border border-slate-200 px-3 py-2 text-sm"
          >
            <option value="">Todos los estados</option>
            {estados.map((e) => (
              <option key={e} value={e}>
                {e}
              </option>
            ))}
          </select>
          <select
            value={filtroFuncion}
            onChange={(e) => setFiltroFuncion(e.target.value)}
            className="rounded-lg border border-slate-200 px-3 py-2 text-sm"
          >
            <option value="">Todas las funciones</option>
            {funciones.map((f) => (
              <option key={f} value={f}>
                {f}
              </option>
            ))}
          </select>
        </div>
        <div className="mt-2 flex flex-wrap items-center justify-between gap-2">
          <div className="inline-flex rounded-lg bg-slate-100 p-1 text-xs font-bold">
            <button
              onClick={() => {
                setModo("circuitos");
                setCircuitoSel(null);
              }}
              className={`rounded-md px-3 py-1.5 ${
                modo === "circuitos" ? "bg-white text-[#031F4E] shadow" : "text-slate-500"
              }`}
            >
               Circuitos
            </button>
            <button
              onClick={() => setModo("tribunales")}
              className={`rounded-md px-3 py-1.5 ${
                modo === "tribunales" ? "bg-white text-[#031F4E] shadow" : "text-slate-500"
              }`}
            >
               Tribunales
            </button>
          </div>
          <span className="text-xs text-slate-500">
            {modo === "circuitos"
              ? `${circuitos.length} circuitos · ${visibles.length} tribunales`
              : `${visibles.length} tribunales`}
            {hayFiltros ? (
              <button
                onClick={limpiarFiltros}
                className="ml-2 text-[#031F4E] underline"
              >
                Limpiar filtros
              </button>
            ) : null}
          </span>
        </div>
      </div>


      {/* Resultados del buscador: la lista aparece aquí, no en una lista fija */}
      {hayFiltros ? (
        <div className="max-h-72 overflow-auto border-b border-slate-200 bg-white">
          {visibles.length === 0 ? (
            <p className="p-4 text-center text-xs text-slate-500">
              Sin resultados. Prueba con el nombre del tribunal, la sede, el
              municipio o el circuito.
            </p>
          ) : (
            <ul className="divide-y divide-slate-100">
              {visibles.slice(0, 40).map((t) => (
                <li key={t.id} className="flex items-start gap-3 px-3 py-2">
                  {t.url_foto ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img
                      src={t.url_foto}
                      alt={`Foto del ${t.nombre}`}
                      loading="lazy"
                      className="h-14 w-14 shrink-0 rounded-lg object-cover"
                      onError={(e) => {
                        (e.currentTarget as HTMLImageElement).style.display = "none";
                      }}
                    />
                  ) : null}
                  <div className="min-w-0 flex-1">
                    <div className="text-xs font-semibold text-[#031F4E]">
                      {t.nombre}
                    </div>
                    <div className="text-[11px] text-slate-500">
                      {[t.funcion, t.municipio, t.parroquia, circuitoDe(t)]
                        .filter(Boolean)
                        .join(" · ")}
                    </div>
                    <div className="mt-1 flex flex-wrap gap-1.5">
                      <button
                        onClick={() => irATribunal(t)}
                        className="rounded-md border border-slate-200 px-2 py-0.5 text-[10.5px] font-semibold text-[#031F4E] hover:bg-slate-50"
                      >
                         Ver en el mapa
                      </button>
                      {t.latitud != null && t.longitud != null ? (
                        <a
                          href={`https://www.google.com/maps?q=${t.latitud},${t.longitud}`}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="rounded-md bg-[#0F172A] px-2 py-0.5 text-[10.5px] font-semibold text-white hover:bg-[#1e293b]"
                        >
                           Google Maps
                        </a>
                      ) : null}
                    </div>
                  </div>
                </li>
              ))}
            </ul>
          )}
        </div>
      ) : null}

      {/* Mapa */}
      <div className="relative">
        <div ref={mapRef} className="h-[520px] w-full" />
        <button
          type="button"
          onClick={() => {
            const m = mapInstance.current;
            if (!m) return;
            if (m.dragging.enabled()) {
              m.dragging.disable();
              m.scrollWheelZoom.disable();
              setMapaActivo(false);
            } else {
              m.dragging.enable();
              m.scrollWheelZoom.enable();
              setMapaActivo(true);
            }
          }}
          className="absolute right-3 top-3 z-[500] rounded-md bg-white px-3 py-1.5 text-xs font-semibold text-[#031F4E] shadow-md ring-1 ring-slate-200"
        >
          {mapaActivo ? "Bloquear mapa" : "Mover mapa"}
        </button>
        {cargando ? (
          <div className="absolute inset-0 flex items-center justify-center bg-white/70 text-sm text-slate-500">
            Cargando mapa…
          </div>
        ) : null}

        {/* Panel del circuito seleccionado */}
        {modo === "circuitos" && circuitoSel ? (
          <div className="absolute bottom-3 left-3 right-3 max-h-64 overflow-auto rounded-xl border border-slate-200 bg-white p-3 shadow-xl sm:left-3 sm:right-auto sm:w-96">
            <div className="flex items-start justify-between gap-2">
              <div>
                <div className="text-sm font-bold text-[#031F4E]">{circuitoSel}</div>
                <div className="text-[11px] text-slate-500">
                  {tribunalesDelCircuito.length} tribunales penales
                </div>
              </div>
              <button
                onClick={() => setCircuitoSel(null)}
                className="text-slate-400 hover:text-slate-600"
                aria-label="Cerrar"
              >
                
              </button>
            </div>
            <ul className="mt-2 divide-y divide-slate-100">
              {tribunalesDelCircuito.map((t) => (
                <li key={t.id} className="py-2">
                  <div className="flex items-start justify-between gap-2">
                    {t.url_foto ? (
                      // eslint-disable-next-line @next/next/no-img-element
                      <img
                        src={t.url_foto}
                        alt={`Foto del ${t.nombre}`}
                        loading="lazy"
                        className="mt-0.5 h-12 w-12 shrink-0 rounded-md object-cover"
                        onError={(e) => {
                          (e.currentTarget as HTMLImageElement).style.display = "none";
                        }}
                      />
                    ) : null}
                    <div className="min-w-0">
                      <div className="text-xs font-semibold text-[#031F4E]">
                        {t.nombre}
                      </div>
                      <div className="text-[11px] text-slate-500">
                        {[t.municipio, t.parroquia, t.sede]
                          .filter(Boolean)
                          .join(" · ")}
                      </div>
                      {t.latitud != null && t.longitud != null ? (
                        <div className="mt-0.5 font-mono text-[10px] text-slate-400">
                          {t.latitud.toFixed(5)}, {t.longitud.toFixed(5)}
                        </div>
                      ) : null}
                    </div>
                    {t.funcion ? (
                      <span
                        className="mt-0.5 shrink-0 rounded-full px-2 py-0.5 text-[9px] font-bold uppercase text-white"
                        style={{ background: colorFuncion(t.funcion) }}
                      >
                        {t.funcion}
                      </span>
                    ) : null}
                  </div>
                  <div className="mt-1.5 flex flex-wrap gap-1.5">
                    <button
                      onClick={() => irATribunal(t)}
                      className="rounded-md border border-slate-200 px-2 py-1 text-[10.5px] font-semibold text-[#031F4E] hover:bg-slate-50"
                    >
                       Ver en el mapa
                    </button>
                    {t.latitud != null && t.longitud != null ? (
                      <a
                        href={`https://www.google.com/maps?q=${t.latitud},${t.longitud}`}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="rounded-md bg-[#0F172A] px-2 py-1 text-[10.5px] font-semibold text-white hover:bg-[#1e293b]"
                      >
                         Google Maps
                      </a>
                    ) : null}
                  </div>
                </li>
              ))}
            </ul>
          </div>
        ) : null}
      </div>
    </div>
  );
}
