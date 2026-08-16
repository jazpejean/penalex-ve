import { JudicialRank } from '../types';

/**
 * Rangos Judiciales Oficiales de PENALEX VE
 * Exactamente alineados con la jerarquía del Poder Judicial y Circuito Penal Venezolano
 */
export const JUDICIAL_RANKS: JudicialRank[] = [
  {
    minLevel: 1,
    maxLevel: 1,
    title: 'Alguacil de Sala',
    sala: 'Alguacilazgo del Circuito Penal',
    badgeIcon: 'ShieldAlert',
    description: 'Custodio del orden en las salas de audiencia y ejecutor de citaciones penales.',
    color: '#64748b'
  },
  {
    minLevel: 2,
    maxLevel: 3,
    title: 'Asistente Jurídico',
    sala: 'Secretaría de Tribunal de Municipio',
    badgeIcon: 'BookOpen',
    description: 'Colaborador en la organización de expedientes y doctrina procesal penal básica.',
    color: '#71717a'
  },
  {
    minLevel: 4,
    maxLevel: 7,
    title: 'Escribiente',
    sala: 'Secretaría de Primera Instancia',
    badgeIcon: 'FileText',
    description: 'Redactor de actas de audiencia preliminar y transcripción de fallos judiciales.',
    color: '#818cf8'
  },
  {
    minLevel: 8,
    maxLevel: 14,
    title: 'Secretario de Tribunal de Municipio',
    sala: 'Juzgado de Municipio Ordinario y Ejecutor',
    badgeIcon: 'Scroll',
    description: 'Fedatario de los actos en la jurisdicción municipal del circuito penal.',
    color: '#a855f7'
  },
  {
    minLevel: 15,
    maxLevel: 29,
    title: 'Secretario de Tribunal de Primera Instancia',
    sala: 'Tribunal de Primera Instancia en Funciones de Control',
    badgeIcon: 'Award',
    description: 'Certificador judicial de autos, boletas de excarcelación y traslados penales.',
    color: '#c084fc'
  },
  {
    minLevel: 30,
    maxLevel: 69,
    title: 'Juez Accidental de Municipio',
    sala: 'Juzgado de Municipio Penal',
    badgeIcon: 'Gavel',
    description: 'Conocedor de causas penales por faltas y delitos menores según el COPP.',
    color: '#06b6d4'
  },
  {
    minLevel: 70,
    maxLevel: 129,
    title: 'Juez Suplente de Municipio',
    sala: 'Juzgado Municipal Penal de Control',
    badgeIcon: 'Gavel',
    description: 'Suplente habilitado para dictar medidas cautelares de presentación.',
    color: '#0ea5e9'
  },
  {
    minLevel: 130,
    maxLevel: 199,
    title: 'Juez Provisorio de Municipio',
    sala: 'Juzgado Municipal Penal de Juicio',
    badgeIcon: 'Gavel',
    description: 'Juez a cargo del debate y procedimiento especial para juzgamiento de delitos menores.',
    color: '#38bdf8'
  },
  {
    minLevel: 200,
    maxLevel: 299,
    title: 'Juez Titular de Municipio',
    sala: 'Sede Judicial Municipal Penal',
    badgeIcon: 'Scale',
    description: 'Titular de carrera judicial en la jurisdicción penal de municipio.',
    color: '#10b981'
  },
  {
    minLevel: 300,
    maxLevel: 449,
    title: 'Juez Accidental de Primera Instancia',
    sala: 'Circuito Judicial Penal de Primera Instancia',
    badgeIcon: 'Gavel',
    description: 'Habilitado para dirigir audiencias de presentación de imputados en flagrancia.',
    color: '#14b8a6'
  },
  {
    minLevel: 450,
    maxLevel: 599,
    title: 'Juez Suplente de Primera Instancia',
    sala: 'Tribunal en Funciones de Control',
    badgeIcon: 'Gavel',
    description: 'Resolución de solicitudes de privación judicial preventiva de libertad.',
    color: '#eab308'
  },
  {
    minLevel: 600,
    maxLevel: 749,
    title: 'Juez Provisorio de Primera Instancia',
    sala: 'Tribunal en Funciones de Juicio Oral',
    badgeIcon: 'Gavel',
    description: 'Dirección del debate probatorio oral y público en causas graves.',
    color: '#f59e0b'
  },
  {
    minLevel: 750,
    maxLevel: 899,
    title: 'Juez Titular de Primera Instancia',
    sala: 'Tribunal de Primera Instancia Penal Titular',
    badgeIcon: 'Scale',
    description: 'Magistrado titular con competencia plena en las fases preparatoria e intermedia.',
    color: '#d97706'
  },
  {
    minLevel: 900,
    maxLevel: 1049,
    title: 'Juez de Primera Instancia con Competencia Especial',
    sala: 'Tribunal Especializado en Delitos de Delincuencia Organizada',
    badgeIcon: 'ShieldCheck',
    description: 'Competencia en delitos complejos, legitimación de capitales y terrorismo.',
    color: '#ea580c'
  },
  {
    minLevel: 1050,
    maxLevel: 1199,
    title: 'Juez de Primera Instancia con Competencia Nacional',
    sala: 'Circuito Judicial con Jurisdicción Nacional',
    badgeIcon: 'Building2',
    description: 'Jurisdicción extensiva en todo el territorio de la República Bolivariana.',
    color: '#dc2626'
  },
  {
    minLevel: 1200,
    maxLevel: 1399,
    title: 'Juez Provisorio de Corte de Apelaciones',
    sala: 'Corte de Apelaciones del Circuito Penal',
    badgeIcon: 'Crown',
    description: 'Revisor de recursos ordinarios de apelación contra autos y sentencias.',
    color: '#b91c1c'
  },
  {
    minLevel: 1400,
    maxLevel: 1599,
    title: 'Juez Titular de Corte de Apelaciones',
    sala: 'Corte de Apelaciones Penal - Sala Superior',
    badgeIcon: 'Crown',
    description: 'Cuerpo colegiado superior de alzada penal en la circunscripción judicial.',
    color: '#991b1b'
  },
  {
    minLevel: 1600,
    maxLevel: 1799,
    title: 'Juez Presidente del Circuito Judicial Penal',
    sala: 'Presidencia de Circuito Judicial Penal',
    badgeIcon: 'Building2',
    description: 'Máxima autoridad rectora y administrativa del circuito penal estatal.',
    color: '#831843'
  },
  {
    minLevel: 1800,
    maxLevel: 1999,
    title: 'Magistrado Suplente de la Sala de Casación Penal',
    sala: 'Tribunal Supremo de Justicia - Sala de Casación Penal',
    badgeIcon: 'Sparkles',
    description: 'Convocado al TSJ para conocer de recursos extraordinarios de casación.',
    color: '#9d174d'
  },
  {
    minLevel: 2000,
    maxLevel: 2199,
    title: 'Secretario de la Sala de Casación Penal',
    sala: 'Secretaría de la Sala Penal del TSJ',
    badgeIcon: 'Award',
    description: 'Fedatario máximo de las sentencias vinculantes de casación penal.',
    color: '#701a75'
  },
  {
    minLevel: 2200,
    maxLevel: 2399,
    title: 'Magistrado Principal de la Sala de Casación Penal',
    sala: 'Sala de Casación Penal del TSJ',
    badgeIcon: 'Crown',
    description: 'Unificador de la jurisprudencia penal y garante de la recta aplicación del derecho.',
    color: '#f59e0b'
  },
  {
    minLevel: 2400,
    maxLevel: 2599,
    title: 'Vicepresidente de la Sala de Casación Penal',
    sala: 'Mesa Directiva de la Sala Penal del TSJ',
    badgeIcon: 'Crown',
    description: 'Segundo al mando en la dirección doctrinal de la Sala de Casación Penal.',
    color: '#fbbf24'
  },
  {
    minLevel: 2600,
    maxLevel: 2799,
    title: 'Presidente de la Sala de Casación Penal',
    sala: 'Presidencia de la Sala de Casación Penal TSJ',
    badgeIcon: 'Medal',
    description: 'Líder supremo del órgano colegiado de casación penal de Venezuela.',
    color: '#fef08a'
  },
  {
    minLevel: 2800,
    maxLevel: 2999,
    title: 'Presidente del Tribunal Supremo de Justicia',
    sala: 'Sala Plena del Tribunal Supremo de Justicia',
    badgeIcon: 'Crown',
    description: 'Máxima autoridad constitucional del Poder Judicial en toda Venezuela.',
    color: '#facc15'
  },
  {
    minLevel: 3000,
    maxLevel: 3000,
    title: 'Presidente Emérito',
    sala: 'Cúpula Suprema Perpetua del TSJ',
    badgeIcon: 'Crown',
    description: 'Máxima cúspide histórica de la jurisprudencia y doctrina penal venezolana.',
    color: '#fef08a',
    isMilestoneCertificate: true
  }
];

export function getRankByLevel(level: number): JudicialRank {
  if (level >= 3000) return JUDICIAL_RANKS.find(r => r.title === 'Presidente Emérito')!;
  if (level >= 2800) return JUDICIAL_RANKS.find(r => r.title === 'Presidente del Tribunal Supremo de Justicia')!;
  if (level >= 2600) return JUDICIAL_RANKS.find(r => r.title === 'Presidente de la Sala de Casación Penal')!;
  if (level >= 2400) return JUDICIAL_RANKS.find(r => r.title === 'Vicepresidente de la Sala de Casación Penal')!;
  if (level >= 2200) return JUDICIAL_RANKS.find(r => r.title === 'Magistrado Principal de la Sala de Casación Penal')!;
  if (level >= 2000) return JUDICIAL_RANKS.find(r => r.title === 'Secretario de la Sala de Casación Penal')!;
  if (level >= 1800) return JUDICIAL_RANKS.find(r => r.title === 'Magistrado Suplente de la Sala de Casación Penal')!;
  if (level >= 1600) return JUDICIAL_RANKS.find(r => r.title === 'Juez Presidente del Circuito Judicial Penal')!;
  if (level >= 1400) return JUDICIAL_RANKS.find(r => r.title === 'Juez Titular de Corte de Apelaciones')!;
  if (level >= 1200) return JUDICIAL_RANKS.find(r => r.title === 'Juez Provisorio de Corte de Apelaciones')!;
  if (level >= 1050) return JUDICIAL_RANKS.find(r => r.title === 'Juez de Primera Instancia con Competencia Nacional')!;
  if (level >= 900) return JUDICIAL_RANKS.find(r => r.title === 'Juez de Primera Instancia con Competencia Especial')!;
  if (level >= 750) return JUDICIAL_RANKS.find(r => r.title === 'Juez Titular de Primera Instancia')!;
  if (level >= 600) return JUDICIAL_RANKS.find(r => r.title === 'Juez Provisorio de Primera Instancia')!;
  if (level >= 450) return JUDICIAL_RANKS.find(r => r.title === 'Juez Suplente de Primera Instancia')!;
  if (level >= 300) return JUDICIAL_RANKS.find(r => r.title === 'Juez Accidental de Primera Instancia')!;
  if (level >= 200) return JUDICIAL_RANKS.find(r => r.title === 'Juez Titular de Municipio')!;
  if (level >= 130) return JUDICIAL_RANKS.find(r => r.title === 'Juez Provisorio de Municipio')!;
  if (level >= 70) return JUDICIAL_RANKS.find(r => r.title === 'Juez Suplente de Municipio')!;
  if (level >= 30) return JUDICIAL_RANKS.find(r => r.title === 'Juez Accidental de Municipio')!;
  if (level >= 15) return JUDICIAL_RANKS.find(r => r.title === 'Secretario de Tribunal de Primera Instancia')!;
  if (level >= 8) return JUDICIAL_RANKS.find(r => r.title === 'Secretario de Tribunal de Municipio')!;
  if (level >= 4) return JUDICIAL_RANKS.find(r => r.title === 'Escribiente')!;
  if (level >= 2) return JUDICIAL_RANKS.find(r => r.title === 'Asistente Jurídico')!;
  return JUDICIAL_RANKS[0]; // Alguacil de Sala
}

export const MILESTONE_LEVELS = [100, 500, 1000, 2000, 3000];
