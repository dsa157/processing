/**
 * Polar Projection Morph with Angular Gradient
 * Version: 2026.01.06.22.53.55
 * Primitives transition between grid and circle, shifting color based on angle.
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
int GRID_ROWS = 22;           // Default: 22
int GRID_COLS = 14;           // Default: 14
float SHAPE_SIZE = 20.0;      // Default: 12.0
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

ShapePrimitive[] primitives;
float morphFactor = 0;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  randomSeed(GLOBAL_SEED);
  frameRate(ANIMATION_SPEED);
  rectMode(CENTER);
  
  int totalShapes = GRID_ROWS * GRID_COLS;
  primitives = new ShapePrimitive[totalShapes];
  
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
      float radius = map(r, 0, GRID_ROWS, 30, maxRadius);
      
      float px = (width / 2.0) + cos(angle) * radius;
      float py = (height / 2.0) + sin(angle) * radius;
      
      int type = floor(random(3));
      // Base color chosen from palette, but will be tinted by angle later
      int pickColor = PALETTES[PALETTE_INDEX][floor(random(1, 5))];
      
      primitives[index++] = new ShapePrimitive(cx, cy, px, py, angle, type, pickColor);
    }
  }
}

void draw() {
  int bgColor = PALETTES[PALETTE_INDEX][0];
  int fillBG = INVERT_BACKGROUND ? ~bgColor | 0xFF000000 : bgColor;
  background(fillBG);
  
  morphFactor = (sin(frameCount * 0.02) + 1.0) / 2.0;
  
  if (SHOW_GRID) drawDebugGrid();
  
  for (ShapePrimitive p : primitives) {
    p.display(morphFactor);
  }
  
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) noLoop();
  }
}

void drawDebugGrid() {
  stroke(255, 20);
  noFill();
  ellipse(width/2, height/2, width-PADDING*2, width-PADDING*2);
}

class ShapePrimitive {
  float cartX, cartY, polarX, polarY;
  float targetAngle;
  int type, baseCol;
  float rotOffset;
  
  ShapePrimitive(float cx, float cy, float px, float py, float ang, int t, int f) {
    cartX = cx; cartY = cy;
    polarX = px; polarY = py;
    targetAngle = ang;
    type = t; baseCol = f;
    rotOffset = random(TWO_PI);
  }
  
  void display(float m) {
    float x = lerp(cartX, polarX, m);
    float y = lerp(cartY, polarY, m);
    float currentRot = lerp(0, targetAngle, m);
    
    // Gradient Logic: Interpolate color based on angle when morphing to polar
    // We pick two colors from the palette to lerp between based on angle
    int colA = PALETTES[PALETTE_INDEX][1];
    int colB = PALETTES[PALETTE_INDEX][2];
    int colC = PALETTES[PALETTE_INDEX][3];
    
    float colorWeight = map(targetAngle, 0, TWO_PI, 0, 1);
    int gradientCol;
    if (colorWeight < 0.5) {
      gradientCol = lerpColor(colA, colB, colorWeight * 2);
    } else {
      gradientCol = lerpColor(colB, colC, (colorWeight - 0.5) * 2);
    }
    
    // Blend the original random color with the angular gradient as we morph
    int finalCol = lerpColor(baseCol, gradientCol, m);
    
    pushMatrix();
    translate(x, y);
    rotate(currentRot + (rotOffset * (1.0 - m)));
    
    noStroke();
    fill(finalCol);
    
    float s = SHAPE_SIZE;
    if (type == 0) rect(0, 0, s, s);
    else if (type == 1) ellipse(0, 0, s, s);
    else triangle(-s/2, s/2, s/2, s/2, 0, -s/2);
    
    popMatrix();
  }
}
