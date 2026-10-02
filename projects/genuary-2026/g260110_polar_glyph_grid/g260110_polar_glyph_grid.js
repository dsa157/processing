/**
 * Genuary 2026 - Day 10: Polar coordinates
 * Procedural Glyph Polar Morph
 * Version: 2026.10.02.17.42.18
 * Replaces primitives with complex generated objects that morph between cartesian grid and polar layouts.
 */

// --- Configuration Parameters ---
let SKETCH_WIDTH = 800;           // Default: 800 (converted from 480)
let SKETCH_HEIGHT = 800;          // Default: 800
let PADDING = 60;                 // Default: 60
let MAX_FRAMES = 900;             // Default: 900
let SAVE_FRAMES = false;          // Default: false
let ANIMATION_SPEED = 30;         // Default: 30
let GLOBAL_SEED = 30;             // Seed for reproducibility

// Grid Settings
let GRID_ROWS = 15;               // Default: 15 (original comment was 18)
let GRID_COLS = 10;               // Default: 10
let SHAPE_SIZE = 35.0;            // Default: 35.0 (original comment was 20.0)
let SHOW_GRID = false;            // Default: false

// Animation & Morph Parameters
let MORPH_SPEED = 0.02;           // Default: 0.02
let POLAR_MIN_RADIUS = 35.0;      // Default: 35.0

// Glyph Procedural Generation Limits
let ROTATION_SPEED_MIN = -0.05;   // Default: -0.05
let ROTATION_SPEED_MAX = 0.05;    // Default: 0.05
let PETAL_COUNT_MIN = 3;          // Default: 3
let PETAL_COUNT_MAX = 8;          // Default: 8
let INNER_SCALE_MIN = 0.3;        // Default: 0.3
let INNER_SCALE_MAX = 0.7;        // Default: 0.7
let STROKE_WEIGHT_MIN = 1.0;      // Default: 1.0
let STROKE_WEIGHT_MAX = 2.5;      // Default: 2.5

// Relative Shape Geometry
let GLYPH_OUTER_OFFSET_FACTOR = 0.4; // Default: 0.4
let GLYPH_OUTER_W_FACTOR = 0.3;      // Default: 0.3
let GLYPH_OUTER_H_FACTOR = 0.1;      // Default: 0.1

// Visuals
let INVERT_BACKGROUND = false;    // Default: false
let PALETTE_INDEX = 1;            // 0 to 4

// Palettes from Adobe Color (Kuler)
// Palette 0: "Retro Beach" - Deep Teal, Mint, Pale Cream, Coral, Sunny Yellow
// Palette 1: "Sandy Stone" - Deep Marine, Sea Green, Sandy Ochre, Coral Orange, Burnt Terracotta
// Palette 2: "Warm Ember"  - Indigo Navy, Crimson Red, Tangerine, Golden Amber, Cream White
// Palette 3: "Moss Forest" - Olive Leaf, Deep Moss, Vanilla Soft, Golden Ochre, Warm Bark
// Palette 4: "Muted Mauve" - Midnight Plum, Dusky Slate, Rose Heather, Desert Dust, Pale Linen
const PALETTES = [
  ['#1A535C', '#4ECDC4', '#F7FFF7', '#FF6B6B', '#FFE66D'],
  ['#264653', '#2A9D8F', '#E9C46A', '#F4A261', '#E76F51'],
  ['#003049', '#D62828', '#F77F00', '#FCBF49', '#EAE2B7'],
  ['#606C38', '#283618', '#FEFAE0', '#DDA15E', '#BC6C25'],
  ['#22223B', '#4A4E69', '#9A8C98', '#C9ADA7', '#F2E9E1']
];

let glyphs = [];
let morphFactor = 0;

function setup() {
  createCanvas(SKETCH_WIDTH, SKETCH_HEIGHT);
  randomSeed(GLOBAL_SEED);
  frameRate(ANIMATION_SPEED);
  rectMode(CENTER);

  let totalShapes = GRID_ROWS * GRID_COLS;
  glyphs = [];

  let drawAreaW = width - (PADDING * 2);
  let drawAreaH = height - (PADDING * 2);
  let maxRadius = min(drawAreaW, drawAreaH) / 2.0;

  for (let r = 0; r < GRID_ROWS; r++) {
    for (let c = 0; c < GRID_COLS; c++) {
      // Cartesian Base
      let cx = PADDING + (c * (drawAreaW / (GRID_COLS - 1)));
      let cy = PADDING + (r * (drawAreaH / (GRID_ROWS - 1)));

      // Polar Target
      let angle = map(c, 0, GRID_COLS, 0, TWO_PI);
      let radius = map(r, 0, GRID_ROWS, POLAR_MIN_RADIUS, maxRadius);

      let px = (width / 2.0) + cos(angle) * radius;
      let py = (height / 2.0) + sin(angle) * radius;

      let colIndex = floor(random(1, 5));
      let baseCol = PALETTES[PALETTE_INDEX][colIndex];
      glyphs.push(new ComplexGlyph(cx, cy, px, py, angle, baseCol));
    }
  }
}

function draw() {
  let bgHex = PALETTES[PALETTE_INDEX][0];
  let fillBG = color(bgHex);
  if (INVERT_BACKGROUND) {
    fillBG = color(255 - red(fillBG), 255 - green(fillBG), 255 - blue(fillBG));
  }
  background(fillBG);

  morphFactor = (sin(frameCount * MORPH_SPEED) + 1.0) / 2.0;

  for (let g of glyphs) {
    g.display(morphFactor);
  }

  if (SAVE_FRAMES) {
    if (frameCount >= MAX_FRAMES) noLoop();
  }
}

class ComplexGlyph {
  constructor(cx, cy, px, py, ang, col) {
    this.cartX = cx;
    this.cartY = cy;
    this.polarX = px;
    this.polarY = py;
    this.targetAngle = ang;
    this.baseCol = col;

    // Randomize procedural traits
    this.rotationSpeed = random(ROTATION_SPEED_MIN, ROTATION_SPEED_MAX);
    this.petalCount = floor(random(PETAL_COUNT_MIN, PETAL_COUNT_MAX));
    this.innerScale = random(INNER_SCALE_MIN, INNER_SCALE_MAX);
    this.hasInnerCircle = random(1) > 0.5;
    this.strokeW = random(STROKE_WEIGHT_MIN, STROKE_WEIGHT_MAX);
  }

  display(m) {
    let x = lerp(this.cartX, this.polarX, m);
    let y = lerp(this.cartY, this.polarY, m);

    // Angular gradient blending
    let colA = color(PALETTES[PALETTE_INDEX][1]);
    let colB = color(PALETTES[PALETTE_INDEX][2]);
    let colC = color(PALETTES[PALETTE_INDEX][3]);
    let colorWeight = map(this.targetAngle, 0, TWO_PI, 0, 1);
    let gradientCol = (colorWeight < 0.5)
      ? lerpColor(colA, colB, colorWeight * 2)
      : lerpColor(colB, colC, (colorWeight - 0.5) * 2);

    let finalCol = lerpColor(color(this.baseCol), gradientCol, m);

    push();
    translate(x, y);
    rotate(lerp(0, this.targetAngle, m) + (frameCount * this.rotationSpeed));

    noFill();
    stroke(finalCol);
    strokeWeight(this.strokeW);

    // Draw Generated Glyph
    for (let i = 0; i < this.petalCount; i++) {
      push();
      rotate((TWO_PI * i) / this.petalCount);
      // Outer component
      rect(
        SHAPE_SIZE * GLYPH_OUTER_OFFSET_FACTOR,
        0,
        SHAPE_SIZE * GLYPH_OUTER_W_FACTOR,
        SHAPE_SIZE * GLYPH_OUTER_H_FACTOR
      );
      // Connection line
      line(0, 0, SHAPE_SIZE * GLYPH_OUTER_OFFSET_FACTOR, 0);
      pop();
    }

    if (this.hasInnerCircle) {
      ellipse(0, 0, SHAPE_SIZE * this.innerScale, SHAPE_SIZE * this.innerScale);
    } else {
      rect(0, 0, SHAPE_SIZE * this.innerScale, SHAPE_SIZE * this.innerScale);
    }

    pop();
  }
}
