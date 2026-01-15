/*
 * Flow Field Syntax (Quine)
 * Version: 2026.01.04.23.20.05
 * A self-referential visualization where the source code characters 
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
float NOISE_SCALE = 0.008;    // Default: 0.008
float TIME_STEP = 0.015;      // Default: 0.015
int CHAR_SPACING = 14;        // Default: 14
int TXT_SIZE = 12;            // Default: 12

// Color Management - Prefixed with 0xFF for Alpha/Opacity
int PALETTE_INDEX = 2;        // Default: 0
int[][] PALETTES = {
  {0xFF0D1B2A, 0xFF1B263B, 0xFF415A77, 0xFF778DA9, 0xFFE0E1DD}, // Deep Space
  {0xFF264653, 0xFF2A9D8F, 0xFFE9C46A, 0xFFF4A261, 0xFFE76F51}, // Adobe Natural
  {0xFF2B2D42, 0xFF8D99AE, 0xFFEDF2F4, 0xFFEF233C, 0xFFD90429}, // High Contrast
  {0xFF1A535C, 0xFF4ECDC4, 0xFFF7FFF7, 0xFFFF6B6B, 0xFFE66DFF}, // Modern Pop
  {0xFF000000, 0xFF333333, 0xFF666666, 0xFF999999, 0xFFFFFFFF}  // Grayscale
};

// Global Data
String content = "void settings(){size(480,800);}void setup(){frameRate(30);randomSeed(42);noiseSeed(42);}void draw(){background(0);float n=noise(x,y,z);pushMatrix();rotate(n);text(c,0,0);popMatrix();}";
float zOffset = 0;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  frameRate(ANIMATION_SPEED);
  randomSeed(SEED);
  noiseSeed(SEED);
  
  // Explicitly set text parameters
  textSize(TXT_SIZE);
  textAlign(CENTER, CENTER);
}

void draw() {
  int[] activePalette = PALETTES[PALETTE_INDEX];
  
  // Handle background selection and inversion
  int bgHex = INVERT_BG ? activePalette[activePalette.length - 1] : activePalette[0];
  background(bgHex);
  
  // Calculate centering logic
  int availableWidth = width - (PADDING * 2);
  int availableHeight = height - (PADDING * 2);
  
  int cols = availableWidth / CHAR_SPACING;
  int rows = availableHeight / CHAR_SPACING;
  
  float xStart = PADDING + (availableWidth - (cols * CHAR_SPACING)) / 2.0;
  float yStart = PADDING + (availableHeight - (rows * CHAR_SPACING)) / 2.0;
  
  int charCounter = 0;
  
  for (int j = 0; j < rows; j++) {
    for (int i = 0; i < cols; i++) {
      float x = xStart + i * CHAR_SPACING + CHAR_SPACING/2.0;
      float y = yStart + j * CHAR_SPACING + CHAR_SPACING/2.0;
      
      // Calculate Noise
      float n = noise(x * NOISE_SCALE, y * NOISE_SCALE, zOffset);
      float angle = n * TWO_PI * 4.0; 
      
      // Select text color (avoiding background index)
      int colIdx = floor(map(n, 0, 1, 1, activePalette.length));
      fill(activePalette[constrain(colIdx, 0, activePalette.length - 1)]);
      
      // Draw grid if enabled
      if (SHOW_GRID) {
        stroke(activePalette[2], 50);
        noFill();
        rect(x - CHAR_SPACING/2.0, y - CHAR_SPACING/2.0, CHAR_SPACING, CHAR_SPACING);
        // Re-fill for text
        fill(activePalette[constrain(colIdx, 0, activePalette.length - 1)]);
      }
      
      pushMatrix();
      translate(x, y);
      rotate(angle);
      
      // Loop through source characters
      char c = content.charAt(charCounter % content.length());
      text(c, 0, 0);
      
      popMatrix();
      charCounter++;
    }
  }
  
  zOffset += TIME_STEP;
  
  // Save/Stop Logic
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) {
      noLoop();
    }
  }
}
