/**
 * Vector Field Cellular Automata - Pattern Emergence Edition
 * Uses a blend of neighbor alignment and Perlin noise to generate
 * flowing, fluid-like structures.
 *
 * Version: 2026.09.29.23.27.00
 */

// --- Parameters ---
let SKETCH_WIDTH = 480;          // default: 480
let SKETCH_HEIGHT = 800;         // default: 800
let PADDING = 20;                // default: 40
let SEED = 6789;                 // default: 12345
let MAX_FRAMES = 900;            // default: 900
let SAVE_FRAMES = false;         // default: false
let ANIMATION_SPEED = 60;        // default: 30 (increased for smoother flow)

// Grid Configuration
let COLS = 40;                   // Number of columns (higher for detail, default: 40)
let ROWS = 70;                   // Number of rows (default: 70)
let NEIGHBOR_INFLUENCE = 0.12;   // 0.0 to 1.0 (default: 0.12)
let CURVATURE = 0.01;            // Rotational force over time (default: 0.01)
let NOISE_SCALE = 0.08;          // Scale of the underlying Perlin field (default: 0.08)
let SHOW_GRID = false;           // default: false

// Visuals
let VECTOR_LENGTH_MULT = 1.2;    // Overlapping vectors create texture (default: 1.2)
let STROKE_WEIGHT = 1.5;         // default: 1.5
let INVERT_BACKGROUND = false;   // default: false

// 5 Color Palettes (Adobe Kuler)
const PALETTES = [
  ["#023047", "#219EBC", "#8ECAE6", "#FFB703", "#FB8500"], // 0: Deep Sea
  ["#264653", "#2A9D8F", "#E9C46A", "#F4A261", "#E76F51"], // 1: Terra Cotta
  ["#1A1A1A", "#4E4E4E", "#FFFFFF", "#8A8A8A", "#CCCCCC"], // 2: Monochromatic
  ["#5F0F40", "#9A031E", "#FB8B24", "#E36414", "#0F4C5C"], // 3: Sunset Fire
  ["#22223B", "#4A4E69", "#9A8C98", "#C9ADA7", "#F2E9E4"]  // 4: Muted Lavender
];
let ACTIVE_PALETTE = 2;          // Range: 0 - 4 (default: 2)

// --- Internal Variables ---
let grid = [];
let bg_color;
let current_colors = [];
let cellW, cellH;

function setup() {
  createCanvas(SKETCH_WIDTH, SKETCH_HEIGHT);
  randomSeed(SEED);
  noiseSeed(SEED);
  frameRate(ANIMATION_SPEED);

  // Initialize current colors from palette
  current_colors = PALETTES[ACTIVE_PALETTE].map(c => color(c));

  if (INVERT_BACKGROUND) {
    bg_color = color(255);
    current_colors[0] = color(20); // Force dark ink for contrast
  } else {
    bg_color = current_colors[0];
  }

  let availableW = width - (2 * PADDING);
  let availableH = height - (2 * PADDING);
  cellW = availableW / COLS;
  cellH = availableH / ROWS;

  grid = [];
  for (let i = 0; i < COLS; i++) {
    grid[i] = [];
    for (let j = 0; j < ROWS; j++) {
      grid[i][j] = new Cell(i, j);
    }
  }
}

function draw() {
  background(bg_color);
  push();
  translate(PADDING, PADDING);

  // 1. Update states
  for (let i = 0; i < COLS; i++) {
    for (let j = 0; j < ROWS; j++) {
      grid[i][j].calculateNextState();
    }
  }

  // 2. Apply and Render
  for (let i = 0; i < COLS; i++) {
    for (let j = 0; j < ROWS; j++) {
      grid[i][j].apply();
      grid[i][j].display();
    }
  }
  pop();

  if (SAVE_FRAMES) {
    saveCanvas(`frame_${String(frameCount).padStart(4, "0")}`, "png");
    if (frameCount >= MAX_FRAMES) noLoop();
  }
}

// --- Cell Class ---
class Cell {
  constructor(x, y) {
    this.xIdx = x;
    this.yIdx = y;
    // Base angle influenced by position to create initial structure
    this.angle = noise(x * NOISE_SCALE, y * NOISE_SCALE) * TWO_PI;
    this.nextAngle = this.angle;
    this.noiseOffset = random(1000);
  }

  calculateNextState() {
    let sumSin = 0;
    let sumCos = 0;
    let count = 0;

    // Neighbor wrap-around logic
    for (let i = -1; i <= 1; i++) {
      for (let j = -1; j <= 1; j++) {
        if (i === 0 && j === 0) continue;
        let ni = (this.xIdx + i + COLS) % COLS;
        let nj = (this.yIdx + j + ROWS) % ROWS;

        sumSin += sin(grid[ni][nj].angle);
        sumCos += cos(grid[ni][nj].angle);
        count++;
      }
    }

    let avgAngle = atan2(sumSin / count, sumCos / count);

    // Pattern Emergence: Mix neighbor alignment with local curl
    this.nextAngle = this.lerpAngle(this.angle, avgAngle, NEIGHBOR_INFLUENCE);
    this.nextAngle += CURVATURE; // Constant "spin"

    // Add micro-turbulence using Perlin noise
    let n = noise(this.xIdx * NOISE_SCALE, this.yIdx * NOISE_SCALE, frameCount * 0.01);
    this.nextAngle += map(n, 0, 1, -0.05, 0.05);
  }

  apply() {
    this.angle = this.nextAngle;
  }

  display() {
    let px = this.xIdx * cellW + cellW / 2;
    let py = this.yIdx * cellH + cellH / 2;

    if (SHOW_GRID) {
      let gridCol = color(red(current_colors[1]), green(current_colors[1]), blue(current_colors[1]), 30);
      stroke(gridCol);
      noFill();
      rect(this.xIdx * cellW, this.yIdx * cellH, cellW, cellH);
    }

    push();
    translate(px, py);
    rotate(this.angle);

    // Map angle to color index (excluding background color at index 0)
    let colorSelect = map(sin(this.angle + frameCount * 0.02), -1, 1, 1, current_colors.length - 1);
    let c1 = floor(colorSelect);
    let c2 = ceil(colorSelect) % current_colors.length;
    if (c2 === 0) c2 = 1;

    let mixedC = lerpColor(current_colors[c1], current_colors[c2], colorSelect - c1);
    let finalC = color(red(mixedC), green(mixedC), blue(mixedC), 180);

    stroke(finalC);
    strokeWeight(STROKE_WEIGHT);

    let len = (cellW < cellH ? cellW : cellH) * VECTOR_LENGTH_MULT;
    // Draw vectors with a slight curve or offset for "water" feel
    line(-len / 2, 0, len / 2, 0);

    // Visual tip
    strokeWeight(STROKE_WEIGHT * 1.5);
    point(len / 2, 0);

    pop();
  }

  lerpAngle(a, b, t) {
    let diff = b - a;
    while (diff < -PI) diff += TWO_PI;
    while (diff > PI) diff -= TWO_PI;
    return a + diff * t;
  }
}
