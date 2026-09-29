/**
 * Centrosymmetric Spiral Interlock - "Greedy Coloring & Perfect Bleed"
 * Version: 2026.09.29.23.48.36
 */

// --- Global Parameters ---
let SKETCH_WIDTH = 480;       // Default: 480
let SKETCH_HEIGHT = 800;      // Default: 800
let RANDOM_SEED = 12345;      // Default: 12345
let PADDING = 40;             // Default: 40
let MAX_FRAMES = 900;         // Default: 900
let SAVE_FRAMES = false;      // Default: false
let ANIMATION_SPEED = 30;     // Default: 30
let PALETTE_INDEX = 0;        // Default: 0
let INVERT_BG = false;        // Default: false
let SHOW_GRID = false;        // Default: false

// --- Design Parameters ---
let HEX_RADIUS = 55.0;        // Default: 55.0
let SPIRAL_INTENSITY = 0.6;   // Default: 0.6
let PULSE_SPEED = 0.06;       // Default: 0.06
let DROP_SHADOW = false;      // Default: false
let SHADOW_OFFSET = 4.0;      // Default: 4.0
let SHADOW_ALPHA = 120;       // Default: 120

// --- Color Palettes (Adobe Color / Kuler inspired) ---
// 0: Deep Sea / Arctic Frost
// 1: Warm Coral Sunset
// 2: Modern Slate & Cyan
// 3: Teal Serenity / Mint Echo
// 4: Vibrant Twilight Glow
const PALETTES = [
  ["#1B262C", "#0F4C75", "#3282B8", "#BBE1FA", "#FFFFFF"],
  ["#2D4059", "#EA5455", "#F07B3F", "#FFD460", "#EEEEEE"],
  ["#222831", "#393E46", "#00ADB5", "#EEEEEE", "#FFD369"],
  ["#40514E", "#30E3CA", "#11999E", "#E4F1FE", "#F5F5F5"],
  ["#543864", "#FF6363", "#FFBD69", "#FF9A3C", "#202040"]
];

let activePalette;
let backgroundColor;
let colorGrid;
let gridRows, gridCols;

function setup() {
  createCanvas(SKETCH_WIDTH, SKETCH_HEIGHT);
  randomSeed(RANDOM_SEED);
  frameRate(ANIMATION_SPEED);

  activePalette = PALETTES[PALETTE_INDEX];
  backgroundColor = INVERT_BG ? activePalette[3] : activePalette[0];

  // Hex Grid Dimensions
  let vertDist = HEX_RADIUS * 1.5;
  let horizDist = sqrt(3) * HEX_RADIUS;

  // Buffers for full coverage (Overscan)
  gridRows = ceil(SKETCH_HEIGHT / vertDist) + 6;
  gridCols = ceil(SKETCH_WIDTH / horizDist) + 6;

  initializeColorGrid();
}

/**
 * Greedy Map Coloring for Hexagonal Lattice.
 * Ensures randomized appearance while preventing adjacent tiles from having the same color.
 */
function initializeColorGrid() {
  colorGrid = [];
  for (let r = 0; r < gridRows; r++) {
    colorGrid[r] = [];
    for (let c = 0; c < gridCols; c++) {
      // Indices 1-4 are the decorative colors (0 is background)
      let available = [];
      for (let i = 1; i < activePalette.length; i++) {
        available.push(i);
      }

      // Check neighbors in a hex grid context (top, left, and diagonal neighbors)
      if (r > 0) {
        available = available.filter(val => val !== colorGrid[r - 1][c]);
      }
      if (c > 0) {
        available = available.filter(val => val !== colorGrid[r][c - 1]);
      }
      if (r > 0 && c > 0) {
        available = available.filter(val => val !== colorGrid[r - 1][c - 1]);
      }
      if (r > 0 && c < gridCols - 1) {
        available = available.filter(val => val !== colorGrid[r - 1][c + 1]);
      }

      if (available.length > 0) {
        available = shuffle(available);
        colorGrid[r][c] = available[0];
      } else {
        // Fallback to random if constraints are too tight
        colorGrid[r][c] = floor(random(1, activePalette.length));
      }
    }
  }
}

function draw() {
  background(backgroundColor);

  let time = frameCount * PULSE_SPEED;
  let morph = map(sin(time), -1, 1, 0.5, 1.2);

  let vertDist = HEX_RADIUS * 1.5;
  let horizDist = sqrt(3) * HEX_RADIUS;

  push();
  // Move origin back significantly to cover left/top margins
  translate(-horizDist * 1.5, -vertDist * 1.5);

  for (let r = 0; r < gridRows; r++) {
    for (let c = 0; c < gridCols; c++) {
      let x = c * horizDist + (r % 2 === 0 ? 0 : horizDist / 2);
      let y = r * vertDist;

      push();
      translate(x, y);

      let colIdx = colorGrid[r][c];
      drawTightSpiral(HEX_RADIUS, activePalette[colIdx], morph);

      pop();
    }
  }
  pop();

  // Save Frames and Loop Management
  if (SAVE_FRAMES) {
    saveCanvas(`frame_${nf(frameCount, 4)}`, "png");
    if (frameCount >= MAX_FRAMES) noLoop();
  }
}

/**
 * Draws a tile with centrosymmetric edges: f(t) = -f(1-t).
 * This ensures the complex "limbs" always fit perfectly into neighboring sockets.
 */
function drawTightSpiral(radius, c, morph) {
  fill(c);
  if (SHOW_GRID) {
    stroke(255, 60);
  } else {
    noStroke();
  }

  beginShape();
  for (let i = 0; i < 6; i++) {
    let angle1 = (PI / 3) * i - PI / 6;
    let angle2 = (PI / 3) * (i + 1) - PI / 6;

    let x1 = cos(angle1) * radius;
    let y1 = sin(angle1) * radius;
    let x2 = cos(angle2) * radius;
    let y2 = sin(angle2) * radius;

    // Sampling for curvature
    for (let step = 0; step <= 1.0; step += 0.04) {
      let tx = lerp(x1, x2, step);
      let ty = lerp(y1, y2, step);

      let normalAngle = angle1 + HALF_PI;
      let offset = calculateSpiral(step, morph);

      vertex(tx + cos(normalAngle) * offset, ty + sin(normalAngle) * offset);
    }
  }
  endShape(CLOSE);
}

/**
 * Harmonic function maintaining point-symmetry at t=0.5.
 */
function calculateSpiral(t, morph) {
  let amp = HEX_RADIUS * SPIRAL_INTENSITY * morph;
  let spiral = sin(t * TWO_PI);
  let harmonic = 0.2 * sin(t * 4 * PI);
  return (spiral + harmonic) * amp;
}
