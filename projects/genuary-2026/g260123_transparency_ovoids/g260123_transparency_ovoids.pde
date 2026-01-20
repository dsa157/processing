/**
 * Overlapping Ovoids: Transparency & Color Theory
 * Fix: Added Alpha channel to hex literals to ensure visibility across all palettes.
 * Version: 2026.01.17.13.48.10
 */

// --- Global Parameters ---
int SKETCH_WIDTH = 480;       // Default: 480
int SKETCH_HEIGHT = 800;      // Default: 800
int SEED_VALUE = 42;          // Default: 42
int PADDING = 40;             // Default: 40
int MAX_FRAMES = 900;         // Default: 900
int ANIMATION_SPEED = 30;     // Default: 30
boolean SAVE_FRAMES = false;  // Default: false
boolean INVERT_BG = true;    // Default: false
boolean SHOW_GRID = false;    // Default: false

// --- Visualization Parameters ---
int OVOID_COUNT = 50;         // Default: 45
float MIN_SIZE = 60;          // Default: 40
float MAX_SIZE = 180;         // Default: 180
float ROTATION_SPEED = 0.012; // Default: 0.012
int ALPHA_VALUE = 140;        // Default: 140

// --- Color Palettes (Ensured 0xFF prefix for Alpha) ---
int PALETTE_INDEX = 3;        // Changed to 1 to verify fix
int[][] PALETTES = {
  {0xFF00FFFF, 0xFFFF00FF, 0xFFFFFF00, 0xFF000000}, // 0: CMYK
  {0xFFFF5E5B, 0xFFD72638, 0xFF3F88C5, 0xFFF49D37}, // 1: Bold Modern
  {0xFF264653, 0xFF2A9D8F, 0xFFE9C46A, 0xFFF4A261}, // 2: Sandy Stone
  {0xFF606C38, 0xFF283618, 0xFFDDA15E, 0xFFBC6C25}, // 3: Earthy Tones
  {0xFF003049, 0xFFD62828, 0xFFF77F00, 0xFFFCBF49}  // 4: High Contrast
};

Ovoid[] shapes;
int activeBgColor;
float innerLeft, innerRight, innerTop, innerBottom;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  randomSeed(SEED_VALUE);
  frameRate(ANIMATION_SPEED);
  
  innerLeft = PADDING;
  innerRight = width - PADDING;
  innerTop = PADDING;
  innerBottom = height - PADDING;
  
  // Set background from palette or default
  int[] currentPalette = PALETTES[PALETTE_INDEX];
  if (INVERT_BG) {
    activeBgColor = color(25);
  } else {
    activeBgColor = color(245);
  }
  
  shapes = new Ovoid[OVOID_COUNT];
  for (int i = 0; i < OVOID_COUNT; i++) {
    int hexColor = currentPalette[i % currentPalette.length];
    shapes[i] = new Ovoid(hexColor);
  }
}

void draw() {
  background(activeBgColor);
  
  if (SHOW_GRID) drawDebugGrid();

  // MULTIPLY is a subtractive blend mode.
  // It darkens the background, which is why it requires a light background to be visible.
  blendMode(INVERT_BG ? SCREEN : MULTIPLY);
  
  for (Ovoid o : shapes) {
    o.update();
    o.display();
  }
  
  blendMode(BLEND); 

  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) noLoop();
  }
}

void drawDebugGrid() {
  stroke(200, 0, 0, 100);
  noFill();
  rect(innerLeft, innerTop, innerRight - innerLeft, innerBottom - innerTop);
}

class Ovoid {
  float x, y, w, h;
  float angle, rotDir, tOffset;
  int selfColor;

  Ovoid(int hex) {
    w = random(MIN_SIZE, MAX_SIZE);
    h = w * random(0.4, 0.7);
    
    // Bounds check for initial spawn
    float r = w / 2.0;
    x = random(innerLeft + r, innerRight - r);
    y = random(innerTop + r, innerBottom - r);
    
    angle = random(TWO_PI);
    rotDir = random(1) > 0.5 ? 1 : -1;
    selfColor = hex;
    tOffset = random(1000);
  }

  void update() {
    angle += ROTATION_SPEED * rotDir;
    
    float dx = sin(frameCount * 0.02 + tOffset) * 0.7;
    float dy = cos(frameCount * 0.02 + tOffset) * 0.7;
    
    float margin = w / 2.0;
    // Boundary collision/containment
    if (x + dx > innerLeft + margin && x + dx < innerRight - margin) {
      x += dx;
    } else {
      rotDir *= -1; // Flip rotation on "bump"
    }
    
    if (y + dy > innerTop + margin && y + dy < innerBottom - margin) {
      y += dy;
    }
  }

  void display() {
    pushMatrix();
    translate(x, y);
    rotate(angle);
    noStroke();
    // Re-applying alpha to the hex color
    fill(selfColor, ALPHA_VALUE);
    ellipse(0, 0, w, h);
    popMatrix();
  }
}
