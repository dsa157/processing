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
int GRID_ROWS = 12; // 12
int GRID_COLS = 8; // 8
float ROTATION_SPEED = 0.02; // 0.02
float SHAPE_MAX_SIZE = 0.85; // 0.85
float OPACITY_SPEED = 0.05; // 0.05

// Color Palette (Adobe Kuler: Monochromatic Deep Teal)
String[] HEX_PALETTE = {
  "#023047", // Background
  "#219EBC" // Main Shape
};

int BG_COLOR_INDEX = 0; 
int SHAPE_COLOR_INDEX = 1;

// Asynchronous Opacity Tracking
float[][] opacityOffsets;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  randomSeed(SEED_VALUE);
  frameRate(ANIMATION_SPEED);
  rectMode(CENTER);

  // Initialize random offsets for opacity only
  opacityOffsets = new float[GRID_COLS][GRID_ROWS];
  for (int i = 0; i < GRID_COLS; i++) {
    for (int j = 0; j < GRID_ROWS; j++) {
      opacityOffsets[i][j] = random(TWO_PI);
    }
  }
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

  pushMatrix();
  translate(PADDING + cellW/2, PADDING + cellH/2);

  for (int i = 0; i < GRID_COLS; i++) {
    for (int j = 0; j < GRID_ROWS; j++) {
      float posX = i * cellW;
      float posY = j * cellH;
      
      // Original spatial wave for rotation and scale
      float distance = dist(i, j, GRID_COLS/2, GRID_ROWS/2);
      float spatialOffset = distance * 0.2;
      float wave = sin(frameCount * ROTATION_SPEED + spatialOffset);
      
      // Independent wave for opacity using stored random offsets
      float opacityWave = sin(frameCount * OPACITY_SPEED + opacityOffsets[i][j]);

      if (SHOW_GRID) {
        strokeWeight(1);
        stroke(INVERT_COLORS ? bg : fg, 40);
        rect(posX, posY, cellW, cellH);
      }

      pushMatrix();
      translate(posX, posY);
      
      // Restore initial behavior
      float rotation = wave * PI;
      float scaleFactor = map(wave, -1, 1, 0.2, SHAPE_MAX_SIZE);
      float weight = map(wave, -1, 1, 0.5, 5);
      
      // New randomized opacity behavior
      float alpha = map(opacityWave, -1, 1, 20, 255);
      
      if (INVERT_COLORS) stroke(bg, alpha);
      else stroke(fg, alpha);
      
      strokeWeight(weight);
      rotate(rotation);
      
      rect(0, 0, cellW * scaleFactor, cellH * scaleFactor);
      
      popMatrix();
    }
  }
  popMatrix();

  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
  }
  
  if (frameCount >= MAX_FRAMES) {
    noLoop();
  }
}
