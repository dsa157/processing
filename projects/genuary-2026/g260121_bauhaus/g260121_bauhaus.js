/*
 * Genuary 2026 - Day 21: Bauhaus
 * Bauhaus Kinetic Reconstruction
 * Version: 2026.10.02.17.20.00
 * Focus: High-complexity geometric layering with rhythmic motion.
 */

// --- Parameters ---
let SKETCH_WIDTH = 600;       // Default: 800 (Original PDE: 480)
let SKETCH_HEIGHT = 800;      // Default: 800
let PADDING = 40;             // Default: 40
let SEED_VALUE = 1923;        // Default: 1923
let MAX_FRAMES = 900;         // Default: 900
let SAVE_FRAMES = false;      // Default: false
let ANIMATION_SPEED = 30;     // Default: 30
let PALETTE_INDEX = 1;        // Default: 1 (Classic Exhibition)
let INVERT_BG = false;        // Default: false
let TIME_STEP = 0.03;         // Default: 0.03
let BORDER_WEIGHT = 2;        // Default: 2

// Composition Dimensions & Animation Parameters
let ARC_SIZE = 400;           // Default: 400
let BASE_BLOCK_WIDTH = 80;    // Default: 80
let BLOCK_WIDTH_AMP = 10;     // Default: 10
let BLOCK_HEIGHT = 100;       // Default: 100
let HEAD_RING_SIZE = 320;     // Default: 320
let ORBIT_RING_SIZE = 180;    // Default: 180
let ORBIT_DOT_SIZE = 20;      // Default: 20
let HEAD_STROKE_WEIGHT = 4;   // Default: 4
let NOSE_AMP = 15;            // Default: 15
let GRID_V_COUNT = 6;         // Default: 6
let GRID_V_SPACING = 12;      // Default: 12
let GRID_H_COUNT = 8;         // Default: 8
let GRID_H_SPACING = 10;      // Default: 10
let TITLE_CHAR_COUNT = 7;     // Default: 7
let TITLE_CHAR_WIDTH = 40;    // Default: 40
let TITLE_CHAR_HEIGHT = 50;   // Default: 50
let FOOTER_CHAR_COUNT = 10;   // Default: 10
let FOOTER_CHAR_WIDTH = 25;   // Default: 25
let FOOTER_CHAR_HEIGHT = 30;  // Default: 30

// --- Bauhaus Color Palettes (Adobe Color / Kuler inspired) ---
const PALETTES = [
  ['#D92B2B', '#1A1A1B', '#E6D5B8', '#B3A48A', '#F2F2F2'], // 0: Bauhaus Weimar
  ['#F2E8CF', '#D92B2B', '#203652', '#1A1A1B', '#EBC944'], // 1: Classic Exhibition [Cream, Red, Blue, Black, Yellow]
  ['#3E4A59', '#F2C12E', '#F24405', '#0D0D0D', '#F2F2F2'], // 2: Constructivist Contrast
  ['#F4F0EA', '#E05A47', '#204E5F', '#1F1E24', '#ECA43B'], // 3: Kandinsky Warmth
  ['#EAE6DF', '#C83E34', '#325D79', '#272727', '#D9B44A']  // 4: Moholy Modern
];

let activePalette;
let backgroundColor;
let time = 0;

function setup() {
  createCanvas(SKETCH_WIDTH, SKETCH_HEIGHT);
  randomSeed(SEED_VALUE);
  frameRate(ANIMATION_SPEED);

  activePalette = PALETTES[PALETTE_INDEX];
  backgroundColor = INVERT_BG ? activePalette[3] : activePalette[0];
}

function draw() {
  background(backgroundColor);
  time += TIME_STEP;

  // Outer Border/Frame
  noFill();
  stroke(activePalette[3]);
  strokeWeight(BORDER_WEIGHT);
  rect(PADDING, PADDING, width - PADDING * 2, height - PADDING * 2);

  // Center Composition
  push();
  translate(width / 2, height / 2);

  drawComplexBackground();
  drawKineticProfile();
  drawOverlayGrid();
  drawBauhausType();
  pop();

  // --- Frame Saving and Loop Management ---
  if (SAVE_FRAMES) {
    saveCanvas(`frame-${nf(frameCount, 4)}`, 'png');
    if (frameCount >= MAX_FRAMES) noLoop();
  }
}

function drawComplexBackground() {
  noStroke();

  // Large Red Arc (Animated)
  fill(activePalette[1]);
  let arcOsc = map(sin(time * 0.5), -1, 1, PI, PI + QUARTER_PI);
  arc(-width / 8, -height / 12, ARC_SIZE, ARC_SIZE, PI, arcOsc + PI, PIE);

  // Solid Blue Block
  fill(activePalette[2]);
  let rectW = BASE_BLOCK_WIDTH + sin(time) * BLOCK_WIDTH_AMP;
  rect(-width / 2 + PADDING + 20, height / 4, rectW, BLOCK_HEIGHT);
}

function drawKineticProfile() {
  push();

  // The Profile Core (Black Blocks)
  fill(activePalette[3]);
  rectMode(CENTER);

  // Upper head structure
  rect(20, -100, 100, 150);
  rect(-40, -50, 60, 40);

  // Animated "Nose" segment
  let noseX = -70 + sin(time * 0.8) * NOSE_AMP;
  fill(activePalette[1]);
  triangle(noseX, -20, noseX, 20, noseX - 40, 0);

  // Rotating Circle Assembly
  noFill();
  stroke(activePalette[3]);
  strokeWeight(HEAD_STROKE_WEIGHT);
  ellipse(0, 0, HEAD_RING_SIZE, HEAD_RING_SIZE); // Main head ring

  stroke(activePalette[2]);
  strokeWeight(2);
  push();
  rotate(time * 0.2);
  ellipse(60, 0, ORBIT_RING_SIZE, ORBIT_RING_SIZE); // Secondary orbiting ring
  fill(activePalette[3]);
  ellipse(60 + 90, 0, ORBIT_DOT_SIZE, ORBIT_DOT_SIZE); // Orbiting eye/dot
  pop();

  pop();
}

function drawOverlayGrid() {
  stroke(activePalette[1]);
  strokeWeight(2);

  // Vertical Red Lines (Right Side)
  for (let i = 0; i < GRID_V_COUNT; i++) {
    let x = width / 4 + (i * GRID_V_SPACING);
    line(x, -height / 2 + PADDING, x, height / 2 - PADDING);
  }

  // Horizontal Blue Lines (Bottom Right)
  stroke(activePalette[2]);
  for (let i = 0; i < GRID_H_COUNT; i++) {
    let y = height / 6 + (i * GRID_H_SPACING);
    let xStart = width / 10 + (sin(time + i) * 20);
    line(xStart, y, width / 2 - PADDING, y);
  }
}

function drawBauhausType() {
  fill(activePalette[3]);
  rectMode(CORNER);

  // Top Title: "BAUHAUS" Simulation
  let startX = -width / 2 + PADDING + 10;
  let topY = -height / 2 + PADDING + 10;

  for (let i = 0; i < TITLE_CHAR_COUNT; i++) {
    rect(startX + (i * (TITLE_CHAR_WIDTH + 15)), topY, TITLE_CHAR_WIDTH, TITLE_CHAR_HEIGHT);
  }

  // Bottom Footer: "B 4 3 U H A..." Simulation
  let footerY = height / 2 - PADDING - 60;
  for (let i = 0; i < FOOTER_CHAR_COUNT; i++) {
    let x = -width / 2 + PADDING + 10 + (i * 40);
    rect(x, footerY, FOOTER_CHAR_WIDTH, FOOTER_CHAR_HEIGHT);
    // Tiny "Parameter" text simulation below footer
    rect(x, footerY + 40, 20, 4);
    rect(x, footerY + 48, 15, 4);
  }
}
