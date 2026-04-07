/**
 * Tessellated Fish-to-Bird Morph: Wave & Dynamic Rotation
 * Version: 2026.03.18.13.25.10
 * Propagation wave affects morphing and rotation across the grid.
 */

// --- Global Parameters ---
int SKETCH_WIDTH = 480;      // default: 480
int SKETCH_HEIGHT = 800;     // default: 800
int PADDING = 40;            // default: 40
int SEED = 777;              // default: 42
int MAX_FRAMES = 900;        // default: 900
int ANIMATION_SPEED = 60;    // default: 30 (Increased for smoothness)
boolean SAVE_FRAMES = false; // default: false
boolean INVERT_COLORS = false; // default: false
boolean SHOW_GRID = false;   // default: false

// --- Visual Parameters ---
int GRID_COLS = 10;          // default: 6
float MORPH_SPEED = 0.05;    // default: 0.02
float WAVE_STRENGTH = 0.15;  // default: 0.15
float ROTATION_MULT = 1.5;   // default: 1.5
int PALETTE_INDEX = 6;       // 0-6

// --- Color Palettes (Adobe Color) ---
String[][] PALETTES = {
  {"#264653", "#2a9d8f", "#e9c46a", "#f4a261", "#e76f51"}, // Oceanic
  {"#606c38", "#283618", "#fefae0", "#dda15e", "#bc6c25"}, // Earthy
  {"#001219", "#005f73", "#0a9396", "#94d2bd", "#e9d8a6"}, // Cool Blue
  {"#540d6e", "#ee4266", "#ffd23f", "#3bceac", "#0ead69"}, // Vibrant
  {"#2b2d42", "#8d99ae", "#edf2f4", "#ef233c", "#d90429"}, // Bold Red/Grey
  {"#222222", "#555555", "#888888", "#bbbbbb", "#eeeeee"}, // Grayscale
  {"#000000", "#FFFFFF", "#ef233c", "#FFFFFF", "#000000"}  // B & W & Red
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
  
  if (INVERT_COLORS) {
    background(fgBase);
  } else {
    background(bgBase);
  }
  
  pushMatrix();
  translate(PADDING, PADDING);
  tessellator.display(activePalette);
  popMatrix();

  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) {
      noLoop();
    }
  }
}

class Tessellator {
  int cols, rows;
  float size;
  PVector[] fishShape;
  PVector[] birdShape;
  
  Tessellator(int c, int r, float s) {
    cols = c;
    rows = r;
    size = s;
    initShapes();
  }
  
  void initShapes() {
    // Sharp geometric vertices for better interlocking
    fishShape = new PVector[] {
      new PVector(0.5, 0), new PVector(1, 0.2), new PVector(0.7, 0.5), 
      new PVector(1, 0.8), new PVector(0.5, 1), new PVector(0.3, 0.5)
    };
    
    birdShape = new PVector[] {
      new PVector(0, 0.5), new PVector(0.3, 0), new PVector(0.7, 0), 
      new PVector(1, 0.5), new PVector(0.7, 1), new PVector(0.3, 1)
    };
  }
  
  void display(String[] palette) {
    rectMode(CENTER);
    float time = frameCount * MORPH_SPEED;
    
    for (int i = 0; i < cols; i++) {
      for (int j = 0; j < rows; j++) {
        // Calculate Wave Factor based on distance from center/top
        float distance = dist(i, j, cols/2.0, rows/2.0) * WAVE_STRENGTH;
        float wave = (sin(time - distance) + 1) / 2.0;
        
        pushMatrix();
        translate(i * size + size/2, j * size + size/2);
        
        // Aggressive dynamic rotation
        float baseRot = ((i + j) % 2 == 0) ? 0 : PI/2;
        float waveRot = sin(time - distance) * ROTATION_MULT;
        rotate(baseRot + waveRot);
        
        if (SHOW_GRID) {
          stroke(100, 50);
          noFill();
          rect(0, 0, size, size);
        }
        
        // Dynamic Color Selection
        int colIdx = (wave > 0.5) ? 2 : 3;
        color c = color(unhex("FF" + palette[colIdx].substring(1)));
        if (INVERT_COLORS) c = color(255 - red(c), 255 - green(c), 255 - blue(c));
        
        fill(c);
        noStroke();
        
        // Render Shape with Wave-based Morphing
        beginShape();
        for (int v = 0; v < fishShape.length; v++) {
          float vx = lerp(fishShape[v].x, birdShape[v].x, wave) - 0.5;
          float vy = lerp(fishShape[v].y, birdShape[v].y, wave) - 0.5;
          vertex(vx * size, vy * size);
        }
        endShape(CLOSE);
        
        popMatrix();
      }
    }
  }
}
