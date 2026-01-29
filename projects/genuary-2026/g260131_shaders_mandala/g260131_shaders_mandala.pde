/**
 * Dual Static-Symmetry Audio-Reactive Mandala - Heartbeat Focus
 * Version: 2026.01.29.14.48.15
 * ------------------------------------------------------------------------
 * Technique: Buffer-mapped vertical oscilloscope rendering.
 * Fix: COLOR_CYCLE_SPEED now correctly scales the rate of color transitions.
 * Fix: Background color (index 0) remains static; elements cycle indices 1-9.
 * Features:
 * - Dynamic Stop: Termination at MAX_FRAMES (synced to 30 FPS).
 * - Multi-Band Rings: Elastic rings reacting to raw wave data.
 * - AGC Normalization: Ensures consistent movement across the track.
 * ------------------------------------------------------------------------
 */

import ddf.minim.*;
import ddf.minim.analysis.*;

// --- Global Parameters ---
int SKETCH_WIDTH = 480;      // default: 480
int SKETCH_HEIGHT = 800;     // default: 800
int SEED_VALUE = 42;         // default: 42
int PADDING = 40;            // default: 40
int MAX_FRAMES;              // Pre-calculated in setup based on audio length
boolean SAVE_FRAMES = false; // default: false
int ANIMATION_SPEED = 30;    // default: 30 fps
int PALETTE_INDEX = 1;       // default: 1
boolean INVERT_BG = false;   // default: false (Toggle background color inversion)

// --- Visibility Toggles ---
boolean SHOW_M1 = true;        // default: true
boolean SHOW_M2 = true;        // default: true
boolean BEAT_PULSE_BG = false; // default: false
boolean SHOW_STRANDS = true;   // default: true

// --- Progression Parameters ---
float SPIN_SPEED = 0.5;         // default: 0.5 (Base rotation velocity)
float SPIRAL_TWIST = 3.2;       // default: 1.2 (Spiral factor for mandala arms)
int JITTER_DURATION = 90;       // default: 90 (Frames to hold asymmetric peak bias)
float COLOR_CYCLE_SPEED = 30.5;  // default: 1.5 (Rate of color index rotation)
float FREQ_SMOOTHING = 0.15;    // default: 0.15 (Ease-out factor for AGC band values)
float NOISE_FLOOR = 0.0001;     // default: 0.0001 (Noise gate for motion)

// --- Frequency Strength Parameters ---
float BASS_STRENGTH = 0.02;      // Scaled for direct visibility
float MID_STRENGTH = 0.004;       // Scaled for direct visibility
float TREBLE_STRENGTH = 0.004;    // Scaled for direct visibility
float RIPPLE_STRENGTH = 25.0;   // default: 25.0 (Multiplier for elastic pond rings)

// --- Visual Style Parameters ---
float GLOW_STRENGTH = 1.5;     // default: 1.5 (Overall brightness multiplier)
float STRAND_WIDTH = 0.002;    // default: 0.002 (EKG line thickness)

// --- Mandala Parameters ---
float MANDALA_DIAMETER = 0.85;     // default: 0.85
float STARBURST_ARM_WIDTH = 0.02;  // default: 0.02
float ARM_OSCILLATION = 20.0;      // default: 20.0 (Wave frequency on arms)
float NODE_DISTORTION = 0.5;       // default: 0.5 (Bead spacing; valid range 0.1-3.0)
float MAX_RIPPLE_DIAMETER = 0.4;   // default: 0.4
int RIPPLE_COUNT = 1;              // default: 1

// --- Fixed Symmetry ---
float TOP_SYMMETRY = 11.0;   
float BOT_SYMMETRY = 9.0;    

// --- Positions ---
float CENTER_T_X = 0.5;      
float CENTER_T_Y = 0.72;     
float CENTER_B_X = 0.5;      
float CENTER_B_Y = 0.28;     

// --- 10-Color Palettes (Adobe Kuler inspired) ---
String[][] PALETTES = {
  {"#1a091a", "#2e112d", "#540032", "#820333", "#c02739", "#e71d36", "#ff5d5d", "#ff9191", "#f1e4e8", "#ffffff"}, 
  {"#000814", "#001d3d", "#003566", "#ffc300", "#ffd60a", "#fb8500", "#ffb703", "#8ecae6", "#219ebc", "#023047"}, 
  {"#011627", "#2ec4b6", "#e71d36", "#ff9f1c", "#fdfffc", "#011627", "#2ec4b6", "#e71d36", "#ff9f1c", "#fdfffc"}, 
  {"#2b2d42", "#8D99AE", "#edf2f4", "#ef233c", "#d90429", "#2b2d42", "#8d99ae", "#edf2f4", "#ef233c", "#d90429"}, 
  {"#1b4332", "#2d6a4f", "#40916c", "#52b788", "#74c69d", "#95d5b2", "#b7e4c7", "#d8f3dc", "#081c15", "#ffffff"}  
};

Minim minim;
AudioPlayer song;
FFT fft;
PShader dualShader;

float[] shaderColors = new float[30]; 
float waveJitterX = 0.5; 
float jitterDir = 1.0;
int jitterCounter = 0;

float bandBass, bandMid, bandTreble;
float peakBass = 0.01, peakMid = 0.01, peakTreble = 0.01;

void setup() {
  size(480, 800, P2D);
  randomSeed(SEED_VALUE);
  frameRate(ANIMATION_SPEED);
  pixelDensity(displayDensity());
  
  minim = new Minim(this);
  song = minim.loadFile("islandman.mp3", 1024);
  if (song == null) exit();
  
  float durationSeconds = song.length() / 1000.0;
  MAX_FRAMES = int(durationSeconds * ANIMATION_SPEED);
  
  println("--- Audio Engine Loaded ---");
  println("FPS: " + ANIMATION_SPEED + " | Limit: " + MAX_FRAMES);
  println("---------------------------");
  
  fft = new FFT(song.bufferSize(), song.sampleRate());
  song.play();

  String[] vertSource = {
    "#version 410",
    "uniform mat4 transform;",
    "in vec4 position;",
    "void main() { gl_Position = transform * position; }"
  };

  String[] fragSource = {
    "#version 410",
    "uniform vec2 u_resolution;",
    "uniform float u_loopProgress;",
    "uniform float u_topSectors;",
    "uniform float u_botSectors;",
    "uniform vec3 u_palette[10];", 
    "uniform float u_audioIntensity;",
    "uniform float u_waveVal;",       
    "uniform float u_jitterDir;",
    "uniform float u_bandBass;",      
    "uniform float u_bandMid;",       
    "uniform float u_bandTreble;",    
    "uniform float u_rippleStrength;", 
    "uniform int u_rippleCount;",
    "uniform float u_diameter;",
    "uniform float u_maxRipple;",
    "uniform float u_spiral;",
    "uniform float u_armWidth;",
    "uniform float u_armOscillation;", 
    "uniform float u_distortion;",     
    "uniform float u_colorCycleSpeed;",
    "uniform float u_glow;",
    "uniform float u_strandWidth;",
    "uniform vec2 u_centerT;",
    "uniform vec2 u_centerB;",
    "uniform bool u_showM1;",
    "uniform bool u_showM2;",
    "uniform bool u_showStrands;",
    "out vec4 fragColor;",

    // Fixed color helper: COLOR_CYCLE_SPEED now drives the animation rate
    "vec3 getSmoothColor(float offset, float dir) {",
    "  float cycle = u_loopProgress * u_colorCycleSpeed * 10.0;",
    "  float t = mod(cycle * dir + offset, 9.0);",
    "  int i0 = int(t) + 1;", 
    "  int i1 = (i0 >= 9) ? 1 : i0 + 1;",
    "  return mix(u_palette[i0], u_palette[i1], fract(t));",
    "}",

    "vec3 renderMandala(vec2 uv, vec2 center, float sectors, float isSpiral, float spinDir) {",
    "  float aspect = u_resolution.x / u_resolution.y;",
    "  vec2 p_uv = (uv - center);",
    "  p_uv.y /= aspect;",
    "  float r = length(p_uv) * 2.5;",
    "  if (r > 1.4) return vec3(0.0);",
    "  float a = atan(p_uv.y, p_uv.x);", 
    "  float phi = a + (u_loopProgress * 6.28318 * spinDir) + (r * u_spiral * isSpiral);",
    "  float s = 6.2831853 / sectors;",
    "  float folded_a = abs(mod(phi + 3.14159, s) - s * 0.5);",
    "  vec2 p = vec2(cos(folded_a), sin(folded_a)) * r;",
    "  float centerRingRadius = 0.12 + u_audioIntensity * 0.2;",
    "  float rings = 0.0;",
    "  for(int i=1; i<=u_rippleCount; i++) {",
    "    float elasticRadius = centerRingRadius + (abs(u_waveVal) * u_rippleStrength * float(i) * 0.05);",
    "    rings += 0.001 / (abs(r - clamp(elasticRadius, centerRingRadius, u_maxRipple)) + 0.0003);",
    "  }",
    "  float ring1 = abs(r - centerRingRadius);",
    "  float arms = abs(p.y - (u_armWidth + sin(r * u_armOscillation - u_loopProgress * 50.0) * 0.01));",
    "  float beads = length(vec2(mod(r, 0.15 * u_distortion) - 0.075, p.y)) - (0.01 + u_audioIntensity * 0.03);",
    "  vec3 col = vec3(0.0);",
    "  col += getSmoothColor(2.0, spinDir) * (0.005 / arms);",
    "  col += getSmoothColor(5.0, spinDir) * (0.004 / ring1);",
    "  col += getSmoothColor(8.0, spinDir) * (0.003 / abs(beads));",
    "  col += getSmoothColor(3.0, spinDir) * rings;", 
    "  col += getSmoothColor(0.0, spinDir) * (0.015 / (r + 0.05));",
    "  return col * u_glow * smoothstep(u_diameter, u_diameter * 0.7, r);",
    "}",

    "void main() {",
    "  vec2 uv = gl_FragCoord.xy / u_resolution.xy;",
    "  vec3 col = vec3(0.0);",
    "  if(u_showM1) col += renderMandala(uv, u_centerT, u_topSectors, 0.0, 1.0);",
    "  if(u_showM2) col += renderMandala(uv, u_centerB, u_botSectors, 1.0, -1.0);",
    "  if(u_showStrands) {",
    "    float yLow = min(u_centerB.y, u_centerT.y);",
    "    float yHigh = max(u_centerB.y, u_centerT.y);",
    "    if(uv.y >= yLow && uv.y <= yHigh) {",
    "      float localY = (uv.y - yLow) / (yHigh - yLow);",
    "      float bMix = mix(u_bandBass, u_bandMid, smoothstep(0.1, 0.5, localY));",
    "      bMix = mix(bMix, u_bandTreble, smoothstep(0.5, 0.9, localY));",
    "      float rawWave = sin(uv.y * 50.0 + u_loopProgress * 62.83);",
    "      float peakBias = (u_jitterDir > 0.0) ? (rawWave > 0.0 ? 4.0 : 0.5) : (rawWave < 0.0 ? 4.0 : 0.5);",
    "      float heartbeat = 0.5 + (rawWave * peakBias * u_waveVal * (bMix * 10.0));",
    "      col += getSmoothColor(5.0, 1.0) * (u_strandWidth / abs(uv.x - heartbeat)) * u_glow;",
    "    }",
    "  }",
    "  fragColor = vec4(col * (1.0 + u_audioIntensity), 1.0);",
    "}"
  };

  dualShader = new PShader(this, vertSource, fragSource);
}

void updatePalette() {
  int pIdx = PALETTE_INDEX % PALETTES.length;
  for (int i = 0; i < 10; i++) {
    color c = unhex("FF" + PALETTES[pIdx][i].substring(1));
    shaderColors[i*3] = red(c)/255.0;
    shaderColors[i*3+1] = green(c)/255.0;
    shaderColors[i*3+2] = blue(c)/255.0;
  }
}

void draw() {
  if (frameCount >= MAX_FRAMES) {
    song.close(); minim.stop(); noLoop(); exit(); return;
  }

  float progress = (float)(frameCount % MAX_FRAMES) / MAX_FRAMES;
  fft.forward(song.mix);
  
  float rawB = fft.calcAvg(20, 200);   
  float rawM = fft.calcAvg(200, 2000); 
  float rawT = fft.calcAvg(2000, 10000);
  
  if (rawB + rawM + rawT < NOISE_FLOOR) { rawB = rawM = rawT = 0; }
  
  peakBass = max(peakBass * 0.99f, rawB);
  peakMid = max(peakMid * 0.99f, rawM);
  peakTreble = max(peakTreble * 0.99f, rawT);
  
  bandBass = lerp(bandBass, (rawB / (peakBass + 0.001f)) * BASS_STRENGTH, FREQ_SMOOTHING);
  bandMid = lerp(bandMid, (rawM / (peakMid + 0.001f)) * MID_STRENGTH, FREQ_SMOOTHING);
  bandTreble = lerp(bandTreble, (rawT / (peakTreble + 0.001f)) * TREBLE_STRENGTH, FREQ_SMOOTHING);

  float intensity = (bandBass + bandMid + bandTreble) * 0.05;

  updatePalette();
  color baseBg = color(shaderColors[0]*255, shaderColors[1]*255, shaderColors[2]*255);
  if (INVERT_BG) baseBg = color(255 - red(baseBg), 255 - green(baseBg), 255 - blue(baseBg));
  background(baseBg);

  float waveVal = song.mix.get(frameCount % song.bufferSize());
  
  jitterCounter++;
  if (jitterCounter >= JITTER_DURATION) {
    jitterDir = random(1.0) > 0.5 ? 1.0 : -1.0;
    jitterCounter = 0;
  }

  dualShader.set("u_resolution", (float)width * displayDensity(), (float)height * displayDensity());
  dualShader.set("u_loopProgress", progress);
  dualShader.set("u_topSectors", TOP_SYMMETRY);
  dualShader.set("u_botSectors", BOT_SYMMETRY);
  dualShader.set("u_audioIntensity", intensity);
  dualShader.set("u_waveVal", waveVal);
  dualShader.set("u_jitterDir", jitterDir);
  dualShader.set("u_bandBass", bandBass);
  dualShader.set("u_bandMid", bandMid);
  dualShader.set("u_bandTreble", bandTreble);
  dualShader.set("u_rippleStrength", RIPPLE_STRENGTH);
  dualShader.set("u_rippleCount", RIPPLE_COUNT);
  dualShader.set("u_diameter", MANDALA_DIAMETER);
  dualShader.set("u_maxRipple", MAX_RIPPLE_DIAMETER);
  dualShader.set("u_spiral", SPIRAL_TWIST);
  dualShader.set("u_armWidth", STARBURST_ARM_WIDTH);
  dualShader.set("u_armOscillation", ARM_OSCILLATION);
  dualShader.set("u_distortion", NODE_DISTORTION);
  dualShader.set("u_colorCycleSpeed", COLOR_CYCLE_SPEED);
  dualShader.set("u_glow", GLOW_STRENGTH);
  dualShader.set("u_strandWidth", STRAND_WIDTH);
  dualShader.set("u_centerT", CENTER_T_X, CENTER_T_Y);
  dualShader.set("u_centerB", CENTER_B_X, CENTER_B_Y);
  dualShader.set("u_showM1", SHOW_M1);
  dualShader.set("u_showM2", SHOW_M2);
  dualShader.set("u_showStrands", SHOW_STRANDS);
  dualShader.set("u_palette", shaderColors, 3);

  shader(dualShader);
  rect(0, 0, width, height);
  resetShader();

  if (SAVE_FRAMES) saveFrame("frames/####.tif");
}

void stop() {
  song.close(); minim.stop(); super.stop();
}
