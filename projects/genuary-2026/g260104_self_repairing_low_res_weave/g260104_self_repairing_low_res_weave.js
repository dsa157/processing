/**
 * The Digital Loom: Chromatic Impressions
 * Weaving simulation where deforming circular blobs apply palette-based colors 
 * and physical displacement to the textile grid.
 *
 * Version: 2026.09.30.12.39.23
 */

// --- Configuration Parameters ---
let SKETCH_WIDTH = 800;       // Canvas width: 480
let SKETCH_HEIGHT = 800;      // Canvas height: 800
let SEED = 42;                // Global random/noise seed: 42
let PADDING = 40;             // Canvas padding: 40
let MAX_FRAMES = 900;         // Animation limit: 900
let SAVE_FRAMES = false;      // Save frames to disk: false
let ANIMATION_SPEED = 30;     // Frame rate: 30

let NOISE_SCALE = 0.05;       // Weave complexity: 0.05
let GRID_RES = 10;            // Space between threads: 10
let THREAD_WEIGHT = 8.0;      // Line thickness: 8.0
let SHOW_GRID = false;        // Hide debug grid: false
let INVERT_BG = false;        // Background inversion: false

// Interaction Parameters
let CIRCLE_CHANCE = 10;       // 1 in 10 chance to spawn blob: 10
let DECAY_RATE = 5.5;         // Decay speed: 5.5
let ELASTICITY = 25.0;        // Max displacement: 25.0
let EFFECT_RADIUS = 100.0;    // Area of effect: 100.0
let TIME_STEP = 0.02;         // Noise time increment: 0.02
let BASE_H_COLOR_INDEX = 2;   // Base horizontal thread palette index: 2
let BASE_V_COLOR_INDEX = 3;   // Base vertical thread palette index: 3
let BLOB_MIN_DIAMETER = 60;   // Minimum blob diameter: 60
let BLOB_MAX_DIAMETER = 120;  // Maximum blob diameter: 120
let BLOB_INITIAL_OPACITY = 200; // Blob initial opacity: 200
let BLOB_FILL_ALPHA_MULT = 0.2; // Blob fill alpha multiplier: 0.2

// Color Palettes (Adobe Color / Kuler)
let PALETTES = [
  // Palette 0: Retro Metro (Original)
  ["#264653", "#2a9d8f", "#e9c46a", "#f4a261", "#e76f51"],
  // Palette 1: Nordic Twilight
  ["#1b263b", "#415a77", "#778da9", "#e0e1dd", "#3a86ff"],
  // Palette 2: Campfire Glow
  ["#2b0938", "#900c3f", "#c70039", "#ff5733", "#ffc300"],
  // Palette 3: Botanical Moss
  ["#132a13", "#31572c", "#4f772d", "#90a955", "#ecf39e"],
  // Palette 4: Vintage Silk
  ["#2d3142", "#4f5d75", "#bfc0c0", "#ef8354", "#ffffff"]
];

let ACTIVE_PALETTE_INDEX = 0; // Active palette selector: 0
let BG_COLOR_INDEX = 0;       // Background color index within palette: 0

let circles = [];

function setup() {
  createCanvas(SKETCH_WIDTH, SKETCH_HEIGHT);
  randomSeed(SEED);
  noiseSeed(SEED);
  frameRate(ANIMATION_SPEED);
  circles = [];
}

function draw() {
  background(getBgColor());

  let innerW = width - (PADDING * 2);
  let innerH = height - (PADDING * 2);
  
  // Update Impressions
  if (random(CIRCLE_CHANCE) < 1) {
    let pal = PALETTES[ACTIVE_PALETTE_INDEX % PALETTES.length];
    let randomColorIdx = floor(random(1, pal.length));
    circles.push(new Impression(random(PADDING, width - PADDING), random(PADDING, height - PADDING), randomColorIdx));
  }
  
  for (let i = circles.length - 1; i >= 0; i--) {
    let c = circles[i];
    c.update();
    if (c.isDead()) {
      circles.splice(i, 1);
    }
  }
  
  // Render Weave centered
  push();
  let offsetX = (width - innerW) / 2;
  let offsetY = (height - innerH) / 2;
  translate(offsetX, offsetY);
  renderLoom(innerW, innerH);
  if (SHOW_GRID) drawDebugGrid(innerW, innerH);
  pop();

  // Render Blobs (Optional: set to very low alpha or hide to see only thread tinting)
  for (let c of circles) {
    c.display();
  }

  // Lifecycle Management
  if (SAVE_FRAMES) {
    saveCanvas(`frame_${nf(frameCount, 4)}`, 'png');
    if (frameCount >= MAX_FRAMES) noLoop();
  }
}

function renderLoom(w, h) {
  strokeWeight(THREAD_WEIGHT);
  strokeCap(PROJECT);
  let t = frameCount * TIME_STEP;

  for (let x = 0; x < w; x += GRID_RES) {
    for (let y = 0; y < h; y += GRID_RES) {
      
      let dispX = 0;
      let dispY = 0;
      
      // Determine base thread colors
      let baseH = getPaletteColor(BASE_H_COLOR_INDEX);
      let baseV = getPaletteColor(BASE_V_COLOR_INDEX);
      
      let targetH = baseH;
      let targetV = baseV;

      // Interaction Logic: Displacement and Color Blending
      for (let c of circles) {
        let d = dist(x + PADDING, y + PADDING, c.x, c.y);
        if (d < EFFECT_RADIUS) {
          let pct = map(d, 0, EFFECT_RADIUS, 1.0, 0);
          let alphaFactor = c.opacity / BLOB_INITIAL_OPACITY;
          let influence = pct * alphaFactor;
          
          let angle = atan2((y + PADDING) - c.y, (x + PADDING) - c.x);
          dispX += cos(angle) * influence * ELASTICITY;
          dispY += sin(angle) * influence * ELASTICITY;
          
          // Blend thread color toward blob color
          targetH = lerpColor(targetH, getPaletteColor(c.colorIdx), influence);
          targetV = lerpColor(targetV, getPaletteColor(c.colorIdx), influence);
        }
      }

      let n = noise((x + dispX) * NOISE_SCALE, (y + dispY) * NOISE_SCALE, t);
      
      if (n > 0.5) {
        drawHLine(x + dispX, y + dispY, GRID_RES, targetH);
        drawVLine(x + dispX, y + dispY, GRID_RES, targetV);
      } else {
        drawVLine(x + dispX, y + dispY, GRID_RES, targetV);
        drawHLine(x + dispX, y + dispY, GRID_RES, targetH);
      }
    }
  }
}

function drawHLine(x, y, sz, c) {
  stroke(c);
  line(x, y + sz / 2, x + sz, y + sz / 2);
}

function drawVLine(x, y, sz, c) {
  stroke(c);
  line(x + sz / 2, y, x + sz / 2, y + sz);
}

function getPaletteColor(index, alpha) {
  let pal = PALETTES[ACTIVE_PALETTE_INDEX % PALETTES.length];
  let hexCode = pal[index % pal.length];
  let c = color(hexCode);
  if (alpha !== undefined) {
    return color(red(c), green(c), blue(c), alpha);
  }
  return c;
}

function getBgColor() {
  let c = getPaletteColor(BG_COLOR_INDEX);
  if (INVERT_BG) {
    return color(255 - red(c), 255 - green(c), 255 - blue(c));
  }
  return c;
}

function drawDebugGrid(w, h) {
  stroke(255, 30);
  strokeWeight(1);
  for (let x = 0; x <= w; x += GRID_RES) line(x, 0, x, h);
  for (let y = 0; y <= h; y += GRID_RES) line(0, y, w, y);
}

class Impression {
  constructor(tx, ty, cIdx) {
    this.x = tx;
    this.y = ty;
    this.colorIdx = cIdx;
    this.opacity = BLOB_INITIAL_OPACITY; 
    this.diameter = random(BLOB_MIN_DIAMETER, BLOB_MAX_DIAMETER);
  }

  update() {
    this.opacity -= DECAY_RATE;
  }

  display() {
    noStroke();
    // Low alpha fill so the "blob" itself is subtle, emphasizing the thread color change
    fill(getPaletteColor(this.colorIdx, this.opacity * BLOB_FILL_ALPHA_MULT));
    ellipse(this.x, this.y, this.diameter, this.diameter);
  }

  isDead() {
    return this.opacity <= 0;
  }
}
