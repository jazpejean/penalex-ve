import React, { useState } from 'react';
import { UserProfile, CertificateData } from '../types';
import { getRankByLevel, MILESTONE_LEVELS } from '../data/judicialRanks';
import { generateCertificatePdf } from '../services/certificatePdfGenerator';
import { sounds } from '../services/soundEffects';
import { supabaseService } from '../services/supabaseService';
import { 
  Award, 
  Download, 
  Printer, 
  Share2, 
  CheckCircle2, 
  Lock, 
  Crown, 
  Sparkles, 
  Calendar, 
  FileText,
  ShieldCheck,
  Building2
} from 'lucide-react';

interface CertificateViewProps {
  profile: UserProfile;
  onUpdateProfile: (updated: UserProfile) => void;
}

export const CertificateView: React.FC<CertificateViewProps> = ({
  profile,
  onUpdateProfile
}) => {
  const [selectedMilestone, setSelectedMilestone] = useState<number>(100);
  const [justGenerated, setJustGenerated] = useState<boolean>(false);

  const selectedRank = getRankByLevel(selectedMilestone);
  const isUnlocked = profile.nivel_actual >= selectedMilestone;

  const handleGeneratePdf = (levelToGenerate: number) => {
    sounds.playScroll();
    const certData = generateCertificatePdf(profile, levelToGenerate);
    
    // Save to user profile and sync to Supabase
    const existingIndex = profile.pdf_generados.findIndex(c => c.nivel === levelToGenerate);
    let updatedCertList = [...profile.pdf_generados];
    
    if (existingIndex >= 0) {
      updatedCertList[existingIndex] = certData;
    } else {
      updatedCertList.push(certData);
    }

    const updatedProfile: UserProfile = {
      ...profile,
      pdf_generados: updatedCertList
    };

    onUpdateProfile(updatedProfile);
    supabaseService.saveCertificate(certData);
    setJustGenerated(true);
    setTimeout(() => setJustGenerated(false), 4000);
  };

  const handlePrint = () => {
    sounds.playClick();
    window.print();
  };

  const handleShare = () => {
    sounds.playClick();
    if (navigator.share) {
      navigator.share({
        title: `Certificado Judicial de ${profile.nombre}`,
        text: `¡He alcanzado el rango de ${selectedRank.title} en Derecho Penal Venezolano (Nivel ${selectedMilestone}) con IurisPenal!`,
        url: window.location.href
      }).catch(() => {});
    } else {
      navigator.clipboard.writeText(window.location.href);
      alert('¡Enlace de verificación copiado al portapapeles!');
    }
  };

  return (
    <div className="max-w-5xl mx-auto px-3 sm:px-6 pb-24">
      
      {/* Top Header */}
      <div className="text-center max-w-2xl mx-auto mb-8">
        <div className="inline-flex items-center justify-center w-14 h-14 rounded-2xl bg-amber-950/80 border border-amber-500/40 mb-3 shadow-lg shadow-amber-950/60">
          <Award className="w-8 h-8 text-amber-400" />
        </div>
        <h2 className="font-judicial text-2xl sm:text-4xl font-extrabold text-transparent bg-clip-text bg-gradient-to-r from-amber-200 via-amber-400 to-amber-600 mb-2">
          Certificados y Diplomas Oficiales
        </h2>
        <p className="text-sm text-slate-300">
          Acreditaciones del Poder Judicial por hitos superados en Derecho Penal Venezolano. Genera y descarga en formato PDF de alta resolución.
        </p>
      </div>

      {/* Milestone Tabs Selector */}
      <div className="flex items-center justify-center gap-2 mb-8 overflow-x-auto pb-2">
        {MILESTONE_LEVELS.map((level) => {
          const rank = getRankByLevel(level);
          const unlocked = profile.nivel_actual >= level;
          const isSelected = selectedMilestone === level;

          return (
            <button
              key={level}
              onClick={() => { sounds.playClick(); setSelectedMilestone(level); }}
              id={`tab-certificate-${level}`}
              className={`px-4 py-2.5 rounded-2xl border-2 transition-all flex items-center gap-2 cursor-pointer shrink-0 ${
                isSelected
                  ? 'bg-gradient-to-r from-amber-500 to-amber-700 border-amber-300 text-slate-950 font-bold shadow-lg shadow-amber-950/60 scale-105'
                  : unlocked
                  ? 'bg-slate-900 border-amber-600/50 text-amber-300 hover:border-amber-400'
                  : 'bg-slate-950/60 border-slate-800 text-slate-500 hover:border-slate-700'
              }`}
            >
              {unlocked ? (
                <Crown className={`w-4 h-4 ${isSelected ? 'text-slate-950' : 'text-amber-400'}`} />
              ) : (
                <Lock className="w-3.5 h-3.5 text-slate-600" />
              )}
              <div className="text-left leading-tight">
                <span className="text-xs font-mono block">Nivel {level}</span>
                <span className="text-[10px] font-judicial block truncate max-w-[120px]">
                  {rank.title.split(' ')[0]}...
                </span>
              </div>
            </button>
          );
        })}
      </div>

      {/* Diploma Preview Screen Frame */}
      <div className="bg-[#090d16] border-2 border-amber-800/60 rounded-3xl p-4 sm:p-8 shadow-2xl mb-8 relative">
        
        {/* Certificate Landscape Replica */}
        <div 
          id="printable-diploma"
          className="relative bg-[#fcf9ef] text-slate-900 rounded-2xl p-6 sm:p-12 border-4 border-amber-700 shadow-2xl overflow-hidden min-h-[420px] sm:min-h-[500px] flex flex-col justify-between"
        >
          {/* Inner decorative double gold borders */}
          <div className="absolute inset-2 border-2 border-amber-600/70 pointer-events-none rounded-xl" />
          <div className="absolute inset-3 border border-slate-900/30 pointer-events-none rounded-lg" />

          {/* Watermark TSJ Emblem in Center Background */}
          <div className="absolute inset-0 flex items-center justify-center pointer-events-none opacity-[0.04]">
            <Building2 className="w-96 h-96 text-slate-900" />
          </div>

          {/* Header Section */}
          <div className="text-center relative z-10">
            <div className="text-[10px] sm:text-xs font-bold tracking-widest text-slate-600 uppercase mb-0.5">
              REPÚBLICA BOLIVARIANA DE VENEZUELA
            </div>
            <div className="text-[9px] sm:text-[11px] font-semibold text-slate-500 tracking-wider uppercase mb-1">
              PODER JUDICIAL • CIRCUITO JUDICIAL PENAL
            </div>
            <div className="text-[9px] sm:text-[11px] font-bold text-amber-800 tracking-wider uppercase mb-3">
              TRIBUNAL SUPREMO DE JUSTICIA - SALA DE CASACIÓN PENAL
            </div>

            <div className="w-32 sm:w-48 h-0.5 bg-gradient-to-r from-transparent via-amber-700 to-transparent mx-auto mb-4" />

            <h1 className="font-judicial text-2xl sm:text-4xl font-extrabold text-amber-900 tracking-wide uppercase mb-2">
              CERTIFICADO DE MÉRITO JUDICIAL
            </h1>

            <p className="italic text-xs sm:text-sm text-slate-600 font-serif">
              Se confiere la presente Acreditación de Excelencia y Aptitud Jurídica a:
            </p>
          </div>

          {/* Recipient Name in Calligraphy Style */}
          <div className="text-center my-4 sm:my-6 relative z-10">
            <h2 className="font-judicial text-2xl sm:text-4xl font-black text-slate-900 tracking-wider uppercase underline decoration-amber-600 decoration-2 underline-offset-8">
              {profile.nombre}
            </h2>
            <p className="text-xs sm:text-sm text-slate-700 mt-4 max-w-xl mx-auto leading-relaxed">
              Por haber superado exitosamente el <span className="font-bold text-amber-900">Nivel {selectedMilestone}</span> de casos penales, demostrando riguroso dominio dogmático del Código Penal Venezolano, del Código Orgánico Procesal Penal y jurisprudencia vinculante del Tribunal Supremo de Justicia, otorgándosele el rango de honor:
            </p>

            {/* Rank Badge Box */}
            <div className="inline-block mt-3 bg-amber-100/90 border border-amber-700/80 rounded-xl px-5 py-2 shadow-inner">
              <span className="font-judicial text-base sm:text-xl font-bold text-amber-950">
                « {selectedRank.title} »
              </span>
            </div>
          </div>

          {/* Signatures & Seal Section */}
          <div className="relative z-10 pt-4 border-t border-amber-700/30 flex items-end justify-between text-center text-slate-800">
            
            {/* Left signature */}
            <div className="w-1/3">
              <div className="w-24 sm:w-36 h-0.5 bg-slate-700 mx-auto mb-1" />
              <div className="text-[10px] sm:text-xs font-bold font-serif">Magistrado Presidente</div>
              <div className="text-[8px] sm:text-[10px] text-slate-600">Sala de Casación Penal TSJ</div>
            </div>

            {/* Center Gold Seal */}
            <div className="w-1/3 flex flex-col items-center">
              <div className="w-12 h-12 sm:w-16 sm:h-16 rounded-full bg-gradient-to-tr from-amber-700 via-amber-500 to-yellow-200 border-2 border-amber-900 flex items-center justify-center text-slate-950 font-bold shadow-md">
                <Crown className="w-6 h-6 sm:w-8 sm:h-8 text-slate-950 fill-slate-950" />
              </div>
              <span className="text-[8px] sm:text-[9px] font-bold text-amber-900 mt-1 uppercase tracking-wider">
                SELLO OFICIAL TSJ
              </span>
            </div>

            {/* Right signature */}
            <div className="w-1/3">
              <div className="w-24 sm:w-36 h-0.5 bg-slate-700 mx-auto mb-1" />
              <div className="text-[10px] sm:text-xs font-bold font-serif">Secretario de Sala</div>
              <div className="text-[8px] sm:text-[10px] text-slate-600">Circuito Judicial Penal</div>
            </div>

          </div>

          {/* Verification Code Footer */}
          <div className="text-center text-[8px] sm:text-[9px] font-mono text-slate-500 mt-3">
            VERIFICACIÓN DIGITAL: VE-TSJ-{selectedMilestone}-{profile.id.toUpperCase()} • EXPEDIDO EN CARACAS, VENEZUELA
          </div>
        </div>

        {/* Lock Overlay if level not yet unlocked */}
        {!isUnlocked && (
          <div className="absolute inset-0 bg-slate-950/85 backdrop-blur-sm rounded-3xl flex flex-col items-center justify-center p-6 text-center z-20">
            <div className="w-16 h-16 rounded-2xl bg-amber-950/80 border border-amber-500/50 flex items-center justify-center mb-4 shadow-xl">
              <Lock className="w-8 h-8 text-amber-400" />
            </div>
            <h3 className="font-judicial text-2xl font-bold text-amber-200 mb-1">
              Certificado Bloqueado
            </h3>
            <p className="text-sm text-slate-300 max-w-md mb-4">
              Debes alcanzar el <strong className="text-amber-400">Nivel {selectedMilestone}</strong> para desbloquear este título honorífico del Poder Judicial.
            </p>
            <div className="text-xs font-mono text-slate-400 bg-slate-900 px-4 py-2 rounded-xl border border-slate-800">
              Progreso actual: Nivel {profile.nivel_actual} / {selectedMilestone} ({Math.round((profile.nivel_actual / selectedMilestone) * 100)}%)
            </div>
          </div>
        )}

      </div>

      {/* Certificate Controls & Downloads */}
      {isUnlocked && (
        <div className="flex flex-col sm:flex-row items-center justify-center gap-3">
          
          <button
            onClick={() => handleGeneratePdf(selectedMilestone)}
            id="btn-descargar-pdf"
            className="w-full sm:w-auto py-3.5 px-6 rounded-2xl bg-gradient-to-r from-amber-500 via-amber-400 to-amber-600 text-slate-950 font-black text-sm tracking-wide shadow-xl shadow-amber-950/80 hover:brightness-110 active:scale-[0.98] transition-all flex items-center justify-center gap-2 cursor-pointer"
          >
            <Download className="w-4 h-4" />
            <span>Descargar Certificado en PDF</span>
          </button>

          <button
            onClick={handlePrint}
            id="btn-imprimir-diploma"
            className="w-full sm:w-auto py-3.5 px-5 rounded-2xl bg-slate-800 hover:bg-slate-700 text-slate-200 font-bold text-sm flex items-center justify-center gap-2 transition-colors cursor-pointer"
          >
            <Printer className="w-4 h-4" />
            <span>Imprimir</span>
          </button>

          <button
            onClick={handleShare}
            id="btn-compartir-diploma"
            className="w-full sm:w-auto py-3.5 px-5 rounded-2xl bg-slate-800 hover:bg-slate-700 text-slate-200 font-bold text-sm flex items-center justify-center gap-2 transition-colors cursor-pointer"
          >
            <Share2 className="w-4 h-4 text-amber-400" />
            <span>Compartir</span>
          </button>

        </div>
      )}

      {justGenerated && (
        <div className="mt-4 p-3 rounded-xl bg-emerald-950/80 border border-emerald-500/60 text-emerald-300 text-xs font-semibold text-center animate-fade-in flex items-center justify-center gap-2">
          <CheckCircle2 className="w-4 h-4" />
          <span>¡Certificado PDF generado exitosamente y sincronizado con Supabase Storage!</span>
        </div>
      )}

    </div>
  );
};
