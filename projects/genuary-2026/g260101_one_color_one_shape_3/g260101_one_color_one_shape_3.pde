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
int GRID_ROWS = 6; // 6 (Reduced base rows to allow for nesting)
int GRID_COLS = 4; // 4 (Reduced base cols to allow for nesting)
float SUBDIVIDE_CHANCE = 0.45; // 0.45 (Probability a cell splits)
float ROTATION_SPEED = 0.02; // 0.02
float SHAPE_MAX_SIZE = 0.85; // 0.85
float OPACITY_SPEED = 0.1; // 0.05

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

  // Reset random seed every frame to keep the grid structure consistent
  // but allowing the temporal logic (frameCount) to move.
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
  // Determine if we should subdivide (Limit to 2 levels deep)
  if (level < 2 && random(1.0) < SUBDIVIDE_CHANCE) {
    float newW = w / 2;
    float newH = h / 2;
    // Subdivide into 4 smaller cells
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

  // Spatial wave based on coordinate position
  float distance = dist(x, y, width/2, height/2);
  float spatialOffset = distance * 0.01;
  float wave = sin(frameCount * ROTATION_SPEED + spatialOffset);
  
  // Unique opacity wave per shape based on its specific coordinates
  // This replaces the array with a deterministic coordinate-based seed
  float opacitySeed = (x * 1.7) + (y * 2.9); 
  float opacityWave = sin(frameCount * OPACITY_SPEED + opacitySeed);

  if (SHOW_GRID) {
    strokeWeight(1);
    stroke(INVERT_COLORS ? bg : fg, 40);
    rect(x, y, w, h);
  }

  pushMatrix();
  translate(x, y);
  
  float rotation = wave * PI;
  float scaleFactor = map(wave, -1, 1, 0.2, SHAPE_MAX_SIZE);
  float weight = map(wave, -1, 1, 0.5, 3.5);
  float alpha = map(opacityWave, -1, 1, 20, 255);
  
  if (INVERT_COLORS) stroke(bg, alpha);
  else stroke(fg, alpha);
  
  strokeWeight(weight);
  rotate(rotation);
  
  rect(0, 0, w * scaleFactor, h * scaleFactor);
  popMatrix();
}
