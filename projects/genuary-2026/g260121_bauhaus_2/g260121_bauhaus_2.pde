/*
 * Bauhaus Variation 6: The Fragmented Silhouette
 * Version: 2026.01.12.21.22.10
 * Focus: Asymmetrical profile fragmentation and shutter-style animation.
 */

// --- Parameters ---
int SKETCH_WIDTH = 480;       // Default: 480
int SKETCH_HEIGHT = 800;      // Default: 800
int PADDING = 40;             // Default: 40
int SEED_VALUE = 404;         // Default: 404
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
  
  // Center composition with slight asymmetrical left-bias
  translate(width/2 - 20, height/2);
  
  drawStaticBackdrop();
  drawProfileCore();
  drawSweepingArcs();
  drawInterferingLines();
  drawFooterTextBlocks();

  // --- Frame Saving and Loop Management ---
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) noLoop();
  }
}

void drawStaticBackdrop() {
  noStroke();
  // Large off-center vertical black column
  fill(activePalette[3]);
  rect(20, -height/2 + PADDING, 110, height - PADDING*2);
  
  // High-contrast yellow rectangle behind the "head"
  fill(activePalette[4]);
  rect(-100, -150, 150, 200);
}

void drawProfileCore() {
  pushMatrix();
  // Subtle "breathing" movement
  float shift = sin(time * 0.5) * 5;
  translate(shift, 0);
  
  // The Eye
  fill(activePalette[3]);
  ellipse(-60, -80, 25, 25);
  fill(activePalette[0]);
  ellipse(-60, -80, 8, 8);
  
  // The Nose/Chin Abstraction (Red)
  fill(activePalette[1]);
  beginShape();
  vertex(-80, -20);
  vertex(-120 + sin(time)*10, 20); // Animated tip
  vertex(-80, 60);
  vertex(-50, 20);
  endShape(CLOSE);
  
  // Heavy black blocks defining the back of the head
  fill(activePalette[3]);
  rect(130, -80, 40, 160);
  popMatrix();
}

void drawSweepingArcs() {
  noFill();
  stroke(activePalette[3]);
  strokeWeight(3);
  
  // Large framing circle from original reference
  ellipse(0, 0, 380, 380);
  
  // Animated Blue Arc
  stroke(activePalette[2]);
  strokeWeight(12);
  float arcStart = PI + QUARTER_PI;
  float arcEnd = arcStart + map(sin(time), -1, 1, 0, HALF_PI);
  arc(0, 0, 330, 330, arcStart, arcEnd);
}

void drawInterferingLines() {
  // Red grid lines cutting through the face (asymmetrical)
  stroke(activePalette[1]);
  strokeWeight(2);
  for(int i = 0; i < 4; i++) {
    float x = -150 + (i * 12);
    line(x, -100, x, 250);
  }
  
  // Horizontal black cut
  stroke(activePalette[3]);
  strokeWeight(8);
  float lineY = 120 + cos(time) * 40;
  line(-200, lineY, 150, lineY);
}

void drawFooterTextBlocks() {
  fill(activePalette[3]);
  noStroke();
  rectMode(CORNER);
  
  // Simulated footer detail
  for(int i = 0; i < 8; i++) {
    float w = 20 + i*5;
    rect(-width/2 + PADDING + 60, height/2 - PADDING - 40 + (i*8), w, 4);
  }
}
