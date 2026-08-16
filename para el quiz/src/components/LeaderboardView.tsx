import React, { useState, useEffect } from 'react';
import { UserProfile, RankingUser } from '../types';
import { supabaseService } from '../services/supabaseService';
import { sounds } from '../services/soundEffects';
import { Trophy, Sparkles, Crown, Medal, User, ArrowUp, RefreshCw, Building2, Gavel } from 'lucide-react';

interface LeaderboardViewProps {
  profile: UserProfile;
}

export const LeaderboardView: React.FC<LeaderboardViewProps> = ({ profile }) => {
  const [rankingList, setRankingList] = useState<RankingUser[]>([]);
  const [loading, setLoading] = useState<boolean>(true);

  const fetchRanking = async () => {
    setLoading(true);
    const data = await supabaseService.getLeaderboard(25);

    // Insert current user into ranking display if not already included
    const userInList = data.find(r => r.user_id === profile.id);
    if (!userInList) {
      data.push({
        id: 'me',
        user_id: profile.id,
        nombre: `${profile.nombre} (Tú)`,
        nivel: profile.nivel_actual,
        xp: profile.puntos_totales,
        rango: profile.rango_actual
      });
      // Re-sort by XP descending
      data.sort((a, b) => b.xp - a.xp);
    }

    setRankingList(data);
    setLoading(false);
  };

  useEffect(() => {
    fetchRanking();
  }, [profile.puntos_totales, profile.nivel_actual]);

  return (
    <div className="max-w-5xl mx-auto px-3 sm:px-6 pb-28">
      
      {/* Header */}
      <div className="text-center max-w-2xl mx-auto mb-8">
        <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-gradient-to-tr from-amber-600 via-amber-400 to-yellow-500 p-0.5 mb-3 shadow-xl shadow-amber-950/80">
          <div className="w-full h-full bg-[#0b101c] rounded-[14px] flex items-center justify-center border border-amber-400/50">
            <Trophy className="w-8 h-8 text-amber-400" />
          </div>
        </div>
        <h2 className="font-judicial text-2xl sm:text-4xl font-black text-transparent bg-clip-text bg-gradient-to-r from-amber-100 via-amber-300 to-amber-500 mb-2">
          Sala de Honor • Poder Judicial TSJ
        </h2>
        <p className="text-sm text-slate-300">
          Asientos numerados de magistrados y juristas en el Circuito Penal de la República Bolivariana de Venezuela, ordenados por experiencia procesal (XP).
        </p>
      </div>

      {/* Top 3 Podium (Magistrados de Honor en Estrado Principal) */}
      {rankingList.length >= 3 && (
        <div className="grid grid-cols-3 gap-3 sm:gap-6 mb-10 items-end">
          
          {/* 2nd Place: Vicepresidente de Sala */}
          <div className="bg-gradient-to-b from-[#18233a] via-[#111a2c] to-[#0a0f1d] border-2 border-slate-500/70 rounded-3xl p-4 sm:p-6 text-center shadow-2xl flex flex-col items-center relative overflow-hidden">
            <div className="absolute top-2 left-2 text-[10px] font-mono text-slate-400 bg-slate-900 px-2 py-0.5 rounded border border-slate-700">
              Curul #2
            </div>
            <div className="w-12 h-12 sm:w-16 sm:h-16 rounded-2xl bg-gradient-to-tr from-slate-400 to-slate-200 text-slate-950 flex items-center justify-center font-black font-judicial text-base sm:text-xl mb-2 border-2 border-white shadow-lg">
              2°
            </div>
            <span className="text-[9px] uppercase tracking-wider font-bold bg-slate-800 text-slate-300 px-2 py-0.5 rounded-full mb-1 border border-slate-700">
              Vicepresidente
            </span>
            <h4 className="font-judicial text-xs sm:text-sm font-bold text-slate-100 truncate w-full">
              {rankingList[1].nombre}
            </h4>
            <span className="text-[11px] text-amber-400 font-mono block font-semibold mt-0.5">
              Nivel {rankingList[1].nivel}
            </span>
            <span className="text-xs sm:text-sm font-mono font-black text-slate-200 mt-1">
              {rankingList[1].xp.toLocaleString()} XP
            </span>
          </div>

          {/* 1st Place: Presidente del Tribunal Supremo */}
          <div className="bg-gradient-to-b from-[#2a1708] via-[#1c2438] to-[#0c1220] border-2 border-amber-400 rounded-3xl p-5 sm:p-7 text-center shadow-[0_0_40px_rgba(245,158,11,0.35)] flex flex-col items-center -translate-y-3 ring-4 ring-amber-500/30 relative overflow-hidden">
            <div className="absolute top-2 left-2 text-[10px] font-mono text-amber-300 bg-amber-950 px-2 py-0.5 rounded border border-amber-600">
              Curul #1 • Estrado
            </div>
            <div className="w-14 h-14 sm:w-20 sm:h-20 rounded-2xl bg-gradient-to-tr from-amber-500 via-yellow-300 to-amber-600 text-slate-950 flex items-center justify-center font-black font-judicial text-xl sm:text-2xl mb-2 border-2 border-yellow-100 shadow-xl animate-pulse">
              <Crown className="w-8 h-8 sm:w-10 sm:h-10 fill-slate-950" />
            </div>
            <span className="text-[9px] uppercase tracking-widest font-black bg-gradient-to-r from-amber-400 to-yellow-300 text-slate-950 px-3 py-0.5 rounded-full mb-1 shadow">
              Presidente TSJ
            </span>
            <h4 className="font-judicial text-sm sm:text-lg font-black text-amber-200 truncate w-full">
              {rankingList[0].nombre}
            </h4>
            <span className="text-xs sm:text-sm text-amber-400 font-mono block font-bold mt-0.5">
              Nivel {rankingList[0].nivel}
            </span>
            <span className="text-sm sm:text-base font-mono font-black text-amber-300 mt-1">
              {rankingList[0].xp.toLocaleString()} XP
            </span>
          </div>

          {/* 3rd Place: Magistrado Ponente */}
          <div className="bg-gradient-to-b from-[#18233a] via-[#111a2c] to-[#0a0f1d] border-2 border-amber-700/60 rounded-3xl p-4 sm:p-6 text-center shadow-2xl flex flex-col items-center relative overflow-hidden">
            <div className="absolute top-2 left-2 text-[10px] font-mono text-amber-600 bg-slate-900 px-2 py-0.5 rounded border border-amber-900/60">
              Curul #3
            </div>
            <div className="w-12 h-12 sm:w-16 sm:h-16 rounded-2xl bg-gradient-to-tr from-amber-700 to-amber-500 text-slate-950 flex items-center justify-center font-black font-judicial text-base sm:text-xl mb-2 border-2 border-amber-400 shadow-lg">
              3°
            </div>
            <span className="text-[9px] uppercase tracking-wider font-bold bg-amber-950/80 text-amber-300 px-2 py-0.5 rounded-full mb-1 border border-amber-800">
              Magistrado
            </span>
            <h4 className="font-judicial text-xs sm:text-sm font-bold text-slate-100 truncate w-full">
              {rankingList[2].nombre}
            </h4>
            <span className="text-[11px] text-amber-400 font-mono block font-semibold mt-0.5">
              Nivel {rankingList[2].nivel}
            </span>
            <span className="text-xs sm:text-sm font-mono font-black text-slate-200 mt-1">
              {rankingList[2].xp.toLocaleString()} XP
            </span>
          </div>

        </div>
      )}

      {/* Red Velvet Courtroom Seating Rows (Bancos de Audiencia) */}
      <div className="bg-[#090d18] border-2 border-amber-800/60 rounded-3xl overflow-hidden shadow-2xl">
        
        {/* Table Header Ribbon */}
        <div className="px-5 py-4 bg-[#0d1424] border-b border-amber-900/40 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Gavel className="w-4 h-4 text-amber-400" />
            <span className="text-xs font-judicial font-bold uppercase tracking-wider text-amber-300">
              Bancos de Magistrados y Juristas (Asientos de Audiencia)
            </span>
          </div>
          <button
            onClick={() => { sounds.playClick(); fetchRanking(); }}
            className="flex items-center gap-1.5 text-xs text-amber-400 hover:text-amber-300 font-semibold px-3 py-1 rounded-xl bg-slate-900 border border-slate-700 cursor-pointer transition-colors"
          >
            <RefreshCw className={`w-3.5 h-3.5 ${loading ? 'animate-spin' : ''}`} />
            <span>Actualizar Sala</span>
          </button>
        </div>

        {/* Velvet Bench Rows */}
        <div className="divide-y divide-slate-800/80">
          {rankingList.map((jurist, index) => {
            const isMe = jurist.user_id === profile.id;
            const seatNumber = index + 1;
            const isTop3 = seatNumber <= 3;

            return (
              <div
                key={jurist.id}
                className={`flex items-center justify-between p-4 sm:p-5 transition-all ${
                  isMe
                    ? 'bg-gradient-to-r from-amber-950/60 via-[#18233c] to-[#0e1628] border-l-4 border-amber-400 font-semibold shadow-inner'
                    : index % 2 === 0
                    ? 'bg-[#0a0f1d]'
                    : 'bg-[#070b14]'
                } hover:bg-slate-900/60`}
              >
                {/* Left: Seat Bronze Plaque & Name */}
                <div className="flex items-center gap-3.5">
                  {/* Bronze Seat Plaque */}
                  <div className={`w-9 h-9 sm:w-10 sm:h-10 rounded-xl flex items-center justify-center font-mono font-bold text-xs sm:text-sm border shadow ${
                    isTop3
                      ? 'bg-gradient-to-tr from-amber-500 to-yellow-400 text-slate-950 border-yellow-200'
                      : 'bg-slate-900 text-slate-300 border-slate-700'
                  }`}>
                    {seatNumber}
                  </div>

                  {/* Red Velvet Seat Cushion Icon */}
                  <div className="w-9 h-9 rounded-xl bg-gradient-to-br from-red-950 to-[#220404] border border-red-800/60 flex items-center justify-center text-amber-300 shadow">
                    <User className="w-4 h-4" />
                  </div>

                  <div>
                    <h5 className={`text-sm sm:text-base font-judicial font-bold flex items-center gap-2 ${
                      isMe ? 'text-amber-300' : 'text-slate-200'
                    }`}>
                      <span>{jurist.nombre}</span>
                      {isMe && (
                        <span className="text-[10px] px-2 py-0.2 rounded-full bg-amber-500 text-slate-950 font-black font-mono">
                          Tú
                        </span>
                      )}
                      {seatNumber === 1 && (
                        <Crown className="w-4 h-4 text-amber-400 fill-amber-400" />
                      )}
                    </h5>
                    <span className="text-xs text-slate-400 block truncate max-w-[180px] sm:max-w-xs">
                      {jurist.rango}
                    </span>
                  </div>
                </div>

                {/* Right: Level & XP */}
                <div className="text-right">
                  <div className="font-mono text-sm sm:text-base font-black text-amber-300">
                    {jurist.xp.toLocaleString()} XP
                  </div>
                  <span className="text-xs font-mono text-slate-400 block">
                    Escalón #{jurist.nivel}
                  </span>
                </div>
              </div>
            );
          })}
        </div>

      </div>

    </div>
  );
};
