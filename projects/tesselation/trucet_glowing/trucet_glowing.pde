/**
 * Animated Carlson Truchet Morph
 * Version: 2026.02.04.09.00.12
 * * All cross tiles use dot-pulsing logic.
 * * Synchronized retraction: Dot is smallest when arms are furthest away.
 * * Cleaned glow layers to remove end-cap artifacts.
 */

// --- Parameters ---
int SKETCH_WIDTH = 480;           // default 480
int SKETCH_HEIGHT = 800;          // default 800
int CANVAS_PADDING = 40;          // default 40
int GLOBAL_SEED = 157;            // default 999
int MAX_FRAMES = 900;             // default 900
boolean SAVE_FRAMES = false;      // default false
int ANIMATION_SPEED = 30;         // default 30
boolean SHOW_GRID = false;        // default false
boolean INVERT_COLORS = false;    // default false
int PALETTE_INDEX = 1;            // 0 to 4

// Distribution & Animation
float CURVE_RATIO = 0.5;         // default 0.65
int GRID_COUNT = 6;               // default 6
float MORPH_SPEED = 0.08;         // default 0.05
float STROKE_WEIGHT_RATIO = 0.16; // default 0.15

// Glow Parameters
float GLOW_ALPHA = 20;            // default 20
float GLOW_SPREAD = 4.0;          // default 6.0

// --- Colors ---
String[][] PALETTES = {
  {"#1A1A1B", "#F13C20", "#4056A1", "#D79922", "#EFE2BA"},
  {"#0B0C10", "#66FCF1", "#45A29E", "#C5C6C7", "#1F2833"},
  {"#282828", "#EBDBB2", "#FB4934", "#B8BB26", "#FABD2F"},
  {"#101820", "#F2AA4C", "#FFFFFF", "#000000", "#F2AA4C"},
  {"#2D3436", "#00CEC9", "#0984E3", "#6C5CE7", "#DFE6E9"}
};

color[] currentPalette;
color bgCol, strokeCol, accentCol;
ArrayList<TruchetTile> tiles;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  randomSeed(GLOBAL_SEED);
  frameRate(ANIMATION_SPEED);
  loadPalette();
  initGrid();
}

void loadPalette() {
  currentPalette = new color[5];
  for (int i = 0; i < 5; i++) {
    currentPalette[i] = unhex("FF" + PALETTES[PALETTE_INDEX][i].substring(1));
  }
  
  if (INVERT_COLORS) {
    bgCol = currentPalette[4];
    strokeCol = currentPalette[0];
    accentCol = currentPalette[1];
  } else {
    bgCol = currentPalette[0];
    strokeCol = currentPalette[1];
    accentCol = currentPalette[2];
  }
}

void initGrid() {
  tiles = new ArrayList<TruchetTile>();
  float availableWidth = SKETCH_WIDTH - (CANVAS_PADDING * 2);
  float cellSize = availableWidth / GRID_COUNT;
  int rows = floor((SKETCH_HEIGHT - (CANVAS_PADDING * 2)) / cellSize);
  
  float startX = (SKETCH_WIDTH - (GRID_COUNT * cellSize)) / 2;
  float startY = (SKETCH_HEIGHT - (rows * cellSize)) / 2;

  for (int i = 0; i < GRID_COUNT; i++) {
    for (int j = 0; j < rows; j++) {
      tiles.add(new TruchetTile(startX + i * cellSize, startY + j * cellSize, cellSize));
    }
  }
}

void draw() {
  background(bgCol);
  
  for (TruchetTile t : tiles) {
    t.update();
    t.display();
  }

  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) noLoop();
  }
}

class TruchetTile {
  float x, y, s;
  boolean isCurved;
  int rotation;
  float morphPhase;
  float offset;

  TruchetTile(float x, float y, float s) {
    this.x = x;
    this.y = y;
    this.s = s;
    this.isCurved = random(1.0) < CURVE_RATIO;
    this.rotation = int(random(4));
    this.offset = random(TWO_PI);
  }

  void update() {
    morphPhase = sin(frameCount * MORPH_SPEED + offset);
  }

  void display() {
    pushMatrix();
    translate(x + s/2, y + s/2);
    rotate(HALF_PI * rotation);

    float baseWeight = s * STROKE_WEIGHT_RATIO;

    // Render Glow (Background to Foreground)
    for (int i = 3; i > 0; i--) {
      float extraWeight = i * GLOW_SPREAD;
      drawPattern(color(strokeCol, GLOW_ALPHA / (i * 1.5)), extraWeight, baseWeight);
    }
    
    // Render Core
    drawPattern(strokeCol, 0, baseWeight);
    
    popMatrix();
  }

  void drawPattern(color c, float weightMod, float bWeight) {
    stroke(c);
    strokeWeight(bWeight + weightMod);
    noFill();
    strokeCap(ROUND);

    if (isCurved) {
      // Arcs morph by length
      float m = map(morphPhase, -1, 1, 0.1, 1.0);
      arc(-s/2, -s/2, s, s, 0, HALF_PI * m);
      arc(s/2, s/2, s, s, PI, PI + (HALF_PI * m));
    } else {
      // Synchronized Dot & Cross
      // Abs(phase) goes 0 -> 1 -> 0. 
      // Dot is smallest (0.1) when retract is furthest (0.45)
      float pulse = abs(morphPhase); 
      float retractVal = map(pulse, 0, 1, s * 0.45, 0); 
      float dotScale = map(pulse, 0, 1, 0.1, 1.0);

      // Draw retracting arms
      line(-s/2, 0, -retractVal, 0);
      line(s/2, 0, retractVal, 0);
      line(0, -s/2, 0, -retractVal);
      line(0, s/2, 0, retractVal);
      
      // Draw pulsing dot
      pushStyle();
      fill(c);
      noStroke();
      float dotSize = (s * 0.3 * dotScale) + (weightMod * 0.5);
      ellipse(0, 0, dotSize, dotSize);
      popStyle();
    }
  }
}

void mousePressed() {
  GLOBAL_SEED = (int)random(100000);
  randomSeed(GLOBAL_SEED);
  initGrid();
}
