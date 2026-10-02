/*
 * Kinetic Raster Clock
 * Version: 2026.10.02.18.33.00
 * Description: Kinetic raster clock displaying current time on a grid of morphing pulsing glyphs,
 * transitioning between chaos and coherent time display. Converted from Processing (Java) to p5.js.
 * Fixes: Guaranteed visibility of background cells at clock peak.
 * Optimized phase transition and persistent grid properties.
 */

// --- Parameters ---
let SKETCH_WIDTH = 480;         // Default: 800 (converted from 480)
let SKETCH_HEIGHT = 800;        // Default: 800
let MAX_FRAMES = 900;           // Default: 900
let SAVE_FRAMES = false;        // Default: false
let ANIMATION_SPEED = 30;       // Default: 30
let GLOBAL_SEED = 42;           // Default: 42
let PADDING = 40;               // Default: 40

let GRID_COLS = 11;             // User Adjusted: 11
let GRID_ROWS = 25;             // User Adjusted: 25
let SHOW_GRID = false;          // Default: true
let GRID_OVERLAY_ALPHA = 40;    // Default: 40
let GRID_OVERLAY_STROKE_WEIGHT = 0.5; // Default: 0.5

let USE_24H = false;            // Default: false
let PALETTE_INDEX = 1;          // User Adjusted: 1
let INVERT_BG = false;          // Default: false

let MIN_PULSE_SPD = 0.15;       // User Adjusted: 0.15
let MAX_PULSE_SPD = 0.25;       // User Adjusted: 0.25
let MAX_GLYPH_SIZE_MULT = 0.65; // User Adjusted: 0.65
let MIN_GLYPH_SIZE_MULT = 0.1;  // Default: 0.1
let PHASE_DIVERSITY = 1.0;      // Default: 1.0
let GUTTER = 1;                 // Gap between digits

// Glyph Style Parameters
// Styles: 0:Solid Dot, 1:Ring, 2:Target, 3:Radar, 4:Flower
let GLYPH_STYLE = 0;            // Default: 0
let CYCLE_GLYPH_STYLE = true;   // Default: true
let RANDOM_BG_GLYPHS = true;    // Default: true

// Glyph Geometry Parameters
let RING_STROKE_WEIGHT_MIN = 0.5; // Default: 0.5
let RING_STROKE_WEIGHT_MAX = 2.0; // Default: 2.0
let TARGET_INNER_RATIO = 0.3;     // Default: 0.3
let TARGET_STROKE_WEIGHT = 0.5;   // Default: 0.5
let RADAR_STROKE_WEIGHT = 1.5;    // Default: 1.5
let RADAR_ROTATION_MULT = 0.5;    // Default: 0.5
let FLOWER_RINGS = 3;             // Default: 3
let FLOWER_STROKE_WEIGHT = 0.5;   // Default: 0.5
let MORPH_EXPONENT = 0.4;         // Default: 0.4

// Animation Toggles
let BG_COLOR_SHIFT = false;     // Default: false

// Alpha Parameters
let BG_ALPHA_CHAOS = 255;       // User Adjusted: 200, Default: 255
let BG_ALPHA_CLOCK = 20;        // User Adjusted: 140, Default: 20
let CLOCK_ALPHA_PEAK = 255;     // Default: 255

// Phase Timing (Seconds)
let DURATION_CHAOS = 10.0;      // User Adjusted: 10, Default: 10.0
let DURATION_CLOCK = 15.0;      // User Adjusted: 15, Default: 15.0

// Readable Font Dimensions
let FONT_COLS = 5;              // Default: 5
let FONT_ROWS = 7;              // Default: 7

// --- Readable Font Data (5x7) ---
const fontMatrix = [
  [ // 0
    [0, 1, 1, 1, 0],
    [1, 0, 0, 0, 1],
    [1, 0, 0, 0, 1],
    [1, 0, 0, 0, 1],
    [1, 0, 0, 0, 1],
    [1, 0, 0, 0, 1],
    [0, 1, 1, 1, 0]
  ],
  [ // 1
    [0, 0, 1, 0, 0],
    [0, 1, 1, 0, 0],
    [0, 0, 1, 0, 0],
    [0, 0, 1, 0, 0],
    [0, 0, 1, 0, 0],
    [0, 0, 1, 0, 0],
    [0, 1, 1, 1, 0]
  ],
  [ // 2
    [0, 1, 1, 1, 0],
    [1, 0, 0, 0, 1],
    [0, 0, 0, 0, 1],
    [0, 0, 0, 1, 0],
    [0, 0, 1, 0, 0],
    [0, 1, 0, 0, 0],
    [1, 1, 1, 1, 1]
  ],
  [ // 3
    [0, 1, 1, 1, 0],
    [1, 0, 0, 0, 1],
    [0, 0, 0, 0, 1],
    [0, 0, 1, 1, 0],
    [0, 0, 0, 0, 1],
    [1, 0, 0, 0, 1],
    [0, 1, 1, 1, 0]
  ],
  [ // 4
    [0, 0, 0, 1, 0],
    [0, 0, 1, 1, 0],
    [0, 1, 0, 1, 0],
    [1, 0, 0, 1, 0],
    [1, 1, 1, 1, 1],
    [0, 0, 0, 1, 0],
    [0, 0, 0, 1, 0]
  ],
  [ // 5
    [1, 1, 1, 1, 1],
    [1, 0, 0, 0, 0],
    [1, 1, 1, 1, 0],
    [0, 0, 0, 0, 1],
    [0, 0, 0, 0, 1],
    [1, 0, 0, 0, 1],
    [0, 1, 1, 1, 0]
  ],
  [ // 6
    [0, 1, 1, 1, 0],
    [1, 0, 0, 0, 0],
    [1, 1, 1, 1, 0],
    [1, 0, 0, 0, 1],
    [1, 0, 0, 0, 1],
    [1, 0, 0, 0, 1],
    [0, 1, 1, 1, 0]
  ],
  [ // 7
    [1, 1, 1, 1, 1],
    [0, 0, 0, 0, 1],
    [0, 0, 0, 1, 0],
    [0, 0, 1, 0, 0],
    [0, 1, 0, 0, 0],
    [1, 0, 0, 0, 0],
    [1, 0, 0, 0, 0]
  ],
  [ // 8
    [0, 1, 1, 1, 0],
    [1, 0, 0, 0, 1],
    [1, 0, 0, 0, 1],
    [0, 1, 1, 1, 0],
    [1, 0, 0, 0, 1],
    [1, 0, 0, 0, 1],
    [0, 1, 1, 1, 0]
  ],
  [ // 9
    [0, 1, 1, 1, 0],
    [1, 0, 0, 0, 1],
    [1, 0, 0, 0, 1],
    [0, 1, 1, 1, 1],
    [0, 0, 0, 0, 1],
    [1, 0, 0, 0, 1],
    [0, 1, 1, 1, 0]
  ]
];

// Color Palettes from Adobe Color (Kuler)
// 0: "Deep Blues"  - Electric Blue, Royal Blue, Sky Blue, Vivid Orange, Flame Orange
// 1: "Matrix"      - Charcoal, Slate Grey, Terminal Green, Matrix Green, Dark Forest
// 2: "Cyber Neon"  - Hot Pink, Crimson Rose, Mint Turquoise, Aqua Blue, Electric Blue
// 3: "Campfire"    - Deep Plum, Crimson Red, Blaze Orange, Amber Glow, Deep Teal
// 4: "Monochrome"  - Pure White, Light Silver, Medium Grey, Dark Slate, Charcoal Black
const PALETTES = [
  ["#0511F2", "#0524F2", "#0787F2", "#F27405", "#F24405"],
  ["#1A1A1A", "#4E4E4E", "#00FF41", "#008F11", "#003B00"],
  ["#F20587", "#F20544", "#05F292", "#05F2DB", "#0587F2"],
  ["#2E0927", "#D90000", "#FF2D00", "#FF8C00", "#04756F"],
  ["#FFFFFF", "#CCCCCC", "#999999", "#666666", "#333333"]
];

// --- Internal Variables ---
let cellW, cellH;
let bgColor, accentColor, altColor;
let digitBoxW, digitBoxH;
let activeCells;
let pulsePhases;
let pulseSpeeds;
let cellGlyphStyles;

function setup() {
  createCanvas(SKETCH_WIDTH, SKETCH_HEIGHT);
  pixelDensity(1);
  randomSeed(GLOBAL_SEED);
  frameRate(ANIMATION_SPEED);

  cellW = (width - 2 * PADDING) / GRID_COLS;
  cellH = (height - 2 * PADDING) / GRID_ROWS;
  digitBoxW = Math.floor((GRID_COLS - GUTTER) / 2);
  digitBoxH = Math.floor((GRID_ROWS - (2 * GUTTER)) / 3);

  updatePaletteColors();

  activeCells = Array.from({ length: GRID_COLS }, () => new Array(GRID_ROWS).fill(false));
  pulsePhases = Array.from({ length: GRID_COLS }, () => new Array(GRID_ROWS).fill(0));
  pulseSpeeds = Array.from({ length: GRID_COLS }, () => new Array(GRID_ROWS).fill(0));
  cellGlyphStyles = Array.from({ length: GRID_COLS }, () => new Array(GRID_ROWS).fill(0));

  for (let i = 0; i < GRID_COLS; i++) {
    for (let j = 0; j < GRID_ROWS; j++) {
      pulsePhases[i][j] = random(TWO_PI) * PHASE_DIVERSITY;
      pulseSpeeds[i][j] = random(MIN_PULSE_SPD, MAX_PULSE_SPD);
      cellGlyphStyles[i][j] = Math.floor(random(5));
    }
  }
}

function updatePaletteColors() {
  let activePalette = PALETTES[PALETTE_INDEX];
  if (INVERT_BG) {
    bgColor = color(255);
    accentColor = color(activePalette[0]);
    altColor = color(activePalette[3]);
  } else {
    bgColor = color(activePalette[0]);
    accentColor = color(activePalette[2]);
    altColor = color(activePalette[4]);
  }
}

function draw() {
  background(bgColor);
  for (let i = 0; i < GRID_COLS; i++) {
    for (let j = 0; j < GRID_ROWS; j++) {
      activeCells[i][j] = false;
    }
  }

  updateTimeGrid();

  let totalCycleTime = DURATION_CLOCK + DURATION_CHAOS;
  let currentTime = (millis() / 1000.0) % totalCycleTime;

  let t;
  if (currentTime < DURATION_CLOCK) {
    let normVal = currentTime / DURATION_CLOCK;
    t = (1.0 + cos(normVal * PI)) / 2.0;
  } else {
    let normVal = (currentTime - DURATION_CLOCK) / DURATION_CHAOS;
    t = (1.0 - cos(normVal * PI)) / 2.0;
  }

  renderGrid(t);

  if (SHOW_GRID) drawGridOverlay();

  if (SAVE_FRAMES) {
    saveCanvas('frame-' + nf(frameCount, 4), 'png');
    if (frameCount >= MAX_FRAMES) noLoop();
  }
}

function updateTimeGrid() {
  let hRaw = hour();
  if (!USE_24H) {
    hRaw = hRaw % 12;
    if (hRaw === 0) hRaw = 12;
  }
  let timeStr = nf(hRaw, 2) + nf(minute(), 2) + nf(second(), 2);
  let startX = Math.floor((GRID_COLS - (2 * digitBoxW + GUTTER)) / 2);
  let startY = Math.floor((GRID_ROWS - (3 * digitBoxH + 2 * GUTTER)) / 2);

  for (let i = 0; i < 6; i++) {
    let val = parseInt(timeStr.charAt(i), 10);
    let offsetX = startX + ((i % 2) * (digitBoxW + GUTTER));
    let offsetY = startY + (Math.floor(i / 2) * (digitBoxH + GUTTER));
    let sX = Math.floor((digitBoxW - FONT_COLS) / 2);
    let sY = Math.floor((digitBoxH - FONT_ROWS) / 2);
    for (let r = 0; r < FONT_ROWS; r++) {
      for (let c = 0; c < FONT_COLS; c++) {
        if (fontMatrix[val][r][c] === 1) {
          let gx = offsetX + sX + c;
          let gy = offsetY + startY + r;
          if (gx >= 0 && gx < GRID_COLS && gy >= 0 && gy < GRID_ROWS) {
            activeCells[gx][gy] = true;
          }
        }
      }
    }
  }
}

function renderGrid(t) {
  ellipseMode(CENTER);
  let maxD = cellW * MAX_GLYPH_SIZE_MULT;

  // Background alpha is always calculated
  let currentBgAlpha = Math.floor(lerp(BG_ALPHA_CHAOS, BG_ALPHA_CLOCK, t));

  for (let i = 0; i < GRID_COLS; i++) {
    for (let j = 0; j < GRID_ROWS; j++) {
      let cx = PADDING + i * cellW + cellW / 2;
      let cy = PADDING + j * cellH + cellH / 2;

      pulsePhases[i][j] += pulseSpeeds[i][j];
      let n = (sin(pulsePhases[i][j]) + 1) / 2.0;

      let drawColor = activeCells[i][j] ? accentColor : (BG_COLOR_SHIFT ? lerpColor(accentColor, altColor, t) : accentColor);

      if (activeCells[i][j]) {
        // Morphing logic for clock cells: Style 0 (Stationary) vs Chaos Style
        let chaosStyle = RANDOM_BG_GLYPHS ? cellGlyphStyles[i][j] : GLYPH_STYLE;
        let clockAlpha = Math.floor(lerp(BG_ALPHA_CHAOS, CLOCK_ALPHA_PEAK, t));

        // Use a power curve for morphing back to chaos faster
        let morphT = (t < 0.5) ? Math.pow(t * 2, MORPH_EXPONENT) : 1.0;

        if (t < 1.0) {
          // Morphing between Chaos Style and Clock Style 0
          drawGlyph(cx, cy, n, t, true, Math.floor(clockAlpha * (1.0 - morphT)), maxD, chaosStyle, drawColor);
          drawGlyph(cx, cy, n, t, true, Math.floor(clockAlpha * morphT), maxD, 0, drawColor);
        } else {
          drawGlyph(cx, cy, n, t, true, CLOCK_ALPHA_PEAK, maxD, 0, drawColor);
        }
      } else {
        // Background stays Background
        let bgStyle = RANDOM_BG_GLYPHS ? cellGlyphStyles[i][j] : GLYPH_STYLE;
        drawGlyph(cx, cy, n, t, false, currentBgAlpha, maxD, bgStyle, drawColor);
      }
    }
  }
}

function drawGlyph(x, y, n, clockT, active, alphaVal, maxD, style, c) {
  if (alphaVal <= 0) return;
  push();
  translate(x, y);
  stroke(red(c), green(c), blue(c), alphaVal);
  fill(red(c), green(c), blue(c), alphaVal);

  // Size logic: background pulses, active clock cells lock to maxD at peak
  let pulseSize = lerp(cellW * MIN_GLYPH_SIZE_MULT, maxD, n);
  let finalSize = active ? lerp(pulseSize, maxD, clockT) : pulseSize;

  switch (style) {
    case 0:
      noStroke();
      ellipse(0, 0, finalSize, finalSize);
      break;
    case 1:
      noFill();
      strokeWeight(lerp(RING_STROKE_WEIGHT_MIN, RING_STROKE_WEIGHT_MAX, clockT));
      ellipse(0, 0, finalSize, finalSize);
      break;
    case 2:
      noStroke();
      ellipse(0, 0, finalSize * TARGET_INNER_RATIO, finalSize * TARGET_INNER_RATIO);
      noFill();
      strokeWeight(TARGET_STROKE_WEIGHT);
      ellipse(0, 0, finalSize, finalSize);
      break;
    case 3: {
      noFill();
      strokeWeight(RADAR_STROKE_WEIGHT);
      let colIdx = ((Math.floor(x / cellW) % GRID_COLS) + GRID_COLS) % GRID_COLS;
      let rowIdx = ((Math.floor(y / cellH) % GRID_ROWS) + GRID_ROWS) % GRID_ROWS;
      rotate(pulsePhases[colIdx][rowIdx] * RADAR_ROTATION_MULT);
      arc(0, 0, finalSize, finalSize, 0, HALF_PI);
      break;
    }
    case 4:
      noFill();
      strokeWeight(FLOWER_STROKE_WEIGHT);
      for (let i = 1; i <= FLOWER_RINGS; i++) {
        let s = finalSize * (i / FLOWER_RINGS);
        ellipse(0, 0, s, s);
      }
      break;
  }
  pop();
}

function drawGridOverlay() {
  stroke(red(accentColor), green(accentColor), blue(accentColor), GRID_OVERLAY_ALPHA);
  strokeWeight(GRID_OVERLAY_STROKE_WEIGHT);
  for (let i = 0; i <= GRID_COLS; i++) {
    line(PADDING + i * cellW, PADDING, PADDING + i * cellW, height - PADDING);
  }
  for (let j = 0; j <= GRID_ROWS; j++) {
    line(PADDING, PADDING + j * cellH, width - PADDING, PADDING + j * cellH);
  }
}
