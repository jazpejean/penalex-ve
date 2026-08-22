
import 'package:flutter/material.dart';

/// Región de Venezuela con sus monumentos y tribunales
class RegionVenezuela {
  final String estado;
  final String capital;
  final String descripcion;
  final List<MonumentoRegional> monumentos;
  final int nivelInicio;
  final int nivelFin;
  final Color colorPrincipal;
  final String imagenFondo; // Nombre del asset

  RegionVenezuela({
    required this.estado,
    required this.capital,
    required this.descripcion,
    required this.monumentos,
    required this.nivelInicio,
    required this.nivelFin,
    required this.colorPrincipal,
    required this.imagenFondo,
  });

  bool contieneNivel(int nivel) {
    return nivel >= nivelInicio && nivel <= nivelFin;
  }
}

/// Monumento o edificación de una región
class MonumentoRegional {
  final String nombre;
  final String tipo; // 'tribunal', 'colonial', 'iglesia', 'plaza', 'institucion'
  final String descripcion;
  final IconData icono;
  final int nivel; // En qué nivel aparece
  final bool esHistorico;

  MonumentoRegional({
    required this.nombre,
    required this.tipo,
    required this.descripcion,
    required this.icono,
    required this.nivel,
    this.esHistorico = false,
  });
}

/// Lista completa de regiones de Venezuela (23 estados + Distrito Capital)
/// Ordenadas por niveles del juego
final List<RegionVenezuela> regionesVenezuela = [
  
  // DISTRITO CAPITAL - Niveles 1-125 (Inicio del juego)
  RegionVenezuela(
    estado: 'Distrito Capital',
    capital: 'Caracas',
    descripcion: 'Sede del Poder Judicial Nacional y centro histórico del país',
    nivelInicio: 1,
    nivelFin: 125,
    colorPrincipal: const Color(0xFFCF142B), // Rojo
    imagenFondo: 'regions/caracas_background.jpg',
    monumentos: [
      MonumentoRegional(
        nombre: 'Tribunal Supremo de Justicia',
        tipo: 'tribunal',
        descripcion: 'Máxima instancia judicial de Venezuela',
        icono: Icons.account_balance,
        nivel: 10,
      ),
      MonumentoRegional(
        nombre: 'Palacio Federal Legislativo',
        tipo: 'institucion',
        descripcion: 'Sede de la Asamblea Nacional',
        icono: Icons.domain,
        nivel: 25,
        esHistorico: true,
      ),
      MonumentoRegional(
        nombre: 'Catedral de Caracas',
        tipo: 'iglesia',
        descripcion: 'Construcción colonial del siglo XVII',
        icono: Icons.church,
        nivel: 40,
        esHistorico: true,
      ),
      MonumentoRegional(
        nombre: 'Plaza Bolívar',
        tipo: 'plaza',
        descripcion: 'Corazón histórico de la capital',
        icono: Icons.landscape,
        nivel: 50,
        esHistorico: true,
      ),
      MonumentoRegional(
        nombre: 'Palacio de Justicia',
        tipo: 'tribunal',
        descripcion: 'Sede de tribunales capitalinos',
        icono: Icons.gavel,
        nivel: 75,
      ),
      MonumentoRegional(
        nombre: 'Casa Natal del Libertador',
        tipo: 'colonial',
        descripcion: 'Lugar de nacimiento de Simón Bolívar',
        icono: Icons.home,
        nivel: 100,
        esHistorico: true,
      ),
      MonumentoRegional(
        nombre: 'Panteón Nacional',
        tipo: 'colonial',
        descripcion: 'Mausoleo de héroes nacionales',
        icono: Icons.museum,
        nivel: 125,
        esHistorico: true,
      ),
    ],
  ),

  // MIRANDA - Niveles 126-250
  RegionVenezuela(
    estado: 'Miranda',
    capital: 'Los Teques',
    descripcion: 'Estado central con importante actividad judicial',
    nivelInicio: 126,
    nivelFin: 250,
    colorPrincipal: const Color(0xFF003893), // Azul
    imagenFondo: 'regions/miranda_background.jpg',
    monumentos: [
      MonumentoRegional(
        nombre: 'Circuito Judicial Penal de Miranda',
        tipo: 'tribunal',
        descripcion: 'Tribunales de primera instancia',
        icono: Icons.business,
        nivel: 150,
      ),
      MonumentoRegional(
        nombre: 'Plaza Bolívar de Los Teques',
        tipo: 'plaza',
        descripcion: 'Centro histórico de la capital',
        icono: Icons.park,
        nivel: 175,
        esHistorico: true,
      ),
      MonumentoRegional(
        nombre: 'Iglesia San Felipe Neri',
        tipo: 'iglesia',
        descripcion: 'Templo colonial del siglo XVIII',
        icono: Icons.church,
        nivel: 200,
        esHistorico: true,
      ),
      MonumentoRegional(
        nombre: 'Corte de Apelaciones Miranda',
        tipo: 'tribunal',
        descripcion: 'Segunda instancia judicial',
        icono: Icons.account_balance,
        nivel: 225,
      ),
    ],
  ),

  // VARGAS - Niveles 251-350
  RegionVenezuela(
    estado: 'Vargas',
    capital: 'La Guaira',
    descripcion: 'Puerto histórico y entrada de Venezuela',
    nivelInicio: 251,
    nivelFin: 350,
    colorPrincipal: const Color(0xFFFCDD09), // Amarillo
    imagenFondo: 'regions/vargas_background.jpg',
    monumentos: [
      MonumentoRegional(
        nombre: 'Fuerte San Carlos',
        tipo: 'colonial',
        descripcion: 'Fortificación colonial del siglo XVIII',
        icono: Icons.fort,
        nivel: 275,
        esHistorico: true,
      ),
      MonumentoRegional(
        nombre: 'Tribunal del Puerto',
        tipo: 'tribunal',
        descripcion: 'Tribunales marítimos y aduaneros',
        icono: Icons.anchor,
        nivel: 300,
      ),
      MonumentoRegional(
        nombre: 'Casa Guipuzcoana',
        tipo: 'colonial',
        descripcion: 'Antigua compañía colonial',
        icono: Icons.store,
        nivel: 325,
        esHistorico: true,
      ),
    ],
  ),

  // ARAGUA - Niveles 351-475
  RegionVenezuela(
    estado: 'Aragua',
    capital: 'Maracay',
    descripcion: 'Ciudad jardín y sede militar',
    nivelInicio: 351,
    nivelFin: 475,
    colorPrincipal: const Color(0xFF228B22), // Verde
    imagenFondo: 'regions/aragua_background.jpg',
    monumentos: [
      MonumentoRegional(
        nombre: 'Plaza Bolívar de Maracay',
        tipo: 'plaza',
        descripcion: 'Centro cívico de la ciudad',
        icono: Icons.location_city,
        nivel: 375,
      ),
      MonumentoRegional(
        nombre: 'Palacio de Gobierno',
        tipo: 'institucion',
        descripcion: 'Sede gubernamental estatal',
        icono: Icons.location_city,
        nivel: 400,
      ),
      MonumentoRegional(
        nombre: 'Circuito Judicial Aragua',
        tipo: 'tribunal',
        descripcion: 'Sistema judicial estatal',
        icono: Icons.account_balance,
        nivel: 425,
      ),
      MonumentoRegional(
        nombre: 'Catedral de Maracay',
        tipo: 'iglesia',
        descripcion: 'Templo principal de la ciudad',
        icono: Icons.church,
        nivel: 450,
      ),
    ],
  ),

  // CARABOBO - Niveles 476-600
  RegionVenezuela(
    estado: 'Carabobo',
    capital: 'Valencia',
    descripcion: 'Cuna de la batalla de Carabobo',
    nivelInicio: 476,
    nivelFin: 600,
    colorPrincipal: const Color(0xFFD4AF37), // Dorado
    imagenFondo: 'regions/carabobo_background.jpg',
    monumentos: [
      MonumentoRegional(
        nombre: 'Campo de Carabobo',
        tipo: 'colonial',
        descripcion: 'Sitio histórico de la batalla',
        icono: Icons.flag,
        nivel: 500,
        esHistorico: true,
      ),
      MonumentoRegional(
        nombre: 'Capitolio de Valencia',
        tipo: 'institucion',
        descripcion: 'Sede del poder legislativo regional',
        icono: Icons.account_balance,
        nivel: 525,
      ),
      MonumentoRegional(
        nombre: 'Catedral de Valencia',
        tipo: 'iglesia',
        descripcion: 'Construcción colonial del siglo XVI',
        icono: Icons.church,
        nivel: 550,
        esHistorico: true,
      ),
      MonumentoRegional(
        nombre: 'Palacio de Justicia Carabobo',
        tipo: 'tribunal',
        descripcion: 'Centro judicial del estado',
        icono: Icons.gavel,
        nivel: 575,
      ),
    ],
  ),

  // ZULIA - Niveles 601-750
  RegionVenezuela(
    estado: 'Zulia',
    capital: 'Maracaibo',
    descripcion: 'Capital petrolera y ciudad del sol amado',
    nivelInicio: 601,
    nivelFin: 750,
    colorPrincipal: const Color(0xFF4169E1), // Azul rey
    imagenFondo: 'regions/zulia_background.jpg',
    monumentos: [
      MonumentoRegional(
        nombre: 'Basílica de Chiquinquirá',
        tipo: 'iglesia',
        descripcion: 'Templo patronal de Maracaibo',
        icono: Icons.church,
        nivel: 625,
        esHistorico: true,
      ),
      MonumentoRegional(
        nombre: 'Casa Morales',
        tipo: 'colonial',
        descripcion: 'Arquitectura colonial zuliana',
        icono: Icons.home,
        nivel: 650,
        esHistorico: true,
      ),
      MonumentoRegional(
        nombre: 'Palacio de Gobierno del Zulia',
        tipo: 'institucion',
        descripcion: 'Sede del ejecutivo regional',
        icono: Icons.domain,
        nivel: 675,
      ),
      MonumentoRegional(
        nombre: 'Circuito Judicial Zulia',
        tipo: 'tribunal',
        descripcion: 'Mayor circuito judicial del occidente',
        icono: Icons.account_balance,
        nivel: 700,
      ),
      MonumentoRegional(
        nombre: 'Catedral de Maracaibo',
        tipo: 'iglesia',
        descripcion: 'Templo metropolitano',
        icono: Icons.church,
        nivel: 725,
      ),
    ],
  ),

  // LARA - Niveles 751-875
  RegionVenezuela(
    estado: 'Lara',
    capital: 'Barquisimeto',
    descripcion: 'Ciudad musical y crepuscular',
    nivelInicio: 751,
    nivelFin: 875,
    colorPrincipal: const Color(0xFFFF6347), // Rojo tomate
    imagenFondo: 'regions/lara_background.jpg',
    monumentos: [
      MonumentoRegional(
        nombre: 'Catedral de Barquisimeto',
        tipo: 'iglesia',
        descripcion: 'Moderna catedral metropolitana',
        icono: Icons.church,
        nivel: 775,
      ),
      MonumentoRegional(
        nombre: 'Palacio Legislativo Lara',
        tipo: 'institucion',
        descripcion: 'Consejo legislativo estadal',
        icono: Icons.account_balance,
        nivel: 800,
      ),
      MonumentoRegional(
        nombre: 'Tribunales de Barquisimeto',
        tipo: 'tribunal',
        descripcion: 'Centro judicial larense',
        icono: Icons.gavel,
        nivel: 825,
      ),
      MonumentoRegional(
        nombre: 'Plaza Bolívar de Barquisimeto',
        tipo: 'plaza',
        descripcion: 'Corazón histórico',
        icono: Icons.park,
        nivel: 850,
      ),
    ],
  ),

  // TÁCHIRA - Niveles 876-1000
  RegionVenezuela(
    estado: 'Táchira',
    capital: 'San Cristóbal',
    descripcion: 'Estado fronterizo de los Andes',
    nivelInicio: 876,
    nivelFin: 1000,
    colorPrincipal: const Color(0xFF8B4513), // Marrón andino
    imagenFondo: 'regions/tachira_background.jpg',
    monumentos: [
      MonumentoRegional(
        nombre: 'Catedral de San Cristóbal',
        tipo: 'iglesia',
        descripcion: 'Templo principal andino',
        icono: Icons.church,
        nivel: 900,
        esHistorico: true,
      ),
      MonumentoRegional(
        nombre: 'Palacio de los Leones',
        tipo: 'institucion',
        descripcion: 'Sede del gobierno regional',
        icono: Icons.domain,
        nivel: 925,
      ),
      MonumentoRegional(
        nombre: 'Circuito Judicial Táchira',
        tipo: 'tribunal',
        descripcion: 'Tribunales fronterizos',
        icono: Icons.account_balance,
        nivel: 950,
      ),
      MonumentoRegional(
        nombre: 'Plaza Bolívar Tachirense',
        tipo: 'plaza',
        descripcion: 'Centro histórico andino',
        icono: Icons.landscape,
        nivel: 975,
      ),
    ],
  ),

  // MÉRIDA - Niveles 1001-1125
  RegionVenezuela(
    estado: 'Mérida',
    capital: 'Mérida',
    descripcion: 'Ciudad de los caballeros y sede universitaria',
    nivelInicio: 1001,
    nivelFin: 1125,
    colorPrincipal: const Color(0xFF006400), // Verde oscuro
    imagenFondo: 'regions/merida_background.jpg',
    monumentos: [
      MonumentoRegional(
        nombre: 'Universidad de Los Andes',
        tipo: 'institucion',
        descripcion: 'Alma mater andina',
        icono: Icons.school,
        nivel: 1025,
        esHistorico: true,
      ),
      MonumentoRegional(
        nombre: 'Catedral Metropolitana de Mérida',
        tipo: 'iglesia',
        descripcion: 'Basílica menor andina',
        icono: Icons.church,
        nivel: 1050,
        esHistorico: true,
      ),
      MonumentoRegional(
        nombre: 'Tribunales de Mérida',
        tipo: 'tribunal',
        descripcion: 'Circuito judicial andino',
        icono: Icons.gavel,
        nivel: 1075,
      ),
      MonumentoRegional(
        nombre: 'Plaza Bolívar de Mérida',
        tipo: 'plaza',
        descripcion: 'Centro cívico',
        icono: Icons.park,
        nivel: 1100,
      ),
    ],
  ),

  // BOLÍVAR - Niveles 1126-1250
  RegionVenezuela(
    estado: 'Bolívar',
    capital: 'Ciudad Bolívar',
    descripcion: 'Puerta de entrada a la Gran Sabana',
    nivelInicio: 1126,
    nivelFin: 1250,
    colorPrincipal: const Color(0xFFCD853F), // Marrón dorado
    imagenFondo: 'regions/bolivar_background.jpg',
    monumentos: [
      MonumentoRegional(
        nombre: 'Catedral de Ciudad Bolívar',
        tipo: 'iglesia',
        descripcion: 'Templo colonial guayanés',
        icono: Icons.church,
        nivel: 1150,
        esHistorico: true,
      ),
      MonumentoRegional(
        nombre: 'Casa del Congreso de Angostura',
        tipo: 'colonial',
        descripcion: 'Sitio histórico independentista',
        icono: Icons.account_balance,
        nivel: 1175,
        esHistorico: true,
      ),
      MonumentoRegional(
        nombre: 'Palacio de Justicia Bolívar',
        tipo: 'tribunal',
        descripcion: 'Centro judicial guayanés',
        icono: Icons.gavel,
        nivel: 1200,
      ),
      MonumentoRegional(
        nombre: 'Plaza Bolívar Colonial',
        tipo: 'plaza',
        descripcion: 'Centro histórico',
        icono: Icons.landscape,
        nivel: 1225,
        esHistorico: true,
      ),
    ],
  ),

  // ANZOÁTEGUI - Niveles 1251-1400
  RegionVenezuela(
    estado: 'Anzoátegui',
    capital: 'Barcelona',
    descripcion: 'Estado oriental con historia independentista',
    nivelInicio: 1251,
    nivelFin: 1400,
    colorPrincipal: const Color(0xFF1E90FF), // Azul dodger
    imagenFondo: 'regions/anzoategui_background.jpg',
    monumentos: [
      MonumentoRegional(
        nombre: 'Casa Fuerte de Barcelona',
        tipo: 'colonial',
        descripcion: 'Sitio del martirio patriótico',
        icono: Icons.fort,
        nivel: 1275,
        esHistorico: true,
      ),
      MonumentoRegional(
        nombre: 'Catedral de Barcelona',
        tipo: 'iglesia',
        descripcion: 'Templo colonial oriental',
        icono: Icons.church,
        nivel: 1300,
        esHistorico: true,
      ),
      MonumentoRegional(
        nombre: 'Circuito Judicial Anzoátegui',
        tipo: 'tribunal',
        descripcion: 'Tribunales del oriente',
        icono: Icons.account_balance,
        nivel: 1325,
      ),
      MonumentoRegional(
        nombre: 'Plaza Bolívar de Barcelona',
        tipo: 'plaza',
        descripcion: 'Centro histórico oriental',
        icono: Icons.park,
        nivel: 1375,
      ),
    ],
  ),
  // SUCRE - Niveles 1401-1525
  RegionVenezuela(
    estado: 'Sucre',
    capital: 'Cumaná',
    descripcion: 'Primogénita del continente americano',
    nivelInicio: 1401,
    nivelFin: 1525,
    colorPrincipal: const Color(0xFFFF4500), // Naranja rojizo
    imagenFondo: 'regions/sucre_background.jpg',
    monumentos: [
      MonumentoRegional(
        nombre: 'Castillo de San Antonio',
        tipo: 'colonial',
        descripcion: 'Fortificación colonial de Cumaná',
        icono: Icons.castle,
        nivel: 1425,
        esHistorico: true,
      ),
      MonumentoRegional(
        nombre: 'Catedral de Cumaná',
        tipo: 'iglesia',
        descripcion: 'Primera catedral de Tierra Firme',
        icono: Icons.church,
        nivel: 1450,
        esHistorico: true,
      ),
      MonumentoRegional(
        nombre: 'Tribunales de Sucre',
        tipo: 'tribunal',
        descripcion: 'Circuito judicial oriental',
        icono: Icons.gavel,
        nivel: 1475,
      ),
      MonumentoRegional(
        nombre: 'Plaza Bolívar de Cumaná',
        tipo: 'plaza',
        descripcion: 'Centro histórico primogénito',
        icono: Icons.park,
        nivel: 1500,
        esHistorico: true,
      ),
    ],
  ),

  // MONAGAS - Niveles 1526-1650
  RegionVenezuela(
    estado: 'Monagas',
    capital: 'Maturín',
    descripcion: 'Tierra de José Tadeo y José Gregorio Monagas',
    nivelInicio: 1526,
    nivelFin: 1650,
    colorPrincipal: const Color(0xFF32CD32), // Verde lima
    imagenFondo: 'regions/monagas_background.jpg',
    monumentos: [
      MonumentoRegional(
        nombre: 'Catedral de Maturín',
        tipo: 'iglesia',
        descripcion: 'Templo principal monaguense',
        icono: Icons.church,
        nivel: 1550,
      ),
      MonumentoRegional(
        nombre: 'Palacio de Gobierno Monagas',
        tipo: 'institucion',
        descripcion: 'Sede ejecutiva regional',
        icono: Icons.domain,
        nivel: 1575,
      ),
      MonumentoRegional(
        nombre: 'Circuito Judicial Monagas',
        tipo: 'tribunal',
        descripcion: 'Tribunales del estado',
        icono: Icons.account_balance,
        nivel: 1600,
      ),
      MonumentoRegional(
        nombre: 'Museo Histórico Monagas',
        tipo: 'institucion',
        descripcion: 'Patrimonio histórico',
        icono: Icons.museum,
        nivel: 1625,
      ),
    ],
  ),

  // DELTA AMACURO - Niveles 1651-1775
  RegionVenezuela(
    estado: 'Delta Amacuro',
    capital: 'Tucupita',
    descripcion: 'Delta del Orinoco y tierra Warao',
    nivelInicio: 1651,
    nivelFin: 1775,
    colorPrincipal: const Color(0xFF20B2AA), // Verde azulado
    imagenFondo: 'regions/delta_background.jpg',
    monumentos: [
      MonumentoRegional(
        nombre: 'Catedral de Tucupita',
        tipo: 'iglesia',
        descripcion: 'Templo del delta',
        icono: Icons.church,
        nivel: 1675,
      ),
      MonumentoRegional(
        nombre: 'Tribunales Delta Amacuro',
        tipo: 'tribunal',
        descripcion: 'Justicia en el delta',
        icono: Icons.gavel,
        nivel: 1700,
      ),
      MonumentoRegional(
        nombre: 'Casa de la Cultura Warao',
        tipo: 'institucion',
        descripcion: 'Patrimonio indígena',
        icono: Icons.account_balance,
        nivel: 1725,
      ),
      MonumentoRegional(
        nombre: 'Plaza Bolívar de Tucupita',
        tipo: 'plaza',
        descripcion: 'Centro cívico deltano',
        icono: Icons.park,
        nivel: 1750,
      ),
    ],
  ),

  // AMAZONAS - Niveles 1776-1900
  RegionVenezuela(
    estado: 'Amazonas',
    capital: 'Puerto Ayacucho',
    descripcion: 'Pulmón vegetal de Venezuela',
    nivelInicio: 1776,
    nivelFin: 1900,
    colorPrincipal: const Color(0xFF228B22), // Verde bosque
    imagenFondo: 'regions/amazonas_background.jpg',
    monumentos: [
      MonumentoRegional(
        nombre: 'Catedral de Puerto Ayacucho',
        tipo: 'iglesia',
        descripcion: 'Templo amazónico',
        icono: Icons.church,
        nivel: 1800,
      ),
      MonumentoRegional(
        nombre: 'Tribunales de Amazonas',
        tipo: 'tribunal',
        descripcion: 'Justicia en la selva',
        icono: Icons.gavel,
        nivel: 1825,
      ),
      MonumentoRegional(
        nombre: 'Museo Etnológico',
        tipo: 'institucion',
        descripcion: 'Culturas indígenas amazónicas',
        icono: Icons.museum,
        nivel: 1850,
      ),
      MonumentoRegional(
        nombre: 'Gobernación de Amazonas',
        tipo: 'institucion',
        descripcion: 'Sede del ejecutivo',
        icono: Icons.domain,
        nivel: 1875,
      ),
    ],
  ),

  // APURE - Niveles 1901-2025
  RegionVenezuela(
    estado: 'Apure',
    capital: 'San Fernando de Apure',
    descripcion: 'Llanos venezolanos y tierra de José Antonio Páez',
    nivelInicio: 1901,
    nivelFin: 2025,
    colorPrincipal: const Color(0xFFDEB887), // Marrón llanero
    imagenFondo: 'regions/apure_background.jpg',
    monumentos: [
      MonumentoRegional(
        nombre: 'Catedral de San Fernando',
        tipo: 'iglesia',
        descripcion: 'Templo llanero',
        icono: Icons.church,
        nivel: 1925,
      ),
      MonumentoRegional(
        nombre: 'Plaza Páez',
        tipo: 'plaza',
        descripcion: 'Homenaje al Centauro',
        icono: Icons.park,
        nivel: 1950,
        esHistorico: true,
      ),
      MonumentoRegional(
        nombre: 'Circuito Judicial Apure',
        tipo: 'tribunal',
        descripcion: 'Tribunales llaneros',
        icono: Icons.account_balance,
        nivel: 1975,
      ),
      MonumentoRegional(
        nombre: 'Palacio de Gobierno Apure',
        tipo: 'institucion',
        descripcion: 'Sede gubernamental',
        icono: Icons.domain,
        nivel: 2000,
      ),
    ],
  ),

  // BARINAS - Niveles 2026-2150
  RegionVenezuela(
    estado: 'Barinas',
    capital: 'Barinas',
    descripcion: 'Tierra de los llanos altos',
    nivelInicio: 2026,
    nivelFin: 2150,
    colorPrincipal: const Color(0xFFFF8C00), // Naranja oscuro
    imagenFondo: 'regions/barinas_background.jpg',
    monumentos: [
      MonumentoRegional(
        nombre: 'Catedral Nuestra Señora del Pilar',
        tipo: 'iglesia',
        descripcion: 'Templo principal barinés',
        icono: Icons.church,
        nivel: 2050,
      ),
      MonumentoRegional(
        nombre: 'Casa de la Cultura',
        tipo: 'institucion',
        descripcion: 'Centro cultural de Barinas',
        icono: Icons.museum,
        nivel: 2075,
      ),
      MonumentoRegional(
        nombre: 'Tribunales de Barinas',
        tipo: 'tribunal',
        descripcion: 'Circuito judicial',
        icono: Icons.gavel,
        nivel: 2100,
      ),
      MonumentoRegional(
        nombre: 'Plaza Bolívar de Barinas',
        tipo: 'plaza',
        descripcion: 'Centro histórico',
        icono: Icons.park,
        nivel: 2125,
      ),
    ],
  ),

  // PORTUGUESA - Niveles 2151-2275
  RegionVenezuela(
    estado: 'Portuguesa',
    capital: 'Guanare',
    descripcion: 'Granero de Venezuela',
    nivelInicio: 2151,
    nivelFin: 2275,
    colorPrincipal: const Color(0xFFFFD700), // Dorado agrícola
    imagenFondo: 'regions/portuguesa_background.jpg',
    monumentos: [
      MonumentoRegional(
        nombre: 'Santuario de Coromoto',
        tipo: 'iglesia',
        descripcion: 'Basílica patronal de Venezuela',
        icono: Icons.church,
        nivel: 2175,
        esHistorico: true,
      ),
      MonumentoRegional(
        nombre: 'Plaza Bolívar de Guanare',
        tipo: 'plaza',
        descripcion: 'Centro cívico',
        icono: Icons.park,
        nivel: 2200,
      ),
      MonumentoRegional(
        nombre: 'Circuito Judicial Portuguesa',
        tipo: 'tribunal',
        descripcion: 'Tribunales del granero',
        icono: Icons.account_balance,
        nivel: 2225,
      ),
      MonumentoRegional(
        nombre: 'Palacio Episcopal',
        tipo: 'institucion',
        descripcion: 'Sede eclesiástica',
        icono: Icons.domain,
        nivel: 2250,
      ),
    ],
  ),

  // COJEDES - Niveles 2276-2400
  RegionVenezuela(
    estado: 'Cojedes',
    capital: 'San Carlos',
    descripcion: 'Estado central de Venezuela',
    nivelInicio: 2276,
    nivelFin: 2400,
    colorPrincipal: const Color(0xFF9370DB), // Púrpura medio
    imagenFondo: 'regions/cojedes_background.jpg',
    monumentos: [
      MonumentoRegional(
        nombre: 'Catedral de San Carlos',
        tipo: 'iglesia',
        descripcion: 'Templo principal',
        icono: Icons.church,
        nivel: 2300,
      ),
      MonumentoRegional(
        nombre: 'Tribunales de Cojedes',
        tipo: 'tribunal',
        descripcion: 'Circuito judicial',
        icono: Icons.gavel,
        nivel: 2325,
      ),
      MonumentoRegional(
        nombre: 'Plaza Bolívar de San Carlos',
        tipo: 'plaza',
        descripcion: 'Centro histórico',
        icono: Icons.park,
        nivel: 2350,
      ),
      MonumentoRegional(
        nombre: 'Palacio de Gobierno',
        tipo: 'institucion',
        descripcion: 'Sede ejecutiva',
        icono: Icons.domain,
        nivel: 2375,
      ),
    ],
  ),

  // GUÁRICO - Niveles 2401-2525
  RegionVenezuela(
    estado: 'Guárico',
    capital: 'San Juan de los Morros',
    descripcion: 'Corazón de los llanos centrales',
    nivelInicio: 2401,
    nivelFin: 2525,
    colorPrincipal: const Color(0xFF8B4513), // Marrón silla
    imagenFondo: 'regions/guarico_background.jpg',
    monumentos: [
      MonumentoRegional(
        nombre: 'Morros de San Juan',
        tipo: 'colonial',
        descripcion: 'Formación geológica emblemática',
        icono: Icons.landscape,
        nivel: 2425,
        esHistorico: true,
      ),
      MonumentoRegional(
        nombre: 'Catedral de San Juan',
        tipo: 'iglesia',
        descripcion: 'Templo principal',
        icono: Icons.church,
        nivel: 2450,
      ),
      MonumentoRegional(
        nombre: 'Circuito Judicial Guárico',
        tipo: 'tribunal',
        descripcion: 'Tribunales llaneros',
        icono: Icons.account_balance,
        nivel: 2475,
      ),
      MonumentoRegional(
        nombre: 'Plaza Bolívar Guarica',
        tipo: 'plaza',
        descripcion: 'Centro cívico',
        icono: Icons.park,
        nivel: 2500,
      ),
    ],
  ),

  // YARACUY - Niveles 2526-2650
  RegionVenezuela(
    estado: 'Yaracuy',
    capital: 'San Felipe',
    descripcion: 'Tierra de María Lionza',
    nivelInicio: 2526,
    nivelFin: 2650,
    colorPrincipal: const Color(0xFF9932CC), // Orquídea oscuro
    imagenFondo: 'regions/yaracuy_background.jpg',
    monumentos: [
      MonumentoRegional(
        nombre: 'Catedral de San Felipe',
        tipo: 'iglesia',
        descripcion: 'Templo yaracuyano',
        icono: Icons.church,
        nivel: 2550,
      ),
      MonumentoRegional(
        nombre: 'Santuario de María Lionza',
        tipo: 'colonial',
        descripcion: 'Monumento místico',
        icono: Icons.self_improvement,
        nivel: 2575,
        esHistorico: true,
      ),
      MonumentoRegional(
        nombre: 'Tribunales de Yaracuy',
        tipo: 'tribunal',
        descripcion: 'Circuito judicial',
        icono: Icons.gavel,
        nivel: 2600,
      ),
      MonumentoRegional(
        nombre: 'Palacio Municipal',
        tipo: 'institucion',
        descripcion: 'Sede gubernamental',
        icono: Icons.domain,
        nivel: 2625,
      ),
    ],
  ),

  // FALCÓN - Niveles 2651-2800
  RegionVenezuela(
    estado: 'Falcón',
    capital: 'Coro',
    descripcion: 'Patrimonio histórico de la humanidad',
    nivelInicio: 2651,
    nivelFin: 2800,
    colorPrincipal: const Color(0xFFE9967A), // Salmón oscuro
    imagenFondo: 'regions/falcon_background.jpg',
    monumentos: [
      MonumentoRegional(
        nombre: 'Catedral de Coro',
        tipo: 'iglesia',
        descripcion: 'Primera catedral continental',
        icono: Icons.church,
        nivel: 2675,
        esHistorico: true,
      ),
      MonumentoRegional(
        nombre: 'Cruz de San Clemente',
        tipo: 'colonial',
        descripcion: 'Monumento fundacional',
        icono: Icons.add_circle,
        nivel: 2700,
        esHistorico: true,
      ),
      MonumentoRegional(
        nombre: 'Casa de las Ventanas de Hierro',
        tipo: 'colonial',
        descripcion: 'Arquitectura colonial',
        icono: Icons.home,
        nivel: 2725,
        esHistorico: true,
      ),
      MonumentoRegional(
        nombre: 'Tribunales de Falcón',
        tipo: 'tribunal',
        descripcion: 'Circuito judicial patrimonial',
        icono: Icons.account_balance,
        nivel: 2750,
      ),
      MonumentoRegional(
        nombre: 'Cementerio Judío de Coro',
        tipo: 'colonial',
        descripcion: 'Patrimonio de la humanidad',
        icono: Icons.museum,
        nivel: 2775,
        esHistorico: true,
      ),
    ],
  ),

  // DISTRITO CAPITAL (RETORNO) - Niveles 2801-3000
  // DISTRITO CAPITAL (RETORNO) - Niveles 2801-3000
  RegionVenezuela(
    estado: 'Distrito Capital',
    capital: 'Caracas',
    descripcion: 'Retorno a la capital como Magistrado Supremo',
    nivelInicio: 2801,
    nivelFin: 3000,
    colorPrincipal: const Color(0xFFFFD700), // Dorado supremo
    imagenFondo: 'regions/caracas_magistrado.jpg',
    monumentos: [
      MonumentoRegional(
        nombre: 'Sala Constitucional TSJ',
        tipo: 'tribunal',
        descripcion: 'Máxima instancia constitucional',
        icono: Icons.gavel,
        nivel: 2850,
      ),
      MonumentoRegional(
        nombre: 'Sala de Casación Penal',
        tipo: 'tribunal',
        descripcion: 'Última instancia penal',
        icono: Icons.balance,
        nivel: 2900,
      ),
      MonumentoRegional(
        nombre: 'Presidencia del TSJ',
        tipo: 'tribunal',
        descripcion: 'Cúspide del Poder Judicial',
        icono: Icons.emoji_events,
        nivel: 2950,
      ),
      MonumentoRegional(
        nombre: 'Magistratura Suprema',
        tipo: 'tribunal',
        descripcion: 'Cumbre de la carrera judicial',
        icono: Icons.workspace_premium,
        nivel: 3000,
      ),
    ],
  ),
];

/// Obtener la región actual según el nivel
RegionVenezuela? getRegionForLevel(int nivel) {
  try {
    return regionesVenezuela.firstWhere(
      (region) => region.contieneNivel(nivel),
    );
  } catch (e) {
    return null;
  }
}

/// Obtener monumentos visibles en un rango de niveles
List<MonumentoRegional> getMonumentosInRange(int nivelInicio, int nivelFin) {
  final List<MonumentoRegional> monumentos = [];
  
  for (final region in regionesVenezuela) {
    if (region.nivelInicio <= nivelFin && region.nivelFin >= nivelInicio) {
      for (final monumento in region.monumentos) {
        if (monumento.nivel >= nivelInicio && monumento.nivel <= nivelFin) {
          monumentos.add(monumento);
        }
      }
    }
  }
  
  return monumentos;
}
