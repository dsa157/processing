/**
 * Smoked Glass Flow (Decay & High Kinetic)
 * Version: 2026.01.15.20.58.12
 * Fast-moving ribbons that decay over time within a persistent buffer.
 * Overlaid with a slow-pulsing, large-format transparency grid.
 */

// --- Parameters ---
int SKETCH_WIDTH = 480;      // Default: 480
int SKETCH_HEIGHT = 800;     // Default: 800
int PADDING = 40;            // Default: 40
int MAX_FRAMES = 900;        // Default: 900
boolean SAVE_FRAMES = false; // Default: false
int ANIMATION_SPEED = 60;    // Default: 60 fps
int GLOBAL_SEED = 42;        // Default: 42
boolean SHOW_GRID = true;    // Default: true 
boolean INVERT_COLORS = false; // Default: false

// Flow Parameters
int PARTICLE_COUNT = 1000;    // User Param: 500
float NOISE_SCALE = 0.01;   // Default: 0.008
float NOISE_EVOLUTION = 0.01; // Default: 0.01
float RIBBON_SPEED = 5.5;    // User Param: 5.5
float RIBBON_ALPHA = 40;     // Default: 40 (Higher because of decay)
float STROKE_WEIGHT = 2.0;   // Default: 2.0
float DECAY_RATE = 12;       // Default: 12 (Speed of trail vanishing 0-255)

// Grid Overlay Parameters
int GRID_COLS = 4;           // User Param: 4
int GRID_ROWS = 7;           // User Param: 7
float ALPHA_MIN = 5;         // User Param: 5
float ALPHA_MAX = 200;       // User Param: 200
float PULSE_SPEED = 0.01;    // User Param: 0.01

// Color Palettes
int PALETTE_INDEX = 0; 
int[][] PALETTES = {
  {#1A1A1A, #333333, #4D4D4D, #666666, #808080}, // Smoked Grays
  {#0D1B2A, #1B263B, #415A77, #778DA9, #E0E1DD}, // Deep Blues
  {#2B2D42, #8D99AE, #EDF2F4, #EF233C, #D90429}, // Cool Slate
  {#121212, #242424, #363636, #484848, #5A5A5A}, // Obsidian
  {#220901, #621708, #941B0C, #BC3908, #F6AA1C}  // Ember Dark
};

Particle[] particles;
PGraphics ribbonLayer;
int bgColor;
int gridColor;
float[][] gridOffsets;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  frameRate(ANIMATION_SPEED);
  randomSeed(GLOBAL_SEED);
  noiseSeed(GLOBAL_SEED);
  
  int[] activePalette = PALETTES[PALETTE_INDEX];
  bgColor = INVERT_COLORS ? color(245) : activePalette[0];
  gridColor = INVERT_COLORS ? color(30) : activePalette[activePalette.length - 1];
  
  ribbonLayer = createGraphics(width, height);
  ribbonLayer.beginDraw();
  ribbonLayer.background(bgColor);
  ribbonLayer.endDraw();
  
  particles = new Particle[PARTICLE_COUNT];
  for (int i = 0; i < PARTICLE_COUNT; i++) {
    particles[i] = new Particle();
  }
  
  gridOffsets = new float[GRID_COLS][GRID_ROWS];
  for (int i = 0; i < GRID_COLS; i++) {
    for (int j = 0; j < GRID_ROWS; j++) {
      gridOffsets[i][j] = random(TWO_PI);
    }
  }
}

void draw() {
  // Update particles and draw to buffer
  ribbonLayer.beginDraw();
  
  // Apply Alpha Decay: Draw a rectangle with low alpha over the buffer
  ribbonLayer.noStroke();
  ribbonLayer.fill(bgColor, DECAY_RATE);
  ribbonLayer.rect(0, 0, width, height);
  
  for (Particle p : particles) {
    p.update();
    p.display(ribbonLayer);
  }
  ribbonLayer.endDraw();

  // Clear main canvas and show the decayed ribbon layer
  background(bgColor);
  image(ribbonLayer, 0, 0);

  if (SHOW_GRID) {
    drawAsynchronousGrid();
  }

  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) {
      noLoop();
    }
  }
}

void drawAsynchronousGrid() {
  float gridW = (width - 2 * PADDING) / (float)GRID_COLS;
  float gridH = (height - 2 * PADDING) / (float)GRID_ROWS;
  
  noStroke();
  for (int i = 0; i < GRID_COLS; i++) {
    for (int j = 0; j < GRID_ROWS; j++) {
      float x = PADDING + i * gridW;
      float y = PADDING + j * gridH;
      
      float phase = frameCount * PULSE_SPEED + gridOffsets[i][j];
      float currentAlpha = map(sin(phase), -1, 1, ALPHA_MIN, ALPHA_MAX);
      
      fill(gridColor, currentAlpha);
      rect(x + 2, y + 2, gridW - 4, gridH - 4);
    }
  }
}

class Particle {
  PVector pos;
  PVector prevPos;
  PVector vel;
  int ribbonColor;
  
  Particle() {
    init();
  }
  
  void init() {
    pos = new PVector(
      random(PADDING, width - PADDING), 
      random(PADDING, height - PADDING)
    );
    prevPos = pos.copy();
    vel = new PVector(0, 0);
    
    int colIdx = floor(random(1, PALETTES[PALETTE_INDEX].length));
    ribbonColor = PALETTES[PALETTE_INDEX][colIdx];
    
    if (INVERT_COLORS) {
      ribbonColor = color(255 - red(ribbonColor), 255 - green(ribbonColor), 255 - blue(ribbonColor));
    }
  }
  
  void update() {
    float angle = noise(pos.x * NOISE_SCALE, pos.y * NOISE_SCALE, frameCount * NOISE_EVOLUTION) * TWO_PI * 3;
    vel.x = cos(angle);
    vel.y = sin(angle);
    vel.mult(RIBBON_SPEED);
    
    prevPos.set(pos.x, pos.y);
    pos.add(vel);
    
    if (pos.x < PADDING || pos.x > width - PADDING || 
        pos.y < PADDING || pos.y > height - PADDING) {
      init();
    }
  }
  
  void display(PGraphics pg) {
    pg.strokeWeight(STROKE_WEIGHT);
    pg.stroke(ribbonColor, RIBBON_ALPHA);
    pg.line(prevPos.x, prevPos.y, pos.x, pos.y);
  }
}
