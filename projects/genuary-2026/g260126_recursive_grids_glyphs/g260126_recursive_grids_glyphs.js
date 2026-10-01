/**
 * Genuary 2026 - Day 26: Recursive Grids. Split the canvas into a grid of some kind and recurse on each cell.
 * Recursive Grid Zoom - Variation: Glyph Morph (Refined)
 * Version: 2026.10.01.15.46.00
 * 
 * Description:
 * Recursive grid zoom animation morphing geometric glyphs across nested hierarchical scales.
 * Converted from Processing (Java) to p5.js.
 * 
 * Changes:
 * - Render full 3x3 outer ring for bleed glyphs so left, right, and corners remain seamless before and during zoom.
 * - Added mouse click handler to cycle color palettes.
 * - Added spacebar handler to cycle glyph types.
 * - Converted from Processing PDE to p5.js.
 * - Retained all visual parameters, palettes, and glyph generators.
 * - Integer division handled cleanly for JS runtime.
 * - Filtered library to: Diamond Frame, Nested Squares, X Target, Split Circle.
 * - Added GLYPH_SCALE parameter for internal sizing.
 * - Added DETAIL_SIZE and SHOW_DETAILS for corner/intersection decorations.
 * - Palette index set to 3 (Muted).
 * - Rotation and layout synchronized for seamless looping.
 */

// --- Parameters ---
let SKETCH_WIDTH = 800;      // Default: 480
let SKETCH_HEIGHT = 800;     // Default: 800
let MAX_FRAMES = 800;        // Default: 800
let SAVE_FRAMES = false;     // Default: false
let ANIMATION_SPEED = 30;    // Default: 30
let CYCLE_LENGTH = 100;      // Default: 100
let GLOBAL_SEED = 42;        // Default: 42
let CANVAS_PADDING = 40;     // Default: 40

// Logic Parameters
let START_SIZE = 400;        // Default: 400
let END_SIZE = 118;          // Default: 118
let GRID_COUNT = 3;          // Default: 3
let INVERT_BACK = false;     // Default: false
let SHOW_GRID_CELLS = false; // Default: false

// Glyph Visual Parameters
let GLYPH_SCALE = 1.2;       // Default: 1.2 (Internal scale of the design)
let DETAIL_SIZE = 6.0;       // Default: 6.0 (Size of decorative circles)
let SHOW_DETAILS = true;     // Default: true
let GLYPH_TYPE = 2;          // Default: 2 (Select 0-3: 0 = Diamond Frame, 1 = Nested Squares, 2 = X Target, 3 = Split Circle)
const GLYPH_NAMES = [
  "Diamond Frame", "Nested Squares", "X Target", "Split Circle"
];

// Color Palettes
const PALETTES = [
  ["#264653", "#2a9d8f", "#e9c46a", "#f4a261", "#e76f51"], // Palette 0: Terra Cotta
  ["#001219", "#005f73", "#0a9396", "#94d2bd", "#e9d8a6"], // Palette 1: Deep Sea
  ["#ffbe0b", "#fb5607", "#ff006d", "#8338ec", "#3a86ff"], // Palette 2: Cyber
  ["#22223b", "#4a4e69", "#9a8c98", "#c9ada7", "#f2e9e4"], // Palette 3: Muted
  ["#1a1c2c", "#5d275d", "#b13e53", "#ef7d57", "#ffcd75"]  // Palette 4: Sunset
];
let PALETTE_INDEX = 3; // Default: 3

// Variables
let bg_color;

function setup() {
  createCanvas(SKETCH_WIDTH, SKETCH_HEIGHT);
  randomSeed(GLOBAL_SEED);
  frameRate(ANIMATION_SPEED);
  updateBackgroundColor();
}

function updateBackgroundColor() {
  let activePalette = PALETTES[PALETTE_INDEX];
  bg_color = color(activePalette[0]);
  if (INVERT_BACK) {
    bg_color = color(255 - red(bg_color), 255 - green(bg_color), 255 - blue(bg_color));
  }
}

function draw() {
  background(bg_color);
  translate(width / 2, height / 2);

  // Progress Logic
  let currentFrame = frameCount - 1;
  let progress = (currentFrame % CYCLE_LENGTH) / CYCLE_LENGTH;

  // --- Color Selection ---
  let p = PALETTES[PALETTE_INDEX];
  let paletteCount = p.length - 1;
  let colorLevel = Math.floor(currentFrame / CYCLE_LENGTH);

  let colorBleed = color(p[1 + ((colorLevel + paletteCount - 1) % paletteCount)]);
  let colorCurr = color(p[1 + (colorLevel % paletteCount)]);
  let colorNext = color(p[1 + ((colorLevel + 1) % paletteCount)]);

  // --- Animation Timing ---
  let zoomT = constrain(map(progress, 0.0, 0.4, 0, 1), 0, 1);
  let shrinkT = constrain(map(progress, 0.4, 0.6, 0, 1), 0, 1);
  let distributeT = constrain(map(progress, 0.6, 1.0, 0, 1), 0, 1);

  // --- Geometry Constants ---
  let targetScale = START_SIZE / END_SIZE;
  let gap = (START_SIZE - (GRID_COUNT * END_SIZE)) / (GRID_COUNT - 1);
  let gridStep = END_SIZE + gap;
  let currentZoom = Math.pow(targetScale, zoomT);

  push();
  scale(currentZoom);

  // --- 1. BLEED GLYPHS (Background - Outer 3x3 Ring) ---
  for (let row = -1; row <= 1; row++) {
    for (let col = -1; col <= 1; col++) {
      if (row === 0 && col === 0) continue;
      drawGlyph(col * gridStep * targetScale, row * gridStep * targetScale, START_SIZE, colorBleed, progress, GLYPH_TYPE);
    }
  }

  // --- 2. MAIN 3x3 GRID ---
  for (let row = -1; row <= 1; row++) {
    for (let col = -1; col <= 1; col++) {
      if (row === 0 && col === 0) continue;
      drawGlyph(col * gridStep, row * gridStep, END_SIZE, colorCurr, progress, GLYPH_TYPE);
    }
  }

  // --- 3. CENTER STACK ---
  let shrunkenSize = END_SIZE / targetScale;
  let currentS = lerp(END_SIZE, shrunkenSize, shrinkT);
  let distStep = gridStep / targetScale;
  let stackColor = lerpColor(colorCurr, colorNext, progress);

  renderGlyphStack(0, 0, currentS, distributeT, distStep, shrunkenSize, stackColor, progress);

  pop();

  if (SAVE_FRAMES) {
    saveCanvas(`frames/${nf(frameCount, 4)}`, "png");
  }
  if (frameCount >= MAX_FRAMES && SAVE_FRAMES) {
    noLoop();
  }
}

function renderGlyphStack(cx, cy, s, t, step, targetS, c, prog) {
  for (let i = 0; i < 9; i++) {
    let tx = ((i % 3) - 1) * step;
    let ty = (Math.floor(i / 3) - 1) * step;
    let x = cx;
    let y = cy;
    let dSize = (t > 0) ? targetS : s;

    if (t > 0 && i !== 4) {
      let moveOrder = (i > 4) ? i - 1 : i;
      let indT = constrain(map(t, moveOrder * 0.125, (moveOrder + 1) * 0.125, 0, 1), 0, 1);
      let easedT = 1 - Math.pow(1 - indT, 3);
      x = lerp(cx, tx, easedT);
      y = lerp(cy, ty, easedT);
    }
    drawGlyph(x, y, dSize, c, prog, GLYPH_TYPE);
  }
}

function drawGlyph(x, y, size, c, prog, type) {
  push();
  translate(x, y);
  rotate(prog * HALF_PI);

  if (SHOW_GRID_CELLS) {
    stroke(red(c), green(c), blue(c), 40);
    noFill();
    rectMode(CENTER);
    rect(0, 0, size, size);
  }

  stroke(c);
  strokeWeight(size * 0.05);
  noFill();
  strokeCap(PROJECT);

  // Apply GLYPH_SCALE to the drawing context
  push();
  scale(GLYPH_SCALE);
  drawGlyphDesign(size, prog, type, c);
  pop();

  pop();
}

function drawGlyphDesign(s, p, type, c) {
  let r = s / 2;
  let dSize = DETAIL_SIZE * (s / END_SIZE); // Scale detail with glyph size

  switch (type) {
    case 0: // Diamond Frame
      beginShape();
      vertex(0, -r);
      vertex(r, 0);
      vertex(0, r);
      vertex(-r, 0);
      endShape(CLOSE);
      if (SHOW_DETAILS) {
        fill(c);
        noStroke();
        ellipse(0, -r, dSize, dSize);
        ellipse(r, 0, dSize, dSize);
        ellipse(0, r, dSize, dSize);
        ellipse(-r, 0, dSize, dSize);
        noFill();
        stroke(c);
      }
      break;

    case 1: // Nested Squares
      rectMode(CENTER);
      rect(0, 0, s * 0.7, s * 0.7);
      rect(0, 0, s * 0.2, s * 0.2);
      if (SHOW_DETAILS) {
        fill(c);
        noStroke();
        let corner = s * 0.35;
        ellipse(-corner, -corner, dSize, dSize);
        ellipse(corner, -corner, dSize, dSize);
        ellipse(corner, corner, dSize, dSize);
        ellipse(-corner, corner, dSize, dSize);
        noFill();
        stroke(c);
      }
      break;

    case 2: // X Target
      line(-r, -r, r, r);
      line(r, -r, -r, r);
      ellipse(0, 0, s * 0.5, s * 0.5);
      if (SHOW_DETAILS) {
        fill(c);
        noStroke();
        ellipse(-r, -r, dSize, dSize);
        ellipse(r, -r, dSize, dSize);
        ellipse(r, r, dSize, dSize);
        ellipse(-r, r, dSize, dSize);
        ellipse(0, 0, dSize, dSize);
        noFill();
        stroke(c);
      }
      break;

    case 3: // Split Circle
      ellipse(0, 0, s, s);
      line(-r, 0, r, 0);
      line(0, -r, 0, r);
      if (SHOW_DETAILS) {
        fill(c);
        noStroke();
        ellipse(0, 0, dSize, dSize);
        ellipse(-r, 0, dSize, dSize);
        ellipse(r, 0, dSize, dSize);
        ellipse(0, -r, dSize, dSize);
        ellipse(0, r, dSize, dSize);
        noFill();
        stroke(c);
      }
      break;
  }
}

function mousePressed() {
  PALETTE_INDEX = (PALETTE_INDEX + 1) % PALETTES.length;
  updateBackgroundColor();
}

function keyPressed() {
  if (key === ' ') {
    GLYPH_TYPE = (GLYPH_TYPE + 1) % GLYPH_NAMES.length;
    return false; // Prevent browser scroll
  }
}
