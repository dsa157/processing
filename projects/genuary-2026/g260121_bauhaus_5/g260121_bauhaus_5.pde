/*
 * Bauhaus Master Poster Generator
 * Version: 2026.01.12.21.45.00
 * A composite of all variations: Borders, Curvilinear Arcs, and Dense Grids.
 */

// --- Global Parameters ---
int SKETCH_WIDTH = 480;       // Default: 480
int SKETCH_HEIGHT = 800;      // Default: 800
int PADDING = 40;             // Default: 40
int SEED_VALUE = 2026;        // Default: 2026
int MAX_FRAMES = 900;         // Default: 900
boolean SAVE_FRAMES = false;  // Default: false
int ANIMATION_SPEED = 30;     // Default: 30
int PALETTE_INDEX = 1;        // Default: 1 (Classic Exhibition)
boolean INVERT_BG = false;    // Default: false
boolean SHOW_GRID = false;    // Default: false

// --- Master Parameterized Values ---
float BORDER_BLOCK_W = 52.0;  // Default: 52.0
float BORDER_BLOCK_H = 55.0;  // Default: 55.0
int GRID_LINE_COUNT = 18;     // Default: 18
float PROFILE_SCALE = 1.1;    // Default: 1.1
float ROTATION_SPEED = 0.02;  // Default: 0.02

// --- Color Palettes ---
int[][] PALETTES = {
  {#D92B2B, #1A1A1B, #E6D5B8, #B3A48A, #F2F2F2}, // Red/Black/Cream
  {#F2E8CF, #D92B2B, #203652, #1A1A1B, #EBC944}, // Classic Exhibition [0:Cream, 1:Red, 2:Blue, 3:Black, 4:Yellow]
  {#3E4A59, #F2C12E, #F24405, #0D0D0D, #F2F2F2}, // High Contrast
  {#8C3030, #262626, #BFB8AD, #59544E, #D9D9D9}, // Industrial
  {#1A1A1B, #F2F2F2, #D92B2B, #B3A48A, #203652}  // Dark Mode Base
};

int[] activePalette;
color backgroundColor;
float time = 0;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  randomSeed(SEED_VALUE);
  frameRate(ANIMATION_SPEED);
  
  activePalette = PALETTES[PALETTE_INDEX];
  backgroundColor = INVERT_BG ? activePalette[3] : activePalette[0]; 
}

void draw() {
  background(backgroundColor);
  time += ROTATION_SPEED;
  
  // 1. Structural Framing
  drawMasterHeader();
  drawMasterFooter();
  
  // 2. Central Composition
  pushMatrix();
  translate(width/2, height/2);
  scale(PROFILE_SCALE);
  
  drawBackdropArcs();
  drawDenseHorizontalGrid();
  drawAsymmetricProfile();
  drawKineticOrbits();
  
  popMatrix();
  
  // 3. Grid Visualization
  if (SHOW_GRID) drawDebugGrid();

  // --- Frame Saving and Loop Management ---
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) noLoop();
  }
}

// --- Layering Functions ---

void drawMasterHeader() {
  fill(activePalette[3]);
  noStroke();
  rectMode(CORNER);
  float startX = PADDING + 8;
  for(int i = 0; i < 7; i++) {
    // Subtle height oscillation for "living" typography
    float h = BORDER_BLOCK_H * 2 + sin(time * 0.5 + i) * 5;
    rect(startX + (i * (BORDER_BLOCK_W + 4)), PADDING, BORDER_BLOCK_W, h);
  }
}

void drawMasterFooter() {
  fill(activePalette[3]);
  float footerY = height - PADDING - 90;
  for(int i = 0; i < 9; i++) {
    rect(PADDING + (i * 44), footerY, 32, 40);
  }
  // Parameter sub-lines
  stroke(activePalette[3]);
  strokeWeight(2);
  line(PADDING, height - PADDING - 15, width - PADDING, height - PADDING - 15);
}

void drawBackdropArcs() {
  noStroke();
  // Main Red Sweeping Arc
  fill(activePalette[1], 240);
  float arcMotion = map(sin(time * 0.3), -1, 1, HALF_PI, PI + QUARTER_PI);
  arc(-10, -10, 360, 360, PI, PI + arcMotion, PIE);
  
  // Large Yellow Balancing Circle
  fill(activePalette[4], 160);
  ellipse(70, 60, 240, 240);
}

void drawDenseHorizontalGrid() {
  stroke(activePalette[3], 120);
  strokeWeight(1);
  for(int i = 0; i < GRID_LINE_COUNT; i++) {
    float y = -140 + (i * 18);
    // Asymmetric length
    float xLen = 100 + cos(time + i*0.1) * 40;
    line(-180, y, xLen, y);
  }
}

void drawAsymmetricProfile() {
  // Main Pillar (Black)
  fill(activePalette[3]);
  noStroke();
  rectMode(CENTER);
  rect(35, 0, 80, 340);
  
  // Geometric "Eye" (Blue)
  fill(activePalette[2]);
  ellipse(-60, -60, 45, 45);
  fill(backgroundColor);
  ellipse(-60, -60, 15, 15);
  
  // Animated "Shutter" (Yellow)
  fill(activePalette[4]);
  float shutterX = sin(time * 0.8) * 25;
  rect(-50 + shutterX, -20, 70, 12);
  
  // Red Triangle "Nose"
  fill(activePalette[1]);
  triangle(-110, 20, -110, 80, -150, 50);
}

void drawKineticOrbits() {
  noFill();
  stroke(activePalette[2]);
  strokeWeight(2);
  ellipse(0, 0, 340, 340); // Guide Circle
  
  // Orbiting Dots
  fill(activePalette[2]); // Blue
  pushMatrix();
  rotate(time);
  ellipse(170, 0, 25, 25);
  popMatrix();
  
  fill(activePalette[1]); // Red
  pushMatrix();
  rotate(-time * 1.5);
  ellipse(130, 0, 20, 20);
  popMatrix();
}

void drawDebugGrid() {
  stroke(150, 50);
  strokeWeight(1);
  for(int i = 0; i < width; i+=20) line(i, 0, i, height);
  for(int j = 0; j < height; j+=20) line(0, j, width, j);
}
