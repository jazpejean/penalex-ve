import React, { useState, useEffect } from 'react';
import { sounds, AudioMode } from '../services/soundEffects';
import { 
  Volume2, 
  VolumeX, 
  Volume1, 
  Music, 
  Play, 
  Pause, 
  Gavel, 
  Sparkles, 
  Radio, 
  Sliders,
  Award,
  Flame,
  Check
} from 'lucide-react';

export const AudioBar: React.FC = () => {
  const [audioState, setAudioState] = useState<{
    mode: AudioMode;
    isPlaying: boolean;
    musicType: string | null;
    isUnlocked: boolean;
  }>({
    mode: sounds.getAudioMode(),
    isPlaying: sounds.getCurrentMusicType() !== null && sounds.getAudioMode() === 'all',
    musicType: sounds.getCurrentMusicType(),
    isUnlocked: sounds.isUnlocked()
  });

  const [expanded, setExpanded] = useState<boolean>(false);
  const [volume, setVolume] = useState<number>(80);
  const [showPromptBanner, setShowPromptBanner] = useState<boolean>(!sounds.isUnlocked());

  useEffect(() => {
    const unsubscribe = sounds.subscribe((newState) => {
      setAudioState(newState);
      if (newState.isUnlocked) {
        setShowPromptBanner(false);
      }
    });
    return unsubscribe;
  }, []);

  const handleToggleMusic = () => {
    sounds.playClick();
    sounds.unlockAudio();
    if (audioState.mode === 'muted') {
      sounds.setAudioMode('all');
    } else if (audioState.mode === 'sfx_only') {
      sounds.setAudioMode('all');
    } else {
      sounds.setAudioMode('sfx_only');
    }
  };

  const handleVolumeChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const val = parseInt(e.target.value, 10);
    setVolume(val);
    sounds.setVolume(val / 100);
  };

  const handleUnlockAndPlay = () => {
    sounds.unlockAudio();
    sounds.setAudioMode('all');
    sounds.startLobbyMusic();
    sounds.playGavelStrike();
    setShowPromptBanner(false);
  };

  return (
    <div className="w-full">
      {/* 🎵 Banner de bienvenida / activador de audio si el navegador tiene el audio en pausa */}
      {showPromptBanner && (
        <div className="mb-4 bg-gradient-to-r from-amber-600 via-amber-500 to-yellow-500 text-slate-950 p-3 rounded-2xl shadow-xl flex items-center justify-between gap-3 border-2 border-yellow-300 animate-pulse">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-slate-950/20 flex items-center justify-center flex-shrink-0">
              <Music className="w-6 h-6 text-slate-950 animate-bounce" />
            </div>
            <div>
              <p className="font-bold text-sm sm:text-base leading-tight">
                🎶 ¡Activa la Banda Sonora Orquestal & Efectos de PENALEX!
              </p>
              <p className="text-xs text-slate-900/80 font-medium hidden sm:block">
                Música solemne de tribunal, mazos judiciales realistas y voces del narrador.
              </p>
            </div>
          </div>
          <button
            onClick={handleUnlockAndPlay}
            className="px-4 py-2 bg-slate-950 text-amber-300 hover:bg-slate-900 font-bold text-xs sm:text-sm rounded-xl shadow-lg border border-amber-400/50 flex items-center gap-2 cursor-pointer transition-transform hover:scale-105 active:scale-95 flex-shrink-0"
          >
            <Play className="w-4 h-4 fill-amber-300" />
            <span>ACTIVAR MÚSICA</span>
          </button>
        </div>
      )}

      {/* 🎛️ Barra de Control de Audio Cinematográfico */}
      <div className="bg-[#0b101c]/90 border border-amber-500/40 rounded-2xl p-2.5 sm:p-3 shadow-xl backdrop-blur-md flex flex-wrap items-center justify-between gap-3 mb-6">
        
        {/* Left: Estado de la música & Ecualizador animado */}
        <div className="flex items-center gap-3">
          <button
            onClick={handleToggleMusic}
            title={audioState.mode === 'all' ? 'Pausar música' : 'Reproducir música'}
            className={`w-10 h-10 rounded-xl flex items-center justify-center transition-all cursor-pointer shadow-md ${
              audioState.mode === 'all'
                ? 'bg-gradient-to-tr from-amber-600 to-yellow-400 text-slate-950 shadow-amber-500/30'
                : 'bg-slate-800 text-slate-400 hover:bg-slate-700'
            }`}
          >
            {audioState.mode === 'all' ? (
              <Music className="w-5 h-5 animate-spin-slow" />
            ) : (
              <Play className="w-5 h-5 fill-current ml-0.5" />
            )}
          </button>

          <div>
            <div className="flex items-center gap-2">
              <span className="text-xs font-bold text-amber-300 font-mono tracking-wider">
                BANDA SONORA ORQUESTAL
              </span>
              {audioState.mode === 'all' && (
                <span className="inline-flex items-center gap-1 px-1.5 py-0.5 rounded-full text-[10px] font-bold bg-amber-500/20 text-amber-300 border border-amber-500/40 animate-pulse">
                  <span className="w-1.5 h-1.5 rounded-full bg-emerald-400" />
                  {audioState.musicType === 'quiz' ? 'Audiencia TSJ' : 'Lobby Solemne'}
                </span>
              )}
            </div>

            {/* Simulated Animated Equalizer Bars */}
            <div className="flex items-end gap-1 h-3.5 mt-1">
              {[0.4, 0.8, 0.6, 1.0, 0.5, 0.9, 0.3, 0.7].map((h, i) => (
                <span
                  key={i}
                  className={`w-1 rounded-full transition-all duration-300 ${
                    audioState.mode === 'all'
                      ? 'bg-gradient-to-t from-amber-500 to-yellow-300'
                      : 'bg-slate-700'
                  }`}
                  style={{
                    height: audioState.mode === 'all' ? `${Math.max(20, Math.sin(Date.now() / 200 + i) * 50 + 50)}%` : '20%',
                    animationDuration: `${0.6 + i * 0.15}s`
                  }}
                />
              ))}
              <span className="text-[10px] text-slate-400 ml-1.5 font-mono">
                {audioState.mode === 'all' ? 'Sonando en Vivo' : audioState.mode === 'sfx_only' ? 'Solo Efectos (SFX)' : 'Silenciado'}
              </span>
            </div>
          </div>
        </div>

        {/* Right: Quick Action Controls & Sound Test */}
        <div className="flex items-center gap-2">
          {/* Mode Switch Button */}
          <button
            onClick={() => sounds.toggleNextMode()}
            className={`px-3 py-1.5 rounded-xl text-xs font-medium border flex items-center gap-1.5 transition-all cursor-pointer ${
              audioState.mode === 'all'
                ? 'bg-amber-500/15 border-amber-500/40 text-amber-300 hover:bg-amber-500/25'
                : audioState.mode === 'sfx_only'
                ? 'bg-blue-500/15 border-blue-500/40 text-blue-300 hover:bg-blue-500/25'
                : 'bg-red-500/15 border-red-500/40 text-red-300 hover:bg-red-500/25'
            }`}
          >
            {audioState.mode === 'all' && <Volume2 className="w-4 h-4 text-amber-400" />}
            {audioState.mode === 'sfx_only' && <Volume1 className="w-4 h-4 text-blue-400" />}
            {audioState.mode === 'muted' && <VolumeX className="w-4 h-4 text-red-400" />}
            <span className="capitalize">
              {audioState.mode === 'all' ? 'Música + SFX' : audioState.mode === 'sfx_only' ? 'Solo SFX' : 'Silencio'}
            </span>
          </button>

          {/* Test Sound Effects Trigger */}
          <button
            onClick={() => setExpanded(!expanded)}
            className="p-2 rounded-xl bg-slate-800/80 hover:bg-slate-700 text-slate-300 border border-slate-700 transition-colors cursor-pointer"
            title="Ajustes y Efectos de Sonido"
          >
            <Sliders className="w-4 h-4 text-amber-400" />
          </button>
        </div>

      </div>

      {/* Expanded Sound FX Playground Tray */}
      {expanded && (
        <div className="bg-[#0e1628] border border-amber-500/30 rounded-2xl p-4 mb-6 shadow-2xl space-y-3 animate-fadeIn">
          <div className="flex items-center justify-between text-xs font-bold text-amber-300 pb-2 border-b border-slate-800">
            <span className="flex items-center gap-1.5">
              <Sparkles className="w-4 h-4 text-amber-400" />
              Consola de Efectos & Pruebas de Audio
            </span>
            <div className="flex items-center gap-2">
              <span className="text-slate-400 text-[11px]">Volumen:</span>
              <input
                type="range"
                min="0"
                max="100"
                value={volume}
                onChange={handleVolumeChange}
                className="w-24 accent-amber-500 cursor-pointer"
              />
              <span className="font-mono text-slate-300 text-[11px] w-7">{volume}%</span>
            </div>
          </div>

          <div className="grid grid-cols-2 sm:grid-cols-4 gap-2 pt-1">
            <button
              onClick={() => { sounds.unlockAudio(); sounds.playGavelStrike(); }}
              className="px-3 py-2 rounded-xl bg-slate-900 hover:bg-slate-800 border border-amber-500/20 text-xs text-amber-200 flex items-center justify-center gap-1.5 cursor-pointer active:scale-95"
            >
              <Gavel className="w-3.5 h-3.5 text-amber-400" />
              <span>Golpe de Mazo</span>
            </button>

            <button
              onClick={() => { sounds.unlockAudio(); sounds.playCorrect(); }}
              className="px-3 py-2 rounded-xl bg-slate-900 hover:bg-slate-800 border border-emerald-500/20 text-xs text-emerald-200 flex items-center justify-center gap-1.5 cursor-pointer active:scale-95"
            >
              <Sparkles className="w-3.5 h-3.5 text-emerald-400" />
              <span>Campana Victoria</span>
            </button>

            <button
              onClick={() => { sounds.unlockAudio(); sounds.playStarPop(3); }}
              className="px-3 py-2 rounded-xl bg-slate-900 hover:bg-slate-800 border border-yellow-500/20 text-xs text-yellow-200 flex items-center justify-center gap-1.5 cursor-pointer active:scale-95"
            >
              <Award className="w-3.5 h-3.5 text-yellow-400" />
              <span>Pop 3 Estrellas</span>
            </button>

            <button
              onClick={() => { sounds.unlockAudio(); sounds.voiceCorrect(); }}
              className="px-3 py-2 rounded-xl bg-slate-900 hover:bg-slate-800 border border-purple-500/20 text-xs text-purple-200 flex items-center justify-center gap-1.5 cursor-pointer active:scale-95"
            >
              <Radio className="w-3.5 h-3.5 text-purple-400" />
              <span>Narrador Judicial</span>
            </button>
          </div>
        </div>
      )}
    </div>
  );
};
