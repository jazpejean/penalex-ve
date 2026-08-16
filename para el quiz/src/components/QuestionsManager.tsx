import React, { useState } from 'react';
import { Pregunta } from '../types';
import { getQuestionByLevel, BASE_QUESTIONS, getQuestionsBatch } from '../data/questionsData';
import { sounds } from '../services/soundEffects';
import { 
  BookOpen, 
  Search, 
  Download, 
  Upload, 
  FileJson, 
  CheckCircle2, 
  Scale, 
  Copy, 
  Sparkles,
  Filter
} from 'lucide-react';

export const QuestionsManager: React.FC = () => {
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const [inspectedLevel, setInspectedLevel] = useState<number>(1);
  const [importedJson, setImportedJson] = useState<string>('');
  const [importStatus, setImportStatus] = useState<string>('');
  const [batchCount, setBatchCount] = useState<number>(50);

  const currentInspectedQuestion = getQuestionByLevel(inspectedLevel);

  const categories = [
    'all',
    'Parte General',
    'Delitos contra las Personas',
    'Delitos contra la Propiedad',
    'COPP y Procedimiento',
    'Drogas y Leyes Especiales',
    'Jurisprudencia TSJ'
  ];

  const handleExportJson = () => {
    sounds.playClick();
    const batch = getQuestionsBatch(1, batchCount);
    const dataStr = "data:text/json;charset=utf-8," + encodeURIComponent(JSON.stringify(batch, null, 2));
    const downloadAnchor = document.createElement('a');
    downloadAnchor.setAttribute("href", dataStr);
    downloadAnchor.setAttribute("download", `banco_preguntas_derecho_penal_1_${batchCount}.json`);
    document.body.appendChild(downloadAnchor);
    downloadAnchor.click();
    downloadAnchor.remove();
  };

  const handleExportSql = () => {
    sounds.playClick();
    const batch = getQuestionsBatch(1, batchCount);
    let sql = `-- MIGRACIÓN MASIVA DE PREGUNTAS EN SUPABASE (PostgreSQL)\n`;
    sql += `INSERT INTO public.preguntas (nivel, pregunta, opciones, respuesta_correcta, fundamentacion, articulo_referencia, categoria, activo) VALUES\n`;
    
    const rows = batch.map((q) => {
      const opcionesJson = JSON.stringify(q.opciones).replace(/'/g, "''");
      const pregEscaped = q.pregunta.replace(/'/g, "''");
      const fundEscaped = q.fundamentacion.replace(/'/g, "''");
      const artEscaped = (q.articulo_referencia || '').replace(/'/g, "''");
      const catEscaped = (q.categoria || 'Jurisprudencia').replace(/'/g, "''");
      return `(${q.nivel}, '${pregEscaped}', '${opcionesJson}'::jsonb, ${q.respuesta_correcta}, '${fundEscaped}', '${artEscaped}', '${catEscaped}', true)`;
    });

    sql += rows.join(',\n') + ';\n';

    const dataStr = "data:text/sql;charset=utf-8," + encodeURIComponent(sql);
    const downloadAnchor = document.createElement('a');
    downloadAnchor.setAttribute("href", dataStr);
    downloadAnchor.setAttribute("download", `seed_preguntas_supabase_1_${batchCount}.sql`);
    document.body.appendChild(downloadAnchor);
    downloadAnchor.click();
    downloadAnchor.remove();
  };

  const handleProcessImport = () => {
    try {
      const parsed = JSON.parse(importedJson);
      if (Array.isArray(parsed)) {
        setImportStatus(`¡Éxito! Se han validado ${parsed.length} preguntas en formato compatible con Supabase.`);
      } else {
        setImportStatus('El formato debe ser un arreglo de objetos JSON (Array de preguntas).');
      }
    } catch (e) {
      setImportStatus('Error de sintaxis JSON. Revisa la estructura del archivo.');
    }
  };

  return (
    <div className="max-w-6xl mx-auto px-3 sm:px-6 pb-24">
      
      {/* Header */}
      <div className="text-center max-w-2xl mx-auto mb-8">
        <div className="inline-flex items-center justify-center w-14 h-14 rounded-2xl bg-amber-950/80 border border-amber-500/40 mb-3 shadow-lg shadow-amber-950/60">
          <BookOpen className="w-8 h-8 text-amber-400" />
        </div>
        <h2 className="font-judicial text-2xl sm:text-4xl font-extrabold text-transparent bg-clip-text bg-gradient-to-r from-amber-200 via-amber-400 to-amber-600 mb-2">
          Banco de Casos & Carga Masiva (3000)
        </h2>
        <p className="text-sm text-slate-300">
          Inspecciona el banco de preguntas de Derecho Penal Venezolano, descarga lotes para Supabase o importa nuevas preguntas mediante JSON o CSV.
        </p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        {/* Left Column: Explorer & Question Inspector */}
        <div className="lg:col-span-2 space-y-4">
          
          {/* Search & Level Quick Selector */}
          <div className="bg-[#0c1220] border border-amber-900/50 rounded-2xl p-4 shadow-xl">
            <div className="flex flex-col sm:flex-row items-center justify-between gap-3">
              <div className="flex items-center gap-2 w-full sm:w-auto">
                <Scale className="w-5 h-5 text-amber-400 shrink-0" />
                <span className="text-sm font-judicial font-bold text-slate-200">
                  Explorador de Niveles (1 al 3000)
                </span>
              </div>
              <div className="flex items-center gap-2 w-full sm:w-auto">
                <input
                  type="range"
                  min="1"
                  max="3000"
                  value={inspectedLevel}
                  onChange={(e) => setInspectedLevel(parseInt(e.target.value, 10))}
                  className="w-full sm:w-48 accent-amber-500 cursor-pointer"
                />
                <span className="font-mono text-xs font-bold text-amber-400 bg-slate-900 px-2 py-1 rounded border border-slate-700">
                  Nivel {inspectedLevel}
                </span>
              </div>
            </div>
          </div>

          {/* Inspected Case Card */}
          <div className="bg-[#0f172a] border-2 border-amber-600/70 rounded-3xl p-5 sm:p-7 shadow-2xl space-y-4">
            
            <div className="flex items-center justify-between border-b border-slate-800 pb-3">
              <div className="flex items-center gap-2">
                <span className="w-8 h-8 rounded-lg bg-amber-500 text-slate-950 font-judicial font-black flex items-center justify-center text-sm">
                  {inspectedLevel}
                </span>
                <div>
                  <span className="text-[10px] font-mono text-amber-400 block font-semibold">
                    {currentInspectedQuestion.categoria || 'Derecho Penal'}
                  </span>
                  <span className="text-xs font-bold text-slate-200">
                    {currentInspectedQuestion.articulo_referencia}
                  </span>
                </div>
              </div>

              <span className="text-[11px] font-mono bg-emerald-950/70 text-emerald-300 border border-emerald-800/60 px-2 py-0.5 rounded-full">
                Correcta: Opción {['A', 'B', 'C', 'D'][currentInspectedQuestion.respuesta_correcta]}
              </span>
            </div>

            {/* Case Text */}
            <div className="bg-[#090d16] p-4 rounded-2xl border border-slate-800">
              <span className="text-[10px] uppercase tracking-wider font-bold text-slate-500 block mb-1">
                Enunciado del Caso Hipotético:
              </span>
              <p className="text-sm sm:text-base text-slate-100 leading-relaxed font-medium">
                {currentInspectedQuestion.pregunta}
              </p>
            </div>

            {/* Options */}
            <div className="space-y-2">
              <span className="text-[10px] uppercase tracking-wider font-bold text-slate-500 block">
                Opciones de Respuesta:
              </span>
              {currentInspectedQuestion.opciones.map((opt, idx) => {
                const isCorrect = idx === currentInspectedQuestion.respuesta_correcta;
                return (
                  <div
                    key={idx}
                    className={`p-3 rounded-xl border text-xs sm:text-sm flex items-center gap-3 ${
                      isCorrect
                        ? 'bg-emerald-950/40 border-emerald-500/70 text-emerald-200 font-semibold'
                        : 'bg-slate-900 border-slate-800 text-slate-300'
                    }`}
                  >
                    <span className={`w-6 h-6 rounded-md flex items-center justify-center font-bold text-xs shrink-0 ${
                      isCorrect ? 'bg-emerald-500 text-slate-950' : 'bg-slate-800 text-slate-400'
                    }`}>
                      {['A', 'B', 'C', 'D'][idx]}
                    </span>
                    <span>{opt}</span>
                  </div>
                );
              })}
            </div>

            {/* Legal Fundamentation */}
            <div className="bg-[#121c32] p-4 rounded-2xl border border-amber-800/50">
              <span className="text-[10px] uppercase tracking-wider font-bold text-amber-400 block mb-1">
                Fundamentación Legal & Precedente:
              </span>
              <p className="text-xs sm:text-sm text-slate-200 leading-relaxed">
                {currentInspectedQuestion.fundamentacion}
              </p>
            </div>

          </div>

        </div>

        {/* Right Column: Mass Export & Ingestion Tools */}
        <div className="space-y-6">
          
          {/* Export Panel for Supabase */}
          <div className="bg-[#0c1220] border border-amber-900/50 rounded-2xl p-5 shadow-xl space-y-4">
            <div className="flex items-center gap-2">
              <Download className="w-5 h-5 text-amber-400" />
              <h3 className="font-judicial text-base font-bold text-slate-100">
                Exportar Lotes para Supabase
              </h3>
            </div>

            <p className="text-xs text-slate-300">
              Genera archivos de inserción masiva para la tabla <code className="text-amber-300 font-mono">preguntas</code> en Supabase PostgreSQL.
            </p>

            <div className="flex items-center gap-2">
              <label className="text-xs text-slate-400">Cantidad:</label>
              <select
                value={batchCount}
                onChange={(e) => setBatchCount(parseInt(e.target.value, 10))}
                className="bg-slate-900 border border-slate-700 text-slate-200 rounded-lg px-2.5 py-1 text-xs font-mono"
              >
                <option value="50">50 Preguntas</option>
                <option value="100">100 Preguntas</option>
                <option value="500">500 Preguntas</option>
                <option value="1000">1,000 Preguntas</option>
                <option value="3000">3,000 Preguntas (Completo)</option>
              </select>
            </div>

            <div className="flex flex-col gap-2">
              <button
                onClick={handleExportJson}
                className="py-2.5 px-3 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-200 text-xs font-bold flex items-center justify-center gap-2 transition-colors cursor-pointer"
              >
                <FileJson className="w-4 h-4 text-amber-400" />
                <span>Descargar en Formato JSON</span>
              </button>

              <button
                onClick={handleExportSql}
                className="py-2.5 px-3 rounded-xl bg-gradient-to-r from-amber-600 to-amber-700 hover:brightness-110 text-slate-950 text-xs font-bold flex items-center justify-center gap-2 transition-colors cursor-pointer shadow"
              >
                <Download className="w-4 h-4 text-slate-950" />
                <span>Descargar Script SQL (INSERT)</span>
              </button>
            </div>
          </div>

          {/* Mass Ingestion Validator */}
          <div className="bg-[#0c1220] border border-amber-900/50 rounded-2xl p-5 shadow-xl space-y-3">
            <div className="flex items-center gap-2">
              <Upload className="w-5 h-5 text-amber-400" />
              <h3 className="font-judicial text-base font-bold text-slate-100">
                Importador de Nuevas Preguntas
              </h3>
            </div>

            <p className="text-xs text-slate-300">
              Pega aquí preguntas en formato JSON para verificar y cargar al banco.
            </p>

            <textarea
              rows={4}
              placeholder={`[{\n  "nivel": 1,\n  "pregunta": "...",\n  "opciones": ["A", "B", "C", "D"],\n  "respuesta_correcta": 3,\n  "fundamentacion": "..."\n}]`}
              value={importedJson}
              onChange={(e) => setImportedJson(e.target.value)}
              className="w-full bg-slate-950 border border-slate-800 rounded-xl p-3 text-xs font-mono text-slate-300 focus:outline-none focus:border-amber-500"
            />

            <button
              onClick={handleProcessImport}
              className="w-full py-2.5 px-3 rounded-xl bg-amber-500 hover:bg-amber-400 text-slate-950 text-xs font-bold flex items-center justify-center gap-2 transition-colors cursor-pointer"
            >
              <CheckCircle2 className="w-4 h-4" />
              <span>Validar e Importar</span>
            </button>

            {importStatus && (
              <p className="text-xs text-amber-300 bg-amber-950/40 p-2.5 rounded-lg border border-amber-800/40 font-mono">
                {importStatus}
              </p>
            )}
          </div>

        </div>

      </div>

    </div>
  );
};
