/**
 * Organic Glowing Peano Flows
 * Eliminates straight lines through Bezier interpolation and fills the 480x800 canvas.
 * Version: 2026.01.15.11.35.10
 */

// --- Parameters ---
int SKETCH_WIDTH = 480;       // default: 480
int SKETCH_HEIGHT = 800;      // default: 800
int RANDOM_SEED = 1234;       // default: 1234
int PADDING = 20;             // default: 20
int MAX_FRAMES = 900;         // default: 900
boolean SAVE_FRAMES = false;  // default: false
int ANIMATION_SPEED = 30;     // default: 30
boolean INVERT_BG = false;    // default: false

// Curve Specific Parameters
int MAX_RECURSION = 3;        // default: 3
float NOISE_SCALE = 0.003f;   // default: 0.003
float NOISE_STRENGTH = 50.0f; // default: 50.0
float GLOW_MULT = 12.0f;      // default: 12.0
float COLOR_CYCLE_SPEED = 0.01f; // default: 0.01

// --- Color Palettes ---
int[][] PALETTES = {
  {#0A0A0A, #FF0055, #00FFD1, #ADFF2F, #FF8300}, 
  {#050505, #50C878, #007FFF, #89CFF0, #F4FDFF},
  {#101010, #FF3F00, #FFFB00, #00FF5F, #00B9FF},
  {#000000, #E100FF, #7F00FF, #00FFFF, #00FF00},
  {#080808, #FFFFFF, #AAAAAA, #444444, #222222}
};
int PALETTE_INDEX = 2; // default: 2

// --- Internal Variables ---
ArrayList<PVector> pathPoints;
int bgCol;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  randomSeed(RANDOM_SEED);
  noiseSeed(RANDOM_SEED);
  frameRate(ANIMATION_SPEED);
  
  int[] cp = PALETTES[PALETTE_INDEX];
  bgCol = INVERT_BG ? color(250) : cp[0];
  
  pathPoints = new ArrayList<PVector>();
  
  // Fill the canvas by calculating 3x3 subdivisions tailored to aspect ratio
  generateOrganicPeano(PADDING, PADDING, width - PADDING*2, height - PADDING*2, MAX_RECURSION);
}

void draw() {
  background(bgCol);
  
  float time = frameCount * 0.02f;
  float colorShift = frameCount * COLOR_CYCLE_SPEED;
  
  blendMode(ADD);
  noFill();

  // Draw multiple glowing layers
  for (int j = 4; j > 0; j--) {
    strokeWeight(1.0f + (j * GLOW_MULT * abs(sin(time * 0.5f))));
    beginShape();
    for (int i = 0; i < pathPoints.size(); i++) {
      PVector p = pathPoints.get(i);
      
      // Calculate dynamic noise offset
      float nx = p.x + (noise(p.x * NOISE_SCALE, p.y * NOISE_SCALE, time) - 0.5f) * NOISE_STRENGTH;
      float ny = p.y + (noise(p.y * NOISE_SCALE, p.x * NOISE_SCALE, time + 50) - 0.5f) * NOISE_STRENGTH;
      
      // Cycle colors through the palette index over time
      stroke(getCycleColor(i + colorShift), 40 / j);
      curveVertex(nx, ny);
    }
    endShape();
  }

  // Core bright line
  strokeWeight(2);
  stroke(255, 180);
  beginShape();
  for (PVector p : pathPoints) {
    float nx = p.x + (noise(p.x * NOISE_SCALE, p.y * NOISE_SCALE, time) - 0.5f) * NOISE_STRENGTH;
    float ny = p.y + (noise(p.y * NOISE_SCALE, p.x * NOISE_SCALE, time + 50) - 0.5f) * NOISE_STRENGTH;
    curveVertex(nx, ny);
  }
  endShape();

  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) noLoop();
  }
}

/**
 * Recursively creates points. Unlike standard Peano, it adds mid-points
 * to ensure the curve renderer has enough vertices to stay "curvy".
 */
void generateOrganicPeano(float x, float y, float w, float h, int depth) {
  if (depth == 0) {
    // Add point with slight jitter to prevent perfect grid alignment
    pathPoints.add(new PVector(x + w/2 + random(-2, 2), y + h/2 + random(-2, 2)));
    return;
  }

  float nw = w / 3.0f;
  float nh = h / 3.0f;
  
  // Peano path: S-curve mapping
  int[][] grid = {
    {0, 0}, {0, 1}, {0, 2},
    {1, 2}, {1, 1}, {1, 0},
    {2, 0}, {2, 1}, {2, 2}
  };

  for (int i = 0; i < 9; i++) {
    // Randomly prune branches to create non-uniform density
    if (random(1.0) > 0.98) continue; 
    
    generateOrganicPeano(
      x + grid[i][0] * nw, 
      y + grid[i][1] * nh, 
      nw, nh, 
      depth - 1
    );
  }
}

/**
 * Interpolates between palette colors based on a continuous offset
 */
int getCycleColor(float offset) {
  int[] cp = PALETTES[PALETTE_INDEX];
  float index = offset % (cp.length - 1);
  int i1 = floor(index) + 1;
  int i2 = (i1 % (cp.length - 1)) + 1;
  return lerpColor(cp[i1], cp[i2], index - floor(index));
}
