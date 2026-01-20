/**
 * Chiaroscuro Harris Spirals: Focus on Value and Space
 * Version: 2026.01.15.12.11.04
 * Technique: Golden Ratio Recursion & High-Contrast Tonal Arcs
 */

// --- Global Parameters ---
int SKETCH_WIDTH = 480;       // Default: 480
int SKETCH_HEIGHT = 800;      // Default: 800
int RANDOM_SEED = 42;         // Default: 42
int PADDING = 40;             // Default: 40
int MAX_FRAMES = 900;         // Default: 900
boolean SAVE_FRAMES = false;  // Default: false
int ANIMATION_SPEED = 30;     // Default: 30
boolean INVERT_COLORS = false;// Default: false
boolean SHOW_GRID = false;    // Default: false

// --- Aesthetic Parameters ---
int PALETTE_INDEX = 1;        // Default: 0 (Range 0-4)
float MIN_STROKE = 0.5;       // Default: 0.5
float MAX_STROKE = 4.0;       // Default: 8.0
float PHI = (1 + sqrt(5)) / 2; // Golden Ratio

// --- Color Palettes (Adobe Color / Kuler Inspired) ---
color[][] PALETTES = {
  {#0D0D0D, #262626, #404040, #F2F2F2, #A6A6A6}, // Monochrome Industrial
  {#1A1A1A, #5E5E5E, #999999, #D9D9D9, #FFFFFF}, // High Contrast Silver
  {#021126, #043359, #08738C, #BFD1D9, #F2F2F2}, // Deep Blue Slate
  {#261201, #593112, #8C5E35, #BF9B7A, #F2E3D5}, // Sepia Shadows
  {#0D0D0D, #1F2601, #455902, #A1A602, #F2F2F2}  // Dark Moss & Bone
};

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  randomSeed(RANDOM_SEED);
  frameRate(ANIMATION_SPEED);
  noFill();
}

void draw() {
  // Determine Background and Foreground
  color[] activePalette = PALETTES[PALETTE_INDEX];
  color bgColor = activePalette[0];
  color primaryColor = activePalette[3];
  
  if (INVERT_COLORS) {
    bgColor = activePalette[3];
    primaryColor = activePalette[0];
  }
  
  background(bgColor);
  
  // Calculate drawing area
  float drawW = width - (PADDING * 2);
  float drawH = height - (PADDING * 2);
  
  pushMatrix();
  translate(PADDING, PADDING);
  
  // Start Recursion
  drawHarrisSpiral(0, 0, drawW, drawH, 8);
  
  popMatrix();

  // --- Frame Management ---
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) {
      noLoop();
    }
  }
}

/**
 * Recursive function to draw Harris Spiral subdivisions
 */
void drawHarrisSpiral(float x, float y, float w, float h, int depth) {
  if (depth <= 0) return;

  // Draw Grid if enabled
  if (SHOW_GRID) {
    stroke(PALETTES[PALETTE_INDEX][1], 50);
    strokeWeight(1);
    rect(x, y, w, h);
  }

  // Determine split (Horizontal vs Vertical)
  boolean horizontal = w > h;
  
  if (horizontal) {
    float split = w / PHI;
    renderChiaroscuroArc(x, y, split, h, 1);
    drawHarrisSpiral(x + split, y, w - split, h, depth - 1);
  } else {
    float split = h / PHI;
    renderChiaroscuroArc(x, y, w, split, 2);
    drawHarrisSpiral(x, y + split, w, h - split, depth - 1);
  }
}

/**
 * Renders an arc with variable stroke weight to create depth
 */
void renderChiaroscuroArc(float x, float y, float w, float h, int orientation) {
  int density = 15; // Number of lines per arc for value gradient
  
  for (int i = 0; i < density; i++) {
    float inter = map(i, 0, density - 1, 0, 1);
    float sw = map(sin(inter * PI + (frameCount * 0.05)), -1, 1, MIN_STROKE, MAX_STROKE);
    
    // Select color from palette based on "light" (inter)
    color c = lerpColor(PALETTES[PALETTE_INDEX][1], PALETTES[PALETTE_INDEX][4], inter);
    if(INVERT_COLORS) c = lerpColor(PALETTES[PALETTE_INDEX][4], PALETTES[PALETTE_INDEX][1], inter);
    
    stroke(c, 200);
    strokeWeight(sw);
    
    // Vary arc based on orientation to fill the square/rectangle
    if (orientation == 1) {
      // Arc from top-right to bottom-left
      arc(x + w, y, w * 2 * inter, h * 2 * inter, HALF_PI, PI);
    } else {
      // Arc from bottom-left to top-right
      arc(x, y + h, w * 2 * inter, h * 2 * inter, PI + HALF_PI, TWO_PI);
    }
  }
}
