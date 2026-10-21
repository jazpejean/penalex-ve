-- ============================================================
-- PENALEX VE — Tabla TRIBUNALES (catálogo oficial TSJ, solo penal adultos)
-- Fuente: geoportal.tsj.gob.ve/api/listarTribunales (público, 2026-10-20)
-- 868 tribunales: 1ª instancia (808: control 437, juicio 240, ejecución 132)
--                2ª instancia (59: apelación 57) + Sala Penal (1)
-- Ejecutar en: Supabase Dashboard → SQL Editor
-- ============================================================

create table if not exists public.tribunales (
  id            uuid primary key,          -- idTRibunal del TSJ
  codigo        text not null unique,      -- ej. "POR20"
  nombre        text not null,
  sede          text,
  estado        text not null,
  municipio     text,
  parroquia     text,
  latitud       double precision,
  longitud      double precision,
  materia       text not null default 'PENAL',
  instancia     text,                       -- PRIMERA / SEGUNDA / ULTIMA INSTANCIA
  funcion       text,                       -- CONTROL / JUICIO / EJECUCIÓN / APELACIÓN
  seccion       text,
  tipo_sede     text,
  condicion_sede text,
  url_foto      text,
  despacho      text not null default 'desconocido', -- TSJ no publica el dato diario
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

comment on table public.tribunales is
  'Catálogo oficial de tribunales penales venezolanos (1ª y 2ª instancia), excluye LOPNNA/menores. Fuente: geoportal TSJ.';

-- Índice para búsqueda por estado y función (agenda + mapa)
create index if not exists idx_tribunales_estado   on public.tribunales (estado);
create index if not exists idx_tribunales_funcion  on public.tribunales (funcion);
create index if not exists idx_tribunales_codigo   on public.tribunales (codigo);

-- RLS: lectura pública (catálogo oficial del Estado), escritura solo service role
alter table public.tribunales enable row level security;

create policy "tribunales_lectura_publica"
  on public.tribunales for select
  using (true);

create policy "tribunales_escritura_servicio"
  on public.tribunales for insert
  with check (true);   -- solo service role puede insertar (bypass RLS)

-- Trigger para mantener updated_at
create or replace function public.touch_tribunales()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;

create trigger trg_tribunales_touch
  before update on public.tribunales
  for each row execute function public.touch_tribunales();