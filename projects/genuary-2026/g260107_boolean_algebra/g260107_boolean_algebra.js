/**
 * XOR Interference Visualization (p5.js)
 * Two procedural 3D line patterns combined via XOR logic.
 * Parameterized for line thickness, rotation complexity, and color palettes.
 * Version: 2026.09.29.23.13.00
 */

// --- Canvas Parameters ---
let SKETCH_WIDTH = 480;       // Default: 480
let SKETCH_HEIGHT = 800;      // Default: 800
let PADDING = 40;             // Default: 40

// --- Animation Parameters ---
let MAX_FRAMES = 900;         // Default: 900
let SAVE_FRAMES = false;      // Default: false
let ANIMATION_SPEED = 30;     // Default: 30
let SEED_VALUE = 42;          // Default: 42
let TIME_STEP = 0.01;         // Default: 0.01

// --- Visual Tuning Parameters ---
let THICKNESS_RATIO = 0.86;   // Default: 0.86 (Higher = Thinner lines, 0.0 to 1.0)
let ROT_COMPLEXITY = 1.5;     // Default: 1.5 (Multiplies rotation speed/offset)
let PATTERN_SCALE_A = 28.0;   // Default: 28.0
let PATTERN_SCALE_B = 32.0;   // Default: 32.0
let SHOW_GRID = false;        // Default: false
let INVERT_COLORS = false;    // Default: false

// --- Color Palettes (Adobe Color) ---
// 5 curated palettes for generative visualization
const COLOR_PALETTES = [
  // 0: "Cyberpunk Neon" (Original Sketch Theme)
  ["#0B0D17", "#00FFC5", "#0072FF", "#FF0072", "#FFFFFF"],
  // 1: "Nordic Aurora"
  ["#1A1C23", "#5E81AC", "#88C0D0", "#A3BE8C", "#ECEFF4"],
  // 2: "Solarized Sunset"
  ["#101018", "#F39C12", "#E74C3C", "#9B59B6", "#ECF0F1"],
  // 3: "Deep Forest Emerald"
  ["#0A140F", "#2ECC71", "#27AE60", "#F1C40F", "#E8F8F5"],
  // 4: "Monochrome Precision"
  ["#111111", "#444444", "#888888", "#CCCCCC", "#FFFFFF"]
];

let PALETTE_INDEX = 0;        // Default: 0 (Choose active palette: 0 to 4)
let BG_COLOR_INDEX = 0;       // Default: 0 (Palette index for background)
let FG_COLOR_INDEX = 1;       // Default: 1 (Palette index for primary foreground)
let ACCENT_COLOR_INDEX = 3;   // Default: 3 (Palette index for accent)

let xorShader;
let timeVar = 0;

// Vertex Shader Source
const vertSource = `
  precision highp float;
  attribute vec3 aPosition;
  attribute vec2 aTexCoord;
  varying vec2 vTexCoord;

  void main() {
    vTexCoord = aTexCoord;
    vec4 positionVec4 = vec4(aPosition, 1.0);
    positionVec4.xy = positionVec4.xy * 2.0 - 1.0;
    gl_Position = positionVec4;
  }
`;

// Fragment Shader Source
const fragSource = `
  precision highp float;
  varying vec2 vTexCoord;

  uniform vec2 u_resolution;
  uniform float u_time;
  uniform float u_padding;
  uniform float u_showGrid;
  uniform float u_colorMode;
  uniform float u_thickness;
  uniform float u_rotComp;
  uniform float u_scaleA;
  uniform float u_scaleB;
  uniform vec3 u_bgColor;
  uniform vec3 u_fgColor;
  uniform vec3 u_accentColor;

  float getPattern(vec2 uv, float rotation, float scale) {
    float s = sin(rotation);
    float c = cos(rotation);
    mat2 rot = mat2(c, -s, s, c);
    vec2 st = uv * rot;
    vec2 grid = abs(sin(st * scale));
    return step(u_thickness, max(grid.x, grid.y));
  }

  void main() {
    // Pixel coordinate handling with padding compensation
    vec2 pixelCoord = gl_FragCoord.xy;
    vec2 paddedRes = u_resolution - vec2(u_padding * 2.0);
    vec2 uv = (pixelCoord - vec2(u_padding)) / paddedRes;

    // Pattern A & B logic using Rotation Complexity
    float patA = getPattern(uv - 0.5, u_time * 0.4 * u_rotComp, u_scaleA);
    float patB = getPattern(uv - 0.5, -u_time * 0.2 * u_rotComp + (u_rotComp * 0.5), u_scaleB);

    float xor = abs(patA - patB);

    if (u_showGrid > 0.5) {
      float g = step(0.995, fract(uv.x * 20.0)) + step(0.995, fract(uv.y * 20.0));
      xor = max(xor, g * 0.3);
    }

    vec3 finalColor = mix(u_bgColor, u_fgColor, xor);
    if (u_colorMode > 0.5) {
      finalColor = mix(u_fgColor, u_bgColor, xor);
    }

    gl_FragColor = vec4(finalColor, 1.0);
  }
`;

// Helper: Convert HEX string (#RRGGBB) to normalized RGB float array [0..1]
function hexToRgbNormalized(hex) {
  let cleanHex = hex.replace("#", "");
  let r = parseInt(cleanHex.substring(0, 2), 16) / 255.0;
  let g = parseInt(cleanHex.substring(2, 4), 16) / 255.0;
  let b = parseInt(cleanHex.substring(4, 6), 16) / 255.0;
  return [r, g, b];
}

function setup() {
  createCanvas(SKETCH_WIDTH, SKETCH_HEIGHT, WEBGL);
  randomSeed(SEED_VALUE);
  frameRate(ANIMATION_SPEED);
  pixelDensity(1);

  xorShader = createShader(vertSource, fragSource);
}

function draw() {
  let activePalette = COLOR_PALETTES[PALETTE_INDEX % COLOR_PALETTES.length];
  let bgHex = activePalette[BG_COLOR_INDEX % activePalette.length];
  let fgHex = activePalette[FG_COLOR_INDEX % activePalette.length];
  let accentHex = activePalette[ACCENT_COLOR_INDEX % activePalette.length];

  let bgRgb = hexToRgbNormalized(bgHex);
  let fgRgb = hexToRgbNormalized(fgHex);
  let accentRgb = hexToRgbNormalized(accentHex);

  if (INVERT_COLORS) {
    background(color(fgHex));
  } else {
    background(color(bgHex));
  }

  timeVar += TIME_STEP;

  shader(xorShader);

  // Pass Uniforms to Shader
  xorShader.setUniform("u_resolution", [float(width), float(height)]);
  xorShader.setUniform("u_time", timeVar);
  xorShader.setUniform("u_padding", float(PADDING));
  xorShader.setUniform("u_showGrid", SHOW_GRID ? 1.0 : 0.0);
  xorShader.setUniform("u_colorMode", INVERT_COLORS ? 1.0 : 0.0);
  xorShader.setUniform("u_thickness", THICKNESS_RATIO);
  xorShader.setUniform("u_rotComp", ROT_COMPLEXITY);
  xorShader.setUniform("u_scaleA", PATTERN_SCALE_A);
  xorShader.setUniform("u_scaleB", PATTERN_SCALE_B);
  xorShader.setUniform("u_bgColor", bgRgb);
  xorShader.setUniform("u_fgColor", fgRgb);
  xorShader.setUniform("u_accentColor", accentRgb);

  // Render centered rectangular viewport
  let innerW = width - (PADDING * 2);
  let innerH = height - (PADDING * 2);
  rectMode(CENTER);
  rect(0, 0, innerW, innerH);

  resetShader();

  if (SAVE_FRAMES) {
    saveCanvas(`frames/frame_${nf(frameCount, 4)}`, "png");
    if (frameCount >= MAX_FRAMES) {
      noLoop();
    }
  }
}
