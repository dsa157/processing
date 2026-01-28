/**
 * Recursive Grid Zoom - Variation: Glyph Morph (Refined)
 * Version: 2026.01.20.10.55.00
 * * Changes:
 * - Filtered library to: Diamond Frame, Nested Squares, X Target, Split Circle.
 * - Added GLYPH_SCALE parameter for internal sizing.
 * - Added DETAIL_SIZE and SHOW_DETAILS for corner/intersection decorations.
 * - Palette index set to 1 (Deep Sea).
 * - Rotation and layout synchronized for seamless looping.
 */

// --- Parameters ---
int SKETCH_WIDTH = 480;      // Default: 480
int SKETCH_HEIGHT = 800;     // Default: 800
int MAX_FRAMES = 800;        // Default: 900
boolean SAVE_FRAMES = false; // Default: false
int ANIMATION_SPEED = 30;    // Default: 30
int CYCLE_LENGTH = 100;      // Default: 150
int GLOBAL_SEED = 42;        // Default: 42
float CANVAS_PADDING = 40;   // Default: 40

// Logic Parameters
float START_SIZE = 400;      // Default: 400
float END_SIZE = 118;        // Default: 118
int GRID_COUNT = 3;          // Default: 3
boolean INVERT_BACK = false; // Default: false
boolean SHOW_GRID_CELLS = false; // Default: false

// Glyph Visual Parameters
float GLYPH_SCALE = 1.2;    // Default: 0.85 (Internal scale of the design)
float DETAIL_SIZE = 6.0;     // Default: 6.0 (Size of decorative circles)
boolean SHOW_DETAILS = true; // Default: true
int GLYPH_TYPE = 2;          // Default: 0 (Select 0-3)
String[] GLYPH_NAMES = {
  "Diamond Frame", "Nested Squares", "X Target", "Split Circle"
};

// Color Palettes
String[][] PALETTES = {
  {"#264653", "#2a9d8f", "#e9c46a", "#f4a261", "#e76f51"}, // Palette 0: Terra Cotta
  {"#001219", "#005f73", "#0a9396", "#94d2bd", "#e9d8a6"}, // Palette 1: Deep Sea
  {"#ffbe0b", "#fb5607", "#ff006d", "#8338ec", "#3a86ff"}, // Palette 2: Cyber
  {"#22223b", "#4a4e69", "#9a8c98", "#c9ada7", "#f2e9e4"}, // Palette 3: Muted
  {"#1a1c2c", "#5d275d", "#b13e53", "#ef7d57", "#ffcd75"}  // Palette 4: Sunset
};
int PALETTE_INDEX = 3; // Updated to 1

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
  
  color colorBleed = color(unhex("FF" + p[1 + ((colorLevel + paletteCount - 1) % paletteCount)].substring(1)));
  color colorCurr = color(unhex("FF" + p[1 + (colorLevel % paletteCount)].substring(1)));
  color colorNext = color(unhex("FF" + p[1 + ((colorLevel + 1) % paletteCount)].substring(1)));
  
  // --- Animation Timing ---
  float zoomT = constrain(map(progress, 0.0, 0.4, 0, 1), 0, 1);
  float shrinkT = constrain(map(progress, 0.4, 0.6, 0, 1), 0, 1);
  float distributeT = constrain(map(progress, 0.6, 1.0, 0, 1), 0, 1);
  
  // --- Geometry Constants ---
  float targetScale = START_SIZE / END_SIZE; 
  float gap = (START_SIZE - (GRID_COUNT * END_SIZE)) / (GRID_COUNT - 1); 
  float gridStep = END_SIZE + gap; 
  float currentZoom = pow(targetScale, zoomT);
  
  pushMatrix();
  scale(currentZoom);
  
  // --- 1. BLEED GLYPHS (Background) ---
  drawGlyph(0, -gridStep * targetScale, START_SIZE, colorBleed, progress, GLYPH_TYPE);
  drawGlyph(0, gridStep * targetScale, START_SIZE, colorBleed, progress, GLYPH_TYPE);
  
  // --- 2. MAIN 3x3 GRID ---
  for (int row = -1; row <= 1; row++) {
    for (int col = -1; col <= 1; col++) {
      if (row == 0 && col == 0) continue; 
      drawGlyph(col * gridStep, row * gridStep, END_SIZE, colorCurr, progress, GLYPH_TYPE);
    }
  }
  
  // --- 3. CENTER STACK ---
  float shrunkenSize = END_SIZE / targetScale;
  float currentS = lerp(END_SIZE, shrunkenSize, shrinkT);
  float distStep = gridStep / targetScale;
  color stackColor = lerpColor(colorCurr, colorNext, progress);
  
  renderGlyphStack(0, 0, currentS, distributeT, distStep, shrunkenSize, stackColor, progress);
  
  popMatrix();

  if (SAVE_FRAMES) saveFrame("frames/####.tif");
  if (frameCount >= MAX_FRAMES && SAVE_FRAMES) noLoop();
}

void renderGlyphStack(float cx, float cy, float s, float t, float step, float targetS, color c, float prog) {
  for (int i = 0; i < 9; i++) {
    float tx = ((i % 3) - 1) * step;
    float ty = ((i / 3) - 1) * step;
    float x = cx;
    float y = cy;
    float dSize = (t > 0) ? targetS : s;

    if (t > 0 && i != 4) {
      int moveOrder = (i > 4) ? i - 1 : i;
      float indT = constrain(map(t, moveOrder * 0.125, (moveOrder + 1) * 0.125, 0, 1), 0, 1);
      float easedT = 1 - pow(1 - indT, 3);
      x = lerp(cx, tx, easedT);
      y = lerp(cy, ty, easedT);
    }
    drawGlyph(x, y, dSize, c, prog, GLYPH_TYPE);
  }
}

void drawGlyph(float x, float y, float size, color c, float prog, int type) {
  pushMatrix();
  translate(x, y);
  rotate(prog * HALF_PI); 
  
  if (SHOW_GRID_CELLS) {
    stroke(c, 40);
    noFill();
    rectMode(CENTER);
    rect(0, 0, size, size);
  }

  stroke(c);
  strokeWeight(size * 0.05); 
  noFill();
  strokeCap(PROJECT);
  
  // Apply GLYPH_SCALE to the drawing context
  pushMatrix();
  scale(GLYPH_SCALE);
  drawGlyphDesign(size, prog, type, c);
  popMatrix();
  
  popMatrix();
}

void drawGlyphDesign(float s, float p, int type, color c) {
  float r = s/2;
  float dSize = DETAIL_SIZE * (s / END_SIZE); // Scale detail with glyph size

  switch(type) {
    case 0: // Diamond Frame
      beginShape();
      vertex(0, -r); vertex(r, 0); vertex(0, r); vertex(-r, 0);
      endShape(CLOSE);
      if (SHOW_DETAILS) {
        fill(c); noStroke();
        ellipse(0, -r, dSize, dSize); ellipse(r, 0, dSize, dSize);
        ellipse(0, r, dSize, dSize); ellipse(-r, 0, dSize, dSize);
        noFill(); stroke(c);
      }
      break;
      
    case 1: // Nested Squares
      rectMode(CENTER);
      rect(0, 0, s*0.7, s*0.7);
      rect(0, 0, s*0.2, s*0.2);
      if (SHOW_DETAILS) {
        fill(c); noStroke();
        float corner = s*0.35;
        ellipse(-corner, -corner, dSize, dSize); ellipse(corner, -corner, dSize, dSize);
        ellipse(corner, corner, dSize, dSize); ellipse(-corner, corner, dSize, dSize);
        noFill(); stroke(c);
      }
      break;
      
    case 2: // X Target
      line(-r, -r, r, r); line(r, -r, -r, r);
      ellipse(0, 0, s*0.5, s*0.5);
      if (SHOW_DETAILS) {
        fill(c); noStroke();
        ellipse(-r, -r, dSize, dSize); ellipse(r, -r, dSize, dSize);
        ellipse(r, r, dSize, dSize); ellipse(-r, r, dSize, dSize);
        ellipse(0, 0, dSize, dSize);
        noFill(); stroke(c);
      }
      break;
      
    case 3: // Split Circle
      ellipse(0, 0, s, s);
      line(-r, 0, r, 0);
      line(0, -r, 0, r);
      if (SHOW_DETAILS) {
        fill(c); noStroke();
        ellipse(0, 0, dSize, dSize);
        ellipse(-r, 0, dSize, dSize); ellipse(r, 0, dSize, dSize);
        ellipse(0, -r, dSize, dSize); ellipse(0, r, dSize, dSize);
        noFill(); stroke(c);
      }
      break;
  }
}
