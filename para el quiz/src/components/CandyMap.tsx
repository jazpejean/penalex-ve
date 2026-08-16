import React, { useState, useEffect, useRef } from 'react';
import { UserProfile, BoostersInventory } from '../types';
import { getRankByLevel, MILESTONE_LEVELS } from '../data/judicialRanks';
import { sounds } from '../services/soundEffects';
import { 
  Sparkles, 
  Lock, 
  Check, 
  Award, 
  Play, 
  ChevronUp, 
  ChevronDown, 
  Search, 
  Crown, 
  Gavel, 
  ShieldCheck, 
  Scroll,
  Navigation,
  Flame,
  Building2,
  Gift,
  Star,
  Clock,
  X,
  Trophy,
  Scale,
  Zap,
  Volume2
} from 'lucide-react';

import celestialPathArt from '../assets/images/celestial_judicial_path_1786768242811.jpg';
import gavelSunburstImg from '../assets/images/golden_gavel_sunburst_1786768259678.jpg';
import blueFlameLockedImg from '../assets/images/blue_flame_locked_medal_1786768269315.jpg';
import goldenScalesCoinImg from '../assets/images/golden_scales_coin_1786768281789.jpg';

interface CandyMapProps {
  profile: UserProfile;
  onSelectLevel: (level: number) => void;
  onOpenCertificate: () => void;
  onClaimChest?: (level: number, rewards: { xp: number; appeals: number; booster?: keyof BoostersInventory }) => void;
}

interface TierChapter {
  id: number;
  name: string;
  subtitle: string;
  startLevel: number;
  endLevel: number;
}

const CHAPTER_SIZE = 10;
const TOTAL_LEVELS = 3000;
const TOTAL_CHAPTERS = Math.ceil(TOTAL_LEVELS / CHAPTER_SIZE);

export const CandyMap: React.FC<CandyMapProps> = ({
  profile,
  onSelectLevel,
  onOpenCertificate,
  onClaimChest
}) => {
  const currentChapter = Math.floor((profile.nivel_actual - 1) / CHAPTER_SIZE);
  const [selectedChapter, setSelectedChapter] = useState<number>(currentChapter);
  const [selectedLevelModal, setSelectedLevelModal] = useState<number | null>(null);
  const [searchInput, setSearchInput] = useState<string>('');
  const [claimedChestModal, setClaimedChestModal] = useState<{ level: number; xp: number; appeals: number; boosterName: string } | null>(null);

  const startLvl = selectedChapter * CHAPTER_SIZE + 1;
  const endLvl = Math.min(TOTAL_LEVELS, startLvl + CHAPTER_SIZE - 1);

  const currentRank = getRankByLevel(profile.nivel_actual);

  // Define the 10 node positions on the celestial illustrated map to match the user's reference image perfectly
  // The reference image has:
  // - Pillars and Crown at the bottom
  // - Node 1: Crown Platform (bottom center)
  // - Node 2: Island 1 (bottom left)
  // - Node 3: Golden Bridge transition (mid-bottom left)
  // - Node 4: Main stairs lower bend (center)
  // - Node 5: The Grand Sunburst Gavel Medallion (mid right on golden stairs)
  // - Node 6: Island 2 (mid left with blue flames)
  // - Node 7: Higher stairs bend (mid center)
  // - Node 8: Island 3 (upper right with blue flames)
  // - Node 9: High island (upper left)
  // - Node 10: Temple of Justice Dome entrance (top celestial summit)
  const NODE_COORDINATES = [
    { x: 50, y: 92, label: "Atrio de la Corona", type: "crown" },
    { x: 20, y: 78, label: "Isla de la Balanza", type: "coin" },
    { x: 38, y: 73, label: "Puente Dorado", type: "bridge" },
    { x: 49, y: 64, label: "Escalones Centrales", type: "stair" },
    { x: 78, y: 55, label: "Sagrario del Mazo", type: "sunburst" },
    { x: 28, y: 48, label: "Isla de las Llamas", type: "flame" },
    { x: 51, y: 38, label: "Ascenso Celestial", type: "stair" },
    { x: 74, y: 31, label: "Altar Superior", type: "flame" },
    { x: 34, y: 28, label: "Terraza de la Ley", type: "coin" },
    { x: 50, y: 15, label: "Cúpula Suprema TSJ", type: "temple" },
  ];

  const handleNodeClick = (levelNumber: number) => {
    sounds.playOrbPop();
    setSelectedLevelModal(levelNumber);
  };

  const handleStartGame = (levelNumber: number) => {
    sounds.playGavelStrike();
    setSelectedLevelModal(null);
    onSelectLevel(levelNumber);
  };

  const handleSearchSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const lvl = parseInt(searchInput, 10);
    if (!isNaN(lvl) && lvl >= 1 && lvl <= TOTAL_LEVELS) {
      const targetChapter = Math.floor((lvl - 1) / CHAPTER_SIZE);
      setSelectedChapter(targetChapter);
      setSelectedLevelModal(lvl);
      setSearchInput('');
      sounds.playScroll();
    }
  };

  const handleClaimChest = (chestLvl: number) => {
    if (profile.nivel_actual < chestLvl) {
      sounds.playWrong();
      return;
    }
    const alreadyClaimed = (profile.cofres_reclamados || []).includes(chestLvl);
    if (alreadyClaimed) {
      sounds.playScroll();
      return;
    }

    sounds.playChestOpen();
    sounds.playLevelUp();

    const xpReward = 100 + chestLvl * 2;
    const appealReward = 1;
    const boosterOptions: (keyof BoostersInventory)[] = ['mazo5050', 'relojExtra', 'doctrinaTSJ', 'escudo'];
    const randomBooster = boosterOptions[Math.floor(Math.random() * boosterOptions.length)];
    const boosterNames: Record<keyof BoostersInventory, string> = {
      mazo5050: '1x Mazo 50/50',
      relojExtra: '1x Reloj Extra (+20s)',
      doctrinaTSJ: '1x Jurisprudencia TSJ',
      escudo: '1x Escudo de Apelación'
    };

    if (onClaimChest) {
      onClaimChest(chestLvl, { xp: xpReward, appeals: appealReward, booster: randomBooster });
    }

    setClaimedChestModal({
      level: chestLvl,
      xp: xpReward,
      appeals: appealReward,
      boosterName: boosterNames[randomBooster]
    });
  };

  const getStarsForLevel = (lvl: number): number => {
    if (profile.estrellas_por_nivel && profile.estrellas_por_nivel[lvl]) {
      return profile.estrellas_por_nivel[lvl];
    }
    if (lvl < profile.nivel_actual) return 3;
    return 0;
  };

  return (
    <div className="w-full max-w-4xl mx-auto flex flex-col items-center pb-24 px-2 sm:px-4 select-none">
      
      {/* 👑 HEADER BAR: EL SENDERO CELESTIAL DE LA JUSTICIA */}
      <div className="w-full mb-4 bg-gradient-to-r from-[#091530]/95 via-[#10234a]/95 to-[#091530]/95 border-2 border-amber-400/60 rounded-3xl p-4 sm:p-5 shadow-[0_10px_35px_rgba(0,0,0,0.8)] backdrop-blur-md">
        <div className="flex flex-col sm:flex-row items-center justify-between gap-4">
          
          {/* Title & Realm Info */}
          <div className="flex items-center gap-3.5 text-center sm:text-left">
            <div className="w-14 h-14 rounded-2xl bg-gradient-to-tr from-amber-600 via-yellow-400 to-amber-300 p-0.5 shadow-lg shadow-amber-500/40 shrink-0">
              <div className="w-full h-full bg-[#070e1c] rounded-[14px] flex items-center justify-center border border-amber-300/40">
                <Crown className="w-8 h-8 text-amber-300 animate-pulse" />
              </div>
            </div>

            <div>
              <div className="flex items-center justify-center sm:justify-start gap-2">
                <span className="px-2.5 py-0.5 rounded-full text-[10px] font-black uppercase tracking-wider bg-amber-500/20 text-amber-300 border border-amber-400/40 shadow-sm flex items-center gap-1">
                  <Sparkles className="w-3 h-3 text-yellow-400" />
                  CAPÍTULO {selectedChapter + 1} • NIVELES {startLvl} - {endLvl}
                </span>
              </div>
              <h1 className="text-lg sm:text-xl font-black text-transparent bg-clip-text bg-gradient-to-r from-amber-100 via-yellow-200 to-amber-400">
                El Gran Sendero Celestial de la Justicia TSJ
              </h1>
              <p className="text-xs text-sky-200/90 font-medium">
                {currentRank.title} • {currentRank.sala}
              </p>
            </div>
          </div>

          {/* Quick Stats Pill */}
          <div className="flex items-center gap-2 sm:gap-4 bg-[#050b17]/90 px-3.5 py-2 rounded-2xl border border-amber-400/30">
            <div className="text-center px-1.5">
              <span className="text-[9px] uppercase font-bold text-slate-400 block">Nivel Actual</span>
              <span className="text-base sm:text-lg font-black text-amber-300 font-mono">#{profile.nivel_actual}</span>
            </div>
            <div className="w-px h-6 bg-amber-500/20" />
            <div className="text-center px-1.5">
              <span className="text-[9px] uppercase font-bold text-slate-400 block">Estrellas</span>
              <span className="text-base sm:text-lg font-black text-yellow-400 flex items-center gap-1">
                <Star className="w-3.5 h-3.5 fill-yellow-400 text-yellow-500" />
                {(Object.values(profile.estrellas_por_nivel || {}) as number[]).reduce((a: number, b: number) => a + b, 0) || (profile.nivel_actual - 1) * 3}
              </span>
            </div>
            <div className="w-px h-6 bg-amber-500/20" />
            <div className="text-center px-1.5">
              <span className="text-[9px] uppercase font-bold text-slate-400 block">Racha</span>
              <span className="text-base sm:text-lg font-black text-rose-400 flex items-center gap-0.5">
                <Flame className="w-3.5 h-3.5 fill-rose-500" />
                {profile.racha_actual}
              </span>
            </div>
          </div>

        </div>

        {/* Chapter Navigation & Search Controls */}
        <div className="mt-3 pt-3 border-t border-amber-500/20 flex flex-wrap items-center justify-between gap-2 text-xs">
          <div className="flex items-center gap-2">
            <button
              disabled={selectedChapter === 0}
              onClick={() => { sounds.playScroll(); setSelectedChapter(c => Math.max(0, c - 1)); }}
              className="px-3 py-1.5 rounded-xl bg-slate-900/90 hover:bg-slate-800 disabled:opacity-40 disabled:pointer-events-none text-sky-100 font-bold flex items-center gap-1 border border-amber-400/30 transition-all cursor-pointer active:scale-95 shadow"
            >
              <ChevronDown className="w-4 h-4 text-amber-300" />
              <span>Capítulo Anterior</span>
            </button>

            <button
              disabled={selectedChapter >= TOTAL_CHAPTERS - 1}
              onClick={() => { sounds.playScroll(); setSelectedChapter(c => Math.min(TOTAL_CHAPTERS - 1, c + 1)); }}
              className="px-3 py-1.5 rounded-xl bg-slate-900/90 hover:bg-slate-800 disabled:opacity-40 disabled:pointer-events-none text-sky-100 font-bold flex items-center gap-1 border border-amber-400/30 transition-all cursor-pointer active:scale-95 shadow"
            >
              <span>Subir hacia la Cúpula</span>
              <ChevronUp className="w-4 h-4 text-amber-300" />
            </button>
          </div>

          <div className="flex items-center gap-2">
            <button
              onClick={() => {
                sounds.playAscent();
                setSelectedChapter(currentChapter);
              }}
              className="px-3 py-1.5 rounded-xl bg-gradient-to-r from-amber-400 via-yellow-300 to-amber-500 text-slate-950 font-black flex items-center gap-1.5 transition-transform active:scale-95 cursor-pointer shadow-md hover:brightness-110"
            >
              <Navigation className="w-3.5 h-3.5 fill-slate-950" />
              <span>Mi Nivel (#{profile.nivel_actual})</span>
            </button>

            <form onSubmit={handleSearchSubmit} className="flex items-center gap-1">
              <input
                type="number"
                min="1"
                max={TOTAL_LEVELS}
                placeholder="1..3000"
                value={searchInput}
                onChange={(e) => setSearchInput(e.target.value)}
                className="w-20 px-2.5 py-1.5 bg-slate-950/90 border border-amber-500/40 rounded-xl text-white placeholder-slate-400 text-xs font-mono focus:outline-none focus:border-amber-300 shadow-inner"
              />
              <button
                type="submit"
                className="p-1.5 bg-amber-500 hover:bg-amber-400 text-slate-950 rounded-xl transition-colors cursor-pointer shadow"
                title="Ir al nivel"
              >
                <Search className="w-3.5 h-3.5" />
              </button>
            </form>
          </div>
        </div>

      </div>

      {/* 🌟 THE CELESTIAL STAIRWAY GAME CANVAS (FAITHFUL RECREATION OF THE REFERENCE IMAGE) */}
      <div className="relative w-full max-w-[540px] aspect-[9/16] rounded-3xl overflow-hidden shadow-[0_20px_60px_rgba(0,0,0,0.95)] border-4 border-amber-400/80 bg-slate-950">
        
        {/* 1. Full-Resolution Celestial Background Artwork with Golden Stairs & Clouds */}
        <img
          src={celestialPathArt}
          alt="El Gran Sendero Celestial de la Justicia TSJ"
          referrerPolicy="no-referrer"
          className="absolute inset-0 w-full h-full object-cover object-center pointer-events-none"
        />

        {/* 2. Divine Golden Sunbeam Light Shimmer & Atmosphere */}
        <div className="absolute inset-0 bg-gradient-to-b from-amber-400/10 via-transparent to-[#040914]/40 pointer-events-none" />
        <div className="absolute top-4 left-1/2 -translate-x-1/2 w-72 h-40 bg-gradient-to-b from-amber-300/30 via-yellow-400/15 to-transparent blur-2xl rounded-full pointer-events-none animate-pulse" />

        {/* 3. Golden Temple of Justice Summit Banner at the top */}
        <div 
          onClick={() => setSelectedLevelModal(TOTAL_LEVELS)}
          className="absolute top-3 left-1/2 -translate-x-1/2 z-20 cursor-pointer group flex flex-col items-center"
        >
          <div className="px-3 py-1 rounded-full bg-gradient-to-r from-amber-500/90 via-yellow-400/90 to-amber-500/90 text-slate-950 font-black text-[10px] sm:text-[11px] uppercase tracking-wider shadow-[0_0_20px_#f59e0b] border border-white flex items-center gap-1 group-hover:scale-105 transition-transform">
            <Building2 className="w-3.5 h-3.5" />
            <span>Cúpula Magna del TSJ • Nivel {TOTAL_LEVELS}</span>
          </div>
        </div>

        {/* 4. Interactive Level Nodes Positioned Accurately Along the Celestial Stairs and Floating Islands */}
        {NODE_COORDINATES.map((nodeCoord, index) => {
          const levelNumber = startLvl + index;
          if (levelNumber > TOTAL_LEVELS) return null;

          const isCompleted = levelNumber < profile.nivel_actual;
          const isCurrent = levelNumber === profile.nivel_actual;
          const isLocked = levelNumber > profile.nivel_actual;
          const isMilestone = levelNumber % 10 === 0;
          const stars = getStarsForLevel(levelNumber);

          return (
            <div
              key={levelNumber}
              style={{
                left: `${nodeCoord.x}%`,
                top: `${nodeCoord.y}%`,
                transform: 'translate(-50%, -50%)'
              }}
              className="absolute z-20 flex flex-col items-center group cursor-pointer"
              onClick={() => handleNodeClick(levelNumber)}
            >
              
              {/* CURRENT ACTIVE LEVEL: "¡AUDIENCIA EN VIVO!" BANNER */}
              {isCurrent && (
                <div className="absolute -top-11 sm:-top-13 z-30 flex flex-col items-center animate-bounce pointer-events-none">
                  <div className="bg-gradient-to-r from-amber-400 via-yellow-300 to-amber-500 text-slate-950 font-black text-[9px] sm:text-[10px] px-2.5 py-0.5 rounded-full shadow-[0_0_20px_rgba(245,158,11,1)] border-2 border-white flex items-center gap-1 tracking-wider whitespace-nowrap">
                    <Gavel className="w-3 h-3 fill-slate-950" />
                    <span>¡AUDIENCIA ACTIVA!</span>
                  </div>
                  <div className="w-2.5 h-2.5 bg-amber-400 rotate-45 -mt-1 border-r border-b border-amber-600" />
                </div>
              )}

              {/* NODE BUTTON RENDERING (MATCHING USER REFERENCE ARTWORK) */}
              <div className="relative flex items-center justify-center transition-all duration-300 group-hover:scale-115 active:scale-95">
                
                {/* CASE A: CURRENT ACTIVE LEVEL (Radiant Sunburst Gavel Medallion with Ribbons) */}
                {isCurrent ? (
                  <div className="relative w-18 h-18 sm:w-22 sm:h-22 filter drop-shadow-[0_0_25px_rgba(245,158,11,0.9)] animate-pulse">
                    <img
                      src={gavelSunburstImg}
                      alt={`Nivel Activo ${levelNumber}`}
                      referrerPolicy="no-referrer"
                      className="w-full h-full object-contain"
                    />
                    {/* Level Number Overlay in the Center */}
                    <div className="absolute inset-0 flex items-center justify-center -translate-y-0.5">
                      <span className="font-black text-slate-950 text-base sm:text-lg font-mono drop-shadow-[0_1px_2px_rgba(255,255,255,0.9)]">
                        {levelNumber}
                      </span>
                    </div>
                  </div>
                ) : isCompleted ? (

                  /* CASE B: COMPLETED LEVEL (Golden Scales of Justice Coin) */
                  <div className="relative w-12 h-12 sm:w-14 sm:h-14 filter drop-shadow-[0_0_12px_rgba(234,179,8,0.8)]">
                    <img
                      src={goldenScalesCoinImg}
                      alt={`Nivel Completado ${levelNumber}`}
                      referrerPolicy="no-referrer"
                      className="w-full h-full object-contain group-hover:brightness-125"
                    />
                    <div className="absolute inset-0 flex items-center justify-center">
                      <span className="font-black text-amber-950 text-xs sm:text-sm font-mono drop-shadow-[0_1px_1px_rgba(255,255,255,0.6)]">
                        {levelNumber}
                      </span>
                    </div>
                  </div>

                ) : (

                  /* CASE C: LOCKED LEVEL (Dark Bronze Padlock Enveloped in Mystical Blue/Cyan Flames) */
                  <div className="relative w-12 h-12 sm:w-14 sm:h-14 filter drop-shadow-[0_0_15px_rgba(59,130,246,0.8)] opacity-90 group-hover:opacity-100">
                    <img
                      src={blueFlameLockedImg}
                      alt={`Nivel Bloqueado ${levelNumber}`}
                      referrerPolicy="no-referrer"
                      className="w-full h-full object-contain"
                    />
                    <div className="absolute inset-0 flex items-center justify-center pt-3">
                      <span className="font-black text-slate-300 text-[10px] sm:text-xs font-mono">
                        {levelNumber}
                      </span>
                    </div>
                  </div>

                )}

              </div>

              {/* ⭐⭐⭐ 3 STARS RIBBON UNDER COMPLETED MEDALLIONS */}
              {isCompleted && (
                <div className="relative -mt-2 z-20 flex items-center justify-center gap-0.5 bg-[#091224]/95 px-2 py-0.5 rounded-full border border-amber-400/60 shadow-lg scale-90">
                  <Star className={`w-2.5 h-2.5 ${stars >= 1 ? 'fill-yellow-400 text-yellow-500' : 'fill-slate-800 text-slate-700'}`} />
                  <Star className={`w-3 h-3 -translate-y-0.5 ${stars >= 2 ? 'fill-yellow-400 text-yellow-500' : 'fill-slate-800 text-slate-700'}`} />
                  <Star className={`w-2.5 h-2.5 ${stars >= 3 ? 'fill-yellow-400 text-yellow-500' : 'fill-slate-800 text-slate-700'}`} />
                </div>
              )}

              {/* Milestone Tag */}
              {isMilestone && (
                <span className="mt-0.5 px-1.5 py-0.2 rounded bg-purple-950/90 border border-purple-400/40 text-[8px] font-black uppercase text-purple-200 drop-shadow">
                  Hito #{levelNumber}
                </span>
              )}

            </div>
          );
        })}

        {/* 5. Entrance Glowing Golden Crown at the Foot of the Marble Stairs with Beam of Light */}
        <div 
          onClick={() => handleNodeClick(1)}
          className="absolute bottom-2 left-1/2 -translate-x-1/2 z-20 flex flex-col items-center cursor-pointer group"
          title="Atrio de la Corona (Nivel 1)"
        >
          <div className="w-10 h-10 sm:w-12 sm:h-12 rounded-xl bg-gradient-to-tr from-amber-500 via-yellow-300 to-amber-400 p-0.5 shadow-[0_0_25px_rgba(245,158,11,1)] group-hover:scale-110 transition-transform animate-pulse">
            <div className="w-full h-full bg-[#091224] rounded-[10px] flex items-center justify-center border border-amber-200">
              <Crown className="w-6 h-6 text-amber-300 fill-amber-400/40" />
            </div>
          </div>
          <span className="text-[9px] font-black text-amber-200 uppercase tracking-widest mt-0.5 drop-shadow-[0_1px_3px_#000]">
            Inicio Procesal
          </span>
        </div>

      </div>

      {/* 📜 MODAL: AUDIENCIA PRE-NIVEL (ENTRADA AL TRIBUNAL) */}
      {selectedLevelModal !== null && (
        <div className="fixed inset-0 z-50 bg-slate-950/85 backdrop-blur-md flex items-center justify-center p-4 animate-fadeIn">
          <div className="relative w-full max-w-md bg-gradient-to-b from-[#142344] via-[#0d172e] to-[#070c18] border-3 border-amber-400 rounded-3xl p-6 sm:p-7 shadow-[0_20px_70px_rgba(0,0,0,0.95)] overflow-hidden">
            
            {/* Ambient Lighting */}
            <div className="absolute -top-12 -right-12 w-36 h-36 bg-amber-400/20 rounded-full blur-2xl pointer-events-none" />

            {/* Close Button */}
            <button
              onClick={() => { sounds.playClick(); setSelectedLevelModal(null); }}
              className="absolute top-4 right-4 p-2 rounded-full bg-slate-800/80 hover:bg-slate-700 text-slate-400 hover:text-white transition-colors cursor-pointer border border-slate-700"
            >
              <X className="w-5 h-5" />
            </button>

            {/* Medallion Showcase Header */}
            <div className="flex flex-col items-center text-center mb-5">
              <div className="w-24 h-24 mb-2">
                <img 
                  src={selectedLevelModal <= profile.nivel_actual ? (selectedLevelModal === profile.nivel_actual ? gavelSunburstImg : goldenScalesCoinImg) : blueFlameLockedImg} 
                  alt="Medallón de Audiencia"
                  referrerPolicy="no-referrer"
                  className="w-full h-full object-contain drop-shadow-[0_0_25px_rgba(245,158,11,0.7)]"
                />
              </div>

              <span className="text-[11px] font-black uppercase text-amber-400 tracking-wider px-3 py-0.5 rounded-full bg-amber-950/60 border border-amber-500/40 mb-1">
                AUDIENCIA PENAL #{selectedLevelModal}
              </span>

              <h3 className="text-xl sm:text-2xl font-black text-transparent bg-clip-text bg-gradient-to-r from-amber-100 via-yellow-200 to-amber-400">
                {getRankByLevel(selectedLevelModal).title}
              </h3>
              
              <p className="text-xs text-sky-200/90 mt-1 max-w-xs">
                {getRankByLevel(selectedLevelModal).sala}
              </p>
            </div>

            {/* Star Objectives */}
            <div className="bg-[#070e1c]/90 border border-amber-400/30 rounded-2xl p-4 mb-4 space-y-3">
              <div className="flex items-center justify-between text-xs font-bold text-amber-300 border-b border-slate-800 pb-2">
                <span className="flex items-center gap-1.5">
                  <Trophy className="w-4 h-4 text-yellow-400" />
                  Meta de Estrellas del Juicio
                </span>
                <span className="text-slate-400 font-mono">+10 a +35 XP</span>
              </div>

              <div className="grid grid-cols-3 gap-2 text-center text-[11px]">
                <div className="bg-slate-900/90 p-2 rounded-xl border border-slate-800">
                  <div className="flex justify-center mb-1">
                    <Star className="w-4 h-4 fill-yellow-400 text-yellow-500" />
                  </div>
                  <span className="text-slate-300 block font-bold">1 Estrella</span>
                  <span className="text-[10px] text-slate-400">Veredicto Válido</span>
                </div>

                <div className="bg-slate-900/90 p-2 rounded-xl border border-slate-800">
                  <div className="flex justify-center mb-1 gap-0.5">
                    <Star className="w-3.5 h-3.5 fill-yellow-400 text-yellow-500" />
                    <Star className="w-3.5 h-3.5 fill-yellow-400 text-yellow-500" />
                  </div>
                  <span className="text-slate-300 block font-bold">2 Estrellas</span>
                  <span className="text-[10px] text-slate-400">&gt;20s Restantes</span>
                </div>

                <div className="bg-amber-950/30 p-2 rounded-xl border border-amber-500/40">
                  <div className="flex justify-center mb-1 gap-0.5">
                    <Star className="w-3 h-3 fill-yellow-400 text-yellow-500" />
                    <Star className="w-3.5 h-3.5 fill-yellow-400 text-yellow-500" />
                    <Star className="w-3 h-3 fill-yellow-400 text-yellow-500" />
                  </div>
                  <span className="text-amber-300 block font-bold">3 Estrellas</span>
                  <span className="text-[10px] text-amber-200/90">Racha Imparable</span>
                </div>
              </div>
            </div>

            {/* Boosters Equipped */}
            <div className="mb-5">
              <span className="text-[11px] font-bold text-slate-400 uppercase tracking-wider block mb-2">
                Tus Potenciadores Procesales:
              </span>
              <div className="grid grid-cols-4 gap-2">
                <div className="bg-[#070e1c] p-2 rounded-xl border border-slate-800 flex flex-col items-center text-center">
                  <Gavel className="w-4 h-4 text-amber-400 mb-1" />
                  <span className="text-[10px] font-bold text-slate-200">50/50</span>
                  <span className="text-[9px] text-amber-300 font-mono">x{profile.boosters?.mazo5050 ?? 3}</span>
                </div>
                <div className="bg-[#070e1c] p-2 rounded-xl border border-slate-800 flex flex-col items-center text-center">
                  <Clock className="w-4 h-4 text-blue-400 mb-1" />
                  <span className="text-[10px] font-bold text-slate-200">+20s</span>
                  <span className="text-[9px] text-blue-300 font-mono">x{profile.boosters?.relojExtra ?? 3}</span>
                </div>
                <div className="bg-[#070e1c] p-2 rounded-xl border border-slate-800 flex flex-col items-center text-center">
                  <Scroll className="w-4 h-4 text-purple-400 mb-1" />
                  <span className="text-[10px] font-bold text-slate-200">Doctrina</span>
                  <span className="text-[9px] text-purple-300 font-mono">x{profile.boosters?.doctrinaTSJ ?? 2}</span>
                </div>
                <div className="bg-[#070e1c] p-2 rounded-xl border border-slate-800 flex flex-col items-center text-center">
                  <ShieldCheck className="w-4 h-4 text-emerald-400 mb-1" />
                  <span className="text-[10px] font-bold text-slate-200">Escudo</span>
                  <span className="text-[9px] text-emerald-300 font-mono">x{profile.boosters?.escudo ?? 2}</span>
                </div>
              </div>
            </div>

            {/* Launch Action */}
            {selectedLevelModal <= profile.nivel_actual ? (
              <button
                onClick={() => handleStartGame(selectedLevelModal)}
                className="w-full py-4 rounded-2xl bg-gradient-to-r from-amber-500 via-yellow-400 to-amber-600 hover:from-amber-400 hover:to-amber-500 text-slate-950 font-black text-base uppercase tracking-wider shadow-[0_8px_25px_rgba(245,158,11,0.7)] flex items-center justify-center gap-2 cursor-pointer transition-transform hover:scale-102 active:scale-98"
              >
                <Play className="w-5 h-5 fill-slate-950" />
                <span>¡ENTRAR A LA SALA DE AUDIENCIA!</span>
              </button>
            ) : (
              <div className="text-center p-3 rounded-2xl bg-red-950/50 border border-red-500/40 text-red-300 text-xs font-bold">
                🔒 Nivel Bloqueado. Debes superar primero la Audiencia #{profile.nivel_actual}.
              </div>
            )}

          </div>
        </div>
      )}

      {/* 🎁 COFRE DE RECOMPENSAS RECLAMADO */}
      {claimedChestModal && (
        <div className="fixed inset-0 z-50 bg-slate-950/85 backdrop-blur-lg flex items-center justify-center p-4 animate-fadeIn">
          <div className="relative w-full max-w-sm bg-gradient-to-b from-[#1c2844] via-[#10192e] to-[#0a0f1d] border-3 border-yellow-400 rounded-3xl p-6 text-center shadow-[0_0_60px_rgba(250,204,21,0.7)]">
            
            <div className="w-20 h-20 mx-auto rounded-3xl bg-gradient-to-tr from-yellow-500 to-amber-300 flex items-center justify-center mb-4 shadow-xl shadow-yellow-500/50">
              <Gift className="w-10 h-10 text-slate-950 animate-pulse" />
            </div>

            <h3 className="text-2xl font-black text-yellow-300 mb-1">
              ¡COFRE CELESTIAL ABIERTO!
            </h3>
            <p className="text-xs text-sky-200 mb-5">
              Recompensas procesales otorgadas por tu ascenso en el Sendero Judicial #{claimedChestModal.level}:
            </p>

            <div className="bg-[#070e1c] p-4 rounded-2xl border border-yellow-500/40 space-y-2 mb-6 text-left text-xs font-bold text-amber-200">
              <div className="flex items-center justify-between">
                <span>⭐ Puntos de Experiencia:</span>
                <span className="text-yellow-400 font-mono">+{claimedChestModal.xp} XP</span>
              </div>
              <div className="flex items-center justify-between">
                <span>📜 Pergaminos de Apelación:</span>
                <span className="text-emerald-400 font-mono">+{claimedChestModal.appeals} Pergamino</span>
              </div>
              <div className="flex items-center justify-between">
                <span>⚡ Potenciador Procesal:</span>
                <span className="text-purple-300 font-mono">{claimedChestModal.boosterName}</span>
              </div>
            </div>

            <button
              onClick={() => setClaimedChestModal(null)}
              className="w-full py-3.5 bg-gradient-to-r from-yellow-400 to-amber-500 text-slate-950 font-black rounded-xl shadow-lg cursor-pointer transition-transform active:scale-95"
            >
              ¡RECLAMAR Y CONTINUAR EL ASCENSO!
            </button>

          </div>
        </div>
      )}

    </div>
  );
};
