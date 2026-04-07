/**
 * Tessellated Fish-to-Bird Morph: Row-Cycling
 * Version: 2026.03.18.13.06.45
 * Features 10 selectable row-based cycling patterns and Red-Accent BW palette.
 */

// --- Global Parameters ---
int SKETCH_WIDTH = 480;      // default: 480
int SKETCH_HEIGHT = 800;     // default: 800
int PADDING = 40;            // default: 40
int SEED = 888;              // default: 42
int MAX_FRAMES = 900;        // default: 900
int ANIMATION_SPEED = 60;    // default: 30
boolean SAVE_FRAMES = false; // default: false
boolean INVERT_COLORS = false; // default: false
boolean SHOW_GRID = false;   // default: false

// --- Visual Parameters ---
int GRID_COLS = 7;          // default: 10
float CYCLE_SPEED = 0.07;    // default: 0.05
int PALETTE_INDEX = 2;       // 0-6 (6 is new BW + Red)
int PATTERN_INDEX = 0;       // 0-9 (Selects the cycling logic)

// --- Color Palettes ---
String[][] PALETTES = {
  {"#264653", "#2a9d8f", "#e9c46a", "#f4a261", "#e76f51"}, // Oceanic
  {"#606c38", "#283618", "#fefae0", "#dda15e", "#bc6c25"}, // Earthy
  {"#001219", "#005f73", "#0a9396", "#94d2bd", "#e9d8a6"}, // Cool Blue
  {"#540d6e", "#ee4266", "#ffd23f", "#3bceac", "#0ead69"}, // Vibrant
  {"#2b2d42", "#8d99ae", "#edf2f4", "#ef233c", "#d90429"}, // Bold Red/Grey
  {"#222222", "#555555", "#888888", "#bbbbbb", "#eeeeee"}, // Grayscale
  {"#000000", "#FFFFFF", "#ef233c", "#FFFFFF", "#000000"}  // BW + RED Accent
};

Tessellator tessellator;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  randomSeed(SEED);
  frameRate(ANIMATION_SPEED);
  
  float gridW = (width - (2 * PADDING));
  float cellSize = gridW / GRID_COLS;
  int rows = ceil((height - (2 * PADDING)) / cellSize);
  
  tessellator = new Tessellator(GRID_COLS, rows, cellSize);
}

void draw() {
  String[] activePalette = PALETTES[PALETTE_INDEX];
  color bgBase = color(unhex("FF" + activePalette[0].substring(1)));
  color fgBase = color(unhex("FF" + activePalette[1].substring(1)));
  
  background(INVERT_COLORS ? fgBase : bgBase);
  
  pushMatrix();
  translate(PADDING, PADDING);
  tessellator.display(activePalette);
  popMatrix();

  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) noLoop();
  }
}

class Tessellator {
  int cols, rows;
  float size;
  PVector[] fish;
  PVector[] bird;
  
  Tessellator(int c, int r, float s) {
    cols = c; rows = r; size = s;
    initShapes();
  }
  
  void initShapes() {
    fish = new PVector[]{ new PVector(0.5, 0), new PVector(1, 0.2), new PVector(0.7, 0.5), new PVector(1, 0.8), new PVector(0.5, 1), new PVector(0.3, 0.5) };
    bird = new PVector[]{ new PVector(0, 0.5), new PVector(0.3, 0), new PVector(0.7, 0), new PVector(1, 0.5), new PVector(0.7, 1), new PVector(0.3, 1) };
  }
  
  void display(String[] palette) {
    rectMode(CENTER);
    float t = frameCount * CYCLE_SPEED;
    color redAccent = color(unhex("FF" + palette[2].substring(1)));

    for (int i = 0; i < cols; i++) {
      for (int j = 0; j < rows; j++) {
        float factor = calculatePattern(i, j, t);
        
        pushMatrix();
        translate(i * size + size/2, j * size + size/2);
        
        // Aggressive Rotation based on row position
        rotate(factor * TWO_PI * 0.5 + ((i+j)%2 == 0 ? 0 : HALF_PI));
        
        // Color cycling using red accent
        fill(lerpColor(color(255), redAccent, factor));
        if ((i + j) % 2 == 0) fill(lerpColor(color(0), redAccent, 1-factor));
        
        noStroke();
        beginShape();
        for (int v = 0; v < fish.length; v++) {
          float vx = lerp(fish[v].x, bird[v].x, factor) - 0.5;
          float vy = lerp(fish[v].y, bird[v].y, factor) - 0.5;
          vertex(vx * size, vy * size);
        }
        endShape(CLOSE);
        popMatrix();
      }
    }
  }

  float calculatePattern(int i, int j, float t) {
    switch(PATTERN_INDEX) {
      case 0: return (sin(t + j * 0.5) + 1) / 2.0;           // Standard Row Wave
      case 1: return (sin(t + (i + j) * 0.3) + 1) / 2.0;    // Diagonal Slide
      case 2: return abs(sin(t * 0.5 + j * 0.2));           // Slow Row Bounce
      case 3: return (sin(t + j * j * 0.05) + 1) / 2.0;     // Accelerating Row Offset
      case 4: return j % 2 == 0 ? abs(sin(t)) : abs(cos(t));// Alternating Row Pulse
      case 5: return (sin(t + dist(i, j, cols/2, j) * 0.5) + 1) / 2.0; // Horizontal Row Pinch
      case 6: return noise(i * 0.1, j * 0.1, t);            // Perlin Row Drift
      case 7: return (sin(t + (j % 3) * PI) + 1) / 2.0;     // Tri-Phase Row Step
      case 8: return map(j, 0, rows, 0, 1) * abs(sin(t));   // Vertical Gradient Pulse
      case 9: return (sin(t + sin(j * 0.8) * 2.0) + 1) / 2.0;// Serpentine Row Distortion
      default: return 0.5;
    }
  }
}
