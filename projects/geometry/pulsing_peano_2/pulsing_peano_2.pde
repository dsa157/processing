/**
 * Oscillation-Driven Peano Flows
 * Animates curve tightness through a defined range to create a breathing effect.
 * Version: 2026.01.15.11.45.50
 */

// --- Parameters ---
int SKETCH_WIDTH = 480;       // default: 480
int SKETCH_HEIGHT = 800;      // default: 800
int RANDOM_SEED = 222;        // default: 222
int PADDING = 20;             // default: 20
int MAX_FRAMES = 900;         // default: 900
boolean SAVE_FRAMES = false;  // default: false
int ANIMATION_SPEED = 30;     // default: 30
boolean INVERT_BG = false;    // default: false

// Grid and Curve Parameters
int GRID_COLS = 2;            // default: 3
int GRID_ROWS = 3;            // default: 5
int MAX_RECURSION = 1;        // default: 1
float STROKE_WEIGHT = 2.5f;   // default: 2.5
float GLOW_SIZE = 12.0f;      // default: 12.0
float COLOR_SPEED = 0.15f;    // default: 0.15
float MAX_DIST_FACTOR = 2.6f; // default: 4.6

// Animation Range Parameters
float CURVE_TIGHTNESS_MIN = -5.0f; // default: -5.0
float CURVE_TIGHTNESS_MAX = 10.0f; // default: 10.0
float TIGHTNESS_SPEED = 0.02f;     // default: 0.02

// --- Color Palettes ---
int[][] PALETTES = {
  {#0A0A0A, #00FFD1, #32CCFF, #9000FF, #FF0055}, 
  {#050505, #E94560, #0F3460, #16213E, #533483},
  {#101010, #00FF00, #ADFF2F, #32CD32, #006400},
  {#000000, #F64F59, #C471ED, #12C2E9, #FFFFFF},
  {#080808, #7D11FE, #FF2079, #440BD4, #00D7FF}
};
int PALETTE_INDEX = 2; 

// --- Internal Variables ---
ArrayList<PVector> points = new ArrayList<PVector>();
float stepThreshold;
int bgCol;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  randomSeed(RANDOM_SEED);
  noiseSeed(RANDOM_SEED);
  frameRate(ANIMATION_SPEED);
  
  int[] cp = PALETTES[PALETTE_INDEX];
  bgCol = INVERT_BG ? color(245) : cp[0];
  
  float totalW = width - PADDING * 2;
  float totalH = height - PADDING * 2;
  float cellW = totalW / GRID_COLS;
  float cellH = totalH / GRID_ROWS;
  
  stepThreshold = (cellW / pow(3, MAX_RECURSION)) * MAX_DIST_FACTOR;

  // Generate the Peano path nodes
  for (int r = 0; r < GRID_ROWS; r++) {
    for (int c = 0; c < GRID_COLS; c++) {
      int actualC = (r % 2 == 0) ? c : (GRID_COLS - 1 - c);
      float x = PADDING + actualC * cellW;
      float y = PADDING + r * cellH;
      generatePeano(x, y, cellW, cellH, MAX_RECURSION);
    }
  }
}

void draw() {
  background(bgCol);
  
  float time = frameCount * 0.03f;
  int activeColor = getGlobalCycleColor(frameCount * COLOR_SPEED);
  
  // Animate Curve Tightness
  float tightnessCycle = (sin(frameCount * TIGHTNESS_SPEED) + 1) / 2.0f; // 0.0 to 1.0
  float currentTightness = lerp(CURVE_TIGHTNESS_MIN, CURVE_TIGHTNESS_MAX, tightnessCycle);
  
  noFill();
  curveTightness(currentTightness);
  
  // 1. Glow Pass (Additive)
  blendMode(ADD);
  for (int g = 3; g > 0; g--) {
    stroke(activeColor, 40 / g);
    strokeWeight(STROKE_WEIGHT + (g * GLOW_SIZE * abs(sin(time))));
    renderSegmentedCurve(time);
  }

  // 2. Core Pass (Standard)
  blendMode(BLEND);
  stroke(255, 200);
  strokeWeight(STROKE_WEIGHT);
  renderSegmentedCurve(time);

  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) noLoop();
  }
}

/**
 * Renders the spline path, breaking lines if the distance exceeds stepThreshold.
 */
void renderSegmentedCurve(float t) {
  if (points.size() < 2) return;

  boolean inShape = false;
  
  for (int i = 0; i < points.size() - 1; i++) {
    PVector p1 = points.get(i);
    PVector p2 = points.get(i + 1);
    
    if (PVector.dist(p1, p2) < stepThreshold) {
      if (!inShape) {
        beginShape();
        curveVertex(p1.x, p1.y);
        inShape = true;
      }
      
      // Subtle noise jitter for organic feel
      float nx = p1.x + (noise(p1.x * 0.01, t) - 0.5) * 10;
      float ny = p1.y + (noise(p1.y * 0.01, t + 5) - 0.5) * 10;
      curveVertex(nx, ny);
      
    } else {
      if (inShape) {
        curveVertex(p1.x, p1.y);
        endShape();
        inShape = false;
      }
    }
  }
  
  if (inShape) {
    PVector last = points.get(points.size()-1);
    curveVertex(last.x, last.y);
    endShape();
  }
}

void generatePeano(float x, float y, float w, float h, int depth) {
  if (depth == 0) {
    points.add(new PVector(x + w/2, y + h/2));
    return;
  }

  float nw = w / 3.0f;
  float nh = h / 3.0f;

  int[][] path = {
    {0, 0}, {0, 1}, {0, 2},
    {1, 2}, {1, 1}, {1, 0},
    {2, 0}, {2, 1}, {2, 2}
  };

  for (int i = 0; i < 9; i++) {
    if (random(1.0) > 0.99) continue; 
    generatePeano(x + path[i][0] * nw, y + path[i][1] * nh, nw, nh, depth - 1);
  }
}

int getGlobalCycleColor(float offset) {
  int[] cp = PALETTES[PALETTE_INDEX];
  int count = cp.length - 1;
  float val = offset % count;
  int i1 = floor(val) + 1;
  int i2 = (i1 % count) + 1;
  return lerpColor(cp[i1], cp[i2], val - floor(val));
}
