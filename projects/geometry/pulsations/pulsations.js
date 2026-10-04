/*
 * Pulsations
 * Version: 2026.10.02.18.43.00
 * Description: Generative morphing subdivision shapes pulsating through smooth Catmull-Clark
 * interpolation cycles across random seeds and harmonious palettes.
 * Converted from Processing (Java) to p5.js.
 */

// --- Parameters ---
// Canvas Setup
let SKETCH_WIDTH = 800;                 // default: 800 (requested: 800, original pde: 480)
let SKETCH_HEIGHT = 800;                // default: 800
let PADDING = 40;                       // default: 40

// Animation & Save
let MAX_FRAMES = 900;                   // default: 900
let SAVE_FRAMES = false;                // default: false
let ANIMATION_SPEED = 30;               // default: 30 (fps)

// Seed for Randomness
let GLOBAL_SEED = 157;                  // default: 157

// Color Palettes (Adobe Kuler inspired harmonious 5-color palettes)
// Palette 0: "Ocean Breeze" - Deep Indigo & Oceanic Blues
const PALETTE_OCEAN_BREEZE = [
  '#03045E', // Deep Indigo (Background)
  '#0077B6', // Vibrant Blue
  '#00B4D8', // Light Cerulean
  '#90E0EF', // Pale Cyan
  '#CAF0F8'  // Very Light Blue
];

// Palette 1: "Cyber Neon" - Midnight Purple & Vivid Fluorescents (Original)
const PALETTE_CYBER_NEON = [
  '#1B033A', // Very Dark Purple (Background)
  '#F72585', // Hot Pink
  '#4CC9F0', // Electric Cyan
  '#B5179E', // Violet/Fuchsia
  '#F8FF00'  // Neon Yellow (Accent)
];

// Palette 2: "Sunset Glow" - Twilight Plum & Warm Radiance
const PALETTE_SUNSET_GLOW = [
  '#2B1055', // Deep Twilight Violet (Background)
  '#7597DE', // Soft Periwinkle
  '#FF5964', // Coral Pink
  '#F9C80E', // Golden Sunglow
  '#F86624'  // Fiery Tangerine
];

// Palette 3: "Forest Aurora" - Midnight Woodland & Emerald Lights
const PALETTE_FOREST_AURORA = [
  '#0B1D13', // Abyssal Forest Green (Background)
  '#1E4D2B', // Deep Pine
  '#48B880', // Mint Jade
  '#95F9C3', // Phosphor Leaf
  '#E0FF4F'  // Lime Glow (Accent)
];

// Palette 4: "Solar Terracotta" - Obsidian Dust & Warm Earth
const PALETTE_SOLAR_TERRACOTTA = [
  '#1A1423', // Dark Slate Obsidian (Background)
  '#3D314A', // Smoky Plum
  '#E07A5F', // Terracotta Clay
  '#F2CC8F', // Desert Sand
  '#81B29A'  // Sage Mist
];

const PALETTES = [
  PALETTE_OCEAN_BREEZE,
  PALETTE_CYBER_NEON,
  PALETTE_SUNSET_GLOW,
  PALETTE_FOREST_AURORA,
  PALETTE_SOLAR_TERRACOTTA
];

// Color & Visuals Selection
let PALETTE_INDEX = 1;                  // default: 1 ("Cyber Neon")
let BACKGROUND_COLOR_INDEX = 0;         // default: 0
let INVERT_BACKGROUND = false;          // default: false
let SHOW_GRID = false;                  // default: false (initial mesh overlay)

// Subdivision Settings
let INITIAL_POINTS_MIN = 3;             // default: 3 (triangle)
let INITIAL_POINTS_MAX = 6;             // default: 6 (hexagon)
let INITIAL_RADIUS_BASE = 5;            // default: 5
let INITIAL_RADIUS_VARIATION = 15;      // default: 15
let MAX_SUBDIVISIONS = 4;               // default: 4

// Multiple Shapes
let NUM_SHAPES = 1000;                  // default: 1000
let SHAPE_ALPHA_MIN = 50;               // default: 50
let SHAPE_ALPHA_MAX = 200;              // default: 200
let STROKE_WEIGHT_MIN = 1.0;            // default: 1.0
let STROKE_WEIGHT_MAX = 2.5;            // default: 2.5
let SCALE_MIN = 0.5;                    // default: 0.5
let SCALE_MAX = 3.0;                    // default: 3.0
let ANIMATION_DURATION_MIN = 1.0;       // default: 1.0 (min cycle duration in seconds)
let ANIMATION_DURATION_MAX = 4.0;       // default: 4.0 (max cycle duration in seconds)

// Geometry & Jitter Parameters
let ANGLE_JITTER_RATIO = 0.1;           // default: 0.1 (random angle jitter: +/- PI * ratio)
let RADIUS_JITTER_RATIO = 0.2;          // default: 0.2 (random radius jitter: +/- radius * ratio)
let ROTATION_SPEED_FACTOR = 0.01;       // default: 0.01
let ROTATION_AMPLITUDE = 0.1;           // default: 0.1
let GRID_STROKE_WEIGHT = 0.5;           // default: 0.5
let GRID_STROKE_ALPHA = 50;             // default: 50
let CORNER_WEIGHT = 6.0;                // default: 6.0 (Catmull-Clark corner weighting)
let EDGE_DIVISOR = 8.0;                 // default: 8.0 (Catmull-Clark normalization divisor)

// --- Global Variables ---
let sketchAreaCenter;
let bgColor;
let subdivisionShapes = [];

// --- Catmull-Clark Subdivision Class (Simplified for a single closed curve) ---
class Polygon {
  constructor(initialVertices) {
    this.vertices = initialVertices; // Array of p5.Vector
  }

  // Simplified Catmull-Clark-like subdivision for a polygon/polyline
  subdivide() {
    const finalVertices = [];
    const n = this.vertices.length;

    for (let i = 0; i < n; i++) {
      const p_prev = this.vertices[(i - 1 + n) % n];
      const p_curr = this.vertices[i];
      const p_next = this.vertices[(i + 1) % n];

      // Adjusted corner point (P'_i = (P_{i-1} + 6*P_i + P_{i+1}) / 8)
      const adjustedCorner = p5.Vector.mult(p_prev, 1.0)
        .add(p5.Vector.mult(p_curr, CORNER_WEIGHT))
        .add(p5.Vector.mult(p_next, 1.0))
        .div(EDGE_DIVISOR);

      // New edge point (E_i = (P_i + P_{i+1}) / 2)
      const edgePoint = p5.Vector.mult(p_curr, 0.5)
        .add(p5.Vector.mult(p_next, 0.5));

      // Insert the adjusted corner point and the new edge point
      finalVertices.push(adjustedCorner);
      finalVertices.push(edgePoint);
    }
    return new Polygon(finalVertices);
  }
}

// --- SubdivisionShape Class ---
class SubdivisionShape {
  constructor(pos, rot, col, scaleVal, duration, offset, strokeW, alpha) {
    this.position = pos;
    this.rotationAngle = rot;
    this.shapeColor = col;
    this.scaleFactor = scaleVal;
    this.cycleDuration = duration;
    this.startTimeOffset = offset;
    this.strokeWeight = strokeW;
    this.alphaValue = alpha;

    // 1. Generate initial polygon points
    this.basePolygonPoints = [];
    const numPoints = floor(random(INITIAL_POINTS_MIN, INITIAL_POINTS_MAX + 1));
    const radius = INITIAL_RADIUS_BASE + random(-INITIAL_RADIUS_VARIATION, INITIAL_RADIUS_VARIATION);
    const angleStep = TWO_PI / numPoints;
    for (let i = 0; i < numPoints; i++) {
      const angle = angleStep * i + random(-PI * ANGLE_JITTER_RATIO, PI * ANGLE_JITTER_RATIO);
      const r = radius + random(-radius * RADIUS_JITTER_RATIO, radius * RADIUS_JITTER_RATIO);
      this.basePolygonPoints.push(createVector(cos(angle) * r, sin(angle) * r));
    }

    // 2. Pre-calculate all subdivision levels (0 to MAX_SUBDIVISIONS)
    this.allLevels = [];
    let currentPoly = new Polygon(this.basePolygonPoints);
    this.allLevels.push(currentPoly.vertices); // Level 0

    for (let i = 0; i < MAX_SUBDIVISIONS; i++) {
      currentPoly = currentPoly.subdivide();
      this.allLevels.push(currentPoly.vertices); // Level 1 to MAX_SUBDIVISIONS
    }

    // 3. Pre-calculate all "start" points for interpolation (mapped previous levels)
    this.mappedPrevLevels = [];
    // The first element is Level 0, which is the start of the L0 -> L1 interpolation
    this.mappedPrevLevels.push(this.allLevels[0]);

    for (let level = 1; level <= MAX_SUBDIVISIONS; level++) {
      const prevLevel = this.allLevels[level - 1];
      const mappedPrevLevel = [];
      const n_prev = prevLevel.length;

      // Map the sparser previous level (L_i-1) onto the current level's structure (L_i)
      for (let i = 0; i < n_prev; i++) {
        const p_curr = prevLevel[i];
        const p_next = prevLevel[(i + 1) % n_prev];

        // Corner point in L_i (2i) maps back to p_curr
        mappedPrevLevel.push(p_curr.copy());

        // Edge point in L_i (2i+1) maps back to midpoint (p_curr, p_next)
        const edgePoint = p5.Vector.add(p_curr, p_next).mult(0.5);
        mappedPrevLevel.push(edgePoint);
      }
      this.mappedPrevLevels.push(mappedPrevLevel);
    }
  }

  display() {
    // Calculate animation time (in seconds)
    const currentTime = (frameCount + this.startTimeOffset) / ANIMATION_SPEED;

    // Normalized time within the shape's cycle (0.0 to 1.0)
    const cycleTime = (currentTime % this.cycleDuration) / this.cycleDuration;

    // --- Smooth Boomerang Progress Calculation (0.0 to MAX_SUBDIVISIONS and back) ---
    // Use a cosine wave to generate a smooth 0 to 1 to 0 movement.
    // Progress Factor: 0.0 to 1.0 to 0.0
    const progressFactor = 0.5 + 0.5 * cos(TWO_PI * cycleTime + PI); // Range: 0.0 to 1.0 to 0.0

    // currentProgress: 0.0 to MAX_SUBDIVISIONS and back to 0.0
    const currentProgress = progressFactor * MAX_SUBDIVISIONS;

    this.drawSubdividedShape(currentProgress);
  }

  drawSubdividedShape(currentProgress) {
    // The step is the lower subdivision level we are starting from (0 to MAX_SUBDIVISIONS - 1)
    let step = floor(currentProgress);
    step = constrain(step, 0, MAX_SUBDIVISIONS - 1);

    // The interpolation factor is the progress from one integer level to the next (0.0 to 1.0)
    let interpolationFactor = currentProgress - step;

    // Determine the start and end level indices for the interpolation
    const startLevelIndex = step;
    const endLevelIndex = step + 1;

    // --- Determine Start and End Point Sets ---
    let startPoints;
    let endPoints;

    if (endLevelIndex > MAX_SUBDIVISIONS) {
      // We are interpolating from MAX_SUBDIVISIONS back to MAX_SUBDIVISIONS - 1
      // The *visual* step is MAX_SUBDIVISIONS-1 to MAX_SUBDIVISIONS to MAX_SUBDIVISIONS-1
      // When progress is 3.5 to 4.0 to 3.5, the 'step' is 3 for forward, 3 for backward.

      // Use the highest level (MAX_SUBDIVISIONS) and the one before it (MAX_SUBDIVISIONS - 1)
      startPoints = this.mappedPrevLevels[MAX_SUBDIVISIONS]; // L_max-1 mapped to L_max structure
      endPoints = this.allLevels[MAX_SUBDIVISIONS];          // L_max structure

      // Reverse the interpolation factor for the backward half of the cycle
      // Since we are moving between the final two states, we use the complementary factor to blend back
      interpolationFactor = 1.0 - interpolationFactor;
    } else {
      // Forward motion (or regression at lower levels)
      startPoints = this.mappedPrevLevels[endLevelIndex]; // L_step mapped to L_step+1 structure
      endPoints = this.allLevels[endLevelIndex];          // L_step+1 structure
    }

    // --- Final Interpolation (Constant Point Count) ---
    const interpolatedSurface = [];
    // The point count is constant for any given step transition (always the size of the higher level)
    const n = endPoints.length;

    for (let i = 0; i < n; i++) {
      const start = startPoints[i];
      const end = endPoints[i];

      const interpolatedPoint = p5.Vector.lerp(start, end, interpolationFactor);
      interpolatedSurface.push(interpolatedPoint);
    }

    push();
    // 1. Position and Rotation
    translate(this.position.x, this.position.y);
    rotate(this.rotationAngle + sin(frameCount * ROTATION_SPEED_FACTOR * this.cycleDuration) * ROTATION_AMPLITUDE);
    scale(this.scaleFactor);

    // Draw the Emergent Smooth Form
    noFill();
    strokeWeight(this.strokeWeight); // Use instance property
    let col = color(this.shapeColor);
    col.setAlpha(this.alphaValue);
    stroke(col);

    beginShape();
    for (let v of interpolatedSurface) {
      vertex(v.x, v.y);
    }
    endShape(CLOSE);

    // Draw initial polygon (grid) if enabled
    if (SHOW_GRID) {
      strokeWeight(GRID_STROKE_WEIGHT);
      stroke(255, GRID_STROKE_ALPHA);

      beginShape();
      for (let v of this.basePolygonPoints) {
        vertex(v.x, v.y);
      }
      endShape(CLOSE);
    }

    pop();
  }
}

// --- Setup ---

function setup() {
  createCanvas(SKETCH_WIDTH, SKETCH_HEIGHT);

  // Setup Random Seed
  randomSeed(GLOBAL_SEED);

  // Set frame rate
  frameRate(ANIMATION_SPEED);

  // Calculate Sketch Area Center
  sketchAreaCenter = createVector(SKETCH_WIDTH / 2.0, SKETCH_HEIGHT / 2.0);

  // Active Color Palette Selection
  const activePalette = PALETTES[PALETTE_INDEX];

  // Set Colors
  let bgHex = activePalette[BACKGROUND_COLOR_INDEX];
  if (INVERT_BACKGROUND) {
    let c = color(bgHex);
    bgColor = color(255 - red(c), 255 - green(c), 255 - blue(c));
  } else {
    bgColor = color(bgHex);
  }

  // Initialize multiple SubdivisionShapes
  subdivisionShapes = [];

  // Define the boundary for spawning shapes (respecting padding)
  const minX = PADDING;
  const minY = PADDING;
  const maxX = SKETCH_WIDTH - PADDING;
  const maxY = SKETCH_HEIGHT - PADDING;

  for (let i = 0; i < NUM_SHAPES; i++) {
    const x = random(minX, maxX);
    const y = random(minY, maxY);
    const pos = createVector(x, y);

    const rot = random(TWO_PI);
    const colorIndex = floor(random(1, activePalette.length));
    const col = activePalette[colorIndex];

    const scaleVal = random(SCALE_MIN, SCALE_MAX);
    const duration = random(ANIMATION_DURATION_MIN, ANIMATION_DURATION_MAX);
    const offset = random(duration * ANIMATION_SPEED);

    const strokeW = random(STROKE_WEIGHT_MIN, STROKE_WEIGHT_MAX);
    const alphaVal = random(SHAPE_ALPHA_MIN, SHAPE_ALPHA_MAX);

    subdivisionShapes.push(new SubdivisionShape(pos, rot, col, scaleVal, duration, offset, strokeW, alphaVal));
  }
}

// --- Draw Loop ---

function draw() {
  background(bgColor);

  // Display all shapes asynchronously
  for (let shape of subdivisionShapes) {
    shape.display();
  }

  // --- Frame Saving ---
  if (SAVE_FRAMES) {
    if (frameCount <= MAX_FRAMES) {
      saveCanvas('frame-' + nf(frameCount, 4), 'png');
    } else {
      noLoop();
    }
  }
}
