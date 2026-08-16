import React, { useState, useEffect } from 'react';
import { Pregunta, UserProfile } from '../types';
import { getRankByLevel } from '../data/judicialRanks';
import { sounds } from '../services/soundEffects';
import { supabaseService } from '../services/supabaseService';
import { 
  Gavel, 
  Scroll, 
  Flame, 
  Sparkles, 
  CheckCircle2, 
  XCircle, 
  BookOpen, 
  ArrowRight, 
  RotateCcw, 
  ShieldAlert, 
  Scale, 
  HelpCircle,
  Clock,
  Zap,
  BookMarked,
  Hourglass,
  Info,
  Star,
  ShieldCheck,
  Trophy
} from 'lucide-react';

interface QuizArenaProps {
  currentLevel: number;
  profile: UserProfile;
  onAnswerResult: (correct: boolean, xpEarned: number, starsEarned: number) => void;
  onOpenAppealsModal: () => void;
  onBackToMap: () => void;
}

export const QuizArena: React.FC<QuizArenaProps> = ({
  currentLevel,
  profile,
  onAnswerResult,
  onOpenAppealsModal,
  onBackToMap
}) => {
  const [question, setQuestion] = useState<Pregunta | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [selectedOption, setSelectedOption] = useState<number | null>(null);
  const [isAnswerSubmitted, setIsAnswerSubmitted] = useState<boolean>(false);
  const [isCorrect, setIsCorrect] = useState<boolean>(false);
  const [showFundamentacion, setShowFundamentacion] = useState<boolean>(false);

  // Hourglass timer (45 seconds)
  const [timeLeft, setTimeLeft] = useState<number>(45);
  const [timerActive, setTimerActive] = useState<boolean>(true);

  // Boosters state
  const [eliminatedOptions, setEliminatedOptions] = useState<number[]>([]);
  const [used5050, setUsed5050] = useState<boolean>(false);
  const [usedTSJClue, setUsedTSJClue] = useState<boolean>(false);
  const [showClueBox, setShowClueBox] = useState<boolean>(false);
  const [hasShieldProtection, setHasShieldProtection] = useState<boolean>(false);
  const [starsEarned, setStarsEarned] = useState<number>(0);
  const [showVictoryCard, setShowVictoryCard] = useState<boolean>(false);

  // Load question for current level and launch suspense background music
  useEffect(() => {
    let isMounted = true;
    setLoading(true);
    setSelectedOption(null);
    setIsAnswerSubmitted(false);
    setShowFundamentacion(false);
    setTimeLeft(45);
    setTimerActive(true);
    setEliminatedOptions([]);
    setUsed5050(false);
    setUsedTSJClue(false);
    setShowClueBox(false);
    setHasShieldProtection(false);
    setShowVictoryCard(false);

    // Start suspense soundtrack
    sounds.startQuizMusic(0);

    supabaseService.getQuestion(currentLevel).then((q) => {
      if (isMounted) {
        setQuestion(q);
        setLoading(false);
      }
    });

    return () => {
      isMounted = false;
      sounds.stopMusic(0.2);
    };
  }, [currentLevel]);

  // Countdown loop with dynamic tempo urgency scaling
  useEffect(() => {
    if (!timerActive || isAnswerSubmitted || loading) return;

    const interval = setInterval(() => {
      setTimeLeft((prev) => {
        if (prev <= 1) {
          clearInterval(interval);
          handleTimeExpired();
          return 0;
        }
        
        const urgency = (45 - prev) / 45;
        if (prev === 30 || prev === 20 || prev === 10) {
          sounds.updateQuizMusicUrgency(urgency);
        }

        if (prev <= 10) {
          sounds.playTicking(true);
        } else if (prev % 5 === 0) {
          sounds.playTicking(false);
        }

        return prev - 1;
      });
    }, 1000);

    return () => clearInterval(interval);
  }, [timerActive, isAnswerSubmitted, loading]);

  const handleTimeExpired = () => {
    if (isAnswerSubmitted || !question) return;
    sounds.stopMusic(0.1);
    sounds.playCrack();
    sounds.playWrong();
    sounds.voiceTimeOut();
    setIsAnswerSubmitted(true);
    setIsCorrect(false);
    setShowFundamentacion(true);
    onAnswerResult(false, 0, 0);
  };

  const handleSelectOption = (idx: number) => {
    if (isAnswerSubmitted || eliminatedOptions.includes(idx)) return;
    sounds.playScroll();
    setSelectedOption(idx);
  };

  const handleSubmitVerdict = () => {
    if (selectedOption === null || !question || isAnswerSubmitted) return;

    if (profile.apelaciones <= 0 && !hasShieldProtection) {
      sounds.playWrong();
      onOpenAppealsModal();
      return;
    }

    setTimerActive(false);
    sounds.stopMusic(0.2);
    sounds.playGavelStrike();

    const correct = selectedOption === question.respuesta_correcta;
    setIsAnswerSubmitted(true);
    setIsCorrect(correct);
    setShowFundamentacion(true);

    if (correct) {
      sounds.playCorrect();
      sounds.voiceCorrect();
      
      // Calculate 1 to 3 Stars
      let stars = 1;
      if (timeLeft >= 20) stars = 2;
      if (timeLeft >= 20 && profile.racha_actual >= 1) stars = 3;
      setStarsEarned(stars);

      // Trigger sequential Candy Crush star popping sound
      setTimeout(() => sounds.playStarPop(1), 300);
      if (stars >= 2) setTimeout(() => sounds.playStarPop(2), 650);
      if (stars >= 3) setTimeout(() => sounds.playStarPop(3), 1000);

      const baseXP = 10;
      const streakBonus = profile.racha_actual >= 2 ? 5 : 0;
      const speedBonus = timeLeft > 25 ? 5 : 0;
      const totalEarned = baseXP + streakBonus + speedBonus;
      
      setShowVictoryCard(true);
      onAnswerResult(true, totalEarned, stars);
    } else {
      if (!hasShieldProtection) {
        sounds.playCrack();
        sounds.playWrong();
        sounds.playFireBurn();
        sounds.voiceWrong();
      } else {
        sounds.playShieldSuccess();
      }
      onAnswerResult(false, 0, 0);
    }
  };

  // Booster: 50/50 discard 2 wrong options
  const handleUse5050 = () => {
    if (used5050 || !question || isAnswerSubmitted) return;
    sounds.playOrbPop();
    setUsed5050(true);

    const wrongIndexes = [0, 1, 2, 3].filter(i => i !== question.respuesta_correcta);
    const shuffled = wrongIndexes.sort(() => Math.random() - 0.5).slice(0, 2);
    setEliminatedOptions(shuffled);
  };

  // Booster: TSJ Clue
  const handleUseTSJClue = () => {
    if (usedTSJClue || !question || isAnswerSubmitted) return;
    sounds.playScroll();
    setUsedTSJClue(true);
    setShowClueBox(true);
  };

  // Booster: Add 20s
  const handleAddExtraTime = () => {
    if (isAnswerSubmitted) return;
    sounds.playCorrect();
    setTimeLeft(t => t + 20);
  };

  // Booster: Shield
  const handleUseShield = () => {
    if (hasShieldProtection || isAnswerSubmitted) return;
    sounds.playLevelUp();
    setHasShieldProtection(true);
  };

  const handleRetryLevel = () => {
    if (profile.apelaciones <= 0 && !hasShieldProtection) {
      onOpenAppealsModal();
      return;
    }
    setSelectedOption(null);
    setIsAnswerSubmitted(false);
    setShowFundamentacion(false);
    setShowVictoryCard(false);
    setTimeLeft(45);
    setTimerActive(true);
    setEliminatedOptions([]);
    sounds.playClick();
    sounds.startQuizMusic(0);
  };

  const handleLeaveArena = () => {
    sounds.stopMusic(0.2);
    sounds.playClick();
    sounds.startLobbyMusic();
    onBackToMap();
  };

  const currentRank = getRankByLevel(currentLevel);
  const optionLetters = ['A', 'B', 'C', 'D'];

  if (loading || !question) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[60vh] text-center px-4">
        <div className="w-16 h-16 rounded-2xl bg-amber-950/60 border border-amber-500/40 flex items-center justify-center mb-4 animate-spin">
          <Scale className="w-8 h-8 text-amber-400" />
        </div>
        <h3 className="text-xl font-bold text-amber-200">
          Abriendo Expediente Nivel {currentLevel}...
        </h3>
        <p className="text-xs text-slate-400 mt-1">
          Cargando jurisprudencia penal y normativa aplicable
        </p>
      </div>
    );
  }

  return (
    <div className="max-w-3xl mx-auto px-3 sm:px-6 pb-28">
      
      {/* Top Level & Hourglass Bar */}
      <div className="flex items-center justify-between gap-2 mb-4 bg-gradient-to-r from-[#0c1424]/95 to-[#070b14]/95 border border-amber-600/40 rounded-3xl px-4 py-3 shadow-xl backdrop-blur-md">
        <div className="flex items-center gap-3">
          <div className="w-11 h-11 rounded-2xl bg-gradient-to-tr from-amber-600 via-yellow-400 to-amber-500 text-slate-950 flex items-center justify-center font-black text-lg shadow-lg shadow-amber-950/80 border border-yellow-200">
            {currentLevel}
          </div>
          <div>
            <span className="text-[10px] font-mono uppercase tracking-wider text-amber-400 block font-semibold">
              {question.categoria || currentRank.sala}
            </span>
            <h3 className="text-xs sm:text-sm font-extrabold text-slate-100">
              Audiencia de Imputación Penal
            </h3>
          </div>
        </div>

        {/* Animated Hourglass Timer */}
        <div className="flex items-center gap-3">
          <div 
            title="Tiempo restante para fundamentar el veredicto"
            className={`flex items-center gap-1.5 px-3.5 py-1.5 rounded-2xl border font-mono font-black text-xs sm:text-sm transition-all ${
              timeLeft <= 10
                ? 'bg-rose-950/80 border-rose-500 text-rose-300 animate-pulse shadow-lg shadow-rose-950/50'
                : 'bg-slate-900/90 border-amber-700/50 text-amber-300'
            }`}
          >
            <Hourglass className={`w-4 h-4 ${timeLeft <= 10 ? 'text-rose-400 animate-spin' : 'text-amber-400'}`} />
            <span>{timeLeft}s</span>
          </div>

          <button
            onClick={handleLeaveArena}
            className="text-xs text-slate-400 hover:text-amber-300 font-bold px-3 py-1.5 rounded-xl bg-slate-800/90 hover:bg-slate-700 transition-colors border border-slate-700 cursor-pointer"
          >
            Salir al Mapa
          </button>
        </div>
      </div>

      {/* 🍬 CANDY CRUSH BOOSTERS TRAY (Potenciadores In-Game) */}
      {!isAnswerSubmitted && (
        <div className="mb-4 bg-slate-950/80 border border-amber-500/30 rounded-2xl p-2.5 flex items-center justify-between gap-2 shadow-lg backdrop-blur-md">
          <span className="text-[11px] font-extrabold text-amber-300 flex items-center gap-1.5 pl-1 hidden sm:flex">
            <Zap className="w-3.5 h-3.5 text-yellow-400" />
            Potenciadores:
          </span>

          <div className="flex items-center gap-2 w-full sm:w-auto justify-around sm:justify-end">
            {/* 50/50 */}
            <button
              disabled={used5050}
              onClick={handleUse5050}
              className={`flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-bold border transition-all cursor-pointer ${
                used5050
                  ? 'opacity-30 bg-slate-900 border-slate-800 text-slate-600 cursor-not-allowed'
                  : 'bg-slate-900 hover:bg-slate-800 border-amber-500/50 text-amber-300 shadow-md hover:scale-105 active:scale-95'
              }`}
              title="Descarta 2 opciones erradas"
            >
              <Gavel className="w-3.5 h-3.5 text-amber-400" />
              <span>50/50</span>
            </button>

            {/* Extra Time */}
            <button
              onClick={handleAddExtraTime}
              className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-bold border bg-slate-900 hover:bg-slate-800 border-blue-500/50 text-blue-300 shadow-md hover:scale-105 active:scale-95 transition-all cursor-pointer"
              title="Añadir +20 segundos"
            >
              <Clock className="w-3.5 h-3.5 text-blue-400" />
              <span>+20s</span>
            </button>

            {/* Jurisprudencia Clue */}
            <button
              disabled={usedTSJClue}
              onClick={handleUseTSJClue}
              className={`flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-bold border transition-all cursor-pointer ${
                usedTSJClue
                  ? 'opacity-30 bg-slate-900 border-slate-800 text-slate-600 cursor-not-allowed'
                  : 'bg-slate-900 hover:bg-slate-800 border-purple-500/50 text-purple-300 shadow-md hover:scale-105 active:scale-95'
              }`}
              title="Pista doctrinal TSJ"
            >
              <Scroll className="w-3.5 h-3.5 text-purple-400" />
              <span>Doctrina</span>
            </button>

            {/* Shield Protection */}
            <button
              disabled={hasShieldProtection}
              onClick={handleUseShield}
              className={`flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-bold border transition-all cursor-pointer ${
                hasShieldProtection
                  ? 'bg-emerald-950/60 border-emerald-500 text-emerald-300'
                  : 'bg-slate-900 hover:bg-slate-800 border-emerald-500/50 text-emerald-300 shadow-md hover:scale-105 active:scale-95'
              }`}
              title="Escudo de Apelación: Protege tu pergamino en error"
            >
              <ShieldCheck className="w-3.5 h-3.5 text-emerald-400" />
              <span>{hasShieldProtection ? 'Escudo Activo' : 'Escudo'}</span>
            </button>
          </div>
        </div>
      )}

      {/* TSJ Clue Drawer */}
      {showClueBox && (
        <div className="mb-4 p-3.5 rounded-2xl bg-purple-950/50 border border-purple-500/60 text-purple-200 text-xs flex items-start gap-2.5 shadow-lg animate-fadeIn">
          <BookOpen className="w-4 h-4 text-purple-400 shrink-0 mt-0.5" />
          <div>
            <span className="font-bold block text-purple-300">Pista Doctrinal & Jurisprudencial:</span>
            <span>Presta especial atención a la tipicidad, antijuridicidad y culpabilidad aplicables al {question.articulo_referencia || 'Código Penal'}.</span>
          </div>
        </div>
      )}

      {/* Out of Appeals Alert */}
      {profile.apelaciones <= 0 && !isAnswerSubmitted && !hasShieldProtection && (
        <div className="mb-4 p-4 rounded-2xl bg-gradient-to-r from-rose-950/90 to-slate-900 border-2 border-rose-500/80 flex items-center justify-between gap-3 shadow-xl">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-rose-500 text-slate-950 flex items-center justify-center font-bold shrink-0">
              <ShieldAlert className="w-6 h-6" />
            </div>
            <div>
              <h4 className="text-xs font-bold uppercase tracking-wider text-rose-300">
                ¡Sin Apelaciones Disponibles!
              </h4>
              <p className="text-xs text-slate-300">
                Has agotado tus 5 pergaminos. Usa un Escudo o solicita restitución.
              </p>
            </div>
          </div>
          <button
            onClick={() => { sounds.playScroll(); onOpenAppealsModal(); }}
            className="px-3.5 py-1.5 rounded-xl bg-rose-500 hover:bg-rose-400 text-slate-950 text-xs font-bold shrink-0 shadow cursor-pointer"
          >
            Restaurar
          </button>
        </div>
      )}

      {/* Case Brief Scroll Card */}
      <div 
        id="card-case-brief"
        className="relative bg-gradient-to-b from-[#18233c] via-[#101726] to-[#0a0f1d] border-2 border-amber-500/70 rounded-3xl p-6 sm:p-8 shadow-2xl mb-6 overflow-hidden"
      >
        <div className="flex items-center justify-between mb-4 border-b border-amber-800/40 pb-3">
          <div className="flex items-center gap-2">
            <Scroll className="w-5 h-5 text-amber-400 fill-amber-500/20" />
            <span className="text-xs sm:text-sm font-black tracking-wider text-amber-300 uppercase">
              Hechos y Planteamiento del Caso
            </span>
          </div>
          <span className="text-[11px] font-mono text-slate-300 bg-black/50 px-2.5 py-0.5 rounded-lg border border-amber-500/30">
            {question.articulo_referencia || 'Código Penal Venezolano'}
          </span>
        </div>

        <p className="text-base sm:text-lg text-slate-100 font-medium leading-relaxed">
          {question.pregunta}
        </p>
      </div>

      {/* 4 Interactive Legal Option Columns */}
      <div className="space-y-3.5 mb-6" id="options-container">
        {question.opciones.map((opcion, idx) => {
          const isSelected = selectedOption === idx;
          const isRightOption = idx === question.respuesta_correcta;
          const isEliminated = eliminatedOptions.includes(idx);
          
          let cardStyle = "bg-[#0d1424] border-slate-700/80 text-slate-200 hover:border-amber-400/80 hover:bg-[#121c32]";

          if (isEliminated) {
            cardStyle = "opacity-20 line-through bg-black/40 border-slate-900 text-slate-600 pointer-events-none";
          } else if (isAnswerSubmitted) {
            if (isRightOption) {
              cardStyle = "bg-gradient-to-r from-emerald-950/90 to-[#0c1f18] border-emerald-500 text-emerald-100 shadow-[0_0_25px_rgba(16,185,129,0.4)] ring-2 ring-emerald-400";
            } else if (isSelected && !isRightOption) {
              cardStyle = "bg-gradient-to-r from-rose-950/90 to-[#1f0c0c] border-rose-500 text-rose-100 shadow-[0_0_25px_rgba(244,63,94,0.4)] ring-2 ring-rose-400";
            } else {
              cardStyle = "bg-slate-950/60 border-slate-800 text-slate-500 opacity-40";
            }
          } else if (isSelected) {
            cardStyle = "bg-gradient-to-r from-[#1f2d4d] to-[#162137] border-amber-400 text-amber-200 shadow-[0_0_20px_rgba(245,158,11,0.3)] ring-2 ring-amber-400/60 scale-[1.01]";
          }

          return (
            <button
              key={idx}
              disabled={isAnswerSubmitted || isEliminated}
              onClick={() => handleSelectOption(idx)}
              id={`option-card-${idx}`}
              className={`w-full p-4 sm:p-5 rounded-2xl border-2 text-left transition-all duration-200 flex items-start gap-3.5 relative cursor-pointer select-none group ${cardStyle}`}
            >
              <div className={`w-9 h-9 rounded-xl flex items-center justify-center font-bold text-sm shrink-0 border transition-all ${
                isAnswerSubmitted && isRightOption
                  ? 'bg-emerald-500 text-slate-950 border-emerald-300'
                  : isAnswerSubmitted && isSelected && !isRightOption
                  ? 'bg-rose-500 text-slate-950 border-rose-300'
                  : isSelected
                  ? 'bg-amber-400 text-slate-950 border-amber-300 shadow'
                  : 'bg-slate-800/80 text-slate-300 border-slate-700 group-hover:border-amber-500/50'
              }`}>
                {optionLetters[idx]}
              </div>

              <span className="text-sm sm:text-base font-medium flex-1 pt-1 leading-snug">
                {opcion}
              </span>

              {isAnswerSubmitted && (
                <div className="shrink-0 mt-1">
                  {isRightOption ? (
                    <CheckCircle2 className="w-6 h-6 text-emerald-400 fill-emerald-500/20" />
                  ) : isSelected ? (
                    <XCircle className="w-6 h-6 text-rose-400 fill-rose-500/20" />
                  ) : null}
                </div>
              )}
            </button>
          );
        })}
      </div>

      {/* 🎉 CANDY CRUSH STYLE VICTORY CARD */}
      {showVictoryCard && (
        <div className="bg-gradient-to-b from-[#1b2a47] via-[#0f1b30] to-[#070c18] border-3 border-amber-400 rounded-3xl p-6 mb-6 shadow-2xl text-center animate-bounce-subtle">
          
          {/* 3 Stars Trophy Animation */}
          <div className="flex items-center justify-center gap-2 mb-3">
            <Star className={`w-8 h-8 transition-transform duration-500 ${starsEarned >= 1 ? 'fill-yellow-400 text-yellow-500 scale-110 drop-shadow-[0_0_12px_#facc15]' : 'fill-slate-800 text-slate-700'}`} />
            <Star className={`w-12 h-12 -translate-y-2 transition-transform duration-500 ${starsEarned >= 2 ? 'fill-yellow-400 text-yellow-500 scale-120 drop-shadow-[0_0_16px_#facc15]' : 'fill-slate-800 text-slate-700'}`} />
            <Star className={`w-8 h-8 transition-transform duration-500 ${starsEarned >= 3 ? 'fill-yellow-400 text-yellow-500 scale-110 drop-shadow-[0_0_12px_#facc15]' : 'fill-slate-800 text-slate-700'}`} />
          </div>

          <h3 className="text-2xl sm:text-3xl font-black text-transparent bg-clip-text bg-gradient-to-r from-amber-200 via-yellow-300 to-amber-500">
            ¡VEREDICTO MAGISTRAL!
          </h3>
          <p className="text-xs text-amber-200/90 font-semibold mb-4">
            Has superado el Caso Penal Nivel {currentLevel} con {starsEarned} Estrellas.
          </p>

          <div className="grid grid-cols-3 gap-2 bg-slate-950/80 p-3 rounded-2xl border border-amber-500/30 text-xs font-bold text-slate-200 max-w-sm mx-auto mb-4">
            <div>
              <span className="text-slate-400 block text-[10px]">XP GANADO</span>
              <span className="text-amber-300 font-mono text-sm">+20 XP</span>
            </div>
            <div>
              <span className="text-slate-400 block text-[10px]">TIEMPO</span>
              <span className="text-blue-300 font-mono text-sm">{timeLeft}s</span>
            </div>
            <div>
              <span className="text-slate-400 block text-[10px]">RACHA</span>
              <span className="text-rose-400 font-mono text-sm">{profile.racha_actual + 1} 🔥</span>
            </div>
          </div>
        </div>
      )}

      {/* Legal Fundamentation Drawer */}
      {showFundamentacion && (
        <div 
          id="drawer-fundamentacion"
          className={`p-6 rounded-3xl border-2 mb-6 shadow-2xl animate-fadeIn ${
            isCorrect
              ? 'bg-gradient-to-b from-emerald-950/80 via-[#0a1813] to-[#07110e] border-emerald-500/80'
              : 'bg-gradient-to-b from-rose-950/80 via-[#190b0e] to-[#100709] border-rose-500/80'
          }`}
        >
          <div className="flex items-center gap-2.5 mb-3">
            <BookOpen className={`w-5 h-5 ${isCorrect ? 'text-emerald-400' : 'text-rose-400'}`} />
            <h4 className="text-base sm:text-lg font-black text-slate-100">
              {isCorrect ? '¡Veredicto Acertado! • Fundamentación Jurídica' : 'Apelación Denegada • Fundamento Legal'}
            </h4>
          </div>

          <p className="text-sm text-slate-200 leading-relaxed bg-black/50 p-4 rounded-2xl border border-white/10 mb-3">
            {question.fundamentacion}
          </p>

          <div className="flex items-center justify-between text-xs text-slate-400">
            <span className="flex items-center gap-1.5 font-mono">
              <Scale className="w-4 h-4 text-amber-400" />
              {question.articulo_referencia || 'Código Penal de Venezuela'}
            </span>
            {!isCorrect ? (
              <span className="text-rose-400 font-bold font-mono">
                {hasShieldProtection ? '🛡️ Escudo protegió tu pergamino' : '-1 Apelación (Pergamino quemado)'}
              </span>
            ) : (
              <span className="text-amber-300 font-bold font-mono">
                +10 XP (+ Escalón superado)
              </span>
            )}
          </div>
        </div>
      )}

      {/* Main Action Bar */}
      <div className="flex items-center gap-3">
        {!isAnswerSubmitted ? (
          <button
            disabled={selectedOption === null}
            onClick={handleSubmitVerdict}
            id="btn-dictar-sentencia"
            className="w-full py-4 px-6 rounded-2xl bg-gradient-to-r from-amber-500 via-yellow-400 to-amber-600 text-slate-950 font-black text-base uppercase tracking-wider shadow-xl shadow-amber-950/80 hover:brightness-110 active:scale-[0.98] transition-all flex items-center justify-center gap-2 cursor-pointer disabled:opacity-40 disabled:cursor-not-allowed"
          >
            <Gavel className="w-5 h-5 text-slate-950" />
            <span>Dictar Sentencia (Verificar Veredicto)</span>
          </button>
        ) : (
          <div className="w-full flex flex-col sm:flex-row gap-3">
            {!isCorrect && (
              <button
                onClick={handleRetryLevel}
                id="btn-reintentar-audiencia"
                className="flex-1 py-3.5 px-6 rounded-2xl bg-slate-800 hover:bg-slate-700 text-slate-200 font-bold text-sm flex items-center justify-center gap-2 transition-colors cursor-pointer border border-slate-700"
              >
                <RotateCcw className="w-4 h-4" />
                <span>Reintentar Caso</span>
              </button>
            )}
            
            <button
              onClick={handleLeaveArena}
              id="btn-continuar-mapa"
              className="flex-1 py-4 px-6 rounded-2xl bg-gradient-to-r from-amber-500 to-yellow-400 hover:brightness-110 text-slate-950 font-black text-base uppercase tracking-wide flex items-center justify-center gap-2 shadow-xl shadow-amber-950/80 cursor-pointer"
            >
              <span>{isCorrect ? '¡Siguiente Nivel en el Mapa!' : 'Volver al Mapa'}</span>
              <ArrowRight className="w-5 h-5" />
            </button>
          </div>
        )}
      </div>

    </div>
  );
};
