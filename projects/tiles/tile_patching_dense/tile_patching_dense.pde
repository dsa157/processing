// ====================================================================
// VERSION
// ====================================================================

// Version: 2025.10.15.13.01.20

// ====================================================================
// PARAMETERS
// ====================================================================

// Seeding
final long GLOBAL_SEED = 157; // default 12345

// Canvas dimensions
int SKETCH_WIDTH = 480; // default 480
int SKETCH_HEIGHT = 800; // default 800

// Animation and saving
final int MAX_FRAMES = 900; // default 900
final boolean SAVE_FRAMES = false; // default false
final int ANIMATION_SPEED = 30; // default 30 (frames per second)
// Patch regeneration frequency: number of frames between each patch replacement (default 100)
final int PATCH_REFRESH_INTERVAL = 100; // default 100
// Animation tick speed: How quickly the internal tile random features change (default 10)
final int ANIMATION_TICK_RATE = 10; // default 10

// Line thickness
final float FIXED_LINE_THICKNESS = 2.0; // default 2.0 (Fixed pixel thickness)

// Layout
final int PADDING = 40; // default 40

// Color inversion
final boolean INVERT_COLORS = false; // default false

// ====================================================================
// COLORS (Adobe Kuler Palette)
// ====================================================================

final String[] PALETTE_HEX = {
  "#283d3b", // Dark Teal/Green (0)
  "#c44536", // Red/Rust (1)
  "#772e25", // Dark Red/Brown (2)
  "#d6a244", // Gold/Mustard (3)
  "#f1f3f4"  // Off-White (4)
};

final int BACKGROUND_PALETTE_INDEX = 4; // default 4 (Off-White)

// ====================================================================
// TILING PARAMETERS
// ====================================================================

final int TILE_GRID_SIZE = 10; // default 50
final boolean SHOW_TILE_GRID = false; // default false
final int[][] TILE_SIZES = {
  {1, 1},
  {2, 2},
  {3, 3},
  {2, 1},
  {1, 2},
  {3, 1},
  {1, 3}
};

// Patch Regeneration Parameters
final int PATCH_COLS = 3; // default 3
final int PATCH_ROWS = 3; // default 3


// ====================================================================
// GLOBAL VARIABLES
// ====================================================================

ArrayList<Tile> tiles;
int backgroundShade;
int foregroundShade;
int gridCols, gridRows;
int[][] gridMap; // stores indices of tiles occupying each grid cell (-1 = empty)
int animationTick = 0; // New variable to control periodic animation within tiles

// ====================================================================
// COLOR UTILITIES
// ====================================================================

int hexToColor(String hex) {
  if (hex.startsWith("#")) hex = hex.substring(1);
  return color(
    unhex(hex.substring(0, 2)),
    unhex(hex.substring(2, 4)),
    unhex(hex.substring(4, 6))
  );
}

float brightnessOfColor(int c) {
  return red(c) * 0.299 + green(c) * 0.587 + blue(c) * 0.114;
}

boolean isBrightColor(int c) {
  return brightnessOfColor(c) > 160;
}

// ====================================================================
// UTILITY
// ====================================================================

boolean intListContains(IntList list, int value) {
  for (int i = 0; i < list.size(); i++) {
    if (list.get(i) == value) return true;
  }
  return false;
}

// ====================================================================
// TILE CLASS
// ====================================================================

class Tile {
  float x, y, w, h;
  int shapeType;
  long localSeed;
  boolean isDead = false;

  Tile(float x, float y, float w, float h, int type, long seed) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.shapeType = type;
    this.localSeed = seed;
  }

  void drawShape() {
    if (isDead) return;

    pushMatrix();
    translate(x, y);
    
    // Use the localSeed combined with the periodic animationTick
    randomSeed(localSeed + animationTick); 

    int colorA = hexToColor(PALETTE_HEX[1]); // Red/Rust
    int colorB = hexToColor(PALETTE_HEX[3]); // Gold/Mustard
    int colorC = hexToColor(PALETTE_HEX[2]); // Dark Red/Brown
    int strokeColor = foregroundShade;

    stroke(strokeColor);
    // Use the FIXED pixel line thickness
    strokeWeight(FIXED_LINE_THICKNESS);
    noFill();

    // Subtle base wash that changes periodically
    if (random(1) < 0.2) {
      fill(strokeColor, 10);
      rect(0, 0, w, h);
      noFill();
    }

    switch (shapeType) {
      case 1: randomShape1(w, h, colorA, colorB, colorC, strokeColor); break;
      case 2: randomShape2(w, h, colorA, colorB, colorC, strokeColor); break;
      case 3: randomShape3(w, h, colorA, colorB, colorC, strokeColor); break;
    }
    popMatrix();
  }
}

// ====================================================================
// SETUP and DRAW
// ====================================================================

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  randomSeed(GLOBAL_SEED);
  frameRate(ANIMATION_SPEED);

  float sketchW = SKETCH_WIDTH - 2 * PADDING;
  float sketchH = SKETCH_HEIGHT - 2 * PADDING;
  gridCols = floor(sketchW / TILE_GRID_SIZE);
  gridRows = floor(sketchH / TILE_GRID_SIZE);
  gridMap = new int[gridCols][gridRows];

  for (int c = 0; c < gridCols; c++) {
    for (int r = 0; r < gridRows; r++) gridMap[c][r] = -1;
  }

  int initialBackground = hexToColor(PALETTE_HEX[BACKGROUND_PALETTE_INDEX]);
  if (isBrightColor(initialBackground)) {
    foregroundShade = hexToColor(PALETTE_HEX[0]);
    backgroundShade = initialBackground;
  } else {
    foregroundShade = hexToColor(PALETTE_HEX[4]);
    backgroundShade = initialBackground;
  }

  if (INVERT_COLORS) {
    int tmp = backgroundShade;
    backgroundShade = foregroundShade;
    foregroundShade = tmp;
  }

  tiles = new ArrayList<Tile>();
  generateTilesInPatch(0, 0, gridCols, gridRows);
}

void draw() {
  background(backgroundShade);

  float centeredX = (width - (SKETCH_WIDTH - 2 * PADDING)) / 2;
  float centeredY = (height - (SKETCH_HEIGHT - 2 * PADDING)) / 2;
  pushMatrix();
  translate(centeredX, centeredY);

  // Update the animation tick at the controlled rate
  if (frameCount > 0 && (frameCount % ANIMATION_TICK_RATE) == 0) {
    animationTick++;
  }

  for (Tile t : tiles) t.drawShape();

  popMatrix();

  // ------------------------------------------------------------------
  // FIXED INTERVAL LOGIC (Patch Regeneration)
  // ------------------------------------------------------------------
  if (frameCount > 0 && (frameCount % PATCH_REFRESH_INTERVAL) == 0) {
      regenerateRandomPatch();
  }
  // ------------------------------------------------------------------
  
  if (SHOW_TILE_GRID) drawTileGrid(centeredX, centeredY);
  
  // Code block for saving frames and stopping the loop
  if (SAVE_FRAMES) saveFrame("frames/####.tif");
  if (frameCount >= MAX_FRAMES) noLoop();
}

// ====================================================================
// TILE AND PATCH MANAGEMENT
// ====================================================================

/**
 * Generates and adds NEW tiles to the 'tiles' list within a specified grid area.
 * It includes a fallback to 1x1 tiles to guarantee all space is filled.
 * * FIX: Correctly advances the column counter 'c' by the width of the placed tile.
 */
void generateTilesInPatch(int startCol, int startRow, int numCols, int numRows) {
  // Use a changing seed for the patch layout itself 
  randomSeed((long) random(Long.MAX_VALUE) + frameCount); 

  for (int r = 0; r < numRows; r++) {
    for (int c = 0; c < numCols; ) { // NOTE: 'c' is advanced inside the loop body
      int globalC = startCol + c;
      int globalR = startRow + r;
      
      int tileCols = 0;
      int tileRows = 0;
      boolean placed = false;
      
      // Ensure we are within bounds and the cell is empty
      if (globalC < gridCols && globalR < gridRows && gridMap[globalC][globalR] == -1) {
        
        // 1. Attempt to place a randomly sized tile (2 attempts max)
        for (int attempt = 0; attempt < 2; attempt++) {
            int[] tileSize = TILE_SIZES[floor(random(TILE_SIZES.length))];
            tileCols = tileSize[0];
            tileRows = tileSize[1];
            
            // Check if the proposed tile fits within the patch/grid bounds
            if (c + tileCols <= numCols && r + tileRows <= numRows && globalC + tileCols <= gridCols && globalR + tileRows <= gridRows) {
              boolean canPlace = true;
              // Check if the proposed area is cleared in the global map
              for (int tc = 0; tc < tileCols; tc++) {
                for (int tr = 0; tr < tileRows; tr++) {
                  // The check needs to use global coordinates
                  if (gridMap[globalC + tc][globalR + tr] != -1) {
                    canPlace = false;
                    break;
                  }
                }
                if (!canPlace) break;
              }

              if (canPlace) {
                placed = true;
                break; 
              }
            }
        }
        
        // 2. Fallback: If placement failed, force a 1x1 tile.
        if (!placed) {
            // Re-check 1x1 placement availability, though it should be available here
            if (globalC < gridCols && globalR < gridRows && gridMap[globalC][globalR] == -1) {
                tileCols = 1;
                tileRows = 1;
                placed = true;
            }
        }

        // 3. Finalize placement
        if (placed) {
            float tileX = globalC * TILE_GRID_SIZE;
            float tileY = globalR * TILE_GRID_SIZE;
            float tileW = tileCols * TILE_GRID_SIZE;
            float tileH = tileRows * TILE_GRID_SIZE;
            
            int shapeType = floor(random(1, 4));
            long localSeed = (long) random(Long.MAX_VALUE); 
            
            Tile newTile = new Tile(tileX, tileY, tileW, tileH, shapeType, localSeed);
            tiles.add(newTile);
            int newTileIndex = tiles.size() - 1;

            // Update the global gridMap
            for (int tc = 0; tc < tileCols; tc++) {
              for (int tr = 0; tr < tileRows; tr++) {
                gridMap[globalC + tc][globalR + tr] = newTileIndex;
              }
            }
            
            // CRITICAL FIX: Advance the column counter by the width of the tile just placed
            c += tileCols; 
            
        } else {
            // Should theoretically not happen if the fallback to 1x1 is used, but for safety:
            c++;
        }
      } else {
        // This cell is already occupied (e.g., by a tile started at c-1) or out of bounds. Move to the next cell.
        c++;
      }
    }
  }
}

/**
 * Optimized cleanup to be called mid-process.
 */
void cleanupTiles() {
    ArrayList<Tile> liveTiles = new ArrayList<Tile>();
    for (Tile t : tiles) if (!t.isDead) liveTiles.add(t);
    tiles = liveTiles;
    
    // Completely rebuild the gridMap based on the remaining tiles
    for (int c = 0; c < gridCols; c++)
        for (int r = 0; r < gridRows; r++)
            gridMap[c][r] = -1;
    
    // Repopulate the grid map with the new, reduced indices
    for (int i = 0; i < tiles.size(); i++) {
        Tile t = tiles.get(i);
        int tc = floor(t.x / TILE_GRID_SIZE);
        int tr = floor(t.y / TILE_GRID_SIZE);
        int tCols = floor(t.w / TILE_GRID_SIZE);
        int tRows = floor(t.h / TILE_GRID_SIZE);
        
        for (int c = 0; c < tCols; c++) {
            for (int r = 0; r < tRows; r++) {
                if (tc + c < gridCols && tr + r < gridRows) {
                    gridMap[tc + c][tr + r] = i;
                }
            }
        }
    }
}

void regenerateRandomPatch() {
  // 1. Choose a random starting cell for the patch
  // Ensure the patch fits entirely within the grid
  int startCol = floor(random(gridCols - PATCH_COLS + 1));
  int startRow = floor(random(gridRows - PATCH_ROWS + 1));
  int endCol = startCol + PATCH_COLS;
  int endRow = startRow + PATCH_ROWS;

  // 2. Mark intersecting tiles as dead and clear the grid map cells
  IntList tilesToMarkDeadIndices = new IntList();
  for (int c = startCol; c < endCol; c++) {
    for (int r = startRow; r < endRow; r++) {
      
      int tileIndex = gridMap[c][r];
      
      if (tileIndex != -1 && !intListContains(tilesToMarkDeadIndices, tileIndex)) {
        tilesToMarkDeadIndices.append(tileIndex);
      }
      gridMap[c][r] = -1; // Clear the grid entry immediately
    }
  }

  // 3. Mark the tile objects as dead
  for (int i = 0; i < tilesToMarkDeadIndices.size(); i++) {
    int idx = tilesToMarkDeadIndices.get(i);
    // Index check for safety
    if (idx >= 0 && idx < tiles.size()) tiles.get(idx).isDead = true; 
  }
  
  // 4. Perform the full cleanup and index rebuild now, *before* placing new tiles.
  cleanupTiles(); 

  // 5. Generate new tiles only within the patch bounds 
  generateTilesInPatch(startCol, startRow, PATCH_COLS, PATCH_ROWS);
}

// ====================================================================
// SHAPE GENERATION
// ====================================================================

/**
 * Shape 1: Layered rectangles with diagonal emphasis.
 */
void randomShape1(float w, float h, int fillA, int fillB, int fillC, int strokeC) {
  float step = min(w, h) * 0.15; // Consistent spacing
  
  // Base fill
  if (random(1) < 0.4) {
    fill(fillC, 150);
    noStroke();
    rect(0, 0, w, h);
  }

  // Concentric or layered rectangles
  noFill();
  stroke(strokeC);
  strokeWeight(FIXED_LINE_THICKNESS); // Fixed thickness
  int numLayers = floor(random(2, 4));
  
  for (int i = 0; i < numLayers; i++) {
    float sizeW = w - i * step * 2;
    float sizeH = h - i * step * 2;
    rect(i * step, i * step, sizeW, sizeH);
  }

  // Diagonal Line
  strokeWeight(FIXED_LINE_THICKNESS * random(0.8, 1.2)); // Slight variation for interest
  if (random(1) < 0.7) {
    if (random(1) < 0.5) line(0, 0, w, h);
    else line(w, 0, 0, h);
  }

  // Central circle accent
  if (random(1) < 0.6) {
    fill(fillA, 220);
    noStroke();
    float radius = min(w, h) * random(0.1, 0.3);
    ellipse(w / 2, h / 2, radius * 2, radius * 2);
  }
}

/**
 * Shape 2: Quadrant division with arcs and internal crosses.
 */
void randomShape2(float w, float h, int fillA, int fillB, int fillC, int strokeC) {
  float cx = w / 2;
  float cy = h / 2;
  float minDim = min(w, h);
  
  // Cross division
  stroke(strokeC);
  strokeWeight(FIXED_LINE_THICKNESS); // Fixed thickness
  if (random(1) < 0.8) line(cx, 0, cx, h);
  if (random(1) < 0.8) line(0, cy, w, cy);

  // Corner arcs (Quarter circles)
  noFill();
  float arcRadius = minDim * random(0.5, 1.0);
  strokeWeight(FIXED_LINE_THICKNESS); // Fixed thickness

  if (random(1) < 0.6) arc(0, 0, arcRadius * 2, arcRadius * 2, 0, HALF_PI);
  if (random(1) < 0.6) arc(w, 0, arcRadius * 2, arcRadius * 2, HALF_PI, PI);
  if (random(1) < 0.6) arc(w, h, arcRadius * 2, arcRadius * 2, PI, PI + HALF_PI);
  if (random(1) < 0.6) arc(0, h, arcRadius * 2, arcRadius * 2, PI + HALF_PI, TWO_PI);

  // Central filled shape (Rectangle or Ellipse)
  if (random(1) < 0.7) {
    fill(fillB, 200);
    noStroke();
    if (random(1) < 0.5) {
      rectMode(CENTER);
      rect(cx, cy, w * 0.3, h * 0.3);
      rectMode(CORNER);
    } else {
      ellipse(cx, cy, w * 0.4 * random(0.8, 1.2), h * 0.4 * random(0.8, 1.2));
    }
  }
}

/**
 * Shape 3: Abstract, overlapping, and complex polygons/sunbursts.
 */
void randomShape3(float w, float h, int fillA, int fillB, int fillC, int strokeC) {
  float cx = w / 2;
  float cy = h / 2;
  float radius = min(w, h) / 2;

  // 1. Central sunburst/spoke pattern
  stroke(strokeC);
  noFill();
  strokeWeight(FIXED_LINE_THICKNESS); // Fixed thickness
  int numLines = floor(random(5, 10));
  for (int i = 0; i < numLines; i++) {
    float angle = TWO_PI / numLines * i + radians(random(30));
    // Lines extend from center to near edge
    line(cx, cy, cx + cos(angle) * radius * random(0.7, 1.0), cy + sin(angle) * radius * random(0.7, 1.0));
  }

  // 2. Overlapping, filled polygon
  if (random(1) < 0.6) {
    fill(fillA, 180);
    strokeWeight(FIXED_LINE_THICKNESS); // Fixed thickness
    beginShape();
    int numPoints = floor(random(4, 7));
    for (int i = 0; i < numPoints; i++) {
        float px = w * random(0.1, 0.9);
        float py = h * random(0.1, 0.9);
        vertex(px, py);
    }
    endShape(CLOSE);
  }
  
  // 3. Small corner detail
  if (random(1) < 0.4) {
    fill(fillB, 255);
    noStroke();
    rect(w * 0.75, h * 0.75, w * 0.25, h * 0.25);
  }
}

// ====================================================================
// DEBUG GRID
// ====================================================================

void drawTileGrid(float xOffset, float yOffset) {
  stroke(foregroundShade, 50);
  strokeWeight(1);
  noFill();
  float sketchW = SKETCH_WIDTH - 2 * PADDING;
  float sketchH = SKETCH_HEIGHT - 2 * PADDING;

  pushMatrix();
  translate(xOffset, yOffset); 
  for (int x = 0; x <= sketchW; x += TILE_GRID_SIZE) line(x, 0, x, sketchH);
  for (int y = 0; y <= sketchH; y += TILE_GRID_SIZE) line(0, y, sketchW, y);
  popMatrix();
}
