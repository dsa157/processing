/**
 * Varied Procedural Glyph Morph
 * Version: 2026.01.06.22.46.12
 * Advanced procedural generation for complex grid objects with diverse DNA types.
 */

// --- Configuration Parameters ---
int SKETCH_WIDTH = 480;       // Default: 480
int SKETCH_HEIGHT = 800;      // Default: 800
int PADDING = 60;             // Default: 60
int MAX_FRAMES = 900;         // Default: 900
boolean SAVE_FRAMES = false;  // Default: false
int ANIMATION_SPEED = 30;     // Default: 30
int GLOBAL_SEED = 157;        // Seed for reproducibility

// Grid Settings
int GRID_ROWS = 15;           // Default: 15
int GRID_COLS = 10;           // Default: 10
float SHAPE_SIZE = 35.0;      // Default: 20.0
boolean SHOW_GRID = false;    // Default: false

// Visuals
boolean INVERT_BACKGROUND = false; // Default: false
int PALETTE_INDEX = 4;             // 0 to 4

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
      float cx = PADDING + (c * (drawAreaW / (GRID_COLS - 1)));
      float cy = PADDING + (r * (drawAreaH / (GRID_ROWS - 1)));
      
      float angle = map(c, 0, GRID_COLS, 0, TWO_PI);
      float radius = map(r, 0, GRID_ROWS, 40, maxRadius);
      
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
  
  morphFactor = (sin(frameCount * 0.015) + 1.0) / 2.0;
  
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
  float rotSpeed;
  int dnaType; // 0: Radial, 1: Geometric, 2: Hatching
  
  int detailCount;
  float strokeW;
  
  ComplexGlyph(float cx, float cy, float px, float py, float ang, int col) {
    cartX = cx; cartY = cy;
    polarX = px; polarY = py;
    targetAngle = ang;
    baseCol = col;
    
    dnaType = floor(random(3));
    rotSpeed = random(-0.04, 0.04);
    detailCount = floor(random(3, 7));
    strokeW = random(1.0, 2.0);
  }
  
  void display(float m) {
    float x = lerp(cartX, polarX, m);
    float y = lerp(cartY, polarY, m);
    
    // Color blending logic
    int colA = PALETTES[PALETTE_INDEX][1];
    int colB = PALETTES[PALETTE_INDEX][2];
    int colC = PALETTES[PALETTE_INDEX][3];
    float w = map(targetAngle, 0, TWO_PI, 0, 1);
    int gradCol = (w < 0.5) ? lerpColor(colA, colB, w*2) : lerpColor(colB, colC, (w-0.5)*2);
    int finalCol = lerpColor(baseCol, gradCol, m);
    
    pushMatrix();
    translate(x, y);
    rotate(lerp(0, targetAngle, m) + (frameCount * rotSpeed));
    
    noFill();
    stroke(finalCol);
    strokeWeight(strokeW);
    
    renderDNA();
    
    popMatrix();
  }
  
  void renderDNA() {
    float r = SHAPE_SIZE / 2.0;
    
    switch(dnaType) {
      case 0: // Radial Spokes
        for (int i = 0; i < detailCount; i++) {
          rotate(TWO_PI / detailCount);
          line(0, 0, r, 0);
          ellipse(r, 0, r * 0.3, r * 0.3);
        }
        break;
        
      case 1: // Concentric Geometric
        for (int i = 1; i <= 3; i++) {
          float s = (r * 2) * (i / 3.0);
          if (i % 2 == 0) ellipse(0, 0, s, s);
          else rect(0, 0, s, s);
        }
        break;
        
      case 2: // Cross-Hatching
        for (int i = 0; i < detailCount; i++) {
          float offset = map(i, 0, detailCount, -r, r);
          line(-r, offset, r, offset);
          line(offset, -r, offset, r);
        }
        break;
    }
  }
}
