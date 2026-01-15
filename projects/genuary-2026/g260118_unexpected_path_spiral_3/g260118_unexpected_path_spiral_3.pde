/**
 * Unexpected Path: Recursive Golden Spiral Growth 
 * Rule: Spiral doubles in radius -> Reset origin to tip -> Flip chirality.
 * Features: Dynamic Camera, High-Speed Step, Recursive Color Shifting.
 */

// --- Parameters ---
int SKETCH_WIDTH = 480; // 480
int SKETCH_HEIGHT = 800; // 800
int MAX_FRAMES = 900; // 900
boolean SAVE_FRAMES = false; // false
int ANIMATION_SPEED = 30; // 30 (FPS)
int GROWTH_SPEED = 8; // 8 (Calculations per frame)
int PADDING = 40; // 40
int SEED = 42; // 42
boolean SHOW_GRID = false; // false
boolean INVERT_BG = false; // false

// New Parameters
float STEP_SIZE = 20.0; // 30.0 (Higher values make the path more angular/abstract)
boolean COLOR_SHIFT = true; // true (Changes color at every reset point)

// Palette Index (0-4)
int PALETTE_INDEX = 0; // 4

// Color Palettes (Adobe Color / Kuler)
int[][] PALETTES = {
  {#264653, #2a9d8f, #e9c46a, #f4a261, #e76f51}, // Terra Cotta
  {#001219, #005f73, #0a9396, #94d2bd, #e9d8a6}, // Deep Sea
  {#f8f9fa, #dee2e6, #adb5bd, #495057, #212529}, // Grayscale
  {#ffbe0b, #fb5607, #ff006d, #8338ec, #3a86ff}, // Neon Pop
  {#220901, #621708, #941b0c, #bc3908, #f6aa1c}  // Burnt Ember
};

// Golden Ratio Constant
float PHI = (1 + sqrt(5)) / 2.0; // ~1.618

// Logic Variables
float currentAngle = 0;
float currentRadius = 2.0; 
float resetThreshold;
boolean isClockwise = true;
PVector currentOrigin;
PVector currentTip;
ArrayList<PathSegment> pathSegments;
int currentColorIndex = 1;

// Camera Variables
float camX, camY;
float camScale = 1.0;
float minX, maxX, minY, maxY;

class PathSegment {
  ArrayList<PVector> points;
  int segColor;

  PathSegment(int c) {
    points = new ArrayList<PVector>();
    segColor = c;
  }
}

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  randomSeed(SEED);
  frameRate(ANIMATION_SPEED);
  
  resetThreshold = currentRadius * 2.0;
  currentOrigin = new PVector(0, 0);
  currentTip = new PVector(0, 0);
  
  pathSegments = new ArrayList<PathSegment>();
  pathSegments.add(new PathSegment(PALETTES[PALETTE_INDEX][currentColorIndex]));
  pathSegments.get(0).points.add(new PVector(0, 0));
  
  minX = maxX = minY = maxY = 0;
}

void draw() {
  int[] activePalette = PALETTES[PALETTE_INDEX];
  int bgColor = INVERT_BG ? activePalette[activePalette.length - 1] : activePalette[0];
  
  background(bgColor);
  
  for (int i = 0; i < GROWTH_SPEED; i++) {
    updatePath();
  }

  updateCamera();

  pushMatrix();
  translate(width/2, height/2);
  scale(camScale);
  translate(-camX, -camY);

  if (SHOW_GRID) drawGrid(activePalette[2]);

  // Draw the path segments
  noFill();
  for (PathSegment seg : pathSegments) {
    stroke(seg.segColor);
    strokeWeight(2 / camScale);
    beginShape();
    for (PVector p : seg.points) {
      vertex(p.x, p.y);
    }
    endShape();
  }

  // Draw the tip
  fill(activePalette[3]);
  noStroke();
  ellipse(currentTip.x, currentTip.y, 6 / camScale, 6 / camScale);
  popMatrix();

  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) noLoop();
  }
}

void updatePath() {
  // Use STEP_SIZE as a fraction of the full rotation growth
  float radStep = STEP_SIZE * 0.001; 
  currentAngle += radStep;
  currentRadius *= pow(PHI, radStep / TWO_PI);
  
  float xOff = currentRadius * cos(currentAngle);
  float yOff = (isClockwise ? 1 : -1) * currentRadius * sin(currentAngle);
  
  currentTip = new PVector(currentOrigin.x + xOff, currentOrigin.y + yOff);
  
  // Add point to the current active segment
  pathSegments.get(pathSegments.size() - 1).points.add(currentTip);

  minX = min(minX, currentTip.x);
  maxX = max(maxX, currentTip.x);
  minY = min(minY, currentTip.y);
  maxY = max(maxY, currentTip.y);

  if (currentRadius >= resetThreshold) {
    currentOrigin = currentTip.copy();
    currentRadius = 1.0; 
    resetThreshold = 2.0; 
    isClockwise = !isClockwise;
    currentAngle = random(TWO_PI); 
    
    // Handle Color Shifting
    if (COLOR_SHIFT) {
      currentColorIndex = (currentColorIndex + 1) % PALETTES[PALETTE_INDEX].length;
      // Skip background color if it matches
      if (currentColorIndex == 0 && !INVERT_BG) currentColorIndex = 1; 
    }
    
    int nextColor = PALETTES[PALETTE_INDEX][currentColorIndex];
    PathSegment newSeg = new PathSegment(nextColor);
    newSeg.points.add(currentTip.copy());
    pathSegments.add(newSeg);
  }
}

void updateCamera() {
  float targetX = (minX + maxX) / 2;
  float targetY = (minY + maxY) / 2;
  camX = lerp(camX, targetX, 0.1);
  camY = lerp(camY, targetY, 0.1);
  
  float textW = max(1, maxX - minX);
  float textH = max(1, maxY - minY);
  float targetScale = min((width - PADDING * 2) / textW, (height - PADDING * 2) / textH);
  camScale = lerp(camScale, targetScale, 0.05);
}

void drawGrid(int gridColor) {
  stroke(gridColor, 40);
  strokeWeight(1 / camScale);
  int gridStep = 100; 
  for (int i = -5000; i < 5000; i += gridStep) line(i, -5000, i, 5000);
  for (int j = -5000; j < 5000; j += gridStep) line(-5000, j, 5000, j);
}
