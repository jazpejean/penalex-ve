-- Corrige las fechas largas ("Weekday, DD Mes de YYYY") -> "YYYY-MM-DD".
-- Enfoque robusto: extrae año (primer número de 4 dígitos), mes (nombre en
-- español) y día (primer número de 1-2 dígitos), independientemente del formato.

update documentos
set fecha = to_char(
  make_date(
    (substring(fecha from '(\d{4})'))::int,
    case
      when fecha ilike '%Enero%' then 1
      when fecha ilike '%Febrero%' then 2
      when fecha ilike '%Marzo%' then 3
      when fecha ilike '%Abril%' then 4
      when fecha ilike '%Mayo%' then 5
      when fecha ilike '%Junio%' then 6
      when fecha ilike '%Julio%' then 7
      when fecha ilike '%Agosto%' then 8
      when fecha ilike '%Septiembre%' then 9
      when fecha ilike '%Octubre%' then 10
      when fecha ilike '%Noviembre%' then 11
      when fecha ilike '%Diciembre%' then 12
      else 1
    end,
    (substring(fecha from '(\d{1,2})'))::int
  ),
  'YYYY-MM-DD'
)
where length(fecha) > 10;
