// High-Fidelity Web Audio API Synthesizer & Soundtrack Engine for PENALEX VE
export type AudioMode = 'all' | 'sfx_only' | 'muted';

class SoundEffectsEngine {
  private ctx: AudioContext | null = null;
  private audioMode: AudioMode = 'all';
  private masterGain: GainNode | null = null;
  private musicGain: GainNode | null = null;
  private sfxGain: GainNode | null = null;
  private voiceGain: GainNode | null = null;

  // Background Music Timers & Nodes
  private currentMusicType: 'lobby' | 'quiz' | 'victory' | null = null;
  private bgmInterval: number | null = null;
  private isAudioUnlocked: boolean = false;
  private volumeLevel: number = 0.8;

  // Listeners for UI state changes
  private listeners: ((state: { mode: AudioMode; isPlaying: boolean; musicType: string | null; isUnlocked: boolean }) => void)[] = [];

  constructor() {
    if (typeof window !== 'undefined') {
      const savedMode = localStorage.getItem('penalex_audio_mode') as AudioMode;
      if (savedMode && ['all', 'sfx_only', 'muted'].includes(savedMode)) {
        this.audioMode = savedMode;
      }

      // Auto-unlock on any user gesture across the whole page
      const unlockHandler = () => {
        this.unlockAudio();
      };
      window.addEventListener('click', unlockHandler, { passive: true });
      window.addEventListener('touchstart', unlockHandler, { passive: true });
      window.addEventListener('keydown', unlockHandler, { passive: true });
    }
  }

  public subscribe(listener: (state: { mode: AudioMode; isPlaying: boolean; musicType: string | null; isUnlocked: boolean }) => void): () => void {
    this.listeners.push(listener);
    listener({
      mode: this.audioMode,
      isPlaying: this.currentMusicType !== null && this.audioMode === 'all',
      musicType: this.currentMusicType,
      isUnlocked: this.isAudioUnlocked
    });
    return () => {
      this.listeners = this.listeners.filter(l => l !== listener);
    };
  }

  private notifyListeners() {
    this.listeners.forEach(l => l({
      mode: this.audioMode,
      isPlaying: this.currentMusicType !== null && this.audioMode === 'all',
      musicType: this.currentMusicType,
      isUnlocked: this.isAudioUnlocked
    }));
  }

  public unlockAudio() {
    this.initCtx();
    if (this.ctx && this.ctx.state === 'suspended') {
      this.ctx.resume().then(() => {
        this.isAudioUnlocked = true;
        if (this.audioMode === 'all' && !this.currentMusicType) {
          this.startLobbyMusic();
        }
        this.notifyListeners();
      });
    } else if (this.ctx && this.ctx.state === 'running') {
      this.isAudioUnlocked = true;
      if (this.audioMode === 'all' && !this.currentMusicType) {
        this.startLobbyMusic();
      }
      this.notifyListeners();
    }
  }

  public setAudioMode(mode: AudioMode) {
    this.audioMode = mode;
    if (typeof window !== 'undefined') {
      localStorage.setItem('penalex_audio_mode', mode);
    }

    if (this.musicGain && this.ctx) {
      if (mode === 'all') {
        this.musicGain.gain.setValueAtTime(0.28 * this.volumeLevel, this.ctx.currentTime);
      } else {
        this.musicGain.gain.setValueAtTime(0, this.ctx.currentTime);
      }
    }

    if (mode === 'muted') {
      this.stopMusic(0.1);
    } else if (mode === 'all' && !this.currentMusicType) {
      this.startLobbyMusic();
    }

    this.notifyListeners();
  }

  public getAudioMode(): AudioMode {
    return this.audioMode;
  }

  public isUnlocked(): boolean {
    return this.isAudioUnlocked;
  }

  public getCurrentMusicType(): string | null {
    return this.currentMusicType;
  }

  public setVolume(vol: number) {
    this.volumeLevel = Math.max(0, Math.min(1, vol));
    if (this.masterGain && this.ctx) {
      this.masterGain.gain.setValueAtTime(this.volumeLevel, this.ctx.currentTime);
    }
  }

  public toggleNextMode(): AudioMode {
    const next: AudioMode = 
      this.audioMode === 'all' ? 'sfx_only' :
      this.audioMode === 'sfx_only' ? 'muted' : 'all';
    this.setAudioMode(next);
    return next;
  }

  public initCtx() {
    if (!this.ctx && typeof window !== 'undefined') {
      const AudioContextClass = window.AudioContext || (window as any).webkitAudioContext;
      if (AudioContextClass) {
        this.ctx = new AudioContextClass();

        // Node routing hierarchy
        this.masterGain = this.ctx.createGain();
        this.musicGain = this.ctx.createGain();
        this.sfxGain = this.ctx.createGain();
        this.voiceGain = this.ctx.createGain();

        this.masterGain.gain.value = this.volumeLevel;
        this.musicGain.gain.value = this.audioMode === 'all' ? 0.28 : 0;
        this.sfxGain.gain.value = this.audioMode === 'muted' ? 0 : 0.85;
        this.voiceGain.gain.value = this.audioMode === 'muted' ? 0 : 0.95;

        this.musicGain.connect(this.masterGain);
        this.sfxGain.connect(this.masterGain);
        this.voiceGain.connect(this.masterGain);
        this.masterGain.connect(this.ctx.destination);
      }
    }
    if (this.ctx && this.ctx.state === 'suspended') {
      this.ctx.resume();
    }
  }

  // =========================================================================
  // 🎻 BANDA SONORA CINEMATOGRÁFICA (Continuous Polyphonic Looping Orchestral Engine)
  // =========================================================================

  /**
   * Lobby Theme: Solemn, majestic orchestral score (The Godfather / The Crown / Genshin Court)
   * Minor-to-major noble progression (D minor -> Bb -> G minor -> A7 -> Dm)
   */
  public startLobbyMusic() {
    if (this.audioMode !== 'all') return;
    if (this.currentMusicType === 'lobby') return;
    this.stopMusic(0.3);

    this.initCtx();
    if (!this.ctx || !this.musicGain) return;

    this.currentMusicType = 'lobby';
    this.notifyListeners();

    // Cinematic chord roots and lush arpeggios
    const chords = [
      { bass: 73.42, padNotes: [220, 261.63, 329.63, 440], harpNotes: [220, 261.63, 329.63, 440, 523.25, 659.25] }, // Dm
      { bass: 58.27, padNotes: [233.08, 293.66, 349.23, 466.16], harpNotes: [233.08, 293.66, 349.23, 466.16, 587.33] }, // Bb
      { bass: 49.00, padNotes: [196, 246.94, 293.66, 392], harpNotes: [196, 246.94, 293.66, 392, 493.88, 587.33] }, // Gm
      { bass: 55.00, padNotes: [220, 277.18, 329.63, 440], harpNotes: [220, 277.18, 329.63, 440, 554.37, 659.25] }, // A7
    ];

    let chordIndex = 0;
    let step = 0;

    const playBgmStep = () => {
      if (!this.ctx || !this.musicGain || this.currentMusicType !== 'lobby' || this.audioMode !== 'all') return;

      const now = this.ctx.currentTime;
      const currentChord = chords[chordIndex];

      // Warm orchestral string pad on first beat
      if (step === 0) {
        // Cello / Double Bass Sub-Harmonic
        const bassOsc = this.ctx.createOscillator();
        const bassFilter = this.ctx.createBiquadFilter();
        const bassGain = this.ctx.createGain();

        bassOsc.type = 'sawtooth';
        bassOsc.frequency.setValueAtTime(currentChord.bass, now);

        bassFilter.type = 'lowpass';
        bassFilter.frequency.setValueAtTime(220, now);

        bassGain.gain.setValueAtTime(0, now);
        bassGain.gain.linearRampToValueAtTime(0.2, now + 0.4);
        bassGain.gain.linearRampToValueAtTime(0.14, now + 2.0);
        bassGain.gain.linearRampToValueAtTime(0.001, now + 2.6);

        bassOsc.connect(bassFilter);
        bassFilter.connect(bassGain);
        bassGain.connect(this.musicGain);

        bassOsc.start(now);
        bassOsc.stop(now + 2.7);

        // Warm French Horn / Cello Chord (2 voices)
        currentChord.padNotes.slice(0, 2).forEach((padFreq) => {
          if (!this.ctx || !this.musicGain) return;
          const padOsc = this.ctx.createOscillator();
          const padGain = this.ctx.createGain();
          const padFilter = this.ctx.createBiquadFilter();

          padOsc.type = 'triangle';
          padOsc.frequency.setValueAtTime(padFreq, now);

          padFilter.type = 'lowpass';
          padFilter.frequency.setValueAtTime(600, now);

          padGain.gain.setValueAtTime(0, now);
          padGain.gain.linearRampToValueAtTime(0.09, now + 0.5);
          padGain.gain.linearRampToValueAtTime(0.06, now + 2.0);
          padGain.gain.linearRampToValueAtTime(0.001, now + 2.6);

          padOsc.connect(padFilter);
          padFilter.connect(padGain);
          padGain.connect(this.musicGain);

          padOsc.start(now);
          padOsc.stop(now + 2.7);
        });
      }

      // Delicate Harp / Glockenspiel Arpeggio
      const noteFreq = currentChord.harpNotes[step % currentChord.harpNotes.length];
      const arpOsc = this.ctx.createOscillator();
      const arpGain = this.ctx.createGain();

      arpOsc.type = 'sine';
      arpOsc.frequency.setValueAtTime(noteFreq, now);

      arpGain.gain.setValueAtTime(0, now);
      arpGain.gain.linearRampToValueAtTime(0.11, now + 0.03);
      arpGain.gain.exponentialRampToValueAtTime(0.001, now + 0.58);

      arpOsc.connect(arpGain);
      arpGain.connect(this.musicGain);

      arpOsc.start(now);
      arpOsc.stop(now + 0.6);

      step++;
      if (step >= 6) {
        step = 0;
        chordIndex = (chordIndex + 1) % chords.length;
      }
    };

    playBgmStep();
    this.bgmInterval = window.setInterval(playBgmStep, 450);
  }

  /**
   * Quiz Arena Theme: Tense suspense soundtrack with strings & deep bass
   */
  public startQuizMusic(urgency: number = 0) {
    if (this.audioMode !== 'all') return;
    this.stopMusic(0.2);

    this.initCtx();
    if (!this.ctx || !this.musicGain) return;

    this.currentMusicType = 'quiz';
    this.notifyListeners();

    // Tension progression in E minor (E - F - G - D#)
    const notes = [164.81, 174.61, 196.00, 155.56, 220.00, 246.94];
    let noteIdx = 0;

    const intervalMs = Math.max(200, 420 - urgency * 220);

    const playTensionStep = () => {
      if (!this.ctx || !this.musicGain || this.currentMusicType !== 'quiz' || this.audioMode !== 'all') return;

      const now = this.ctx.currentTime;
      const freq = notes[noteIdx % notes.length];

      // Staccato pizzicato pluck
      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();

      osc.type = 'sawtooth';
      osc.frequency.setValueAtTime(freq * (urgency > 0.6 ? 2 : 1), now);

      gain.gain.setValueAtTime(0, now);
      gain.gain.linearRampToValueAtTime(0.16 + urgency * 0.08, now + 0.02);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.22);

      osc.connect(gain);
      gain.connect(this.musicGain);

      osc.start(now);
      osc.stop(now + 0.24);

      // Low ominous sub-bass heartbeat pulse
      if (noteIdx % 2 === 0) {
        const subOsc = this.ctx.createOscillator();
        const subGain = this.ctx.createGain();

        subOsc.type = 'sine';
        subOsc.frequency.setValueAtTime(41.20, now); // Low E1

        subGain.gain.setValueAtTime(0.22 + urgency * 0.1, now);
        subGain.gain.exponentialRampToValueAtTime(0.001, now + 0.35);

        subOsc.connect(subGain);
        subGain.connect(this.musicGain);

        subOsc.start(now);
        subOsc.stop(now + 0.38);
      }

      noteIdx++;
    };

    playTensionStep();
    this.bgmInterval = window.setInterval(playTensionStep, intervalMs);
  }

  public updateQuizMusicUrgency(urgency: number) {
    if (this.currentMusicType === 'quiz') {
      this.startQuizMusic(urgency);
    }
  }

  public stopMusic(fadeDuration: number = 0.4) {
    if (this.bgmInterval) {
      clearInterval(this.bgmInterval);
      this.bgmInterval = null;
    }
    this.currentMusicType = null;
    this.notifyListeners();
  }

  // =========================================================================
  // 🔊 EFECTOS DE SONIDO REALISTAS & CANDY CRUSH JUICY SFX
  // =========================================================================

  /**
   * Candy Crush Star Pop Sound (Star 1, Star 2, Star 3 popping on victory)
   */
  public playStarPop(starNumber: number = 1) {
    if (this.audioMode === 'muted') return;
    this.initCtx();
    if (!this.ctx || !this.sfxGain) return;

    const freqs = [523.25, 659.25, 783.99]; // C5, E5, G5
    const freq = freqs[Math.min(2, Math.max(0, starNumber - 1))];
    const now = this.ctx.currentTime;

    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();

    osc.type = 'sine';
    osc.frequency.setValueAtTime(freq, now);
    osc.frequency.exponentialRampToValueAtTime(freq * 1.5, now + 0.12);

    gain.gain.setValueAtTime(0, now);
    gain.gain.linearRampToValueAtTime(0.4, now + 0.02);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.4);

    osc.connect(gain);
    gain.connect(this.sfxGain);

    osc.start(now);
    osc.stop(now + 0.42);

    // Sparkle shimmer
    setTimeout(() => {
      if (!this.ctx || !this.sfxGain) return;
      const shimmOsc = this.ctx.createOscillator();
      const shimmGain = this.ctx.createGain();
      const t = this.ctx.currentTime;

      shimmOsc.type = 'triangle';
      shimmOsc.frequency.setValueAtTime(freq * 2, t);
      shimmGain.gain.setValueAtTime(0.2, t);
      shimmGain.gain.exponentialRampToValueAtTime(0.001, t + 0.25);

      shimmOsc.connect(shimmGain);
      shimmGain.connect(this.sfxGain);
      shimmOsc.start(t);
      shimmOsc.stop(t + 0.26);
    }, 60);
  }

  /**
   * Candy Crush Jelly / Orb Bounce Sound (When clicking a level node)
   */
  public playOrbPop() {
    if (this.audioMode === 'muted') return;
    this.initCtx();
    if (!this.ctx || !this.sfxGain) return;

    const now = this.ctx.currentTime;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();

    osc.type = 'sine';
    osc.frequency.setValueAtTime(300, now);
    osc.frequency.exponentialRampToValueAtTime(680, now + 0.08);

    gain.gain.setValueAtTime(0.2, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.12);

    osc.connect(gain);
    gain.connect(this.sfxGain);

    osc.start(now);
    osc.stop(now + 0.13);
  }

  /**
   * Treasure Chest Open Fanfare (Cofre del Tesoro)
   */
  public playChestOpen() {
    if (this.audioMode === 'muted') return;
    this.initCtx();
    if (!this.ctx || !this.sfxGain) return;

    const notes = [440, 554.37, 659.25, 880];
    const now = this.ctx.currentTime;

    notes.forEach((f, i) => {
      if (!this.ctx || !this.sfxGain) return;
      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();

      osc.type = 'triangle';
      osc.frequency.setValueAtTime(f, now + i * 0.07);

      gain.gain.setValueAtTime(0, now + i * 0.07);
      gain.gain.linearRampToValueAtTime(0.3, now + i * 0.07 + 0.02);
      gain.gain.exponentialRampToValueAtTime(0.001, now + i * 0.07 + 0.45);

      osc.connect(gain);
      gain.connect(this.sfxGain);

      osc.start(now + i * 0.07);
      osc.stop(now + i * 0.07 + 0.48);
    });
  }

  /**
   * Shield Protect Success Sound
   */
  public playShieldSuccess() {
    if (this.audioMode === 'muted') return;
    this.initCtx();
    if (!this.ctx || !this.sfxGain) return;

    const now = this.ctx.currentTime;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();

    osc.type = 'sine';
    osc.frequency.setValueAtTime(523.25, now); // C5
    osc.frequency.exponentialRampToValueAtTime(1046.50, now + 0.35); // C6

    gain.gain.setValueAtTime(0.01, now);
    gain.gain.linearRampToValueAtTime(0.4, now + 0.05);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.5);

    osc.connect(gain);
    gain.connect(this.sfxGain);

    osc.start(now);
    osc.stop(now + 0.52);
  }

  /**
   * Authentic Gavel Strike (Golpe de Mazo Judicial):
   */
  public playGavelStrike() {
    if (this.audioMode === 'muted') return;
    this.initCtx();
    if (!this.ctx || !this.sfxGain) return;

    const now = this.ctx.currentTime;

    // Primary strike transient (hardwood thud)
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();

    osc.type = 'triangle';
    osc.frequency.setValueAtTime(160, now);
    osc.frequency.exponentialRampToValueAtTime(45, now + 0.15);

    gain.gain.setValueAtTime(0.85, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.28);

    osc.connect(gain);
    gain.connect(this.sfxGain);

    osc.start(now);
    osc.stop(now + 0.29);

    // Second bounce
    setTimeout(() => {
      if (!this.ctx || !this.sfxGain || this.audioMode === 'muted') return;
      const echoOsc = this.ctx.createOscillator();
      const echoGain = this.ctx.createGain();
      const echoTime = this.ctx.currentTime;

      echoOsc.type = 'triangle';
      echoOsc.frequency.setValueAtTime(120, echoTime);
      echoOsc.frequency.exponentialRampToValueAtTime(40, echoTime + 0.14);

      echoGain.gain.setValueAtTime(0.45, echoTime);
      echoGain.gain.exponentialRampToValueAtTime(0.001, echoTime + 0.22);

      echoOsc.connect(echoGain);
      echoGain.connect(this.sfxGain);

      echoOsc.start(echoTime);
      echoOsc.stop(echoTime + 0.23);
    }, 85);
  }

  /**
   * Correct Answer: Deep Bell Chime + Distant Courtroom Applause
   */
  public playCorrect() {
    if (this.audioMode === 'muted') return;
    this.initCtx();
    if (!this.ctx || !this.sfxGain) return;

    const now = this.ctx.currentTime;
    const notes = [523.25, 659.25, 783.99, 1046.50, 1318.51]; // C5, E5, G5, C6, E6

    notes.forEach((freq, idx) => {
      if (!this.ctx || !this.sfxGain) return;
      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();

      osc.type = 'sine';
      osc.frequency.setValueAtTime(freq, now + idx * 0.05);

      gain.gain.setValueAtTime(0, now + idx * 0.05);
      gain.gain.linearRampToValueAtTime(0.28, now + idx * 0.05 + 0.02);
      gain.gain.exponentialRampToValueAtTime(0.001, now + idx * 0.05 + 0.55);

      osc.connect(gain);
      gain.connect(this.sfxGain);

      osc.start(now + idx * 0.05);
      osc.stop(now + idx * 0.05 + 0.56);
    });

    // Distant applause
    const bufferSize = this.ctx.sampleRate * 0.6;
    const buffer = this.ctx.createBuffer(1, bufferSize, this.ctx.sampleRate);
    const data = buffer.getChannelData(0);
    for (let i = 0; i < bufferSize; i++) {
      data[i] = (Math.random() * 2 - 1) * Math.sin((i / bufferSize) * Math.PI) * 0.15;
    }

    const applause = this.ctx.createBufferSource();
    applause.buffer = buffer;

    const applauseFilter = this.ctx.createBiquadFilter();
    applauseFilter.type = 'bandpass';
    applauseFilter.frequency.setValueAtTime(1800, now);

    const applauseGain = this.ctx.createGain();
    applauseGain.gain.setValueAtTime(0.12, now);
    applauseGain.gain.exponentialRampToValueAtTime(0.001, now + 0.6);

    applause.connect(applauseFilter);
    applauseFilter.connect(applauseGain);
    applauseGain.connect(this.sfxGain);

    applause.start(now + 0.1);
  }

  public playWrong() {
    this.playGavelStrike();
    if (this.audioMode === 'muted') return;
    this.initCtx();
    if (!this.ctx || !this.sfxGain) return;

    const now = this.ctx.currentTime;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();

    osc.type = 'sawtooth';
    osc.frequency.setValueAtTime(230, now);
    osc.frequency.linearRampToValueAtTime(130, now + 0.35);

    gain.gain.setValueAtTime(0.28, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.38);

    osc.connect(gain);
    gain.connect(this.sfxGain);

    osc.start(now);
    osc.stop(now + 0.4);
  }

  public playLevelUp() {
    if (this.audioMode === 'muted') return;
    this.initCtx();
    if (!this.ctx || !this.sfxGain) return;

    this.playGong();

    const melody = [
      { f: 392.00, d: 0.14 }, // G4
      { f: 523.25, d: 0.14 }, // C5
      { f: 659.25, d: 0.14 }, // E5
      { f: 783.99, d: 0.38 }, // G5
      { f: 659.25, d: 0.14 }, // E5
      { f: 1046.50, d: 0.8 }  // C6
    ];

    let offset = 0.05;
    const start = this.ctx.currentTime;

    melody.forEach((note) => {
      if (!this.ctx || !this.sfxGain) return;
      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();

      osc.type = 'triangle';
      osc.frequency.setValueAtTime(note.f, start + offset);

      gain.gain.setValueAtTime(0, start + offset);
      gain.gain.linearRampToValueAtTime(0.35, start + offset + 0.02);
      gain.gain.exponentialRampToValueAtTime(0.001, start + offset + note.d);

      osc.connect(gain);
      gain.connect(this.sfxGain);

      osc.start(start + offset);
      osc.stop(start + offset + note.d + 0.05);

      offset += note.d * 0.82;
    });
  }

  public playFireBurn() {
    if (this.audioMode === 'muted') return;
    this.initCtx();
    if (!this.ctx || !this.sfxGain) return;

    const now = this.ctx.currentTime;
    const bufferSize = this.ctx.sampleRate * 0.55;
    const buffer = this.ctx.createBuffer(1, bufferSize, this.ctx.sampleRate);
    const data = buffer.getChannelData(0);
    for (let i = 0; i < bufferSize; i++) {
      data[i] = (Math.random() * 2 - 1) * Math.exp(-i / (bufferSize * 0.6));
    }

    const noise = this.ctx.createBufferSource();
    noise.buffer = buffer;

    const filter = this.ctx.createBiquadFilter();
    filter.type = 'bandpass';
    filter.frequency.setValueAtTime(1400, now);
    filter.frequency.linearRampToValueAtTime(350, now + 0.5);

    const gain = this.ctx.createGain();
    gain.gain.setValueAtTime(0.4, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.52);

    noise.connect(filter);
    filter.connect(gain);
    gain.connect(this.sfxGain);

    noise.start(now);
  }

  public playCrack() {
    if (this.audioMode === 'muted') return;
    this.initCtx();
    if (!this.ctx || !this.sfxGain) return;

    const now = this.ctx.currentTime;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();

    osc.type = 'sawtooth';
    osc.frequency.setValueAtTime(340, now);
    osc.frequency.exponentialRampToValueAtTime(50, now + 0.16);

    gain.gain.setValueAtTime(0.45, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.19);

    osc.connect(gain);
    gain.connect(this.sfxGain);

    osc.start(now);
    osc.stop(now + 0.2);
  }

  public playTicking(fast: boolean = false) {
    if (this.audioMode === 'muted') return;
    this.initCtx();
    if (!this.ctx || !this.sfxGain) return;

    const now = this.ctx.currentTime;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();

    osc.type = 'sine';
    osc.frequency.setValueAtTime(fast ? 1600 : 1000, now);
    osc.frequency.exponentialRampToValueAtTime(250, now + 0.03);

    gain.gain.setValueAtTime(fast ? 0.2 : 0.09, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.035);

    osc.connect(gain);
    gain.connect(this.sfxGain);

    osc.start(now);
    osc.stop(now + 0.04);
  }

  public playGong() {
    if (this.audioMode === 'muted') return;
    this.initCtx();
    if (!this.ctx || !this.sfxGain) return;

    const now = this.ctx.currentTime;
    const freqs = [82.4, 164.8, 246.9, 329.6, 493.8];

    freqs.forEach((f, idx) => {
      if (!this.ctx || !this.sfxGain) return;
      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();

      osc.type = idx === 0 ? 'triangle' : 'sine';
      osc.frequency.setValueAtTime(f, now);

      gain.gain.setValueAtTime(0.5 / (idx + 1), now);
      gain.gain.exponentialRampToValueAtTime(0.0001, now + 2.8);

      osc.connect(gain);
      gain.connect(this.sfxGain);

      osc.start(now);
      osc.stop(now + 2.9);
    });
  }

  public playAscent() {
    if (this.audioMode === 'muted') return;
    this.initCtx();
    if (!this.ctx || !this.sfxGain) return;

    const notes = [261.63, 329.63, 392.00, 523.25, 659.25, 783.99, 1046.50, 1318.51];
    const now = this.ctx.currentTime;

    notes.forEach((freq, i) => {
      if (!this.ctx || !this.sfxGain) return;
      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();

      osc.type = 'sine';
      osc.frequency.setValueAtTime(freq, now + i * 0.05);

      gain.gain.setValueAtTime(0, now + i * 0.05);
      gain.gain.linearRampToValueAtTime(0.18, now + i * 0.05 + 0.02);
      gain.gain.exponentialRampToValueAtTime(0.001, now + i * 0.05 + 0.45);

      osc.connect(gain);
      gain.connect(this.sfxGain);

      osc.start(now + i * 0.05);
      osc.stop(now + i * 0.05 + 0.48);
    });
  }

  public playScroll() {
    if (this.audioMode === 'muted') return;
    this.initCtx();
    if (!this.ctx || !this.sfxGain) return;

    const now = this.ctx.currentTime;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();

    osc.type = 'sine';
    osc.frequency.setValueAtTime(400, now);
    osc.frequency.exponentialRampToValueAtTime(920, now + 0.16);

    gain.gain.setValueAtTime(0.12, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.19);

    osc.connect(gain);
    gain.connect(this.sfxGain);

    osc.start(now);
    osc.stop(now + 0.2);
  }

  public playClick() {
    if (this.audioMode === 'muted') return;
    this.initCtx();
    if (!this.ctx || !this.sfxGain) return;

    const now = this.ctx.currentTime;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();

    osc.type = 'sine';
    osc.frequency.setValueAtTime(800, now);
    osc.frequency.exponentialRampToValueAtTime(200, now + 0.04);

    gain.gain.setValueAtTime(0.1, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.05);

    osc.connect(gain);
    gain.connect(this.sfxGain);

    osc.start(now);
    osc.stop(now + 0.05);
  }

  // =========================================================================
  // 🗣️ VOCES DEL NARRADOR JUDICIAL
  // =========================================================================

  public speakJudicial(phrase: string) {
    if (this.audioMode === 'muted') return;
    if (typeof window === 'undefined' || !('speechSynthesis' in window)) return;

    try {
      window.speechSynthesis.cancel();

      const utterance = new SpeechSynthesisUtterance(phrase);
      utterance.lang = 'es-VE';
      utterance.pitch = 0.82;
      utterance.rate = 0.96;
      utterance.volume = 1.0;

      const voices = window.speechSynthesis.getVoices();
      const spanishVoice = voices.find(v => v.lang.startsWith('es') && (v.name.includes('Male') || v.name.includes('Jorge') || v.name.includes('Diego') || v.name.includes('Carlos') || v.name.includes('Natural')));
      if (spanishVoice) {
        utterance.voice = spanishVoice;
      }

      if (this.musicGain && this.ctx && this.audioMode === 'all') {
        this.musicGain.gain.setValueAtTime(0.06, this.ctx.currentTime);
        utterance.onend = () => {
          if (this.musicGain && this.ctx && this.audioMode === 'all') {
            this.musicGain.gain.setValueAtTime(0.28 * this.volumeLevel, this.ctx.currentTime);
          }
        };
      }

      window.speechSynthesis.speak(utterance);
    } catch (e) {
      console.warn('SpeechSynthesis error:', e);
    }
  }

  public voiceWelcome(name: string) {
    this.speakJudicial(`¡Bienvenido a la Sala Magna, jurista ${name}!`);
  }

  public voiceCorrect() {
    const lines = [
      "¡Veredicto correcto! Fundamentación jurídica ratificada.",
      "¡Procedente! El tribunal valida tu respuesta.",
      "¡Ajustado a derecho! Continúa el ascenso."
    ];
    this.speakJudicial(lines[Math.floor(Math.random() * lines.length)]);
  }

  public voiceWrong() {
    const lines = [
      "¡Veredicto errado! Se declara sin lugar.",
      "¡Incorrecto! Apelación desestimada.",
      "¡Vicio procesal! Mazo en estrado."
    ];
    this.speakJudicial(lines[Math.floor(Math.random() * lines.length)]);
  }

  public voiceLevelUp(rankTitle: string) {
    this.speakJudicial(`¡Nivel superado! Nuevo rango judicial conferido: ${rankTitle}.`);
  }

  public voiceAppealLost() {
    this.speakJudicial("¡Apelación consumida! Se quema el pergamino.");
  }

  public voiceTimeOut() {
    this.speakJudicial("¡Tiempo procesal expirado en sala!");
  }
}

export const sounds = new SoundEffectsEngine();
