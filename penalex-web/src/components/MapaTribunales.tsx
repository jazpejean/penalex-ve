"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import { listarTribunalesConUbicacion, listarEstadosTribunales, type Tribunal } from "../lib/tribunales";

declare global {
  interface Window {
    L: any;
  }
}

const COLORES: Record<string, string> = {
  CONTROL: "#1d4ed8",
  JUICIO: "#6d28d9",
  "EJECUCIÓN": "#c2410c",
  APELACIÓN: "#0f766e",
  OTRO: "#4b5563",
};

function colorFuncion(f: string | null | undefined): string {
  return COLORES[f?.toUpperCase() ?? ""] ?? COLORES.OTRO;
}

function cargarLeaflet(): Promise<void> {
  return new Promise((resolve) => {
    if (window.L) return resolve();
    const css = document.createElement("link");
    css.rel = "stylesheet";
    css.href = "https://unpkg.com/leaflet@1.9.4/dist/leaflet.css";
    document.head.appendChild(css);
    const js = document.createElement("script");
    js.src = "https://unpkg.com/leaflet@1.9.4/dist/leaflet.js";
    js.onload = () => resolve();
    document.head.appendChild(js);
  });
}

export default function MapaTribunales() {
  const mapRef = useRef<HTMLDivElement>(null);
  const mapInstance = useRef<any>(null);
  const markersRef = useRef<any[]>([]);
  const [tribunales, setTribunales] = useState<Tribunal[]>([]);
  const [estados, setEstados] = useState<string[]>([]);
  const [cargando, setCargando] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Buscador + filtros
  const [busqueda, setBusqueda] = useState("");
  const [filtroEstado, setFiltroEstado] = useState("");
  const [filtroFuncion, setFiltroFuncion] = useState("");
  const [filtroInstancia, setFiltroInstancia] = useState("");
  const [filtroSeccion, setFiltroSeccion] = useState("");
  const [avanzados, setAvanzados] = useState(false);

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
    () => [...new Set(tribunales.map((t) => t.funcion ?? "").filter(Boolean))].sort(),
    [tribunales]
  );
  const instancias = useMemo(
    () => [...new Set(tribunales.map((t) => t.instancia).filter(Boolean))].sort(),
    [tribunales]
  );
  const secciones = useMemo(
    () => [...new Set(tribunales.map((t) => t.seccion ?? "").filter(Boolean))].sort(),
    [tribunales]
  );

  const visibles = useMemo(() => {
    const q = busqueda.trim().toLowerCase();
    return tribunales.filter((t) => {
      if (q) {
        const haystack = [t.nombre, t.codigo, t.sede ?? "", t.municipio ?? "", t.estado, t.parroquia ?? "", t.seccion ?? ""]
          .join(" ")
          .toLowerCase();
        if (!haystack.includes(q)) return false;
      }
      if (filtroEstado && t.estado !== filtroEstado) return false;
      if (filtroFuncion && (t.funcion ?? "") !== filtroFuncion) return false;
      if (filtroInstancia && t.instancia !== filtroInstancia) return false;
      if (filtroSeccion && (t.seccion ?? "") !== filtroSeccion) return false;
      return true;
    });
  }, [tribunales, busqueda, filtroEstado, filtroFuncion, filtroInstancia, filtroSeccion]);

  const hayFiltros = Boolean(busqueda || filtroEstado || filtroFuncion || filtroInstancia || filtroSeccion);

  function limpiarFiltros() {
    setBusqueda("");
    setFiltroEstado("");
    setFiltroFuncion("");
    setFiltroInstancia("");
    setFiltroSeccion("");
  }

  useEffect(() => {
    if (!mapRef.current || !tribunales.length) return;
    let cancelled = false;

    (async () => {
      await cargarLeaflet();
      if (cancelled) return;
      const L = window.L;
      if (!mapInstance.current) {
        mapInstance.current = L.map(mapRef.current).setView([9.3, -66.2], 5.6);
        L.tileLayer("https://tile.openstreetmap.org/{z}/{x}/{y}.png", {
          attribution: "&copy; OpenStreetMap",
          maxZoom: 18,
        }).addTo(mapInstance.current);
      }
      markersRef.current.forEach((m) => mapInstance.current.removeLayer(m));
      markersRef.current = [];

      // Agrupa los tribunales que comparten la MISMA coordenada (varios en
      // un mismo palacio de justicia) y los separa en espiral: sin esto,
      // los ~16 de "Los Teques" se apilan en un solo punto y solo se ve el
      // último dibujado (la Sala 1 de la Corte de Apelaciones).
      const radio = 0.0016; // ~170 m de separación en zoom urbano
      const grupos = new Map<string, Tribunal[]>();
      visibles.forEach((t) => {
        if (t.latitud == null || t.longitud == null) return;
        const clave = `${t.latitud.toFixed(4)},${t.longitud.toFixed(4)}`;
        if (!grupos.has(clave)) grupos.set(clave, []);
        grupos.get(clave)!.push(t);
      });
      grupos.forEach((grupo) => {
        if (grupo.length === 1) {
          const t = grupo[0];
          agregarMarker(t, t.latitud!, t.longitud!);
          return;
        }
        grupo.forEach((t, i) => {
          const angulo = i * 2.399963; // ángulo dorado (rad)
          const d = radio * (0.4 + i * 0.22);
          agregarMarker(
            t,
            t.latitud! + d * Math.cos(angulo),
            t.longitud! + d * Math.sin(angulo)
          );
        });
      });

      function agregarMarker(t: Tribunal, lat: number, lng: number) {
        const marker = L.marker([lat, lng], {
          icon: L.divIcon({
            className: "",
            html: `<div style="width:22px;height:22px;border-radius:50%;background:${colorFuncion(t.funcion)};border:2px solid white;box-shadow:0 1px 3px rgba(0,0,0,.4);display:flex;align-items:center;justify-content:center;font-size:12px;color:white">⚖</div>`,
            iconSize: [22, 22],
            iconAnchor: [11, 11],
          }),
        }).addTo(mapInstance.current);
        marker.bindPopup(
          (t.url_foto
            ? `<img src="${t.url_foto}" style="width:220px;height:110px;object-fit:cover;border-radius:8px;display:block;margin-bottom:6px" onerror="this.style.display='none'"/>`
            : "") +
            `<b>${t.nombre}</b><br/>${t.sede ?? ""}<br/>${t.estado}${t.municipio ? " · " + t.municipio : ""}<br/>` +
            `<span style="font-size:12px;color:#555">${t.funcion ?? ""} · ${t.instancia}</span>`
        );
        markersRef.current.push(marker);
      }

      // Ajustar vista solo cuando hay filtros (evita saltos molestos)
      if (visibles.length && (filtroEstado || filtroFuncion || filtroInstancia || filtroSeccion || busqueda)) {
        const bounds = L.latLngBounds(
          visibles.filter((t) => t.latitud != null && t.longitud != null).map((t) => [t.latitud, t.longitud])
        );
        mapInstance.current.fitBounds(bounds, { padding: [30, 30] });
      }
    })();

    return () => {
      cancelled = true;
    };
  }, [visibles, filtroEstado, filtroFuncion, filtroInstancia, filtroSeccion, busqueda]);

  const selectCls =
    "rounded-lg border border-gray-300 px-3 py-2 text-sm bg-white focus:outline-none focus:ring-2 focus:ring-[#031F4E]/20";

  return (
    <div className="mx-auto max-w-6xl px-4 py-10">
      <h1 className="text-3xl font-bold text-[#0f172a] mb-2">Mapa de Tribunales Penales</h1>
      <p className="text-gray-600 mb-6">
        Catálogo oficial del Tribunal Supremo de Justicia · {tribunales.length} tribunales de 1ª y 2ª
        instancia (excluye menores/LOPNNA). Fuente: geoportal.tsj.gob.ve.
      </p>

      {error && (
        <div className="mb-4 rounded-lg bg-red-50 border border-red-200 p-4 text-red-700 text-sm">{error}</div>
      )}

      {/* Buscador */}
      <div className="mb-3 flex gap-2">
        <div className="relative flex-1">
          <input
            type="text"
            value={busqueda}
            onChange={(e) => setBusqueda(e.target.value)}
            placeholder="Buscar por nombre, código, sede, municipio, estado…"
            className="w-full rounded-lg border border-gray-300 pl-9 pr-9 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-[#031F4E]/20"
          />
          <span className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 text-sm">🔍</span>
          {busqueda && (
            <button
              onClick={() => setBusqueda("")}
              className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
              aria-label="Limpiar búsqueda"
            >
              ✕
            </button>
          )}
        </div>
        <button
          onClick={() => setAvanzados(!avanzados)}
          className={`rounded-lg border px-3 py-2 text-sm font-medium ${avanzados ? "bg-[#031F4E] text-white border-[#031F4E]" : "bg-white text-gray-700 border-gray-300 hover:bg-gray-50"}`}
          title="Filtros avanzados"
        >
          ⚙ Filtros
        </button>
        {hayFiltros && (
          <button
            onClick={limpiarFiltros}
            className="rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-700 bg-white hover:bg-gray-50"
          >
            Limpiar
          </button>
        )}
      </div>

      {/* Filtros */}
      <div className="mb-3 grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4 gap-3">
        <select value={filtroEstado} onChange={(e) => setFiltroEstado(e.target.value)} className={selectCls}>
          <option value="">Todos los estados</option>
          {estados.map((e) => (
            <option key={e} value={e}>{e}</option>
          ))}
        </select>
        <select value={filtroFuncion} onChange={(e) => setFiltroFuncion(e.target.value)} className={selectCls}>
          <option value="">Todas las funciones</option>
          {funciones.map((f) => (
            <option key={f} value={f}>{f}</option>
          ))}
        </select>
        {avanzados && (
          <>
            <select value={filtroInstancia} onChange={(e) => setFiltroInstancia(e.target.value)} className={selectCls}>
              <option value="">Todas las instancias</option>
              {instancias.map((i) => (
                <option key={i} value={i}>{i}</option>
              ))}
            </select>
            <select value={filtroSeccion} onChange={(e) => setFiltroSeccion(e.target.value)} className={selectCls}>
              <option value="">Todas las secciones</option>
              {secciones.map((s) => (
                <option key={s} value={s}>{s}</option>
              ))}
            </select>
          </>
        )}
      </div>

      {/* Contador */}
      <div className="mb-3 flex items-center gap-3 text-xs text-gray-600">
        <span className="font-semibold">
          {visibles.length} de {tribunales.length} tribunales
        </span>
        {Object.entries(COLORES).slice(0, 4).map(([k, c]) => (
          <span key={k} className="flex items-center gap-1">
            <span className="inline-block w-3 h-3 rounded-full" style={{ background: c }} />
            {k.charAt(0) + k.slice(1).toLowerCase()}
          </span>
        ))}
      </div>

      <div
        ref={mapRef}
        className="w-full rounded-2xl overflow-hidden border border-gray-200 shadow-sm"
        style={{ height: "540px", zIndex: 0 }}
      >
        {cargando && (
          <div className="flex items-center justify-center h-full bg-gray-50 text-gray-500">
            Cargando mapa…
          </div>
        )}
        {!cargando && visibles.length === 0 && (
          <div className="flex items-center justify-center h-full bg-gray-50 text-gray-500">
            Sin tribunales con esos criterios
          </div>
        )}
      </div>

      <p className="mt-4 text-xs text-gray-400">
        Los tribunales son datos públicos del TSJ. El estado de despacho diario no es publicado por el
        TSJ; la app lo muestra como desconocido hasta que exista una fuente oficial.
      </p>
    </div>
  );
}