/**
 * Topographic Rings: Perlin Noise Polar
 * Version: 2026.01.06.22.18.15
 * * Generates organic, undulating rings using 2D Perlin Noise.
 * * Added NOISE_COMPLEXITY and GLITCH_STRENGTH parameters.
 */

// --- Configuration Parameters ---
int SKETCH_WIDTH = 480;       // Default: 480
int SKETCH_HEIGHT = 800;      // Default: 800
int RANDOM_SEED = 42;         // Default: 42
int PADDING = 40;             // Default: 40
int MAX_FRAMES = 900;         // Default: 900
boolean SAVE_FRAMES = false;  // Default: false
int ANIMATION_SPEED = 30;     // Default: 30

// --- Effect Parameters ---
int RING_COUNT = 50;          // Default: 50
float NOISE_STRENGTH = 300.0; // Default: 110.0
float NOISE_SCALE = 0.5;      // Default: 0.9
float NOISE_COMPLEXITY = 0.01; // Default: 0.1 (Step size for angle - lower is smoother)
float GLITCH_STRENGTH = 3.0;  // Default: 0.0 (Try 2.0 - 5.0 for jagged artifacts)
float Z_STEP = 0.007;         // Default: 0.007
float STROKE_WEIGHT = 1.2;    // Default: 1.2

boolean SHOW_GRID = false;    // Default: false
boolean INVERT_COLORS = false;// Default: false
int PALETTE_INDEX = 1;        // Default: 1

// --- Color Palettes (Adobe Color) ---
int[][] palettes = {
  {#264653, #2a9d8f, #e9c46a, #f4a261, #e76f51}, 
  {#001219, #005f73, #0a9396, #94d2bd, #e9d8a6}, 
  {#5f0f40, #9a031e, #fb8b24, #e36414, #0f4c5c}, 
  {#22223b, #4a4e69, #9a8c98, #c9ada7, #f2e9e4}, 
  {#118ab2, #06d6a0, #ffd166, #ef476f, #073b4c}  
};

float zOff = 0.0;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  randomSeed(RANDOM_SEED);
  noiseSeed(RANDOM_SEED);
  frameRate(ANIMATION_SPEED);
}

void draw() {
  int[] currentPalette = palettes[PALETTE_INDEX];
  int bgColor = currentPalette[0];
  
  if (INVERT_COLORS) {
    background(255 - red(bgColor), 255 - green(bgColor), 255 - blue(bgColor));
  } else {
    background(bgColor);
  }

  if (SHOW_GRID) drawDebugGrid();

  pushMatrix();
  translate(width / 2, height / 2);
  noFill();
  
  float maxRadius = (min(width, height) / 2.0) - PADDING;

  for (int i = 0; i < RING_COUNT; i++) {
    int col = currentPalette[1 + (i % (currentPalette.length - 1))];
    if (INVERT_COLORS) {
      stroke(255 - red(col), 255 - green(col), 255 - blue(col), 160);
    } else {
      stroke(col, 160);
    }
    
    strokeWeight(STROKE_WEIGHT);
    
    // Rings grow outward from center
    float baseRadius = map(i, 0, RING_COUNT, 5, maxRadius);
    drawOrganicRing(baseRadius, zOff + (i * 0.015));
  }
  popMatrix();

  zOff += Z_STEP;

  // --- Export & Loop Control ---
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) {
      noLoop();
    }
  }
}

void drawOrganicRing(float radius, float z) {
  beginShape();
  // NOISE_COMPLEXITY determines the resolution of the ring
  for (float a = 0; a < TWO_PI; a += NOISE_COMPLEXITY) {
    float xOff = map(cos(a), -1, 1, 0, NOISE_SCALE);
    float yOff = map(sin(a), -1, 1, 0, NOISE_SCALE);
    
    float n = noise(xOff, yOff, z);
    float r = radius + map(n, 0, 1, -NOISE_STRENGTH, NOISE_STRENGTH);
    
    // Apply Glitch: Random jitter based on GLITCH_STRENGTH
    float glitchX = random(-GLITCH_STRENGTH, GLITCH_STRENGTH);
    float glitchY = random(-GLITCH_STRENGTH, GLITCH_STRENGTH);
    
    float x = r * cos(a) + glitchX;
    float y = r * sin(a) + glitchY;
    vertex(x, y);
  }
  endShape(CLOSE);
}

void drawDebugGrid() {
  stroke(150, 40);
  strokeWeight(1);
  for (int x = PADDING; x <= width - PADDING; x += 40) {
    line(x, PADDING, x, height - PADDING);
  }
  for (int y = PADDING; y <= height - PADDING; y += 40) {
    line(PADDING, y, width - PADDING, y);
  }
}
