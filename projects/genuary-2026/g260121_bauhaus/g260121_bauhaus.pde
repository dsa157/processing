/*
 * Bauhaus Kinetic Reconstruction
 * Version: 2026.01.11.18.45.30
 * Focus: High-complexity geometric layering with rhythmic motion.
 */

// --- Parameters ---
int SKETCH_WIDTH = 480;       // Default: 480
int SKETCH_HEIGHT = 800;      // Default: 800
int PADDING = 40;             // Default: 40
int SEED_VALUE = 1923;        // Default: 1923
int MAX_FRAMES = 900;         // Default: 900
boolean SAVE_FRAMES = false;  // Default: false
int ANIMATION_SPEED = 30;     // Default: 30
int PALETTE_INDEX = 1;        // Default: 1 (Classic Exhibition)
boolean INVERT_BG = false;    // Default: false

// --- Bauhaus Color Palettes ---
int[][] PALETTES = {
  {#D92B2B, #1A1A1B, #E6D5B8, #B3A48A, #F2F2F2}, 
  {#F2E8CF, #D92B2B, #203652, #1A1A1B, #EBC944}, // Classic Exhibition [Yellow, Red, Blue, Black, Cream]
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
  
  // Outer Border/Frame
  noFill();
  stroke(activePalette[3]);
  strokeWeight(2);
  rect(PADDING, PADDING, width - PADDING*2, height - PADDING*2);

  // Center Composition
  translate(width/2, height/2);
  
  drawComplexBackground();
  drawKineticProfile();
  drawOverlayGrid();
  drawBauhausType();

  // --- Frame Saving and Loop Management ---
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) noLoop();
  }
}

void drawComplexBackground() {
  noStroke();
  
  // Large Red Arc (Animated)
  fill(activePalette[1]);
  float arcOsc = map(sin(time * 0.5), -1, 1, PI, PI + QUARTER_PI);
  arc(-width/8, -height/12, 400, 400, PI, arcOsc + PI, PIE);
  
  // Solid Blue Block
  fill(activePalette[2]);
  float rectW = 80 + sin(time) * 10;
  rect(-width/2 + PADDING + 20, height/4, rectW, 100);
}

void drawKineticProfile() {
  pushMatrix();
  
  // The Profile Core (Black Blocks)
  fill(activePalette[3]);
  rectMode(CENTER);
  
  // Upper head structure
  rect(20, -100, 100, 150);
  rect(-40, -50, 60, 40);
  
  // Animated "Nose" segment
  float noseX = -70 + sin(time * 0.8) * 15;
  fill(activePalette[1]);
  triangle(noseX, -20, noseX, 20, noseX - 40, 0);
  
  // Rotating Circle Assembly
  noFill();
  stroke(activePalette[3]);
  strokeWeight(4);
  ellipse(0, 0, 320, 320); // Main head ring
  
  stroke(activePalette[2]);
  strokeWeight(2);
  pushMatrix();
  rotate(time * 0.2);
  ellipse(60, 0, 180, 180); // Secondary orbiting ring
  fill(activePalette[3]);
  ellipse(60 + 90, 0, 20, 20); // Orbiting eye/dot
  popMatrix();
  
  popMatrix();
}

void drawOverlayGrid() {
  stroke(activePalette[1]);
  strokeWeight(2);
  
  // Vertical Red Lines (Right Side)
  float spacing = 12;
  for(int i = 0; i < 6; i++) {
    float x = width/4 + (i * spacing);
    line(x, -height/2 + PADDING, x, height/2 - PADDING);
  }
  
  // Horizontal Blue Lines (Bottom Right)
  stroke(activePalette[2]);
  for(int i = 0; i < 8; i++) {
    float y = height/6 + (i * 10);
    float xStart = width/10 + (sin(time + i) * 20);
    line(xStart, y, width/2 - PADDING, y);
  }
}

void drawBauhausType() {
  fill(activePalette[3]);
  rectMode(CORNER);
  
  // Top Title: "BAUHAUS" Simulation
  float tw = 40;
  float th = 50;
  float startX = -width/2 + PADDING + 10;
  float topY = -height/2 + PADDING + 10;
  
  for(int i = 0; i < 7; i++) {
    rect(startX + (i * (tw + 15)), topY, tw, th);
  }
  
  // Bottom Footer: "B 4 3 U H A..." Simulation
  float footerY = height/2 - PADDING - 60;
  for(int i = 0; i < 10; i++) {
    float x = -width/2 + PADDING + 10 + (i * 40);
    rect(x, footerY, 25, 30);
    // Tiny "Parameter" text simulation below footer
    rect(x, footerY + 40, 20, 4);
    rect(x, footerY + 48, 15, 4);
  }
}
