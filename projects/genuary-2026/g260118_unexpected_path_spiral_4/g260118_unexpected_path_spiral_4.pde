/**
 * Unexpected Path - Oscillating Growth & Decay
 * Path reflects off boundaries with a trailing decay effect.
 * Features an optional oscillation for the radius expansion rate.
 */

// --- GLOBAL PARAMETERS ---
int SKETCH_WIDTH = 480;      // default: 480
int SKETCH_HEIGHT = 800;     // default: 800
int CANVAS_PADDING = 40;     // default: 40
int MAX_FRAMES = 900;        // default: 900
boolean SAVE_FRAMES = false; // default: false
int ANIMATION_SPEED = 60;    // default: 60 fps
int GLOBAL_SEED = 1234;      // default: 1234

// --- PERFORMANCE PARAMETERS ---
int STEPS_PER_FRAME = 4;     // default: 4

// --- VISUAL PARAMETERS ---
float MIN_RADIUS = 10.0;     // default: 10.0
float MAX_RADIUS = 400.0;    // default: 400.0
float RADIUS_STEP_BASE = 0.5; // default: 0.5
float STEP_SIZE = 4.0;       // default: 4.0
float STROKE_WEIGHT = 6.0;   // default: 4.0
float DECAY_RATE = 10.0;     // default: 10.0
boolean SHOW_GRID = false;   // default: false
boolean INVERT_COLORS = false; // default: false

// --- OSCILLATION PARAMETERS ---
boolean OSCILLATE_RADIUS_STEP = false; // default: true
float OSC_SPEED = 0.02;      // default: 0.02 (Speed of change)
float OSC_MULT = 1.5;        // default: 1.5 (Strength of change)

// --- COLOR PALETTES ---
String[][] PALETTES = {
  {"#264653", "#2a9d8f", "#e9c46a", "#f4a261", "#e76f51"},
  {"#001219", "#005f73", "#94d2bd", "#ee9b00", "#ae2012"},
  {"#231942", "#5e548e", "#9f86c0", "#be95c4", "#e0b1cb"},
  {"#1a1c2c", "#5d275d", "#b13e53", "#ef7d57", "#ffcd75"},
  {"#2d3142", "#4f5d75", "#bfc0c0", "#ffffff", "#ef8354"}
};
int PALETTE_INDEX = 0;       // default: 0
int BG_COLOR_INDEX = 0;      // default: 0

// --- STATE VARIABLES ---
float currentX, currentY;
float currentAngle;
float currentRadius = MIN_RADIUS;
float oscTimer = 0;
int drawColor;
int bgColor;
int directionSign = 1;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  randomSeed(GLOBAL_SEED);
  frameRate(ANIMATION_SPEED);
  
  String[] activePalette = PALETTES[PALETTE_INDEX];
  bgColor = unhex("FF" + activePalette[BG_COLOR_INDEX].substring(1));
  int strokeIdx = floor(random(1, activePalette.length));
  drawColor = unhex("FF" + activePalette[strokeIdx].substring(1));
  
  if (INVERT_COLORS) {
    bgColor = color(255 - red(bgColor), 255 - green(bgColor), 255 - blue(bgColor));
    drawColor = color(255 - red(drawColor), 255 - green(drawColor), 255 - blue(drawColor));
  }

  background(bgColor);
  
  currentX = width / 2;
  currentY = height / 2;
  currentAngle = random(TWO_PI);
  
  if (SHOW_GRID) drawGrid();
}

void draw() {
  // Apply Decay
  noStroke();
  fill(bgColor, DECAY_RATE);
  rect(0, 0, width, height);

  if (SHOW_GRID) drawGrid();

  for (int i = 0; i < STEPS_PER_FRAME; i++) {
    updateAndDrawPath();
  }

  handleExport();
}

void updateAndDrawPath() {
  // Movement calculation
  float deltaAngle = (STEP_SIZE / currentRadius) * directionSign;
  currentAngle += deltaAngle;

  float nextX = currentX + cos(currentAngle) * STEP_SIZE;
  float nextY = currentY + sin(currentAngle) * STEP_SIZE;

  // Boundary Reflection
  boolean hitBoundary = false;
  if (nextX <= CANVAS_PADDING || nextX >= width - CANVAS_PADDING) {
    currentAngle = PI - currentAngle;
    hitBoundary = true;
  }
  if (nextY <= CANVAS_PADDING || nextY >= height - CANVAS_PADDING) {
    currentAngle = -currentAngle;
    hitBoundary = true;
  }

  if (hitBoundary) {
    nextX = currentX + cos(currentAngle) * STEP_SIZE;
    nextY = currentY + sin(currentAngle) * STEP_SIZE;
    directionSign *= -1; 
  }

  // Draw Path
  stroke(drawColor);
  strokeWeight(STROKE_WEIGHT);
  line(currentX, currentY, nextX, nextY);

  // Advance State
  currentX = nextX;
  currentY = nextY;
  
  // Rule: Radius growth with optional oscillation
  float stepIncrease = RADIUS_STEP_BASE;
  if (OSCILLATE_RADIUS_STEP) {
    oscTimer += OSC_SPEED;
    stepIncrease *= (1.0 + sin(oscTimer) * OSC_MULT);
  }
  
  currentRadius += stepIncrease;
  
  if (currentRadius > MAX_RADIUS) {
    currentRadius = MIN_RADIUS;
  }
}

void drawGrid() {
  stroke(drawColor, 40);
  strokeWeight(1);
  int gridStep = 50;
  for (int i = CANVAS_PADDING; i <= width - CANVAS_PADDING; i += gridStep) {
    line(i, CANVAS_PADDING, i, height - CANVAS_PADDING);
  }
  for (int j = CANVAS_PADDING; j <= height - CANVAS_PADDING; j += gridStep) {
    line(CANVAS_PADDING, j, width - CANVAS_PADDING, j);
  }
}

void handleExport() {
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) {
      noLoop();
    }
  }
}
