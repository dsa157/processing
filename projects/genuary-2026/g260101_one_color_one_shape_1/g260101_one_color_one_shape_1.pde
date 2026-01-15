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
float ROTATION_SPEED = 0.03; // 0.02
float SHAPE_MAX_SIZE = 0.85; // 0.85 (percentage of cell size)

// Color Palette (Adobe Color inspired)
// Palette: Monochromatic Deep Teal
String[] HEX_PALETTE = {
  "#023047", // Background candidate
  "#219EBC" // Main Shape
};

int BG_COLOR_INDEX = 0; // Index 0
int SHAPE_COLOR_INDEX = 1; // Index 1

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  randomSeed(SEED_VALUE);
  frameRate(ANIMATION_SPEED);
  rectMode(CENTER);
}

void draw() {
  // Handle Background and Inversion
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

  // Calculate Grid Metrics
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
      
      // Visual Logic
      float distance = dist(i, j, GRID_COLS/2, GRID_ROWS/2);
      float offset = distance * 0.2;
      float wave = sin(frameCount * ROTATION_SPEED + offset);
      
      // Show Grid Cells
      if (SHOW_GRID) {
        strokeWeight(1);
        stroke(100, 50); // Faint guide
        rect(posX, posY, cellW, cellH);
        // Reset stroke for main shape
        stroke(INVERT_COLORS ? bg : fg); 
      }

      pushMatrix();
      translate(posX, posY);
      
      // Dynamics
      float rotation = wave * PI;
      float scaleFactor = map(wave, -1, 1, 0.2, SHAPE_MAX_SIZE);
      float alpha = map(wave, -1, 1, 50, 255);
      float weight = map(wave, -1, 1, 0.5, 5);
      
      // Apply Transparency
      if (INVERT_COLORS) stroke(bg, alpha);
      else stroke(fg, alpha);
      
      strokeWeight(weight);
      rotate(rotation);
      
      // The single shape: A square
      rect(0, 0, cellW * scaleFactor, cellH * scaleFactor);
      
      popMatrix();
    }
  }
  popMatrix();

  // Export and Loop Control
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
  }
  
  if (frameCount >= MAX_FRAMES) {
    noLoop();
  }
}
