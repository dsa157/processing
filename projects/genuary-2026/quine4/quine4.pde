/**
 * Kinetic Typography Wave (Quine)
 * A visualization where the sketch's source code flows in a sine-wave pattern.
 * Movement is driven by per-character offsets and a global phase shift.
 */

// --- Configuration Parameters ---
int SKETCH_WIDTH = 480;       // Default: 480
int SKETCH_HEIGHT = 800;      // Default: 800
int PADDING = 40;             // Default: 40
int MAX_FRAMES = 900;         // Default: 900
boolean SAVE_FRAMES = false;  // Default: false
int ANIMATION_SPEED = 30;     // Default: 30
int RANDOM_SEED = 42157;         // Default: 42
boolean INVERT_BG = false;    // Default: false
int PALETTE_INDEX = 1;        // Default: 0 (0-4)
boolean SHOW_GRID = false;    // Default: false

// Typography Parameters
float FONT_SIZE = 11;         // Default: 11
float LINE_SPACING = 0.8;     // Default: 1.2
float WAVE_AMPLITUDE = 25.0;  // Default: 25.0
float WAVE_FREQUENCY = 0.05;  // Default: 0.05
float FLOW_SPEED = 0.08;      // Default: 0.08

// --- Color Palettes (Adobe Color / Kuler) ---
int[][] PALETTES = {
  {#023E73, #03738C, #0E8C7F, #F28705, #D95204}, // Deep Sea
  {#1A1A1A, #4E4E4E, #8C8C8C, #D9D9D9, #FFFFFF}, // Grayscale
  {#F20587, #0582CA, #05FFD1, #F2CF05, #F25C05}, // Neon
  {#581845, #900C3F, #C70039, #FF5733, #FFC300}, // Magma
  {#2E4057, #66A182, #CAFE48, #FFBC42, #D81159}  // Modular
};

String[] sourceLines;
float phase = 0;
int bgCol, textCol, accentCol;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  randomSeed(RANDOM_SEED);
  frameRate(ANIMATION_SPEED);
  textFont(createFont("Courier New Bold", FONT_SIZE));
  
  // Initialize Colors
  int[] activePalette = PALETTES[PALETTE_INDEX];
  bgCol = INVERT_BG ? activePalette[4] : activePalette[0];
  textCol = INVERT_BG ? activePalette[0] : activePalette[4];
  accentCol = activePalette[2];
  
  // Load source code as strings
  sourceLines = loadStrings(getClass().getSimpleName() + ".pde");
  // Fallback if file not found (e.g., in some IDE exports)
  if (sourceLines == null) {
    sourceLines = new String[]{"Source code unavailable.", "Check file name matches class name."};
  }
}

void draw() {
  background(bgCol);
  
  if (SHOW_GRID) drawDebugGrid();
  
  float xStart = PADDING;
  float yStart = PADDING + FONT_SIZE;
  float availableWidth = width - (PADDING * 2);
  
  float currentY = yStart;
  int charCount = 0;

  for (int i = 0; i < sourceLines.length; i++) {
    String lineText = sourceLines[i];
    float currentX = xStart;
    
    for (int j = 0; j < lineText.length(); j++) {
      char c = lineText.charAt(j);
      
      // Calculate Wave Offset
      // Offsets based on X position, Y position, and Time (phase)
      float offsetX = sin(currentY * WAVE_FREQUENCY + phase) * WAVE_AMPLITUDE;
      float offsetY = cos(currentX * WAVE_FREQUENCY + phase) * (WAVE_AMPLITUDE * 0.5);
      
      // Apply color variation based on wave position
      if (abs(offsetX) > WAVE_AMPLITUDE * 0.8) {
        fill(accentCol);
      } else {
        fill(textCol);
      }
      
      text(c, currentX + offsetX, currentY + offsetY);
      
      currentX += textWidth(c);
      
      // Wrap text if it exceeds padding
      if (currentX > width - PADDING) break;
    }
    
    currentY += FONT_SIZE * LINE_SPACING;
    if (currentY > height - PADDING) break;
  }

  phase += FLOW_SPEED;

  // --- Export / Loop Control ---
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) {
      noLoop();
    }
  }
}

void drawDebugGrid() {
  stroke(accentCol, 50);
  for (int i = 0; i <= width; i += 20) line(i, 0, i, height);
  for (int j = 0; j <= height; j += 20) line(0, j, width, j);
}
