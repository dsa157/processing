// ====================================================================
// GLOBAL PARAMETERS
// ====================================================================

// Canvas setup
final int SKETCH_WIDTH = 480;   // Default: 480
final int SKETCH_HEIGHT = 800; // Default: 800
final int PADDING = 40;        // Default: 40

// Animation and saving
final int MAX_FRAMES = 900;       // Default: 900
final boolean SAVE_FRAMES = true; // Default: false
final int ANIMATION_SPEED = 30;   // Default: 30 (frames/second)
final long SEED_VALUE = 12345;    // Default: 12345

// Grid and Visualization
final int ROWS = 5;                // Default: 5
final int COLS = 3;                // Default: 3
final int NESTING_DEPTH = 30;       // Default: 3 (Total number of circles in the hierarchy)
final float SIZE_RATIO = 0.9;     // Default: 0.75 (3/4)
final float CIRCLE_THICKNESS = 3.5; // Default: 1.5 (Stroke weight)
final boolean SHOW_GRID_CELLS = false; // Default: false

// Speed parameters
// Rotation speed in radians per frame (faster decimal values).
final float MIN_ROTATION_SPEED = 0.05;  // Default: 0.03 radians/frame (e.g., ~1.7 degrees/frame)
final float MAX_ROTATION_SPEED = 0.1;  // Default: 0.08 radians/frame (e.g., ~4.6 degrees/frame)

// Color Palette (Adobe Kuler - a pleasing, desaturated palette)
// Hex values: #3E885B, #6AAB9C, #B7B8B6, #D8D6C3, #EDC951
final int[] PALETTE = {
  unhex("FFA01D2C"), // Deep Crimson
  unhex("FFC45E2D"), // Burnt Orange
  unhex("FFED9A4A"), // Goldenrod
  unhex("FFFAE1B4"), // Creamy Beige
  unhex("FF495867")  // Slate Gray
};
final int BACKGROUND_COLOR_INDEX = 4; // Index in PALETTE for background
final boolean INVERT_BACKGROUND = false; // Default: false

// ====================================================================
// CLASS DEFINITIONS
// ====================================================================

/**
 * Represents a single rotating circle in the hierarchy.
 */
class NestedCircle {
  PVector center;
  float radius;
  float currentAngle;
  float rotationSpeed;
  float tangentOffsetAngle;
  int myDepth;
  NestedCircle child = null;
  int strokeColor;
  int fillColor;

  /**
   * Constructor for the outermost circle.
   */
  NestedCircle(PVector center, float radius, int depth) {
    this(center, radius, depth, null);
  }

  /**
   * Recursive constructor for nested circles.
   */
  NestedCircle(PVector center, float radius, int depth, NestedCircle parent) {
    this.center = center;
    this.radius = radius;
    this.myDepth = depth;

    // Random initialization for rotation using direct speed parameters
    // Random speed between MIN and MAX, and random direction (+/-)
    this.rotationSpeed = random(MIN_ROTATION_SPEED, MAX_ROTATION_SPEED) * (random(1) < 0.5 ? 1 : -1);
    this.tangentOffsetAngle = random(TWO_PI);

    // Assign colors based on depth
    this.strokeColor = PALETTE[myDepth % PALETTE.length];
    this.fillColor = unhex("00000000"); // Transparent fill

    // Create a child circle if the current depth is less than the total nesting depth MINUS ONE
    if (myDepth < NESTING_DEPTH - 1) {
      PVector childCenter = calculateChildCenter(this.radius, SIZE_RATIO, this.tangentOffsetAngle);
      float childRadius = this.radius * SIZE_RATIO;
      this.child = new NestedCircle(childCenter, childRadius, myDepth + 1, this);
    }
  }

  /**
   * Calculates the child's center position relative to the parent's center
   * at the initial tangent point.
   */
  PVector calculateChildCenter(float parentRadius, float ratio, float angle) {
    float childRadius = parentRadius * ratio;
    float distance = parentRadius - childRadius;
    float x = distance * cos(angle);
    float y = distance * sin(angle);
    return new PVector(x, y);
  }

  /**
   * Updates the circle's rotation and recursively updates its child.
   */
  void update() {
    this.currentAngle += this.rotationSpeed;
    if (this.child != null) {
      this.child.update();
    }
  }

  /**
   * Draws the circle and its child.
   */
  void display() {
    pushMatrix();
    // Translate to this circle's center
    translate(this.center.x, this.center.y);
    // Rotate the entire hierarchy rooted at this circle
    rotate(this.currentAngle);

    // Draw the circle
    noFill();
    strokeWeight(CIRCLE_THICKNESS); // Use the new parameter
    stroke(this.strokeColor);
    ellipse(0, 0, this.radius * 2, this.radius * 2);

    // Draw the child, which is drawn relative to a rotated coordinate system
    if (this.child != null) {
      // The child's center is a position *relative* to the parent's center (0,0)
      // and is rotated along with the parent's coordinate system.
      // The child itself applies its own translation/rotation *after* this.
      child.display();
    }
    popMatrix();
  }
}

// ====================================================================
// GLOBAL VARIABLES
// ====================================================================

NestedCircle[][] circleGrid;
float cellWidth;
float cellHeight;
int bgCol, fgCol;

// ====================================================================
// PROCESSING FUNCTIONS
// ====================================================================

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  // Setup
  frameRate(ANIMATION_SPEED);
  
  // Set the global seed for repeatable results
  randomSeed(SEED_VALUE);

  // Set colors
  bgCol = PALETTE[BACKGROUND_COLOR_INDEX];
  fgCol = (BACKGROUND_COLOR_INDEX + 1) % PALETTE.length; // Simple foreground pick
  if (INVERT_BACKGROUND) {
    bgCol = 0xFFFFFFFF - bgCol; // Simple color inversion logic
  }

  // Calculate cell dimensions
  cellWidth = (SKETCH_WIDTH - 2 * PADDING) / (float)COLS;
  cellHeight = (SKETCH_HEIGHT - 2 * PADDING) / (float)ROWS;
  float maxRadius = min(cellWidth, cellHeight) / 2.0;

  // Initialize the grid of circles
  circleGrid = new NestedCircle[ROWS][COLS];
  for (int r = 0; r < ROWS; r++) {
    for (int c = 0; c < COLS; c++) {
      // Calculate the center of the grid cell
      float centerX = PADDING + c * cellWidth + cellWidth / 2.0;
      float centerY = PADDING + r * cellHeight + cellHeight / 2.0;
      PVector center = new PVector(centerX, centerY);

      // Create the outermost circle (depth 0)
      circleGrid[r][c] = new NestedCircle(center, maxRadius, 0);
    }
  }
}

void draw() {
  background(bgCol);

  // Draw and update
  for (int r = 0; r < ROWS; r++) {
    for (int c = 0; c < COLS; c++) {
      // Show grid cells if parameterized
      if (SHOW_GRID_CELLS) {
        noFill();
        stroke(fgCol, 50); // Semi-transparent for grid lines
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
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) {
      noLoop();
    }
  } else if (frameCount >= MAX_FRAMES) {
    noLoop(); // Stop loop even if not saving
  }
}
