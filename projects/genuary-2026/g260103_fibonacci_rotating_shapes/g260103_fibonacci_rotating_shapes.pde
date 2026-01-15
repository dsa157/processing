// Version 2025.12.18.13.17.45
// Description: Distributed 3D Golden Nexus Orrery.
// Uses spherical distribution to spread Fibonacci objects across the vertical canvas.

// --- Parameters ---
final int SKETCH_WIDTH = 480;       // default 480
final int SKETCH_HEIGHT = 800;      // default 800
final int PADDING = 40;             // default 40
final int MAX_FRAMES = 900;         // default 900 (Used only for SAVE_FRAMES limit)
final boolean SAVE_FRAMES = false;  // default false
final int ANIMATION_SPEED = 60;     // default 60
final long GLOBAL_SEED = 1111L;     // default 1111L

final int OBJECT_COUNT = 25;        // default 15
final int NESTED_LAYERS = 6;        // default 6
final float PHI = 1.61803398875;    // The Golden Ratio

final boolean INVERT_BG = false;    // Toggle background
final boolean SHOW_GRID = false;    // Toggle grid

// Motion Parameters
final float ROT_SPEED_MIN = 0.005;  // default 0.005
final float ROT_SPEED_MAX = 0.020;  // default 0.020
final float GLOBAL_ROT_SPEED = 0.005; // default 0.005

// Adobe Kuler Palette: "Midnight Gold"
final int[] PALETTE = {
  #020812, // 0: Background
  #FF4E50, // 1: Coral
  #FCCA14, // 2: Gold
  #00D2FF, // 3: Sky
  #FFFFFF  // 4: Ghost White
};

GoldenNexus[] systems;

void settings() {
  size(480, 800, P3D);
}

void setup() {
  frameRate(ANIMATION_SPEED);
  randomSeed(GLOBAL_SEED);
  
  systems = new GoldenNexus[OBJECT_COUNT];
  for (int i = 0; i < OBJECT_COUNT; i++) {
    // Distribute objects using a spherical layout
    float offset = 2.0 / OBJECT_COUNT;
    float increment = PI * (3.0 - sqrt(5.0)); // Golden Angle
    float y = ((i * offset) - 1) + (offset / 2);
    float r = sqrt(1 - pow(y, 2));
    float phi = i * increment;
    
    float x = cos(phi) * r;
    float z = sin(phi) * r;
    
    // Scale vectors to fit the 480x800 aspect ratio
    PVector pos = new PVector(x * 200, y * 350, z * 150);
    systems[i] = new GoldenNexus(pos);
  }
}

void draw() {
  int currentBg = INVERT_BG ? PALETTE[4] : PALETTE[0];
  int currentStroke = INVERT_BG ? PALETTE[0] : PALETTE[4];
  
  background(currentBg);
  
  // Basic Scene Lighting
  ambientLight(80, 80, 100);
  pointLight(255, 255, 255, width/2, height/2, 400);

  if (SHOW_GRID) drawDebugGrid(currentStroke);

  translate(width/2, height/2, -100);
  
  // Slow global rotation for visual interest
  rotateY(frameCount * GLOBAL_ROT_SPEED);
  rotateX(frameCount * GLOBAL_ROT_SPEED * 0.5);

  for (GoldenNexus gn : systems) {
    gn.update();
    gn.display(currentStroke);
  }

  // --- Export Block ---
  if (SAVE_FRAMES && frameCount <= MAX_FRAMES) {
    saveFrame("frames/####.tif");
  }
}

// --- Classes ---

class GoldenNexus {
  PVector pos;
  PVector rotation;
  PVector rotStep;
  float baseScale;
  int accent;

  GoldenNexus(PVector _pos) {
    pos = _pos;
    rotation = new PVector(random(TWO_PI), random(TWO_PI), random(TWO_PI));
    
    // Parameters for unique spin rates
    rotStep = new PVector(
      random(ROT_SPEED_MIN, ROT_SPEED_MAX) * (random(1) > 0.5 ? 1 : -1), 
      random(ROT_SPEED_MIN, ROT_SPEED_MAX) * (random(1) > 0.5 ? 1 : -1), 
      random(ROT_SPEED_MIN, ROT_SPEED_MAX) * (random(1) > 0.5 ? 1 : -1)
    );
    
    baseScale = random(100, 220);
    accent = PALETTE[(int)random(1, 4)];
  }

  void update() {
    rotation.add(rotStep);
  }

  void display(int primaryStroke) {
    pushMatrix();
    translate(pos.x, pos.y, pos.z);
    rotateX(rotation.x);
    rotateY(rotation.y);
    rotateZ(rotation.z);

    float currentSize = baseScale;
    
    for (int i = 0; i < NESTED_LAYERS; i++) {
      float alpha = map(i, 0, NESTED_LAYERS, 255, 60);
      float sw = map(i, 0, NESTED_LAYERS, 2.0, 0.7);
      
      pushMatrix();
      rotateZ(i * HALF_PI);
      
      float w = currentSize;
      float h = currentSize / PHI;
      
      noFill();
      strokeWeight(sw);
      
      // Rect Frame
      stroke(primaryStroke, alpha * 0.4);
      rectMode(CENTER);
      rect(0, 0, w, h);
      
      // Golden Spiral Arc
      stroke(accent, alpha);
      drawArc(w/2, h/2, h);
      
      popMatrix();

      // Transform for next nested layer
      float prevSize = currentSize;
      currentSize /= PHI;
      translate((prevSize - currentSize) / 2, -(prevSize - currentSize) / (2 * PHI), 0);
    }
    popMatrix();
  }

  void drawArc(float x, float y, float r) {
    beginShape();
    for (float a = PI; a <= PI + HALF_PI; a += 0.15) {
      vertex(x + cos(a) * r * 2, y + sin(a) * r * 2);
    }
    endShape();
  }
}

// --- Utilities ---

void drawDebugGrid(int gridColor) {
  stroke(gridColor, 25);
  strokeWeight(1);
  for (int i = -400; i <= 400; i += 100) {
    line(i, -height, -200, i, height, -200);
    line(-width, i, -200, width, i, -200);
  }
}
