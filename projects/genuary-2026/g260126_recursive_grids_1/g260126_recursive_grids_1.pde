/**
 * Recursive Grid Zoom - Phase 23 (Color & Pixel Milestone)
 * Version: 2026.01.20.08.45.10
 */

// --- Parameters ---
int SKETCH_WIDTH = 480;       // Default: 480
int SKETCH_HEIGHT = 800;      // Default: 800
int MAX_FRAMES = 800;         // Default: 800 (8 cycles of 100 frames)
boolean SAVE_FRAMES = false;  // Default: false
int ANIMATION_SPEED = 60;     // Default: 60
int CYCLE_LENGTH = 100;       // Default: 100 frames per zoom cycle
int GLOBAL_SEED = 42;         // Default: 42
float CANVAS_PADDING = 40;    // Default: 40

// Logic Parameters
float START_SIZE = 400;       // Default: 400 (Grid boundary width)
float END_SIZE = 118;         // Default: 118 (Square size)
int GRID_COUNT = 3;           // Default: 3
boolean INVERT_BACK = false;  // Default: false
boolean SHOW_GRID_CELLS = false; // Default: false

// Color Palettes (Adobe Color / Kuler)
String[][] PALETTES = {
  {"#264653", "#2a9d8f", "#e9c46a", "#f4a261", "#e76f51"}, // Palette 0: Terra Cotta
  {"#001219", "#005f73", "#0a9396", "#94d2bd", "#e9d8a6"}, // Palette 1: Deep Sea
  {"#ffbe0b", "#fb5607", "#ff006d", "#8338ec", "#3a86ff"}, // Palette 2: Cyber
  {"#22223b", "#4a4e69", "#9a8c98", "#c9ada7", "#f2e9e4"}, // Palette 3: Muted
  {"#1a1c2c", "#5d275d", "#b13e53", "#ef7d57", "#ffcd75"}  // Palette 4: Sunset
};
int PALETTE_INDEX = 1; // Default: 1

// Variables
color bg_color;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  randomSeed(GLOBAL_SEED);
  frameRate(ANIMATION_SPEED);
  
  String[] activePalette = PALETTES[PALETTE_INDEX];
  bg_color = color(unhex("FF" + activePalette[0].substring(1)));
  if (INVERT_BACK) {
    bg_color = color(255 - red(bg_color), 255 - green(bg_color), 255 - blue(bg_color));
  }
}

void draw() {
  background(bg_color);
  translate(width/2, height/2);
  
  // Progress Logic
  int currentFrame = (frameCount - 1);
  float progress = (float)(currentFrame % CYCLE_LENGTH) / CYCLE_LENGTH;

  // --- Color Selection ---
  String[] p = PALETTES[PALETTE_INDEX];
  int paletteCount = p.length - 1; 
  int colorLevel = currentFrame / CYCLE_LENGTH;
  
  // Bleed squares = Color of the level we are zooming AWAY from
  color colorBleed = color(unhex("FF" + p[1 + ((colorLevel + paletteCount - 1) % paletteCount)].substring(1)));
  // Main Grid = Color of the current level
  color colorCurr = color(unhex("FF" + p[1 + (colorLevel % paletteCount)].substring(1)));
  // Emerging Stack = Color of the next level we are moving TOWARD
  color colorNext = color(unhex("FF" + p[1 + ((colorLevel + 1) % paletteCount)].substring(1)));
  
  // --- Animation Timing ---
  float zoomT = constrain(map(progress, 0.0, 0.3, 0, 1), 0, 1);
  float shrinkT = constrain(map(progress, 0.3, 0.5, 0, 1), 0, 1);
  float distributeT = constrain(map(progress, 0.5, 1.0, 0, 1), 0, 1);
  
  // --- Geometry Constants ---
  float targetScale = START_SIZE / END_SIZE; 
  float gap = (START_SIZE - (GRID_COUNT * END_SIZE)) / (GRID_COUNT - 1); 
  float gridStep = END_SIZE + gap; 
  
  // Perceptual zoom depth
  float currentZoom = pow(targetScale, zoomT);
  
  pushMatrix();
  scale(currentZoom);
  
  rectMode(CENTER);
  noStroke();

  // --- 1. BLEED SQUARES (Color of previous level) ---
  float bleedH = height * 5; 
  fill(colorBleed); // Correct color for the surrounding context
  
  // Clipping width to START_SIZE (400)
  rect(0, -(gridStep * targetScale) - (bleedH/2.0) + (END_SIZE * targetScale / 2.0), START_SIZE, bleedH);
  rect(0, (gridStep * targetScale) + (bleedH/2.0) - (END_SIZE * targetScale / 2.0), START_SIZE, bleedH);
  
  // --- 2. MAIN 3x3 GRID (Color of current level) ---
  fill(colorCurr); 
  for (int row = -1; row <= 1; row++) {
    for (int col = -1; col <= 1; col++) {
      if (row == 0 && col == 0) continue; 
      rect(col * gridStep, row * gridStep, END_SIZE, END_SIZE);
    }
  }
  
  // --- 3. CENTER STACK (Morphed to next color level) ---
  float shrunkenSize = END_SIZE / targetScale;
  float currentS = lerp(END_SIZE, shrunkenSize, shrinkT);
  float distStep = gridStep / targetScale;
  
  // The stack squares transition smoothly toward the color of the next level
  color stackColor = lerpColor(colorCurr, colorNext, progress);
  
  renderStack(0, 0, currentS, distributeT, distStep, shrunkenSize, stackColor);
  
  popMatrix();

  if (SAVE_FRAMES) saveFrame("frames/####.tif");
  if (frameCount >= MAX_FRAMES) noLoop();
}

/**
 * Renders the center stack of 9 squares with sequential distribution.
 */
void renderStack(float cx, float cy, float s, float t, float step, float targetS, color c) {
  for (int i = 0; i < 9; i++) {
    float tx = ((i % 3) - 1) * step;
    float ty = ((i / 3) - 1) * step;
    float x = cx;
    float y = cy;
    float dSize = (t > 0) ? targetS : s;

    if (t > 0 && i != 4) {
      int moveOrder = (i > 4) ? i - 1 : i;
      float pPhase = 1.0 / 8.0;
      float startT = moveOrder * pPhase;
      float endT = startT + pPhase;
      float indT = constrain(map(t, startT, endT, 0, 1), 0, 1);
      float easedT = 1 - pow(1 - indT, 3);
      x = lerp(cx, tx, easedT);
      y = lerp(cy, ty, easedT);
    }
    
    rectMode(CENTER);
    fill(c);
    noStroke();
    rect(x, y, dSize, dSize);
  }
}
