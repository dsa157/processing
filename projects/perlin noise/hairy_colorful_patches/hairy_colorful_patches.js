/**
 * Hairy Colorful Patches
 * Version: 2026.10.04.16.54.00
 * 
 * Description:
 * Perlin noise flow field, creating fibrous, organic hair-like trails that slowly dissolve.
 * Colors are geographically mapped via 2D spatial Perlin noise in full-spectrum
 * HSB space with central saturation falloff, with optional palettes.
 * 
 */

// ====================================================================
// GLOBAL PARAMETERS
// ====================================================================

// --- Canvas Setup ---
let SKETCH_WIDTH = 600;                 // default: 600 
let SKETCH_HEIGHT = 800;                // default: 800
let ANIMATION_SPEED = 60;               // default: 60 
let MAX_FRAMES = 600;                   // default: 600
let SAVE_FRAMES = false;                // default: false 

// --- Reproducibility & Seeds ---
let GLOBAL_SEED = 157;                  // default: 157 

// --- Flow Field Physics & Dynamics ---
let TIME_SPEED = 0.005;                 // default: 0.005 (evolution speed of flow field over time)
let NOISE_SCALE = 0.005;                // default: 0.005 (spatial frequency of noise field)
let STEP_SIZE = 1.0;                    // default: 1.0 (step size for particle movement)
let ANGLE_MULTIPLIER = 4.0;             // default: 4.0 (TWO_PI * 4 angle range)
let FIELD_STEP = 4;                     // default: 4 (step size in pixels for flow field grid)
let FIELD_UPDATE_INTERVAL = 10;         // default: 10 (frames between flow field updates)

// --- Particle Population & Trail Parameters ---
let MAX_PARTICLES = 40000;              // default: 40000 (original pde: 40000)
let INVERT_COLORS = true;               // default: true (original pde: true -> black background)
let TRAIL_FADE_ALPHA = 10;              // default: 10 (corresponds to alpha 10/255 in original PDE: fill(0, 10))
let PARTICLE_ALPHA = 20;                // default: 20 (corresponds to alpha 20/255 in original PDE: stroke(..., 20))
let COLOR_NOISE_SCALE = 0.01;           // default: 0.01 (spatial scale for particle color noise mapping)
let STROKE_WEIGHT_MIN = 0.5;            // default: 0.5 (min stroke weight)
let STROKE_WEIGHT_MAX = 3.0;            // default: 3.0 (max stroke weight)
let COLOR_BUCKETS = 48;                 // default: 48 (hue quantization buckets for high-fps path batching)

// --- Color Palettes (Curated from Adobe Kuler / Color Themes) ---
// 5 distinct palettes with 5 harmonious colors each
const PALETTES = [
  // Palette 0: "Original Java HSB Spectrum" (Pure black background with full-spectrum rainbow patch gradients)
  ["#000000", "#FF0055", "#FF7700", "#00FF66", "#00CCFF", "#9900FF"],

  // Palette 1: "Electric Aurora" (Deep space navy background with luminous teal, aqua, and vibrant violet)
  ["#0B132B", "#1C2541", "#5BC0BE", "#6FFFE9", "#9B5DE5"],

  // Palette 2: "Retro Sunset" (Dark indigo background with rich magenta, fiery coral, gold, and warm amber)
  ["#1A1423", "#3D315B", "#E05A47", "#F0A202", "#F2E863"],

  // Palette 3: "Deep Oceanic Reef" (Abyssal teal background with cyan, marine blue, coral pink, and seafoam)
  ["#03071E", "#087E8B", "#00B4D8", "#FF5A5F", "#C1FBA4"],

  // Palette 4: "Mystic Forest" (Shadowed pine background with emerald, moss olive, warm sandstone, and ochre)
  ["#0D1B1E", "#2B4C3F", "#606C38", "#DDA15E", "#BC6C25"]
];

let PALETTE_INDEX = 0;                  // default: 0 (0 = Original Java HSB Spectrum, 1-4 = Adobe Kuler)
let BG_COLOR_INDEX = 0;                 // default: 0 (palette index chosen for background color)

// ====================================================================
// SIMULATION DATA STRUCTURES
// ====================================================================

let field = [];
let particles = [];
let cols = 0;
let rows = 0;

// Path batching buffers for silky-smooth 60fps rendering
let bucketPaths = [];
let isLoopingState = true;

function setup() {
  let canvas = createCanvas(SKETCH_WIDTH, SKETCH_HEIGHT);
  let container = document.getElementById("canvas-container");
  if (container) {
    canvas.parent(container);
  }
  frameRate(ANIMATION_SPEED);

  // Initialize deterministic seeds
  randomSeed(GLOBAL_SEED);
  noiseSeed(GLOBAL_SEED);

  // Flow field grid dimensions
  cols = Math.ceil(width / FIELD_STEP);
  rows = Math.ceil(height / FIELD_STEP);

  field = new Array(cols);
  for (let x = 0; x < cols; x++) {
    field[x] = new Array(rows);
  }

  // Pre-calculate the flow field
  calculateFlowField(0);

  // Initialize path batching buckets
  bucketPaths = new Array(COLOR_BUCKETS);
  for (let b = 0; b < COLOR_BUCKETS; b++) {
    bucketPaths[b] = [];
  }

  // Create particles
  particles = [];
  for (let i = 0; i < MAX_PARTICLES; i++) {
    particles.push(new Particle(random(width), random(height)));
  }

  // Set initial background color
  applyBackgroundColor();
}

function draw() {
  // Semi-transparent overlay for trails
  let bgCol = getActiveBackgroundColor();
  noStroke();
  fill(red(bgCol), green(bgCol), blue(bgCol), TRAIL_FADE_ALPHA);
  rect(0, 0, width, height);

  // Animate the flow field over time
  if (frameCount % FIELD_UPDATE_INTERVAL === 0) {
    calculateFlowField(frameCount * TIME_SPEED);
  }

  // Clear path batching buckets
  for (let b = 0; b < COLOR_BUCKETS; b++) {
    bucketPaths[b].length = 0;
  }

  // Update and collect particle line segments
  for (let i = 0; i < particles.length; i++) {
    particles[i].update();
    particles[i].queueDisplay();
  }

  // Render batched lines for high-fps playback
  renderBatchedLines();

  // Frame management
  if (SAVE_FRAMES && frameCount >= MAX_FRAMES) {
    noLoop();
  }
}

/**
 * Computes 2D vector flow field from 3D Perlin noise.
 */
function calculateFlowField(timeOffset) {
  const twoPi4 = TWO_PI * ANGLE_MULTIPLIER;
  for (let y = 0; y < rows; y++) {
    const py = y * FIELD_STEP;
    for (let x = 0; x < cols; x++) {
      const px = x * FIELD_STEP;
      let noiseValue;
      if (timeOffset === 0) {
        noiseValue = noise(px * NOISE_SCALE, py * NOISE_SCALE);
      } else {
        noiseValue = noise(px * NOISE_SCALE, py * NOISE_SCALE, timeOffset);
      }
      const angle = map(noiseValue, 0, 1, 0, twoPi4);
      field[x][y] = p5.Vector.fromAngle(angle);
    }
  }
}

/**
 * Returns current background p5.Color instance.
 */
function getActiveBackgroundColor() {
  if (PALETTE_INDEX === 0) {
    return color(INVERT_COLORS ? 0 : 255);
  } else {
    let bgHex = PALETTES[PALETTE_INDEX][BG_COLOR_INDEX];
    let c = color(bgHex);
    if (!INVERT_COLORS) {
      return color(255 - red(c), 255 - green(c), 255 - blue(c));
    }
    return c;
  }
}

function applyBackgroundColor() {
  background(getActiveBackgroundColor());
}

/**
 * Particle Class matching Java implementation logic.
 */
class Particle {
  constructor(x, y) {
    this.position = createVector(x, y);
    this.prevPosition = this.position.copy();
  }

  update() {
    // Wrap particles that go off-screen
    if (this.position.x < 0 || this.position.x >= width || this.position.y < 0 || this.position.y >= height) {
      this.position.x = random(width);
      this.position.y = random(height);
      this.prevPosition = this.position.copy();
    }

    this.prevPosition = this.position.copy();

    // Get vector from flow field
    let fieldX = Math.floor(constrain(this.position.x / FIELD_STEP, 0, cols - 1));
    let fieldY = Math.floor(constrain(this.position.y / FIELD_STEP, 0, rows - 1));
    let currentVector = field[fieldX][fieldY];

    this.position.add(currentVector.x * STEP_SIZE, currentVector.y * STEP_SIZE);
  }

  queueDisplay() {
    // Spatial noise value for color mapping
    let nVal = noise(this.position.x * COLOR_NOISE_SCALE, this.position.y * COLOR_NOISE_SCALE);
    let bucketIdx = Math.floor(constrain(nVal * COLOR_BUCKETS, 0, COLOR_BUCKETS - 1));

    // Store line segment in the bucket
    bucketPaths[bucketIdx].push(
      this.prevPosition.x, this.prevPosition.y,
      this.position.x, this.position.y
    );
  }

  display() {
    // Direct individual display fallback
    colorMode(HSB, 255);
    let hue1 = map(noise(this.position.x * COLOR_NOISE_SCALE, this.position.y * COLOR_NOISE_SCALE), 0, 1, 0, 255);
    let saturation = map(dist(width / 2, height / 2, this.position.x, this.position.y), 0, height / 2, 255, 100);
    let brightness = 255;

    stroke(hue1, saturation, brightness, PARTICLE_ALPHA);

    let fieldX = Math.floor(constrain(this.position.x / FIELD_STEP, 0, cols - 1));
    let fieldY = Math.floor(constrain(this.position.y / FIELD_STEP, 0, rows - 1));
    let weight = map(field[fieldX][fieldY].mag(), 0, 1, STROKE_WEIGHT_MIN, STROKE_WEIGHT_MAX);
    strokeWeight(weight);

    line(this.prevPosition.x, this.prevPosition.y, this.position.x, this.position.y);
    colorMode(RGB, 255);
  }
}

/**
 * Batched line segment renderer to execute 40,000 lines at silky 60fps.
 */
function renderBatchedLines() {
  const ctx = drawingContext;
  ctx.lineWidth = STROKE_WEIGHT_MAX; // mag() of unit vector fromAngle is 1.0 -> weight = 3.0
  ctx.lineCap = "round";

  const isOriginalHSB = (PALETTE_INDEX === 0);
  const activePalette = PALETTES[PALETTE_INDEX];
  const alphaRatio = PARTICLE_ALPHA / 255;

  for (let b = 0; b < COLOR_BUCKETS; b++) {
    const coords = bucketPaths[b];
    const len = coords.length;
    if (len === 0) continue;

    const normVal = (b + 0.5) / COLOR_BUCKETS;

    if (isOriginalHSB) {
      // Map to full rainbow HSB hue [0..360]
      const hueDeg = normVal * 360;
      // Saturation average: 177 / 255 ≈ 70%
      ctx.strokeStyle = `hsla(${hueDeg}, 75%, 55%, ${alphaRatio})`;
    } else {
      // Interpolate along active Adobe Kuler palette
      const colorsOnly = activePalette.slice(1);
      const scaled = normVal * (colorsOnly.length - 1);
      const idx0 = Math.floor(scaled);
      const frac = scaled - idx0;
      const c1 = color(colorsOnly[idx0]);
      const c2 = color(colorsOnly[Math.min(colorsOnly.length - 1, idx0 + 1)]);
      const r = red(c1) + (red(c2) - red(c1)) * frac;
      const g = green(c1) + (green(c2) - green(c1)) * frac;
      const bl = blue(c1) + (blue(c2) - blue(c1)) * frac;
      ctx.strokeStyle = `rgba(${Math.round(r)}, ${Math.round(g)}, ${Math.round(bl)}, ${alphaRatio})`;
    }

    ctx.beginPath();
    for (let i = 0; i < len; i += 4) {
      ctx.moveTo(coords[i], coords[i + 1]);
      ctx.lineTo(coords[i + 2], coords[i + 3]);
    }
    ctx.stroke();
  }
}

/**
 * Handles keyboard interactivity.
 */
function keyPressed() {
  if (key === " " || keyCode === 32) {
    // Spacebar: Cycle color palette
    PALETTE_INDEX = (PALETTE_INDEX + 1) % PALETTES.length;
    return false; // Prevent page scroll on spacebar
  } else if (key === "p" || key === "P") {
    // P: Cycle color palette
    PALETTE_INDEX = (PALETTE_INDEX + 1) % PALETTES.length;
  } else if (key === "i" || key === "I") {
    // I: Invert background
    INVERT_COLORS = !INVERT_COLORS;
    applyBackgroundColor();
  } else if (key === "c" || key === "C") {
    // C: Clear trails
    applyBackgroundColor();
  } else if (key === "r" || key === "R") {
    // R: Reset simulation
    randomSeed(GLOBAL_SEED);
    noiseSeed(GLOBAL_SEED);
    calculateFlowField(0);
    particles = [];
    for (let i = 0; i < MAX_PARTICLES; i++) {
      particles.push(new Particle(random(width), random(height)));
    }
    applyBackgroundColor();
  }
}

function mousePressed() {
  // Clicking on canvas cycles color palettes
  if (mouseX >= 0 && mouseX < width && mouseY >= 0 && mouseY < height) {
    PALETTE_INDEX = (PALETTE_INDEX + 1) % PALETTES.length;
  }
}
