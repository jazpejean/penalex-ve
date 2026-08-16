import React, { useEffect } from 'react';
import confetti from 'canvas-confetti';
import { UserProfile, JudicialRank } from '../types';
import { getRankByLevel, MILESTONE_LEVELS } from '../data/judicialRanks';
import { sounds } from '../services/soundEffects';
import { Award, Sparkles, Flame, ChevronRight, CheckCircle2, Crown, Scroll } from 'lucide-react';

interface LevelUpModalProps {
  isOpen: boolean;
  onClose: () => void;
  profile: UserProfile;
  levelPassed: number;
  xpEarned: number;
  streak: number;
  onGoToNextLevel: () => void;
  onViewCertificate: () => void;
}

export const LevelUpModal: React.FC<LevelUpModalProps> = ({
  isOpen,
  onClose,
  profile,
  levelPassed,
  xpEarned,
  streak,
  onGoToNextLevel,
  onViewCertificate
}) => {
  const currentRank: JudicialRank = getRankByLevel(levelPassed + 1);
  const isMilestone = MILESTONE_LEVELS.includes(levelPassed);

  useEffect(() => {
    if (!isOpen) return;

    // Trigger triumphant sound
    sounds.playLevelUp();

    // Trigger vibrant particle and gold confetti explosion
    const count = 200;
    const defaults = {
      origin: { y: 0.6 }
    };

    function fire(particleRatio: number, opts: confetti.Options) {
      confetti({
        ...defaults,
        ...opts,
        particleCount: Math.floor(count * particleRatio)
      });
    }

    fire(0.25, {
      spread: 26,
      startVelocity: 55,
      colors: ['#f59e0b', '#fbbf24', '#d97706']
    });
    fire(0.2, {
      spread: 60,
      colors: ['#ffffff', '#fef08a', '#eab308']
    });
    fire(0.35, {
      spread: 100,
      decay: 0.91,
      scalar: 0.8,
      colors: ['#38bdf8', '#818cf8', '#f59e0b']
    });
    fire(0.1, {
      spread: 120,
      startVelocity: 25,
      decay: 0.92,
      scalar: 1.2,
      colors: ['#fbbf24', '#f97316']
    });
  }, [isOpen]);

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/85 backdrop-blur-md animate-fade-in">
      <div 
        id="modal-levelup"
        className="w-full max-w-lg bg-gradient-to-b from-[#18233d] via-[#0f172a] to-[#0a0f1d] border-2 border-amber-500 rounded-3xl shadow-2xl p-6 sm:p-8 text-center relative overflow-hidden"
      >
        {/* Golden ambient background radial */}
        <div className="absolute -top-32 left-1/2 -translate-x-1/2 w-80 h-44 bg-amber-500/25 rounded-full blur-3xl pointer-events-none" />

        {/* Level Emblem */}
        <div className="relative inline-block mb-4">
          <div className="w-24 h-24 sm:w-28 sm:h-28 rounded-3xl bg-gradient-to-tr from-amber-600 via-amber-400 to-yellow-200 p-1 shadow-xl shadow-amber-950/80 mx-auto transform hover:rotate-6 transition-transform">
            <div className="w-full h-full bg-[#0d1322] rounded-[22px] flex flex-col items-center justify-center border border-amber-300/40">
              <span className="text-[10px] font-mono tracking-widest text-amber-400 uppercase font-bold">
                Nivel Superado
              </span>
              <span className="font-judicial text-3xl sm:text-4xl font-black text-amber-300">
                {levelPassed}
              </span>
              <div className="flex gap-0.5 mt-0.5">
                {[1, 2, 3].map((s) => (
                  <Sparkles key={s} className="w-3 h-3 text-amber-400 fill-amber-400" />
                ))}
              </div>
            </div>
          </div>
          {isMilestone && (
            <div className="absolute -top-2 -right-2 bg-gradient-to-r from-amber-500 to-rose-600 text-slate-950 p-1.5 rounded-full shadow-lg border border-amber-200 animate-bounce">
              <Crown className="w-5 h-5 text-slate-950 fill-slate-950" />
            </div>
          )}
        </div>

        {/* Title */}
        <h2 className="font-judicial text-2xl sm:text-3xl font-extrabold text-transparent bg-clip-text bg-gradient-to-r from-amber-200 via-amber-400 to-yellow-300 mb-1">
          ¡Veredicto Favorable!
        </h2>
        <p className="text-sm text-slate-300 mb-6">
          Has fundamentado correctamente el caso conforme al Derecho Penal Venezolano.
        </p>

        {/* Rewards Breakdown Box */}
        <div className="bg-[#0b101d] border border-amber-900/60 rounded-2xl p-4 sm:p-5 mb-6 text-left space-y-3 shadow-inner">
          <div className="flex items-center justify-between text-sm">
            <span className="text-slate-400 flex items-center gap-1.5">
              <Sparkles className="w-4 h-4 text-amber-400" />
              Puntos Base de Jurisprudencia:
            </span>
            <span className="font-mono font-bold text-amber-300">+10 XP</span>
          </div>

          {streak >= 3 && (
            <div className="flex items-center justify-between text-sm">
              <span className="text-orange-400 flex items-center gap-1.5 font-medium">
                <Flame className="w-4 h-4 text-orange-400 fill-orange-500" />
                Bonificación de Racha ({streak} consecutivas):
              </span>
              <span className="font-mono font-bold text-orange-400">+5 XP</span>
            </div>
          )}

          <div className="flex items-center justify-between text-sm pt-2 border-t border-slate-800">
            <span className="text-slate-300 font-semibold">Total Ganado en esta Audiencia:</span>
            <span className="font-mono font-black text-lg text-amber-400">+{xpEarned} XP</span>
          </div>

          {/* Current Rank in Career */}
          <div className="mt-3 pt-3 border-t border-slate-800/80 flex items-center justify-between">
            <div className="flex items-center gap-2">
              <div 
                className="w-3 h-3 rounded-full" 
                style={{ backgroundColor: currentRank.color }} 
              />
              <span className="text-xs text-slate-300">Rango de Carrera:</span>
            </div>
            <span className="text-xs font-bold font-judicial text-amber-300">
              {currentRank.title}
            </span>
          </div>
        </div>

        {/* Milestone Certificate Banner */}
        {isMilestone && (
          <div className="mb-6 p-4 rounded-2xl bg-gradient-to-r from-amber-950/90 via-amber-900/80 to-slate-900 border-2 border-amber-400 text-left flex items-center justify-between shadow-lg shadow-amber-950/70">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-amber-500 text-slate-950 flex items-center justify-center font-bold shrink-0">
                <Award className="w-6 h-6 text-slate-950" />
              </div>
              <div>
                <h4 className="text-xs font-bold uppercase tracking-wider text-amber-300 font-judicial">
                  ¡Hito Judicial Nivel {levelPassed}!
                </h4>
                <p className="text-xs text-slate-200">
                  Se ha desbloqueado tu Certificado Oficial del Poder Judicial en PDF.
                </p>
              </div>
            </div>
            <button
              onClick={() => {
                sounds.playScroll();
                onViewCertificate();
              }}
              id="btn-ver-certificado-milestone"
              className="px-3 py-1.5 rounded-lg bg-amber-400 hover:bg-amber-300 text-slate-950 text-xs font-bold flex items-center gap-1 shadow cursor-pointer whitespace-nowrap"
            >
              <Scroll className="w-3.5 h-3.5" />
              <span>Ver PDF</span>
            </button>
          </div>
        )}

        {/* Action Buttons */}
        <div className="flex flex-col sm:flex-row gap-3">
          <button
            onClick={() => {
              sounds.playClick();
              onGoToNextLevel();
            }}
            id="btn-continuar-siguiente-nivel"
            className="flex-1 py-3.5 px-6 rounded-2xl bg-gradient-to-r from-amber-500 via-amber-400 to-amber-600 hover:brightness-110 text-slate-950 font-black text-base tracking-wide shadow-xl shadow-amber-950/80 active:scale-[0.98] transition-all flex items-center justify-center gap-2 cursor-pointer"
          >
            <span>Siguiente Nivel ({levelPassed + 1})</span>
            <ChevronRight className="w-5 h-5" />
          </button>
          
          <button
            onClick={() => {
              sounds.playClick();
              onClose();
            }}
            className="py-3 px-5 rounded-2xl bg-slate-800 hover:bg-slate-700 text-slate-300 font-semibold text-sm transition-colors cursor-pointer"
          >
            Volver al Mapa
          </button>
        </div>
      </div>
    </div>
  );
};
