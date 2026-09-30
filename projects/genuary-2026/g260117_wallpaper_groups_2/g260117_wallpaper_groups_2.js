/**
 * Scalene Wallpaper Group Morpher - Offset Edition
 * Version: 2026.09.30.12.31.50
 * Fixed p1 vs pg ambiguity by offsetting the motif from the cell center.
 */

// --- Parameters ---
let SKETCH_WIDTH = 800;        // default: 480 - Canvas width
let SKETCH_HEIGHT = 800;       // default: 800 - Canvas height
let PADDING = 40;              // default: 40 - Outer padding
let MAX_FRAMES = 1200;         // default: 1200 - Frame limit
let SAVE_FRAMES = false;       // default: false - Whether to save frames
let ANIMATION_SPEED = 60;      // default: 60 - Target framerate
let SEED = 777;                // default: 777 - Random seed for reproducibility
let INVERT_BACKGROUND = false; // default: false - Invert palette background and foreground
let PALETTE_INDEX = 1;         // default: 1 - Active palette index (0-4)

// --- Group Selection ---
let GROUPS_TO_INCLUDE_TEST = ["p1", "pg", "p2", "pm", "p4m", "p6m"]; // Limited for testing fix
let GROUPS_TO_INCLUDE = [
  "p1", "p2", "pg", "pm", "cm", "pmm", "pmg", "cmm", "p4",
  "pgg", "p4g", "p4m", "p3", "p6", "p3m1", "p6m", "p31m"
];

// --- Visual Customization ---
let ENABLE_BLUR = true;            // default: true - Enable trailing blur
let BLUR_STRENGTH = 35;            // default: 35 - Blur alpha amount (0-255)
let INTERPOLATE_COLOR = false;     // default: false - Color transition interpolation
let FONT_NAME = "Arial Black";     // default: "Arial Black" - Label font family
let FONT_SIZE = 145;               // default: 145 - Background label font size
let TEXT_Y_POS = 400;              // default: 400 - Y position for background labels
let TEXT_OPACITY = 10;             // default: 10 - Label opacity (0-255)
let CELL_SIZE = 140.0;             // default: 140.0 - Grid cell size in pixels
let TRANSITION_DURATION = 0.5;     // default: 0.5 - Morph duration in seconds
let HOLD_DURATION = 0.5;           // default: 0.5 - Hold state duration in seconds

// --- IMPORTANT FIX PARAMETER ---
let MOTIF_OFFSET = 25.0;           // default: 25.0 - Offsets the motif to reveal glide/mirror operations

// --- Color Palettes (Adobe Color / Kuler) ---
let PALETTES = [
  // 0: Deep Sea / Sandy Beach
  ["#264653", "#2a9d8f", "#e9c46a", "#f4a261", "#e76f51"],
  // 1: Deep Ocean Reef
  ["#001219", "#005f73", "#0a9396", "#94d2bd", "#e9d8a6"],
  // 2: Ruby Orange Glow
  ["#5f0f40", "#9a031e", "#fb8b24", "#e36414", "#0f4c5c"],
  // 3: Vintage Muted Mauve
  ["#22223b", "#4a4e69", "#9a8c98", "#c9ada7", "#f2e9e4"],
  // 4: Retro Bright Pop
  ["#118ab2", "#073b4c", "#06d6a0", "#ffd166", "#ef476f"]
];

// --- Internal State ---
let activeBG, activeStroke;
let states = [];
let currentIdx = 0, nextIdx = 1;
let progress = 0;

function setup() {
  createCanvas(SKETCH_WIDTH, SKETCH_HEIGHT);
  randomSeed(SEED);
  frameRate(ANIMATION_SPEED);

  let palette = PALETTES[PALETTE_INDEX];
  activeBG = INVERT_BACKGROUND ? palette[4] : palette[0];
  activeStroke = INVERT_BACKGROUND ? palette[0] : palette[4];

  states = [];

  let masterList = [
    ["p1", 1.0, 0.0, 0.0], ["p2", 2.0, 0.0, 0.0], ["pm", 1.0, 1.0, 0.0],
    ["pg", 1.0, 0.0, 1.0], ["cm", 1.0, 1.0, 0.5], ["pmm", 2.0, 1.0, 0.0],
    ["pmg", 2.0, 1.0, 0.5], ["pgg", 2.0, 0.0, 1.0], ["cmm", 2.0, 1.0, 1.0],
    ["p4", 4.0, 0.0, 0.0], ["p4m", 4.0, 1.0, 0.0], ["p4g", 4.0, 1.0, 0.5],
    ["p3", 3.0, 0.0, 0.0], ["p3m1", 3.0, 1.0, 0.0], ["p31m", 3.0, 1.0, 0.2],
    ["p6", 6.0, 0.0, 0.0], ["p6m", 6.0, 1.0, 0.0]
  ];

  for (let target of GROUPS_TO_INCLUDE) {
    for (let row of masterList) {
      if (target === row[0]) {
        states.push(new GroupState(row[0], row[1], row[2], row[3]));
      }
    }
  }
}

function draw() {
  if (ENABLE_BLUR) {
    let c = color(activeBG);
    c.setAlpha(BLUR_STRENGTH);
    fill(c);
    noStroke();
    rect(0, 0, width, height);
  } else {
    background(activeBG);
  }

  updateTimer();
  drawFadingLabels();

  let s1 = states[currentIdx];
  let s2 = states[nextIdx];

  let curRot = lerp(s1.folds, s2.folds, progress);
  let curMir = lerp(s1.mirror, s2.mirror, progress);
  let curGld = lerp(s1.glide, s2.glide, progress);

  let drawColor = activeStroke;
  if (INTERPOLATE_COLOR) {
    let p = PALETTES[PALETTE_INDEX];
    drawColor = lerpColor(color(p[1]), color(p[3]), progress);
  }

  let offsetX = (width % CELL_SIZE) / 2.0;
  let offsetY = (height % CELL_SIZE) / 2.0;

  push();
  translate(offsetX, offsetY);
  for (let x = -CELL_SIZE; x <= width + CELL_SIZE; x += CELL_SIZE) {
    for (let y = -CELL_SIZE; y <= height + CELL_SIZE; y += CELL_SIZE) {
      push();
      translate(x, y);
      drawGroup(curRot, curMir, curGld, drawColor);
      pop();
    }
  }
  pop();

  if (SAVE_FRAMES) {
    saveCanvas(`frames_${nf(frameCount, 4)}`, "png");
    if (frameCount >= MAX_FRAMES) noLoop();
  }
}

function updateTimer() {
  let total = TRANSITION_DURATION + HOLD_DURATION;
  let tCycle = (frameCount / ANIMATION_SPEED) % total;
  if (tCycle > HOLD_DURATION) {
    let t = (tCycle - HOLD_DURATION) / TRANSITION_DURATION;
    progress = 0.5 - 0.5 * cos(PI * t);
  } else {
    if (progress > 0.9) {
      currentIdx = nextIdx;
      nextIdx = (currentIdx + 1) % states.length;
    }
    progress = 0;
  }
}

function drawGroup(rot, mir, gld, c) {
  stroke(c);
  strokeWeight(2.5);
  for (let i = 0; i < 6; i++) {
    if (i < rot) {
      push();
      rotate(i * (TWO_PI / rot));

      // Base Motif with offset
      push();
      translate(MOTIF_OFFSET, 0);
      renderUnifiedMotif(c);
      pop();

      // Symmetrized Motif (Glide/Mirror)
      if (mir > 0.01 || gld > 0.01) {
        push();
        scale(mir > 0.01 ? -1 : 1, 1);
        translate(MOTIF_OFFSET, CELL_SIZE * gld * 0.5); // Glide is 0.5 shift
        renderUnifiedMotif(c);
        pop();
      }
      pop();
    }
  }
}

function renderUnifiedMotif(c) {
  let b = CELL_SIZE * 0.3;
  let x1 = 0, y1 = -b, x2 = -b * 0.4, y2 = b * 0.7, x3 = b * 0.9, y3 = b * 0.5;
  noFill();
  stroke(c);
  strokeWeight(2.5);
  triangle(x1, y1, x2, y2, x3, y3);
  fill(c);
  noStroke();
  ellipse(x1, y1, b * 0.3, b * 0.3);
}

function drawFadingLabels() {
  textFont(FONT_NAME);
  textSize(FONT_SIZE);
  textAlign(CENTER, CENTER);
  let alphaOut = (1.0 - progress) * TEXT_OPACITY;
  let alphaIn = progress * TEXT_OPACITY;

  let cOut = color(activeStroke);
  cOut.setAlpha(alphaOut);
  fill(cOut);
  noStroke();
  text(states[currentIdx].name.toUpperCase(), width / 2, TEXT_Y_POS);

  let cIn = color(activeStroke);
  cIn.setAlpha(alphaIn);
  fill(cIn);
  noStroke();
  text(states[nextIdx].name.toUpperCase(), width / 2, TEXT_Y_POS);
}

class GroupState {
  constructor(n, f, m, g) {
    this.name = n;
    this.folds = f;
    this.mirror = m;
    this.glide = g;
  }
}
