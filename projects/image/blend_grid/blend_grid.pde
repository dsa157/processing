PImage img;

// -- GRID PARAMETERS
int ROWS = 10;
int COLS = 5;
int PADDING = 0;
boolean SHOW_GRID = true;

// -- VISUAL PARAMETERS
int BG_COLOR = 255;
boolean INVERT_BG = false;
color GRID_COLOR = 0;
float GRID_STROKE = 1.0;

// -- BLENDING
int[] blendModes = {
  BLEND, ADD, SUBTRACT, DARKEST, LIGHTEST, DIFFERENCE, EXCLUSION, MULTIPLY, SCREEN
};

// -- SCRIPT PARAMETERS
int SEED = 1;
int MAX_FRAMES = 600;
boolean SAVE_FRAMES = false;

// -- INTERNAL VARIABLES
float cellW, cellH;
int gridX, gridY;
int[][] gridDivision;

void setup() {
  size(480, 800);
  randomSeed(SEED);
  
  if (INVERT_BG) {
    BG_COLOR = 255 - BG_COLOR;
    GRID_COLOR = 255 - GRID_COLOR;
  }
  
  img = loadImage("img1.png");
  if (img.width != width || img.height != height) {
    img.resize(width, height);
  }
  
  cellW = (width - 2 * PADDING) / (float)COLS;
  cellH = (height - 2 * PADDING) / (float)ROWS;
  gridX = PADDING;
  gridY = PADDING;
  
  resetGrid();
}

void draw() {
  background(BG_COLOR);
  image(img, 0, 0);
  
  // Apply blending effects
  applyBlending();
  
  // Draw grid lines
  if (SHOW_GRID) {
    drawGridLines();
  }
  
  // Change grid division and blending modes every cycle
  if (frameCount % 60 == 0) {
    resetGrid();
  }

  // --- SCRIPT CONTROL
  if (SAVE_FRAMES && frameCount < MAX_FRAMES) {
    saveFrame("frames/####.tif");
  }
  if (frameCount >= MAX_FRAMES) {
    noLoop();
  }
}

void resetGrid() {
  gridDivision = new int[COLS][ROWS];
  for (int x = 0; x < COLS; x++) {
    for (int y = 0; y < ROWS; y++) {
      gridDivision[x][y] = (int)random(4);
    }
  }
}

void applyBlending() {
  for (int x = 0; x < COLS; x++) {
    for (int y = 0; y < ROWS; y++) {
      int division = gridDivision[x][y];
      
      switch (division) {
        case 0: // Full cell
          applySubCell(x, y, 1, 1);
          break;
        case 1: // 2x1 sub-grid
          applySubCell(x, y, 2, 1);
          break;
        case 2: // 1x2 sub-grid
          applySubCell(x, y, 1, 2);
          break;
        case 3: // 2x2 sub-grid
          applySubCell(x, y, 2, 2);
          break;
      }
    }
  }
}

void applySubCell(int x, int y, int subCols, int subRows) {
  float subCellW = cellW / subCols;
  float subCellH = cellH / subRows;
  
  for (int sc = 0; sc < subCols; sc++) {
    for (int sr = 0; sr < subRows; sr++) {
      int blendMode = blendModes[(int)random(blendModes.length)];
      PImage subImg = img.get(
        (int)(gridX + x * cellW + sc * subCellW), 
        (int)(gridY + y * cellH + sr * subCellH), 
        (int)subCellW, 
        (int)subCellH
      );
      
      tint(255, 255, 255);
      blend(subImg, 0, 0, subImg.width, subImg.height, (int)(gridX + x * cellW + sc * subCellW), (int)(gridY + y * cellH + sr * subCellH), (int)subCellW, (int)subCellH, blendMode);
    }
  }
}

void drawGridLines() {
  stroke(GRID_COLOR);
  strokeWeight(GRID_STROKE);
  noFill();
  
  for (int x = 0; x < COLS; x++) {
    for (int y = 0; y < ROWS; y++) {
      int division = gridDivision[x][y];
      
      switch (division) {
        case 0: // Full cell
          rect(gridX + x * cellW, gridY + y * cellH, cellW, cellH);
          break;
        case 1: // 2x1 sub-grid
          rect(gridX + x * cellW, gridY + y * cellH, cellW, cellH);
          line(gridX + x * cellW + cellW / 2, gridY + y * cellH, gridX + x * cellW + cellW / 2, gridY + y * cellH + cellH);
          break;
        case 2: // 1x2 sub-grid
          rect(gridX + x * cellW, gridY + y * cellH, cellW, cellH);
          line(gridX + x * cellW, gridY + y * cellH + cellH / 2, gridX + x * cellW + cellW, gridY + y * cellH + cellH / 2);
          break;
        case 3: // 2x2 sub-grid
          rect(gridX + x * cellW, gridY + y * cellH, cellW, cellH);
          line(gridX + x * cellW + cellW / 2, gridY + y * cellH, gridX + x * cellW + cellW / 2, gridY + y * cellH + cellH);
          line(gridX + x * cellW, gridY + y * cellH + cellH / 2, gridX + x * cellW + cellW, gridY + y * cellH + cellH / 2);
          break;
      }
    }
  }
}
