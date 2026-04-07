/**
 * Truchet Filled Rotating
 * Version: 2026.04.07.14.31.46
 * Description: A Smith-style Truchet tiling sketch featuring thick, connected "blobby" arcs with secondary outlines to match the provided reference image.
 */

// --- Global Constants & Canvas Settings ---
int SKETCH_WIDTH = 480;      // 480: default width
int SKETCH_HEIGHT = 800;     // 800: default height

// --- Customizable Parameters ---
int GRID_COLS = 10;           // 10: number of tiles horizontally
int GRID_ROWS = 16;           // 16: number of tiles vertically
float PADDING = 40.0;        // 40.0: padding around the overall sketch
float ANIM_INCREMENT = 0.02;  // 0.02: rate of rotation oscillation
float OUTER_STOWKE = 12.0;    // 12.0: thickness of the black outline
float INNER_STOWKE = 8.0;     // 8.0: thickness of the color fill (should be < OUTER_STOWKE)
int GLOBAL_SEED = 42;         // 42: seed for reproducibility
int PALETTE_INDEX = 0;        // 0: active palette (0-6)
boolean INVERT_BACKGROUND = false; // false: toggle to invert background
boolean SHOW_GRID = false;    // false: toggle grid visibility

// --- Animation & Rendering Controls ---
int MAX_FRAMES = 900;        
boolean SAVE_FRAMES = false; 
int ANIMATION_SPEED = 30;    

// --- Color Palettes ---
// 0: "Neon Sunset"
// 1: "Deep Sea Escape"
// 2: "Nordic Forest"
// 3: "Vibrant Energy"
// 4: "Vintage Pastel"
// 5: "Grayscale"
// 6: "Black & White"
String[][] HEX_PALETTES = {
  {"#FFFFFF", "#008080", "#000000", "#FFD700", "#FF4500"}, 
  {"#001F3F", "#39CCCC", "#000000", "#7FDBFF", "#01FF70"}, 
  {"#2D4032", "#8B9467", "#000000", "#556B2F", "#EAEAEA"}, 
  {"#FF4136", "#FFDC00", "#000000", "#FF851B", "#0074D9"}, 
  {"#FAD02E", "#D8334A", "#000000", "#F28D35", "#E8A87C"},
  {"#000000", "#999999", "#FFFFFF", "#666666", "#CCCCCC"},
  {"#000000", "#FFFFFF", "#000000", "#FFFFFF", "#000000"}
};

color[] activePalette;
float t = 0;                 
float tileSize;              

void setup() {
  size(480, 800); 
  frameRate(ANIMATION_SPEED);
  pixelDensity(displayDensity());
  randomSeed(GLOBAL_SEED);
  noiseSeed(GLOBAL_SEED);
  
  activePalette = new color[5];
  updatePalette();
  
  float availableW = width - (PADDING * 2);
  tileSize = availableW / (float)GRID_COLS;
}

void updatePalette() {
  int idx = PALETTE_INDEX % 7;
  for (int i = 0; i < 5; i++) {
    activePalette[i] = unhex("FF" + HEX_PALETTES[idx][i].substring(1));
  }
}

void draw() {
  updatePalette();
  
  color bgColor = activePalette[0];
  if (INVERT_BACKGROUND) bgColor = color(255 - red(bgColor), 255 - green(bgColor), 255 - blue(bgColor));
  background(bgColor);
  
  pushMatrix();
  translate(PADDING, PADDING);

  // First pass: Draw the thick black "outer" strokes to ensure they connect
  for (int x = 0; x < GRID_COLS; x++) {
    for (int y = 0; y < GRID_ROWS; y++) {
      float px = x * tileSize;
      float py = y * tileSize;
      if (py + tileSize > height - (PADDING * 2)) continue;
      
      float n = noise(x * 0.1, y * 0.1, GLOBAL_SEED);
      boolean type = n > 0.5;
      
      drawTruchetLayer(px, py, tileSize, type, x, y, activePalette[2], OUTER_STOWKE);
    }
  }

  // Second pass: Draw the "inner" color fill strokes
  for (int x = 0; x < GRID_COLS; x++) {
    for (int y = 0; y < GRID_ROWS; y++) {
      float px = x * tileSize;
      float py = y * tileSize;
      if (py + tileSize > height - (PADDING * 2)) continue;
      
      float n = noise(x * 0.1, y * 0.1, GLOBAL_SEED);
      boolean type = n > 0.5;
      
      drawTruchetLayer(px, py, tileSize, type, x, y, activePalette[1], INNER_STOWKE);
      
      if (SHOW_GRID) {
        stroke(255, 0, 0, 100);
        strokeWeight(1);
        noFill();
        rect(px, py, tileSize, tileSize);
      }
    }
  }
  popMatrix();
  
  t += ANIM_INCREMENT;
  
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) noLoop();
  }
}

void drawTruchetLayer(float x, float y, float s, boolean type, int gridX, int gridY, color strokeC, float weight) {
  pushMatrix();
  translate(x + s/2, y + s/2);
  
  float distVal = dist(gridX, gridY, GRID_COLS/2, GRID_ROWS/2);
  float rotationFactor = sin(t + distVal * 0.2);
  float rotAngle = floor(rotationFactor * 2) * HALF_PI; 
  rotate(rotAngle);
  
  stroke(strokeC);
  strokeWeight(weight);
  noFill();
  
  // Arcs are centered at corners with diameter = tileSize (radius = s/2)
  if (type) {
    arc(-s/2, -s/2, s, s, 0, HALF_PI);
    arc(s/2, s/2, s, s, PI, PI + HALF_PI);
  } else {
    arc(s/2, -s/2, s, s, HALF_PI, PI);
    arc(-s/2, s/2, s, s, PI + HALF_PI, TWO_PI);
  }
  
  popMatrix();
}
