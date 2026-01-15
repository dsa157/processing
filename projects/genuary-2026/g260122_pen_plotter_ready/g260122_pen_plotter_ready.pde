/**
 * Multi-Agent Maze Art Generator
 * A grid-based maze construction visualization using recursive backtracking agents.
 * Grid transparency and visibility are now parameterized.
 * Version: 2026.01.14.13.21.10
 */

// --- Global Parameters ---
int SKETCH_WIDTH = 480;       // Default: 480
int SKETCH_HEIGHT = 800;      // Default: 800
int PADDING = 40;             // Default: 40
int SEED_VALUE = 42;          // Default: 42
int MAX_FRAMES = 900;         // Default: 900
boolean SAVE_FRAMES = false;  // Default: false
int ANIMATION_SPEED = 30;     // Default: 30
float STROKE_WEIGHT = 2.0;    // Default: 4.0

// Grid Parameters
int COLS = 30;                // Default: 15
int ROWS = 50;                // Default: 25
boolean HIDE_GRID = true;     // Default: true
int GRID_ALPHA = 255;          // Default: 40 (0-255)

// Visual Style
boolean INVERT_BG = false;    // Default: false
int PALETTE_INDEX = 0;        // Default: 0 (0-4)

// --- Color Palettes (Adobe Color / Kuler inspired) ---
int[][] PALETTES = {
  {#264653, #2a9d8f, #e9c46a, #f4a261, #e76f51}, // Terra Cotta
  {#001219, #005f73, #0a9396, #94d2bd, #e9d8a6}, // Deep Sea
  {#5f0f40, #9a031e, #cb2c31, #fb8b24, #e36414}, // Warm Fire
  {#231942, #5e548e, #9f86c0, #be95c4, #e0b1cb}, // Lavender
  {#1a1a1b, #333333, #f5f5f5, #cccccc, #999999}  // Monochromatic
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
  bgColor = INVERT_BG ? currentPalette[2] : currentPalette[0];
  wallStrokeColor = INVERT_BG ? 0 : 255;
  
  // Calculate cell sizes based on fixed rows/cols and padding
  cellSizeW = (float)(width - (PADDING * 2)) / COLS;
  cellSizeH = (float)(height - (PADDING * 2)) / ROWS;
  
  grid = new Cell[COLS][ROWS];
  for (int i = 0; i < COLS; i++) {
    for (int j = 0; j < ROWS; j++) {
      grid[i][j] = new Cell(i, j);
    }
  }
  
  crawlers = new ArrayList<Crawler>();
  // Initialize agents with specific palette colors
  crawlers.add(new Crawler(0, 0, currentPalette[1]));
  crawlers.add(new Crawler(COLS - 1, 0, currentPalette[3]));
  crawlers.add(new Crawler(COLS / 2, ROWS - 1, currentPalette[4]));
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
  boolean[] walls = {true, true, true, true}; // Top, Right, Bottom, Left
  boolean visited = false;
  
  Cell(int i, int j) {
    this.i = i;
    this.j = j;
  }
  
  void display() {
    float x = i * cellSizeW;
    float y = j * cellSizeH;
    
    // Background Grid logic
    if (!HIDE_GRID) {
      stroke(wallStrokeColor, GRID_ALPHA);
      strokeWeight(1);
      noFill();
      rect(x, y, cellSizeW, cellSizeH);
    }
    
    strokeWeight(STROKE_WEIGHT);
    strokeCap(ROUND);
    stroke(wallStrokeColor, 255); // Full opacity for the maze walls

    // Draw walls if they exist
    if (walls[0]) line(x, y, x + cellSizeW, y);
    if (walls[1]) line(x + cellSizeW, y, x + cellSizeW, y + cellSizeH);
    if (walls[2]) line(x + cellSizeW, y + cellSizeH, x, y + cellSizeH);
    if (walls[3]) line(x, y + cellSizeH, x, y);
  }
}

class Crawler {
  Cell current;
  ArrayList<Cell> stack = new ArrayList<Cell>();
  int drawColor;
  
  Crawler(int i, int j, int c) {
    current = grid[i][j];
    current.visited = true;
    drawColor = c;
  }
  
  void update() {
    Cell next = checkNeighbors(current);
    if (next != null) {
      next.visited = true;
      stack.add(current);
      removeWalls(current, next);
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
      
      if (ni >= 0 && nj >= 0 && ni < COLS && nj < ROWS) {
        Cell neighbor = grid[ni][nj];
        if (!neighbor.visited) {
          neighbors.add(neighbor);
        }
      }
    }
    
    if (neighbors.size() > 0) {
      return neighbors.get(floor(random(neighbors.size())));
    }
    return null;
  }
  
  void removeWalls(Cell a, Cell b) {
    int dx = a.i - b.i;
    if (dx == 1) {
      a.walls[3] = false;
      b.walls[1] = false;
    } else if (dx == -1) {
      a.walls[1] = false;
      b.walls[3] = false;
    }
    
    int dy = a.j - b.j;
    if (dy == 1) {
      a.walls[0] = false;
      b.walls[2] = false;
    } else if (dy == -1) {
      a.walls[2] = false;
      b.walls[0] = false;
    }
  }
}
