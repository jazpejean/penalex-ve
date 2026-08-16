import React from 'react';
import { UserProfile } from '../types';
import { LOGROS_LIST } from '../data/logrosData';
import { 
  ShieldAlert, 
  CheckCircle2, 
  Lock, 
  Flame, 
  Award, 
  Gavel, 
  Crown, 
  Sparkles, 
  BookOpen, 
  TrendingUp, 
  Briefcase, 
  ShieldCheck, 
  Zap 
} from 'lucide-react';

interface AchievementsViewProps {
  profile: UserProfile;
}

export const AchievementsView: React.FC<AchievementsViewProps> = ({ profile }) => {
  const iconMap: Record<string, any> = {
    CheckCircle2,
    ShieldAlert,
    Flame,
    Zap,
    BookOpen,
    Award,
    ShieldCheck,
    Briefcase,
    Gavel,
    TrendingUp,
    Crown,
    Sparkles
  };

  const isUnlocked = (logro: typeof LOGROS_LIST[0]) => {
    if (logro.nivel_requerido && profile.nivel_actual >= logro.nivel_requerido) return true;
    if (logro.racha_requerida && (profile.max_racha >= logro.racha_requerida || profile.racha_actual >= logro.racha_requerida)) return true;
    if (logro.puntos_requeridos && profile.puntos_totales >= logro.puntos_requeridos) return true;
    return profile.logros.includes(logro.id);
  };

  const unlockedCount = LOGROS_LIST.filter(isUnlocked).length;

  return (
    <div className="max-w-5xl mx-auto px-3 sm:px-6 pb-24">
      
      {/* Header */}
      <div className="text-center max-w-2xl mx-auto mb-8">
        <div className="inline-flex items-center justify-center w-14 h-14 rounded-2xl bg-amber-950/80 border border-amber-500/40 mb-3 shadow-lg shadow-amber-950/60">
          <ShieldAlert className="w-8 h-8 text-amber-400" />
        </div>
        <h2 className="font-judicial text-2xl sm:text-4xl font-extrabold text-transparent bg-clip-text bg-gradient-to-r from-amber-200 via-amber-400 to-amber-600 mb-2">
          Insignias y Logros Judiciales
        </h2>
        <p className="text-sm text-slate-300">
          Desbloquea condecoraciones especiales del foro penal al superar niveles, mantener rachas y dictar sentencias.
        </p>

        {/* Progress Bar */}
        <div className="mt-4 bg-[#0a0f1d] border border-slate-800 rounded-2xl p-4 max-w-md mx-auto">
          <div className="flex justify-between text-xs font-mono mb-1.5">
            <span className="text-slate-400">Progreso Total de Insignias:</span>
            <span className="font-bold text-amber-400">{unlockedCount} / {LOGROS_LIST.length} ({Math.round((unlockedCount / LOGROS_LIST.length) * 100)}%)</span>
          </div>
          <div className="w-full h-2.5 bg-slate-900 rounded-full overflow-hidden border border-slate-800">
            <div 
              className="h-full bg-gradient-to-r from-amber-500 to-amber-300 transition-all duration-500" 
              style={{ width: `${(unlockedCount / LOGROS_LIST.length) * 100}%` }}
            />
          </div>
        </div>
      </div>

      {/* Badges Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {LOGROS_LIST.map((logro) => {
          const unlocked = isUnlocked(logro);
          const IconComponent = iconMap[logro.icono] || Award;

          return (
            <div
              key={logro.id}
              className={`rounded-2xl p-5 border-2 transition-all flex items-start gap-4 ${
                unlocked
                  ? 'bg-gradient-to-br from-[#18233d] to-[#0f172a] border-amber-500/80 shadow-xl shadow-amber-950/40'
                  : 'bg-slate-950/60 border-slate-800 opacity-60'
              }`}
            >
              {/* Badge Icon */}
              <div className={`w-14 h-14 rounded-2xl flex items-center justify-center shrink-0 border-2 transition-all ${
                unlocked
                  ? 'bg-gradient-to-tr from-amber-600 to-amber-400 text-slate-950 border-amber-200 shadow-lg shadow-amber-500/30'
                  : 'bg-slate-900 border-slate-800 text-slate-600'
              }`}>
                {unlocked ? (
                  <IconComponent className="w-7 h-7" />
                ) : (
                  <Lock className="w-6 h-6 text-slate-600" />
                )}
              </div>

              {/* Info */}
              <div className="flex-1">
                <div className="flex items-center justify-between gap-1 mb-1">
                  <h4 className={`font-judicial text-base font-bold ${
                    unlocked ? 'text-amber-200' : 'text-slate-400'
                  }`}>
                    {logro.nombre}
                  </h4>
                  {unlocked && (
                    <span className="text-[10px] uppercase tracking-wider font-bold text-emerald-400 font-mono bg-emerald-950/60 px-1.5 py-0.5 rounded border border-emerald-800/50">
                      Concedido
                    </span>
                  )}
                </div>

                <p className="text-xs text-slate-300 leading-relaxed mb-2">
                  {logro.descripcion}
                </p>

                <span className="text-[10px] font-mono text-slate-500 block">
                  {logro.nivel_requerido && `Requisito: Nivel ${logro.nivel_requerido}`}
                  {logro.racha_requerida && `Requisito: Racha de ${logro.racha_requerida} aciertos`}
                  {logro.puntos_requeridos && `Requisito: ${logro.puntos_requeridos} XP`}
                </span>
              </div>
            </div>
          );
        })}
      </div>

    </div>
  );
};
