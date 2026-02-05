/*
 * Kinetic Raster Clock
 * Version: 2026.02.05.18.15.42
 * Features: Seamless glyph morphing between cycles.
 * Fixed radar rotation and eased phase transitions.
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
float PHASE_DIVERSITY = 1.0;  // Default: 1.0
int GUTTER = 1;               // Gap between digits

// Glyph Style Parameters
int GLYPH_STYLE = 0;          // Initial Style (0-4)
boolean CYCLE_GLYPH_STYLE = true; 

// Alpha Parameters
int BG_ALPHA_CHAOS = 100;     // Default: 100
int BG_ALPHA_CLOCK = 40;      // Default: 40

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
int totalCycleFrames, chaosFrames;
int currentStyle = 0;
int nextStyle = 0;
int lastCycleFrame = -1;

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
      pulsePhases[i][j] = random(TWO_PI) * PHASE_DIVERSITY;
      pulseSpeeds[i][j] = random(MIN_PULSE_SPD, MAX_PULSE_SPD);
    }
  }

  chaosFrames = int(DURATION_CHAOS * ANIMATION_SPEED);
  totalCycleFrames = chaosFrames + int(DURATION_CLOCK * ANIMATION_SPEED);
  currentStyle = GLYPH_STYLE;
  nextStyle = GLYPH_STYLE;
}

void draw() {
  background(bgColor);
  for (int i = 0; i < GRID_COLS; i++) {
    for (int j = 0; j < GRID_ROWS; j++) activeCells[i][j] = false;
  }
  
  updateTimeGrid();
  
  int currentCycleFrame = frameCount % totalCycleFrames;
  
  // Logic to determine when to trigger the next style
  if (currentCycleFrame < lastCycleFrame) {
    currentStyle = nextStyle;
    if (CYCLE_GLYPH_STYLE) nextStyle = (currentStyle + 1) % 5;
  }
  lastCycleFrame = currentCycleFrame;

  float t; // Global transition progress
  float morphT; // Internal morphing progress (only during chaos)

  if (currentCycleFrame < chaosFrames) {
    float norm = map(currentCycleFrame, 0, chaosFrames, 0, 1);
    t = (1.0 - cos(norm * PI)) / 2.0;
    // Morph happens specifically while the clock is faded out
    morphT = norm; 
  } else {
    float norm = map(currentCycleFrame, chaosFrames, totalCycleFrames, 0, 1);
    t = (1.0 + cos(norm * PI)) / 2.0;
    morphT = 1.0;
  }
  
  renderGrid(t, morphT);
  if (SHOW_GRID) drawGridOverlay();

  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) noLoop();
  }
}

void updateTimeGrid() {
  int hRaw = hour();
  if (!USE_24H) { hRaw = hRaw % 12; if (hRaw == 0) hRaw = 12; }
  String timeStr = nf(hRaw, 2) + nf(minute(), 2) + nf(second(), 2);
  int startX = (GRID_COLS - (2 * digitBoxW + GUTTER)) / 2;
  int startY = (GRID_ROWS - (3 * digitBoxH + 2 * GUTTER)) / 2;

  for (int i = 0; i < 6; i++) {
    int val = Character.getNumericValue(timeStr.charAt(i));
    int offsetX = startX + ((i % 2) * (digitBoxW + GUTTER));
    int offsetY = startY + ((i / 2) * (digitBoxH + GUTTER));
    int sX = (digitBoxW - 5) / 2;
    int sY = (digitBoxH - 7) / 2;
    for (int r = 0; r < 7; r++) {
      for (int c = 0; c < 5; c++) {
        if (fontMatrix[val][r][c] == 1) {
          int gx = offsetX + sX + c;
          int gy = offsetY + sY + r;
          if (gx >= 0 && gx < GRID_COLS && gy >= 0 && gy < GRID_ROWS) activeCells[gx][gy] = true;
        }
      }
    }
  }
}

void renderGrid(float t, float morphT) {
  ellipseMode(CENTER);
  float maxD = cellW * MAX_GLYPH_SIZE_MULT;
  int bgAlpha = int(lerp(BG_ALPHA_CHAOS, BG_ALPHA_CLOCK, t));

  for (int i = 0; i < GRID_COLS; i++) {
    for (int j = 0; j < GRID_ROWS; j++) {
      float cx = PADDING + i * cellW + cellW/2;
      float cy = PADDING + j * cellH + cellH/2;
      
      pulsePhases[i][j] += pulseSpeeds[i][j];
      float n = (sin(pulsePhases[i][j]) + 1) / 2.0;
      
      int finalAlpha = activeCells[i][j] ? int(lerp(BG_ALPHA_CHAOS, 255, t)) : bgAlpha;
      
      // Cross-fade drawing between current and next style
      if (morphT < 1.0 && currentStyle != nextStyle) {
        push();
        tint(255, (1.0 - morphT) * 255);
        drawGlyph(cx, cy, n, t, activeCells[i][j], int(finalAlpha * (1.0 - morphT)), maxD, currentStyle);
        pop();
        push();
        tint(255, morphT * 255);
        drawGlyph(cx, cy, n, t, activeCells[i][j], int(finalAlpha * morphT), maxD, nextStyle);
        pop();
      } else {
        drawGlyph(cx, cy, n, t, activeCells[i][j], finalAlpha, maxD, nextStyle);
      }
    }
  }
}

void drawGlyph(float x, float y, float n, float t, boolean active, int alpha, float maxD, int style) {
  push();
  translate(x, y);
  stroke(accentColor, alpha);
  fill(accentColor, alpha);
  
  float curSize = lerp(cellW * 0.1, maxD, n);
  if (active) curSize = lerp(curSize, maxD, t);

  switch(style) {
    case 0: // Solid Dot
      noStroke();
      ellipse(0, 0, curSize, curSize);
      break;
    case 1: // Ring
      noFill();
      strokeWeight(lerp(0.5, 2.0, t));
      ellipse(0, 0, curSize, curSize);
      break;
    case 2: // Target
      noStroke();
      ellipse(0, 0, curSize * 0.3, curSize * 0.3);
      noFill();
      strokeWeight(0.5);
      ellipse(0, 0, curSize, curSize);
      break;
    case 3: // Radar
      noFill();
      strokeWeight(1.5);
      rotate(pulsePhases[(int)(x/cellW)%GRID_COLS][(int)(y/cellH)%GRID_ROWS] * 0.5);
      arc(0, 0, curSize, curSize, 0, HALF_PI);
      break;
    case 4: // Flower
      noFill();
      strokeWeight(0.5);
      for (int i = 1; i <= 3; i++) {
        float s = curSize * (i / 3.0);
        ellipse(0, 0, s, s);
      }
      break;
  }
  pop();
}

void drawGridOverlay() {
  stroke(accentColor, 40);
  strokeWeight(0.5);
  for (int i = 0; i <= GRID_COLS; i++) line(PADDING + i * cellW, PADDING, PADDING + i * cellW, height - PADDING);
  for (int j = 0; j <= GRID_ROWS; j++) line(PADDING, PADDING + j * cellH, width - PADDING, PADDING + j * cellH);
}
