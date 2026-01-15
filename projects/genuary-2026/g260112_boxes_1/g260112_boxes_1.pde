/**
 * Wobbly Grid-Hollow Box & Precision Axis Travelers
 * Version: 2026.01.10.13.19.45
 */

// --- Parameters ---
int SKETCH_WIDTH = 480;       // Default: 480
int SKETCH_HEIGHT = 800;      // Default: 800
int MAX_FRAMES = 900;         // Default: 900
boolean SAVE_FRAMES = false;  // Default: false
int ANIMATION_SPEED = 30;     // Default: 30
int GLOBAL_SEED = 1234;       // Default: 1234
float PADDING = 40;           // Default: 40

// Colors & Palettes
int[][] PALETTES = {
  {#264653, #2a9d8f, #e9c46a, #f4a261, #e76f51}, 
  {#001219, #005f73, #0a9396, #94d2bd, #e9d8a6}, 
  {#1d3557, #457b9d, #a8dadc, #f1faee, #e63946}, 
  {#2b2d42, #8d99ae, #edf2f4, #ef233c, #d90429}, 
  {#011627, #fdfffc, #2ec4b6, #e71d36, #ff9f1c}  
};
int PALETTE_INDEX = 0;        // Default: 4
int BG_COLOR_INDEX = 0;       // Default: 0
boolean INVERT_BG = false;    // Default: false

// Geometry & Animation Parameters
float MAIN_BOX_SIZE = 300;    // Default: 240
float HOLE_SIZE = 40;         // Default: 40
float SMALL_BOX_SIZE = 40;    // Default: 40 (Fits perfectly in holes)
float WOBBLE_STRENGTH = 0.4;  // Default: 0.2
int TRAVELER_COUNT = 500;      // Default: 30 (Doubled per request)
float TRAVELER_SPEED = 6.0;   // Default: 6.0
boolean SHOW_GRID = false;    // Default: false (Grid lines removed)

// Global Variables
float rotationY = 0;
Traveler[] travelers;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT, P3D);
}

void setup() {
  randomSeed(GLOBAL_SEED);
  frameRate(ANIMATION_SPEED);
  
  travelers = new Traveler[TRAVELER_COUNT];
  for (int i = 0; i < TRAVELER_COUNT; i++) {
    travelers[i] = new Traveler();
  }
}

void draw() {
  // Handle Background
  int activeBg = PALETTES[PALETTE_INDEX][BG_COLOR_INDEX];
  if (INVERT_BG) activeBg = color(255 - red(activeBg), 255 - green(activeBg), 255 - blue(activeBg));
  background(activeBg);
  
  translate(width/2, height/2, -100);
  
  // Lighting
  ambientLight(120, 120, 120);
  pointLight(255, 255, 255, 400, -400, 500);
  
  // Rotation and Wobble
  rotationY += 0.015;
  float wobbleX = sin(frameCount * 0.04) * WOBBLE_STRENGTH;
  float wobbleZ = cos(frameCount * 0.02) * WOBBLE_STRENGTH;

  pushMatrix();
  rotateY(rotationY);
  rotateX(wobbleX);
  rotateZ(wobbleZ);
  
  // Draw Box
  drawGridHollowBox(MAIN_BOX_SIZE, HOLE_SIZE);
  
  // Update and Draw Travelers
  for (Traveler t : travelers) {
    t.update();
    t.display();
  }
  popMatrix();

  // Save/Stop Logic
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) noLoop();
  }
}

void drawGridHollowBox(float sz, float holeSz) {
  fill(PALETTES[PALETTE_INDEX][1]);
  // Use noStroke for the box faces as requested (removing grid lines)
  noStroke();
  
  float half = sz / 2;
  for (int i = 0; i < 6; i++) {
    pushMatrix();
    if (i == 1) rotateY(HALF_PI);
    if (i == 2) rotateY(PI);
    if (i == 3) rotateY(-HALF_PI);
    if (i == 4) rotateX(HALF_PI);
    if (i == 5) rotateX(-HALF_PI);
    translate(0, 0, half);
    drawFaceWith9Holes(sz, holeSz);
    popMatrix();
  }
}

void drawFaceWith9Holes(float sz, float holeSz) {
  float h = sz / 2;
  float step = sz / 3;
  
  for (int x = 0; x < 3; x++) {
    for (int y = 0; y < 3; y++) {
      float cx = -h + x * step + step/2;
      float cy = -h + y * step + step/2;
      
      float innerH = step / 2;
      float hh = holeSz / 2;
      
      beginShape(QUADS);
      // Constructing geometry around holes without internal divider strokes
      vertex(cx - innerH, cy - innerH, 0); vertex(cx + innerH, cy - innerH, 0); 
      vertex(cx + innerH, cy - hh, 0);     vertex(cx - innerH, cy - hh, 0);
      
      vertex(cx - innerH, cy + hh, 0);     vertex(cx + innerH, cy + hh, 0); 
      vertex(cx + innerH, cy + innerH, 0); vertex(cx - innerH, cy + innerH, 0);
      
      vertex(cx - innerH, cy - hh, 0);     vertex(cx - hh, cy - hh, 0); 
      vertex(cx - hh, cy + hh, 0);         vertex(cx - innerH, cy + hh, 0);
      
      vertex(cx + hh, cy - hh, 0);         vertex(cx + innerH, cy - hh, 0); 
      vertex(cx + innerH, cy + hh, 0);     vertex(cx + hh, cy + hh, 0);
      endShape();
    }
  }
}

class Traveler {
  PVector pos;
  int axis; 
  float currentSpeed;
  int col;
  float boundary = 1200; 

  Traveler() {
    init(true);
  }

  void init(boolean firstStart) {
    axis = int(random(3));
    currentSpeed = (random(1) > 0.5 ? 1 : -1) * TRAVELER_SPEED;
    col = PALETTES[PALETTE_INDEX][int(random(2, 5))];
    
    float step = MAIN_BOX_SIZE / 3;
    float h = MAIN_BOX_SIZE / 2;
    float[] grid = { -h + step/2, 0, h - step/2 };
    
    // Lock to hole centers
    float gx = grid[int(random(3))];
    float gy = grid[int(random(3))];
    float gz = grid[int(random(3))];

    if (axis == 0) pos = new PVector(currentSpeed > 0 ? -boundary : boundary, gy, gz);
    else if (axis == 1) pos = new PVector(gx, currentSpeed > 0 ? -boundary : boundary, gz);
    else pos = new PVector(gx, gy, currentSpeed > 0 ? -boundary : boundary);
    
    if (firstStart) {
      float startOffset = random(-boundary, boundary);
      if (axis == 0) pos.x = startOffset;
      else if (axis == 1) pos.y = startOffset;
      else pos.z = startOffset;
    }
  }

  void update() {
    if (axis == 0) pos.x += currentSpeed;
    else if (axis == 1) pos.y += currentSpeed;
    else pos.z += currentSpeed;

    if (abs(pos.x) > boundary || abs(pos.y) > boundary || abs(pos.z) > boundary) {
      init(false);
    }
  }

  void display() {
    pushMatrix();
    translate(pos.x, pos.y, pos.z);
    fill(col);
    noStroke();
    box(SMALL_BOX_SIZE);
    popMatrix();
  }
}
