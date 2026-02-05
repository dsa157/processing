/*
 * Kinetic Raster Clock
 * Version: 2026.02.05.18.25.10
 * Symmetrical easing for seamless phase loops.
 * Background glyph dimming during active clock phase.
 */

// --- Parameters ---
int MAX_FRAMES = 900;         // Default: 900
boolean SAVE_FRAMES = false;  // Default: false
int ANIMATION_SPEED = 30;     // Default: 30
int GLOBAL_SEED = 42;         // Default: 42
float PADDING = 40;           // Default: 40

int GRID_COLS = 11;           // User Adjusted: 11
int GRID_ROWS = 25;           // User Adjusted: 25
boolean SHOW_GRID = true;     // Default: true

boolean USE_24H = false;      // Default: false
int PALETTE_INDEX = 1;        // User Adjusted: 1
boolean INVERT_BG = false;    // Default: false

float MIN_PULSE_SPD = 0.15;   // User Adjusted: 0.15
float MAX_PULSE_SPD = 0.25;   // User Adjusted: 0.25
float MAX_GLYPH_SIZE_MULT = 0.65; // User Adjusted: 0.65
int GUTTER = 1;               // Gap between digits

// Alpha Parameters
int BG_ALPHA_CHAOS = 100;     // Default: 100
int BG_ALPHA_CLOCK = 40;      // Default: 40 (Lowered for contrast)

// Phase Timing (Seconds)
float DURATION_CHAOS = 5.0;   // Default: 5
float DURATION_CLOCK = 10.0;  // Default: 10

// --- Readable Font Data (5x7) ---
int[][][] fontMatrix = {
  { // 0
    {0, 1, 1, 1, 0},
    {1, 0, 0, 0, 1},
    {1, 0, 0, 0, 1},
    {1, 0, 0, 0, 1},
    {1, 0, 0, 0, 1},
    {1, 0, 0, 0, 1},
    {0, 1, 1, 1, 0}
  },
  { // 1
    {0, 0, 1, 0, 0},
    {0, 1, 1, 0, 0},
    {0, 0, 1, 0, 0},
    {0, 0, 1, 0, 0},
    {0, 0, 1, 0, 0},
    {0, 0, 1, 0, 0},
    {0, 1, 1, 1, 0}
  },
  { // 2
    {0, 1, 1, 1, 0},
    {1, 0, 0, 0, 1},
    {0, 0, 0, 0, 1},
    {0, 0, 0, 1, 0},
    {0, 0, 1, 0, 0},
    {0, 1, 0, 0, 0},
    {1, 1, 1, 1, 1}
  },
  { // 3
    {0, 1, 1, 1, 0},
    {1, 0, 0, 0, 1},
    {0, 0, 0, 0, 1},
    {0, 0, 1, 1, 0},
    {0, 0, 0, 0, 1},
    {1, 0, 0, 0, 1},
    {0, 1, 1, 1, 0}
  },
  { // 4
    {0, 0, 0, 1, 0},
    {0, 0, 1, 1, 0},
    {0, 1, 0, 1, 0},
    {1, 0, 0, 1, 0},
    {1, 1, 1, 1, 1},
    {0, 0, 0, 1, 0},
    {0, 0, 0, 1, 0}
  },
  { // 5
    {1, 1, 1, 1, 1},
    {1, 0, 0, 0, 0},
    {1, 1, 1, 1, 0},
    {0, 0, 0, 0, 1},
    {0, 0, 0, 0, 1},
    {1, 0, 0, 0, 1},
    {0, 1, 1, 1, 0}
  },
  { // 6
    {0, 1, 1, 1, 0},
    {1, 0, 0, 0, 0},
    {1, 1, 1, 1, 0},
    {1, 0, 0, 0, 1},
    {1, 0, 0, 0, 1},
    {1, 0, 0, 0, 1},
    {0, 1, 1, 1, 0}
  },
  { // 7
    {1, 1, 1, 1, 1},
    {0, 0, 0, 0, 1},
    {0, 0, 0, 1, 0},
    {0, 0, 1, 0, 0},
    {0, 1, 0, 0, 0},
    {1, 0, 0, 0, 0},
    {1, 0, 0, 0, 0}
  },
  { // 8
    {0, 1, 1, 1, 0},
    {1, 0, 0, 0, 1},
    {1, 0, 0, 0, 1},
    {0, 1, 1, 1, 0},
    {1, 0, 0, 0, 1},
    {1, 0, 0, 0, 1},
    {0, 1, 1, 1, 0}
  },
  { // 9
    {0, 1, 1, 1, 0},
    {1, 0, 0, 0, 1},
    {1, 0, 0, 0, 1},
    {0, 1, 1, 1, 1},
    {0, 0, 0, 0, 1},
    {1, 0, 0, 0, 1},
    {0, 1, 1, 1, 0}
  }
};

// Color Palettes
String[][] PALETTES = {
  {"#0511F2", "#0524F2", "#0787F2", "#F27405", "#F24405"},
  {"#1A1A1A", "#4E4E4E", "#00FF41", "#008F11", "#003B00"},
  {"#F20587", "#F20544", "#05F292", "#05F2DB", "#0587F2"},
  {"#2E0927", "#D90000", "#FF2D00", "#FF8C00", "#04756F"},
  {"#FFFFFF", "#CCCCCC", "#999999", "#666666", "#333333"}
};

// --- Internal Variables ---
float cellW, cellH;
int bgColor, accentColor;
int digitBoxW, digitBoxH;
boolean[][] activeCells;
float[][] pulsePhases;
float[][] pulseSpeeds;
int totalCycleFrames;
int chaosFrames, clockFrames;

void setup() {
  size(480, 800);
  pixelDensity(1);
  randomSeed(GLOBAL_SEED);
  frameRate(ANIMATION_SPEED);
  
  cellW = (width - 2 * PADDING) / GRID_COLS;
  cellH = (height - 2 * PADDING) / GRID_ROWS;
  
  digitBoxW = (GRID_COLS - GUTTER) / 2; 
  digitBoxH = (GRID_ROWS - (2 * GUTTER)) / 3;

  String[] activePalette = PALETTES[PALETTE_INDEX];
  if (INVERT_BG) {
    bgColor = color(255);
    accentColor = unhex("FF" + activePalette[0].substring(1));
  } else {
    bgColor = unhex("FF" + activePalette[0].substring(1));
    accentColor = unhex("FF" + activePalette[2].substring(1));
  }
  
  activeCells = new boolean[GRID_COLS][GRID_ROWS];
  pulsePhases = new float[GRID_COLS][GRID_ROWS];
  pulseSpeeds = new float[GRID_COLS][GRID_ROWS];
  
  for (int i = 0; i < GRID_COLS; i++) {
    for (int j = 0; j < GRID_ROWS; j++) {
      pulsePhases[i][j] = random(TWO_PI);
      pulseSpeeds[i][j] = random(MIN_PULSE_SPD, MAX_PULSE_SPD);
    }
  }

  chaosFrames = int(DURATION_CHAOS * ANIMATION_SPEED);
  clockFrames = int(DURATION_CLOCK * ANIMATION_SPEED);
  totalCycleFrames = chaosFrames + clockFrames;
}

void draw() {
  background(bgColor);
  
  for (int i = 0; i < GRID_COLS; i++) {
    for (int j = 0; j < GRID_ROWS; j++) {
      activeCells[i][j] = false;
    }
  }
  
  updateTimeGrid();
  
  int currentCycleFrame = frameCount % totalCycleFrames;
  float transitionProgress;

  if (currentCycleFrame < chaosFrames) {
    // Phase 1: Chaos to Clock
    float linearNorm = map(currentCycleFrame, 0, chaosFrames, 0.0, 1.0);
    transitionProgress = (1.0 - cos(linearNorm * PI)) / 2.0;
  } else {
    // Phase 2: Clock back to Chaos
    float linearNorm = map(currentCycleFrame, chaosFrames, totalCycleFrames, 0.0, 1.0);
    transitionProgress = (1.0 + cos(linearNorm * PI)) / 2.0; // Inverted cosine for ease-out
  }
  
  renderGrid(transitionProgress);
  
  if (SHOW_GRID) drawGridOverlay();

  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) noLoop();
  }
}

void updateTimeGrid() {
  int hRaw = hour();
  if (!USE_24H) {
    hRaw = hRaw % 12;
    if (hRaw == 0) hRaw = 12;
  }
  
  String timeStr = nf(hRaw, 2) + nf(minute(), 2) + nf(second(), 2);
  
  int totalW = (2 * digitBoxW) + GUTTER;
  int totalH = (3 * digitBoxH) + (2 * GUTTER);
  int startX = (GRID_COLS - totalW) / 2;
  int startY = (GRID_ROWS - totalH) / 2;

  for (int i = 0; i < 6; i++) {
    int val = Character.getNumericValue(timeStr.charAt(i));
    int colIdx = i % 2;
    int rowIdx = i / 2;
    int offsetX = startX + (colIdx * (digitBoxW + GUTTER));
    int offsetY = startY + (rowIdx * (digitBoxH + GUTTER));
    mapFontToGrid(val, offsetX, offsetY);
  }
}

void mapFontToGrid(int digit, int offsetX, int offsetY) {
  int startX = (digitBoxW - 5) / 2;
  int startY = (digitBoxH - 7) / 2;
  for (int r = 0; r < 7; r++) {
    for (int c = 0; c < 5; c++) {
      if (fontMatrix[digit][r][c] == 1) {
        int gx = offsetX + startX + c;
        int gy = offsetY + startY + r;
        if (gx >= 0 && gx < GRID_COLS && gy >= 0 && gy < GRID_ROWS) {
          activeCells[gx][gy] = true;
        }
      }
    }
  }
}

void renderGrid(float progress) {
  ellipseMode(CENTER);
  noStroke();
  
  float maxDiameter = cellW * MAX_GLYPH_SIZE_MULT;
  int currentBgAlpha = int(lerp(BG_ALPHA_CHAOS, BG_ALPHA_CLOCK, progress));

  for (int i = 0; i < GRID_COLS; i++) {
    for (int j = 0; j < GRID_ROWS; j++) {
      float centerX = PADDING + i * cellW + cellW / 2;
      float centerY = PADDING + j * cellH + cellH / 2;
      
      pulsePhases[i][j] += pulseSpeeds[i][j];
      float n = (sin(pulsePhases[i][j]) + 1) / 2.0; 
      float pulsingSize = lerp(cellW * 0.1, maxDiameter, n);

      if (activeCells[i][j]) {
        // Clock Cells Interpolation
        float currentSize = lerp(pulsingSize, maxDiameter, progress);
        int currentAlpha = int(lerp(BG_ALPHA_CHAOS, 255, progress));
        
        fill(accentColor, currentAlpha);
        ellipse(centerX, centerY, currentSize, currentSize);
      } else {
        // Background Cells constant pulse, varying alpha
        fill(accentColor, currentBgAlpha);
        ellipse(centerX, centerY, pulsingSize, pulsingSize);
      }
    }
  }
}

void drawGridOverlay() {
  stroke(accentColor, 40);
  strokeWeight(0.5);
  for (int i = 0; i <= GRID_COLS; i++) {
    line(PADDING + i * cellW, PADDING, PADDING + i * cellW, height - PADDING);
  }
  for (int j = 0; j <= GRID_ROWS; j++) {
    line(PADDING, PADDING + j * cellH, width - PADDING, PADDING + j * cellH);
  }
}
