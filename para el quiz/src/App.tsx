import React, { useState, useEffect } from 'react';
import { UserProfile, BoostersInventory } from './types';
import { supabaseService } from './services/supabaseService';
import { sounds } from './services/soundEffects';
import { getRankByLevel } from './data/judicialRanks';

// Core Components
import { Navbar } from './components/Navbar';
import { CandyMap } from './components/CandyMap';
import { QuizArena } from './components/QuizArena';
import { CertificateView } from './components/CertificateView';
import { LeaderboardView } from './components/LeaderboardView';
import { AchievementsView } from './components/AchievementsView';
import { QuestionsManager } from './components/QuestionsManager';
import { SupabaseHub } from './components/SupabaseHub';
import { FlutterExportView } from './components/FlutterExportView';
import { AudioBar } from './components/AudioBar';

// Modals
import { ApelacionesModal } from './components/ApelacionesModal';
import { LevelUpModal } from './components/LevelUpModal';

export function App() {
  const [profile, setProfile] = useState<UserProfile>(() => supabaseService.getInitialProfile());
  const [activeTab, setActiveTab] = useState<string>('mapa');
  const [activeQuizLevel, setActiveQuizLevel] = useState<number>(profile.nivel_actual);

  // Modals state
  const [appealsModalOpen, setAppealsModalOpen] = useState<boolean>(false);
  const [levelUpModalOpen, setLevelUpModalOpen] = useState<boolean>(false);
  const [editNameModalOpen, setEditNameModalOpen] = useState<boolean>(false);
  const [tempUserName, setTempUserName] = useState<string>(profile.nombre);

  // Level Up Details
  const [lastPassedLevel, setLastPassedLevel] = useState<number>(1);
  const [lastXpEarned, setLastXpEarned] = useState<number>(10);

  // Check and regenerate apelaciones every 30s
  useEffect(() => {
    const timer = setInterval(() => {
      setProfile((prev) => supabaseService.calculateRegeneratedAppeals(prev));
    }, 30000);
    return () => clearInterval(timer);
  }, []);

  const handleSelectLevelFromMap = (level: number) => {
    setActiveQuizLevel(level);
    setActiveTab('quiz');
  };

  const handleAnswerResult = (correct: boolean, xpEarned: number, starsEarned: number = 3) => {
    if (correct) {
      const nextLevel = Math.max(profile.nivel_actual, activeQuizLevel + 1);
      const newStreak = profile.racha_actual + 1;
      const newMaxStreak = Math.max(profile.max_racha, newStreak);
      const newXp = profile.puntos_totales + xpEarned;
      const newRank = getRankByLevel(nextLevel).title;

      const starsRecord = { ...(profile.estrellas_por_nivel || {}) };
      starsRecord[activeQuizLevel] = Math.max(starsEarned, starsRecord[activeQuizLevel] || 0);

      const updatedProfile: UserProfile = {
        ...profile,
        nivel_actual: nextLevel,
        puntos_totales: newXp,
        rango_actual: newRank,
        racha_actual: newStreak,
        max_racha: newMaxStreak,
        estrellas_por_nivel: starsRecord
      };

      setProfile(updatedProfile);
      supabaseService.saveProfile(updatedProfile);

      setLastPassedLevel(activeQuizLevel);
      setLastXpEarned(xpEarned);
      setLevelUpModalOpen(true);
    } else {
      // Penalty: Lose 1 apelación (pergamino) and reset current streak
      const newAppeals = Math.max(0, profile.apelaciones - 1);
      const updatedProfile: UserProfile = {
        ...profile,
        apelaciones: newAppeals,
        racha_actual: 0,
        ultima_regeneracion: new Date().toISOString()
      };

      setProfile(updatedProfile);
      supabaseService.saveProfile(updatedProfile);

      if (newAppeals === 0) {
        setTimeout(() => {
          setAppealsModalOpen(true);
        }, 600);
      }
    }
  };

  const handleClaimChest = (level: number, rewards: { xp: number; appeals: number; booster?: keyof BoostersInventory }) => {
    const currentClaimed = profile.cofres_reclamados || [];
    if (currentClaimed.includes(level)) return;

    const updatedBoosters: BoostersInventory = {
      mazo5050: profile.boosters?.mazo5050 ?? 3,
      relojExtra: profile.boosters?.relojExtra ?? 3,
      doctrinaTSJ: profile.boosters?.doctrinaTSJ ?? 2,
      escudo: profile.boosters?.escudo ?? 2,
    };

    if (rewards.booster && rewards.booster in updatedBoosters) {
      updatedBoosters[rewards.booster] = (updatedBoosters[rewards.booster] || 0) + 1;
    }

    const updatedProfile: UserProfile = {
      ...profile,
      puntos_totales: profile.puntos_totales + rewards.xp,
      apelaciones: Math.min(5, profile.apelaciones + rewards.appeals),
      cofres_reclamados: [...currentClaimed, level],
      boosters: updatedBoosters
    };

    setProfile(updatedProfile);
    supabaseService.saveProfile(updatedProfile);
  };

  const handleGoToNextLevel = () => {
    setLevelUpModalOpen(false);
    const nextLvl = activeQuizLevel + 1;
    setActiveQuizLevel(nextLvl);
    setActiveTab('quiz');
  };

  const handleRestoreAppeals = () => {
    const updatedProfile: UserProfile = {
      ...profile,
      apelaciones: 5,
      ultima_regeneracion: new Date().toISOString()
    };
    setProfile(updatedProfile);
    supabaseService.saveProfile(updatedProfile);
  };

  const handleSaveProfileName = (e: React.FormEvent) => {
    e.preventDefault();
    if (!tempUserName.trim()) return;
    sounds.playClick();
    const updatedProfile: UserProfile = {
      ...profile,
      nombre: tempUserName.trim()
    };
    setProfile(updatedProfile);
    supabaseService.saveProfile(updatedProfile);
    setEditNameModalOpen(false);
  };

  return (
    <div className="min-h-screen bg-[#070b13] text-slate-100 flex flex-col selection:bg-amber-500 selection:text-slate-950">
      
      {/* 🎵 Live Audio Control & Background Music Controller */}
      <AudioBar />

      {/* Top Judicial Navbar */}
      <Navbar
        profile={profile}
        activeTab={activeTab}
        setActiveTab={setActiveTab}
        onOpenAppealsModal={() => setAppealsModalOpen(true)}
        isSupabaseConnected={supabaseService.isConnected()}
        onEditProfileName={() => {
          setTempUserName(profile.nombre);
          setEditNameModalOpen(true);
        }}
      />

      {/* Main Screen Body */}
      <main className="flex-1 max-w-7xl w-full mx-auto pt-4 px-3 sm:px-6">
        
        {activeTab === 'mapa' && (
          <CandyMap
            profile={profile}
            onSelectLevel={handleSelectLevelFromMap}
            onOpenCertificate={() => setActiveTab('certificados')}
            onClaimChest={handleClaimChest}
          />
        )}

        {activeTab === 'quiz' && (
          <QuizArena
            currentLevel={activeQuizLevel}
            profile={profile}
            onAnswerResult={handleAnswerResult}
            onOpenAppealsModal={() => setAppealsModalOpen(true)}
            onBackToMap={() => setActiveTab('mapa')}
          />
        )}

        {activeTab === 'certificados' && (
          <CertificateView
            profile={profile}
            onUpdateProfile={(up) => {
              setProfile(up);
              supabaseService.saveProfile(up);
            }}
          />
        )}

        {activeTab === 'ranking' && (
          <LeaderboardView profile={profile} />
        )}

        {activeTab === 'logros' && (
          <AchievementsView profile={profile} />
        )}

        {activeTab === 'banco' && (
          <QuestionsManager />
        )}

        {activeTab === 'supabase' && (
          <SupabaseHub />
        )}

        {activeTab === 'flutter' && (
          <FlutterExportView />
        )}

      </main>

      {/* Modals & Dialogs */}
      
      {/* 1. Appeals (Pergaminos) Modal */}
      <ApelacionesModal
        isOpen={appealsModalOpen}
        onClose={() => setAppealsModalOpen(false)}
        profile={profile}
        onRestoreAppeals={handleRestoreAppeals}
      />

      {/* 2. Level Up Celebratory Modal */}
      <LevelUpModal
        isOpen={levelUpModalOpen}
        onClose={() => setLevelUpModalOpen(false)}
        profile={profile}
        levelPassed={lastPassedLevel}
        xpEarned={lastXpEarned}
        streak={profile.racha_actual}
        onGoToNextLevel={handleGoToNextLevel}
        onViewCertificate={() => {
          setLevelUpModalOpen(false);
          setActiveTab('certificados');
        }}
      />

      {/* 3. Edit Name Modal */}
      {editNameModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm animate-fadeIn">
          <div className="w-full max-w-md bg-[#0f172a] border-2 border-amber-600/70 rounded-3xl p-6 shadow-2xl relative">
            <h3 className="text-xl font-bold text-amber-200 mb-2">
              Identidad en el Foro Penal
            </h3>
            <p className="text-xs text-slate-300 mb-4">
              Este nombre aparecerá en tus Sentencias, Diplomas Oficiales del TSJ y en el Ranking Nacional.
            </p>

            <form onSubmit={handleSaveProfileName} className="space-y-4">
              <input
                type="text"
                value={tempUserName}
                onChange={(e) => setTempUserName(e.target.value)}
                placeholder="Ej. Dr. Andrés Bello"
                className="w-full bg-slate-950 border border-slate-700 rounded-xl p-3 text-sm text-slate-100 font-semibold focus:outline-none focus:border-amber-500"
                maxLength={40}
                required
              />

              <div className="flex gap-2">
                <button
                  type="submit"
                  className="flex-1 py-3 rounded-xl bg-gradient-to-r from-amber-500 to-amber-600 hover:brightness-110 text-slate-950 font-bold text-xs tracking-wide shadow-lg cursor-pointer"
                >
                  Guardar Nombre
                </button>
                <button
                  type="button"
                  onClick={() => setEditNameModalOpen(false)}
                  className="py-3 px-4 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-300 text-xs font-semibold cursor-pointer"
                >
                  Cancelar
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

    </div>
  );
}
export default App;
