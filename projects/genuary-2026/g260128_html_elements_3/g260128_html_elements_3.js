/**
 * Header Constellations
 * Focus on Line and Unity using Proximity Triangulation.
 * Parametric control over typography and network density.
 *
 * Version: 2026.10.01.15.24.00
 */

// --- Parameters ---
let SKETCH_WIDTH = 800;       // Default 480
let SKETCH_HEIGHT = 800;      // Default 800
let PADDING = 40;             // Default 40
let MAX_FRAMES = 900;         // Default 900
let SAVE_FRAMES = false;      // Default false
let ANIMATION_SPEED = 30;     // Default 30
let SEED_VAL = 42;            // Global Seed
let INVERT_BG = false;        // Toggle background inversion
let SHOW_GRID = false;        // Toggle grid visibility

// Typography
let FONT_FACE = "SansSerif";  // Default "SansSerif"
let FONT_SIZE = 18;           // Default 10
let TEXT_ALPHA = 200;         // Default 200

// Tag Configuration
let TAG_COUNT = 100;          // Default 50
let MAX_VELOCITY = 1.8;       // Default 0.8
let MIN_VELOCITY = 1.2;       // Default 0.2
let PROXIMITY_LIMIT = 200.0;  // Default 85.0
let STROKE_WEIGHT = 1.75;     // Default 0.75
let LINE_MAX_ALPHA = 180;     // Default 180
let CORE_DOT_SIZE = 2;        // Default 2
let GRID_STEP = 40;           // Default 40
let GRID_ALPHA = 50;          // Default 50

// Palette Index (0-4)
let PALETTE_INDEX = 1;        // Default 1

// HTML Tag Pool
let TAG_POOL = [
  "<blockquote>", "<textarea>", "<select>", "<option>", "<div>",
  "<span>", "<code>", "<img>", "<section>", "<footer>", "<header>", "<nav>"
];

// --- Color Palettes (Adobe Color / Kuler) ---
let PALETTES = [
  ["#2E112D", "#540032", "#820333", "#C02739", "#F1D4D4"], // Crimson Velvet
  ["#004445", "#2C7873", "#6FB98F", "#FAF1E6", "#FFD800"], // Deep Sea & Gold
  ["#1A1A2E", "#16213E", "#0F3460", "#E94560", "#FFFFFF"], // Cyberpunk Night
  ["#222831", "#393E46", "#00ADB5", "#EEEEEE", "#FF5722"], // Modern Dark
  ["#F9F7F7", "#DBE2EF", "#3F72AF", "#112D4E", "#333333"]  // Business Blue
];

let nodes = [];

function setup() {
  createCanvas(SKETCH_WIDTH, SKETCH_HEIGHT);
  randomSeed(SEED_VAL);
  frameRate(ANIMATION_SPEED);

  textFont(FONT_FACE);
  textSize(FONT_SIZE);

  nodes = [];
  for (let i = 0; i < TAG_COUNT; i++) {
    let x = random(PADDING, width - PADDING);
    let y = random(PADDING, height - PADDING);
    let label = TAG_POOL[floor(random(TAG_POOL.length))];
    nodes.push(new TagNode(x, y, label));
  }
}

function draw() {
  let activePalette = PALETTES[PALETTE_INDEX];
  let bgHex = activePalette[0];
  let strokeHex = activePalette[2];
  let textHex = activePalette[4];

  if (INVERT_BG) {
    bgHex = activePalette[4];
    textHex = activePalette[0];
  }

  background(bgHex);

  if (SHOW_GRID) {
    drawDebugGrid(activePalette[1]);
  }

  let strokeCol = color(strokeHex);
  let sR = red(strokeCol);
  let sG = green(strokeCol);
  let sB = blue(strokeCol);

  // Draw Unity Lines (Proximity Triangulation)
  strokeWeight(STROKE_WEIGHT);
  for (let i = 0; i < nodes.length; i++) {
    let a = nodes[i];
    for (let j = i + 1; j < nodes.length; j++) {
      let b = nodes[j];
      let d = dist(a.pos.x, a.pos.y, b.pos.x, b.pos.y);

      if (d < PROXIMITY_LIMIT) {
        let alpha1 = map(d, 0, PROXIMITY_LIMIT, LINE_MAX_ALPHA, 0);
        stroke(sR, sG, sB, alpha1);
        line(a.pos.x, a.pos.y, b.pos.x, b.pos.y);
      }
    }
  }

  // Update and Draw Tag Nodes
  let textCol = color(textHex);
  for (let i = 0; i < nodes.length; i++) {
    let n = nodes[i];
    n.update();
    n.display(textCol);
  }

  // Recording and Loop Control
  if (SAVE_FRAMES) {
    saveCanvas(`frame_${nf(frameCount, 4)}`, "png");
    if (frameCount >= MAX_FRAMES) {
      noLoop();
    }
  }
}

function drawDebugGrid(gridColHex) {
  let c = color(gridColHex);
  stroke(red(c), green(c), blue(c), GRID_ALPHA);
  for (let x = PADDING; x <= width - PADDING; x += GRID_STEP) {
    line(x, PADDING, x, height - PADDING);
  }
  for (let y = PADDING; y <= height - PADDING; y += GRID_STEP) {
    line(PADDING, y, width - PADDING, y);
  }
}

class TagNode {
  constructor(x, y, label) {
    this.pos = createVector(x, y);
    this.vel = p5.Vector.random2D().mult(random(MIN_VELOCITY, MAX_VELOCITY));
    this.tagLabel = label;
  }

  update() {
    this.pos.add(this.vel);

    // Bounce boundaries with padding
    if (this.pos.x < PADDING || this.pos.x > width - PADDING) this.vel.x *= -1;
    if (this.pos.y < PADDING || this.pos.y > height - PADDING) this.vel.y *= -1;

    this.pos.x = constrain(this.pos.x, PADDING, width - PADDING);
    this.pos.y = constrain(this.pos.y, PADDING, height - PADDING);
  }

  display(textColorObj) {
    let r = red(textColorObj);
    let g = green(textColorObj);
    let b = blue(textColorObj);

    fill(r, g, b, TEXT_ALPHA);
    textAlign(CENTER, CENTER);
    text(this.tagLabel, this.pos.x, this.pos.y);

    noStroke();
    fill(r, g, b, LINE_MAX_ALPHA / 2);
    ellipse(this.pos.x, this.pos.y, CORE_DOT_SIZE, CORE_DOT_SIZE);
  }
}
