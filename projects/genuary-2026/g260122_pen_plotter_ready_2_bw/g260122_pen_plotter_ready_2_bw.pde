/**
 * Multi-Agent Truchet Maze Art - Monochrome Edition
 * Renders black flowing paths on a white background using quarter-circle arcs.
 * Version: 2026.01.14.13.29.55
 */

// --- Global Parameters ---
int SKETCH_WIDTH = 480;       // Default: 480
int SKETCH_HEIGHT = 800;      // Default: 800
int PADDING = 10;             // Default: 40
int SEED_VALUE = 42;          // Default: 42
int MAX_FRAMES = 900;         // Default: 900
boolean SAVE_FRAMES = false;  // Default: false
int ANIMATION_SPEED = 60;     // Default: 30
float STROKE_WEIGHT = 5.0;    // Default: 5.0

// Grid Parameters
int COLS = 25;                // Default: 16
int ROWS = 45;                // Default: 28
boolean HIDE_GRID = true;     // Default: true
int GRID_ALPHA = 20;          // Default: 20

// Visual Style
boolean INVERT_BG = true;     // Default: true (White background for index 4)
int PALETTE_INDEX = 4;        // Default: 4 (Monochromatic)

// --- Color Palettes ---
int[][] PALETTES = {
  {#264653, #2a9d8f, #e9c46a, #f4a261, #e76f51}, 
  {#001219, #005f73, #0a9396, #94d2bd, #e9d8a6}, 
  {#5f0f40, #9a031e, #cb2c31, #fb8b24, #e36414}, 
  {#231942, #5e548e, #9f86c0, #be95c4, #e0b1cb}, 
  {#1a1a1b, #333333, #f5f5f5, #cccccc, #999999}  // Index 4: Black/White/Gray
};

// --- Internal Variables ---
float cellSizeW, cellSizeH;
Cell[][] grid;
ArrayList<Crawler> crawlers;
int bgColor;
int strokeColor;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  randomSeed(SEED_VALUE);
  frameRate(ANIMATION_SPEED);
  
  // Explicitly setting for High Contrast Black on White
  bgColor = #FFFFFF; 
  strokeColor = #000000;
  
  cellSizeW = (float)(width - (PADDING * 2)) / COLS;
  cellSizeH = (float)(height - (PADDING * 2)) / ROWS;
  
  grid = new Cell[COLS][ROWS];
  for (int i = 0; i < COLS; i++) {
    for (int j = 0; j < ROWS; j++) {
      grid[i][j] = new Cell(i, j);
    }
  }
  
  crawlers = new ArrayList<Crawler>();
  // Multiple agents building the single-color maze
  crawlers.add(new Crawler(0, 0, strokeColor));
  crawlers.add(new Crawler(COLS - 1, ROWS - 1, strokeColor));
  crawlers.add(new Crawler(COLS - 1, 0, strokeColor));
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
  
  // Frame Management
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) {
      noLoop();
    }
  }
}

// --- Classes ---

class Cell {
  int i, j;
  boolean[] connections = {false, false, false, false}; // T, R, B, L
  boolean visited = false;
  int cellCol;
  
  Cell(int i, int j) {
    this.i = i;
    this.j = j;
    this.cellCol = strokeColor;
  }
  
  void display() {
    float x = i * cellSizeW;
    float y = j * cellSizeH;
    
    if (!HIDE_GRID) {
      stroke(0, GRID_ALPHA);
      strokeWeight(1);
      noFill();
      rect(x, y, cellSizeW, cellSizeH);
    }
    
    if (!visited) return;

    noFill();
    stroke(cellCol);
    strokeWeight(STROKE_WEIGHT);
    strokeCap(ROUND);
    
    // Draw Arcs for flow
    if (connections[0] && connections[1]) drawArc(x + cellSizeW, y, 2); 
    if (connections[1] && connections[2]) drawArc(x + cellSizeW, y + cellSizeH, 3);
    if (connections[2] && connections[3]) drawArc(x, y + cellSizeH, 0); 
    if (connections[3] && connections[0]) drawArc(x, y, 1);
    
    // Draw Straight segments
    if (connections[0] && connections[2]) line(x + cellSizeW/2, y, x + cellSizeW/2, y + cellSizeH);
    if (connections[1] && connections[3]) line(x, y + cellSizeH/2, x + cellSizeW, y + cellSizeH/2);
    
    // Draw caps for end-points (cells with only 1 connection)
    int total = 0;
    for(boolean b : connections) if(b) total++;
    if (total == 1) {
       if (connections[0]) line(x + cellSizeW/2, y, x + cellSizeW/2, y + cellSizeH/2);
       if (connections[1]) line(x + cellSizeW/2, y + cellSizeH/2, x + cellSizeW, y + cellSizeH/2);
       if (connections[2]) line(x + cellSizeW/2, y + cellSizeH/2, x + cellSizeW/2, y + cellSizeH);
       if (connections[3]) line(x, y + cellSizeH/2, x + cellSizeW/2, y + cellSizeH/2);
    }
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
    current.cellCol = c;
    drawColor = c;
  }
  
  void update() {
    Cell next = checkNeighbors(current);
    if (next != null) {
      next.visited = true;
      next.cellCol = drawColor;
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
    if (a.i < b.i) { a.connections[1] = true; b.connections[3] = true; } 
    else if (a.i > b.i) { a.connections[3] = true; b.connections[1] = true; } 
    else if (a.j < b.j) { a.connections[2] = true; b.connections[0] = true; } 
    else if (a.j > b.j) { a.connections[0] = true; b.connections[2] = true; } 
  }
}
