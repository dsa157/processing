/**
 * Network Yellow - Interactive Attractor Particle Network
 * Version: 2026.10.04.15.50.00
 * 
 * Description:
 * A constellation network of interconnected particles transitioning between target states.
 * A simulated moving attractor orb pulls nearby nodes inward, shifting their color and
 * dynamically reconfiguring the luminous proximity web.
 * 
 * Converted from Processing (Java) to p5.js.
 */

// --- Canvas & Rendering Parameters ---
let SKETCH_WIDTH = 800;                 // default: 800 (requested: 800, original pde: 480)
let SKETCH_HEIGHT = 800;                // default: 800
let ANIMATION_SPEED = 30;               // default: 30 (fps)
let MAX_FRAMES = 600;                   // default: 600
let SAVE_FRAMES = false;                // default: false

// --- Seed for Random Reproducibility ---
let GLOBAL_SEED = 12345;                // default: 12345 (seed from original pde)

// --- Network & Particle Parameters ---
let LINE_DISTANCE = 120;                // default: 120
let LINE_WEIGHT = 1.0;                  // default: 1.0
let DOT_COUNT = 250;                    // default: 250
let DOT_SIZE = 5;                       // default: 5
let DOT_ALPHA = 200;                    // default: 200
let DOT_LERP_SPEED = 0.05;              // default: 0.05
let COLOR_LERP_SPEED = 0.1;             // default: 0.1
let TARGET_REACHED_THRESHOLD = 1.0;     // default: 1.0
let TRANSITION_INTERVAL_FRAMES = 300;   // default: 200 (formerly CHANGE_WORD_FRAMES)

// --- Attractor (Simulated Mouse) Parameters ---
let MOUSE_INFLUENCE_RADIUS = 150;       // default: 150
let MOUSE_FORCE_STRENGTH = 5;           // default: 5
let SIMULATED_MOUSE_X_RADIUS = 100;     // default: 100
let SIMULATED_MOUSE_Y_RADIUS = 200;     // default: 200
let SIMULATED_MOUSE_SPEED = 0.02;       // default: 0.02

// --- Color Palettes (Curated from Adobe Kuler / Color Themes) ---
// Each palette contains 5 colors: [Background, Primary Node, Attracted Accent, Secondary Accent, Highlight]
const PALETTES = [
  // Palette 0: "Network Yellow" (Original Processing Theme)
  ["#000000", "#96C8FF", "#FFFF00", "#00E5FF", "#FFFFA0"],
  // Palette 1: "Cyberpunk Neon" (Midnight Obsidian with Hot Fuchsia & Electric Cyan)
  ["#0B0C10", "#45A29E", "#FF007F", "#66FCF1", "#FFE600"],
  // Palette 2: "Deep Ocean Trench" (Abyssal Navy with Bioluminescent Amber)
  ["#03071E", "#0077B6", "#FFBA08", "#00B4D8", "#F48C06"],
  // Palette 3: "Toxic Meadow" (Deep Forest with Vibrant Neon Lime)
  ["#0A140D", "#38B000", "#CCFF00", "#70E000", "#007200"],
  // Palette 4: "Solar Flare" (Dark Espresso with Radiant Sunburst Orange)
  ["#1A0B00", "#FF5400", "#FFDD00", "#FF0054", "#9E0059"]
];

let PALETTE_INDEX = 0;                  // default: 0 (Network Yellow)
let BACKGROUND_COLOR_INDEX = 0;         // default: 0
let DOT_COLOR_INDEX = 1;                // default: 1
let ATTRACTED_COLOR_INDEX = 2;          // default: 2

// --- Runtime State ---
let currentDots = [];
let targetDots = [];
let originalColor;
let attractedColor;
let simulatedMouse;
let angle = 0;

function setup() {
  createCanvas(SKETCH_WIDTH, SKETCH_HEIGHT);
  frameRate(ANIMATION_SPEED);
  randomSeed(GLOBAL_SEED);
  noiseSeed(GLOBAL_SEED);

  applyPalette(PALETTE_INDEX);
  simulatedMouse = createVector(width / 2, height / 2);

  createDots(currentDots);
  createDots(targetDots);
}

function applyPalette(index) {
  let activePalette = PALETTES[index % PALETTES.length];
  originalColor = color(activePalette[DOT_COLOR_INDEX]);
  attractedColor = color(activePalette[ATTRACTED_COLOR_INDEX]);
}

function draw() {
  let activePalette = PALETTES[PALETTE_INDEX % PALETTES.length];
  background(activePalette[BACKGROUND_COLOR_INDEX]);

  // Update attractor position (simulated Lissajous orbit)
  simulatedMouse.x = width / 2 + cos(angle) * SIMULATED_MOUSE_X_RADIUS;
  simulatedMouse.y = height / 2 + sin(angle) * SIMULATED_MOUSE_Y_RADIUS;
  angle += SIMULATED_MOUSE_SPEED;

  // Update dots, attractor influence, and colors
  for (let i = 0; i < currentDots.length; i++) {
    let d = currentDots[i];
    let t = targetDots[i];

    let distVec = p5.Vector.sub(d.pos, simulatedMouse);
    let d_dist = distVec.mag();

    if (d_dist < MOUSE_INFLUENCE_RADIUS) {
      let strength = map(d_dist, 0, MOUSE_INFLUENCE_RADIUS, MOUSE_FORCE_STRENGTH, 0);
      distVec.normalize();
      distVec.mult(strength);
      d.pos.sub(distVec); // Change here: subtract to attract
      d.setTargetColor(attractedColor);
    } else {
      d.setTargetColor(originalColor);
    }

    d.dotColor = lerpColor(d.dotColor, d.targetColor, COLOR_LERP_SPEED);
    d.lerpTo(t, DOT_LERP_SPEED);
    d.display();
  }

  // Draw connecting constellation lines
  noFill();
  strokeWeight(LINE_WEIGHT);
  for (let i = 0; i < currentDots.length; i++) {
    let d1 = currentDots[i];
    let p1 = d1.pos;
    for (let j = i + 1; j < currentDots.length; j++) {
      let d2 = currentDots[j];
      let p2 = d2.pos;
      let d = p5.Vector.dist(p1, p2);
      if (d < LINE_DISTANCE) {
        let lineColor = lerpColor(d1.dotColor, d2.dotColor, 0.5);
        let alphaVal = map(d, 0, LINE_DISTANCE, 255, 0);
        let strokeCol = color(lineColor);
        strokeCol.setAlpha(alphaVal);
        stroke(strokeCol);
        line(p1.x, p1.y, p2.x, p2.y);
      }
    }
  }

  // Transition check when particles settle or timer elapses
  let allDotsReached = true;
  for (let i = 0; i < currentDots.length; i++) {
    if (p5.Vector.dist(currentDots[i].pos, targetDots[i].pos) > TARGET_REACHED_THRESHOLD) {
      allDotsReached = false;
      break;
    }
  }

  if (allDotsReached || (frameCount % TRANSITION_INTERVAL_FRAMES === 0)) {
    transitionToNewTargets();
  }

  // Frame saving support
  if (SAVE_FRAMES) {
    saveCanvas(`frames/frame-${nf(frameCount, 4)}`, 'png');
    if (frameCount >= MAX_FRAMES) {
      noLoop();
    }
  }
}

function transitionToNewTargets() {
  createDots(targetDots);
}

function mouseClicked() {
  transitionToNewTargets();
}

function keyPressed() {
  // Creative controls: Spacebar or 'P' to cycle color palettes
  if (key === ' ' || keyCode === 32 || key === 'p' || key === 'P') {
    PALETTE_INDEX = (PALETTE_INDEX + 1) % PALETTES.length;
    applyPalette(PALETTE_INDEX);
    return false; // Prevent page scroll on spacebar
  }
}

function createDots(dots) {
  dots.length = 0;
  for (let i = 0; i < DOT_COUNT; i++) {
    let x = random(width);
    let y = random(height);
    dots.push(new Dot(createVector(x, y)));
  }
}

class Dot {
  constructor(_pos) {
    this.pos = _pos.copy();
    this.dotColor = color(originalColor);
    this.targetColor = color(originalColor);
  }

  setTargetColor(newColor) {
    this.targetColor = color(newColor);
  }

  lerpTo(target, amount) {
    this.pos.lerp(target.pos, amount);
  }

  display() {
    noStroke();
    let col = color(this.dotColor);
    col.setAlpha(DOT_ALPHA);
    fill(col);
    ellipse(this.pos.x, this.pos.y, DOT_SIZE * 2, DOT_SIZE * 2);
    //fill(dotColor, 100);
    //ellipse(pos.x, pos.y, dotSize * 5, dotSize * 5);
  }
}
