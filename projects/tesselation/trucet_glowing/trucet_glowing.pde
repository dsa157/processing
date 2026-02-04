/**
 * Animated Carlson Truchet Morph
 * Version: 2026.02.03.18.22.45
 * An expert implementation of morphing Truchet patterns with glow effects.
 */

// --- Parameters ---
int SKETCH_WIDTH = 480;           // default 480
int SKETCH_HEIGHT = 800;          // default 800
int CANVAS_PADDING = 40;          // default 40
int GLOBAL_SEED = 999;            // default 999
int MAX_FRAMES = 900;             // default 900
boolean SAVE_FRAMES = false;      // default false
int ANIMATION_SPEED = 30;         // default 30
boolean SHOW_GRID = false;        // default false
boolean INVERT_COLORS = false;    // default false
int PALETTE_INDEX = 1;            // 0 to 4

// Visual Tweaks
int GRID_COUNT = 6;               // default 6 (columns)
float GLOW_INTENSITY = 20;       // default 120 (alpha of glow)
float MORPH_SPEED = 0.08;         // default 0.05

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
  int type;
  int rotation;
  float morphPhase;
  float offset;

  TruchetTile(float x, float y, float s) {
    this.x = x;
    this.y = y;
    this.s = s;
    this.type = int(random(1, 16));
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

    if (SHOW_GRID) {
      noFill();
      stroke(strokeCol, 30);
      rect(-s/2, -s/2, s, s);
    }

    // Glow Effect: Draw soft underlayers
    for (int i = 3; i > 0; i--) {
      float glowSize = map(i, 3, 1, s * 0.1, 0);
      drawPattern(type, s, color(strokeCol, GLOW_INTENSITY / (i * 2)), glowSize);
    }
    
    // Main Pattern
    drawPattern(type, s, strokeCol, 0);
    
    popMatrix();
  }

  void drawPattern(int t, float sz, color c, float weightMod) {
    float r = (sz * 0.25) + (morphPhase * 5);
    stroke(c);
    strokeWeight(sz * 0.15 + weightMod);
    noFill();
    strokeCap(ROUND);

    float m = map(morphPhase, -1, 1, 0.2, 1.0);

    // Carlson logic: based on connecting points on the 1/4 and 3/4 marks of each side
    if (t < 5) {
      // Type: Arcs and simple paths
      arc(-sz/2, -sz/2, sz, sz, 0, HALF_PI * m);
      arc(sz/2, sz/2, sz, sz, PI, PI + (HALF_PI * m));
    } else if (t < 10) {
      // Type: Intersection/Bridge
      line(-sz/2, 0, sz/2 * m, 0);
      line(0, -sz/2, 0, sz/2 * m);
      ellipse(0, 0, r * m, r * m);
    } else {
      // Type: Complex Hubs
      fill(c);
      noStroke();
      float hubSize = sz * 0.4 * abs(morphPhase);
      rectMode(CENTER);
      rect(0, 0, hubSize, hubSize, r);
      
      // Dynamic connectors
      rect(0, -sz/4, sz * 0.1, sz/2 * abs(morphPhase));
      rect(0, sz/4, sz * 0.1, sz/2 * abs(morphPhase));
      rect(-sz/4, 0, sz/2 * abs(morphPhase), sz * 0.1);
      rect(sz/4, 0, sz/2 * abs(morphPhase), sz * 0.1);
    }
  }
}

void mousePressed() {
  GLOBAL_SEED = (int)random(100000);
  randomSeed(GLOBAL_SEED);
  initGrid();
}
