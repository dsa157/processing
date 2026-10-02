/**
 * Tessellated Fish-to-Bird Morph: Seamless Pattern Blending
 * Version: 2026.10.01.16.08.30
 * 
 * Description:
 * Smoothly blends logic and color between cycling pattern states using Escher-inspired fish and bird tessellations.
 * Converted from Processing (Java) to p5.js.
 */

// --- Global Parameters ---
let SKETCH_WIDTH = 800;          // default: 800
let SKETCH_HEIGHT = 800;         // default: 800
let PADDING = 40;                // default: 40
let SEED = 888;                  // default: 888
let MAX_FRAMES = 1200;           // default: 1200
let ANIMATION_SPEED = 60;        // default: 60
let SAVE_FRAMES = false;         // default: false
let INVERT_COLORS = false;       // default: false
let SHOW_GRID = false;           // default: false

// --- Visual Parameters ---
let GRID_COLS = 25;              // default: 25
let CYCLE_SPEED = 0.04;          // default: 0.04
let PALETTE_INDEX = 6;           // default: 6 (0-6, 6 is BW + Red)
let INITIAL_PATTERN = 2;         // default: 2 (0-9)
let AUTO_CYCLE = true;           // default: true
let DURATION_PER_PATTERN = 2;    // default: 2 (Full sine cycles before switching)

// --- Color Palettes (Curated from Adobe Kuler / Color Palette Library) ---
const PALETTES = [
  ["#264653", "#2a9d8f", "#e9c46a", "#f4a261", "#e76f51"], // Palette 0: Sandy Stone (Adobe Kuler)
  ["#606c38", "#283618", "#fefae0", "#dda15e", "#bc6c25"], // Palette 1: Earthy Green (Adobe Kuler)
  ["#001219", "#005f73", "#0a9396", "#94d2bd", "#e9d8a6"], // Palette 2: Deep Sea (Adobe Kuler)
  ["#540d6e", "#ee4266", "#ffd23f", "#3bceac", "#0ead69"], // Palette 3: Neon Fruit (Adobe Kuler)
  ["#2b2d42", "#8d99ae", "#edf2f4", "#ef233c", "#d90429"], // Palette 4: Crimson Slate (Adobe Kuler)
  ["#222222", "#555555", "#888888", "#bbbbbb", "#eeeeee"], // Palette 5: Monochromatic Gray
  ["#000000", "#FFFFFF", "#ef233c", "#FFFFFF", "#000000"]  // Palette 6: Black & White + Red Accent
];

let tessellator;
let offsetX = 0;
let offsetY = 0;

function setup() {
  createCanvas(SKETCH_WIDTH, SKETCH_HEIGHT);
  randomSeed(SEED);
  noiseSeed(SEED);
  frameRate(ANIMATION_SPEED);
  
  let gridW = width - (2 * PADDING);
  let cellSize = gridW / GRID_COLS;
  let rows = Math.ceil((height - (2 * PADDING)) / cellSize);
  let gridH = rows * cellSize;
  
  // Center grid on canvas
  offsetX = (width - gridW) / 2;
  offsetY = (height - gridH) / 2;
  
  tessellator = new Tessellator(GRID_COLS, rows, cellSize);
}

function draw() {
  let activePalette = PALETTES[PALETTE_INDEX];
  let bgBase = color(activePalette[0]);
  let fgBase = color(activePalette[1]);
  
  background(INVERT_COLORS ? fgBase : bgBase);
  
  let totalPhase = frameCount * CYCLE_SPEED;
  let currentP;
  let blendWeight = 0;

  if (AUTO_CYCLE) {
    let interval = TWO_PI * DURATION_PER_PATTERN;
    currentP = (Math.floor(totalPhase / interval) + INITIAL_PATTERN) % 10;
    
    // Calculate blend weight: smooth transition at the end of the cycle
    let progressInCycle = (totalPhase % interval) / interval;
    blendWeight = map(progressInCycle, 0.85, 1.0, 0, 1);
    blendWeight = constrain(blendWeight, 0, 1);
  } else {
    currentP = INITIAL_PATTERN;
  }
  
  push();
  translate(offsetX, offsetY);
  tessellator.display(activePalette, currentP, totalPhase, blendWeight);
  pop();

  if (SAVE_FRAMES) {
    saveCanvas("frames/frame-" + nf(frameCount, 4), "png");
    if (frameCount >= MAX_FRAMES) noLoop();
  }
}

class Tessellator {
  constructor(c, r, s) {
    this.cols = c;
    this.rows = r;
    this.size = s;
    this.fish = [];
    this.bird = [];
    this.initShapes();
  }
  
  initShapes() {
    this.fish = [
      createVector(0.5, 0),
      createVector(1, 0.2),
      createVector(0.7, 0.5),
      createVector(1, 0.8),
      createVector(0.5, 1),
      createVector(0, 0.8),
      createVector(0.3, 0.5),
      createVector(0, 0.2)
    ];
    this.bird = [
      createVector(0, 0.5),
      createVector(0.3, 0),
      createVector(0.7, 0),
      createVector(1, 0.5),
      createVector(0.7, 1),
      createVector(0.3, 1),
      createVector(0.5, 0.8),
      createVector(0.5, 0.2)
    ];
  }
  
  display(palette, pIdx, phase, blend) {
    rectMode(CENTER);
    let redAccent = color(palette[2]);

    for (let i = 0; i < this.cols; i++) {
      for (let j = 0; j < this.rows; j++) {
        let f1 = this.calculatePattern(i, j, phase, pIdx);
        let f2 = this.calculatePattern(i, j, phase, (pIdx + 1) % 10);
        let factor = lerp(f1, f2, blend);
        
        push();
        translate(i * this.size + this.size / 2, j * this.size + this.size / 2);
        
        let rot = factor * PI;
        rotate(rot + ((i + j) % 2 === 0 ? 0 : HALF_PI));
        
        let c1 = color(0);
        let c2 = color(255);
        let finalFill = ((i + j) % 2 === 0) ? lerpColor(c1, redAccent, factor) : lerpColor(c2, redAccent, factor);
        
        fill(finalFill);
        noStroke();
        
        beginShape();
        for (let v = 0; v < this.fish.length; v++) {
          let vx = lerp(this.fish[v].x, this.bird[v].x, factor) - 0.5;
          let vy = lerp(this.fish[v].y, this.bird[v].y, factor) - 0.5;
          vertex(vx * this.size, vy * this.size);
        }
        endShape(CLOSE);
        pop();
      }
    }
  }

  calculatePattern(i, j, t, pIdx) {
    let wave;
    switch(pIdx) {
      case 0: wave = sin(t + j * 0.5); break;
      case 1: wave = sin(t + (i + j) * 0.3); break;
      case 2: wave = sin(t + dist(i, j, this.cols / 2, this.rows / 2) * 0.4); break;
      case 3: wave = sin(t + j * j * 0.02); break;
      case 4: wave = j % 2 === 0 ? sin(t) : sin(t + PI); break;
      case 5: wave = sin(t + i * 0.5); break;
      case 6: wave = sin(t + (noise(i * 0.2, j * 0.2, t * 0.1) * TWO_PI)); break;
      case 7: wave = sin(t + (j % 3) * (TWO_PI / 3.0)); break;
      case 8: wave = sin(t) * map(j, 0, this.rows, 0, 1); break;
      case 9: wave = sin(t + sin(j * 0.5) * 2.0); break;
      default: wave = sin(t);
    }
    return (wave + 1) / 2.0;
  }
}
