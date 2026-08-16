import React, { useEffect, useState } from 'react';
import { sounds } from '../services/soundEffects';
import { Flame, Sparkles, Clock, AlertCircle } from 'lucide-react';

interface PergaminoAppealsProps {
  apelaciones: number; // 0 to 5
  ultimaRegeneracion?: string;
  onOpenAppealsModal: () => void;
  showTimer?: boolean;
}

export const PergaminoAppeals: React.FC<PergaminoAppealsProps> = ({
  apelaciones,
  ultimaRegeneracion,
  onOpenAppealsModal,
  showTimer = true
}) => {
  const [prevAppeals, setPrevAppeals] = useState<number>(apelaciones);
  const [burningIdx, setBurningIdx] = useState<number | null>(null);
  const [regeneratingIdx, setRegeneratingIdx] = useState<number | null>(null);
  const [timeRemaining, setTimeRemaining] = useState<string>('--:--');

  useEffect(() => {
    if (apelaciones < prevAppeals) {
      // Lost an appeal - trigger burning flame animation
      const lostIndex = apelaciones; // the index that was lost
      setBurningIdx(lostIndex);
      sounds.playFireBurn();
      const timer = setTimeout(() => {
        setBurningIdx(null);
      }, 1400);
      return () => clearTimeout(timer);
    } else if (apelaciones > prevAppeals) {
      // Gained an appeal - trigger gold radiance animation
      const restoredIndex = apelaciones - 1;
      setRegeneratingIdx(restoredIndex);
      sounds.playScroll();
      const timer = setTimeout(() => {
        setRegeneratingIdx(null);
      }, 1000);
      return () => clearTimeout(timer);
    }
    setPrevAppeals(apelaciones);
  }, [apelaciones, prevAppeals]);

  // Countdown timer calculation (30 minutes cycle)
  useEffect(() => {
    if (apelaciones >= 5) {
      setTimeRemaining('Lleno');
      return;
    }

    const interval = setInterval(() => {
      if (!ultimaRegeneracion) {
        setTimeRemaining('29:59');
        return;
      }
      const last = new Date(ultimaRegeneracion).getTime();
      const now = Date.now();
      const diffMs = now - last;
      const cycleMs = 30 * 60 * 1000;
      const elapsedInCycle = diffMs % cycleMs;
      const remainingMs = Math.max(0, cycleMs - elapsedInCycle);

      const mins = Math.floor(remainingMs / 60000);
      const secs = Math.floor((remainingMs % 60000) / 1000);
      setTimeRemaining(`${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`);
    }, 1000);

    return () => clearInterval(interval);
  }, [apelaciones, ultimaRegeneracion]);

  return (
    <div
      onClick={() => { sounds.playClick(); onOpenAppealsModal(); }}
      className="group relative flex items-center gap-2 bg-[#0c1220]/90 backdrop-blur-md px-3.5 py-1.5 rounded-2xl border-2 border-amber-600/40 hover:border-amber-400 shadow-xl shadow-amber-950/30 cursor-pointer transition-all hover:scale-[1.02]"
      title="Apelaciones Judiciales disponibles (vidas)"
    >
      {/* 5 Animated Pergaminos */}
      <div className="flex items-center gap-1.5">
        {[0, 1, 2, 3, 4].map((index) => {
          const isActive = index < apelaciones;
          const isBurning = burningIdx === index;
          const isRegen = regeneratingIdx === index;

          return (
            <div
              key={index}
              className={`relative w-6 h-8 sm:w-7 sm:h-9 flex items-center justify-center transition-all duration-300 ${
                isBurning ? 'anim-fire-burn scale-110 z-20' : isRegen ? 'anim-scroll-unfurl scale-110 z-20' : ''
              }`}
            >
              {/* Flame Effect Overlay */}
              {isBurning && (
                <div className="absolute -top-3 inset-x-0 flex justify-center text-amber-500 animate-bounce pointer-events-none">
                  <Flame className="w-5 h-5 text-red-500 fill-amber-400 animate-pulse" />
                </div>
              )}

              {/* Radiant Glow on Restore */}
              {isRegen && (
                <div className="absolute -inset-1 bg-amber-400/50 rounded-lg blur-sm animate-ping pointer-events-none" />
              )}

              {/* Realistic SVG Pergamino Rolled Scroll */}
              <svg
                viewBox="0 0 32 40"
                className={`w-full h-full drop-shadow-md transition-all ${
                  isActive
                    ? 'filter drop-shadow-[0_2px_6px_rgba(245,158,11,0.5)]'
                    : 'opacity-25 grayscale brightness-50'
                }`}
              >
                {/* Scroll Cylinder Body */}
                <rect
                  x="4"
                  y="4"
                  width="24"
                  height="32"
                  rx="4"
                  fill={isActive ? '#FCF7EA' : '#475569'}
                  stroke={isActive ? '#D97706' : '#334155'}
                  strokeWidth="1.5"
                />

                {/* Aged Parchment Inner Lines */}
                <line x1="8" y1="12" x2="24" y2="12" stroke={isActive ? '#D4B982' : '#64748B'} strokeWidth="1" strokeLinecap="round" />
                <line x1="8" y1="16" x2="20" y2="16" stroke={isActive ? '#D4B982' : '#64748B'} strokeWidth="1" strokeLinecap="round" />
                <line x1="8" y1="20" x2="22" y2="20" stroke={isActive ? '#D4B982' : '#64748B'} strokeWidth="1" strokeLinecap="round" />
                <line x1="8" y1="24" x2="16" y2="24" stroke={isActive ? '#D4B982' : '#64748B'} strokeWidth="1" strokeLinecap="round" />

                {/* Golden Ribbon Band in Center */}
                <rect
                  x="3"
                  y="18"
                  width="26"
                  height="4"
                  rx="1"
                  fill={isActive ? '#F59E0B' : '#64748B'}
                  stroke={isActive ? '#B45309' : '#334155'}
                  strokeWidth="0.8"
                />

                {/* Wax Seal Stamp */}
                <circle
                  cx="16"
                  cy="20"
                  r="3.5"
                  fill={isActive ? '#DC2626' : '#475569'}
                  stroke={isActive ? '#991B1B' : '#1E293B'}
                  strokeWidth="0.8"
                />
                <circle cx="16" cy="20" r="1.5" fill={isActive ? '#FCA5A5' : '#94A3B8'} />

                {/* Scroll Rolled Edges Top & Bottom */}
                <ellipse cx="16" cy="4" rx="12" ry="2.5" fill={isActive ? '#F5E6C8' : '#334155'} stroke={isActive ? '#D97706' : '#1E293B'} strokeWidth="1" />
                <ellipse cx="16" cy="36" rx="12" ry="2.5" fill={isActive ? '#EBD5A8' : '#1E293B'} stroke={isActive ? '#B45309' : '#0F172A'} strokeWidth="1" />
              </svg>
            </div>
          );
        })}
      </div>

      {/* Numerical Counter & Timer */}
      <div className="flex flex-col text-left pl-1 border-l border-amber-800/40">
        <div className="flex items-center gap-1">
          <span className="font-judicial text-xs sm:text-sm font-black text-amber-300">
            {apelaciones}/5
          </span>
        </div>
        {showTimer && apelaciones < 5 && (
          <div className="flex items-center gap-0.5 text-[9px] font-mono text-amber-400/90 font-semibold">
            <Clock className="w-2.5 h-2.5 animate-spin" style={{ animationDuration: '6s' }} />
            <span>{timeRemaining}</span>
          </div>
        )}
      </div>
    </div>
  );
};
