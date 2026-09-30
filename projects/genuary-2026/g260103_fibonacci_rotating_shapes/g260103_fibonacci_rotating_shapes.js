// Version 2026.09.30.13.38.13
// 
// Genuary 2026: Day 4 - Fibonacci forever. 
// Create a work that uses the Fibonacci sequence in some way. 
// Description: Distributed 3D Golden Nexus Orrery in p5.js.
// Uses spherical distribution to spread Fibonacci objects across the vertical canvas in WEBGL mode.

// --- Parameters ---
const SKETCH_WIDTH = 800;            // default 480
const SKETCH_HEIGHT = 800;           // default 800
const PADDING = 40;                  // default 40
const MAX_FRAMES = 900;              // default 900 (Used only for SAVE_FRAMES limit)
const SAVE_FRAMES = false;           // default false
const ANIMATION_SPEED = 60;          // default 60
const GLOBAL_SEED = 1111;            // default 1111

const OBJECT_COUNT = 25;             // default 25
const NESTED_LAYERS = 6;             // default 6
const PHI = 1.61803398875;           // The Golden Ratio

const INVERT_BG = false;             // Toggle background (default false)
const SHOW_GRID = false;             // Toggle grid (default false)

// Motion Parameters
const ROT_SPEED_MIN = 0.005;         // default 0.005
const ROT_SPEED_MAX = 0.020;         // default 0.020
const GLOBAL_ROT_SPEED = 0.005;      // default 0.005
const SCALE_MIN = 100;               // default 100
const SCALE_MAX = 220;               // default 220
const Z_OFFSET = -100;               // default -100
const ARC_STEP = 0.15;               // default 0.15

// Spherical Layout Bounds
const SPHERE_RADIUS_X = 200;         // default 200
const SPHERE_RADIUS_Y = 350;         // default 350
const SPHERE_RADIUS_Z = 150;         // default 150

// Color Palette Index (0 to 4)
const PALETTE_INDEX = 0;             // default 0

// 5 Curated Adobe Kuler Color Palettes
const PALETTES = [
  // 0: "Midnight Gold"
  ['#020812', '#FF4E50', '#FCCA14', '#00D2FF', '#FFFFFF'],
  // 1: "Neon Sunset"
  ['#0B032D', '#843B62', '#F67E7D', '#FFB997', '#F2F2F2'],
  // 2: "Cyberpunk Glow"
  ['#050510', '#FF007F', '#00F0FF', '#7928CA', '#FFFFFF'],
  // 3: "Oceanic Bioluminescence"
  ['#011627', '#2EC4B6', '#E71D36', '#FF9F1C', '#FDFFFC'],
  // 4: "Solar Flare"
  ['#1A0B2E', '#E63946', '#F1A208', '#00A896', '#EDE8F5']
];

let systems = [];

function setup() {
  createCanvas(SKETCH_WIDTH, SKETCH_HEIGHT, WEBGL);
  frameRate(ANIMATION_SPEED);
  randomSeed(GLOBAL_SEED);
  noiseSeed(GLOBAL_SEED);

  const activePalette = PALETTES[PALETTE_INDEX];

  systems = [];
  for (let i = 0; i < OBJECT_COUNT; i++) {
    // Distribute objects using a spherical layout
    let offset = 2.0 / OBJECT_COUNT;
    let increment = Math.PI * (3.0 - Math.sqrt(5.0)); // Golden Angle
    let y = ((i * offset) - 1) + (offset / 2);
    let r = Math.sqrt(1 - Math.pow(y, 2));
    let phi = i * increment;

    let x = Math.cos(phi) * r;
    let z = Math.sin(phi) * r;

    // Scale vectors to fit the aspect ratio
    let pos = createVector(x * SPHERE_RADIUS_X, y * SPHERE_RADIUS_Y, z * SPHERE_RADIUS_Z);
    systems.push(new GoldenNexus(pos, activePalette));
  }
}

function draw() {
  const activePalette = PALETTES[PALETTE_INDEX];
  let currentBg = INVERT_BG ? activePalette[4] : activePalette[0];
  let currentStroke = INVERT_BG ? activePalette[0] : activePalette[4];

  background(currentBg);

  // Basic Scene Lighting
  ambientLight(80, 80, 100);
  pointLight(255, 255, 255, 0, 0, 400);

  if (SHOW_GRID) drawDebugGrid(currentStroke);

  push();
  translate(0, 0, Z_OFFSET);

  // Slow global rotation for visual interest
  rotateY(frameCount * GLOBAL_ROT_SPEED);
  rotateX(frameCount * GLOBAL_ROT_SPEED * 0.5);

  for (let gn of systems) {
    gn.update();
    gn.display(currentStroke);
  }
  pop();

  // --- Export Block ---
  if (SAVE_FRAMES && frameCount <= MAX_FRAMES) {
    saveCanvas(`frame_${nf(frameCount, 4)}`, 'png');
  }
}

// --- Classes ---

class GoldenNexus {
  constructor(_pos, palette) {
    this.pos = _pos;
    this.rotation = createVector(random(TWO_PI), random(TWO_PI), random(TWO_PI));

    // Parameters for unique spin rates
    this.rotStep = createVector(
      random(ROT_SPEED_MIN, ROT_SPEED_MAX) * (random(1) > 0.5 ? 1 : -1),
      random(ROT_SPEED_MIN, ROT_SPEED_MAX) * (random(1) > 0.5 ? 1 : -1),
      random(ROT_SPEED_MIN, ROT_SPEED_MAX) * (random(1) > 0.5 ? 1 : -1)
    );

    this.baseScale = random(SCALE_MIN, SCALE_MAX);
    const accentIndex = floor(random(1, 4));
    this.accent = palette[accentIndex];
  }

  update() {
    this.rotation.add(this.rotStep);
  }

  display(primaryStroke) {
    push();
    translate(this.pos.x, this.pos.y, this.pos.z);
    rotateX(this.rotation.x);
    rotateY(this.rotation.y);
    rotateZ(this.rotation.z);

    let currentSize = this.baseScale;

    for (let i = 0; i < NESTED_LAYERS; i++) {
      let alphaVal = map(i, 0, NESTED_LAYERS, 255, 60);
      let sw = map(i, 0, NESTED_LAYERS, 2.0, 0.7);

      push();
      rotateZ(i * HALF_PI);

      let w = currentSize;
      let h = currentSize / PHI;

      noFill();
      strokeWeight(sw);

      // Rect Frame
      let strokeColor = color(primaryStroke);
      strokeColor.setAlpha(alphaVal * 0.4);
      stroke(strokeColor);
      rectMode(CENTER);
      rect(0, 0, w, h);

      // Golden Spiral Arc
      let accentColor = color(this.accent);
      accentColor.setAlpha(alphaVal);
      stroke(accentColor);
      this.drawArc(w / 2, h / 2, h);

      pop();

      // Transform for next nested layer
      let prevSize = currentSize;
      currentSize /= PHI;
      translate((prevSize - currentSize) / 2, -(prevSize - currentSize) / (2 * PHI), 0);
    }
    pop();
  }

  drawArc(x, y, r) {
    beginShape();
    for (let a = PI; a <= PI + HALF_PI; a += ARC_STEP) {
      vertex(x + cos(a) * r * 2, y + sin(a) * r * 2);
    }
    endShape();
  }
}

// --- Utilities ---

function drawDebugGrid(gridColor) {
  let c = color(gridColor);
  c.setAlpha(25);
  stroke(c);
  strokeWeight(1);
  for (let i = -400; i <= 400; i += 100) {
    line(i, -height, -200, i, height, -200);
    line(-width, i, -200, width, i, -200);
  }
}
