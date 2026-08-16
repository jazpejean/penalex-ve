import React, { useState, useEffect } from 'react';
import { UserProfile } from '../types';
import { sounds } from '../services/soundEffects';
import { Scroll, X, Sparkles, Clock, ShieldCheck, RefreshCw } from 'lucide-react';

interface ApelacionesModalProps {
  isOpen: boolean;
  onClose: () => void;
  profile: UserProfile;
  onRestoreAppeals: () => void;
}

export const ApelacionesModal: React.FC<ApelacionesModalProps> = ({
  isOpen,
  onClose,
  profile,
  onRestoreAppeals
}) => {
  const [timeLeft, setTimeLeft] = useState<string>('');

  useEffect(() => {
    if (!isOpen) return;

    const interval = setInterval(() => {
      if (profile.apelaciones >= 5) {
        setTimeLeft('¡Tus 5 apelaciones están completas!');
        return;
      }

      const lastTime = new Date(profile.ultima_regeneracion).getTime();
      const now = Date.now();
      const diffMs = now - lastTime;
      const intervalMs = 30 * 60 * 1000;
      const remainingMs = intervalMs - (diffMs % intervalMs);

      if (remainingMs <= 0) {
        setTimeLeft('00:00');
      } else {
        const mins = Math.floor(remainingMs / (1000 * 60));
        const secs = Math.floor((remainingMs % (1000 * 60)) / 1000);
        setTimeLeft(`${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`);
      }
    }, 1000);

    return () => clearInterval(interval);
  }, [isOpen, profile.apelaciones, profile.ultima_regeneracion]);

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm animate-fade-in">
      <div 
        id="modal-apelaciones"
        className="w-full max-w-lg bg-gradient-to-b from-[#131b2e] via-[#0f172a] to-[#0a0f1d] border-2 border-amber-600/60 rounded-2xl shadow-2xl p-6 relative overflow-hidden"
      >
        {/* Decorative Golden Top Light */}
        <div className="absolute -top-24 left-1/2 -translate-x-1/2 w-64 h-32 bg-amber-500/20 rounded-full blur-3xl pointer-events-none" />

        {/* Close Button */}
        <button
          onClick={() => { onClose(); sounds.playClick(); }}
          id="btn-close-apelaciones"
          className="absolute top-4 right-4 p-1.5 rounded-lg bg-slate-800 text-slate-400 hover:text-slate-100 hover:bg-slate-700 transition-colors"
        >
          <X className="w-5 h-5" />
        </button>

        {/* Header */}
        <div className="text-center mb-6">
          <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-amber-950/80 border border-amber-500/40 mb-3 shadow-lg shadow-amber-950/60">
            <Scroll className="w-9 h-9 text-amber-400 fill-amber-500/30 animate-pulse" />
          </div>
          <h2 className="font-judicial text-2xl sm:text-3xl font-bold text-amber-300">
            Apelaciones Judiciales
          </h2>
          <p className="text-sm text-slate-300 mt-1 max-w-sm mx-auto">
            En el proceso penal venezolano, el recurso de apelación te permite subsanar un fallo adverso. Representan tus vidas para litigar.
          </p>
        </div>

        {/* Pergaminos Indicator Visuals */}
        <div className="bg-[#0b101c] border border-amber-900/50 rounded-xl p-5 mb-6 text-center shadow-inner">
          <div className="text-xs uppercase tracking-wider font-semibold text-slate-400 mb-3">
            Estado de tus Recursos de Apelación
          </div>
          
          <div className="flex items-center justify-center gap-3 sm:gap-4 my-2">
            {[1, 2, 3, 4, 5].map((num) => {
              const hasScroll = num <= profile.apelaciones;
              return (
                <div key={num} className="flex flex-col items-center gap-1">
                  <div className={`w-12 h-14 sm:w-14 sm:h-16 rounded-xl flex items-center justify-center border transition-all ${
                    hasScroll
                      ? 'bg-gradient-to-b from-amber-900/40 via-amber-950/60 to-slate-950 border-amber-500/80 shadow-[0_0_15px_rgba(245,158,11,0.35)] scale-105'
                      : 'bg-slate-900/80 border-slate-800 opacity-40'
                  }`}>
                    <Scroll className={`w-6 h-6 sm:w-8 sm:h-8 ${
                      hasScroll ? 'text-amber-400 fill-amber-500/40' : 'text-slate-600'
                    }`} />
                  </div>
                  <span className={`text-[10px] font-mono ${hasScroll ? 'text-amber-400 font-bold' : 'text-slate-600'}`}>
                    #{num}
                  </span>
                </div>
              );
            })}
          </div>

          <div className="mt-4 pt-3 border-t border-slate-800 flex items-center justify-center gap-2 text-sm text-slate-300">
            <Clock className="w-4 h-4 text-amber-400" />
            <span>
              {profile.apelaciones >= 5
                ? '¡Capacidad máxima de apelaciones disponible!'
                : `Próximo pergamino en: ${timeLeft}`}
            </span>
          </div>
        </div>

        {/* Info Rules Box */}
        <div className="space-y-2.5 text-xs text-slate-300 mb-6 bg-slate-900/60 rounded-xl p-3.5 border border-slate-800">
          <div className="flex items-start gap-2">
            <ShieldCheck className="w-4 h-4 text-amber-400 shrink-0 mt-0.5" />
            <span>Al errar una respuesta en un nivel, consumes <strong>1 apelación</strong> (pergamino judicial).</span>
          </div>
          <div className="flex items-start gap-2">
            <Clock className="w-4 h-4 text-amber-400 shrink-0 mt-0.5" />
            <span>Se regenera <strong>1 apelación automáticamente cada 30 minutos</strong> hasta llegar a 5.</span>
          </div>
          <div className="flex items-start gap-2">
            <Sparkles className="w-4 h-4 text-amber-400 shrink-0 mt-0.5" />
            <span>Mantener rachas superiores a 3 otorga <strong>+5 XP de bonificación</strong> por veredicto acertado.</span>
          </div>
        </div>

        {/* Actions */}
        <div className="flex flex-col sm:flex-row gap-3">
          <button
            onClick={() => {
              onRestoreAppeals();
              sounds.playCorrect();
              onClose();
            }}
            id="btn-restitucion-plena"
            className="flex-1 py-3 px-4 rounded-xl bg-gradient-to-r from-amber-600 via-amber-500 to-amber-700 text-slate-950 font-bold text-sm tracking-wide shadow-lg shadow-amber-950/60 hover:brightness-110 active:scale-[0.98] transition-all flex items-center justify-center gap-2 cursor-pointer"
          >
            <RefreshCw className="w-4 h-4 text-slate-950" />
            <span>Restitución Constitucional (+5 Vidas)</span>
          </button>
          
          <button
            onClick={() => { onClose(); sounds.playClick(); }}
            className="py-3 px-5 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-200 font-semibold text-sm transition-colors cursor-pointer"
          >
            Entendido
          </button>
        </div>
      </div>
    </div>
  );
};
