/*
 * Flow Field Syntax (Quine)
 * Version: 2026.01.04.23.14.22
 * * A self-referential visualization where the source code characters
 * follow a 2D Perlin noise flow field.
 */

// --- Parameters ---
int SKETCH_WIDTH = 480;       // Default: 480
int SKETCH_HEIGHT = 800;      // Default: 800
int PADDING = 40;             // Default: 40
int SEED = 42;                // Default: 42
int MAX_FRAMES = 900;         // Default: 900
boolean SAVE_FRAMES = false;  // Default: false
int ANIMATION_SPEED = 30;     // Default: 30
boolean INVERT_BG = false;    // Default: false
boolean SHOW_GRID = false;    // Default: false

// Flow Field Parameters
float NOISE_SCALE = 0.005;    // Default: 0.005
float TIME_STEP = 0.01;       // Default: 0.01
int CHAR_SPACING = 12;        // Default: 12
int TEXT_SIZE = 10;           // Default: 10

// Color Management
int PALETTE_INDEX = 0;        // Default: 0 (0 to 4)
int[][] PALETTES = {
  {0x0D1B2A, 0x1B263B, 0x415A77, 0x778DA9, 0xE0E1DD}, // Terra
  {0x264653, 0x2A9D8F, 0xE9C46A, 0xF4A261, 0xE76F51}, // Sandy Stone
  {0x606C38, 0x283618, 0xFEFAE0, 0xDDA15E, 0xBC6C25}, // Earthy
  {0x22223B, 0x4A4E69, 0x9A8C98, 0xC9ADA7, 0xF2E9E4}, // Muted Rose
  {0xFFB5A7, 0xFCD5CE, 0xF8EDEB, 0xF9DCC4, 0xFEC89A}  // Pastel Sunset
};

// Global Variables
String sourceCode = "void settings() { size(SKETCH_WIDTH, SKETCH_HEIGHT); } void setup() { frameRate(ANIMATION_SPEED); randomSeed(SEED); noiseSeed(SEED); }";
float zOffset = 0;
PFont monoFont;

void settings() {
  size(480, 800);
}

void setup() {
  frameRate(ANIMATION_SPEED);
  randomSeed(SEED);
  noiseSeed(SEED);
  
  // Create a string from a subset of the logic for the "Quine" effect
  sourceCode = String.join("", loadStrings(sketchPath(getClass().getSimpleName() + ".pde")));
  if (sourceCode == null || sourceCode.length() == 0) {
    sourceCode = "Checking Flow Field Syntax... Initializing Perlin Noise Quine... System.out.print('Hello World');";
  }
  
  monoFont = createFont("Courier New", TEXT_SIZE);
  textFont(monoFont);
  textAlign(CENTER, CENTER);
}

void draw() {
  int[] currentPalette = PALETTES[PALETTE_INDEX];
  int bgColor = INVERT_BG ? currentPalette[currentPalette.length - 1] : currentPalette[0];
  background(bgColor);
  
  // Calculate Draw Area
  int innerW = width - (PADDING * 2);
  int innerH = height - (PADDING * 2);
  
  int cols = innerW / CHAR_SPACING;
  int rows = innerH / CHAR_SPACING;
  
  pushMatrix();
  translate(PADDING, PADDING);
  
  int charIdx = 0;
  for (int y = 0; y < rows; y++) {
    for (int x = 0; x < cols; x++) {
      float xPos = x * CHAR_SPACING + (CHAR_SPACING / 2);
      float yPos = y * CHAR_SPACING + (CHAR_SPACING / 2);
      
      // Calculate Noise for rotation and color
      float n = noise(xPos * NOISE_SCALE, yPos * NOISE_SCALE, zOffset);
      float angle = n * TWO_PI * 2;
      
      // Grid Debugging
      if (SHOW_GRID) {
        stroke(currentPalette[2], 50);
        noFill();
        rect(x * CHAR_SPACING, y * CHAR_SPACING, CHAR_SPACING, CHAR_SPACING);
      }
      
      // Pick color from palette (skipping background)
      int colIdx = floor(map(n, 0, 1, 1, currentPalette.length));
      fill(currentPalette[constrain(colIdx, 0, currentPalette.length - 1)]);
      
      // Draw Character
      pushMatrix();
      translate(xPos, yPos);
      rotate(angle);
      
      char c = sourceCode.charAt(charIdx % sourceCode.length());
      text(c, 0, 0);
      popMatrix();
      
      charIdx++;
    }
  }
  popMatrix();
  
  zOffset += TIME_STEP;
  
  // Export and Loop Control
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) {
      noLoop();
    }
  }
}
