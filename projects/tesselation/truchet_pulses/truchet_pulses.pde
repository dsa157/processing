/**
 * Truchet Pulses
 * Version: 2026.04.07.15.58.05
 * Description: A Smith-style Truchet tiling sketch featuring organic pulse behaviors
 *              and sound-reactive tile rotations driven by the Minim library.
 *              Beat detection uses Minim's BeatDetect (isKick) in FREQ_ENERGY mode.
 *              Left-click taps a tempo to override BEAT_SENSITIVITY_MS; right-click resets.
 *              Pulsing remains an independent organic breathing effect.
 */

import ddf.minim.*;
import ddf.minim.analysis.*;

// --- Global Constants & Canvas Settings ---
int SKETCH_WIDTH  = 480;      // 480: default width
int SKETCH_HEIGHT = 800;      // 800: default height

// --- Customizable Parameters ---
String MUSIC_FILE = "islandman.mp3"; // "music.mp3": target audio file

int   GRID_COLS          = 10;    // 10:  number of tiles horizontally
int   GRID_ROWS          = 18;    // 18:  number of tiles vertically
float PADDING            = 40.0;  // 40.0: padding around the overall sketch area
float ANIM_INCREMENT     = 0.02;  // 0.02: rate of animation progression (t) — faster = more visible pulsing

// --- Stroke & Pulse Controls ---
float OUTER_STROKE        = 10.0; // 10.0: base thickness of the black outline
float INNER_STROKE        = 6.0;  //  6.0: base thickness of the color fill
boolean PULSE_WIDTHS      = true; // true: enable organic stroke width pulsing
float PULSE_SPEED         = 0.8;  //  0.8: speed of the breathing effect
float PULSE_MIN_SCALE     = 0.1;  //  0.1: minimum thickness factor
float PULSE_MAX_SCALE     = 2.5;  //  2.5: maximum thickness factor
float PULSE_NOISE_SCALE   = 0.3;  //  0.3: spatial scale for organic pulse variation

// --- Sound-Reactive Rotation Parameters ---
boolean ENABLE_ROTATION   = true;  // true: enable beat-triggered tile rotations

// BeatDetect sensitivity: ms that must pass between detectable kick beats.
// This is the fallback value used when ENABLE_CLICK_CALCULATION is false,
// or before enough taps have been recorded.
int BEAT_SENSITIVITY_MS   = 2000;  // 2000 ms: default (~30 BPM) — gives pulsing room to breathe

// When true, left-click taps override BEAT_SENSITIVITY_MS with a calculated interval.
// Right-click resets back to BEAT_SENSITIVITY_MS.
boolean ENABLE_CLICK_CALCULATION = true; // true: allow tap-tempo override via mouse clicks

// Number of clicks to average for tap-tempo BPM calculation
int TAP_BUFFER_SIZE = 4;           //  4: taps averaged per tempo estimate

// --- Global State ---
int     GLOBAL_SEED        = 42;    // 42: seed for reproducibility
int     PALETTE_INDEX      = 1;     //  1: active color palette index (0-6)
boolean INVERT_BACKGROUND  = false; // false: toggle to invert background color
boolean SHOW_GRID          = false; // false: show/hide tile grid cells
boolean DISPLAY_HUD        = true;  // true:  show beat / BPM debug overlay

// --- Animation & Rendering Controls ---
int     MAX_FRAMES         = 900;
boolean SAVE_FRAMES        = false;
int     ANIMATION_SPEED    = 30;

// --- Color Palettes (Adobe Kuler) ---
// 0: Teal Noir        1: Ocean Depths     2: Forest Moss
// 3: Sunset Blaze     4: Warm Harvest     5: Monochrome     6: B&W
String[][] HEX_PALETTES = {
  {"#FFFFFF", "#008080", "#000000", "#FFD700", "#FF4500"}, // Teal Noir
  {"#001F3F", "#39CCCC", "#000000", "#7FDBFF", "#01FF70"}, // Ocean Depths
  {"#2D4032", "#8B9467", "#000000", "#556B2F", "#EAEAEA"}, // Forest Moss
  {"#FF4136", "#FFDC00", "#000000", "#FF851B", "#0074D9"}, // Sunset Blaze
  {"#FAD02E", "#D8334A", "#000000", "#F28D35", "#E8A87C"}, // Warm Harvest
  {"#000000", "#999999", "#FFFFFF", "#666666", "#CCCCCC"}, // Monochrome
  {"#000000", "#FFFFFF", "#000000", "#FFFFFF", "#000000"}  // B&W
};

color[] activePalette;
float   t        = 0;
float   tileSize;

// Per-tile rotation state: 0, 1, 2, or 3 (quarter-turns)
int[][] tileRotations;

// Minim objects
Minim       minim;
AudioPlayer player;
BeatDetect  beat;

// Beat-detection state
boolean beatFlash = false; // true for one frame after a rotation fires (HUD indicator)

// Tap-tempo state
int[]   tapTimes       = new int[0]; // rolling buffer of recent tap timestamps (ms)
boolean tapModeActive  = false;      // true when tap-tempo is overriding BEAT_SENSITIVITY_MS
float   tapIntervalMs  = 0;          // calculated average interval from taps

// -----------------------------------------------------------------------
void setup() {
  size(480, 800);
  frameRate(ANIMATION_SPEED);
  pixelDensity(displayDensity());
  randomSeed(GLOBAL_SEED);
  noiseSeed(GLOBAL_SEED);

  // Initialise per-tile rotation array
  tileRotations = new int[GRID_COLS][GRID_ROWS];
  randomSeed(GLOBAL_SEED);
  for (int x = 0; x < GRID_COLS; x++)
    for (int y = 0; y < GRID_ROWS; y++)
      tileRotations[x][y] = (int)random(4);

  // Setup Sound + BeatDetect
  minim  = new Minim(this);
  player = minim.loadFile(MUSIC_FILE, 1024);
  if (player != null) {
    player.loop();
    // FREQ_ENERGY mode uses per-frequency-band onset detection
    // isKick() targets the low-frequency (bass/kick drum) band
    beat = new BeatDetect(player.bufferSize(), player.sampleRate());
    beat.setSensitivity(activeSensitivityMs()); // ms between detectable beats
    beat.detectMode(BeatDetect.FREQ_ENERGY);
  }

  activePalette = new color[5];
  updatePalette();

  float availableW = width - (PADDING * 2);
  tileSize = availableW / (float)GRID_COLS;
}

// -----------------------------------------------------------------------
void updatePalette() {
  int idx = PALETTE_INDEX % 7;
  for (int i = 0; i < 5; i++) {
    activePalette[i] = unhex("FF" + HEX_PALETTES[idx][i].substring(1));
  }
}

// -----------------------------------------------------------------------
// Returns the sensitivity (ms) currently in use:
// tap-calculated value if tap mode is active and enabled, else BEAT_SENSITIVITY_MS
int activeSensitivityMs() {
  if (ENABLE_CLICK_CALCULATION && tapModeActive && tapIntervalMs > 0) {
    return (int)tapIntervalMs;
  }
  return BEAT_SENSITIVITY_MS;
}

// -----------------------------------------------------------------------
// Fire a rotation event: each tile advances by 1–3 random quarter-turns
void fireRotation() {
  randomSeed((int)(millis() + frameCount * 7));
  for (int x = 0; x < GRID_COLS; x++)
    for (int y = 0; y < GRID_ROWS; y++)
      tileRotations[x][y] = (tileRotations[x][y] + (int)random(1, 4)) % 4;
  beatFlash = true;
}

// -----------------------------------------------------------------------
void draw() {
  updatePalette();

  // Keep BeatDetect sensitivity in sync (tap mode may change it at runtime)
  if (beat != null) beat.setSensitivity(activeSensitivityMs());

  // --- Beat detection ---
  if (ENABLE_ROTATION && beat != null && player != null) {
    beat.detect(player.mix);
    if (beat.isKick()) {
      fireRotation();
    }
  }

  // --- Background ---
  color bgColor = activePalette[0];
  if (INVERT_BACKGROUND) bgColor = color(255 - red(bgColor), 255 - green(bgColor), 255 - blue(bgColor));
  background(bgColor);

  pushMatrix();
  translate(PADDING, PADDING);

  // First pass: thick black "outer" strokes
  randomSeed(GLOBAL_SEED);
  for (int x = 0; x < GRID_COLS; x++) {
    for (int y = 0; y < GRID_ROWS; y++) {
      float px = x * tileSize;
      float py = y * tileSize;
      if (py + tileSize > height - (PADDING * 2)) continue;

      boolean type = random(1) > 0.5;

      float pScale = 1.0;
      if (PULSE_WIDTHS) {
        float noiseVal = noise(x * PULSE_NOISE_SCALE, y * PULSE_NOISE_SCALE, t * PULSE_SPEED);
        pScale = map(noiseVal, 0, 1, PULSE_MIN_SCALE, PULSE_MAX_SCALE);
      }

      drawTruchetLayer(px, py, tileSize, type, x, y, activePalette[2], OUTER_STROKE * pScale);
    }
  }

  // Second pass: "inner" color fill stroke
  randomSeed(GLOBAL_SEED);
  for (int x = 0; x < GRID_COLS; x++) {
    for (int y = 0; y < GRID_ROWS; y++) {
      float px = x * tileSize;
      float py = y * tileSize;
      if (py + tileSize > height - (PADDING * 2)) continue;

      boolean type = random(1) > 0.5;

      float pScale = 1.0;
      if (PULSE_WIDTHS) {
        float noiseVal = noise(x * PULSE_NOISE_SCALE, y * PULSE_NOISE_SCALE, t * PULSE_SPEED);
        pScale = map(noiseVal, 0, 1, PULSE_MIN_SCALE, PULSE_MAX_SCALE);
      }

      drawTruchetLayer(px, py, tileSize, type, x, y, activePalette[1], INNER_STROKE * pScale);

      if (SHOW_GRID) {
        stroke(255, 0, 0, 100);
        strokeWeight(1);
        noFill();
        rect(px, py, tileSize, tileSize);
      }
    }
  }

  popMatrix();

  // --- HUD overlay ---
  if (DISPLAY_HUD) drawHUD();

  beatFlash = false; // reset flash after draw
  t += ANIM_INCREMENT;

  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) noLoop();
  }
}

// -----------------------------------------------------------------------
// HUD overlay: beat indicator, BPM, sensitivity, mode hint
void drawHUD() {
  float hudX = 8;
  float hudY = height - 68;
  float hudW = 230;
  float hudH = 62;

  noStroke();
  fill(0, 0, 0, 170);
  rect(hudX, hudY, hudW, hudH, 6);

  // Beat indicator dot — lights up yellow on each kick detection
  if (beatFlash) {
    noStroke();
    fill(255, 220, 0, 240);
    ellipse(hudX + 14, hudY + 20, 13, 13);
  } else {
    noFill();
    stroke(120);
    strokeWeight(1);
    ellipse(hudX + 14, hudY + 20, 13, 13);
  }

  noStroke();
  fill(220);
  textSize(11);

  // Line 1: mode label
  String modeLabel = (ENABLE_CLICK_CALCULATION && tapModeActive) ? "TAP" : "AUTO";
  text("Mode: " + modeLabel, hudX + 26, hudY + 15);

  // Line 2: active BPM and sensitivity ms in use
  int    activeMs  = activeSensitivityMs();
  float  activeBpm = 60000.0 / activeMs;
  text("BPM: " + nf(activeBpm, 0, 1) + "   sensitivity: " + activeMs + " ms", hudX + 26, hudY + 28);

  // Line 3: tap count or param value
  if (ENABLE_CLICK_CALCULATION) {
    String tapStatus = tapModeActive
      ? "taps: " + tapTimes.length + "/" + TAP_BUFFER_SIZE
      : "taps: 0  (L-click to tap)";
    text(tapStatus, hudX + 26, hudY + 41);
    text("L-click: tap  |  R-click: reset", hudX + 8, hudY + 56);
  } else {
    text("click calc OFF — using param value", hudX + 8, hudY + 44);
    text("BEAT_SENSITIVITY_MS: " + BEAT_SENSITIVITY_MS, hudX + 8, hudY + 57);
  }
}

// -----------------------------------------------------------------------
void drawTruchetLayer(float x, float y, float s, boolean type, int gridX, int gridY, color strokeC, float weight) {
  pushMatrix();
  translate(x + s/2, y + s/2);

  // Apply this tile's stored quarter-turn rotation (0, 90, 180, 270 deg)
  if (ENABLE_ROTATION) {
    rotate(tileRotations[gridX][gridY] * HALF_PI);
  }

  stroke(strokeC);
  strokeWeight(max(0.01, weight));
  noFill();

  if (type) {
    arc(-s/2, -s/2, s, s, 0, HALF_PI);
    arc(s/2,  s/2,  s, s, PI, PI + HALF_PI);
  } else {
    arc(s/2,  -s/2, s, s, HALF_PI, PI);
    arc(-s/2,  s/2, s, s, PI + HALF_PI, TWO_PI);
  }

  popMatrix();
}

// -----------------------------------------------------------------------
// Left-click: record tap, calculate average interval, override sensitivity
// Right-click: reset to BEAT_SENSITIVITY_MS param
void mousePressed() {
  if (!ENABLE_CLICK_CALCULATION) return;

  if (mouseButton == LEFT) {
    int now = millis();

    // Append new tap timestamp
    int[] newTaps = new int[tapTimes.length + 1];
    for (int i = 0; i < tapTimes.length; i++) newTaps[i] = tapTimes[i];
    newTaps[tapTimes.length] = now;

    // Keep only the last TAP_BUFFER_SIZE taps
    if (newTaps.length > TAP_BUFFER_SIZE) {
      int[] trimmed = new int[TAP_BUFFER_SIZE];
      for (int i = 0; i < TAP_BUFFER_SIZE; i++)
        trimmed[i] = newTaps[newTaps.length - TAP_BUFFER_SIZE + i];
      tapTimes = trimmed;
    } else {
      tapTimes = newTaps;
    }

    // Need at least 2 taps to compute an interval
    if (tapTimes.length >= 2) {
      float totalMs = tapTimes[tapTimes.length - 1] - tapTimes[0];
      tapIntervalMs = totalMs / (tapTimes.length - 1);
      tapModeActive = true;
    }

    // Fire a rotation on each tap so you feel the beat sync visually
    fireRotation();

  } else if (mouseButton == RIGHT) {
    // Reset to auto / param mode
    tapTimes      = new int[0];
    tapModeActive = false;
    tapIntervalMs = 0;
  }
}

// -----------------------------------------------------------------------
void stop() {
  if (player != null) player.close();
  if (minim  != null) minim.stop();
  super.stop();
}
