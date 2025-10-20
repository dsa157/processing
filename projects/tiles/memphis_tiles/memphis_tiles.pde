// ====================================================================
// VERSION
// ====================================================================

// Version: 2025.10.15.14.21.30

// ====================================================================
// PARAMETERS
// ====================================================================

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
final int PADDING = 10; // default 40

// Color inversion
final boolean INVERT_COLORS = false; // default false

// Shape Control
final boolean USE_RANDOM_SHAPE1 = true; // default true
final boolean USE_RANDOM_SHAPE2 = true; // default true
final boolean USE_RANDOM_SHAPE3 = true; // default true

// ====================================================================
// COLORS (Adobe Kuler Palettes)
// ====================================================================

// Palette 1: Dark Teal, Red/Rust, Gold (Original)
final String[] PALETTE1 = {
  "#283d3b", // Dark Teal/Green (0)
  "#c44536", // Red/Rust (1)
  "#772e25", // Dark Red/Brown (2)
  "#d6a244", // Gold/Mustard (3)
  "#f1f3f4"  // Off-White (4)
};

// Palette 2: Blue/Gray, Yellow, Maroon (Classic Vintage)
final String[] PALETTE2 = {
  "#4d5382", // Slate Blue (0)
  "#c7b198", // Pale Tan (1)
  "#b23a48", // Dark Red (2)
  "#e3c153", // Muted Yellow (3)
  "#f4f9f9"  // Lightest Gray (4)
};

// Palette 3: Deep Ocean, Sunset Orange, Sand (Vibrant Contrast)
final String[] PALETTE3 = {
  "#003049", // Deep Navy (0)
  "#d62828", // Bright Red (1)
  "#f77f00", // Orange (2)
  "#fcbf49", // Gold/Sand (3)
  "#eae2b7"  // Cream (4)
};

// Palette 4: High-Key Cyan and Magenta (New, High Contrast)
final String[] PALETTE4 = {
  "#FFFFFF", // Pure White (0) - Lightest
  "#00D0FF", // Bright Cyan (1)
  "#FF00C8", // Bright Magenta (2)
  "#FFE700", // Bright Yellow (3)
  "#212121"  // Very Dark Gray (4) - Darkest
};

// Palette 5: Dark, Saturated Jewel Tones (New, High Contrast)
final String[] PALETTE5 = {
  "#141E30", // Deep Night Blue (0) - Darkest
  "#FF6B6B", // Coral Red (1)
  "#5D5D81", // Muted Violet (2)
  "#FFC300", // Bright Gold (3)
  "#F5F5F5"  // Near White (4) - Lightest
};

// Global palette setup
final String[][] ALL_PALETTES = {
  PALETTE1, PALETTE2, PALETTE3, PALETTE4, PALETTE5
};

// Parameter to choose which palette to use (0-indexed: 0=PALETTE1, 1=PALETTE2, etc.)
final int ACTIVE_PALETTE_INDEX = 3; // default 0 

String[] currentPalette;

final int BACKGROUND_PALETTE_INDEX = 4; // default 4 (Usually the lightest/darkest)

// ====================================================================
// TILING PARAMETERS
// ====================================================================

final int TILE_GRID_SIZE = 50; // default 50
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

// Seeding
final long GLOBAL_SEED = 1223345; // default 12345

// ====================================================================
// GLOBAL VARIABLES
// ====================================================================

ArrayList<Tile> tiles;
IntList availableShapes; // Stores the IDs of shapes to be used
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

    // Use currentPalette for shape colors
    int colorA = hexToColor(currentPalette[1]); // Often a bright color
    int colorB = hexToColor(currentPalette[3]); // Often a medium/accent color
    int colorC = hexToColor(currentPalette[2]); // Often a secondary/muted color
    int strokeColor = foregroundShade;

    stroke(strokeColor);
    // Use the FIXED pixel line thickness
    strokeWeight(FIXED_LINE_THICKNESS);
    noFill();

    // Subtle base wash that changes periodically
    if (random(1) < 0.2) {
      fill(colorC, 10);
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
  
  // Set the current palette based on the parameter
  currentPalette = ALL_PALETTES[ACTIVE_PALETTE_INDEX % ALL_PALETTES.length];
  
  // Initialize availableShapes list based on parameters
  availableShapes = new IntList();
  if (USE_RANDOM_SHAPE1) availableShapes.append(1);
  if (USE_RANDOM_SHAPE2) availableShapes.append(2);
  if (USE_RANDOM_SHAPE3) availableShapes.append(3);

  // If no shapes are enabled, fall back to a single default shape to prevent errors
  if (availableShapes.size() == 0) {
      println("Warning: No shapes enabled. Defaulting to Shape 1.");
      availableShapes.append(1); 
  }

  float sketchW = SKETCH_WIDTH - 2 * PADDING;
  float sketchH = SKETCH_HEIGHT - 2 * PADDING;
  gridCols = floor(sketchW / TILE_GRID_SIZE);
  gridRows = floor(sketchH / TILE_GRID_SIZE);
  gridMap = new int[gridCols][gridRows];

  for (int c = 0; c < gridCols; c++) {
    for (int r = 0; r < gridRows; r++) gridMap[c][r] = -1;
  }

  int initialBackground = hexToColor(currentPalette[BACKGROUND_PALETTE_INDEX]);
  
  // Determine foreground/background contrast
  if (isBrightColor(initialBackground)) {
    // Background is bright, foreground should be dark (index 0 is typically the darkest)
    foregroundShade = hexToColor(currentPalette[0]);
    backgroundShade = initialBackground;
  } else {
    // Background is dark, foreground should be light (index 4 is typically the lightest)
    foregroundShade = hexToColor(currentPalette[4]);
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
 * Tile generation method 1: Standard, large-block biased packing.
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
            // Re-check 1x1 placement availability
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
            
            // Select a shape from the pre-filtered list
            int shapeType = availableShapes.get(floor(random(availableShapes.size())));
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
            
            // CRITICAL: Advance the column counter by the width of the tile just placed
            c += tileCols; 
            
        } else {
            // Should theoretically not happen if the fallback to 1x1 is used, but for safety:
            c++;
        }
      } else {
        // This cell is already occupied or out of bounds. Move to the next cell.
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
    if (idx >= 0 && idx < tiles.size()) tiles.get(idx).isDead = true; 
  }
  
  // 4. Perform the full cleanup and index rebuild now, *before* placing new tiles.
  cleanupTiles(); 

  // 5. Generate new tiles only within the patch bounds - Using the one generation method
  generateTilesInPatch(startCol, startRow, PATCH_COLS, PATCH_ROWS);
}

// ====================================================================
// SHAPE GENERATION (Memphis-style)
// ====================================================================

/**
 * Shape 1: Diagonal Division with Squiggle.
 * Uses a strong diagonal line and fills one side with a color, then adds a squiggly accent.
 */
void randomShape1(float w, float h, int fillA, int fillB, int fillC, int strokeC) {
  // 1. Draw a background fill (optional)
  noStroke();
  fill(fillC, 120);
  rect(0, 0, w, h);

  // 2. Draw a geometric half-fill
  if (random(1) < 0.7) {
    fill(fillA);
    stroke(strokeC);
    strokeWeight(FIXED_LINE_THICKNESS);

    beginShape();
    vertex(0, 0);
    vertex(w, 0);
    if (random(1) < 0.5) { // Top-right triangle
      vertex(0, h);
    } else { // Bottom-right polygon
      vertex(w, h);
      vertex(0, h);
    }
    endShape(CLOSE);
  }

  // 3. Add a thick, squiggly line accent (Stroke is controlled globally)
  noFill();
  stroke(fillB);
  strokeWeight(FIXED_LINE_THICKNESS * 2);
  
  if (random(1) < 0.8) {
    // Squiggle effect using bezier curves
    float startX = w * random(0.1, 0.4);
    float startY = h * random(0.1, 0.4);
    float endX = w * random(0.6, 0.9);
    float endY = h * random(0.6, 0.9);
    
    bezier(startX, startY,
           w * random(0.1, 0.9), h * random(0.0, 1.0),
           w * random(0.0, 1.0), h * random(0.1, 0.9),
           endX, endY);
  }
}

/**
 * Shape 2: Overlapping Basic Forms with Dots.
 * Focuses on stacking simple shapes (rect/ellipse) and patterning with small dots.
 */
void randomShape2(float w, float h, int fillA, int fillB, int fillC, int strokeC) {
  float cx = w / 2;
  float cy = h / 2;
  float minDim = min(w, h);
  
  // 1. Large background circle (off-center)
  fill(fillC);
  stroke(strokeC);
  strokeWeight(FIXED_LINE_THICKNESS);
  ellipse(w * random(0.3, 0.7), h * random(0.3, 0.7), minDim * 0.8, minDim * 0.8);
  
  // 2. Layered rectangle (Center-aligned)
  fill(fillA);
  noStroke();
  rectMode(CENTER);
  rect(cx, cy, w * 0.4, h * 0.4);
  rectMode(CORNER);
  
  // 3. Strong outline cross or diagonal
  stroke(strokeC);
  noFill();
  strokeWeight(FIXED_LINE_THICKNESS * 1.5);
  if (random(1) < 0.5) {
    line(0, h, w, 0); // Diagonal
  } else {
    line(cx, 0, cx, h); // Vertical
  }
  
  // 4. Dot pattern overlay (Memphis texture)
  if (random(1) < 0.8) {
    int numDots = floor(random(10, 20));
    float dotSize = minDim * 0.05;
    fill(fillB);
    noStroke();
    for (int i = 0; i < numDots; i++) {
      ellipse(random(w), random(h), dotSize, dotSize);
    }
  }
}

/**
 * Shape 3: Geometric Grid & Pattern Play.
 * Uses strict grid division and fills quadrants/sections with different colors and line patterns.
 */
void randomShape3(float w, float h, int fillA, int fillB, int fillC, int strokeC) {
  float thirdW = w / 3;
  float thirdH = h / 3;
  
  // 1. Draw central core shape
  fill(fillC);
  stroke(strokeC);
  strokeWeight(FIXED_LINE_THICKNESS);
  rect(thirdW, thirdH, thirdW, thirdH); // Central 1/3 square

  // 2. Apply a random diagonal line pattern to the corners
  strokeWeight(FIXED_LINE_THICKNESS * 0.5);
  noFill();
  int numLines = floor(random(3, 8));
  
  // Top-Left Quarter pattern
  if (random(1) < 0.5) {
    stroke(fillB);
    for (int i = 0; i < numLines; i++) {
      line(0, i * thirdH / numLines, thirdW, 0);
    }
  }
  
  // Bottom-Right Quarter pattern
  if (random(1) < 0.5) {
    stroke(fillA);
    for (int i = 0; i < numLines; i++) {
      // Adjusted coordinates to draw the pattern in the corner space
      line(w - i * thirdW / numLines, h, w, h - thirdH / 2 + i * thirdH / numLines);
    }
  }
  
  // 3. Add an intersecting, high-contrast block (top or bottom center)
  if (random(1) < 0.7) {
    fill(fillA);
    stroke(strokeC);
    strokeWeight(FIXED_LINE_THICKNESS);
    if (random(1) < 0.5) {
      rect(thirdW, 0, thirdW, thirdH / 2); // Top overlay
    } else {
      rect(0, h - thirdH / 2, w, thirdH / 2); // Bottom bar overlay
    }
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
