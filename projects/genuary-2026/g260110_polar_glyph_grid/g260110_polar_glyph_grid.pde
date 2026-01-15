/**
 * Procedural Glyph Polar Morph
 * Version: 2026.01.06.22.42.15
 * Replaces primitives with complex generated objects that morph between layouts.
 */

// --- Configuration Parameters ---
int SKETCH_WIDTH = 480;       // Default: 480
int SKETCH_HEIGHT = 800;      // Default: 800
int PADDING = 60;             // Default: 60
int MAX_FRAMES = 900;         // Default: 900
boolean SAVE_FRAMES = false;  // Default: false
int ANIMATION_SPEED = 30;     // Default: 30
int GLOBAL_SEED = 30;         // Seed for reproducibility

// Grid Settings
int GRID_ROWS = 15;           // Default: 18
int GRID_COLS = 10;           // Default: 10
float SHAPE_SIZE = 35.0;      // Default: 20.0
boolean SHOW_GRID = false;    // Default: false

// Visuals
boolean INVERT_BACKGROUND = false; // Default: false
int PALETTE_INDEX = 1;             // 0 to 4

// Palettes from Adobe Color (Kuler)
int[][] PALETTES = {
  {0xFF1A535C, 0xFF4ECDC4, 0xFFF7FFF7, 0xFFFF6B6B, 0xFFFFE66D}, 
  {0xFF264653, 0xFF2A9D8F, 0xFFE9C46A, 0xFFF4A261, 0xFFE76F51}, 
  {0xFF003049, 0xFFD62828, 0xFFF77F00, 0xFFFCBF49, 0xFFEAE2B7}, 
  {0xFF606C38, 0xFF283618, 0xFFFEFAE0, 0xFFDDA15E, 0xFFBC6C25}, 
  {0xFF22223B, 0xFF4A4E69, 0xFF9A8C98, 0xFFC9ADA7, 0xFFF2E9E1}  
};

ComplexGlyph[] glyphs;
float morphFactor = 0;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  randomSeed(GLOBAL_SEED);
  frameRate(ANIMATION_SPEED);
  rectMode(CENTER);
  
  int totalShapes = GRID_ROWS * GRID_COLS;
  glyphs = new ComplexGlyph[totalShapes];
  
  float drawAreaW = width - (PADDING * 2);
  float drawAreaH = height - (PADDING * 2);
  float maxRadius = min(drawAreaW, drawAreaH) / 2.0;
  
  int index = 0;
  for (int r = 0; r < GRID_ROWS; r++) {
    for (int c = 0; c < GRID_COLS; c++) {
      // Cartesian Base
      float cx = PADDING + (c * (drawAreaW / (GRID_COLS - 1)));
      float cy = PADDING + (r * (drawAreaH / (GRID_ROWS - 1)));
      
      // Polar Target
      float angle = map(c, 0, GRID_COLS, 0, TWO_PI);
      float radius = map(r, 0, GRID_ROWS, 35, maxRadius);
      
      float px = (width / 2.0) + cos(angle) * radius;
      float py = (height / 2.0) + sin(angle) * radius;
      
      int baseCol = PALETTES[PALETTE_INDEX][floor(random(1, 5))];
      glyphs[index++] = new ComplexGlyph(cx, cy, px, py, angle, baseCol);
    }
  }
}

void draw() {
  int bgColor = PALETTES[PALETTE_INDEX][0];
  int fillBG = INVERT_BACKGROUND ? ~bgColor | 0xFF000000 : bgColor;
  background(fillBG);
  
  morphFactor = (sin(frameCount * 0.02) + 1.0) / 2.0;
  
  for (ComplexGlyph g : glyphs) {
    g.display(morphFactor);
  }
  
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) noLoop();
  }
}

class ComplexGlyph {
  float cartX, cartY, polarX, polarY;
  float targetAngle;
  int baseCol;
  float rotationSpeed;
  
  // Procedural features
  int petalCount;
  float innerScale;
  boolean hasInnerCircle;
  float strokeW;
  
  ComplexGlyph(float cx, float cy, float px, float py, float ang, int col) {
    cartX = cx; cartY = cy;
    polarX = px; polarY = py;
    targetAngle = ang;
    baseCol = col;
    
    // Randomize procedural traits
    rotationSpeed = random(-0.05, 0.05);
    petalCount = floor(random(3, 8));
    innerScale = random(0.3, 0.7);
    hasInnerCircle = random(1) > 0.5;
    strokeW = random(1, 2.5);
  }
  
  void display(float m) {
    float x = lerp(cartX, polarX, m);
    float y = lerp(cartY, polarY, m);
    
    // Angular gradient blending
    int colA = PALETTES[PALETTE_INDEX][1];
    int colB = PALETTES[PALETTE_INDEX][2];
    int colC = PALETTES[PALETTE_INDEX][3];
    float colorWeight = map(targetAngle, 0, TWO_PI, 0, 1);
    int gradientCol = (colorWeight < 0.5) ? 
                      lerpColor(colA, colB, colorWeight * 2) : 
                      lerpColor(colB, colC, (colorWeight - 0.5) * 2);
    
    int finalCol = lerpColor(baseCol, gradientCol, m);
    
    pushMatrix();
    translate(x, y);
    rotate(lerp(0, targetAngle, m) + (frameCount * rotationSpeed));
    
    noFill();
    stroke(finalCol);
    strokeWeight(strokeW);
    
    // Draw Generated Glyph
    for (int i = 0; i < petalCount; i++) {
      pushMatrix();
      rotate(TWO_PI * i / petalCount);
      // Outer component
      rect(SHAPE_SIZE * 0.4, 0, SHAPE_SIZE * 0.3, SHAPE_SIZE * 0.1);
      // Connection line
      line(0, 0, SHAPE_SIZE * 0.4, 0);
      popMatrix();
    }
    
    if (hasInnerCircle) {
      ellipse(0, 0, SHAPE_SIZE * innerScale, SHAPE_SIZE * innerScale);
    } else {
      rect(0, 0, SHAPE_SIZE * innerScale, SHAPE_SIZE * innerScale);
    }
    
    popMatrix();
  }
}
