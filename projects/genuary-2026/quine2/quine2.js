/*
 * Flow Field Syntax (Quine) - p5.js version
 * Version: 2026.09.30.16.50.43
 * A self-referential visualization where the source code characters 
 * follow a 2D Perlin noise flow field.
 */

// --- Parameters ---
let SKETCH_WIDTH = 800;       // Default: 480
let SKETCH_HEIGHT = 800;      // Default: 800
let PADDING = 40;             // Default: 40
let SEED = 42;                // Default: 42
let MAX_FRAMES = 900;         // Default: 900
let SAVE_FRAMES = false;      // Default: false
let ANIMATION_SPEED = 30;     // Default: 30
let INVERT_BG = false;        // Default: false
let SHOW_GRID = false;        // Default: false

// Flow Field Parameters
let NOISE_SCALE = 0.008;      // Default: 0.008
let TIME_STEP = 0.015;        // Default: 0.015
let CHAR_SPACING = 14;        // Default: 14
let TXT_SIZE = 12;            // Default: 12

// Color Management - Adobe Kuler / Color Palettes
let PALETTE_INDEX = 2;        // Default: 0
const PALETTES = [
  ['#0D1B2A', '#1B263B', '#415A77', '#778DA9', '#E0E1DD'], // Deep Space
  ['#264653', '#2A9D8F', '#E9C46A', '#F4A261', '#E76F51'], // Adobe Natural
  ['#2B2D42', '#8D99AE', '#EDF2F4', '#EF233C', '#D90429'], // High Contrast
  ['#1A535C', '#4ECDC4', '#F7FFF7', '#FF6B6B', '#E66DFF'], // Modern Pop
  ['#000000', '#333333', '#666666', '#999999', '#FFFFFF']  // Grayscale
];

// Global Data
let content = "function setup(){createCanvas(480,800);frameRate(30);randomSeed(42);noiseSeed(42);}function draw(){background(0);let n=noise(x,y,z);push();rotate(n);text(c,0,0);pop();}";
let zOffset = 0;
let glyphCache = {};
let cachedPaletteIndex = -1;
let glyphCanvasSize = 0;

// Pre-render glyph textures to offscreen canvases to eliminate font engine bottlenecks
function buildGlyphCache() {
  glyphCache = {};
  let activePalette = PALETTES[PALETTE_INDEX];
  glyphCanvasSize = CHAR_SPACING * 2;
  let halfSize = glyphCanvasSize / 2;

  let uniqueChars = new Set(content.split(''));
  for (let c of uniqueChars) {
    glyphCache[c] = [];
    for (let col = 0; col < activePalette.length; col++) {
      let offCanvas = document.createElement('canvas');
      offCanvas.width = glyphCanvasSize;
      offCanvas.height = glyphCanvasSize;
      let offCtx = offCanvas.getContext('2d');
      offCtx.font = `${TXT_SIZE}px sans-serif`;
      offCtx.textAlign = 'center';
      offCtx.textBaseline = 'middle';
      offCtx.fillStyle = activePalette[col];
      offCtx.fillText(c, halfSize, halfSize);
      glyphCache[c][col] = offCanvas;
    }
  }
  cachedPaletteIndex = PALETTE_INDEX;
}

function setup() {
  let cnv = createCanvas(SKETCH_WIDTH, SKETCH_HEIGHT);
  cnv.style('display', 'block');
  cnv.style('position', 'absolute');
  cnv.style('left', '50%');
  cnv.style('top', '50%');
  cnv.style('transform', 'translate(-50%, -50%)');
  
  frameRate(ANIMATION_SPEED);
  randomSeed(SEED);
  noiseSeed(SEED);

  buildGlyphCache();
}

function draw() {
  if (cachedPaletteIndex !== PALETTE_INDEX) {
    buildGlyphCache();
  }

  let activePalette = PALETTES[PALETTE_INDEX];
  let ctx = drawingContext;

  // Handle background selection and inversion
  let bgHex = INVERT_BG ? activePalette[activePalette.length - 1] : activePalette[0];
  background(bgHex);

  // Calculate centering logic
  let availableWidth = width - (PADDING * 2);
  let availableHeight = height - (PADDING * 2);

  let cols = floor(availableWidth / CHAR_SPACING);
  let rows = floor(availableHeight / CHAR_SPACING);

  let xStart = PADDING + (availableWidth - (cols * CHAR_SPACING)) / 2.0;
  let yStart = PADDING + (availableHeight - (rows * CHAR_SPACING)) / 2.0;

  let charCounter = 0;
  let halfSpacing = CHAR_SPACING / 2.0;
  let halfGlyph = glyphCanvasSize / 2.0;
  let numPaletteColors = activePalette.length;
  let contentLen = content.length;

  for (let j = 0; j < rows; j++) {
    for (let i = 0; i < cols; i++) {
      let x = xStart + i * CHAR_SPACING + halfSpacing;
      let y = yStart + j * CHAR_SPACING + halfSpacing;

      // Calculate Noise
      let n = noise(x * NOISE_SCALE, y * NOISE_SCALE, zOffset);
      let angle = n * TWO_PI * 4.0;

      // Select text color (avoiding background index)
      let colIdx = floor(map(n, 0, 1, 1, numPaletteColors));
      colIdx = constrain(colIdx, 0, numPaletteColors - 1);

      // Draw grid if enabled
      if (SHOW_GRID) {
        ctx.strokeStyle = activePalette[2];
        ctx.strokeRect(x - halfSpacing, y - halfSpacing, CHAR_SPACING, CHAR_SPACING);
      }

      // Fast affine matrix transform
      let cosA = Math.cos(angle);
      let sinA = Math.sin(angle);
      ctx.setTransform(cosA, sinA, -sinA, cosA, x, y);

      // GPU-accelerated blit from pre-rendered glyph cache
      let c = content.charAt(charCounter % contentLen);
      let glyph = glyphCache[c] ? glyphCache[c][colIdx] : null;
      if (glyph) {
        ctx.drawImage(glyph, -halfGlyph, -halfGlyph);
      }

      charCounter++;
    }
  }

  // Reset canvas transform matrix to identity
  ctx.setTransform(1, 0, 0, 1, 0, 0);

  zOffset += TIME_STEP;

  // Save/Stop Logic
  if (SAVE_FRAMES) {
    saveCanvas(`frame_${nf(frameCount, 4)}`, 'png');
    if (frameCount >= MAX_FRAMES) {
      noLoop();
    }
  }
}
