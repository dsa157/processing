/**
 * Kinetic Skyline: Movement and Rhythm
 * Version: 2026.01.04.21.52.10
 * Restored structural logic from v21.37.52 with multi-palette support.
 * Uses layered rectangles and sine-driven window light for a dense city feel.
 */

// --- Configuration Parameters ---
int SKETCH_WIDTH = 480;      // Default: 480
int SKETCH_HEIGHT = 800;     // Default: 800
int SEED_VALUE = 88;         // Default: 88
int PADDING = 40;            // Default: 40
int MAX_FRAMES = 900;        // Default: 900
boolean SAVE_FRAMES = false; // Default: false
int ANIMATION_SPEED = 30;    // Default: 30

// Visual Parameters
int TOWER_COUNT = 25;        // Number of towers per layer
int LAYERS = 3;              // Background, Midground, Foreground
float WAVE_SPEED = 0.04;     // Speed of the pulse
float TOWER_WIDTH_MIN = 15;  // Default: 15
float TOWER_WIDTH_MAX = 40;  // Default: 40

// UI / Mode Parameters
boolean SHOW_GRID = false;   // Default: false
boolean INVERT_COLORS = false; 
int PALETTE_INDEX = 2;       // 0: Deep Sea, 1: Cyberpunk, 2: Noir, 3: Golden Hour, 4: Emerald

// Color Palettes (5 Themes)
color[][] PALETTES = {
  {#010B13, #0B2545, #134074, #8DA9C4, #EEF4ED}, // 0: Deep Sea (Classic Night)
  {#0F051D, #2D0054, #5D00B1, #AC00E6, #FF00E6}, // 1: Cyberpunk (Neon)
  {#050505, #1A1A1B, #333333, #555555, #FFFFFF}, // 2: Noir (Grayscale)
  {#1A0F0F, #4A1E1B, #963D32, #D88C6F, #FFD07B}, // 3: Golden Hour (Warm)
  {#021101, #072A05, #114B0B, #208116, #9EFF91}  // 4: Emerald City (Matrix)
};

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  randomSeed(SEED_VALUE);
  frameRate(ANIMATION_SPEED);
}

void draw() {
  color[] activePalette = PALETTES[PALETTE_INDEX];
  color bgColor = INVERT_COLORS ? activePalette[4] : activePalette[0];
  color windowColor = INVERT_COLORS ? activePalette[0] : activePalette[4];
  
  background(bgColor);
  
  float drawWidth = width - (2 * PADDING);
  float drawHeight = height - (2 * PADDING);

  pushMatrix();
  translate(PADDING, PADDING);

  if (SHOW_GRID) drawDebugGrid(drawWidth, drawHeight);

  // Draw 3 layers of buildings for depth
  for (int L = 1; L <= LAYERS; L++) {
    drawLayer(L, drawWidth, drawHeight, activePalette, windowColor);
  }
  
  popMatrix();

  // Save Frame and Loop Logic
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) {
      noLoop();
    }
  }
}

void drawLayer(int layerIdx, float w, float h, color[] activePal, color winCol) {
  float layerSpeed = WAVE_SPEED * layerIdx;
  
  for (int i = 0; i < TOWER_COUNT; i++) {
    // Generate deterministic width for this tower using noise and seed
    float tWidth = map(noise(i, layerIdx * 10), 0, 1, TOWER_WIDTH_MIN, TOWER_WIDTH_MAX) / (LAYERS - layerIdx + 1);
    float x = i * (w / TOWER_COUNT);
    
    // Complex Sine Modulation (restored from v21.37.52)
    float waveA = sin(i * 0.3 + frameCount * layerSpeed);
    float waveB = sin(i * 0.8 + frameCount * layerSpeed * 0.5);
    float combinedWave = (waveA + waveB) / 2.0;
    float normWave = map(combinedWave, -1, 1, 0, 1);
    
    // Calculate Height
    float towerH = lerp(h * 0.1, h * (0.3 * layerIdx), normWave);
    
    // Draw Building
    noStroke();
    // Select color from palette based on layer
    fill(activePal[min(layerIdx, activePal.length - 1)]); 
    rect(x, h - towerH, tWidth, towerH);
    
    // Draw Windows (only on midground and foreground layers)
    if (layerIdx > 1 && towerH > 50) {
      drawWindows(x, h - towerH, tWidth, towerH, normWave, winCol);
    }
  }
}

void drawWindows(float tx, float ty, float tw, float th, float energy, color winCol) {
  float winSize = 3;
  float winGap = 6;
  
  // Brightness tied to the building's current sine energy
  fill(winCol, 150 * energy); 
  
  for (float wx = tx + 4; wx < tx + tw - 4; wx += winGap) {
    for (float wy = ty + 10; wy < ty + th - 10; wy += winGap * 2) {
      // Random window flicker
      if (noise(wx, wy, frameCount * 0.1) > 0.4) {
        rect(wx, wy, winSize, winSize);
      }
    }
  }
}

void drawDebugGrid(float w, float h) {
  stroke(255, 30);
  for (int i = 0; i <= 10; i++) {
    line(i * (w/10), 0, i * (w/10), h);
    line(0, i * (h/10), w, i * (h/10));
  }
}
