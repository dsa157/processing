/**
 * Hexagonal Kinetic Weave - Infinite Bleed
 * Version: 2026.04.17.07.13.22
 * * A hexagonal grid that covers the entire canvas. Arc segments rotate and slide 
 * between cell centers independently. Both rotation and sliding speeds are 
 * parameterized. Stroke weight modulates over the total duration to create a 
 * dynamic but seamless 900-frame loop.
 */

// --- Global Parameters ---
int SKETCH_WIDTH = 480;       // Default: 480
int SKETCH_HEIGHT = 800;      // Default: 800
int SEED_VALUE = 42;          // Default: 42
int MAX_FRAMES = 900;         // Default: 900
boolean SAVE_FRAMES = false;  // Default: false
int ANIMATION_SPEED = 30;     // Default: 30
float PADDING = 0;            // Set to 0 for full bleed. Default: 0

// --- Visual Parameters ---
float HEX_RADIUS = 55.0;      // Default: 55.0
float STROKE_WEIGHT_BASE = 5.0; // Base thickness. Default: 5.0
float ARC_GAP = 0.1;          // Space between arcs. Default: 0.1
boolean SHOW_GRID = false;    // Default: false
boolean INVERT_BG = false;    // Default: false
int PALETTE_INDEX = 6;        // Default: 6 (Pure B&W)

// --- Motion Parameters ---
boolean ENABLE_ROTATION = true;   // Default: true
boolean ENABLE_SLIDING = true;    // Default: true
float ROTATION_CYCLES = 10.0;     // Full rotations per 900 frames. Default: 10.0
float SLIDE_CYCLES = 3.0;         // Back-and-forth slide cycles per 900 frames. Default: 3.0
float SLIDE_DISTANCE = 0.8;       // Intensity of sliding movement. Default: 0.8

// --- Color Palettes ---
String[][] PALETTES = {
  {"#264653", "#2a9d8f", "#e9c46a", "#f4a261", "#e76f51"}, // Adobe: Terra
  {"#001219", "#005f73", "#0a9396", "#94d2bd", "#e9d8a6"}, // Adobe: Oceanic
  {"#ffbe0b", "#fb5607", "#ff006e", "#8338ec", "#3a86ff"}, // Adobe: Neon
  {"#f94144", "#f3722c", "#f8961e", "#f9c74f", "#90be6d"}, // Adobe: Rainbow
  {"#5f0f40", "#9a031e", "#fb8b24", "#e36414", "#0f4c5c"}, // Adobe: Sunset
  {"#D9D9D9", "#BFBFBF", "#8C8C8C", "#595959", "#F2F2F2"}, // Grayscale
  {"#FFFFFF", "#FFFFFF", "#FFFFFF", "#FFFFFF", "#FFFFFF"}  // Pure B&W
};

int[] currentPalette;
color bgCol;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  randomSeed(SEED_VALUE);
  frameRate(ANIMATION_SPEED);
  
  currentPalette = new int[5];
  for (int i = 0; i < 5; i++) {
    currentPalette[i] = unhex("FF" + PALETTES[PALETTE_INDEX][i].substring(1));
  }
  
  bgCol = INVERT_BG ? color(255) : color(0);
}

void draw() {
  background(bgCol);
  
  // Normalized 0.0 -> 1.0 progress
  float progress = (frameCount % MAX_FRAMES) / (float) MAX_FRAMES;
  
  // Modulate stroke weight over the full cycle for variety
  float weightMod = STROKE_WEIGHT_BASE + (sin(progress * TWO_PI) * 4.0);
  
  float h = HEX_RADIUS * sqrt(3);
  float w = HEX_RADIUS * 1.5;
  
  // To ensure full bleed, start drawing slightly outside the top-left
  // and extend slightly past the bottom-right.
  for (float x = -w; x <= width + w; x += w) {
    int colIndex = round(x / w);
    // Align columns to center the grid visually if needed, 
    // but here we just flow across from -w.
    for (float y = -h; y <= height + h; y += h) {
      float yPos = y + ((abs(colIndex) % 2 != 0) ? h / 2 : 0);
      drawHexNode(x, yPos, progress, weightMod);
    }
  }

  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) noLoop();
  }
}

void drawHexNode(float x, float y, float prg, float sw) {
  pushMatrix();
  translate(x, y);
  
  if (SHOW_GRID) {
    noFill();
    stroke(INVERT_BG ? 200 : 50);
    strokeWeight(1);
    drawHexOutline(HEX_RADIUS);
  }

  for (int i = 0; i < 6; i++) {
    float angleStep = TWO_PI / 6;
    float baseAngle = i * angleStep;
    
    // Rotation logic - seamless based on ROTATION_CYCLES
    float rot = ENABLE_ROTATION ? (prg * TWO_PI * ROTATION_CYCLES) : 0;
    
    // Sliding logic - seamless based on SLIDE_CYCLES
    float slideX = 0;
    float slideY = 0;
    if (ENABLE_SLIDING) {
      // sin(prg * TWO_PI * SLIDE_CYCLES) ensures it returns to 0 at the end of the loop
      float slidePhase = sin(prg * TWO_PI * SLIDE_CYCLES); 
      float dist = (HEX_RADIUS * sqrt(3)) * 0.5 * SLIDE_DISTANCE;
      slideX = cos(baseAngle) * dist * slidePhase;
      slideY = sin(baseAngle) * dist * slidePhase;
    }
    
    pushMatrix();
    translate(slideX, slideY);
    rotate(rot);
    
    stroke(currentPalette[i % 5]);
    strokeWeight(sw);
    strokeCap(ROUND);
    noFill();
    
    // Draw arc segment
    float start = baseAngle + ARC_GAP;
    float end = baseAngle + angleStep - ARC_GAP;
    arc(0, 0, HEX_RADIUS, HEX_RADIUS, start, end);
    
    popMatrix();
  }
  
  popMatrix();
}

void drawHexOutline(float r) {
  beginShape();
  for (int i = 0; i < 6; i++) {
    float angle = i * TWO_PI / 6;
    vertex(cos(angle) * r, sin(angle) * r);
  }
  endShape(CLOSE);
}
