// =============================================================================
// g260101_one_color_one_shape_4.js
// Genuary 2026 - Day 01: One Color, One Shape
// Converted from Processing/Java to p5.js
// Version: 2026.09.29.22.55.00
//
// Description:
//   Animated grid of nested, rotating rectangles with pulsing opacity and scale.
//   The grid subdivides recursively based on a chance parameter. Each cell's
//   shape rotates continuously with a spatial phase offset creating a wave effect.
// =============================================================================

// --- Parameters ---
const SKETCH_WIDTH        = 900;   // 480
const SKETCH_HEIGHT       = 900;   // 800
const SEED_VALUE          = 42;    // 42
const PADDING             = 40;    // 40
const MAX_FRAMES          = 900;   // 900
const SAVE_FRAMES         = false; // false
const ANIMATION_SPEED     = 30;    // 30
const SHOW_GRID           = false; // false
const INVERT_COLORS       = false; // false

// --- Grid Settings ---
const GRID_ROWS           = 10;    // 10
const GRID_COLS           = 6;     // 6
const SUBDIVIDE_CHANCE    = 0.65;  // 0.65
const ROTATION_INCREMENT  = 0.04;  // 0.04
const SHAPE_MAX_SIZE      = 0.85;  // 0.85
const OPACITY_SPEED       = 0.1;   // 0.1

// --- Color Palettes (Adobe Kuler) ---
// 5 palettes: PALETTE_INDEX selects active one
const COLOR_PALETTES = [
  // 0: Monochromatic Deep Teal (original)
  ["#023047", "#219EBC", "#8ECAE6", "#FFB703", "#FB8500"],
  // 1: Warm Desert Sunset
  ["#2D1B0E", "#C9541D", "#E8944A", "#F5CBA7", "#FFECD1"],
  // 2: Midnight Violet
  ["#0D0221", "#7B2D8B", "#BD4FBE", "#E09EF5", "#F5D5FF"],
  // 3: Forest Moss
  ["#0A1A0A", "#2D6A4F", "#52B788", "#B7E4C7", "#D8F3DC"],
  // 4: Crimson Ice
  ["#0B0C1A", "#9B1C1C", "#E53E3E", "#FEB2B2", "#FFF5F5"],
];

// --- Palette Selection ---
let PALETTE_INDEX     = 0; // 0 = Deep Teal (0-4)
let BG_COLOR_INDEX    = 0; // index within active palette
let SHAPE_COLOR_INDEX = 1; // index within active palette

// =============================================================================

function setup() {
  createCanvas(SKETCH_WIDTH, SKETCH_HEIGHT);
  randomSeed(SEED_VALUE);
  frameRate(ANIMATION_SPEED);
  rectMode(CENTER);
}

function draw() {
  let palette = COLOR_PALETTES[PALETTE_INDEX];
  let bgCol   = color(palette[BG_COLOR_INDEX]);
  let fgCol   = color(palette[SHAPE_COLOR_INDEX]);

  if (INVERT_COLORS) {
    background(fgCol);
  } else {
    background(bgCol);
  }

  noFill();

  let availableWidth  = width  - PADDING * 2;
  let availableHeight = height - PADDING * 2;
  let cellW = availableWidth  / GRID_COLS;
  let cellH = availableHeight / GRID_ROWS;

  // Re-seed each frame so subdivision structure stays static across frames
  randomSeed(SEED_VALUE);

  push();
  translate(PADDING + cellW / 2, PADDING + cellH / 2);

  for (let i = 0; i < GRID_COLS; i++) {
    for (let j = 0; j < GRID_ROWS; j++) {
      drawNestedCell(i * cellW, j * cellH, cellW, cellH, 0);
    }
  }
  pop();

  if (frameCount >= MAX_FRAMES) noLoop();
}

// --- Recursive subdivision ---
function drawNestedCell(x, y, w, h, level) {
  if (level < 3 && random(1.0) < SUBDIVIDE_CHANCE) {
    let newW = w / 2;
    let newH = h / 2;
    drawNestedCell(x - newW / 2, y - newH / 2, newW, newH, level + 1);
    drawNestedCell(x + newW / 2, y - newH / 2, newW, newH, level + 1);
    drawNestedCell(x - newW / 2, y + newH / 2, newW, newH, level + 1);
    drawNestedCell(x + newW / 2, y + newH / 2, newW, newH, level + 1);
  } else {
    renderShape(x, y, w, h);
  }
}

// --- Render a single animated rectangle ---
function renderShape(x, y, w, h) {
  let palette = COLOR_PALETTES[PALETTE_INDEX];
  let bgCol   = color(palette[BG_COLOR_INDEX]);
  let fgCol   = color(palette[SHAPE_COLOR_INDEX]);

  // Distance from canvas center for spatial phase variance
  let distFromCenter = dist(x, y, width / 2, height / 2);

  // Continuous linear rotation with spatial offset
  let rotationAngle = frameCount * ROTATION_INCREMENT + distFromCenter * 0.02;

  // Sine waves for scale and opacity pulsing
  let wave        = sin(frameCount * 0.05 + distFromCenter * 0.01);
  let opacitySeed = x * 1.7 + y * 2.9;
  let opacityWave = sin(frameCount * OPACITY_SPEED + opacitySeed);

  // Optional grid overlay
  if (SHOW_GRID) {
    strokeWeight(1);
    let gridCol = INVERT_COLORS ? bgCol : fgCol;
    stroke(red(gridCol), green(gridCol), blue(gridCol), 30);
    rect(x, y, w, h);
  }

  push();
  translate(x, y);
  rotate(rotationAngle);

  let scaleFactor = map(wave, -1, 1, 0.15, SHAPE_MAX_SIZE);
  let weight      = map(wave, -1, 1, 0.5, 3.0);
  let alpha       = map(opacityWave, -1, 1, 15, 255);

  let shapeCol = INVERT_COLORS ? bgCol : fgCol;
  stroke(red(shapeCol), green(shapeCol), blue(shapeCol), alpha);
  strokeWeight(weight);
  rect(0, 0, w * scaleFactor, h * scaleFactor);

  pop();
}
