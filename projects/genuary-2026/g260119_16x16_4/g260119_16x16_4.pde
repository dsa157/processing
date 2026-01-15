/**
 * Chrono-Grid (16x16)
 * A study in value, rhythm, and modular temporal patterns.
 */

// --- Parameters ---
int SKETCH_WIDTH = 480;       // default: 480
int SKETCH_HEIGHT = 800;      // default: 800
int SEED_VALUE = 42;          // default: 42
int PADDING = 40;             // default: 40
int MAX_FRAMES = 900;         // default: 900
boolean SAVE_FRAMES = false;  // default: false
int ANIMATION_SPEED = 30;     // default: 30
boolean SHOW_GRID = false;    // default: false
boolean INVERT_BG = false;    // default: false

int PALETTE_INDEX = 1;        // default: 0 (Range 0-4)
String[][] PALETTES = {
  {"#2c3e50", "#e74c3c", "#ecf0f1", "#3498db", "#2980b9"}, // Midnight/Clouds
  {"#581845", "#900c3f", "#c70039", "#ff5733", "#ffc300"}, // Sunset Heat
  {"#1a535c", "#4ecdc4", "#f7fff7", "#ff6b6b", "#ffe66d"}, // Retro Mint
  {"#230f2d", "#f25f5c", "#ffe066", "#247ba0", "#70c1b3"}, // Deep Sea
  {"#000000", "#333333", "#666666", "#999999", "#ffffff"}  // Monochromatic
};

// Grid Settings
int GRID_COUNT = 16;          // 16x16 grid
float STROKE_WEIGHT = 8.0;    // default: 2.0
float MODULO_FACTOR = 10.0;    // used for rhythm variance

// --- Global Variables ---
color activeBg;
color[] activePalette;
float cellSize;
float gridAreaSize;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  randomSeed(SEED_VALUE);
  frameRate(ANIMATION_SPEED);
  
  // Initialize Colors
  activePalette = new color[5];
  for (int i = 0; i < 5; i++) {
    activePalette[i] = unhex("FF" + PALETTES[PALETTE_INDEX][i].substring(1));
  }
  
  activeBg = INVERT_BG ? activePalette[4] : activePalette[0];
  
  // Calculate Grid
  gridAreaSize = min(width, height) - (PADDING * 2);
  cellSize = gridAreaSize / GRID_COUNT;
}

void draw() {
  background(activeBg);
  
  // Center the grid
  pushMatrix();
  translate((width - gridAreaSize) / 2, (height - gridAreaSize) / 2);
  
  for (int y = 0; y < GRID_COUNT; y++) {
    for (int x = 0; x < GRID_COUNT; x++) {
      drawChronoCell(x, y);
    }
  }
  
  popMatrix();
  
  // Handling Frame Saving and Loop Termination
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) {
      noLoop();
    }
  }
}

void drawChronoCell(int x, int y) {
  float posX = x * cellSize;
  float posY = y * cellSize;
  
  // Show grid cells if parameter is true
  if (SHOW_GRID) {
    stroke(activePalette[2], 50);
    noFill();
    rect(posX, posY, cellSize, cellSize);
  }
  
  // Modular Rhythm calculation
  // Each cell's speed is a function of its coordinate and frameCount
  float rhythmBase = (x + y * GRID_COUNT) % MODULO_FACTOR;
  float rotationAngle = frameCount * 0.05 * (1 + rhythmBase * 0.2);
  
  // Visuals centered in cell
  pushMatrix();
  translate(posX + cellSize/2, posY + cellSize/2);
  rotate(rotationAngle);
  
  // Value modulation based on rotation (rhythm to light)
  float pulse = sin(rotationAngle + (x * 0.1));
  float mappedStroke = map(pulse, -1, 1, 1, STROKE_WEIGHT * 2);
  int colIdx = floor(map(rhythmBase, 0, MODULO_FACTOR, 1, 4));
  
  stroke(activePalette[colIdx]);
  strokeWeight(mappedStroke);
  noFill();
  
  // Draw the "Clock Hand" or Arc
  float diameter = cellSize * 0.8;
  arc(0, 0, diameter, diameter, 0, PI * pulse);
  line(0, 0, diameter/2, 0);
  
  popMatrix();
}
