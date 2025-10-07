// =========================================================
// GLOBAL PARAMETERS
// =========================================================
final int SKETCH_WIDTH = 480;
final int SKCH_HEIGHT = 800;
final int PADDING = 40; // Padding around the overall sketch
final int MAX_FRAMES = 900;
final boolean SAVE_FRAMES = false;
final int ANIMATION_SPEED = 30; // Frames per second
final boolean INVERT_COLORS = false;

// --- DISPLAY PARAMETERS ---
final boolean SHOW_GRID_SQUARES = true; // Parameter to show/hide the faint bounding box

// COLOR PARAMETERS (HSB: 360, 100, 100)
final int[] BASE_HUES = {210, 350, 45, 0}; // ~ Blue, Red, Yellow, White (0)
final int HUE_SATURATION = 70;
final int HUE_BRIGHTNESS = 80;

// Color palette using HEX codes for background.
final String[] COLOR_PALETTE_HEX = {
  "#1A1A1A", // Very Dark Gray
  "#334C73", // Deep Slate Blue
  "#264026", // Dark Forest Green
  "#40321A", // Muted Dark Brown
  "#CC0044"  // Bright Red (for high-contrast option)
};

// --- GRID FIX PARAMETERS ---
final int TARGET_COLS = 3; // Fixed number of columns
final int TARGET_ROWS = 5; // Fixed number of rows
int TILE_SIZE; // Calculated dynamically in setup()

// PARAMETERS FOR ROTATION VARIATION
final float MIN_ROTATION_SPEED = 0.02; // Minimum speed (radians per frame)
final float MAX_ROTATION_SPEED = 0.09; // Maximum speed (radians per frame)

// Global seed for reproducible random results
long SEED = 12345;

// Background and Foreground color variables
int backgroundColor;
int foregroundColor;

// Array to hold the rotating tile objects
Tile[][] tiles;

// =========================================================
// TILE CLASS
// =========================================================
class Tile {
  float centerX;
  float centerY;
  int size;
  float rotationSpeed; // Unique rotation speed for this tile
  float randomOffset; // Used for unique line/circle movement

  Tile(float x, float y, int s, long seed) {
    this.centerX = x;
    this.centerY = y;
    this.size = s;
    randomSeed(seed); // Unique seed for tile properties

    // Calculate a unique speed and direction for this tile
    float baseSpeed = random(MIN_ROTATION_SPEED, MAX_ROTATION_SPEED);
    float direction = random(1) > 0.5 ? 1 : -1;
    this.rotationSpeed = baseSpeed * direction;

    this.randomOffset = random(2 * PI);
  }

  void display() {
    pushMatrix();
    translate(centerX, centerY);

    // Dynamic rotation based on frameCount and unique rotationSpeed
    float angle = rotationSpeed * frameCount;
    rotate(angle);

    // 1. Draw the main bounding shape (faint guide)
    if (SHOW_GRID_SQUARES) {
      noFill();
      stroke(foregroundColor, 30);
      strokeWeight(1);
      rect(0, 0, size * 0.95f, size * 0.95f);
    }

    // 2. Draw the Woven Elements
    int numElements = 4;
    for (int i = 0; i < numElements; i++) {
      float elementAngle = TWO_PI / numElements * i;

      pushMatrix();
      rotate(elementAngle);

      // Unique movement for this element
      float movementOffset = sin(frameCount * 0.03f + randomOffset * (i + 1)) * (size * 0.1f);

      // Draw the anchor circle (center of the element)
      int baseHue = BASE_HUES[i % BASE_HUES.length];
      fill(baseHue, HUE_SATURATION, HUE_BRIGHTNESS);
      noStroke();
      ellipse(movementOffset, 0, size * 0.1f, size * 0.1f);

      // Draw the connecting line
      stroke(foregroundColor, 100);
      strokeWeight(1.5f);
      line(0, 0, size * 0.3f + movementOffset, 0);

      // Draw the outer indicator circle
      float outerX = size * 0.35f + movementOffset;
      fill(baseHue, HUE_SATURATION, HUE_BRIGHTNESS - 30, 80);
      stroke(baseHue, HUE_SATURATION, HUE_BRIGHTNESS, 100);
      strokeWeight(2);
      float circleSize = size * 0.08f + size * 0.03f * sin(frameCount * 0.05f);
      ellipse(outerX, 0, circleSize, circleSize);

      popMatrix();
    }

    popMatrix();
  }
}

// =========================================================
// PROCESSING LIFECYCLE
// =========================================================

void settings() {
  size(SKETCH_WIDTH, SKCH_HEIGHT);
}

void setup() {
  // Setup environment
  frameRate(ANIMATION_SPEED);
  rectMode(CENTER);
  ellipseMode(CENTER);
  colorMode(HSB, 360, 100, 100, 100);

  // Set initial seed
  if (SEED == 0) {
    SEED = (long)(Math.random() * 1000000);
  }
  randomSeed(SEED);

  // --- BACKGROUND COLOR SELECTION ---
  int paletteIndex = (int)random(COLOR_PALETTE_HEX.length);
  String bg_hex_string = COLOR_PALETTE_HEX[paletteIndex];
  backgroundColor = unhex(bg_hex_string.substring(1));
  float bg_brightness = brightness(backgroundColor);

  if (INVERT_COLORS || bg_brightness < 50) {
    foregroundColor = color(0, 0, 100); // White (HSB: 0, 0, 100)
  } else {
    foregroundColor = color(0, 0, 0);   // Black (HSB: 0, 0, 0)
  }

  // --- TILE SIZE CALCULATION FOR FIXED GRID ---
  // 1. Calculate the available space inside the padding
  float innerWidth = SKETCH_WIDTH - 2.0f * PADDING;
  float innerHeight = SKCH_HEIGHT - 2.0f * PADDING;

  // 2. Calculate the maximum tile size that fits both the columns and rows
  float sizeByWidth = innerWidth / TARGET_COLS;
  float sizeByHeight = innerHeight / TARGET_ROWS;

  // TILE_SIZE must be the smaller of the two to maintain a square aspect ratio
  // Use floor() to get a clean integer size, necessary for TILE_SIZE definition
  TILE_SIZE = (int)floor(min(sizeByWidth, sizeByHeight));
  
  // 3. Calculate the total space the fixed grid will occupy
  float totalGridWidth = TARGET_COLS * TILE_SIZE;
  float totalGridHeight = TARGET_ROWS * TILE_SIZE;

  // 4. Calculate the starting offset to center the grid within the padded area.
  // The grid starts at PADDING, plus half the remaining inner space.
  float offsetX = PADDING + (innerWidth - totalGridWidth) / 2.0f;
  float offsetY = PADDING + (innerHeight - totalGridHeight) / 2.0f;
  
  // Fix grid size to target parameters
  int cols = TARGET_COLS;
  int rows = TARGET_ROWS;
  
  tiles = new Tile[cols][rows];

  // Initialize the Tiles
  long tileSeed = SEED;
  for (int i = 0; i < cols; i++) {
    for (int j = 0; j < rows; j++) {
      // Tile center is the starting offset, plus the index offset, plus half a tile
      float x = offsetX + i * TILE_SIZE + TILE_SIZE / 2.0f;
      float y = offsetY + j * TILE_SIZE + TILE_SIZE / 2.0f;
      tiles[i][j] = new Tile(x, y, TILE_SIZE, tileSeed++);
    }
  }
}

void draw() {
  background(backgroundColor);

  // Draw the grid of tiles
  for (int i = 0; i < tiles.length; i++) {
    for (int j = 0; j < tiles[0].length; j++) {
      tiles[i][j].display();
    }
  }

  // =========================================================
  // FRAME SAVING LOGIC
  // =========================================================
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) {
      noLoop();
      println("Animation finished and saved.");
    }
  }
}
