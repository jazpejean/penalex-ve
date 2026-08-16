import React, { useState, useEffect } from 'react';
import { UserProfile } from '../types';
import { getRankByLevel } from '../data/judicialRanks';
import { sounds, AudioMode } from '../services/soundEffects';
import { PergaminoAppeals } from './PergaminoAppeals';
import { 
  Scroll, 
  Flame, 
  Sparkles, 
  Award, 
  Volume2, 
  Volume1,
  VolumeX, 
  Database, 
  Menu, 
  X,
  Gavel,
  ShieldAlert,
  Smartphone,
  BookOpen,
  Music
} from 'lucide-react';

interface NavbarProps {
  profile: UserProfile;
  activeTab: string;
  setActiveTab: (tab: string) => void;
  onOpenAppealsModal: () => void;
  isSupabaseConnected: boolean;
  onEditProfileName: () => void;
}

export const Navbar: React.FC<NavbarProps> = ({
  profile,
  activeTab,
  setActiveTab,
  onOpenAppealsModal,
  isSupabaseConnected,
  onEditProfileName
}) => {
  const [audioMode, setAudioMode] = useState<AudioMode>(sounds.getAudioMode());
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  useEffect(() => {
    const unsub = sounds.subscribe((mode) => setAudioMode(mode));
    return () => unsub();
  }, []);

  const currentRank = getRankByLevel(profile.nivel_actual);

  const handleToggleSoundMode = () => {
    const nextMode = sounds.toggleNextMode();
    setAudioMode(nextMode);
    if (nextMode !== 'muted') {
      sounds.playClick();
    }
  };

  const navItems = [
    { id: 'mapa', label: 'Sendero Celestial', icon: Sparkles },
    { id: 'quiz', label: 'Tribunal en Vivo', icon: Gavel },
    { id: 'certificados', label: 'Diplomas Oficiales', icon: Award },
    { id: 'ranking', label: 'Sala de Honor TSJ', icon: Sparkles },
    { id: 'logros', label: 'Escudos y Logros', icon: ShieldAlert },
    { id: 'banco', label: 'Banco de Casos', icon: BookOpen },
    { id: 'supabase', label: 'Supabase Backend', icon: Database },
    { id: 'flutter', label: 'Código Flutter', icon: Smartphone },
  ];

  return (
    <header className="sticky top-0 z-40 bg-[#070b13]/95 backdrop-blur-lg border-b border-amber-800/40 shadow-2xl">
      <div className="max-w-7xl mx-auto px-3 sm:px-6">
        <div className="flex items-center justify-between h-16 sm:h-20 gap-2">
          
          {/* Logo & Judicial Brand */}
          <div 
            onClick={() => { setActiveTab('mapa'); sounds.playClick(); }}
            className="flex items-center gap-2.5 cursor-pointer select-none group"
            id="brand-logo"
          >
            <div className="w-10 h-10 sm:w-12 sm:h-12 rounded-2xl bg-gradient-to-br from-amber-600 via-amber-400 to-yellow-600 p-0.5 shadow-lg shadow-amber-950/80 group-hover:scale-105 transition-transform">
              <div className="w-full h-full bg-[#0b101c] rounded-[14px] flex items-center justify-center border border-amber-500/40">
                <Gavel className="w-5 h-5 sm:w-6 sm:h-6 text-amber-400 group-hover:rotate-12 transition-transform" />
              </div>
            </div>
            <div>
              <div className="flex items-center gap-1.5">
                <span className="font-judicial font-black text-lg sm:text-2xl tracking-wider text-transparent bg-clip-text bg-gradient-to-r from-amber-100 via-amber-400 to-amber-600">
                  PENALEX VE
                </span>
                <span className="text-[10px] px-1.5 py-0.5 rounded-full bg-amber-950/90 text-amber-300 font-mono border border-amber-700/60 shadow-inner">
                  3000
                </span>
              </div>
              <p className="text-[10px] sm:text-[11px] text-slate-400 hidden sm:block tracking-wide">
                Tribunal Supremo de Justicia • Derecho Penal Venezolano
              </p>
            </div>
          </div>

          {/* Gamification Stats: Pergamino Appeals with Animations, Streak, XP, Rank */}
          <div className="flex items-center gap-2 sm:gap-3">
            
            {/* Realistic Pergamino Appeals with Fire / Flame Animation */}
            <PergaminoAppeals
              apelaciones={profile.apelaciones}
              ultimaRegeneracion={profile.ultima_regeneracion}
              onOpenAppealsModal={onOpenAppealsModal}
            />

            {/* Racha (Streak) Fire */}
            <div 
              id="badge-racha"
              title={`Racha actual: ${profile.racha_actual} correctas seguidas (${profile.racha_actual >= 3 ? '+5 XP bonus activo' : 'Consigue 3 para bonus'})`}
              className={`flex items-center gap-1 px-2.5 sm:px-3 py-1.5 rounded-2xl border text-xs sm:text-sm font-bold font-mono transition-all ${
                profile.racha_actual >= 3
                  ? 'bg-gradient-to-r from-orange-950/90 to-amber-950/90 border-orange-500 text-orange-300 shadow-lg shadow-orange-950/60 animate-pulse'
                  : 'bg-slate-900/80 border-slate-800 text-slate-400'
              }`}
            >
              <Flame className={`w-4 h-4 ${profile.racha_actual >= 3 ? 'text-orange-400 fill-orange-500' : 'text-slate-500'}`} />
              <span>{profile.racha_actual}</span>
            </div>

            {/* XP Points */}
            <div 
              id="badge-xp"
              title="Puntos de Experiencia Judicial acumulados"
              className="hidden md:flex items-center gap-1.5 px-3 py-1.5 rounded-2xl bg-amber-950/40 border border-amber-700/50 text-amber-300 font-mono text-xs sm:text-sm font-bold shadow-inner"
            >
              <Sparkles className="w-4 h-4 text-amber-400" />
              <span>{profile.puntos_totales.toLocaleString()} XP</span>
            </div>

            {/* User Rank Pill */}
            <button
              onClick={onEditProfileName}
              id="btn-user-profile"
              title={`Rango: ${currentRank.title} (Clic para cambiar nombre)`}
              className="hidden lg:flex items-center gap-2 px-3 py-1.5 rounded-2xl bg-gradient-to-b from-[#162138] to-[#0f172a] border border-slate-700/80 hover:border-amber-500/60 transition-all text-left shadow-md"
            >
              <div 
                className="w-2.5 h-2.5 rounded-full ring-2 ring-slate-800 shadow" 
                style={{ backgroundColor: currentRank.color }} 
              />
              <div className="leading-tight">
                <span className="text-xs font-semibold text-slate-200 block truncate max-w-[120px]">
                  {profile.nombre}
                </span>
                <span className="text-[10px] text-amber-400 font-judicial block truncate max-w-[140px]">
                  {currentRank.title}
                </span>
              </div>
            </button>

            {/* Supabase Status Indicator */}
            <button
              onClick={() => { setActiveTab('supabase'); sounds.playClick(); }}
              id="btn-supabase-status"
              title={isSupabaseConnected ? "Conectado a Supabase PostgreSQL" : "Modo Local Offline (Clic para vincular Supabase)"}
              className={`flex items-center gap-1 px-2.5 py-1.5 rounded-xl border text-[11px] font-mono transition-all cursor-pointer ${
                isSupabaseConnected
                  ? 'bg-emerald-950/70 border-emerald-500/60 text-emerald-300 shadow-md shadow-emerald-950/40'
                  : 'bg-amber-950/50 border-amber-700/50 text-amber-400'
              }`}
            >
              <span className={`w-2 h-2 rounded-full ${isSupabaseConnected ? 'bg-emerald-400 animate-ping' : 'bg-amber-400'}`} />
              <span className="hidden sm:inline">{isSupabaseConnected ? 'Supabase' : 'Offline'}</span>
            </button>

            {/* Tri-state Audio Mode Button (Música+SFX / Solo SFX / Silencio) */}
            <button
              onClick={handleToggleSoundMode}
              id="btn-sound-toggle"
              title={`Audio: ${
                audioMode === 'all' ? 'Música Orquestal + SFX + Voces' :
                audioMode === 'sfx_only' ? 'Solo Efectos SFX y Voces' : 'Silencio Total'
              } (Clic para alternar)`}
              className={`flex items-center gap-1.5 px-2.5 py-1.5 rounded-xl border transition-all cursor-pointer select-none text-xs font-mono font-bold ${
                audioMode === 'all'
                  ? 'bg-gradient-to-r from-amber-950/90 to-yellow-950/90 border-amber-500/80 text-amber-300 shadow-[0_0_15px_rgba(245,158,11,0.3)]'
                  : audioMode === 'sfx_only'
                  ? 'bg-slate-900 border-amber-800/60 text-amber-400'
                  : 'bg-slate-950 border-slate-800 text-slate-500'
              }`}
            >
              {audioMode === 'all' ? (
                <>
                  <Volume2 className="w-4 h-4 text-amber-400 animate-pulse" />
                  <span className="hidden sm:inline text-[10px]">BGM+SFX</span>
                </>
              ) : audioMode === 'sfx_only' ? (
                <>
                  <Volume1 className="w-4 h-4 text-amber-400" />
                  <span className="hidden sm:inline text-[10px]">Solo SFX</span>
                </>
              ) : (
                <>
                  <VolumeX className="w-4 h-4 text-rose-400" />
                  <span className="hidden sm:inline text-[10px]">Mudo</span>
                </>
              )}
            </button>

            {/* Mobile Menu Button */}
            <button
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
              className="p-2 rounded-xl bg-slate-900 border border-slate-700 text-slate-300 xl:hidden"
              id="btn-mobile-menu"
            >
              {mobileMenuOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
            </button>

          </div>
        </div>

        {/* Desktop Navigation Tabs */}
        <nav className="hidden xl:flex items-center gap-1.5 py-2 border-t border-slate-800/70 overflow-x-auto">
          {navItems.map((item) => {
            const Icon = item.icon;
            const isActive = activeTab === item.id;
            return (
              <button
                key={item.id}
                onClick={() => { setActiveTab(item.id); sounds.playClick(); }}
                id={`nav-${item.id}`}
                className={`flex items-center gap-1.5 px-3.5 py-1.5 rounded-xl text-xs font-semibold tracking-wide transition-all cursor-pointer select-none whitespace-nowrap ${
                  isActive
                    ? 'bg-gradient-to-r from-amber-500 via-amber-400 to-amber-600 text-slate-950 font-bold shadow-lg shadow-amber-950/60 scale-105'
                    : 'text-slate-300 hover:text-amber-300 hover:bg-slate-800/60'
                }`}
              >
                <Icon className={`w-3.5 h-3.5 ${isActive ? 'text-slate-950' : 'text-amber-400'}`} />
                <span>{item.label}</span>
              </button>
            );
          })}
        </nav>
      </div>

      {/* Mobile Navigation Dropdown */}
      {mobileMenuOpen && (
        <div className="xl:hidden bg-[#0a0f1d] border-b border-amber-900/40 px-4 py-3 space-y-1 shadow-2xl">
          {navItems.map((item) => {
            const Icon = item.icon;
            const isActive = activeTab === item.id;
            return (
              <button
                key={item.id}
                onClick={() => {
                  setActiveTab(item.id);
                  setMobileMenuOpen(false);
                  sounds.playClick();
                }}
                className={`w-full flex items-center gap-2.5 px-3 py-2 rounded-xl text-sm font-medium transition-colors ${
                  isActive
                    ? 'bg-amber-500 text-slate-950 font-bold'
                    : 'text-slate-300 hover:bg-slate-800'
                }`}
              >
                <Icon className={`w-4 h-4 ${isActive ? 'text-slate-950' : 'text-amber-400'}`} />
                <span>{item.label}</span>
              </button>
            );
          })}
        </div>
      )}
    </header>
  );
};
