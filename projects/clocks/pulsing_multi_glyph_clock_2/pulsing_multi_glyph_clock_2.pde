/*
 * Kinetic Raster Clock
 * Version: 2026.02.05.18.45.30
 * Fixes: Guaranteed visibility of background cells at clock peak.
 * Optimized phase transition and persistent grid properties.
 */

// --- Parameters ---
int MAX_FRAMES = 900;         // Default: 900
boolean SAVE_FRAMES = false;  // Default: false
int ANIMATION_SPEED = 30;     // Default: 30
int GLOBAL_SEED = 42;         // Default: 42
float PADDING = 40;           // Default: 40

int GRID_COLS = 11;           // User Adjusted: 11
int GRID_ROWS = 25;           // User Adjusted: 25
boolean SHOW_GRID = false;     // Default: true

boolean USE_24H = false;      // Default: false
int PALETTE_INDEX = 1;        // User Adjusted: 1
boolean INVERT_BG = false;    // Default: false

float MIN_PULSE_SPD = 0.15;   // User Adjusted: 0.15
float MAX_PULSE_SPD = 0.25;   // User Adjusted: 0.25
float MAX_GLYPH_SIZE_MULT = 0.65; // User Adjusted: 0.65
float PHASE_DIVERSITY = 1.0;  // Default: 1.0
int GUTTER = 1;               // Gap between digits

// Glyph Style Parameters
// Styles: 0:Solid Dot, 1:Ring, 2:Target, 3:Radar, 4:Flower
int GLYPH_STYLE = 0;          
boolean CYCLE_GLYPH_STYLE = true; 
boolean RANDOM_BG_GLYPHS = true;  

// Animation Toggles
boolean BG_COLOR_SHIFT = false;   

// Alpha Parameters
int BG_ALPHA_CHAOS = 255;     // User Adjusted: 200
int BG_ALPHA_CLOCK = 20;     // User Adjusted: 140

// Phase Timing (Seconds)
float DURATION_CHAOS = 10.0;  // User Adjusted: 10
float DURATION_CLOCK = 15.0;  // User Adjusted: 15

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
// 0: Deep Blues, 1: Matrix, 2: Neon, 3: Fire, 4: Grayscale
String[][] PALETTES = {
  {"#0511F2", "#0524F2", "#0787F2", "#F27405", "#F24405"},
  {"#1A1A1A", "#4E4E4E", "#00FF41", "#008F11", "#003B00"},
  {"#F20587", "#F20544", "#05F292", "#05F2DB", "#0587F2"},
  {"#2E0927", "#D90000", "#FF2D00", "#FF8C00", "#04756F"},
  {"#FFFFFF", "#CCCCCC", "#999999", "#666666", "#333333"}
};

// --- Internal Variables ---
float cellW, cellH;
int bgColor, accentColor, altColor;
int digitBoxW, digitBoxH;
boolean[][] activeCells;
float[][] pulsePhases;
float[][] pulseSpeeds;
int[][] cellGlyphStyles;

void setup() {
  size(480, 800);
  pixelDensity(1);
  randomSeed(GLOBAL_SEED);
  
  cellW = (width - 2 * PADDING) / GRID_COLS;
  cellH = (height - 2 * PADDING) / GRID_ROWS;
  digitBoxW = (GRID_COLS - GUTTER) / 2; 
  digitBoxH = (GRID_ROWS - (2 * GUTTER)) / 3;

  updatePaletteColors();
  
  activeCells = new boolean[GRID_COLS][GRID_ROWS];
  pulsePhases = new float[GRID_COLS][GRID_ROWS];
  pulseSpeeds = new float[GRID_COLS][GRID_ROWS];
  cellGlyphStyles = new int[GRID_COLS][GRID_ROWS];
  
  for (int i = 0; i < GRID_COLS; i++) {
    for (int j = 0; j < GRID_ROWS; j++) {
      pulsePhases[i][j] = random(TWO_PI) * PHASE_DIVERSITY;
      pulseSpeeds[i][j] = random(MIN_PULSE_SPD, MAX_PULSE_SPD);
      cellGlyphStyles[i][j] = floor(random(5));
    }
  }
}

void updatePaletteColors() {
  String[] activePalette = PALETTES[PALETTE_INDEX];
  if (INVERT_BG) {
    bgColor = color(255);
    accentColor = unhex("FF" + activePalette[0].substring(1));
    altColor = unhex("FF" + activePalette[3].substring(1));
  } else {
    bgColor = unhex("FF" + activePalette[0].substring(1));
    accentColor = unhex("FF" + activePalette[2].substring(1));
    altColor = unhex("FF" + activePalette[4].substring(1));
  }
}

void draw() {
  background(bgColor);
  for (int i = 0; i < GRID_COLS; i++) {
    for (int j = 0; j < GRID_ROWS; j++) activeCells[i][j] = false;
  }
  
  updateTimeGrid();
  
  float totalCycleTime = DURATION_CHAOS + DURATION_CLOCK;
  float currentTime = (millis() / 1000.0) % totalCycleTime;
  
  float t; 
  if (currentTime < DURATION_CHAOS) {
    float norm = currentTime / DURATION_CHAOS;
    t = (1.0 - cos(norm * PI)) / 2.0; 
  } else {
    float norm = (currentTime - DURATION_CHAOS) / DURATION_CLOCK;
    t = (1.0 + cos(norm * PI)) / 2.0;
  }
  
  renderGrid(t);
  
  if (SHOW_GRID) drawGridOverlay();

  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) noLoop();
  }
}

void updateTimeGrid() {
  int hRaw = hour();
  if (!USE_24H) { hRaw = hRaw % 12; if (hRaw == 12) hRaw = 12; else if (hRaw == 0) hRaw = 12; }
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
          int gy = offsetY + startY + r;
          if (gx >= 0 && gx < GRID_COLS && gy >= 0 && gy < GRID_ROWS) activeCells[gx][gy] = true;
        }
      }
    }
  }
}

void renderGrid(float t) {
  ellipseMode(CENTER);
  float maxD = cellW * MAX_GLYPH_SIZE_MULT;
  
  // Background alpha is always calculated
  int currentBgAlpha = int(lerp(BG_ALPHA_CHAOS, BG_ALPHA_CLOCK, t));

  for (int i = 0; i < GRID_COLS; i++) {
    for (int j = 0; j < GRID_ROWS; j++) {
      float cx = PADDING + i * cellW + cellW/2;
      float cy = PADDING + j * cellH + cellH/2;
      
      pulsePhases[i][j] += pulseSpeeds[i][j];
      float n = (sin(pulsePhases[i][j]) + 1) / 2.0;
      
      int drawColor = activeCells[i][j] ? accentColor : (BG_COLOR_SHIFT ? lerpColor(accentColor, altColor, t) : accentColor);
      
      if (activeCells[i][j]) {
        // Morphing logic for clock cells: Style 0 (Stationary) vs Chaos Style
        int chaosStyle = RANDOM_BG_GLYPHS ? cellGlyphStyles[i][j] : GLYPH_STYLE;
        int clockAlpha = int(lerp(BG_ALPHA_CHAOS, 255, t));
        
        // Use a power curve for morphing back to chaos faster
        float morphT = (t < 0.5) ? pow(t * 2, 0.4) : 1.0; 
        
        if (t < 1.0) {
          // Morphing between Chaos Style and Clock Style 0
          drawGlyph(cx, cy, n, t, true, int(clockAlpha * (1.0 - morphT)), maxD, chaosStyle, drawColor);
          drawGlyph(cx, cy, n, t, true, int(clockAlpha * morphT), maxD, 0, drawColor);
        } else {
          drawGlyph(cx, cy, n, t, true, 255, maxD, 0, drawColor);
        }
      } else {
        // Background stays Background
        int bgStyle = RANDOM_BG_GLYPHS ? cellGlyphStyles[i][j] : GLYPH_STYLE;
        drawGlyph(cx, cy, n, t, false, currentBgAlpha, maxD, bgStyle, drawColor);
      }
    }
  }
}

void drawGlyph(float x, float y, float n, float clockT, boolean active, int alpha, float maxD, int style, int c) {
  if (alpha <= 0) return;
  push();
  translate(x, y);
  stroke(c, alpha);
  fill(c, alpha);
  
  // Size logic: background pulses, active clock cells lock to maxD at peak
  float pulseSize = lerp(cellW * 0.1, maxD, n);
  float finalSize = active ? lerp(pulseSize, maxD, clockT) : pulseSize;

  switch(style) {
    case 0: noStroke(); ellipse(0, 0, finalSize, finalSize); break;
    case 1: noFill(); strokeWeight(lerp(0.5, 2.0, clockT)); ellipse(0, 0, finalSize, finalSize); break;
    case 2: noStroke(); ellipse(0, 0, finalSize * 0.3, finalSize * 0.3); noFill(); strokeWeight(0.5); ellipse(0, 0, finalSize, finalSize); break;
    case 3: noFill(); strokeWeight(1.5); rotate(pulsePhases[(int)(x/cellW)%GRID_COLS][(int)(y/cellH)%GRID_ROWS] * 0.5); arc(0, 0, finalSize, finalSize, 0, HALF_PI); break;
    case 4: noFill(); strokeWeight(0.5); for (int i = 1; i <= 3; i++) { float s = finalSize * (i / 3.0); ellipse(0, 0, s, s); } break;
  }
  pop();
}

void drawGridOverlay() {
  stroke(accentColor, 40);
  strokeWeight(0.5);
  for (int i = 0; i <= GRID_COLS; i++) line(PADDING + i * cellW, PADDING, PADDING + i * cellW, height - PADDING);
  for (int j = 0; j <= GRID_ROWS; j++) line(PADDING, PADDING + j * cellH, width - PADDING, PADDING + j * cellH);
}
