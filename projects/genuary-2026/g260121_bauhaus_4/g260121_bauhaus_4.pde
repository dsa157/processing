/*
 * Bauhaus Variation 9: Linear Grid & Structural Intersections
 * Version: 2026.01.12.21.36.10
 * Focus: High-density horizontal grid-work and rigid linear reconstruction.
 */

// --- Parameters ---
int SKETCH_WIDTH = 480;       // Default: 480
int SKETCH_HEIGHT = 800;      // Default: 800
int PADDING = 40;             // Default: 40
int SEED_VALUE = 202;         // Default: 202
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
  time += 0.03;
  
  drawHeaderBorders();
  drawFooterBorders();
  
  pushMatrix();
  translate(width/2, height/2);
  
  drawLinearBackdrop();
  drawVerticalStems();
  drawHorizontalIntersections();
  drawFocalGeometry();
  
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
  for(int i = 0; i < 9; i++) {
    rect(PADDING + (i * 44), footerY, 32, 35);
  }
}

void drawLinearBackdrop() {
  // Large background circle frame
  noFill();
  stroke(activePalette[3], 100);
  strokeWeight(1);
  ellipse(0, 0, 360, 360);
  
  // Secondary Blue Ring
  stroke(activePalette[2]);
  strokeWeight(4);
  ellipse(40, 20, 280, 280);
}

void drawVerticalStems() {
  noStroke();
  fill(activePalette[3]);
  // Asymmetrical pillar
  rect(30, -180, 60, 360);
  
  // Animated Red Stem
  fill(activePalette[1]);
  float stemH = map(sin(time), -1, 1, 100, 300);
  rect(-80, -150, 15, stemH);
}

void drawHorizontalIntersections() {
  stroke(activePalette[3]);
  strokeWeight(2);
  
  // Dense horizontal grid through the middle
  for(int i = 0; i < 15; i++) {
    float y = -100 + (i * 15);
    float xEnd = 120 + sin(time + i * 0.2) * 50;
    line(-180, y, xEnd, y);
  }
  
  // Thick Blue Focal Line
  stroke(activePalette[2]);
  strokeWeight(10);
  line(-200, 120, 100, 120);
}

void drawFocalGeometry() {
  noStroke();
  // Central Yellow "Eye"
  fill(activePalette[4]);
  ellipse(-60, -40, 40, 40);
  
  // Animated Red Triangle
  fill(activePalette[1]);
  pushMatrix();
  translate(-100, 40);
  float triSize = 30 + cos(time) * 10;
  triangle(0, -triSize, 0, triSize, -triSize, 0);
  popMatrix();
  
  // Small Black Accent Square
  fill(activePalette[3]);
  rect(60, -140, 30, 30);
}
