/**
 * Genuary 2026 - Day 10: Polar coordinates
 * 
 * Topographic Rings: Perlin Noise Polar
 * Version: 2026.09.30.13.48.00
 * Description: Generates organic, undulating rings using 2D Perlin Noise with glitch artifacts.
 */

// --- Configuration Parameters ---
const SKETCH_WIDTH = 800;       // Default: 480
const SKETCH_HEIGHT = 800;      // Default: 800
const RANDOM_SEED = 42;         // Default: 42
const PADDING = 40;             // Default: 40
const MAX_FRAMES = 900;         // Default: 900
const SAVE_FRAMES = false;      // Default: false
const ANIMATION_SPEED = 30;     // Default: 30

// --- Effect Parameters ---
const RING_COUNT = 50;          // Default: 50
const NOISE_STRENGTH = 300.0;   // Default: 110.0
const NOISE_SCALE = 0.5;        // Default: 0.9
const NOISE_COMPLEXITY = 0.01;  // Default: 0.1 (Step size for angle - lower is smoother)
const GLITCH_STRENGTH = 3.0;    // Default: 0.0 (Try 2.0 - 5.0 for jagged artifacts)
const Z_STEP = 0.007;           // Default: 0.007
const STROKE_WEIGHT_VAL = 1.2;  // Default: 1.2

const SHOW_GRID = false;        // Default: false
const INVERT_COLORS = false;    // Default: false
const PALETTE_INDEX = 1;        // Default: 1

// --- Color Palettes (Adobe Color) ---
// 0: Sandy Tropical / Terra Cotta
// 1: Deep Oceanic / Forest Mist
// 2: Crimson Sunset / Amber Glow
// 3: Muted Lavender / Vintage Dusk
// 4: Retro Cyber / Neon Splash

const palettes = [
  ['#264653', '#2a9d8f', '#e9c46a', '#f4a261', '#e76f51'],
  ['#001219', '#005f73', '#0a9396', '#94d2bd', '#e9d8a6'],
  ['#5f0f40', '#9a031e', '#fb8b24', '#e36414', '#0f4c5c'],
  ['#22223b', '#4a4e69', '#9a8c98', '#c9ada7', '#f2e9e4'],
  ['#118ab2', '#06d6a0', '#ffd166', '#ef476f', '#073b4c']
];

let zOff = 0.0;

function setup() {
  createCanvas(SKETCH_WIDTH, SKETCH_HEIGHT);
  randomSeed(RANDOM_SEED);
  noiseSeed(RANDOM_SEED);
  frameRate(ANIMATION_SPEED);
}

function draw() {
  const currentPalette = palettes[PALETTE_INDEX];
  const bgColorHex = currentPalette[0];
  const bgCol = color(bgColorHex);

  if (INVERT_COLORS) {
    background(255 - red(bgCol), 255 - green(bgCol), 255 - blue(bgCol));
  } else {
    background(bgCol);
  }

  if (SHOW_GRID) drawDebugGrid();

  push();
  translate(width / 2, height / 2);
  noFill();

  const maxRadius = (min(width, height) / 2.0) - PADDING;

  for (let i = 0; i < RING_COUNT; i++) {
    const colHex = currentPalette[1 + (i % (currentPalette.length - 1))];
    const col = color(colHex);

    if (INVERT_COLORS) {
      stroke(255 - red(col), 255 - green(col), 255 - blue(col), 160);
    } else {
      stroke(red(col), green(col), blue(col), 160);
    }

    strokeWeight(STROKE_WEIGHT_VAL);

    // Rings grow outward from center
    const baseRadius = map(i, 0, RING_COUNT, 5, maxRadius);
    drawOrganicRing(baseRadius, zOff + (i * 0.015));
  }
  pop();

  zOff += Z_STEP;

  // --- Export & Loop Control ---
  if (SAVE_FRAMES) {
    saveCanvas(`frame-${nf(frameCount, 4)}`, 'png');
    if (frameCount >= MAX_FRAMES) {
      noLoop();
    }
  }
}

function drawOrganicRing(radius, z) {
  beginShape();
  // NOISE_COMPLEXITY determines the resolution of the ring
  for (let a = 0; a < TWO_PI; a += NOISE_COMPLEXITY) {
    const xOff = map(cos(a), -1, 1, 0, NOISE_SCALE);
    const yOff = map(sin(a), -1, 1, 0, NOISE_SCALE);

    const n = noise(xOff, yOff, z);
    const r = radius + map(n, 0, 1, -NOISE_STRENGTH, NOISE_STRENGTH);

    // Apply Glitch: Random jitter based on GLITCH_STRENGTH
    const glitchX = random(-GLITCH_STRENGTH, GLITCH_STRENGTH);
    const glitchY = random(-GLITCH_STRENGTH, GLITCH_STRENGTH);

    const x = r * cos(a) + glitchX;
    const y = r * sin(a) + glitchY;
    vertex(x, y);
  }
  endShape(CLOSE);
}

function drawDebugGrid() {
  stroke(150, 40);
  strokeWeight(1);
  for (let x = PADDING; x <= width - PADDING; x += 40) {
    line(x, PADDING, x, height - PADDING);
  }
  for (let y = PADDING; y <= height - PADDING; y += 40) {
    line(PADDING, y, width - PADDING, y);
  }
}
