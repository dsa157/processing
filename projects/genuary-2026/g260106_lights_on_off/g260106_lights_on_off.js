/**
 * Luminance Flux - Glitch Edition (p5.js)
 * Version: 2026.09.29.23.02.09
 * 
 * Description:
 * An automated generative cycle between lights on and off states featuring
 * glitch transitions, particle physics, vector field flow, and geometric transformations.
 * 
 * Features:
 * - Automated light cycle with glitch transitions.
 * - Customizable particle size ranges.
 * - 5 Switchable color palettes (curated via Adobe Color / Kuler).
 * - Organic flow field (lights off) vs linear bouncing geometry (lights on).
 */

// --- Canvas & Layout Parameters ---
const SKETCH_WIDTH = 480;          // Default: 480
const SKETCH_HEIGHT = 800;         // Default: 800
const PADDING = 40;                // Default: 40
const SEED_VALUE = 42;             // Default: 42
const MAX_FRAMES = 900;            // Default: 900
const SAVE_FRAMES = false;         // Default: false
const ANIMATION_SPEED = 30;        // Default: 30
const SHOW_GRID = false;           // Default: false
const GRID_STEPS = 10;             // Default: 10

// --- Logic & Transition Parameters ---
const CYCLE_DURATION = 100;        // Default: 100
const LIGHT_TRANSITION = 0.1;      // Default: 0.1
const PARTICLE_COUNT = 1000;       // Default: 1000
const NOISE_SCALE = 0.006;         // Default: 0.006
const NOISE_TIME_SCALE = 0.005;    // Default: 0.005
const NOISE_FORCE_MULT = 0.2;      // Default: 0.2
const NOISE_ANGLE_MULT = 4.0;      // Default: 4.0
const GLITCH_STRENGTH = 1.0;       // Default: 1.0
const GLITCH_DECAY = 0.85;         // Default: 0.85
const GLITCH_THRESHOLD = 1.0;      // Default: 1.0
const GLITCH_LINE_COUNT = 5;       // Default: 5
const GLITCH_LINE_ALPHA = 100;     // Default: 100

// --- Particle Size & Physics Parameters ---
const MIN_SIZE = 15.0;             // Default: 15.0
const MAX_SIZE = 40.0;             // Default: 40.0
const MIN_VEL_SPEED = 2.0;         // Default: 2.0
const MAX_VEL_SPEED = 4.0;         // Default: 4.0
const MIN_MAX_SPEED = 3.0;         // Default: 3.0
const MAX_MAX_SPEED = 6.0;         // Default: 6.0
const SPEED_LIMIT_FACTOR = 0.6;    // Default: 0.6
const STROKE_WEIGHT_SQUARE = 1.5;  // Default: 1.5
const STROKE_WEIGHT_CIRCLE = 1.0;  // Default: 1.0
const CENTER_DOT_SIZE = 2.0;       // Default: 2.0
const ALPHA_MIN = 150;             // Default: 150
const ALPHA_MAX = 255;             // Default: 255
const FILL_ALPHA_OFF = 40;         // Default: 40
const CENTER_DOT_ALPHA = 200;      // Default: 200

// --- 5 Color Palettes (Curated Adobe Color / Kuler) ---
const PALETTES = [
  // 0: Cyber Dusk
  ["#0B0D17", "#FFD700", "#00F5FF", "#F0F0F0", "#BF00FF"],
  // 1: Retro Sunset
  ["#2D3047", "#FF9F1C", "#FFBF69", "#FFFFFF", "#2EC4B6"],
  // 2: Neon Matrix
  ["#1A1A1A", "#70E000", "#38B000", "#FFFFFF", "#008000"],
  // 3: Nordic Frost
  ["#1E222A", "#61AFEF", "#98C379", "#E5C07B", "#E06C75"],
  // 4: Electric Violet
  ["#120136", "#035AA6", "#40BAD5", "#F2F4F7", "#FC3D99"]
];

// Active Palette & Color Index Selectors
const PALETTE_INDEX = 2;           // Default: 2 (Neon Matrix)
const BG_DARK_INDEX = 0;           // Default: 0
const BG_LIGHT_INDEX = 3;          // Default: 3
const GLITCH_COLOR_INDEX = 2;      // Default: 2

// --- State Variables ---
let lightsOn = false;
let transitionFactor = 0.0;
let particles = [];
let glitchOffset = 0.0;
let activePalette = [];

function setup() {
  createCanvas(SKETCH_WIDTH, SKETCH_HEIGHT);
  randomSeed(SEED_VALUE);
  noiseSeed(SEED_VALUE);
  frameRate(ANIMATION_SPEED);

  activePalette = PALETTES[PALETTE_INDEX];

  particles = [];
  for (let i = 0; i < PARTICLE_COUNT; i++) {
    particles.push(new Particle());
  }
}

function draw() {
  // --- Automated Light Cycle & Glitch Logic ---
  if (frameCount % CYCLE_DURATION === 0) {
    lightsOn = !lightsOn;
    glitchOffset = GLITCH_STRENGTH; // Trigger glitch
  }
  glitchOffset *= GLITCH_DECAY; // Decay glitch effect

  transitionFactor = lerp(transitionFactor, lightsOn ? 1.0 : 0.0, LIGHT_TRANSITION);

  // Background Interpolation
  const colDark = color(activePalette[BG_DARK_INDEX]);
  const colLight = color(activePalette[BG_LIGHT_INDEX]);
  background(lerpColor(colDark, colLight, transitionFactor));

  // Apply Glitch Screen Shake & Center Canvas Content
  push();
  const gx = random(-glitchOffset, glitchOffset);
  const gy = random(-glitchOffset, glitchOffset);
  translate(PADDING + gx, PADDING + gy);

  const activeWidth = width - PADDING * 2;
  const activeHeight = height - PADDING * 2;

  if (SHOW_GRID) {
    drawDebugGrid(activeWidth, activeHeight);
  }

  // Update and Draw Particles
  for (let p of particles) {
    p.update(activeWidth, activeHeight);
    p.display();
  }

  // Glitch "Scanlines" or displacement
  if (glitchOffset > GLITCH_THRESHOLD) {
    drawGlitchArtifacts(activeWidth, activeHeight);
  }

  pop();

  // --- Frame Saving and Termination ---
  if (SAVE_FRAMES) {
    saveCanvas(`frames/frame_${nf(frameCount, 4)}`, "png");
    if (frameCount >= MAX_FRAMES) {
      noLoop();
    }
  }
}

function drawGlitchArtifacts(w, h) {
  const gCol = color(activePalette[GLITCH_COLOR_INDEX]);
  gCol.setAlpha(GLITCH_LINE_ALPHA);
  stroke(gCol);
  for (let i = 0; i < GLITCH_LINE_COUNT; i++) {
    const y = random(h);
    line(random(-20, 0), y, w + random(0, 20), y + random(-2, 2));
  }
}

function drawDebugGrid(w, h) {
  stroke(128, 50);
  for (let i = 0; i <= GRID_STEPS; i++) {
    line(i * (w / GRID_STEPS), 0, i * (w / GRID_STEPS), h);
    line(0, i * (h / GRID_STEPS), w, i * (h / GRID_STEPS));
  }
}

// --- Particle Entity ---
class Particle {
  constructor() {
    this.pos = createVector(random(width - PADDING * 2), random(height - PADDING * 2));
    this.vel = p5.Vector.random2D().mult(random(MIN_VEL_SPEED, MAX_VEL_SPEED));
    this.acc = createVector(0, 0);
    this.maxSpeed = random(MIN_MAX_SPEED, MAX_MAX_SPEED);
    this.pSize = random(MIN_SIZE, MAX_SIZE);
    
    // Choose particle color from palette (excluding background dark index 0)
    const colorIndex = floor(random(1, activePalette.length));
    this.hexColor = activePalette[colorIndex];
  }

  update(w, h) {
    if (lightsOn) {
      this.pos.add(this.vel);
      if (this.pos.x <= 0 || this.pos.x >= w) this.vel.x *= -1;
      if (this.pos.y <= 0 || this.pos.y >= h) this.vel.y *= -1;
      this.pos.x = constrain(this.pos.x, 0, w);
      this.pos.y = constrain(this.pos.y, 0, h);
    } else {
      const n = noise(this.pos.x * NOISE_SCALE, this.pos.y * NOISE_SCALE, frameCount * NOISE_TIME_SCALE);
      const angle = n * TWO_PI * NOISE_ANGLE_MULT;
      this.acc = p5.Vector.fromAngle(angle).mult(NOISE_FORCE_MULT);
      this.vel.add(this.acc);
      this.vel.limit(this.maxSpeed * SPEED_LIMIT_FACTOR);
      this.pos.add(this.vel);
      if (this.pos.x < 0) this.pos.x = w;
      if (this.pos.x > w) this.pos.x = 0;
      if (this.pos.y < 0) this.pos.y = h;
      if (this.pos.y > h) this.pos.y = 0;
    }
  }

  display() {
    const alphaVal = lerp(ALPHA_MIN, ALPHA_MAX, transitionFactor);
    push();
    translate(this.pos.x, this.pos.y);

    const c = color(this.hexColor);

    if (transitionFactor > 0.5) {
      // Lights On: Geometric Squares
      noFill();
      c.setAlpha(alphaVal);
      stroke(c);
      strokeWeight(STROKE_WEIGHT_SQUARE);
      rectMode(CENTER);
      rect(0, 0, this.pSize, this.pSize);
      
      // Occasional glitch stretching
      if (glitchOffset > 5) {
        line(-this.pSize, 0, this.pSize * 2, 0);
      }
    } else {
      // Lights Off: Organic Circles
      c.setAlpha(FILL_ALPHA_OFF);
      fill(c);
      c.setAlpha(alphaVal);
      stroke(c);
      strokeWeight(STROKE_WEIGHT_CIRCLE);
      ellipse(0, 0, this.pSize, this.pSize);

      c.setAlpha(CENTER_DOT_ALPHA);
      fill(c);
      noStroke();
      ellipse(0, 0, CENTER_DOT_SIZE, CENTER_DOT_SIZE);
    }
    pop();
  }
}
