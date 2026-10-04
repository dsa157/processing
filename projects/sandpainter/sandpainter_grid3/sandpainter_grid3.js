/**
 * SandPainter - Grid-based emergent network visualizatio
 * Inspired by the work of Jared Tarbell.
 * Version: 2026.10.04.17.12.00
 *
 * Description:
 * Grid of cells with flocking particles that paint delicate sand-like lines
 * between nearby neighbors.
 *
 */

//===================================================================
// GLOBAL PARAMETERS
//===================================================================

// --- Sketch Setup Parameters ---
let SKETCH_WIDTH = 480; // default: 480
let SKETCH_HEIGHT = 800; // default: 800
let SEED = 111555; // default: 111555 (Global seed for random() and noise())
let PADDING = 40; // default: 40 (Padding around the overall sketch)
let INVERT_COLORS = false; // default: false (Invert background/foreground colors)

// --- Animation/Saving Parameters ---
let ANIMATION_SPEED = 30; // default: 30 (Desired frames per second)
let MAX_FRAMES = 900; // default: 900 (Maximum frames to run)
let SAVE_FRAMES = false; // default: false (Save frames to disk)

// --- Color Palettes (Curated from Adobe Kuler / Color Themes) ---
// 5 distinct palettes with 5 colors each; active palette chosen by PALETTE_INDEX.
// Each palette array contains [0: Background, 1-4: Foreground / Particle Brush Colors]
const PALETTES = [
  {
    name: "Espresso & Amber", // Rich earthy warm palette from original sketch
    colors: [
      "#2B1B17", // 0: Dark Espresso Brown (BG)
      "#5E3526", // 1: Burnt Sienna
      "#993333", // 2: Deep Brick Red
      "#AF7737", // 3: Mustard / Amber
      "#B2B59C"  // 4: Dusty Olive Green (FG)
    ]
  },
  {
    name: "Coastal Fog", // Muted monochromatic oceanic blues from original sketch PALETTE1
    colors: [
      "#102A43", // 0: Classic Navy (BG)
      "#334D5C", // 1: Dark Slate Gray
      "#5E72F5", // 2: Muted Periwinkle
      "#8FAEC4", // 3: Pale Blue-Gray
      "#D9E4EC"  // 4: Very Light Blue (FG)
    ]
  },
  {
    name: "Desert Twilight", // Sunset glow over cool sand
    colors: [
      "#1D1E2C", // 0: Midnight Shadow (BG)
      "#593F62", // 1: Dusty Violet
      "#7B6D8D", // 2: Muted Lavender
      "#C39E5C", // 3: Warm Desert Sand
      "#F7D08A"  // 4: Golden Dune (FG)
    ]
  },
  {
    name: "Nordic Aurora", // Vivid polar night with bioluminescent greens/teals
    colors: [
      "#0F172A", // 0: Deep Arctic Abyss (BG)
      "#0E7490", // 1: Ocean Cyan
      "#059669", // 2: Emerald Aurora
      "#10B981", // 3: Bright Mint
      "#6EE7B7"  // 4: Icy Celadon (FG)
    ]
  },
  {
    name: "Japanese Blossom", // Refined sumi ink with cherry blossom accents
    colors: [
      "#1F1D2B", // 0: Deep Charcoal Sumi (BG)
      "#7A2048", // 1: Deep Plum Wine
      "#B23B68", // 2: Rosewood Carmine
      "#E07A5F", // 3: Terracotta Coral
      "#F4ACB7"  // 4: Soft Sakura Pink (FG)
    ]
  }
];

let PALETTE_INDEX = 0; // default: 0 (Index to select active palette from PALETTES array)
let BACKGROUND_COLOR_INDEX = 0; // default: 0 (Index in palette for BG color)
let FOREGROUND_COLOR_INDEX = 4; // default: 4 (Index in palette for FG color)

// --- Grid Parameters ---
let COLS = 4; // default: 4 (Number of columns in the grid)
let ROWS = 8; // default: 8 (Number of rows in the grid)
let SHOW_GRID = false; // default: false (Show/hide grid cell boundaries)
let CELL_INNER_PADDING_FACTOR = 0.15; // default: 0.15 (Padding factor * Cell Size)
let COLOR_START_INDEX = 1; // default: 1 (Start index for cell colors, skipping BG color)

// --- Physics/Particle Parameters ---
let FRIENDS_PER_CELL = 3; // default: 3 (Number of particles per cell)
let MAX_SPEED = 1.2; // default: 1.2 (Maximum velocity magnitude)
let MAX_FORCE = 0.08; // default: 0.08 (Maximum steering force)
let NEIGHBOR_RADIUS = 30; // default: 30 (Radius for neighbor interaction)
let SEPARATION_DISTANCE = 12; // default: 12 (Closest distance to maintain)
let SEPARATION_WEIGHT = 1.5; // default: 1.5 (Weighting for separation)
let ALIGNMENT_WEIGHT = 0.5; // default: 0.5 (Weighting for alignment)
let COHESION_WEIGHT = 0.3; // default: 0.3 (Weighting for cohesion)
let CONNECTION_OPACITY_DECAY = 0.05; // default: 0.05 (Opacity decrease per frame)

// --- Visualization / Rendering Tuning Parameters ---
let MIN_SPEED_FACTOR = 0.5; // default: 0.5 (Initial speed random range factor: MAX_SPEED * 0.5 to MAX_SPEED)
let CONFINEMENT_THRESHOLD_FACTOR = 0.8; // default: 0.8 (Confinement trigger threshold: distSq > maxDistSq * 0.8)
let CONFINEMENT_FORCE_FACTOR = 2.0; // default: 2.0 (Steering limit multiplier for confinement force)
let NEIGHBOR_CONNECTION_FACTOR = 1.5; // default: 1.5 (Distance multiplier for connection check: NEIGHBOR_RADIUS * 1.5)
let CONNECTION_BASE_WEIGHT = 0.75; // default: 0.75 (Base line weight for connections)
let CONNECTION_WEIGHT_DISTANCE_FACTOR = 0.05; // default: 0.05 (Distance multiplier added to connection weight)
let OPACITY_DECAY_MULTIPLIER = 0.5; // default: 0.5 (Decay rate multiplier: CONNECTION_OPACITY_DECAY * 0.5)
let FADE_ALPHA = 10; // default: 10 (Alpha value 0-255 for cumulative sandpainter semi-transparent overlay)
let GRID_STROKE_ALPHA = 100; // default: 100 (Stroke alpha for cell boundaries if SHOW_GRID is true)
let GRID_STROKE_WEIGHT = 1; // default: 1 (Stroke weight for cell boundaries)
let CELL_CENTER_EPSILON = 1.0; // default: 1.0 (Distance threshold for cell center matching)

//===================================================================
// CLASSES
//===================================================================

// --- Friend Class: The particle agent ---
class Friend {
  constructor(initialPos, center, padding) {
    this.position = initialPos.copy();
    this.velocity = p5.Vector.random2D();
    this.velocity.setMag(random(MAX_SPEED * MIN_SPEED_FACTOR, MAX_SPEED));
    this.acceleration = createVector(0, 0);
    this.homeCenter = center.copy();
    this.cellInnerPadding = padding;
    this.activeConnections = [];
  }

  applyForce(force) {
    this.acceleration.add(force);
  }

  flock(friends) {
    let sep = this.separate(friends).mult(SEPARATION_WEIGHT);
    let ali = this.align(friends).mult(ALIGNMENT_WEIGHT);
    let coh = this.cohesion(friends).mult(COHESION_WEIGHT);

    let totalForce = createVector(0, 0);
    totalForce.add(sep);
    totalForce.add(ali);
    totalForce.add(coh);

    return totalForce;
  }

  steer(target) {
    let steerForce = p5.Vector.sub(target, this.velocity);
    steerForce.limit(MAX_FORCE);
    return steerForce;
  }

  // --- Localized Flocking Rules (Separation, Alignment, Cohesion) ---

  separate(friends) {
    let steerForce = createVector(0, 0);
    let count = 0;
    for (let other of friends) {
      let d = p5.Vector.dist(this.position, other.position);
      if (d > 0 && d < SEPARATION_DISTANCE) {
        let diff = p5.Vector.sub(this.position, other.position);
        diff.normalize();
        diff.div(d);
        steerForce.add(diff);
        count++;
      }
    }
    if (count > 0) {
      steerForce.div(count);
    }
    if (steerForce.mag() > 0) {
      steerForce.setMag(MAX_SPEED);
      steerForce.sub(this.velocity);
      steerForce.limit(MAX_FORCE);
    }
    return steerForce;
  }

  align(friends) {
    let sum = createVector(0, 0);
    let count = 0;
    for (let other of friends) {
      let d = p5.Vector.dist(this.position, other.position);
      if (d > 0 && d < NEIGHBOR_RADIUS) {
        sum.add(other.velocity);
        count++;
      }
    }
    if (count > 0) {
      sum.div(count);
      sum.setMag(MAX_SPEED);
      let steerForce = p5.Vector.sub(sum, this.velocity);
      steerForce.limit(MAX_FORCE);
      return steerForce;
    }
    return createVector(0, 0);
  }

  cohesion(friends) {
    let sum = createVector(0, 0);
    let count = 0;
    for (let other of friends) {
      let d = p5.Vector.dist(this.position, other.position);
      if (d > 0 && d < NEIGHBOR_RADIUS) {
        sum.add(other.position);
        count++;
      }
    }
    if (count > 0) {
      sum.div(count);
      return this.steer(sum);
    }
    return createVector(0, 0);
  }

  // --- Grid Confinement (Steering and Hard Walls) ---

  confine() {
    let cellHalfWidth = grid.cellWidth / 2 - this.cellInnerPadding;
    let cellHalfHeight = grid.cellHeight / 2 - this.cellInnerPadding;
    let maxDistSq = cellHalfWidth * cellHalfWidth + cellHalfHeight * cellHalfHeight;

    let relPos = p5.Vector.sub(this.position, this.homeCenter);
    let distSq = relPos.magSq();

    if (distSq > maxDistSq * CONFINEMENT_THRESHOLD_FACTOR) {
      let desired = p5.Vector.sub(this.homeCenter, this.position);
      desired.normalize();
      desired.mult(MAX_SPEED);

      let steerForce = p5.Vector.sub(desired, this.velocity);
      steerForce.limit(MAX_FORCE * CONFINEMENT_FORCE_FACTOR);
      return steerForce;
    }
    return createVector(0, 0);
  }

  checkWalls() {
    let xMin = this.homeCenter.x - grid.cellWidth / 2 + this.cellInnerPadding;
    let xMax = this.homeCenter.x + grid.cellWidth / 2 - this.cellInnerPadding;
    let yMin = this.homeCenter.y - grid.cellHeight / 2 + this.cellInnerPadding;
    let yMax = this.homeCenter.y + grid.cellHeight / 2 - this.cellInnerPadding;

    if (this.position.x < xMin) {
      this.position.x = xMin;
      this.velocity.x *= -1;
    } else if (this.position.x > xMax) {
      this.position.x = xMax;
      this.velocity.x *= -1;
    }

    if (this.position.y < yMin) {
      this.position.y = yMin;
      this.velocity.y *= -1;
    } else if (this.position.y > yMax) {
      this.position.y = yMax;
      this.velocity.y *= -1;
    }
  }

  update() {
    let flockForce = this.flock(grid.getCellFriends(this.homeCenter));
    flockForce.add(this.confine());
    this.applyForce(flockForce);
    this.checkWalls();

    this.velocity.add(this.acceleration);
    this.velocity.limit(MAX_SPEED);
    this.position.add(this.velocity);
    this.acceleration.mult(0);
  }
}

// --- Connection Class: The brush-stroke for visualization ---
class Connection {
  constructor(pos1, pos2, c, weight) {
    this.p1 = pos1.copy();
    this.p2 = pos2.copy();
    this.opacity = 1.0;
    this.drawColor = c;
    this.lineWeight = weight;
  }

  display() {
    let c = color(this.drawColor);
    stroke(red(c), green(c), blue(c), this.opacity * 255);
    strokeWeight(this.lineWeight);
    line(this.p1.x, this.p1.y, this.p2.x, this.p2.y);
  }
}

// --- Grid Class: Manages the cells and particles ---
class Grid {
  constructor(x, y, w, h) {
    this.sketchX = x;
    this.sketchY = y;
    this.sketchW = w;
    this.sketchH = h;
    this.cellWidth = this.sketchW / COLS;
    this.cellHeight = this.sketchH / ROWS;
    this.cells = [];

    let activeColors = PALETTES[PALETTE_INDEX].colors;
    let colorCount = activeColors.length - COLOR_START_INDEX;

    // Initialize cells
    for (let i = 0; i < COLS; i++) {
      this.cells[i] = [];
      for (let j = 0; j < ROWS; j++) {
        let cx = this.sketchX + i * this.cellWidth + this.cellWidth / 2;
        let cy = this.sketchY + j * this.cellHeight + this.cellHeight / 2;

        // Randomly pick a color index from the available non-BG colors (1 to 4)
        let colorIndex = COLOR_START_INDEX + floor(random(colorCount));

        this.cells[i][j] = new GridCell(
          createVector(cx, cy),
          i,
          j,
          this.cellWidth,
          this.cellHeight,
          activeColors[colorIndex]
        );
      }
    }
  }

  update() {
    for (let i = 0; i < COLS; i++) {
      for (let j = 0; j < ROWS; j++) {
        this.cells[i][j].updateFriends();
      }
    }

    for (let i = 0; i < COLS; i++) {
      for (let j = 0; j < ROWS; j++) {
        this.cells[i][j].createConnections();
      }
    }
  }

  display() {
    for (let i = 0; i < COLS; i++) {
      for (let j = 0; j < ROWS; j++) {
        this.cells[i][j].displayConnections();
      }
    }

    if (SHOW_GRID) {
      noFill();
      let fgC = color(actualFG);
      stroke(red(fgC), green(fgC), blue(fgC), GRID_STROKE_ALPHA);
      strokeWeight(GRID_STROKE_WEIGHT);
      rectMode(CORNER);
      for (let i = 0; i < COLS; i++) {
        for (let j = 0; j < ROWS; j++) {
          rect(this.sketchX + i * this.cellWidth, this.sketchY + j * this.cellHeight, this.cellWidth, this.cellHeight);
        }
      }
    }
  }

  getCellFriends(center) {
    for (let i = 0; i < COLS; i++) {
      for (let j = 0; j < ROWS; j++) {
        if (p5.Vector.dist(center, this.cells[i][j].center) < CELL_CENTER_EPSILON) {
          return this.cells[i][j].friends;
        }
      }
    }
    return [];
  }
}

// --- GridCell Class: Contains the Friends and their connections ---
class GridCell {
  constructor(c, i, j, width, height, connColor) {
    this.center = c;
    this.col = i;
    this.row = j;
    this.w = width;
    this.h = height;
    this.connections = [];
    this.friends = [];
    this.cellConnectionColor = connColor; // Store the assigned color

    this.innerPadding = min(this.w, this.h) * CELL_INNER_PADDING_FACTOR;

    // Initialize Friends
    for (let k = 0; k < FRIENDS_PER_CELL; k++) {
      let startX = this.center.x + random(-this.w / 2 + this.innerPadding, this.w / 2 - this.innerPadding);
      let startY = this.center.y + random(-this.h / 2 + this.innerPadding, this.h / 2 - this.innerPadding);
      this.friends.push(new Friend(createVector(startX, startY), this.center, this.innerPadding));
    }
  }

  updateFriends() {
    for (let f of this.friends) {
      f.update();
    }
  }

  // Creates the cumulative, 'SandPainter' brush-stroke effect
  createConnections() {
    for (let i = 0; i < this.friends.length; i++) {
      let f1 = this.friends[i];

      for (let j = i + 1; j < this.friends.length; j++) {
        let f2 = this.friends[j];
        let d = p5.Vector.dist(f1.position, f2.position);

        if (d < NEIGHBOR_RADIUS * NEIGHBOR_CONNECTION_FACTOR) {
          // Use the cell's assigned color
          let connWeight = CONNECTION_BASE_WEIGHT + d * CONNECTION_WEIGHT_DISTANCE_FACTOR;
          let newConn = new Connection(f1.position, f2.position, this.cellConnectionColor, connWeight);
          this.connections.push(newConn);
        }
      }
    }
  }

  displayConnections() {
    for (let i = this.connections.length - 1; i >= 0; i--) {
      let conn = this.connections[i];
      conn.opacity -= CONNECTION_OPACITY_DECAY * OPACITY_DECAY_MULTIPLIER;
      if (conn.opacity <= 0) {
        this.connections.splice(i, 1);
      } else {
        conn.display();
      }
    }
  }
}

//===================================================================
// MAIN PROGRAM
//===================================================================

let grid;
let sketchCanvasX, sketchCanvasY;
let sketchCanvasW, sketchCanvasH;
let actualBG, actualFG;

function updateColors() {
  let activeColors = PALETTES[PALETTE_INDEX].colors;
  let bgCol = activeColors[BACKGROUND_COLOR_INDEX];
  let fgCol = activeColors[FOREGROUND_COLOR_INDEX];

  if (INVERT_COLORS) {
    if (BACKGROUND_COLOR_INDEX === 0) {
      actualBG = activeColors[FOREGROUND_COLOR_INDEX];
      actualFG = activeColors[BACKGROUND_COLOR_INDEX];
    } else {
      let cBg = color(bgCol);
      let cFg = color(fgCol);
      actualBG = color(255 - red(cBg), 255 - green(cBg), 255 - blue(cBg));
      actualFG = color(255 - red(cFg), 255 - green(cFg), 255 - blue(cFg));
    }
  } else {
    actualBG = bgCol;
    actualFG = fgCol;
  }
}

function initSketch() {
  randomSeed(SEED);
  noiseSeed(SEED);
  updateColors();

  // Calculate sketch area and center it
  sketchCanvasW = width - 2 * PADDING;
  sketchCanvasH = height - 2 * PADDING;
  sketchCanvasX = PADDING + (width - 2 * PADDING - sketchCanvasW) / 2;
  sketchCanvasY = PADDING + (height - 2 * PADDING - sketchCanvasH) / 2;

  grid = new Grid(sketchCanvasX, sketchCanvasY, sketchCanvasW, sketchCanvasH);

  background(actualBG);
}

function setup() {
  createCanvas(SKETCH_WIDTH, SKETCH_HEIGHT);
  frameRate(ANIMATION_SPEED);
  initSketch();
}

function draw() {
  // Draw a semi-transparent rectangle for the cumulative fade effect (SandPainter)
  let bgC = color(actualBG);
  fill(red(bgC), green(bgC), blue(bgC), FADE_ALPHA);
  noStroke();
  rect(0, 0, width, height);

  grid.update();
  grid.display();

  // --- Frame Saving / Limitation Block ---
  if (SAVE_FRAMES) {
    saveCanvas(`frames/frame_${nf(frameCount, 4)}`, "png");
    if (frameCount >= MAX_FRAMES) {
      noLoop();
      console.log("Animation finished and saved.");
    }
  } else if (frameCount >= MAX_FRAMES) {
    noLoop();
  }
}

// --- Interactive Controls ---
function cyclePalette() {
  PALETTE_INDEX = (PALETTE_INDEX + 1) % PALETTES.length;
  initSketch();
}

function mousePressed() {
  // Click on canvas to cycle color palette
  if (mouseX >= 0 && mouseX <= width && mouseY >= 0 && mouseY <= height) {
    cyclePalette();
  }
}

function keyPressed() {
  // Spacebar or 'P'/'p': Cycle through color palettes
  if (key === " " || keyCode === 32 || key === "p" || key === "P") {
    cyclePalette();
    return false; // Prevent browser scrolling on spacebar
  }

  // 'G'/'g': Toggle grid display
  if (key === "g" || key === "G") {
    SHOW_GRID = !SHOW_GRID;
  }

  // 'I'/'i': Toggle color inversion
  if (key === "i" || key === "I") {
    INVERT_COLORS = !INVERT_COLORS;
    updateColors();
    background(actualBG);
  }

  // 'R'/'r': Restart / reseed simulation
  if (key === "r" || key === "R") {
    initSketch();
  }

  // 'S'/'s': Save snapshot of current canvas
  if (key === "s" || key === "S") {
    saveCanvas(`sandpainter_grid3_${Date.now()}`, "png");
  }
}
