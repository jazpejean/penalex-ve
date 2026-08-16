import { Logro } from '../types';

export const LOGROS_LIST: Logro[] = [
  {
    id: 'primer_fallo',
    nombre: 'Primer Veredicto',
    descripcion: 'Supera con éxito el nivel 1 de Derecho Penal.',
    nivel_requerido: 1,
    icono: 'CheckCircle2',
    categoria: 'nivel'
  },
  {
    id: 'alguacil_juramentado',
    nombre: 'Alguacil Juramentado',
    descripcion: 'Alcanza el nivel 10 en la carrera judicial.',
    nivel_requerido: 10,
    icono: 'ShieldAlert',
    categoria: 'nivel'
  },
  {
    id: 'racha_impecable_5',
    nombre: 'Jurisprudencia Sólida',
    descripcion: 'Consigue una racha de 5 respuestas correctas consecutivas.',
    racha_requerida: 5,
    icono: 'Flame',
    categoria: 'racha'
  },
  {
    id: 'racha_maestra_10',
    nombre: 'In dubio pro reo',
    descripcion: 'Consigue una racha de 10 respuestas correctas consecutivas sin perder apelaciones.',
    racha_requerida: 10,
    icono: 'Zap',
    categoria: 'racha'
  },
  {
    id: 'escribiente_experto',
    nombre: 'Escribiente Mayor',
    descripcion: 'Alcanza el nivel 50 resolviendo casos del Código Penal.',
    nivel_requerido: 50,
    icono: 'BookOpen',
    categoria: 'nivel'
  },
  {
    id: 'primer_diploma_100',
    nombre: 'Certificado de Secretario Penal',
    descripcion: 'Alcanza el nivel 100 y genera tu primer diploma oficial.',
    nivel_requerido: 100,
    icono: 'Award',
    categoria: 'nivel'
  },
  {
    id: 'defensa_inquebrantable',
    nombre: 'Defensa Técnica Inviolable',
    descripcion: 'Alcanza el nivel 250 dominando garantías procesales del COPP.',
    nivel_requerido: 250,
    icono: 'ShieldCheck',
    categoria: 'nivel'
  },
  {
    id: 'fiscal_honorifico',
    nombre: 'Fiscal de Casación',
    descripcion: 'Alcanza el nivel 500 y desbloquea el Diploma de Fiscal de la República.',
    nivel_requerido: 500,
    icono: 'Briefcase',
    categoria: 'nivel'
  },
  {
    id: 'juez_titular_1000',
    nombre: 'Juez Titular de Juicio',
    descripcion: 'Alcanza el nivel 1000 en la judicatura penal venezolana.',
    nivel_requerido: 1000,
    icono: 'Gavel',
    categoria: 'nivel'
  },
  {
    id: 'acumulador_xp_1000',
    nombre: 'Precedente Vinculante',
    descripcion: 'Acumula 1,000 puntos de experiencia judicial (XP).',
    puntos_requeridos: 1000,
    icono: 'TrendingUp',
    categoria: 'puntos'
  },
  {
    id: 'corte_apelaciones_2000',
    nombre: 'Corte de Apelaciones',
    descripcion: 'Alcanza el nivel 2000 y domina todos los recursos penales.',
    nivel_requerido: 2000,
    icono: 'Crown',
    categoria: 'nivel'
  },
  {
    id: 'gran_magistrado_3000',
    nombre: 'Doctor Honoris Causa TSJ',
    descripcion: 'Completa los 3000 niveles y alcanza la Presidencia del TSJ.',
    nivel_requerido: 3000,
    icono: 'Sparkles',
    categoria: 'nivel'
  }
];
