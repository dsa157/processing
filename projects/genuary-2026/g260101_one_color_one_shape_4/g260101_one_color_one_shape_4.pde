// Parameters
int SKETCH_WIDTH = 480; // 480
int SKETCH_HEIGHT = 800; // 800
int SEED_VALUE = 42; // 42
int PADDING = 40; // 40
int MAX_FRAMES = 900; // 900
boolean SAVE_FRAMES = false; // false
int ANIMATION_SPEED = 30; // 30
boolean SHOW_GRID = false; // false
boolean INVERT_COLORS = false; // false

// Grid Settings
int GRID_ROWS = 10; // 10 (Increased for density)
int GRID_COLS = 6; // 6 (Increased for density)
float SUBDIVIDE_CHANCE = 0.65; // 0.65 (Higher chance for smaller cells)
float ROTATION_INCREMENT = 0.04; // 0.04 (Linear speed)
float SHAPE_MAX_SIZE = 0.85; // 0.85
float OPACITY_SPEED = 0.1; // 0.07

// Color Palette (Adobe Kuler: Monochromatic Deep Teal)
String[] HEX_PALETTE = {
  "#023047", // Background
  "#219EBC", // Main Shape
  "#8ECAE6", 
  "#FFB703", 
  "#FB8500"
};

int BG_COLOR_INDEX = 0; 
int SHAPE_COLOR_INDEX = 1;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  randomSeed(SEED_VALUE);
  frameRate(ANIMATION_SPEED);
  rectMode(CENTER);
}

void draw() {
  int bg = unhex("FF" + HEX_PALETTE[BG_COLOR_INDEX].substring(1));
  int fg = unhex("FF" + HEX_PALETTE[SHAPE_COLOR_INDEX].substring(1));
  
  if (INVERT_COLORS) {
    background(fg);
    stroke(bg);
  } else {
    background(bg);
    stroke(fg);
  }
  
  noFill();

  float availableWidth = width - (PADDING * 2);
  float availableHeight = height - (PADDING * 2);
  float cellW = availableWidth / GRID_COLS;
  float cellH = availableHeight / GRID_ROWS;

  // Re-seed to keep subdivision structure static across frames
  randomSeed(SEED_VALUE);

  pushMatrix();
  translate(PADDING + cellW/2, PADDING + cellH/2);

  for (int i = 0; i < GRID_COLS; i++) {
    for (int j = 0; j < GRID_ROWS; j++) {
      drawNestedCell(i * cellW, j * cellH, cellW, cellH, 0);
    }
  }
  popMatrix();

  if (SAVE_FRAMES) saveFrame("frames/####.tif");
  if (frameCount >= MAX_FRAMES) noLoop();
}

void drawNestedCell(float x, float y, float w, float h, int level) {
  // Increased max level to 3 for higher density
  if (level < 3 && random(1.0) < SUBDIVIDE_CHANCE) {
    float newW = w / 2;
    float newH = h / 2;
    drawNestedCell(x - newW/2, y - newH/2, newW, newH, level + 1);
    drawNestedCell(x + newW/2, y - newH/2, newW, newH, level + 1);
    drawNestedCell(x - newW/2, y + newH/2, newW, newH, level + 1);
    drawNestedCell(x + newW/2, y + newH/2, newW, newH, level + 1);
  } else {
    renderShape(x, y, w, h);
  }
}

void renderShape(float x, float y, float w, float h) {
  int bg = unhex("FF" + HEX_PALETTE[BG_COLOR_INDEX].substring(1));
  int fg = unhex("FF" + HEX_PALETTE[SHAPE_COLOR_INDEX].substring(1));

  // Distance from center for spatial variance
  float distance = dist(x, y, width/2, height/2);
  
  // Continuous linear rotation instead of sine oscillation
  float rotationAngle = (frameCount * ROTATION_INCREMENT) + (distance * 0.02);
  
  // Maintain sine for scale and opacity to keep the pulsing feel
  float wave = sin(frameCount * 0.05 + (distance * 0.01));
  float opacitySeed = (x * 1.7) + (y * 2.9); 
  float opacityWave = sin(frameCount * OPACITY_SPEED + opacitySeed);

  if (SHOW_GRID) {
    strokeWeight(1);
    stroke(INVERT_COLORS ? bg : fg, 30);
    rect(x, y, w, h);
  }

  pushMatrix();
  translate(x, y);
  
  // Applied linear rotation
  rotate(rotationAngle);
  
  float scaleFactor = map(wave, -1, 1, 0.15, SHAPE_MAX_SIZE);
  float weight = map(wave, -1, 1, 0.5, 3.0);
  float alpha = map(opacityWave, -1, 1, 15, 255);
  
  if (INVERT_COLORS) stroke(bg, alpha);
  else stroke(fg, alpha);
  
  strokeWeight(weight);
  rect(0, 0, w * scaleFactor, h * scaleFactor);
  
  popMatrix();
}
