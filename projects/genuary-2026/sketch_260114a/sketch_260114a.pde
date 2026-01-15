/**
 * Multi-Agent Maze Art Generator
 * A grid-based maze construction visualization using recursive backtracking agents.
 * Version: 2026.01.14.13.15.22
 */

// --- Global Parameters ---
int SKETCH_WIDTH = 480;       // Default: 480
int SKETCH_HEIGHT = 800;      // Default: 800
int PADDING = 40;             // Default: 40
int SEED_VALUE = 42;          // Default: 42
int MAX_FRAMES = 900;         // Default: 900
boolean SAVE_FRAMES = false;  // Default: false
int ANIMATION_SPEED = 30;     // Default: 30
float STROKE_WEIGHT = 4.0;    // Default: 4.0
int GRID_SIZE = 20;           // Default: 20
boolean SHOW_GRID = false;    // Default: false
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
int cols, rows;
Cell[][] grid;
ArrayList<Crawler> crawlers;
int bgColor;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  randomSeed(SEED_VALUE);
  frameRate(ANIMATION_SPEED);
  
  int[] currentPalette = PALETTES[PALETTE_INDEX];
  bgColor = INVERT_BG ? currentPalette[2] : currentPalette[0];
  
  // Calculate grid dimensions based on padding
  int availableW = width - (PADDING * 2);
  int availableH = height - (PADDING * 2);
  cols = floor(availableW / GRID_SIZE);
  rows = floor(availableH / GRID_SIZE);
  
  grid = new Cell[cols][rows];
  for (int i = 0; i < cols; i++) {
    for (int j = 0; j < rows; j++) {
      grid[i][j] = new Cell(i, j);
    }
  }
  
  crawlers = new ArrayList<Crawler>();
  // Initialize 3 agents at different corners
  crawlers.add(new Crawler(0, 0, currentPalette[1]));
  crawlers.add(new Crawler(cols - 1, 0, currentPalette[3]));
  crawlers.add(new Crawler(cols / 2, rows - 1, currentPalette[4]));
}

void draw() {
  background(bgColor);
  
  // Center the grid
  pushMatrix();
  translate(PADDING + (width - 2 * PADDING - cols * GRID_SIZE) / 2, 
            PADDING + (height - 2 * PADDING - rows * GRID_SIZE) / 2);
  
  for (int i = 0; i < cols; i++) {
    for (int j = 0; j < rows; j++) {
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
    int x = i * GRID_SIZE;
    int y = j * GRID_SIZE;
    
    if (SHOW_GRID) {
      stroke(bgColor, 50);
      noFill();
      rect(x, y, GRID_SIZE, GRID_SIZE);
    }
    
    strokeWeight(STROKE_WEIGHT);
    strokeCap(ROUND);
    
    // Draw walls if they exist
    if (walls[0]) line(x, y, x + GRID_SIZE, y);
    if (walls[1]) line(x + GRID_SIZE, y, x + GRID_SIZE, y + GRID_SIZE);
    if (walls[2]) line(x + GRID_SIZE, y + GRID_SIZE, x, y + GRID_SIZE);
    if (walls[3]) line(x, y + GRID_SIZE, x, y);
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
    stroke(drawColor);
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
      
      if (ni >= 0 && nj >= 0 && ni < cols && nj < rows) {
        Cell neighbor = grid[ni][nj];
        if (!neighbor.visited) {
          neighbors.add(neighbor);
        }
      }
    }
    
    if (neighbors.size() > 0) {
      int r = floor(random(neighbors.size()));
      return neighbors.get(r);
    } else {
      return null;
    }
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
