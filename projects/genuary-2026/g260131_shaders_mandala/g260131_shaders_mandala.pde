/**
 * Dual Static-Symmetry Audio-Reactive Mandala - Shader Fix
 * ------------------------------------------------------------------------
 * Technique: Continuous trigonometric projection for seamless 360-degree rotation.
 * Fix: Removed uniform assignment in shader to resolve compile errors.
 * Features: 
 * - Fixed Symmetry: Top (Starburst) 11 segments, Bottom (Spiral) 5 segments.
 * - Multi-colored Palette: Elements use unique indices from Adobe Kuler palettes.
 * - Node Distortion: Irregular blob shapes driven by u_distortion.
 * - Beat-Pulse BG: Background brightness oscillates with audio (Toggleable).
 * ------------------------------------------------------------------------
 */

import ddf.minim.*;
import ddf.minim.analysis.*;

// --- Global Parameters ---
int SKETCH_WIDTH = 480;      // default: 480
int SKETCH_HEIGHT = 800;     // default: 800
int SEED_VALUE = 42;         // default: 42
int PADDING = 40;            // default: 40
int MAX_FRAMES = 900;        // Dynamically set based on audio duration
boolean SAVE_FRAMES = false; // default: false
int ANIMATION_SPEED = 60;    // default: 60 fps
int PALETTE_INDEX = 2;       // default: 0-4
boolean INVERT_BG = false;   // default: false

// --- Audio Features ---
boolean BEAT_PULSE_BG = true; // default: true (Toggle background beat reactivity)

// --- Visual Parameters ---
float BLOOM_STRENGTH = 1.0;  // default: 1.0
float SPIN_SPEED = 1.5;      // default: 2.5
float MANDALA_DIAMETER = 0.88;     // default: 0.88
float SPIRAL_TWIST = 1.2;          // default: 1.2
float STARBURST_ARM_WIDTH = 0.008; // default: 0.008
float ARM_OSCILLATION = 20.0;      // default: 20.0
float NODE_DISTORTION = 0.5;       // default: 0.5 (0 = circle, 1 = blob)

// --- Fixed Symmetry ---
float TOP_SYMMETRY = 9.0;   // Fixed segments for Starburst
float BOT_SYMMETRY = 7.0;    // Fixed segments for Spiral

// --- Color Palettes (Adobe Color / Kuler inspired) ---
String[][] PALETTES = {
  {"#2E112D", "#540032", "#820333", "#C02739", "#F1E4E8"}, // Deep Reds
  {"#001B2E", "#294C60", "#ADB5BD", "#FFEFD3", "#FFD60A"}, // Midnight Gold
  {"#1A1A1A", "#4E598C", "#AFCBFF", "#FFFFFF", "#F9C784"}, // Cosmic Blue
  {"#2B2D42", "#8D99AE", "#EDF2F4", "#EF233C", "#D90429"}, // Modern High Contrast
  {"#011627", "#FDFFFC", "#2EC4B6", "#E71D36", "#FF9F1C"}  // Cyberpunk
};

// --- Engine Objects ---
Minim minim;
AudioPlayer song;
FFT fft;
PShader dualShader;

// Color State Variables
color curBg, curC1, curC2, curC3, curC4;
color targetBg, targetC1, targetC2, targetC3, targetC4;
float colorLerpFactor = 0.015; 

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT, P2D);
  pixelDensity(displayDensity());
}

void setup() {
  randomSeed(SEED_VALUE);
  frameRate(ANIMATION_SPEED);
  
  minim = new Minim(this);
  song = minim.loadFile("islandman.mp3", 1024);
  if (song == null) exit();
  
  fft = new FFT(song.bufferSize(), song.sampleRate());
  MAX_FRAMES = int((song.length() / 1000.0) * ANIMATION_SPEED);
  
  updateTargetPalette(PALETTE_INDEX);
  curBg = targetBg; curC1 = targetC1; curC2 = targetC2; curC3 = targetC3; curC4 = targetC4;
  
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
    "uniform vec3 u_color1;", // Arms
    "uniform vec3 u_color2;", // Rings
    "uniform vec3 u_color3;", // Core
    "uniform vec3 u_color4;", // Nodes
    "uniform float u_bloom;",
    "uniform float u_audioIntensity;",
    "uniform float u_diameter;",
    "uniform float u_spiral;",
    "uniform float u_armWidth;",
    "uniform float u_armPulse;",
    "uniform float u_distortion;",
    "uniform vec2 u_centerT;",
    "uniform vec2 u_centerB;",
    "out vec4 fragColor;",

    "vec3 renderMandala(vec2 fragCoord, vec2 center, float sectors, float isSpiral, float spinDir) {",
    "  vec2 uv = fragCoord / u_resolution.xy;",
    "  float aspect = u_resolution.x / u_resolution.y;",
    "  vec2 p_uv = (uv - center);",
    "  p_uv.y /= aspect;",
    "  ",
    "  float r = length(p_uv) * 2.5;",
    "  if (r > 1.2) return vec3(0.0);",
    "  ",
    "  // Continuous projection to avoid seams",
    "  float a = atan(p_uv.y, p_uv.x);",
    "  float phi = a + (u_time * 0.4 * spinDir) + (r * u_spiral * isSpiral);",
    "  ",
    "  float s = 6.2831853 / sectors;",
    "  float folded_a = abs(mod(phi + 3.14159, s) - s * 0.5);",
    "  vec2 p = vec2(cos(folded_a), sin(folded_a)) * r;",
    "  ",
    "  float ring1 = abs(r - (0.12 + u_audioIntensity * 0.2));",
    "  float wave = sin(r * u_armPulse - u_time * 8.0) * 0.01 * (1.0 + u_audioIntensity);",
    "  float arms = abs(p.y - (u_armWidth + wave));",
    "  ",
    "  float beadSpacing = 0.15;",
    "  float beadR = mod(r, beadSpacing) - beadSpacing * 0.5;",
    "  float distAngle = atan(p.y, beadR);",
    "  float distortion = sin(distAngle * 5.0) * cos(distAngle * 3.0) * u_distortion * 0.02;",
    "  float beads = length(vec2(beadR, p.y)) - (0.01 + u_audioIntensity * 0.03 + distortion);",
    "  ",
    "  vec3 col = vec3(0.0);",
    "  col += u_color1 * (0.005 / arms);",
    "  col += u_color2 * (0.004 / ring1);",
    "  col += u_color4 * (0.003 / abs(beads));",
    "  col += u_color3 * (0.015 / (r + 0.05));",
    "  ",
    "  return col * smoothstep(u_diameter, u_diameter * 0.7, r);",
    "}",

    "void main() {",
    "  vec3 mTop = renderMandala(gl_FragCoord.xy, u_centerT, u_topSectors, 0.0, 1.0);",
    "  vec3 mBot = renderMandala(gl_FragCoord.xy, u_centerB, u_botSectors, 1.0, -1.0);",
    "  ",
    "  vec3 final = (mTop + mBot) * u_bloom * (1.0 + u_audioIntensity);",
    "  fragColor = vec4(final, 1.0);",
    "}"
  };

  dualShader = new PShader(this, vertSource, fragSource);
}

void updateTargetPalette(int index) {
  String[] p = PALETTES[index % PALETTES.length];
  targetBg = unhex("FF" + p[0].substring(1));
  targetC1 = unhex("FF" + p[1].substring(1));
  targetC2 = unhex("FF" + p[2].substring(1));
  targetC3 = unhex("FF" + p[3].substring(1));
  targetC4 = unhex("FF" + p[4].substring(1));
}

void draw() {
  fft.forward(song.mix);
  float intensity = constrain(fft.calcAvg(20, 200) * 0.15, 0, 1.0);

  // Background and Palette Lerping
  curBg = lerpColor(curBg, targetBg, colorLerpFactor);
  color displayBg = curBg;
  if (BEAT_PULSE_BG) {
    float pulse = intensity * 45.0; // Oscillate brightness
    displayBg = color(red(curBg) + pulse, green(curBg) + pulse, blue(curBg) + pulse);
  }
  background(displayBg);
  
  curC1 = lerpColor(curC1, targetC1, colorLerpFactor);
  curC2 = lerpColor(curC2, targetC2, colorLerpFactor);
  curC3 = lerpColor(curC3, targetC3, colorLerpFactor);
  curC4 = lerpColor(curC4, targetC4, colorLerpFactor);
  
  if (frameCount % (MAX_FRAMES / PALETTES.length) == 0) {
    PALETTE_INDEX = (PALETTE_INDEX + 1) % PALETTES.length;
    updateTargetPalette(PALETTE_INDEX);
  }

  // Set Uniforms
  dualShader.set("u_resolution", (float)width * pixelDensity, (float)height * pixelDensity);
  dualShader.set("u_time", millis() / 1000.0 * SPIN_SPEED);
  dualShader.set("u_topSectors", TOP_SYMMETRY);
  dualShader.set("u_botSectors", BOT_SYMMETRY);
  dualShader.set("u_bloom", BLOOM_STRENGTH);
  dualShader.set("u_audioIntensity", intensity);
  dualShader.set("u_diameter", MANDALA_DIAMETER);
  dualShader.set("u_spiral", SPIRAL_TWIST);
  dualShader.set("u_armWidth", STARBURST_ARM_WIDTH);
  dualShader.set("u_armPulse", ARM_OSCILLATION);
  dualShader.set("u_distortion", NODE_DISTORTION);
  
  // Normalized center coordinates
  dualShader.set("u_centerT", 0.5, 0.72);
  dualShader.set("u_centerB", 0.5, 0.28);
  
  dualShader.set("u_color1", red(curC1)/255.0, green(curC1)/255.0, blue(curC1)/255.0);
  dualShader.set("u_color2", red(curC2)/255.0, green(curC2)/255.0, blue(curC2)/255.0);
  dualShader.set("u_color3", red(curC3)/255.0, green(curC3)/255.0, blue(curC3)/255.0);
  dualShader.set("u_color4", red(curC4)/255.0, green(curC4)/255.0, blue(curC4)/255.0);

  shader(dualShader);
  rect(0, 0, width, height);
  resetShader();

  if (SAVE_FRAMES) saveFrame("frames/####.tif");
  if (frameCount >= MAX_FRAMES || !song.isPlaying()) {
    noLoop(); song.close(); minim.stop();
  }
}

void stop() {
  song.close(); minim.stop(); super.stop();
}
