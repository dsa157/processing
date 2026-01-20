/**
 * Overlapping Ovoids & Particle Ribbon Flow Field
 * Focus: Sharp-edged ovoids over persistent particle trails (history-based).
 * Version: 2026.01.18.09.06.12
 */

// --- Global Parameters ---
int SKETCH_WIDTH = 480;       // Default: 480
int SKETCH_HEIGHT = 800;      // Default: 800
int SEED_VALUE = 42;          // Default: 42
int PADDING = 40;             // Default: 40
int MAX_FRAMES = 900;         // Default: 900
int ANIMATION_SPEED = 30;     // Default: 30
boolean SAVE_FRAMES = false;  // Default: false
boolean INVERT_BG = true;     // Default: true
boolean SHOW_GRID = false;    // Default: false

// --- Flow Parameters ---
int PARTICLE_COUNT = 400;     // Lowered count for history performance
int TRAIL_LENGTH = 15;        // User Param: 15 (Length of particle ribbons)
float NOISE_SCALE = 0.02;     // User Param: 0.01
float NOISE_EVOLUTION = 0.01; // User Param: 0.01
float RIBBON_SPEED = 5.5;     // User Param: 5.5
float RIBBON_ALPHA = 20;      // User Param: 60
float STROKE_WEIGHT = 1.5;    // User Param: 1.5
int FLOW_COLOR_INDEX = 2;     // User Param: Index 2

// --- Visualization Parameters ---
int OVOID_COUNT = 45;         
float MIN_SIZE = 40;          
float MAX_SIZE = 160;         
float ROTATION_SPEED = 0.012; 
float DRIFT_SPEED = 0.8;      
int ALPHA_VALUE = 140;         // User Param: 50

// --- Color Palettes ---
int PALETTE_INDEX = 3;        
int[][] PALETTES = {
  {0xFF00FFFF, 0xFFFF00FF, 0xFFFFFF00, 0xFF000000}, // 0: CMYK
  {0xFFFF5E5B, 0xFFD72638, 0xFF3F88C5, 0xFFF49D37}, // 1: Bold Modern
  {0xFF264653, 0xFF2A9D8F, 0xFFE9C46A, 0xFFF4A261}, // 2: Sandy Stone
  {0xFF606C38, 0xFF283618, 0xFFDDA15E, 0xFFBC6C25}, // 3: Earthy Tones
  {0xFF003049, 0xFFD62828, 0xFFF77F00, 0xFFFCBF49}  // 4: High Contrast
};

Particle[] particles;
Ovoid[] shapes;
int activeBgColor;
int activeFlowColor;
float innerLeft, innerRight, innerTop, innerBottom;
float zOffset = 0; 

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  randomSeed(SEED_VALUE);
  noiseSeed(SEED_VALUE);
  frameRate(ANIMATION_SPEED);
  
  innerLeft = PADDING;
  innerRight = width - PADDING;
  innerTop = PADDING;
  innerBottom = height - PADDING;
  
  activeBgColor = INVERT_BG ? color(15) : color(245); 
  
  int[] currentPalette = PALETTES[PALETTE_INDEX];
  activeFlowColor = currentPalette[constrain(FLOW_COLOR_INDEX, 0, currentPalette.length-1)];

  particles = new Particle[PARTICLE_COUNT];
  for (int i = 0; i < PARTICLE_COUNT; i++) {
    particles[i] = new Particle();
  }
  
  shapes = new Ovoid[OVOID_COUNT];
  for (int i = 0; i < OVOID_COUNT; i++) {
    int hexColor = currentPalette[i % currentPalette.length];
    shapes[i] = new Ovoid(hexColor);
  }
}

void draw() {
  background(activeBgColor); // Clears frame to ensure sharp edges
  
  // Layer 1: Particles (Ribbons drawn as lines through history)
  noFill();
  strokeWeight(STROKE_WEIGHT);
  stroke(activeFlowColor, RIBBON_ALPHA);
  for (Particle p : particles) {
    p.update();
    p.display();
  }
  
  if (SHOW_GRID) drawDebugGrid();

  // Layer 2: Sharp Ovoids
  blendMode(INVERT_BG ? SCREEN : MULTIPLY);
  for (Ovoid o : shapes) {
    o.update();
    o.display();
  }
  
  blendMode(BLEND); 
  zOffset += NOISE_EVOLUTION; 

  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) noLoop();
  }
}

void drawDebugGrid() {
  stroke(255, 0, 0, 150);
  noFill();
  rect(innerLeft, innerTop, innerRight - innerLeft, innerBottom - innerTop);
}

// --- Particle Class with History Trails ---
class Particle {
  PVector pos;
  PVector[] history;
  
  Particle() {
    pos = new PVector(random(innerLeft, innerRight), random(innerTop, innerBottom));
    history = new PVector[TRAIL_LENGTH];
    for (int i = 0; i < history.length; i++) {
      history[i] = pos.copy();
    }
  }
  
  void update() {
    // Shift history
    for (int i = history.length-1; i > 0; i--) {
      history[i].set(history[i-1]);
    }
    history[0].set(pos);
    
    float angle = noise(pos.x * NOISE_SCALE, pos.y * NOISE_SCALE, zOffset) * TWO_PI * 4.0;
    PVector vel = PVector.fromAngle(angle);
    vel.mult(RIBBON_SPEED);
    pos.add(vel);
    
    if (pos.x < innerLeft || pos.x > innerRight || pos.y < innerTop || pos.y > innerBottom) {
      pos.set(random(innerLeft, innerRight), random(innerTop, innerBottom));
      for (int i = 0; i < history.length; i++) {
        history[i].set(pos);
      }
    }
  }
  
  void display() {
    beginShape();
    for (int i = 0; i < history.length; i++) {
      vertex(history[i].x, history[i].y);
    }
    endShape();
  }
}

// --- Ovoid Class ---
class Ovoid {
  PVector pos;
  float w, h;
  float angle, rotDir;
  int selfColor;
  float tOffset;

  Ovoid(int hex) {
    w = random(MIN_SIZE, MAX_SIZE);
    h = w * random(0.5, 0.8);
    pos = new PVector(random(innerLeft + w/2, innerRight - w/2), random(innerTop + h/2, innerBottom - h/2));
    angle = random(TWO_PI);
    rotDir = random(1) > 0.5 ? 1 : -1;
    selfColor = hex;
    tOffset = random(10000);
  }

  void update() {
    angle += ROTATION_SPEED * rotDir;
    float dx = (noise(tOffset + frameCount * 0.01) - 0.5) * DRIFT_SPEED * 2.5;
    float dy = (noise(tOffset + 5000 + frameCount * 0.01) - 0.5) * DRIFT_SPEED * 2.5;
    pos.add(new PVector(dx, dy));

    float rw = w / 2.0;
    float rh = h / 2.0;
    pos.x = constrain(pos.x, innerLeft + rw, innerRight - rw);
    pos.y = constrain(pos.y, innerTop + rh, innerBottom - rh);
  }

  void display() {
    pushMatrix();
    translate(pos.x, pos.y);
    rotate(angle);
    noStroke();
    fill(selfColor, ALPHA_VALUE);
    ellipse(0, 0, w, h);
    popMatrix();
  }
}
