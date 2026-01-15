/**
 * Multi-Agent Truchet Maze Art
 * Uses quarter-circle arcs to create flowing paths based on a maze-carving algorithm.
 * Version: 2026.01.14.13.26.45
 */

// --- Global Parameters ---
int SKETCH_WIDTH = 480;       // Default: 480
int SKETCH_HEIGHT = 800;      // Default: 800
int PADDING = 40;             // Default: 40
int SEED_VALUE = 157;         // Default: 42
int MAX_FRAMES = 900;         // Default: 900
boolean SAVE_FRAMES = false;  // Default: false
int ANIMATION_SPEED = 60;     // Default: 30 (Boosted for tile flow)
float STROKE_WEIGHT = 3.0;    // Default: 6.0

// Grid Parameters
int COLS = 32;                // Default: 16
int ROWS = 56;                // Default: 28
boolean HIDE_GRID = true;     // Default: true
int GRID_ALPHA = 30;          // Default: 30

// Visual Style
boolean INVERT_BG = false;    // Default: false
int PALETTE_INDEX = 0;        // Default: 1 (Deep Sea)

// --- Color Palettes ---
int[][] PALETTES = {
  {#264653, #2a9d8f, #e9c46a, #f4a261, #e76f51}, 
  {#001219, #005f73, #0a9396, #94d2bd, #e9d8a6}, 
  {#5f0f40, #9a031e, #cb2c31, #fb8b24, #e36414}, 
  {#231942, #5e548e, #9f86c0, #be95c4, #e0b1cb}, 
  {#1a1a1b, #333333, #f5f5f5, #cccccc, #999999}
};

// --- Internal Variables ---
float cellSizeW, cellSizeH;
Cell[][] grid;
ArrayList<Crawler> crawlers;
int bgColor;
int wallStrokeColor;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  randomSeed(SEED_VALUE);
  frameRate(ANIMATION_SPEED);
  
  int[] currentPalette = PALETTES[PALETTE_INDEX];
  bgColor = INVERT_BG ? currentPalette[4] : currentPalette[0];
  wallStrokeColor = INVERT_BG ? currentPalette[0] : currentPalette[4];
  
  cellSizeW = (float)(width - (PADDING * 2)) / COLS;
  cellSizeH = (float)(height - (PADDING * 2)) / ROWS;
  
  grid = new Cell[COLS][ROWS];
  for (int i = 0; i < COLS; i++) {
    for (int j = 0; j < ROWS; j++) {
      grid[i][j] = new Cell(i, j);
    }
  }
  
  crawlers = new ArrayList<Crawler>();
  crawlers.add(new Crawler(0, 0, currentPalette[1]));
  crawlers.add(new Crawler(COLS - 1, ROWS - 1, currentPalette[2]));
  crawlers.add(new Crawler(COLS - 1, 0, currentPalette[3]));
}

void draw() {
  background(bgColor);
  
  pushMatrix();
  translate(PADDING, PADDING);
  
  for (int i = 0; i < COLS; i++) {
    for (int j = 0; j < ROWS; j++) {
      grid[i][j].display();
    }
  }
  
  for (Crawler c : crawlers) {
    c.update();
  }
  popMatrix();
  
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) noLoop();
  }
}

// --- Classes ---

class Cell {
  int i, j;
  // Connections: 0:Top, 1:Right, 2:Bottom, 3:Left
  boolean[] connections = {false, false, false, false}; 
  boolean visited = false;
  int col;
  
  Cell(int i, int j) {
    this.i = i;
    this.j = j;
    this.col = wallStrokeColor;
  }
  
  void display() {
    float x = i * cellSizeW;
    float y = j * cellSizeH;
    
    if (!HIDE_GRID) {
      stroke(wallStrokeColor, GRID_ALPHA);
      strokeWeight(1);
      noFill();
      rect(x, y, cellSizeW, cellSizeH);
    }
    
    if (!visited) return;

    noFill();
    stroke(col);
    strokeWeight(STROKE_WEIGHT);
    strokeCap(ROUND);
    
    // Truchet Logic: Draw arcs based on connections to create flow
    // A cell in a maze usually has 1 or 2 connections during growth
    if (connections[0] && connections[1]) drawArc(x + cellSizeW, y, 2); // Top-Right
    if (connections[1] && connections[2]) drawArc(x + cellSizeW, y + cellSizeH, 3); // Right-Bottom
    if (connections[2] && connections[3]) drawArc(x, y + cellSizeH, 0); // Bottom-Left
    if (connections[3] && connections[0]) drawArc(x, y, 1); // Left-Top
    
    // Handle straight lines for end-caps or vertical/horizontal flow
    if (connections[0] && connections[2]) line(x + cellSizeW/2, y, x + cellSizeW/2, y + cellSizeH);
    if (connections[1] && connections[3]) line(x, y + cellSizeH/2, x + cellSizeW, y + cellSizeH/2);
  }
  
  void drawArc(float x, float y, int quadrant) {
    float start = quadrant * HALF_PI;
    float stop = start + HALF_PI;
    arc(x, y, cellSizeW, cellSizeH, start, stop);
  }
}

class Crawler {
  Cell current;
  ArrayList<Cell> stack = new ArrayList<Cell>();
  int drawColor;
  
  Crawler(int i, int j, int c) {
    current = grid[i][j];
    current.visited = true;
    current.col = c;
    drawColor = c;
  }
  
  void update() {
    Cell next = checkNeighbors(current);
    if (next != null) {
      next.visited = true;
      next.col = drawColor;
      stack.add(current);
      connect(current, next);
      current = next;
    } else if (stack.size() > 0) {
      current = stack.remove(stack.size() - 1);
    }
  }
  
  Cell checkNeighbors(Cell c) {
    ArrayList<Cell> neighbors = new ArrayList<Cell>();
    int[][] offsets = {{0, -1}, {1, 0}, {0, 1}, {-1, 0}};
    for (int k = 0; k < 4; k++) {
      int ni = c.i + offsets[k][0];
      int nj = c.j + offsets[k][1];
      if (ni >= 0 && nj >= 0 && ni < COLS && nj < ROWS && !grid[ni][nj].visited) {
        neighbors.add(grid[ni][nj]);
      }
    }
    return neighbors.size() > 0 ? neighbors.get(floor(random(neighbors.size()))) : null;
  }
  
  void connect(Cell a, Cell b) {
    if (a.i < b.i) { a.connections[1] = true; b.connections[3] = true; } // b is Right
    else if (a.i > b.i) { a.connections[3] = true; b.connections[1] = true; } // b is Left
    else if (a.j < b.j) { a.connections[2] = true; b.connections[0] = true; } // b is Bottom
    else if (a.j > b.j) { a.connections[0] = true; b.connections[2] = true; } // b is Top
  }
}
