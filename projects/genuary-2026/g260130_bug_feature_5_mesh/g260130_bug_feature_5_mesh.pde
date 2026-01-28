/*
 * Sketch: 3D Seifert Surface Mesh - Frantic Rhythm & Dash Catchup
 * Version: 2026.01.28.13.35.45
 * Description: Cuboid Seifert surface with high-density mesh and boomerang color cycling.
 * Implements a "frantic" rhythm where the sketch pauses for a parameterized number 
 * of frames and then dashes forward to sync with the elapsed time.
 */

// --- Parameters ---
int SKETCH_WIDTH = 480;
int SKETCH_HEIGHT = 800;
int PADDING = 40; // Default: 40
int MAX_FRAMES = 900; // Default: 900
boolean SAVE_FRAMES = false; // Default: false
int ANIMATION_SPEED = 30; // Default: 30 fps
int SEED = 42; // Global random seed

// Mesh Settings
int MESH_DENSITY = 500; // Default: 200 -> User: 500
int MESH_LAYERS = 500; // Default: 100 -> User: 500
float MESH_STROKE_WEIGHT = 0.5; // Default: 0.5
boolean SHOW_GRID = false; // Default: false

// Color Settings
int PALETTE_INDEX = 3; // Choice: 0-4
boolean INVERT_BG = false; // Toggle background inversion
int COLORS_TO_USE = 4; // Number of colors from palette to cycle (1-5)
float COLOR_CYCLE_SPEED = 1.5; // Multiplier for cycling speed (Default: 1.5)

// Geometry Settings
float RING_SIZE = 150.0; // Default: 120.0
float RING_OFFSET = 50.0; // Default: 50.0
float SHAPE_SQUIRCLE_P = 5.0; // Cuboid factor (Default: 5.0)
float PULSE_AMP = 0.05; // Default: 0.15
float PULSE_FREQ = 0.008; // Default: 0.008

// Rhythm Settings
int HEAVY_CALC_INTERVAL = 80; // Frequency of stutters (Default: 60)
int STUTTER_FRAME_COUNT = 20; // Number of frames to simulate a "hang" (Default: 15)

// Animation Variables
float currentTime = 0;
float lastRealTime = 0;

// Palettes from Adobe Color
int[][] PALETTES = {
  {#2E112D, #540032, #820333, #C02739, #F17308}, 
  {#0048BA, #1034A6, #007FFF, #273BE2, #89CFF0}, 
  {#E0FBFC, #3D5A80, #98C1D9, #EE6C4D, #293241}, 
  {#5F0F40, #9A031E, #FB8B24, #E36414, #0F4C5C}, 
  {#264653, #2A9D8F, #E9C46A, #F4A261, #E76F51}  
};

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT, P3D);
}

void setup() {
  frameRate(ANIMATION_SPEED);
  randomSeed(SEED);
  
  int bgColor = PALETTES[PALETTE_INDEX][0];
  if (INVERT_BG) {
    background(255 - red(bgColor), 255 - green(bgColor), 255 - blue(bgColor));
  } else {
    background(bgColor);
  }
  lastRealTime = millis();
}

void draw() {
  // Calculate real elapsed time since the start
  float realElapsed = (millis() - lastRealTime) / 1000.0;
  
  // Logic: Only update 'currentTime' if we are not in a stutter window
  // This causes the visual state to "freeze" while real time keeps ticking
  if (frameCount % HEAVY_CALC_INTERVAL < STUTTER_FRAME_COUNT) {
    // Hang: Do not increment currentTime. We force a calculation load.
    for (int i = 0; i < 5000000; i++) { Math.sqrt(i); }
  } else {
    // Catch-up: Sync currentTime to the actual time elapsed since setup
    // This creates the "dash" effect after the freeze
    currentTime = realElapsed;
  }

  // Clear Background
  int bgColor = PALETTES[PALETTE_INDEX][0];
  if (INVERT_BG) background(255 - red(bgColor), 255 - green(bgColor), 255 - blue(bgColor));
  else background(bgColor);

  pushMatrix();
  translate(width / 2, height / 2, 0);
  
  // Rotations driven by the (stuttering then dashing) currentTime
  float pulse = 1.0 + sin(currentTime * 5.0) * PULSE_AMP;
  rotateX(currentTime * 0.4);
  rotateY(currentTime * 0.7);
  rotateZ(currentTime * 0.2);
  scale(pulse);

  drawSeifertCuboidMesh();
  
  popMatrix();
  
  // Save frame logic
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) noLoop();
  }
}

PVector getSquirclePoint(float t, float r, float p) {
  float ct = cos(t);
  float st = sin(t);
  float x = pow(abs(ct), 2.0/p) * r * (ct >= 0 ? 1 : -1);
  float y = pow(abs(st), 2.0/p) * r * (st >= 0 ? 1 : -1);
  return new PVector(x, y);
}

void drawSeifertCuboidMesh() {
  noFill();
  strokeWeight(MESH_STROKE_WEIGHT);

  for (int i = 0; i < MESH_DENSITY; i += 2) {
    float t1 = map(i, 0, MESH_DENSITY, 0, TWO_PI);
    float t2 = map(i + 2, 0, MESH_DENSITY, 0, TWO_PI);

    PVector s1_a = getSquirclePoint(t1, RING_SIZE, SHAPE_SQUIRCLE_P);
    PVector s1_b = getSquirclePoint(t2, RING_SIZE, SHAPE_SQUIRCLE_P);
    
    PVector r1_a = new PVector(s1_a.x, s1_a.y, RING_OFFSET);
    PVector r1_b = new PVector(s1_b.x, s1_b.y, RING_OFFSET);
    PVector r2_a = new PVector(RING_OFFSET, s1_a.x, s1_a.y);
    PVector r2_b = new PVector(RING_OFFSET, s1_b.x, s1_b.y);
    PVector r3_a = new PVector(s1_a.x, RING_OFFSET, s1_a.y);
    PVector r3_b = new PVector(s1_b.x, RING_OFFSET, s1_b.y);

    renderMeshSegment(r1_a, r1_b, r2_a, r2_b, i, 0);
    renderMeshSegment(r2_a, r2_b, r3_a, r3_b, i, 0.5);
    renderMeshSegment(r3_a, r3_b, r1_a, r1_b, i, 1.0);
  }
}

void renderMeshSegment(PVector p1, PVector p2, PVector q1, PVector q2, int step, float phase) {
  for (int j = 0; j < MESH_LAYERS; j += 25) {
    float amt = map(j, 0, MESH_LAYERS, 0, 1);
    PVector v1 = PVector.lerp(p1, q1, amt);
    PVector v2 = PVector.lerp(p2, q2, amt);

    applyBoomerangStroke(step, j, phase);
    line(v1.x, v1.y, v1.z, v2.x, v2.y, v2.z);
  }
}

void applyBoomerangStroke(int i, int j, float phase) {
  int[] p = PALETTES[PALETTE_INDEX];
  
  float wave = (currentTime * COLOR_CYCLE_SPEED) + (i * 0.002) + (j * 0.001) + phase;
  float boomerang = abs((wave % 2.0) - 1.0); 
  
  float colorTarget = boomerang * (COLORS_TO_USE - 1);
  int idxA = floor(colorTarget) + 1;
  int idxB = ceil(colorTarget) + 1;
  float lerpFactor = colorTarget % 1.0;
  
  idxA = constrain(idxA, 1, p.length - 1);
  idxB = constrain(idxB, 1, p.length - 1);
  
  stroke(lerpColor(p[idxA], p[idxB], lerpFactor), 220);
}
