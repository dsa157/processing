/**
 * Unexpected Path: Decaying Recursive Spiral
 * Version: 2026.01.11.12.44.10
 * * Rule: Spiral resets and flips chirality at 2x radius.
 * Fix: Restored high-magnification zoom logic and applied smoothing to all camera axes.
 */

// --- Parameters ---
int SKETCH_WIDTH = 480; // 480
int SKETCH_HEIGHT = 800; // 800
int MAX_FRAMES = 900; // 900
boolean SAVE_FRAMES = false; // false
int ANIMATION_SPEED = 30; // 30
int GROWTH_SPEED = 8; // 8
int PADDING = 60; // 60
int SEED = 42; // 42
boolean SHOW_GRID = false; // false
boolean INVERT_BG = false; // false

// Visual Parameters
float PATH_THICKNESS = 4.0; // 4.0
float DECAY_RATE = 1.2; // 1.2
boolean COLOR_SHIFT = true; // true
float STEP_SIZE = 100.0; // 100.0
float ZOOM_LEVEL = 50.0; // 100.0
float CAMERA_SMOOTHING = 0.01; // 0.03 (Lower is smoother/slower)

// Palette Index (0-4)
int PALETTE_INDEX = 0; // 0

int[][] PALETTES = {
  {#264653, #2a9d8f, #e9c46a, #f4a261, #e76f51}, 
  {#001219, #005f73, #0a9396, #94d2bd, #e9d8a6}, 
  {#f8f9fa, #dee2e6, #adb5bd, #495057, #212529}, 
  {#ffbe0b, #fb5607, #ff006d, #8338ec, #3a86ff}, 
  {#220901, #621708, #941b0c, #bc3908, #f6aa1c}  
};

float PHI = (1 + sqrt(5)) / 2.0;

// Logic Variables
float currentAngle = 0;
float currentRadius = 2.0; 
float resetThreshold;
boolean isClockwise = true;
PVector currentOrigin, currentTip;
ArrayList<PathSegment> pathSegments;
int currentColorIndex = 1;

// Camera
float camX, camY, camScale = 1.0;

class PathSegment {
  ArrayList<PVector> points;
  int segColor;
  float alpha = 255;
  
  PathSegment(int c) {
    points = new ArrayList<PVector>();
    segColor = c;
  }
  
  void update() {
    alpha -= DECAY_RATE;
  }
  
  boolean isDead() {
    return alpha <= 0;
  }
}

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT, P2D);
}

void setup() {
  randomSeed(SEED);
  frameRate(ANIMATION_SPEED);
  
  resetThreshold = currentRadius * 2.0;
  currentOrigin = new PVector(0, 0);
  currentTip = new PVector(0, 0);
  
  pathSegments = new ArrayList<PathSegment>();
  pathSegments.add(new PathSegment(PALETTES[PALETTE_INDEX][currentColorIndex]));
  
  camX = 0;
  camY = 0;
  camScale = ZOOM_LEVEL;
}

void draw() {
  int[] activePalette = PALETTES[PALETTE_INDEX];
  int bgColor = INVERT_BG ? activePalette[activePalette.length - 1] : activePalette[0];
  background(bgColor);
  
  for (int i = 0; i < GROWTH_SPEED; i++) {
    updatePath();
  }
  
  for (int i = pathSegments.size() - 1; i >= 0; i--) {
    PathSegment seg = pathSegments.get(i);
    if (i < pathSegments.size() - 1) {
        seg.update();
    }
    if (seg.isDead()) {
      pathSegments.remove(i);
    }
  }

  updateCamera();

  pushMatrix();
  translate(width/2, height/2);
  scale(camScale);
  translate(-camX, -camY);

  if (SHOW_GRID) drawGrid(activePalette[2]);

  for (PathSegment seg : pathSegments) {
    // Glow Layer
    stroke(seg.segColor, seg.alpha * 0.3);
    strokeWeight((PATH_THICKNESS * 2.5) / camScale);
    drawSegment(seg);
    
    // Core Layer
    stroke(seg.segColor, seg.alpha);
    strokeWeight(PATH_THICKNESS / camScale);
    drawSegment(seg);
  }
  
  popMatrix();

  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) noLoop();
  }
}

void drawSegment(PathSegment seg) {
  noFill();
  beginShape();
  for (PVector p : seg.points) {
    vertex(p.x, p.y);
  }
  endShape();
}

void updatePath() {
  float radStep = STEP_SIZE * 0.001; 
  currentAngle += radStep;
  currentRadius *= pow(PHI, radStep / TWO_PI);
  
  float xOff = currentRadius * cos(currentAngle);
  float yOff = (isClockwise ? 1 : -1) * currentRadius * sin(currentAngle);
  currentTip = new PVector(currentOrigin.x + xOff, currentOrigin.y + yOff);
  
  if (pathSegments.size() > 0) {
    pathSegments.get(pathSegments.size() - 1).points.add(currentTip);
  }

  if (currentRadius >= resetThreshold) {
    currentOrigin = currentTip.copy();
    currentRadius = 1.0; 
    resetThreshold = 2.0; 
    isClockwise = !isClockwise;
    currentAngle = random(TWO_PI); 
    
    if (COLOR_SHIFT) {
      currentColorIndex = (currentColorIndex + 1) % PALETTES[PALETTE_INDEX].length;
      if (!INVERT_BG && currentColorIndex == 0) currentColorIndex = 1;
      if (INVERT_BG && currentColorIndex == PALETTES[PALETTE_INDEX].length - 1) currentColorIndex = 0;
    }
    pathSegments.add(new PathSegment(PALETTES[PALETTE_INDEX][currentColorIndex]));
  }
}

void updateCamera() {
  // Smoothly pan to the active tip
  camX = lerp(camX, currentTip.x, CAMERA_SMOOTHING);
  camY = lerp(camY, currentTip.y, CAMERA_SMOOTHING);
  
  // Directly use the ZOOM_LEVEL parameter for scale with smoothing
  camScale = lerp(camScale, ZOOM_LEVEL, CAMERA_SMOOTHING);
}

void drawGrid(int gridColor) {
  stroke(gridColor, 20);
  strokeWeight(1 / camScale);
  int gridStep = 50;
  int gridRange = 20000;
  for (int i = -gridRange; i < gridRange; i += gridStep) line(i, -gridRange, i, gridRange);
  for (int j = -gridRange; j < gridRange; j += gridStep) line(-gridRange, j, gridRange, j);
}
