/**
 * Dual Static-Symmetry Audio-Reactive Mandala - Heartbeat Focus (p5.js WebGL Port)
 * Version: 2026.09.30.17.33.11
 * ------------------------------------------------------------------------
 * Technique: Buffer-mapped vertical oscilloscope rendering with custom WebGL GLSL shaders.
 * Update: Boomerang Morphing Engine. ARM_OSCILLATION and STARBURST_ARM_WIDTH 
 * now oscillate between Min/Max bounds at a dedicated MORPH_SPEED.
 * Features:
 * - Morphing: Uses sin(progress * speed) for seamless boomeranging.
 * - Background Lock: Palette index 0 remains static for background.
 * - Dynamic Stop: Hard termination at pre-calculated MAX_FRAMES.
 * - Elastic Pond Rings: Sharp, rubber-band style pulsing.
 * - Audio Compatibility: Seamless support for p5.sound, native Web Audio API, and OpenProcessing.
 * ------------------------------------------------------------------------
 * Audio Track Credit:
 * "islandman.mp3" - Sumeru by Islandman ‧ 2019
 * ------------------------------------------------------------------------
 */

// --- Global Parameters ---
let AUDIO_FILE = 'islandman.mp3'; // default: 'islandman.mp3'
let SKETCH_WIDTH = 480;      // default: 480
let SKETCH_HEIGHT = 800;     // default: 800
let SEED_VALUE = 42;         // default: 42
let PADDING = 40;            // default: 40
let MAX_FRAMES;              // Pre-calculated in setup based on audio length
let SAVE_FRAMES = false;     // default: false (Set TRUE for frame-locked disk export)
let ANIMATION_SPEED = 30;    // default: 30 fps
let PALETTE_INDEX = 1;       // default: 1
let INVERT_BG = false;       // default: false (Toggle background color inversion)

// --- Visibility Toggles ---
let SHOW_M1 = true;        // default: true (Mandala 1 visibility)
let SHOW_M2 = true;        // default: true (Mandala 2 visibility)
let BEAT_PULSE_BG = false; // default: false (Background brightness pulse)
let SHOW_STRANDS = true;   // default: true (Toggle connecting EKG strand)

// --- Progression Parameters ---
let SPIN_SPEED = 0.5;         // default: 0.5 (Base rotation velocity)
let SPIRAL_TWIST = 3.2;       // default: 3.2 (User refined)
let JITTER_DURATION = 90;     // default: 90 (Frames to hold asymmetric peak bias)
let COLOR_CYCLE_SPEED = 30.0; // default: 30.5 (Rapid palette shifting)
let MORPH_SPEED = 5.0;        // default: 5.0 (Boomerang speed for oscillation/width)
let FREQ_SMOOTHING = 0.15;    // default: 0.15 (Ease-out factor for AGC band values)
let NOISE_FLOOR = 0.0001;     // default: 0.0001 (Noise gate for motion)

// --- Frequency Strength Parameters ---
let BASS_STRENGTH = 0.02;      // User refined: 0.02
let MID_STRENGTH = 0.004;      // User refined: 0.004
let TREBLE_STRENGTH = 0.004;   // User refined: 0.004
let RIPPLE_STRENGTH = 25.0;    // default: 25.0 (Multiplier for elastic pond rings)

// --- Visual Style Parameters ---
let GLOW_STRENGTH = 1.5;     // default: 1.5 (Overall brightness multiplier)
let STRAND_WIDTH = 0.002;    // default: 0.002 (EKG line thickness)

// --- Mandala Parameters ---
let MANDALA_DIAMETER = 0.85; // default: 0.85

// --- Morphing Parameter Bounds ---
let STARBURST_ARM_WIDTH_MIN = 0.02; // Initial default
let STARBURST_ARM_WIDTH_MAX = 0.20; // User refined max
let ARM_OSCILLATION_MIN = 20.0;     // Low frequency wave
let ARM_OSCILLATION_MAX = 50.0;     // User refined high frequency

let NODE_DISTORTION = 0.5;       // default: 0.5 (Bead spacing)
let MAX_RIPPLE_DIAMETER = 0.4;   // default: 0.4 (Pond ring limit)
let RIPPLE_COUNT = 1;            // default: 1 (Number of elastic rings)

// --- Fixed Symmetry ---
let TOP_SYMMETRY = 11.0;
let BOT_SYMMETRY = 9.0;

// --- Positions (Normalized 0.0 - 1.0) ---
let CENTER_T_X = 0.5;
let CENTER_T_Y = 0.72;
let CENTER_B_X = 0.5;
let CENTER_B_Y = 0.28;

// --- 10-Color Palettes (from Adobe Kuler / Color Themes) ---
// Palette 0: Crimson Velvet / Dark Berry
// Palette 1: Midnight Gold / Cyber Sunset
// Palette 2: Neon Cyberpunk / Electric Dream
// Palette 3: Crimson Slate / Modern Minimal
// Palette 4: Emerald Forest / Mint Fade
const PALETTES = [
  ["#1a091a", "#2e112d", "#540032", "#820333", "#c02739", "#e71d36", "#ff5d5d", "#ff9191", "#f1e4e8", "#ffffff"],
  ["#000814", "#001d3d", "#003566", "#ffc300", "#ffd60a", "#fb8500", "#ffb703", "#8ecae6", "#219ebc", "#023047"],
  ["#011627", "#2ec4b6", "#e71d36", "#ff9f1c", "#fdfffc", "#011627", "#2ec4b6", "#e71d36", "#ff9f1c", "#fdfffc"],
  ["#2b2d42", "#8D99AE", "#edf2f4", "#ef233c", "#d90429", "#2b2d42", "#8d99ae", "#edf2f4", "#ef233c", "#d90429"],
  ["#1b4332", "#2d6a4f", "#40916c", "#52b788", "#74c69d", "#95d5b2", "#b7e4c7", "#d8f3dc", "#081c15", "#ffffff"]
];

// --- Engine Objects ---
let song = null;
let audioEngine = null;
let dualShader;

let shaderColors = new Float32Array(30);
let waveJitterX = 0.5;
let jitterDir = 1.0;
let jitterCounter = 0;

// Runtime Calculated Morph values
let currentArmWidth, currentArmOsc;

// AGC internal state
let bandBass = 0.0, bandMid = 0.0, bandTreble = 0.0;
let peakBass = 0.01, peakMid = 0.01, peakTreble = 0.01;

// --- GLSL Shaders ---
const vertSource = `
#ifdef GL_ES
precision highp float;
#endif

attribute vec3 aPosition;

void main() {
  gl_Position = vec4(aPosition.xy, 0.0, 1.0);
}
`;

const fragSource = `
#ifdef GL_ES
precision highp float;
#endif

uniform vec2 u_resolution;
uniform float u_loopProgress;
uniform float u_topSectors;
uniform float u_botSectors;
uniform vec3 u_palette[10];
uniform float u_audioIntensity;
uniform float u_waveVal;
uniform float u_jitterDir;
uniform float u_bandBass;
uniform float u_bandMid;
uniform float u_bandTreble;
uniform float u_rippleStrength;
uniform int u_rippleCount;
uniform float u_diameter;
uniform float u_maxRipple;
uniform float u_spiral;
uniform float u_armWidth;
uniform float u_armOscillation;
uniform float u_distortion;
uniform float u_colorCycleSpeed;
uniform float u_glow;
uniform float u_strandWidth;
uniform vec2 u_centerT;
uniform vec2 u_centerB;
uniform bool u_showM1;
uniform bool u_showM2;
uniform bool u_showStrands;

vec3 getPaletteColor(int idx) {
  if (idx == 0) return u_palette[0];
  if (idx == 1) return u_palette[1];
  if (idx == 2) return u_palette[2];
  if (idx == 3) return u_palette[3];
  if (idx == 4) return u_palette[4];
  if (idx == 5) return u_palette[5];
  if (idx == 6) return u_palette[6];
  if (idx == 7) return u_palette[7];
  if (idx == 8) return u_palette[8];
  return u_palette[9];
}

vec3 getSmoothColor(float offset, float dir) {
  float cycle = u_loopProgress * u_colorCycleSpeed * 10.0;
  float t = mod(cycle * dir + offset, 9.0);
  int i0 = int(t) + 1;
  int i1 = (i0 >= 9) ? 1 : i0 + 1;
  return mix(getPaletteColor(i0), getPaletteColor(i1), fract(t));
}

vec3 renderMandala(vec2 uv, vec2 center, float sectors, float isSpiral, float spinDir) {
  float aspect = u_resolution.x / u_resolution.y;
  vec2 p_uv = (uv - center);
  p_uv.y /= aspect;
  float r = length(p_uv) * 2.5;
  if (r > 1.4) return vec3(0.0);
  
  float a = atan(p_uv.y, p_uv.x); 
  float phi = a + (u_loopProgress * 6.2831853 * spinDir) + (r * u_spiral * isSpiral);
  float s = 6.2831853 / sectors;
  float folded_a = abs(mod(phi + 3.14159265, s) - s * 0.5);
  vec2 p = vec2(cos(folded_a), sin(folded_a)) * r;
  
  float centerRingRadius = 0.12 + u_audioIntensity * 0.2;
  float rings = 0.0;
  for(int i = 1; i <= 10; i++) {
    if (i > u_rippleCount) break;
    float elasticRadius = centerRingRadius + (abs(u_waveVal) * u_rippleStrength * float(i) * 0.05);
    rings += 0.001 / (abs(r - clamp(elasticRadius, centerRingRadius, u_maxRipple)) + 0.0003);
  }
  
  float ring1 = abs(r - centerRingRadius);
  float arms = abs(p.y - (u_armWidth + sin(r * u_armOscillation - u_loopProgress * 50.0) * 0.01));
  float beads = length(vec2(mod(r, 0.15 * u_distortion) - 0.075, p.y)) - (0.01 + u_audioIntensity * 0.03);
  
  vec3 col = vec3(0.0);
  col += getSmoothColor(2.0, spinDir) * (0.005 / arms);
  col += getSmoothColor(5.0, spinDir) * (0.004 / ring1);
  col += getSmoothColor(8.0, spinDir) * (0.003 / abs(beads));
  col += getSmoothColor(3.0, spinDir) * rings; 
  col += getSmoothColor(0.0, spinDir) * (0.015 / (r + 0.05));
  return col * u_glow * smoothstep(u_diameter, u_diameter * 0.7, r);
}

void main() {
  vec2 uv = gl_FragCoord.xy / u_resolution.xy;
  vec3 col = vec3(0.0);
  if(u_showM1) col += renderMandala(uv, u_centerT, u_topSectors, 0.0, 1.0);
  if(u_showM2) col += renderMandala(uv, u_centerB, u_botSectors, 1.0, -1.0);
  
  if(u_showStrands) {
    float yLow = min(u_centerB.y, u_centerT.y);
    float yHigh = max(u_centerB.y, u_centerT.y);
    if(uv.y >= yLow && uv.y <= yHigh) {
      float localY = (uv.y - yLow) / (yHigh - yLow);
      float bMix = mix(u_bandBass, u_bandMid, smoothstep(0.1, 0.5, localY));
      bMix = mix(bMix, u_bandTreble, smoothstep(0.5, 0.9, localY));
      float rawWave = sin(uv.y * 50.0 + u_loopProgress * 62.83);
      float peakBias = (u_jitterDir > 0.0) ? (rawWave > 0.0 ? 4.0 : 0.5) : (rawWave < 0.0 ? 4.0 : 0.5);
      float heartbeat = 0.5 + (rawWave * peakBias * u_waveVal * (bMix * 10.0));
      col += getSmoothColor(5.0, 1.0) * (u_strandWidth / abs(uv.x - heartbeat)) * u_glow;
    }
  }
  gl_FragColor = vec4(col * (1.0 + u_audioIntensity), 1.0);
}
`;

// --- Cross-Platform Audio Engine (supports p5.sound, Web Audio API, or fallback) ---
class AudioEngine {
  constructor() {
    this.mode = 'none';
    this.p5fft = null;
    this.audioCtx = null;
    this.analyser = null;
    this.audioEl = null;
    this.freqData = null;
    this.timeData = null;

    if (typeof p5 !== 'undefined' && typeof p5.FFT === 'function') {
      try {
        this.p5fft = new p5.FFT(0.8, 1024);
        this.mode = 'p5sound';
      } catch (e) {
        this.mode = 'none';
      }
    }
  }

  async init(src) {
    if (this.mode === 'p5sound') {
      try {
        if (typeof loadSound === 'function') {
          song = await loadSound(src);
          if (song && typeof song.play === 'function') {
            song.play();
          }
          return;
        }
      } catch (e) {
        console.warn('p5.sound load failed, using Web Audio:', e);
      }
    }

    try {
      const AudioCtxClass = window.AudioContext || window.webkitAudioContext;
      if (AudioCtxClass) {
        this.audioCtx = new AudioCtxClass();
        this.analyser = this.audioCtx.createAnalyser();
        this.analyser.fftSize = 1024;
        this.analyser.smoothingTimeConstant = 0.8;
        this.freqData = new Uint8Array(this.analyser.frequencyBinCount);
        this.timeData = new Uint8Array(this.analyser.fftSize);

        this.audioEl = new Audio(src);
        this.audioEl.crossOrigin = 'anonymous';
        this.audioEl.loop = false;

        // Wait for metadata to ensure exact duration is known
        await new Promise((resolve) => {
          let resolved = false;
          const done = () => {
            if (!resolved) {
              resolved = true;
              resolve();
            }
          };
          this.audioEl.addEventListener('loadedmetadata', done, { once: true });
          this.audioEl.addEventListener('canplaythrough', done, { once: true });
          this.audioEl.addEventListener('error', done, { once: true });
          setTimeout(done, 2000);
        });

        const source = this.audioCtx.createMediaElementSource(this.audioEl);
        source.connect(this.analyser);
        this.analyser.connect(this.audioCtx.destination);
        this.mode = 'webaudio';
        song = this.audioEl;
      }
    } catch (e) {
      console.warn('Web Audio initialization error:', e);
      this.mode = 'fallback';
    }
  }

  play() {
    if (this.mode === 'p5sound' && song && typeof song.play === 'function') {
      if (typeof userStartAudio === 'function') userStartAudio();
      if (!song.isPlaying()) song.play();
    } else if (this.mode === 'webaudio') {
      if (this.audioCtx && this.audioCtx.state === 'suspended') {
        this.audioCtx.resume();
      }
      if (this.audioEl && this.audioEl.paused) {
        this.audioEl.play().catch(() => { });
      }
    }
  }

  stop() {
    if (this.mode === 'p5sound' && song && typeof song.stop === 'function') {
      song.stop();
    } else if (this.audioEl) {
      this.audioEl.pause();
    }
  }

  analyze() {
    if (this.mode === 'p5sound' && this.p5fft) {
      this.p5fft.analyze();
    } else if (this.mode === 'webaudio' && this.analyser) {
      this.analyser.getByteFrequencyData(this.freqData);
    }
  }

  getEnergy(lowFreq, highFreq) {
    if (this.mode === 'p5sound' && this.p5fft) {
      return this.p5fft.getEnergy(lowFreq, highFreq) / 255.0;
    }
    if (this.mode === 'webaudio' && this.freqData && this.audioCtx) {
      let nyquist = this.audioCtx.sampleRate / 2;
      let lowIndex = Math.floor((lowFreq / nyquist) * this.freqData.length);
      let highIndex = Math.min(Math.ceil((highFreq / nyquist) * this.freqData.length), this.freqData.length - 1);
      if (lowIndex > highIndex) lowIndex = highIndex;
      let sum = 0;
      let count = highIndex - lowIndex + 1;
      for (let i = lowIndex; i <= highIndex; i++) {
        sum += this.freqData[i];
      }
      return (sum / count) / 255.0;
    }
    return 0.0;
  }

  getWaveVal(frameIdx) {
    if (this.mode === 'p5sound' && this.p5fft) {
      let wf = this.p5fft.waveform();
      return (wf && wf.length > 0) ? wf[frameIdx % wf.length] : 0.0;
    }
    if (this.mode === 'webaudio' && this.analyser) {
      this.analyser.getByteTimeDomainData(this.timeData);
      let idx = frameIdx % this.timeData.length;
      return (this.timeData[idx] - 128) / 128.0;
    }
    return 0.0;
  }

  restart() {
    if (this.mode === 'p5sound' && song) {
      if (typeof userStartAudio === 'function') userStartAudio();
      if (typeof song.jump === 'function') {
        song.jump(0);
      } else if (typeof song.stop === 'function') {
        song.stop();
      }
      if (typeof song.play === 'function') song.play();
    } else if (this.mode === 'webaudio') {
      if (this.audioCtx && this.audioCtx.state === 'suspended') {
        this.audioCtx.resume();
      }
      if (this.audioEl) {
        this.audioEl.currentTime = 0;
        this.audioEl.play().catch(() => { });
      }
    }
  }

  getDuration() {
    if (song && typeof song.duration === 'function') {
      let d = song.duration();
      if (!isNaN(d) && d > 0) return d;
    }
    if (this.audioEl && !isNaN(this.audioEl.duration) && this.audioEl.duration > 0) {
      return this.audioEl.duration;
    }
    return 0;
  }
}

async function setup() {
  createCanvas(SKETCH_WIDTH, SKETCH_HEIGHT, WEBGL);
  randomSeed(SEED_VALUE);
  frameRate(ANIMATION_SPEED);
  pixelDensity(displayDensity());

  audioEngine = new AudioEngine();
  await audioEngine.init(AUDIO_FILE);

  let durationSeconds = audioEngine.getDuration();
  MAX_FRAMES = durationSeconds > 0 ? Math.floor(durationSeconds * ANIMATION_SPEED) : 0;

  console.log("--- Audio Engine Loaded ---");
  console.log("FPS: " + ANIMATION_SPEED + " | Target Limit: " + (MAX_FRAMES > 0 ? MAX_FRAMES : "Awaiting metadata"));
  console.log("---------------------------");

  dualShader = createShader(vertSource, fragSource);
}

function hexToRgb(hexStr) {
  let c = color(hexStr);
  return [red(c) / 255.0, green(c) / 255.0, blue(c) / 255.0];
}

function updatePalette() {
  let pIdx = PALETTE_INDEX % PALETTES.length;
  for (let i = 0; i < 10; i++) {
    let rgb = hexToRgb(PALETTES[pIdx][i]);
    shaderColors[i * 3] = rgb[0];
    shaderColors[i * 3 + 1] = rgb[1];
    shaderColors[i * 3 + 2] = rgb[2];
  }
}

function draw() {
  // Dynamically calibrate MAX_FRAMES once audio duration metadata is available
  if (audioEngine) {
    let d = audioEngine.getDuration();
    if (d > 0) {
      let targetFrames = Math.floor(d * ANIMATION_SPEED);
      if (MAX_FRAMES !== targetFrames) {
        MAX_FRAMES = targetFrames;
      }
    }
  }

  if (MAX_FRAMES > 0 && frameCount >= MAX_FRAMES) {
    if (audioEngine) audioEngine.stop();
    noLoop();
    return;
  }

  let totalFrames = MAX_FRAMES > 0 ? MAX_FRAMES : (ANIMATION_SPEED * 30);
  let progress = (frameCount % totalFrames) / totalFrames;

  // Calculate Boomerang Morphing (Sine-based for smooth ping-pong)
  let morphFactor = (sin(progress * TWO_PI * MORPH_SPEED) + 1.0) * 0.5;
  currentArmWidth = lerp(STARBURST_ARM_WIDTH_MIN, STARBURST_ARM_WIDTH_MAX, morphFactor);
  currentArmOsc = lerp(ARM_OSCILLATION_MIN, ARM_OSCILLATION_MAX, morphFactor);

  let rawB = 0.0, rawM = 0.0, rawT = 0.0;
  let waveVal = 0.0;

  if (audioEngine) {
    audioEngine.analyze();
    rawB = audioEngine.getEnergy(20, 200);
    rawM = audioEngine.getEnergy(200, 2000);
    rawT = audioEngine.getEnergy(2000, 10000);
    waveVal = audioEngine.getWaveVal(frameCount);
  }

  if (rawB + rawM + rawT < NOISE_FLOOR) {
    rawB = 0.0;
    rawM = 0.0;
    rawT = 0.0;
  }

  peakBass = max(peakBass * 0.99, rawB);
  peakMid = max(peakMid * 0.99, rawM);
  peakTreble = max(peakTreble * 0.99, rawT);

  bandBass = lerp(bandBass, (rawB / (peakBass + 0.001)) * BASS_STRENGTH, FREQ_SMOOTHING);
  bandMid = lerp(bandMid, (rawM / (peakMid + 0.001)) * MID_STRENGTH, FREQ_SMOOTHING);
  bandTreble = lerp(bandTreble, (rawT / (peakTreble + 0.001)) * TREBLE_STRENGTH, FREQ_SMOOTHING);

  let intensity = (bandBass + bandMid + bandTreble) * 0.05;

  updatePalette();

  let baseR = shaderColors[0] * 255;
  let baseG = shaderColors[1] * 255;
  let baseB = shaderColors[2] * 255;
  if (INVERT_BG) {
    baseR = 255 - baseR;
    baseG = 255 - baseG;
    baseB = 255 - baseB;
  }
  background(baseR, baseG, baseB);

  jitterCounter++;
  if (jitterCounter >= JITTER_DURATION) {
    jitterDir = random(1.0) > 0.5 ? 1.0 : -1.0;
    jitterCounter = 0;
  }

  shader(dualShader);

  dualShader.setUniform("u_resolution", [width * pixelDensity(), height * pixelDensity()]);
  dualShader.setUniform("u_loopProgress", progress);
  dualShader.setUniform("u_topSectors", TOP_SYMMETRY);
  dualShader.setUniform("u_botSectors", BOT_SYMMETRY);
  dualShader.setUniform("u_audioIntensity", intensity);
  dualShader.setUniform("u_waveVal", waveVal);
  dualShader.setUniform("u_jitterDir", jitterDir);
  dualShader.setUniform("u_bandBass", bandBass);
  dualShader.setUniform("u_bandMid", bandMid);
  dualShader.setUniform("u_bandTreble", bandTreble);
  dualShader.setUniform("u_rippleStrength", RIPPLE_STRENGTH);
  dualShader.setUniform("u_rippleCount", RIPPLE_COUNT);
  dualShader.setUniform("u_diameter", MANDALA_DIAMETER);
  dualShader.setUniform("u_maxRipple", MAX_RIPPLE_DIAMETER);
  dualShader.setUniform("u_spiral", SPIRAL_TWIST);
  dualShader.setUniform("u_armWidth", currentArmWidth);
  dualShader.setUniform("u_armOscillation", currentArmOsc);
  dualShader.setUniform("u_distortion", NODE_DISTORTION);
  dualShader.setUniform("u_colorCycleSpeed", COLOR_CYCLE_SPEED);
  dualShader.setUniform("u_glow", GLOW_STRENGTH);
  dualShader.setUniform("u_strandWidth", STRAND_WIDTH);
  dualShader.setUniform("u_centerT", [CENTER_T_X, CENTER_T_Y]);
  dualShader.setUniform("u_centerB", [CENTER_B_X, CENTER_B_Y]);
  dualShader.setUniform("u_showM1", SHOW_M1);
  dualShader.setUniform("u_showM2", SHOW_M2);
  dualShader.setUniform("u_showStrands", SHOW_STRANDS);
  dualShader.setUniform("u_palette", shaderColors);

  // Full-screen quad centered on canvas in WebGL mode
  quad(-1, -1, 1, -1, 1, 1, -1, 1);
  resetShader();

  if (SAVE_FRAMES) {
    saveCanvas(`frames/frame_${nf(frameCount, 4)}.png`);
  }
}

function mousePressed() {
  frameCount = 0;
  randomSeed(SEED_VALUE);
  jitterCounter = 0;
  jitterDir = 1.0;
  peakBass = 0.01;
  peakMid = 0.01;
  peakTreble = 0.01;
  bandBass = 0.0;
  bandMid = 0.0;
  bandTreble = 0.0;

  if (audioEngine) {
    audioEngine.restart();
  }
  loop();
}

