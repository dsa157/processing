/**
 * Nested Circles - Recursive Tangent Rotating Circle Hierarchy
 * Version: 2026.10.04.16.25.00
 *
 * Description:
 * A grid of recursive tangent circles. 
 * Each hierarchy level rotates around its own center, driving child circles that are tangent to their 
 * parent's perimeter to orbit and spin, generating nested spirographic motion patterns.
 *
 */

// ====================================================================
// GLOBAL PARAMETERS
// ====================================================================

// Canvas setup
let SKETCH_WIDTH = 800;   // Default: 800 (requested: 800, original pde: 480)
let SKETCH_HEIGHT = 800;  // Default: 800
let PADDING = 40;         // Default: 40

// Animation and saving
let MAX_FRAMES = 900;        // Default: 900
let SAVE_FRAMES = false;     // Default: false (set to true to export frames)
let ANIMATION_SPEED = 30;    // Default: 30 (frames/second)
let SEED_VALUE = 12345;      // Default: 12345 (global seed value for repeatable results)

// Grid and Visualization
let ROWS = 5;                 // Default: 5
let COLS = 5;                 // Default: 3
let NESTING_DEPTH = 25;       // Default: 30 (Total number of circles in the hierarchy)
let SIZE_RATIO = 0.9;         // Default: 0.9 (original pde: 0.75)
let CIRCLE_THICKNESS = 3.5;   // Default: 3.5 (Stroke weight; original pde: 1.5)
let SHOW_GRID_CELLS = false;  // Default: false

// Speed parameters
// Rotation speed in radians per frame (faster decimal values).
let MIN_ROTATION_SPEED = 0.05;  // Default: 0.05 (radians/frame; e.g., ~2.9 degrees/frame, original pde: 0.03)
let MAX_ROTATION_SPEED = 0.1;   // Default: 0.1  (radians/frame; e.g., ~5.7 degrees/frame, original pde: 0.08)

// Color Palettes (Curated from Adobe Kuler / Color Themes)
// 5 distinct palettes with 5 colors each; active palette chosen by PALETTE_INDEX
const PALETTES = [
  // Palette 0: "Autumn Fire" (Original PDE palette: Deep Crimson, Burnt Orange, Goldenrod, Creamy Beige, Slate Gray)
  ["#A01D2C", "#C45E2D", "#ED9A4A", "#FAE1B4", "#495867"],
  // Palette 1: "Botanical Forest" (Deep Pine, Teal, Saffron, Coral, Burnt Ochre)
  ["#264653", "#2A9D8F", "#E9C46A", "#F4A261", "#E76F51"],
  // Palette 2: "Nordic Frost" (Charcoal, Evergreen, Mint Sage, Seafoam, Ice White)
  ["#1F2421", "#216869", "#49A078", "#9CC5A1", "#DCE1DE"],
  // Palette 3: "Oceanic Abyss" (Midnight, Deep Blue, Steel Blue, Powder Frost, Dark Navy)
  ["#0B2545", "#134074", "#8DA9C4", "#EEF4F8", "#121B2A"],
  // Palette 4: "Cyber Sunset" (Deep Velvet, Indigo Night, Magenta Flare, Warm Amber, Neon Violet)
  ["#0D0221", "#3B185F", "#A12568", "#FEC260", "#F10086"]
];

let PALETTE_INDEX = 0;              // Default: 0 (Index to choose active palette from PALETTES)
let BACKGROUND_COLOR_INDEX = 4;     // Default: 4 (Index in active palette for background)
let INVERT_BACKGROUND = false;      // Default: false

// ====================================================================
// GLOBAL VARIABLES
// ====================================================================

let circleGrid;
let cellWidth;
let cellHeight;

// ====================================================================
// CLASS DEFINITIONS
// ====================================================================

/**
 * Represents a single rotating circle in the hierarchy.
 */
class NestedCircle {
  /**
   * Recursive constructor for nested circles.
   */
  constructor(center, radius, depth, parent = null) {
    this.center = center;
    this.radius = radius;
    this.myDepth = depth;
    this.parent = parent;
    this.currentAngle = 0;
    this.child = null;

    // Random initialization for rotation using direct speed parameters
    // Random speed between MIN and MAX, and random direction (+/-)
    this.rotationSpeed = random(MIN_ROTATION_SPEED, MAX_ROTATION_SPEED) * (random(1) < 0.5 ? 1 : -1);
    this.tangentOffsetAngle = random(TWO_PI);

    // Assign colors based on depth
    this.updateColor();

    // Create a child circle if the current depth is less than the total nesting depth MINUS ONE
    if (this.myDepth < NESTING_DEPTH - 1) {
      let childCenter = this.calculateChildCenter(this.radius, SIZE_RATIO, this.tangentOffsetAngle);
      let childRadius = this.radius * SIZE_RATIO;
      this.child = new NestedCircle(childCenter, childRadius, this.myDepth + 1, this);
    }
  }

  /**
   * Update circle stroke color based on the currently selected palette.
   */
  updateColor() {
    const activePalette = PALETTES[PALETTE_INDEX];
    this.strokeColor = activePalette[this.myDepth % activePalette.length];
    if (this.child) {
      this.child.updateColor();
    }
  }

  /**
   * Calculates the child's center position relative to the parent's center
   * at the initial tangent point.
   */
  calculateChildCenter(parentRadius, ratio, angle) {
    let childRadius = parentRadius * ratio;
    let distance1 = parentRadius - childRadius;
    let x = distance1 * cos(angle);
    let y = distance1 * sin(angle);
    return createVector(x, y);
  }

  /**
   * Updates the circle's rotation and recursively updates its child.
   */
  update() {
    this.currentAngle += this.rotationSpeed;
    if (this.child != null) {
      this.child.update();
    }
  }

  /**
   * Draws the circle and its child.
   */
  display() {
    push();
    // Translate to this circle's center
    translate(this.center.x, this.center.y);
    // Rotate the entire hierarchy rooted at this circle
    rotate(this.currentAngle);

    // Draw the circle
    noFill();
    strokeWeight(CIRCLE_THICKNESS); // Use the parameter
    stroke(this.strokeColor);
    ellipse(0, 0, this.radius * 2, this.radius * 2);

    // Draw the child, which is drawn relative to a rotated coordinate system
    if (this.child != null) {
      // The child's center is a position *relative* to the parent's center (0,0)
      // and is rotated along with the parent's coordinate system.
      // The child itself applies its own translation/rotation *after* this.
      this.child.display();
    }
    pop();
  }
}

// ====================================================================
// HELPER FUNCTIONS
// ====================================================================

/**
 * Gets background color based on active palette and invert setting.
 */
function getBackgroundColor() {
  const activePalette = PALETTES[PALETTE_INDEX];
  let hexCol = activePalette[BACKGROUND_COLOR_INDEX % activePalette.length];
  if (INVERT_BACKGROUND) {
    let c = color(hexCol);
    return color(255 - red(c), 255 - green(c), 255 - blue(c));
  }
  return color(hexCol);
}

/**
 * Gets foreground color based on active palette.
 */
function getForegroundColor() {
  const activePalette = PALETTES[PALETTE_INDEX];
  let fgIndex = (BACKGROUND_COLOR_INDEX + 1) % activePalette.length;
  return color(activePalette[fgIndex]);
}

/**
 * Updates color across all circles in the grid when palette changes.
 */
function updateAllCircleColors() {
  for (let r = 0; r < ROWS; r++) {
    for (let c = 0; c < COLS; c++) {
      if (circleGrid && circleGrid[r] && circleGrid[r][c]) {
        circleGrid[r][c].updateColor();
      }
    }
  }
}

// ====================================================================
// PROCESSING / P5.JS LIFECYCLE FUNCTIONS
// ====================================================================

function setup() {
  let canvas = createCanvas(SKETCH_WIDTH, SKETCH_HEIGHT);
  // Center output on the canvas container
  if (canvas.parent()) {
    canvas.style('display', 'block');
    canvas.style('margin', 'auto');
  }

  // Setup frame rate
  frameRate(ANIMATION_SPEED);

  // Set the global seed for repeatable results
  randomSeed(SEED_VALUE);
  noiseSeed(SEED_VALUE);

  // Calculate cell dimensions
  cellWidth = (SKETCH_WIDTH - 2 * PADDING) / COLS;
  cellHeight = (SKETCH_HEIGHT - 2 * PADDING) / ROWS;
  let maxRadius = min(cellWidth, cellHeight) / 2.0;

  // Initialize the grid of circles
  circleGrid = [];
  for (let r = 0; r < ROWS; r++) {
    circleGrid[r] = [];
    for (let c = 0; c < COLS; c++) {
      // Calculate the center of the grid cell
      let centerX = PADDING + c * cellWidth + cellWidth / 2.0;
      let centerY = PADDING + r * cellHeight + cellHeight / 2.0;
      let center = createVector(centerX, centerY);

      // Create the outermost circle (depth 0)
      circleGrid[r][c] = new NestedCircle(center, maxRadius, 0);
    }
  }
}

function draw() {
  background(getBackgroundColor());

  let fgCol = getForegroundColor();

  // Draw and update
  for (let r = 0; r < ROWS; r++) {
    for (let c = 0; c < COLS; c++) {
      // Show grid cells if parameterized
      if (SHOW_GRID_CELLS) {
        noFill();
        let gridLineColor = color(red(fgCol), green(fgCol), blue(fgCol), 50);
        stroke(gridLineColor); // Semi-transparent for grid lines
        strokeWeight(1);
        rect(PADDING + c * cellWidth, PADDING + r * cellHeight, cellWidth, cellHeight);
      }

      // Update and display the circle hierarchy
      circleGrid[r][c].update();
      circleGrid[r][c].display();
    }
  }

  // Save frames logic
  if (SAVE_FRAMES) {
    saveCanvas(`frames/frame_${nf(frameCount, 4)}`, 'png');
    if (frameCount >= MAX_FRAMES) {
      noLoop();
    }
  } else if (frameCount >= MAX_FRAMES) {
    noLoop(); // Stop loop even if not saving
  }
}

// ====================================================================
// INTERACTION & CREATIVE CONTROLS
// ====================================================================

function keyPressed() {
  // Creative controls: Spacebar or 'P' to cycle color palettes
  if (key === ' ' || keyCode === 32 || key === 'p' || key === 'P') {
    PALETTE_INDEX = (PALETTE_INDEX + 1) % PALETTES.length;
    updateAllCircleColors();
    return false; // Prevent browser scroll on spacebar
  }

  // Toggle grid cells with 'G'
  if (key === 'g' || key === 'G') {
    SHOW_GRID_CELLS = !SHOW_GRID_CELLS;
  }

  // Toggle background invert with 'I'
  if (key === 'i' || key === 'I') {
    INVERT_BACKGROUND = !INVERT_BACKGROUND;
  }

  // Save current frame with 'S'
  if (key === 's' || key === 'S') {
    saveCanvas(`nested_circles_${year()}${nf(month(), 2)}${nf(day(), 2)}_${nf(hour(), 2)}${nf(minute(), 2)}${nf(second(), 2)}`, 'png');
  }
}
