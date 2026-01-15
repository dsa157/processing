/**
 * Topographic Rings: Perlin Noise Polar
 * Version: 2026.01.06.22.15.40
 * * Generates organic, concentric rings using 2D Perlin Noise 
 * mapped to polar coordinates for seamless looping.
 */

// --- Configuration Parameters ---
int SKETCH_WIDTH = 480;       // Default: 480
int SKETCH_HEIGHT = 800;      // Default: 800
int RANDOM_SEED = 42;         // Default: 42
int PADDING = 40;             // Default: 40
int MAX_FRAMES = 900;         // Default: 900
boolean SAVE_FRAMES = false;  // Default: false
int ANIMATION_SPEED = 30;     // Default: 30
int RING_COUNT = 45;          // Default: 45
float NOISE_STRENGTH = 120.0; // Default: 120.0
float NOISE_SCALE = 0.8;      // Default: 0.8
float Z_STEP = 0.008;         // Default: 0.008
float STROKE_WEIGHT = 1.5;    // Default: 1.5
boolean SHOW_GRID = false;    // Default: false
boolean INVERT_COLORS = false;// Default: false
int PALETTE_INDEX = 1;        // Default: 0 (0 to 4)

// --- Color Palettes (Adobe Color / Kuler) ---
int[][] palettes = {
  {#264653, #2a9d8f, #e9c46a, #f4a261, #e76f51}, // Terra Cotta
  {#001219, #005f73, #0a9396, #94d2bd, #e9d8a6}, // Deep Sea
  {#5f0f40, #9a031e, #fb8b24, #e36414, #0f4c5c}, // Retro Fire
  {#22223b, #4a4e69, #9a8c98, #c9ada7, #f2e9e4}, // Muted Stone
  {#118ab2, #06d6a0, #ffd166, #ef476f, #073b4c}  // Pop Art
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
  int strokeColor = currentPalette[1];
  
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
    // Pick color from palette based on ring index
    int col = currentPalette[1 + (i % (currentPalette.length - 1))];
    if (INVERT_COLORS) {
      stroke(255 - red(col), 255 - green(col), 255 - blue(col), 180);
    } else {
      stroke(col, 180);
    }
    
    strokeWeight(STROKE_WEIGHT);
    
    float baseRadius = map(i, 0, RING_COUNT, 10, maxRadius);
    drawOrganicRing(baseRadius, zOff + (i * 0.02));
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
  for (float a = 0; a < TWO_PI; a += 0.05) {
    // 2D Perlin Noise in Polar Space for seamless wrapping
    float xOff = map(cos(a), -1, 1, 0, NOISE_SCALE);
    float yOff = map(sin(a), -1, 1, 0, NOISE_SCALE);
    
    float n = noise(xOff, yOff, z);
    float r = radius + map(n, 0, 1, -NOISE_STRENGTH, NOISE_STRENGTH);
    
    float x = r * cos(a);
    float y = r * sin(a);
    vertex(x, y);
  }
  endShape(CLOSE);
}

void drawDebugGrid() {
  stroke(150, 50);
  strokeWeight(1);
  for (int x = PADDING; x <= width - PADDING; x += 40) {
    line(x, PADDING, x, height - PADDING);
  }
  for (int y = PADDING; y <= height - PADDING; y += 40) {
    line(PADDING, y, width - PADDING, y);
  }
}
