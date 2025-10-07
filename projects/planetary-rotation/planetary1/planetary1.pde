// =========================================================
// GLOBAL PARAMETERS
// =========================================================
final int SKETCH_WIDTH = 480;
final int SKETCH_HEIGHT = 800;
final int PADDING = 40; // Padding around the overall sketch
final int MAX_FRAMES = 600;
final boolean SAVE_FRAMES = false;
final int ANIMATION_SPEED = 30; // Frames per second
final boolean INVERT_COLORS = false;

// Color Palette (now using HSB for better integration with colorMode)
// HSB: Hue, Saturation, Brightness (360, 100, 100)
// Base colors: Blue, Red, Yellow, White
final int[] BASE_HUES = {210, 350, 45, 0}; // ~ Blue, Red, Yellow, White (0)
final int HUE_SATURATION = 70;
final int HUE_BRIGHTNESS = 80;

// Sketch specific parameters
final int TILE_SIZE = 160;
final float BASE_ROTATION_SPEED = 0.005;

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
  float rotationDirection;
  float randomOffset; // Used for unique line/circle movement

  Tile(float x, float y, int s, long seed) {
    this.centerX = x;
    this.centerY = y;
    this.size = s;
    randomSeed(seed); // Unique seed for tile properties

    // FIX: random() must have an argument in Processing (Java)
    this.rotationDirection = random(1) > 0.5 ? 1 : -1;
    this.randomOffset = random(2 * PI);
  }

  void display() {
    pushMatrix();
    translate(centerX, centerY);

    // Dynamic rotation based on frameCount and direction
    float angle = rotationDirection * BASE_ROTATION_SPEED * frameCount;
    rotate(angle);

    // 1. Draw the main bounding shape (faint guide)
    noFill();
    stroke(foregroundColor, 30);
    strokeWeight(1);
    rect(0, 0, size * 0.95, size * 0.95);

    // 2. Draw the Woven Elements
    int numElements = 4;
    for (int i = 0; i < numElements; i++) {
      float elementAngle = TWO_PI / numElements * i;

      pushMatrix();
      rotate(elementAngle);

      // Unique movement for this element
      // Casting to float is necessary for sin/cos argument
      float movementOffset = sin(frameCount * 0.03 + randomOffset * (i+1)) * (size * 0.1);

      // Draw the anchor circle (center of the element)
      int baseHue = BASE_HUES[i % BASE_HUES.length];
      fill(baseHue, HUE_SATURATION, HUE_BRIGHTNESS);
      noStroke();
      ellipse(movementOffset, 0, size * 0.1, size * 0.1);

      // Draw the connecting line
      stroke(foregroundColor, 100);
      strokeWeight(1.5);
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
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
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

  // Define colors based on inversion setting
  if (INVERT_COLORS) {
    backgroundColor = color(0, 0, 100); // White
    foregroundColor = color(0, 0, 0);   // Black
  } else {
    backgroundColor = color(0, 0, 0);   // Black
    foregroundColor = color(0, 0, 100); // White
  }

  // Calculate sketch area and tiles
  int sketchWidth = SKETCH_WIDTH - 2 * PADDING;
  int sketchHeight = SKETCH_HEIGHT - 2 * PADDING;

  int cols = (int)ceil((float)sketchWidth / TILE_SIZE);
  int rows = (int)ceil((float)sketchHeight / TILE_SIZE);

  // Adjust center offset to truly center the grid
  float offsetX = (SKETCH_WIDTH - cols * TILE_SIZE) / 2.0f;
  float offsetY = (SKETCH_HEIGHT - rows * TILE_SIZE) / 2.0f;

  tiles = new Tile[cols][rows];

  // Initialize the Tiles
  long tileSeed = SEED;
  for (int i = 0; i < cols; i++) {
    for (int j = 0; j < rows; j++) {
      float x = offsetX + i * TILE_SIZE + TILE_SIZE / 2.0f;
      float y = offsetY + j * TILE_SIZE + TILE_SIZE / 2.0f;
      // Pass a unique seed for each tile
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
