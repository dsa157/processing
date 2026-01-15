/**
 * Recursive Subdivision Maze
 * Replaces standard lines with geometric cell fragmentation.
 * Creates a shattered or crystalline appearance for pen plotters.
 * Version: 2026.01.14.13.51.12
 */

// --- Global Parameters ---
int SKETCH_WIDTH = 480;       // Default: 480
int SKETCH_HEIGHT = 800;      // Default: 800
int PADDING = 60;             // Default: 60
int SEED_VALUE = 404;         // Default: 404
int MAX_FRAMES = 1200;        // Default: 1200
boolean SAVE_FRAMES = false;  // Default: false
int ANIMATION_SPEED = 60;     // Default: 60

// Subdivision Parameters
float STROKE_WEIGHT = 1.5;    // Default: 0.5
int SUB_DEPTH = 3;            // How many times to split a cell (Default: 3)
float SUB_CHANCE = 0.75;      // Likelihood of a split occurring (Default: 0.75)

// Grid Parameters
int COLS = 10;                // Default: 12
int ROWS = 15;                // Default: 20
boolean HIDE_GRID = true;     // Default: true

// Visual Style
int BG_COLOR = #FFFFFF;       // Default: White
int STROKE_COLOR = #000000;   // Default: Black

// --- Internal Variables ---
float cellSizeW, cellSizeH;
Cell[][] grid;
ArrayList<Crawler> crawlers;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  randomSeed(SEED_VALUE);
  frameRate(ANIMATION_SPEED);
  background(BG_COLOR);
  
  cellSizeW = (float)(width - (PADDING * 2)) / COLS;
  cellSizeH = (float)(height - (PADDING * 2)) / ROWS;
  
  grid = new Cell[COLS][ROWS];
  for (int i = 0; i < COLS; i++) {
    for (int j = 0; j < ROWS; j++) {
      grid[i][j] = new Cell(i, j);
    }
  }
  
  crawlers = new ArrayList<Crawler>();
  crawlers.add(new Crawler(0, 0, STROKE_COLOR));
  crawlers.add(new Crawler(COLS - 1, ROWS - 1, STROKE_COLOR));
}

void draw() {
  pushMatrix();
  translate(PADDING, PADDING);
  
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
  boolean visited = false;
  
  Cell(int i, int j) {
    this.i = i;
    this.j = j;
  }
  
  void subdivide(float x, float y, float w, float h, int depth) {
    if (depth <= 0) {
      stroke(STROKE_COLOR);
      strokeWeight(STROKE_WEIGHT);
      noFill();
      rect(x, y, w, h);
      return;
    }

    // Randomly decide whether to split horizontally or vertically
    if (random(1) < SUB_CHANCE) {
      if (w > h) {
        float split = random(0.3, 0.7) * w;
        subdivide(x, y, split, h, depth - 1);
        subdivide(x + split, y, w - split, h, depth - 1);
      } else {
        float split = random(0.3, 0.7) * h;
        subdivide(x, y, w, split, depth - 1);
        subdivide(x, y + split, w, h - split, depth - 1);
      }
    } else {
      // Draw a line connecting the centers if no further split
      stroke(STROKE_COLOR);
      strokeWeight(STROKE_WEIGHT);
      rect(x, y, w, h);
    }
  }
  
  void drawShatter(Cell other) {
    // Subdivide both the current and the target cell
    subdivide(i * cellSizeW, j * cellSizeH, cellSizeW, cellSizeH, SUB_DEPTH);
    subdivide(other.i * cellSizeW, other.j * cellSizeH, cellSizeW, cellSizeH, SUB_DEPTH);
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
      current.drawShatter(next);
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
}
