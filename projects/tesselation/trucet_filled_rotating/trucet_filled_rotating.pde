/**
 * Truchet Filled Rotating
 * Version: 2026.04.07.14.12.00
 * Description: A dynamic, rotating Truchet tiling with filled shapes, vibrant color gradients, and comprehensive animation controls.
 */

// --- Global Constants & Canvas Settings ---
int SKETCH_WIDTH = 480;      // 480: default width
int SKETCH_HEIGHT = 800;     // 800: default height

// --- Customizable Parameters ---
int tilesX = 10;             // 10: number of tiles horizontally
int tilesY = 16;             // 16: number of tiles vertically (adjusted for 480x800)
float padding = 40.0;        // 40.0: padding around the overall sketch
float animIncrement = 0.02;  // 0.02: increment for rotation oscillation
float strokeThickness = 2.0; // 2.0: thickness of tile outlines
int globalSeed = 42;         // 42: seed for reproducibility
int paletteIndex = 0;        // 0: active color palette index (0-6)
boolean invertBackground = false; // false: toggle to invert background color
boolean showGrid = false;    // false: show/hide tile grid cells

// --- Animation & Rendering Controls ---
int MAX_FRAMES = 900;        // 900: maximum frames to render
boolean SAVE_FRAMES = false; // false: toggle to save frames to disk
int ANIMATION_SPEED = 30;    // 30: frames per second (frameRate)

// --- Color Palettes (Sourced from Adobe Kuler inspiration) ---
// 0: "Neon Sunset"
// 1: "Deep Sea Escape"
// 2: "Nordic Forest"
// 3: "Vibrant Energy"
// 4: "Vintage Pastel"
// 5: "Grayscale"
// 6: "Black & White"
String[][] hexPalettes = {
  {"#FF1493", "#00CED1", "#FF8C00", "#ADFF2F", "#9400D3"}, 
  {"#001F3F", "#0074D9", "#7FDBFF", "#39CCCC", #3D9970}, 
  {"#2D4032", "#556B2F", "#8B9467", "#A9A9A9", "#EAEAEA"}, 
  {"#FF4136", "#FF851B", "#FFDC00", "#2ECC40", "#001F3F"}, 
  {"#FAD02E", "#F28D35", "#D8334A", "#FF6F61", "#E8A87C"},
  {"#000000", "#333333", "#666666", "#999999", "#CCCCCC"},
  {"#000000", "#FFFFFF", "#000000", "#FFFFFF", "#000000"}
};

color[] activePalette;
float t = 0;                 // rotation time tracker
float tileSize;              // calculated based on padding

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  frameRate(ANIMATION_SPEED);
  pixelDensity(displayDensity());
  randomSeed(globalSeed);
  noiseSeed(globalSeed);
  
  // Initialize palette
  activePalette = new color[5];
  updatePalette();
  
  // Calculate tile size to fit within padding
  float availableW = width - (padding * 2);
  tileSize = availableW / (float)tilesX;
}

void updatePalette() {
  int idx = paletteIndex % 7;
  for (int i = 0; i < 5; i++) {
    activePalette[i] = unhex("FF" + hexPalettes[idx][i].substring(1));
  }
}

void draw() {
  updatePalette();
  
  color bgColor = activePalette[0];
  if (invertBackground) bgColor = color(255 - red(bgColor), 255 - green(bgColor), 255 - blue(bgColor));
  background(bgColor);
  
  // Center overall sketch on canvas including padding
  pushMatrix();
  translate(padding, padding);

  for (int x = 0; x < tilesX; x++) {
    for (int y = 0; y < tilesY; y++) {
      float px = x * tileSize;
      float py = y * tileSize;

      // Ensure we don't draw outside the vertical padding
      if (py + tileSize > height - (padding * 2)) continue;
      
      // Determine tile type randomly based on seed
      float n = noise(x * 0.1, y * 0.1, globalSeed);
      boolean type = n > 0.5;
      
      if (showGrid) {
        stroke(activePalette[1], 50);
        strokeWeight(1);
        noFill();
        rect(px, py, tileSize, tileSize);
      }
      
      drawTruchetTile(px, py, tileSize, type);
    }
  }
  popMatrix();
  
  t += animIncrement;
  
  // Animation & Saving Logic
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) {
      noLoop();
    }
  }
}

void drawTruchetTile(float x, float y, float s, boolean type) {
  pushMatrix();
  translate(x + s/2, y + s/2);
  
  // Logic: oscillate rotation based on time and distance from center
  float dist = dist(0, 0, x - width/2, y - height/2);
  float rot = sin(t + dist * 0.005) * HALF_PI;
  rotate(rot);
  
  noStroke();
  if (type) {
    fill(activePalette[1]);
    arc(-s/2, -s/2, s, s, 0, HALF_PI);
    fill(activePalette[2]);
    arc(s/2, s/2, s, s, PI, PI + HALF_PI);
  } else {
    fill(activePalette[3]);
    arc(s/2, -s/2, s, s, HALF_PI, PI);
    fill(activePalette[4]);
    arc(-s/2, s/2, s, s, PI + HALF_PI, TWO_PI);
  }
  
  // Visual Polish: outlines
  stroke(activePalette[0]); 
  strokeWeight(strokeThickness);
  noFill();
  if (type) {
    arc(-s/2, -s/2, s, s, 0, HALF_PI);
    arc(s/2, s/2, s, s, PI, PI + HALF_PI);
  } else {
    arc(s/2, -s/2, s, s, HALF_PI, PI);
    arc(-s/2, s/2, s, s, PI + HALF_PI, TWO_PI);
  }
  
  popMatrix();
}
