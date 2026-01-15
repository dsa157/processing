/*
 * Bauhaus Variation 7.1: Curvilinear Intersections with Structural Borders
 * Version: 2026.01.12.21.32.45
 * Focus: Integrating Variation 7's fluid arcs with heavy header/footer block framing.
 */

// --- Parameters ---
int SKETCH_WIDTH = 480;       // Default: 480
int SKETCH_HEIGHT = 800;      // Default: 800
int PADDING = 40;             // Default: 40
int SEED_VALUE = 909;         // Default: 909
int MAX_FRAMES = 900;         // Default: 900
boolean SAVE_FRAMES = false;  // Default: false
int ANIMATION_SPEED = 30;     // Default: 30
int PALETTE_INDEX = 1;        // Default: 1 (Classic Exhibition)
boolean INVERT_BG = false;    // Default: false

// --- Bauhaus Color Palettes ---
int[][] PALETTES = {
  {#D92B2B, #1A1A1B, #E6D5B8, #B3A48A, #F2F2F2}, 
  {#F2E8CF, #D92B2B, #203652, #1A1A1B, #EBC944}, // 0:Cream, 1:Red, 2:Blue, 3:Black, 4:Yellow
  {#3E4A59, #F2C12E, #F24405, #0D0D0D, #F2F2F2}
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
  time += 0.025;
  
  // 1. Draw Structural Borders (Top/Bottom)
  drawHeaderBorders();
  drawFooterBorders();
  
  // 2. Center and Draw Variation 7 Elements
  pushMatrix();
  translate(width/2, height/2);
  
  drawCurvedBackdrop();
  drawInterlockingRings();
  drawAsymmetricBlocks();
  drawAnimatedProfileDetails();
  
  popMatrix();

  // --- Frame Saving and Loop Management ---
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) noLoop();
  }
}

void drawHeaderBorders() {
  fill(activePalette[3]);
  noStroke();
  rectMode(CORNER);
  float blockW = 52;
  float blockH = 95;
  for(int i = 0; i < 7; i++) {
    rect(PADDING + 8 + (i * (blockW + 4)), PADDING, blockW, blockH);
  }
}

void drawFooterBorders() {
  fill(activePalette[3]);
  rectMode(CORNER);
  float footerY = height - PADDING - 90;
  
  // Secondary "Parameter" blocks
  for(int i = 0; i < 9; i++) {
    rect(PADDING + (i * 44), footerY, 32, 35);
  }
  
  // Fine technical lines at the very bottom
  stroke(activePalette[3]);
  strokeWeight(2);
  line(PADDING, height - PADDING - 10, width - PADDING, height - PADDING - 10);
  noStroke();
  rect(PADDING, height - PADDING - 35, 120, 4);
}

void drawCurvedBackdrop() {
  noStroke();
  fill(activePalette[1], 230); // Red
  float arcExt = map(sin(time * 0.4), -1, 1, HALF_PI, PI);
  arc(-15, -15, 380, 380, PI, PI + arcExt, PIE);
  
  fill(activePalette[4], 140); // Yellow
  ellipse(60, 80, 260, 260);
}

void drawInterlockingRings() {
  noFill();
  stroke(activePalette[3]);
  strokeWeight(2);
  ellipse(0, 0, 320, 320);
  
  stroke(activePalette[2]); // Blue
  strokeWeight(7);
  pushMatrix();
  float ringX = cos(time * 0.5) * 35;
  translate(ringX, 0);
  ellipse(30, 0, 210, 210);
  popMatrix();
}

void drawAsymmetricBlocks() {
  fill(activePalette[3]);
  noStroke();
  rectMode(CORNER);
  
  // Vertical pillar anchoring the right side
  rect(40, -160, 75, 320);
  
  // Blue accent square
  fill(activePalette[2]);
  rect(-160, 100, 70, 70);
}

void drawAnimatedProfileDetails() {
  pushMatrix();
  translate(-30, -30);
  
  // Rotating 'Eye'
  fill(activePalette[2]);
  ellipse(0, 0, 25, 25);
  
  stroke(activePalette[3]);
  strokeWeight(1.5);
  pushMatrix();
  rotate(time * 1.2);
  line(0, 0, 50, 0);
  fill(activePalette[2]);
  noStroke();
  ellipse(50, 0, 12, 12);
  popMatrix();
  
  // Animated 'Nose' plane
  fill(activePalette[1]);
  float noseW = 50 + sin(time * 0.9) * 25;
  rect(-70, 35, noseW, 10);
  popMatrix();
  
  // Horizontal grid line intersections
  stroke(activePalette[3], 180);
  strokeWeight(1);
  for(int i = 0; i < 4; i++) {
    float y = 140 + (i * 10);
    line(-180, y, 120, y);
  }
}
