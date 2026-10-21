-- ============================================================
-- PENALEX VE — Búsqueda semántica de TRIBUNALES
-- pgvector (bge-m3, 1024 dimensiones, similitud coseno)
-- Ejecutar en: Supabase Dashboard → SQL Editor (idempotente)
-- ============================================================

-- 1) Extensión vector (pgvector)
create extension if not exists vector;

-- 2) Columna de embedding en tribunales
alter table public.tribunales
  add column if not exists embedding vector(1024);

-- Índice HNSW para búsqueda por similitud (bge-m3 normalizado → coseno)
create index if not exists idx_tribunales_embedding_hnsw
  on public.tribunales
  using hnsw (embedding vector_cosine_ops);

-- 3) Función de búsqueda semántica con filtros opcionales.
--    Devuelve los tribunales más cercanos al vector de la consulta
--    (distancia coseno 0 = idéntico, 1 = opuesto) aplicando los
--    mismos filtros que el mapa (estado / función / instancia / sección).
create or replace function public.buscar_tribunales_semanticos(
  query_embedding vector(1024),
  limite int default 20,
  p_estado text default null,
  p_funcion text default null,
  p_instancia text default null,
  p_seccion text default null
)
returns table (
  id uuid,
  codigo text,
  nombre text,
  sede text,
  estado text,
  municipio text,
  parroquia text,
  latitud double precision,
  longitud double precision,
  materia text,
  instancia text,
  funcion text,
  seccion text,
  tipo_sede text,
  condicion_sede text,
  url_foto text,
  despacho text,
  distancia real
)
language plpgsql
security definer
set search_path = public
as $$
begin
  return query
  select
    t.id, t.codigo, t.nombre, t.sede, t.estado, t.municipio, t.parroquia,
    t.latitud, t.longitud, t.materia, t.instancia, t.funcion, t.seccion,
    t.tipo_sede, t.condicion_sede, t.url_foto, t.despacho,
    (t.embedding <=> query_embedding)::real as distancia
  from public.tribunales t
  where t.embedding is not null
    and (p_estado   is null or t.estado   = p_estado)
    and (p_funcion  is null or t.funcion  = p_funcion)
    and (p_instancia is null or t.instancia = p_instancia)
    and (p_seccion  is null or t.seccion  = p_seccion)
  order by t.embedding <=> query_embedding
  limit greatest(1, limite);
end;
$$;

-- 4) Permisos: lectura pública del catálogo (ya existe en RLS);
--    la función corre con security definer y search_path fijo.
grant execute on function public.buscar_tribunales_semanticos to anon, authenticated;