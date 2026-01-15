/**
 * Recursive Favela - Full Height Growth
 * Fixed recursion logic to ensure buildings reach the top of the canvas.
 */

// --- Parameters ---
int SKETCH_WIDTH = 480;       // Default: 480
int SKETCH_HEIGHT = 800;      // Default: 800
int PADDING = 40;             // Default: 40
int MAX_FRAMES = 900;         // Default: 900
boolean SAVE_FRAMES = false;  // Default: false
int ANIMATION_SPEED = 10;     // Default: 30
int GLOBAL_SEED = 99887;      // Seed for reproducibility

// Visual Settings
boolean INVERT_COLORS = false; 
boolean SHOW_GRID = false;     
float GROWTH_RATE = 4.0;       // Speed of vertical climb
float MIN_SHACK_WIDTH = 10;    // Minimum width (Default: 12)
float CABLE_PROBABILITY = 0.3; // Chance of drawing a wire to the next shack

// Palette: "Adobe Kuler - Urban Decay"
int[] PALETTE = {
  0xFF2D3033, // Dark Slate
  0xFFC03546, // Red
  0xFF497285, // Muted Blue
  0xFF929EAD, // Grey-Blue
  0xFFF26101  // Burnt Orange
};

int BG_COLOR_INDEX = 0; 
float currentGrowthY = 0;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  frameRate(ANIMATION_SPEED);
  randomSeed(GLOBAL_SEED);
}

void draw() {
  int bg = PALETTE[BG_COLOR_INDEX];
  background(INVERT_COLORS ? ~bg | 0xFF000000 : bg);

  // Increase allowable height
  if (currentGrowthY < (SKETCH_HEIGHT - PADDING * 2)) {
    currentGrowthY += GROWTH_RATE;
  }

  pushMatrix();
  translate(PADDING, height - PADDING);
  
  // Re-seed to keep structure static while growth "reveals" it
  randomSeed(GLOBAL_SEED);
  
  float availableWidth = SKETCH_WIDTH - (PADDING * 2);
  int foundationCount = 5;
  float groundStep = availableWidth / (float)foundationCount;
  
  for (int i = 0; i < foundationCount; i++) {
    float startX = i * groundStep + random(groundStep * 0.1);
    float startW = random(50, 80);
    float startH = random(35, 50);
    // Passing 0 for current height tracker
    drawShack(startX, 0, startW, startH, 0);
  }
  popMatrix();

  if (SHOW_GRID) drawGrid();

  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) noLoop();
  }
}

/**
 * Recursive function using Y-coordinate as the primary exit condition
 */
void drawShack(float x, float y, float w, float h, float accumulatedHeight) {
  // EXIT CONDITIONS:
  // 1. If the shack's top exceeds the current permitted growth height
  // 2. If the shack becomes too narrow
  // 3. Safety break to prevent infinite loops (based on canvas height)
  if (accumulatedHeight + h > currentGrowthY || w < MIN_SHACK_WIDTH || accumulatedHeight > height) {
    return;
  }

  // Draw the shack
  int colIdx = floor(random(1, PALETTE.length));
  fill(PALETTE[colIdx]);
  noStroke();
  rect(x, y - h, w, h);
  
  // Roof shadow
  fill(0, 60);
  rect(x - 2, y - h, w + 4, 4);

  // Windows and Doors
  if (w > 15) {
    fill(0, 150);
    // Randomize door/window placement slightly
    rect(x + w * 0.2, y - h * 0.8, w * 0.2, h * 0.3); 
    rect(x + w * 0.6, y - h * 0.5, w * 0.3, h * 0.5);
  }

  // RECURSIVE STEPS
  
  // 1. Stack Upward
  float nextW = w * random(0.85, 1.05);
  float nextH = h * random(0.8, 1.1);
  float nextX = x + (w - nextW) * random(0, 1);
  
  // Draw cable before recursing
  if (random(1) < CABLE_PROBABILITY) {
    drawCable(x + w/2, y - h/2, nextX + nextW/2, (y - h) - nextH/2);
  }
  
  drawShack(nextX, y - h, nextW, nextH, accumulatedHeight + h);

  // 2. Random Sideways Sprawl (less frequent to encourage verticality)
  if (random(1) > 0.75) {
    float sideW = w * random(0.7, 0.9);
    float sideH = h * random(0.7, 0.9);
    float sideX = (random(1) > 0.5) ? x + w : x - sideW;
    // Side shacks share the same base height
    drawShack(sideX, y, sideW, sideH, accumulatedHeight);
  }
}

void drawCable(float x1, float y1, float x2, float y2) {
  stroke(20, 180);
  strokeWeight(1);
  noFill();
  // Simple catenary curve using a bezier
  float midX = (x1 + x2) / 2;
  float midY = max(y1, y2) + 10; 
  bezier(x1, y1, midX, midY, midX, midY, x2, y2);
  noStroke();
}

void drawGrid() {
  stroke(255, 30);
  for (int i = 0; i <= width; i += 20) line(i, 0, i, height);
  for (int i = 0; i <= height; i += 20) line(0, i, width, i);
  noStroke();
}
