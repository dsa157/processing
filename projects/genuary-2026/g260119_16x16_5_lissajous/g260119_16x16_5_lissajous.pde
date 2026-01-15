/**
 * Harmonograph Lattice - Animated
 * Version: 2026.01.11.18.14.30
 * Features dynamic cell displacement and pulsing radius logic.
 */

// --- Parameters ---
int SKETCH_WIDTH = 480;       // Default: 480
int SKETCH_HEIGHT = 800;      // Default: 800
int PADDING = 20;             // Default: 40
int MAX_FRAMES = 900;         // Default: 900
boolean SAVE_FRAMES = false;  // Default: false
int ANIMATION_SPEED = 30;     // Default: 30
int SEED_VALUE = 42;          // Default: 42

// Grid Settings
int GRID_ROWS = 16;           // Default: 16
int GRID_COLS = 16;           // Default: 16
boolean SHOW_GRID = false;    // Default: false
float CURVE_DETAIL = 50;      // Default: 80 (points per curve)
float FREQ_STEP = 0.8;       // Default: 0.08

// Animation Parameters
float MOTION_STRENGTH = 15.0; // Default: 15.0 (Cell drift)
float PULSE_SPEED = 0.07;     // Default: 0.05
float DRIFT_SPEED = 0.01;     // Default: 0.02

// Visuals
int PALETTE_INDEX = 0;        // Default: 0-4
boolean INVERT_BG = false;    // Default: false
float LINE_WEIGHT = 0.5;      // Default: 1.0

// Color Palettes
int[][] PALETTES = {
  {#1A1A1A, #E6E6E6, #FF4E50, #FC913A, #F9D423}, 
  {#2E112D, #540032, #820333, #C02739, #F1E3D3}, 
  {#002626, #0E4749, #95C623, #E55812, #EFE7DA}, 
  {#223843, #E9DBCE, #EFF1F3, #DBD3D8, #D8B4A0}, 
  {#111111, #444444, #888888, #CCCCCC, #FFFFFF}  
};

int bg_color, stroke_color, accent_color;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  randomSeed(SEED_VALUE);
  noiseSeed(SEED_VALUE);
  frameRate(ANIMATION_SPEED);
  
  int[] current_palette = PALETTES[PALETTE_INDEX];
  bg_color = INVERT_BG ? current_palette[current_palette.length - 1] : current_palette[0];
  stroke_color = INVERT_BG ? current_palette[0] : current_palette[1];
  accent_color = current_palette[2];
}

void draw() {
  background(bg_color);
  
  float availableWidth = width - (PADDING * 2);
  float availableHeight = height - (PADDING * 2);
  float cellW = availableWidth / GRID_COLS;
  float cellH = availableHeight / GRID_ROWS;
  
  float time = frameCount * PULSE_SPEED;
  float driftTime = frameCount * DRIFT_SPEED;

  pushMatrix();
  translate(PADDING, PADDING);

  for (int i = 0; i < GRID_COLS; i++) {
    for (int j = 0; j < GRID_ROWS; j++) {
      // Base cell position
      float xBase = i * cellW + cellW/2;
      float yBase = j * cellH + cellH/2;
      
      // Motion: Organic drift using noise
      float xOff = (noise(i * 0.1, j * 0.1, driftTime) - 0.5) * MOTION_STRENGTH;
      float yOff = (noise(j * 0.1, i * 0.1, driftTime + 100) - 0.5) * MOTION_STRENGTH;
      
      // Pulsing: Sine wave based on time and position
      float pulse = sin(time + (i + j) * 0.2);
      float dynamicRadius = map(pulse, -1, 1, cellW * 0.15, cellW * 0.45);
      
      if (SHOW_GRID) {
        stroke(stroke_color, 30);
        noFill();
        rect(i * cellW, j * cellH, cellW, cellH);
      }
      
      drawLissajous(xBase + xOff, yBase + yOff, dynamicRadius, i, j, time);
    }
  }
  popMatrix();

  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) {
      noLoop();
    }
  }
}

void drawLissajous(float cx, float cy, float radius, int col, int row, float t) {
  noFill();
  
  float freqX = 1 + (col * FREQ_STEP);
  float freqY = 1 + (row * FREQ_STEP);
  
  // Color shifting based on the pulse phase
  float colorMap = map(sin(t + (col * 0.5)), -1, 1, 0, 1);
  stroke(lerpColor(stroke_color, accent_color, colorMap));
  strokeWeight(LINE_WEIGHT);
  
  beginShape();
  for (int i = 0; i <= CURVE_DETAIL; i++) {
    float angle = map(i, 0, CURVE_DETAIL, 0, TWO_PI);
    // The phase here is also modified by 't' to keep the curves spinning
    float x = cx + sin(angle * freqX + t) * radius;
    float y = cy + cos(angle * freqY + t * 0.5) * radius;
    vertex(x, y);
  }
  endShape();
}
