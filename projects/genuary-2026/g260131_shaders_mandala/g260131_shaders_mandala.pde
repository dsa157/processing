/**
 * Dual Static-Symmetry Audio-Reactive Mandala - Heartbeat Focus
 * Version: 2026.01.29.11.35.10
 * ------------------------------------------------------------------------
 * Technique: Buffer-mapped vertical oscilloscope rendering.
 * Fix: Forced resolution uniform to use physical pixel dimensions to resolve
 * the quadrant rendering issue on high-DPI displays.
 * ------------------------------------------------------------------------
 */

import ddf.minim.*;
import ddf.minim.analysis.*;

// --- Global Parameters ---
int SKETCH_WIDTH = 480;      // default: 480
int SKETCH_HEIGHT = 800;     // default: 800
int SEED_VALUE = 42;         // default: 42
int PADDING = 40;            // default: 40
int MAX_FRAMES = 900;        // default: 900
boolean SAVE_FRAMES = false; // default: false
int ANIMATION_SPEED = 60;    // default: 60 fps
int PALETTE_INDEX = 2;       // default: 2 (0-4)
boolean INVERT_BG = false;   // default: false

// --- Visibility Toggles ---
boolean SHOW_M1 = true;        // default: true (Mandala 1 visibility)
boolean SHOW_M2 = true;        // default: true (Mandala 2 visibility)
boolean BEAT_PULSE_BG = false; // default: false (Background brightness pulse)
boolean SHOW_STRANDS = true;   // default: true (Toggle connecting EKG strand)

// --- Progression Parameters ---
float SPIN_SPEED = 0.5;      // default: 0.5
float SPIRAL_TWIST = 1.2;    // default: 1.2
int JITTER_DURATION = 15;    // default: 15 (Frames to hold a jitter direction)

// --- Frequency Strength Parameters ---
float BASS_STRENGTH = 0.001;   // default: 2.0
float MID_STRENGTH = 0.003;    // default: 1.5
float TREBLE_STRENGTH = 0.03;  // default: 3.0

// --- Visual Style Parameters ---
float GLOW_STRENGTH = 1.5;     // default: 1.5 (Overall brightness multiplier)
float STRAND_WIDTH = 0.003;   // default: 0.0012 (Thickness of the heartbeat line)

// --- Mandala Parameters ---
float MANDALA_DIAMETER = 0.88;     // default: 0.88
float STARBURST_ARM_WIDTH = 0.008; // default: 0.008
float ARM_OSCILLATION = 20.0;      // default: 20.0
float NODE_DISTORTION = 0.5;       // default: 0.5

// --- Fixed Symmetry ---
float TOP_SYMMETRY = 7.0;    // default: 7.0
float BOT_SYMMETRY = 5.0;    // default: 5.0

// --- Mandala Positions (Normalized 0.0 - 1.0) ---
float CENTER_T_X = 0.5;      // default: 0.5
float CENTER_T_Y = 0.72;     // default: 0.72 (Top Mandala)
float CENTER_B_X = 0.5;      // default: 0.5
float CENTER_B_Y = 0.28;     // default: 0.28 (Bottom Mandala)

// --- 10-Color Palettes (Adobe Kuler) ---
String[][] PALETTES = {
  {"#1a091a", "#2e112d", "#540032", "#820333", "#c02739", "#e71d36", "#ff5d5d", "#ff9191", "#f1e4e8", "#ffffff"}, // Palette 0: Crimson/Dark
  {"#000814", "#001d3d", "#003566", "#ffc300", "#ffd60a", "#fb8500", "#ffb703", "#8ecae6", "#219ebc", "#023047"}, // Palette 1: Blue/Gold
  {"#011627", "#2ec4b6", "#e71d36", "#ff9f1c", "#fdfffc", "#011627", "#2ec4b6", "#e71d36", "#ff9f1c", "#fdfffc"}, // Palette 2: High Contrast
  {"#2b2d42", "#8D99AE", "#edf2f4", "#ef233c", "#d90429", "#2b2d42", "#8d99ae", "#edf2f4", "#ef233c", "#d90429"}, // Palette 3: Industrial
  {"#1b4332", "#2d6a4f", "#40916c", "#52b788", "#74c69d", "#95d5b2", "#b7e4c7", "#d8f3dc", "#081c15", "#ffffff"}  // Palette 4: Forest
};

// --- Engine Objects ---
Minim minim;
AudioPlayer song;
FFT fft;
PShader dualShader;

float[] shaderColors = new float[30]; 
float waveJitterX = 0.5; 
float paletteTime = 0.0; 
float bandBass, bandMid, bandTreble;
float jitterDir = 1.0;
int jitterCounter = 0;

void setup() {
  size(480, 800, P2D);
  randomSeed(SEED_VALUE);
  frameRate(ANIMATION_SPEED);
  pixelDensity(displayDensity());
  
  minim = new Minim(this);
  song = minim.loadFile("islandman.mp3", 1024);
  if (song == null) exit();
  
  fft = new FFT(song.bufferSize(), song.sampleRate());
  MAX_FRAMES = int((song.length() / 1000.0) * ANIMATION_SPEED);
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
    "uniform float u_time;",
    "uniform float u_topSectors;",
    "uniform float u_botSectors;",
    "uniform vec3 u_palette[10];", 
    "uniform float u_audioIntensity;",
    "uniform float u_waveVal;",       
    "uniform float u_waveJitterX;",   
    "uniform float u_jitterDir;",
    "uniform float u_bandBass;",      
    "uniform float u_bandMid;",       
    "uniform float u_bandTreble;",    
    "uniform float u_diameter;",
    "uniform float u_spiral;",
    "uniform float u_armWidth;",
    "uniform float u_armPulse;",
    "uniform float u_distortion;",
    "uniform float u_glow;",
    "uniform float u_strandWidth;",
    "uniform vec2 u_centerT;",
    "uniform vec2 u_centerB;",
    "uniform bool u_showM1;",
    "uniform bool u_showM2;",
    "uniform bool u_showStrands;",
    "out vec4 fragColor;",

    "vec3 renderMandala(vec2 uv, vec2 center, float sectors, float isSpiral, float spinDir) {",
    "  float aspect = u_resolution.x / u_resolution.y;",
    "  vec2 p_uv = (uv - center);",
    "  p_uv.y /= aspect;",
    "  float r = length(p_uv) * 2.5;",
    "  if (r > 1.4) return vec3(0.0);",
    "  float a = atan(p_uv.y, p_uv.x);",
    "  float phi = a + (u_time * 0.4 * spinDir) + (r * u_spiral * isSpiral);",
    "  float s = 6.2831853 / sectors;",
    "  float folded_a = abs(mod(phi + 3.14159, s) - s * 0.5);",
    "  vec2 p = vec2(cos(folded_a), sin(folded_a)) * r;",
    "  float ring1 = abs(r - (0.12 + u_audioIntensity * 0.2));",
    "  float wave = sin(r * 20.0 - u_time * 8.0) * 0.01;",
    "  float arms = abs(p.y - (u_armWidth + wave));",
    "  float beads = length(vec2(mod(r, 0.15) - 0.075, p.y)) - (0.01 + u_audioIntensity * 0.03);",
    "  vec3 col = vec3(0.0);",
    "  col += u_palette[int(mod(u_time * 1.5 + 2, 10))] * (0.005 / arms);",
    "  col += u_palette[int(mod(u_time * 1.5 + 5, 10))] * (0.004 / ring1);",
    "  col += u_palette[int(mod(u_time * 1.5 + 8, 10))] * (0.003 / abs(beads));",
    "  col += u_palette[int(mod(u_time * 1.5, 10))] * (0.015 / (r + 0.05));",
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
    "      float bandRes = (localY > 0.66) ? u_bandTreble : (localY > 0.33 ? u_bandMid : u_bandBass);",
    "      float heartbeat = u_waveJitterX + (sin(uv.y * 60.0 + u_time * 12.0) * u_waveVal * bandRes * u_jitterDir);",
    "      float dist = abs(uv.x - heartbeat);",
    "      col += u_palette[8] * (u_strandWidth / dist) * u_glow;",
    "    }",
    "  }",
    "  fragColor = vec4(col * (1.0 + u_audioIntensity), 1.0);",
    "}"
  };

  dualShader = new PShader(this, vertSource, fragSource);
}

void updatePalette() {
  paletteTime += 0.005; 
  int pIdx = PALETTE_INDEX % PALETTES.length;
  int nextIdx = (pIdx + 1) % PALETTES.length;
  float transition = paletteTime - floor(paletteTime);
  for (int i = 0; i < 10; i++) {
    color c1 = unhex("FF" + PALETTES[pIdx][i].substring(1));
    color c2 = unhex("FF" + PALETTES[nextIdx][i].substring(1));
    color lerped = lerpColor(c1, c2, transition);
    shaderColors[i*3] = red(lerped)/255.0;
    shaderColors[i*3+1] = green(lerped)/255.0;
    shaderColors[i*3+2] = blue(lerped)/255.0;
  }
}

void draw() {
  fft.forward(song.mix);
  bandBass = fft.calcAvg(20, 200) * BASS_STRENGTH;   
  bandMid = fft.calcAvg(200, 2000) * MID_STRENGTH; 
  bandTreble = fft.calcAvg(2000, 10000) * TREBLE_STRENGTH; 
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
  
  if (bandBass > 1.0) { waveJitterX = random(0.48, 0.52); }

  // PASS PHYSICAL PIXELS: Logic for high-DPI displays
  dualShader.set("u_resolution", (float)width * displayDensity(), (float)height * displayDensity());
  dualShader.set("u_time", millis() / 1000.0 * SPIN_SPEED);
  dualShader.set("u_topSectors", TOP_SYMMETRY);
  dualShader.set("u_botSectors", BOT_SYMMETRY);
  dualShader.set("u_audioIntensity", intensity);
  dualShader.set("u_waveVal", waveVal);
  dualShader.set("u_waveJitterX", waveJitterX);
  dualShader.set("u_jitterDir", jitterDir);
  dualShader.set("u_bandBass", bandBass);
  dualShader.set("u_bandMid", bandMid);
  dualShader.set("u_bandTreble", bandTreble);
  dualShader.set("u_diameter", MANDALA_DIAMETER);
  dualShader.set("u_spiral", SPIRAL_TWIST);
  dualShader.set("u_armWidth", STARBURST_ARM_WIDTH);
  dualShader.set("u_armPulse", ARM_OSCILLATION);
  dualShader.set("u_distortion", NODE_DISTORTION);
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
  if (SAVE_FRAMES && frameCount >= MAX_FRAMES) {
    noLoop(); song.close(); minim.stop();
  }
}

void stop() {
  song.close(); minim.stop(); super.stop();
}
