-- Ajustes del membrete: alineación y tamaño

alter table public.configuracion_usuario
  add column if not exists membrete_alineacion text not null default 'centro';
alter table public.configuracion_usuario
  add column if not exists membrete_tamano text not null default 'medio';
