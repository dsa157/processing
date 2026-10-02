/**
 * Genuary 2026 - Day 23: Explore the concept of transparency
 * Smoked Glass Flow
 * Version: 2026.10.02.17.28.30
 * Fast-moving ribbons that decay over time within a persistent buffer.
 * Overlaid with a slow-pulsing, large-format transparency grid.
 */

// --- Parameters ---
let SKETCH_WIDTH = 800;       // Default: 800 (Original PDE: 480)
let SKETCH_HEIGHT = 800;      // Default: 800
let PADDING = 40;             // Default: 40
let MAX_FRAMES = 900;         // Default: 900
let SAVE_FRAMES = false;      // Default: false
let ANIMATION_SPEED = 60;     // Default: 60 fps
let GLOBAL_SEED = 42;         // Default: 42
let SHOW_GRID = true;         // Default: true 
let INVERT_COLORS = false;    // Default: false
let INVERT_BG_COLOR = 245;    // Default: 245
let INVERT_GRID_COLOR = 30;   // Default: 30
let COLOR_MAX = 255;          // Default: 255

// Flow Parameters
let PARTICLE_COUNT = 1000;    // Default: 1000 (Original User Param: 500)
let NOISE_SCALE = 0.01;       // Default: 0.01 (Original Default: 0.008)
let NOISE_EVOLUTION = 0.01;   // Default: 0.01
let NOISE_ANGLE_MULTIPLIER = 3; // Default: 3
let RIBBON_SPEED = 5.5;       // Default: 5.5
let RIBBON_ALPHA = 40;        // Default: 40 (Higher because of decay)
let STROKE_WEIGHT = 2.0;      // Default: 2.0
let DECAY_RATE = 12;          // Default: 12 (Speed of trail vanishing 0-255)

// Grid Overlay Parameters
let GRID_COLS = 4;            // Default: 4
let GRID_ROWS = 7;            // Default: 7
let ALPHA_MIN = 5;            // Default: 5
let ALPHA_MAX = 200;          // Default: 200
let PULSE_SPEED = 0.01;       // Default: 0.01
let GRID_CELL_INSET = 2;      // Default: 2

// Color Palettes (Adobe Color / Kuler inspired)
let PALETTE_INDEX = 0;        // Default: 0
let BG_PALETTE_COLOR_INDEX = 0; // Default: 0
let PALETTES = [
  ['#1A1A1A', '#333333', '#4D4D4D', '#666666', '#808080'], // 0: Smoked Grays
  ['#0D1B2A', '#1B263B', '#415A77', '#778DA9', '#E0E1DD'], // 1: Deep Blues
  ['#2B2D42', '#8D99AE', '#EDF2F4', '#EF233C', '#D90429'], // 2: Cool Slate
  ['#121212', '#242424', '#363636', '#484848', '#5A5A5A'], // 3: Obsidian
  ['#220901', '#621708', '#941B0C', '#BC3908', '#F6AA1C']  // 4: Ember Dark
];

let particles = [];
let ribbonLayer;
let bgColor;
let gridColor;
let gridOffsets = [];

function setup() {
  createCanvas(SKETCH_WIDTH, SKETCH_HEIGHT);
  frameRate(ANIMATION_SPEED);
  randomSeed(GLOBAL_SEED);
  noiseSeed(GLOBAL_SEED);

  let activePalette = PALETTES[PALETTE_INDEX];
  bgColor = INVERT_COLORS ? color(INVERT_BG_COLOR) : color(activePalette[BG_PALETTE_COLOR_INDEX]);
  gridColor = INVERT_COLORS ? color(INVERT_GRID_COLOR) : color(activePalette[activePalette.length - 1]);

  ribbonLayer = createGraphics(width, height);
  ribbonLayer.pixelDensity(1);
  ribbonLayer.background(bgColor);

  particles = [];
  for (let i = 0; i < PARTICLE_COUNT; i++) {
    particles.push(new Particle());
  }

  gridOffsets = [];
  for (let i = 0; i < GRID_COLS; i++) {
    gridOffsets[i] = [];
    for (let j = 0; j < GRID_ROWS; j++) {
      gridOffsets[i][j] = random(TWO_PI);
    }
  }
}

function draw() {
  // Update particles and draw to buffer
  ribbonLayer.noStroke();
  let bg = color(bgColor);
  ribbonLayer.fill(red(bg), green(bg), blue(bg), DECAY_RATE);
  ribbonLayer.rect(0, 0, width, height);

  for (let p of particles) {
    p.update();
    p.display(ribbonLayer);
  }

  // Clear main canvas and show the decayed ribbon layer
  background(bgColor);
  image(ribbonLayer, 0, 0);

  if (SHOW_GRID) {
    drawAsynchronousGrid();
  }

  if (SAVE_FRAMES) {
    saveCanvas(`frame_${nf(frameCount, 4)}`, 'png');
    if (frameCount >= MAX_FRAMES) {
      noLoop();
    }
  }
}

function drawAsynchronousGrid() {
  let gridW = (width - 2 * PADDING) / GRID_COLS;
  let gridH = (height - 2 * PADDING) / GRID_ROWS;

  noStroke();
  let gc = color(gridColor);
  for (let i = 0; i < GRID_COLS; i++) {
    for (let j = 0; j < GRID_ROWS; j++) {
      let x = PADDING + i * gridW;
      let y = PADDING + j * gridH;

      let phase = frameCount * PULSE_SPEED + gridOffsets[i][j];
      let currentAlpha = map(sin(phase), -1, 1, ALPHA_MIN, ALPHA_MAX);

      fill(red(gc), green(gc), blue(gc), currentAlpha);
      rect(x + GRID_CELL_INSET, y + GRID_CELL_INSET, gridW - (GRID_CELL_INSET * 2), gridH - (GRID_CELL_INSET * 2));
    }
  }
}

class Particle {
  constructor() {
    this.pos = null;
    this.prevPos = null;
    this.vel = null;
    this.ribbonColor = null;
    this.init();
  }

  init() {
    this.pos = createVector(
      random(PADDING, width - PADDING),
      random(PADDING, height - PADDING)
    );
    this.prevPos = this.pos.copy();
    this.vel = createVector(0, 0);

    let activePalette = PALETTES[PALETTE_INDEX];
    let colIdx = floor(random(1, activePalette.length));
    let baseColor = color(activePalette[colIdx]);

    if (INVERT_COLORS) {
      this.ribbonColor = color(
        COLOR_MAX - red(baseColor),
        COLOR_MAX - green(baseColor),
        COLOR_MAX - blue(baseColor)
      );
    } else {
      this.ribbonColor = baseColor;
    }
  }

  update() {
    let angle = noise(this.pos.x * NOISE_SCALE, this.pos.y * NOISE_SCALE, frameCount * NOISE_EVOLUTION) * TWO_PI * NOISE_ANGLE_MULTIPLIER;
    this.vel.x = cos(angle);
    this.vel.y = sin(angle);
    this.vel.mult(RIBBON_SPEED);

    this.prevPos.set(this.pos.x, this.pos.y);
    this.pos.add(this.vel);

    if (this.pos.x < PADDING || this.pos.x > width - PADDING ||
      this.pos.y < PADDING || this.pos.y > height - PADDING) {
      this.init();
    }
  }

  display(pg) {
    pg.strokeWeight(STROKE_WEIGHT);
    let c = color(this.ribbonColor);
    pg.stroke(red(c), green(c), blue(c), RIBBON_ALPHA);
    pg.line(this.prevPos.x, this.prevPos.y, this.pos.x, this.pos.y);
  }
}
