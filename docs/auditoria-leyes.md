# Auditoría de puntuación del corpus legal

Total de hallazgos: **228** en 53 leyes.

| Tipo | Casos |
|---|---|
| Empieza con signo de puntuación | 50 |
| Punto seguido de mayúscula sin espacio | 46 |
| Minúscula después de punto | 43 |
| Espacio antes de coma o punto | 35 |
| Artículo muy corto | 32 |
| Paréntesis sin cerrar | 14 |
| Comillas sin cerrar | 8 |

## Leyes con más hallazgos

| Ley | Casos |
|---|---|
| copp | 34 |
| codigo-organico-de-justicia-militar | 31 |
| ley-organica-para-la-proteccion-de-ninos-ninas-y-adolescentes | 30 |
| reglamento-de-la-ley-para-el-desarme-y-control-de-armas-y-municiones | 30 |
| codigo-penal | 20 |
| ley-organica-contra-la-delincuencia-organizada-y-financiamiento-al-terrorismo | 14 |
| crbv | 12 |
| ley-organica-de-la-defensa-publica | 9 |
| ley-organica-del-ministerio-publico | 8 |
| ley-de-carrera-judicial | 7 |

## Ejemplos por tipo

### Empieza con signo de puntuación

- **codigo-organico-de-justicia-militar art. 8** (texto_principal): `. Para el enjuiciamiento militar en Venezuela por infracciones cometidas fuera del territorio nacional, se requiere que el presunto reo no h`
- **codigo-organico-de-justicia-militar art. 36** (texto_principal): `. El Presidente prestará juramento conforme a la ley, ante todos los miembros de la Corte reunidos, y recibirá el juramento de cada uno de l`
- **codigo-penal art. 144** (texto_principal): `. Cualquiera que, sin autorización del Gobierno Nacional, haga levas o arme venezolanos o extranjeros en el espacio geográfico de la Repúbli`

### Punto seguido de mayúscula sin espacio

- **codigo-organico-de-justicia-militar art. 143** (texto_principal): `La Sentencia se dictará por mayoría de votos, expresará la fecha en que se haya dictado y se firmará por los miembros del Tribunal, pero los`
- **codigo-organico-de-justicia-militar art. 470** (texto_principal): `Es requisito necesario para incurrir en el delito de traición a la patria, que el delincuente sea venezolano o que se encuentre en el moment`
- **codigo-organico-de-justicia-militar art. 520** (texto_principal): `Si la desobediencia hubiese causado daño o perturbación en el servicio, se castigará con prisión de uno a dos años; y si este delito se come`

### Minúscula después de punto

- **codigo-organico-de-justicia-militar art. 48** (texto_principal): `Los Jueces Militares de Primera Instancia Permanentes funcionarán en los lugares donde a juicio del Presidente de la República los requieran`
- **codigo-organico-de-justicia-militar art. 54** (texto_principal): `Son atribuciones del Presidente de la República. como funcionario de justicia militar:`
- **codigo-organico-de-justicia-militar art. 84** (numeral[0]): `1. Informar sobre todas las causas que a los efectos del artículo 224 se sometan a la consideración del Presidente de la República. con el d`

### Espacio antes de coma o punto

- **codigo-organico-de-justicia-militar art. 248** (numeral[1]): `2. La de cualquiera de los contemplados en los números 2 y 3 , el de desechar al acusador, quien dejará de ser parte en el juicio, y éste se`
- **copp art. 359** (texto_principal): `Son condiciones para el otorgamiento de la Suspensión Condicional del Proceso, la restitución, reparación o indemnización por el daño causad`
- **decreto-con-rango-valor-y-fuerza-de-ley-organica-de-precios-justos art. 8** (texto_principal): `Los vehículos, maquinarias, equipos o artefactos y demás bienes de naturaleza durable que posean sistemas mecánicos, eléctricos o electrónic`

### Artículo muy corto

- **codigo-de-etica-del-juez-venezolano-y-jueza-venezolana art. 29** (texto_principal): `Son causales de destitución:`
- **codigo-organico-de-justicia-militar art. 27** (texto_principal): `Son Tribunales Militares:`
- **codigo-organico-de-justicia-militar art. 116** (texto_principal): `Sólo pueden recusar:`

### Paréntesis sin cerrar

- **ley-organica-para-la-proteccion-de-ninos-ninas-y-adolescentes art. 129** (texto_principal): `Las medidas de protección son impuestas en sede administrativa por el Consejo de Protección de Niños, Niñas y Adolescentes, salvo las señala`
- **ley-organica-para-la-proteccion-de-ninos-ninas-y-adolescentes art. 132** (texto_principal): `Siempre que la medida de protección impuesta al niño, niña o adolescente se ejecute en una entidad de atención, el órgano competente, a los `
- **ley-organica-para-la-proteccion-de-ninos-ninas-y-adolescentes art. 169** (texto_principal): `El Ministerio Público deberá contar con fiscales especiales para la protección de niños, niñas y adolescentes en cada localidad donde se con`

### Comillas sin cerrar

- **reglamento-de-la-ley-para-el-desarme-y-control-de-armas-y-municiones art. 91** (numeral[0]): `1. Las armas permitidas para la Empresa que preste servicio de vigilancia privada serán la Escopeta Cal. 12 (mono tiro) con munición del tip`
- **reglamento-de-la-ley-para-el-desarme-y-control-de-armas-y-municiones art. 116** (numeral[0]): `1. Pistola calibre 9x19 mm con cañón de hasta a cinco (5") pulgadas.`
- **reglamento-de-la-ley-para-el-desarme-y-control-de-armas-y-municiones art. 116** (numeral[4]): `1. Pistola calibre 9x19 mm con cañón de hasta a cinco (5") pulgadas.`


## Leyes que no cargan

Dos archivos del corpus están corruptos o vacíos y el worker no puede servirlos:

| Ley | Problema |
|---|---|
| `ley-del-estatuto-de-la-funcion-de-la-policia-de-investigacion` | JSON inválido o vacío |
| `ley-organica-del-servicio-de-policia-de-investigacion-el-cuerpo-de-investigaciones-cientificas-penales-y-criminalisticas-y-el-servicio-nacional-de-medicina-y-ciencias-forenses` | JSON inválido o vacío |

Acción: volver a exportar esas dos leyes y reemplazar el objeto en R2.

## Criterio de corrección

Se corrige automáticamente en el render lo que no cambia el sentido jurídico:
- Signo de puntuación al inicio del artículo.
- Espacio antes de coma, punto y dos puntos.
- Doble espacio dentro de la línea.
- Saltos de línea excesivos.

Se revisa a mano lo que sí puede cambiar el sentido:
- Punto seguido de mayúscula sin espacio (puede ser una abreviatura).
- Minúscula después de punto.
- Comillas y paréntesis sin cerrar.
