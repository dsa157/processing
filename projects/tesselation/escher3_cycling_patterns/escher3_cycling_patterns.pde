/**
 * Tessellated Fish-to-Bird Morph: Seamless Pattern Blending
 * Version: 2026.03.18.14.36.42
 * Smoothly blends logic and color between cycling pattern states.
 */

// --- Global Parameters ---
int SKETCH_WIDTH = 480;      // default: 480
int SKETCH_HEIGHT = 800;     // default: 800
int PADDING = 40;            // default: 40
int SEED = 888;              // default: 42
int MAX_FRAMES = 1200;       // default: 1200
int ANIMATION_SPEED = 60;    // default: 60
boolean SAVE_FRAMES = false; // default: false
boolean INVERT_COLORS = false; // default: false
boolean SHOW_GRID = false;   // default: false

// --- Visual Parameters ---
int GRID_COLS = 9;          // default: 10
float CYCLE_SPEED = 0.04;    // default: 0.04
int PALETTE_INDEX = 6;       // 0-6 (6 is BW + Red)
int INITIAL_PATTERN = 2;     // 0-9
boolean AUTO_CYCLE = true;   // default: true
float DURATION_PER_PATTERN = 2; // Full sine cycles before switching

// --- Color Palettes ---
String[][] PALETTES = {
  {"#264653", "#2a9d8f", "#e9c46a", "#f4a261", "#e76f51"}, 
  {"#606c38", "#283618", "#fefae0", "#dda15e", "#bc6c25"}, 
  {"#001219", "#005f73", "#0a9396", "#94d2bd", "#e9d8a6"}, 
  {"#540d6e", "#ee4266", "#ffd23f", "#3bceac", "#0ead69"}, 
  {"#2b2d42", "#8d99ae", "#edf2f4", "#ef233c", "#d90429"}, 
  {"#222222", "#555555", "#888888", "#bbbbbb", "#eeeeee"}, 
  {"#000000", "#FFFFFF", "#ef233c", "#FFFFFF", "#000000"}  
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
  
  float totalPhase = frameCount * CYCLE_SPEED;
  int currentP;
  float blendWeight = 0;

  if (AUTO_CYCLE) {
    float interval = TWO_PI * DURATION_PER_PATTERN;
    currentP = (floor(totalPhase / interval) + INITIAL_PATTERN) % 10;
    
    // Calculate blend weight: smooth transition at the end of the cycle
    float progressInCycle = (totalPhase % interval) / interval;
    blendWeight = map(progressInCycle, 0.85, 1.0, 0, 1);
    blendWeight = constrain(blendWeight, 0, 1);
  } else {
    currentP = INITIAL_PATTERN;
  }
  
  pushMatrix();
  translate(PADDING, PADDING);
  tessellator.display(activePalette, currentP, totalPhase, blendWeight);
  popMatrix();

  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) noLoop();
  }
}

class Tessellator {
  int cols, rows;
  float size;
  PVector[] fish, bird;
  
  Tessellator(int c, int r, float s) {
    cols = c; rows = r; size = s;
    initShapes();
  }
  
  void initShapes() {
    fish = new PVector[]{ new PVector(0.5,0), new PVector(1,0.2), new PVector(0.7,0.5), new PVector(1,0.8), new PVector(0.5,1), new PVector(0,0.8), new PVector(0.3,0.5), new PVector(0,0.2) };
    bird = new PVector[]{ new PVector(0,0.5), new PVector(0.3,0), new PVector(0.7,0), new PVector(1,0.5), new PVector(0.7,1), new PVector(0.3,1), new PVector(0.5,0.8), new PVector(0.5,0.2) };
  }
  
  void display(String[] palette, int pIdx, float phase, float blend) {
    rectMode(CENTER);
    color redAccent = color(unhex("FF" + palette[2].substring(1)));

    for (int i = 0; i < cols; i++) {
      for (int j = 0; j < rows; j++) {
        float f1 = calculatePattern(i, j, phase, pIdx);
        float f2 = calculatePattern(i, j, phase, (pIdx + 1) % 10);
        float factor = lerp(f1, f2, blend);
        
        pushMatrix();
        translate(i * size + size/2, j * size + size/2);
        
        float rot = factor * PI;
        rotate(rot + ((i+j)%2 == 0 ? 0 : HALF_PI));
        
        color c1 = color(0);
        color c2 = color(255);
        color finalFill = ((i + j) % 2 == 0) ? lerpColor(c1, redAccent, factor) : lerpColor(c2, redAccent, factor);
        
        fill(finalFill);
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

  float calculatePattern(int i, int j, float t, int pIdx) {
    float wave;
    switch(pIdx) {
      case 0: wave = sin(t + j * 0.5); break;
      case 1: wave = sin(t + (i + j) * 0.3); break;
      case 2: wave = sin(t + dist(i, j, cols/2, rows/2) * 0.4); break;
      case 3: wave = sin(t + j * j * 0.02); break;
      case 4: wave = j % 2 == 0 ? sin(t) : sin(t + PI); break;
      case 5: wave = sin(t + i * 0.5); break;
      case 6: wave = sin(t + (noise(i*0.2, j*0.2, t*0.1) * TWO_PI)); break;
      case 7: wave = sin(t + (j % 3) * (TWO_PI/3.0)); break;
      case 8: wave = sin(t) * map(j, 0, rows, 0, 1); break;
      case 9: wave = sin(t + sin(j * 0.5) * 2.0); break;
      default: wave = sin(t);
    }
    return (wave + 1) / 2.0;
  }
}
