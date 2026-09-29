/**
 * Wobbly Grid-Hollow Box & Precision Axis Travelers
 * Version: 2026.09.29.23.36.00
 */

// --- Parameters ---
let SKETCH_WIDTH = 480;       // Default: 480
let SKETCH_HEIGHT = 800;      // Default: 800
let MAX_FRAMES = 900;         // Default: 900
let SAVE_FRAMES = false;      // Default: false
let ANIMATION_SPEED = 30;     // Default: 30
let GLOBAL_SEED = 1234;       // Default: 1234
let PADDING = 40;             // Default: 40

// Colors & Palettes (Adobe Kuler)
const PALETTES = [
  ["#264653", "#2a9d8f", "#e9c46a", "#f4a261", "#e76f51"], // 0: Deep Sea / Tropical Clay
  ["#001219", "#005f73", "#0a9396", "#94d2bd", "#e9d8a6"], // 1: Ocean Depth
  ["#1d3557", "#457b9d", "#a8dadc", "#f1faee", "#e63946"], // 2: Coral Navy
  ["#2b2d42", "#8d99ae", "#edf2f4", "#ef233c", "#d90429"], // 3: Crimson Slate
  ["#011627", "#fdfffc", "#2ec4b6", "#e71d36", "#ff9f1c"]  // 4: Neon Noir
];
let PALETTE_INDEX = 0;        // Default: 4
let BG_COLOR_INDEX = 0;       // Default: 0
let INVERT_BG = false;        // Default: false

// Geometry & Animation Parameters
let MAIN_BOX_SIZE = 300;    // Default: 240
let HOLE_SIZE = 40;         // Default: 40
let SMALL_BOX_SIZE = 40;    // Default: 40 (Fits perfectly in holes)
let WOBBLE_STRENGTH = 0.4;  // Default: 0.2
let TRAVELER_COUNT = 500;   // Default: 30 (Doubled per request)
let TRAVELER_SPEED = 6.0;   // Default: 6.0
let SHOW_GRID = false;      // Default: false (Grid lines removed)

// Global Variables
let rotationY = 0;
let travelers = [];

function setup() {
  createCanvas(SKETCH_WIDTH, SKETCH_HEIGHT, WEBGL);
  randomSeed(GLOBAL_SEED);
  frameRate(ANIMATION_SPEED);

  travelers = [];
  for (let i = 0; i < TRAVELER_COUNT; i++) {
    travelers.push(new Traveler());
  }
}

function draw() {
  // Handle Background
  let activeBg = color(PALETTES[PALETTE_INDEX][BG_COLOR_INDEX]);
  if (INVERT_BG) {
    activeBg = color(255 - red(activeBg), 255 - green(activeBg), 255 - blue(activeBg));
  }
  background(activeBg);

  translate(0, 0, -100);

  // Lighting
  ambientLight(120, 120, 120);
  pointLight(255, 255, 255, 400, -400, 500);

  // Rotation and Wobble
  rotationY += 0.015;
  let wobbleX = sin(frameCount * 0.04) * WOBBLE_STRENGTH;
  let wobbleZ = cos(frameCount * 0.02) * WOBBLE_STRENGTH;

  push();
  rotateY(rotationY);
  rotateX(wobbleX);
  rotateZ(wobbleZ);

  // Draw Box
  drawGridHollowBox(MAIN_BOX_SIZE, HOLE_SIZE);

  // Update and Draw Travelers
  for (let t of travelers) {
    t.update();
    t.display();
  }
  pop();

  // Save/Stop Logic
  if (SAVE_FRAMES) {
    saveCanvas(`frames_${nf(frameCount, 4)}`, "png");
    if (frameCount >= MAX_FRAMES) noLoop();
  }
}

function drawGridHollowBox(sz, holeSz) {
  fill(PALETTES[PALETTE_INDEX][1]);
  // Use noStroke for the box faces as requested (removing grid lines)
  noStroke();

  let half = sz / 2;
  for (let i = 0; i < 6; i++) {
    push();
    if (i === 1) rotateY(HALF_PI);
    if (i === 2) rotateY(PI);
    if (i === 3) rotateY(-HALF_PI);
    if (i === 4) rotateX(HALF_PI);
    if (i === 5) rotateX(-HALF_PI);
    translate(0, 0, half);
    drawFaceWith9Holes(sz, holeSz);
    pop();
  }
}

function drawFaceWith9Holes(sz, holeSz) {
  let h = sz / 2;
  let step = sz / 3;

  for (let x = 0; x < 3; x++) {
    for (let y = 0; y < 3; y++) {
      let cx = -h + x * step + step / 2;
      let cy = -h + y * step + step / 2;

      let innerH = step / 2;
      let hh = holeSz / 2;

      beginShape(QUADS);
      // Constructing geometry around holes without internal divider strokes
      vertex(cx - innerH, cy - innerH, 0); vertex(cx + innerH, cy - innerH, 0);
      vertex(cx + innerH, cy - hh, 0);     vertex(cx - innerH, cy - hh, 0);

      vertex(cx - innerH, cy + hh, 0);     vertex(cx + innerH, cy + hh, 0);
      vertex(cx + innerH, cy + innerH, 0); vertex(cx - innerH, cy + innerH, 0);

      vertex(cx - innerH, cy - hh, 0);     vertex(cx - hh, cy - hh, 0);
      vertex(cx - hh, cy + hh, 0);         vertex(cx - innerH, cy + hh, 0);

      vertex(cx + hh, cy - hh, 0);         vertex(cx + innerH, cy - hh, 0);
      vertex(cx + innerH, cy + hh, 0);     vertex(cx + hh, cy + hh, 0);
      endShape();
    }
  }
}

class Traveler {
  constructor() {
    this.pos = createVector(0, 0, 0);
    this.axis = 0;
    this.currentSpeed = 0;
    this.col = "#ffffff";
    this.boundary = 1200;
    this.init(true);
  }

  init(firstStart) {
    this.axis = int(random(3));
    this.currentSpeed = (random(1) > 0.5 ? 1 : -1) * TRAVELER_SPEED;
    this.col = PALETTES[PALETTE_INDEX][int(random(2, 5))];

    let step = MAIN_BOX_SIZE / 3;
    let h = MAIN_BOX_SIZE / 2;
    let grid = [-h + step / 2, 0, h - step / 2];

    // Lock to hole centers
    let gx = grid[int(random(3))];
    let gy = grid[int(random(3))];
    let gz = grid[int(random(3))];

    if (this.axis === 0) this.pos = createVector(this.currentSpeed > 0 ? -this.boundary : this.boundary, gy, gz);
    else if (this.axis === 1) this.pos = createVector(gx, this.currentSpeed > 0 ? -this.boundary : this.boundary, gz);
    else this.pos = createVector(gx, gy, this.currentSpeed > 0 ? -this.boundary : this.boundary);

    if (firstStart) {
      let startOffset = random(-this.boundary, this.boundary);
      if (this.axis === 0) this.pos.x = startOffset;
      else if (this.axis === 1) this.pos.y = startOffset;
      else this.pos.z = startOffset;
    }
  }

  update() {
    if (this.axis === 0) this.pos.x += this.currentSpeed;
    else if (this.axis === 1) this.pos.y += this.currentSpeed;
    else this.pos.z += this.currentSpeed;

    if (abs(this.pos.x) > this.boundary || abs(this.pos.y) > this.boundary || abs(this.pos.z) > this.boundary) {
      this.init(false);
    }
  }

  display() {
    push();
    translate(this.pos.x, this.pos.y, this.pos.z);
    fill(this.col);
    noStroke();
    box(SMALL_BOX_SIZE);
    pop();
  }
}
