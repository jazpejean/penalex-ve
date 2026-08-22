package com.example.model

import androidx.compose.ui.graphics.Color
import com.example.R

data class Region(
    val id: Int,
    val nombre: String,
    val capitalOEstado: String,
    val nivelInicio: Int,
    val nivelFin: Int,
    val monumentos: String,
    val descripcion: String,
    val drawableRes: Int,
    val colorPrimario: Color = Color(0xFF003893),
    val colorDorado: Color = Color(0xFFD4AF37)
)

val REGIONES_21 = listOf(
    Region(
        id = 1,
        nombre = "Distrito Capital",
        capitalOEstado = "Caracas",
        nivelInicio = 1,
        nivelFin = 143,
        monumentos = "El Ávila, Estatua Ecuestre de Simón Bolívar, Panteón Nacional y Palacio del TSJ",
        descripcion = "Cuna del Libertador Simón Bolívar y sede suprema del Poder Judicial de la República.",
        drawableRes = R.drawable.tile_caracas_valley_1787075903173
    ),
    Region(
        id = 2,
        nombre = "Miranda",
        capitalOEstado = "Los Teques",
        nivelInicio = 144,
        nivelFin = 286,
        monumentos = "Circuito Judicial Penal, Plaza Bolívar de Los Teques y Cacao de Barlovento",
        descripcion = "Altos Mirandinos de templada bruma y solemne tradición procesal.",
        drawableRes = R.drawable.path_caracas
    ),
    Region(
        id = 3,
        nombre = "La Guaira (Vargas)",
        capitalOEstado = "La Guaira",
        nivelInicio = 287,
        nivelFin = 429,
        monumentos = "Fuerte San Carlos, El Puerto Colonial y Tribunal Marítimo",
        descripcion = "Murallas coloniales y baluartes de piedra frente al Mar Caribe.",
        drawableRes = R.drawable.path_margarita
    ),
    Region(
        id = 4,
        nombre = "Aragua",
        capitalOEstado = "Maracay",
        nivelInicio = 430,
        nivelFin = 572,
        monumentos = "Circuito Judicial de Maracay, Plaza Bolívar y Araguaneyes en flor",
        descripcion = "Cálidos valles centrales ornados con araguaneyes de oro y tradición militar.",
        drawableRes = R.drawable.map_llanos_1787056218818
    ),
    Region(
        id = 5,
        nombre = "Carabobo",
        capitalOEstado = "Valencia",
        nivelInicio = 573,
        nivelFin = 715,
        monumentos = "Campo de Carabobo (Arco del Triunfo), Palacio de Justicia y Columnas Corintias",
        descripcion = "Suelo sagrado de la Independencia nacional y severos palacios de jurisprudencia.",
        drawableRes = R.drawable.path_llanos
    ),
    Region(
        id = 6,
        nombre = "Zulia",
        capitalOEstado = "Maracaibo",
        nivelInicio = 716,
        nivelFin = 858,
        monumentos = "Basílica de Chiquinquirá, Puente Rafael Urdaneta y Relámpago del Catatumbo",
        descripcion = "Tierra del Sol amada, devoción mariana y soberanía sobre el Lago de Maracaibo.",
        drawableRes = R.drawable.map_zulia_1787056161873
    ),
    Region(
        id = 7,
        nombre = "Lara",
        capitalOEstado = "Barquisimeto",
        nivelInicio = 859,
        nivelFin = 1001,
        monumentos = "Catedral de Barquisimeto, Monumento al Sol y Circuito Judicial",
        descripcion = "Ciudad de los Crepúsculos, música sacra y templanza jurídica.",
        drawableRes = R.drawable.map_falcon_1787056192708
    ),
    Region(
        id = 8,
        nombre = "Táchira",
        capitalOEstado = "San Cristóbal",
        nivelInicio = 1002,
        nivelFin = 1144,
        monumentos = "Catedral de San Cristóbal, Palacio de los Leones y Cumbres Andinas",
        descripcion = "Soberanía andina de piedra labrada y severidad institucional.",
        drawableRes = R.drawable.path_andes
    ),
    Region(
        id = 9,
        nombre = "Mérida",
        capitalOEstado = "Mérida",
        nivelInicio = 1145,
        nivelFin = 1287,
        monumentos = "Universidad de Los Andes (ULA), Catedral de Mérida y Picos Nevados",
        descripcion = "Ciudad de los Caballeros, claustros universitarios y nieves eternas.",
        drawableRes = R.drawable.map_merida_1787056173961
    ),
    Region(
        id = 10,
        nombre = "Bolívar",
        capitalOEstado = "Ciudad Bolívar",
        nivelInicio = 1288,
        nivelFin = 1430,
        monumentos = "Casa del Congreso de Angostura, Río Orinoco y Puente Angostura",
        descripcion = "Angostura del Padre Río, donde el Libertador proclamó las bases republicanas.",
        drawableRes = R.drawable.map_bolivar_1787056206501
    ),
    Region(
        id = 11,
        nombre = "Anzoátegui",
        capitalOEstado = "Barcelona",
        nivelInicio = 1431,
        nivelFin = 1573,
        monumentos = "Casa Fuerte de Barcelona, Circuito Judicial y Costa Caribeña",
        descripcion = "Murallas patriotas de Barcelona frente a las cálidas aguas orientales.",
        drawableRes = R.drawable.path_margarita
    ),
    Region(
        id = 12,
        nombre = "Sucre",
        capitalOEstado = "Cumaná",
        nivelInicio = 1574,
        nivelFin = 1716,
        monumentos = "Castillo de San Antonio de la Eminencia y Golfo de Cariaco",
        descripcion = "Primogénita del continente americano y cuna del Gran Mariscal de Ayacucho.",
        drawableRes = R.drawable.path_margarita
    ),
    Region(
        id = 13,
        nombre = "Monagas",
        capitalOEstado = "Maturín",
        nivelInicio = 1717,
        nivelFin = 1859,
        monumentos = "Catedral de Nuestra Señora del Carmen y Sabana del Guarapiche",
        descripcion = "Vastas sabanas del Guarapiche y sobrias cortes orientales.",
        drawableRes = R.drawable.map_llanos_1787056218818
    ),
    Region(
        id = 14,
        nombre = "Delta Amacuro",
        capitalOEstado = "Tucupita",
        nivelInicio = 1860,
        nivelFin = 2002,
        monumentos = "Circuito Judicial y Palafitos del Delta del Orinoco",
        descripcion = "Mística confluencia de caños fluviales y palafitos centenarios.",
        drawableRes = R.drawable.path_guayana
    ),
    Region(
        id = 15,
        nombre = "Amazonas",
        capitalOEstado = "Puerto Ayacucho",
        nivelInicio = 2003,
        nivelFin = 2145,
        monumentos = "Piedra de la Tortuga, Selva Amazónica y Tepuyes Ancestrales",
        descripcion = "Corazón indómito del sur, selva milenaria y leyendas ancestrales.",
        drawableRes = R.drawable.path_guayana
    ),
    Region(
        id = 16,
        nombre = "Apure",
        capitalOEstado = "San Fernando",
        nivelInicio = 2146,
        nivelFin = 2288,
        monumentos = "Puente María Nieves sobre el Río Apure y Sabana Infinita",
        descripcion = "Tierra de los Centauros de Páez y horizonte infinito del río Apure.",
        drawableRes = R.drawable.map_llanos_1787056218818
    ),
    Region(
        id = 17,
        nombre = "Barinas",
        capitalOEstado = "Barinas",
        nivelInicio = 2289,
        nivelFin = 2431,
        monumentos = "Casa de la Cultura, Circuito Judicial y Llanos Altos",
        descripcion = "Cruce majestuoso entre la cordillera andina y la llanura ganadera.",
        drawableRes = R.drawable.path_llanos
    ),
    Region(
        id = 18,
        nombre = "Portuguesa",
        capitalOEstado = "Guanare",
        nivelInicio = 2432,
        nivelFin = 2574,
        monumentos = "Basílica Menor Santuario Nacional de la Virgen de Coromoto",
        descripcion = "Capital Espiritual de Venezuela y fértiles llanuras coloniales.",
        drawableRes = R.drawable.map_llanos_1787056218818
    ),
    Region(
        id = 19,
        nombre = "Cojedes",
        capitalOEstado = "San Carlos",
        nivelInicio = 2575,
        nivelFin = 2717,
        monumentos = "Casa La Blanquera y Autódromo Internacional",
        descripcion = "Paso de batallas libertadoras e hidalguía llanera.",
        drawableRes = R.drawable.path_llanos
    ),
    Region(
        id = 20,
        nombre = "Guárico",
        capitalOEstado = "San Juan de los Morros",
        nivelInicio = 2718,
        nivelFin = 2860,
        monumentos = "Los Morros de San Juan y Monumento a San Juan Bautista",
        descripcion = "Centinelas de roca caliza custodiando la puerta de los llanos venezolanos.",
        drawableRes = R.drawable.map_falcon_1787056192708
    ),
    Region(
        id = 21,
        nombre = "Yaracuy",
        capitalOEstado = "San Felipe",
        nivelInicio = 2861,
        nivelFin = 3000,
        monumentos = "Monumento a María Lionza, Parque San Felipe El Fuerte y Tribunal Supremo",
        descripcion = "Tierra de mitos ancestrales, valles fecundos y cumbre máxima de la Magistratura.",
        drawableRes = R.drawable.path_coro
    )
)

fun getRegionForLevel(level: Int): Region {
    return REGIONES_21.find { level in it.nivelInicio..it.nivelFin } ?: REGIONES_21.first()
}

fun getRankForLevel(level: Int): String {
    return when {
        level >= 3000 -> "Presidente Emérito del TSJ"
        level >= 2901 -> "Presidente de la Sala de Casación Penal"
        level >= 2801 -> "Vicepresidente de la Sala de Casación Penal"
        level >= 2601 -> "Magistrado Principal de la Sala de Casación Penal"
        level >= 2401 -> "Secretario de la Sala de Casación Penal"
        level >= 2201 -> "Magistrado Suplente de la Sala de Casación Penal"
        level >= 2001 -> "Juez Presidente del Circuito Judicial Penal"
        level >= 1801 -> "Juez Titular de Corte de Apelaciones"
        level >= 1601 -> "Juez Provisorio de Corte de Apelaciones"
        level >= 1401 -> "Juez Titular de Primera Instancia"
        level >= 1201 -> "Juez Suplente de Primera Instancia"
        level >= 1051 -> "Juez Accidental de Primera Instancia"
        level >= 901 -> "Juez Titular de Municipio"
        level >= 751 -> "Juez Provisorio de Municipio"
        level >= 601 -> "Juez Suplente de Municipio"
        level >= 451 -> "Juez Accidental de Municipio"
        level >= 301 -> "Secretario de Tribunal de Primera Instancia"
        level >= 181 -> "Secretario de Tribunal de Municipio"
        level >= 81 -> "Asistente Jurídico / Escribiente"
        else -> "Alguacil de Sala"
    }
}
