/**
 * Traditional Truchet Flow - Brutalist Gradient
 * 1. Dual-arc system for continuous network flow.
 * 2. Vertical Pen Gradient: 8.0 (top) to 0.5 (bottom).
 * 3. Temporal Scaling: Uniformly fills 900 frames.
 * Version: 2026.01.14.15.35.12
 */

// --- Global Parameters ---
int SKETCH_WIDTH = 480;       
int SKETCH_HEIGHT = 800;      
int PADDING = 40;             
int SEED_VALUE = 157157;          
int MAX_FRAMES = 900;         
boolean SAVE_FRAMES = false;  
int ANIMATION_SPEED = 60;     
float ANIMATION_STRETCH = 1.0; 

// Visual Parameters
float TOP_PEN = 5.0;          
float BOT_PEN = 0.5;          

// Grid Parameters
int COLS = 32;                
int ROWS = 56;                

// Visual Style
int BG_COLOR = #FFFFFF;       
int STROKE_COLOR = #000000;   

// --- Internal Variables ---
float cellW, cellH;
TileCell[][] grid;
ArrayList<TruchetCrawler> crawlers;
int totalCells;
int visitedCount = 0;
float movementAccumulator = 0;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  randomSeed(SEED_VALUE);
  frameRate(ANIMATION_SPEED);
  background(BG_COLOR);
  
  cellW = (float)(width - (PADDING * 2)) / COLS;
  cellH = (float)(height - (PADDING * 2)) / ROWS;
  totalCells = COLS * ROWS;
  
  grid = new TileCell[COLS][ROWS];
  for (int i = 0; i < COLS; i++) {
    for (int j = 0; j < ROWS; j++) {
      grid[i][j] = new TileCell(i, j);
    }
  }
  
  crawlers = new ArrayList<TruchetCrawler>();
  // Distribute crawlers to ensure the bottom fills as fast as the top
  crawlers.add(new TruchetCrawler(0, 0));
  crawlers.add(new TruchetCrawler(COLS-1, ROWS-1));
  crawlers.add(new TruchetCrawler(COLS/2, 0));
  crawlers.add(new TruchetCrawler(COLS/2, ROWS-1));
}

void draw() {
  pushMatrix();
  translate(PADDING, PADDING);
  
  // Calculate pace for uniform growth over 900 frames
  float framesRemaining = max(1, MAX_FRAMES - frameCount);
  float cellsRemaining = (float)(totalCells - visitedCount);
  float rate = (cellsRemaining / framesRemaining) / ANIMATION_STRETCH;
  
  movementAccumulator += rate;
  int steps = floor(movementAccumulator);
  movementAccumulator -= steps;

  for (int s = 0; s < steps; s++) {
    for (TruchetCrawler tc : crawlers) {
      tc.update();
    }
  }
  popMatrix();
  
  if (SAVE_FRAMES) saveFrame("frames/####.tif");
  if (frameCount >= MAX_FRAMES) noLoop();
}

// --- Classes ---

class TileCell {
  int i, j;
  boolean visited = false;
  
  TileCell(int i, int j) {
    this.i = i;
    this.j = j;
  }
  
  void drawTraditionalTruchet() {
    float x = i * cellW;
    float y = j * cellH;
    
    // Vertical Gradient Pen Weight
    float screenY = y + PADDING;
    float vFactor = constrain(map(screenY, PADDING, height - PADDING, 0.0, 1.0), 0.0, 1.0);
    float currentPen = lerp(TOP_PEN, BOT_PEN, vFactor);
    
    stroke(STROKE_COLOR);
    strokeWeight(currentPen);
    noFill();
    strokeCap(ROUND);
    
    // Traditional Truchet: Two arcs connecting midpoints of edges
    // The "visited" check allows us to create a unified flow, 
    // but the tile orientation is decided by a random flip to keep it maze-like.
    if (random(1) < 0.5) {
      // Orientation A
      arc(x, y, cellW, cellH, 0, HALF_PI);
      arc(x + cellW, y + cellH, cellW, cellH, PI, PI + HALF_PI);
    } else {
      // Orientation B
      arc(x + cellW, y, cellW, cellH, HALF_PI, PI);
      arc(x, y + cellH, cellW, cellH, PI + HALF_PI, TWO_PI);
    }
  }
}

class TruchetCrawler {
  TileCell current;
  ArrayList<TileCell> stack = new ArrayList<TileCell>();
  boolean active = true;
  
  TruchetCrawler(int i, int j) {
    current = grid[i][j];
    current.visited = true;
    visitedCount++;
  }
  
  void update() {
    if (!active) return;
    TileCell next = getNeighbor(current);
    if (next != null) {
      next.visited = true;
      visitedCount++;
      stack.add(current);
      // We draw the tile in the cell we just occupied
      current.drawTraditionalTruchet();
      current = next;
    } else if (stack.size() > 0) {
      current = stack.remove(stack.size() - 1);
    } else {
      active = false;
    }
  }
  
  TileCell getNeighbor(TileCell c) {
    ArrayList<TileCell> neighbors = new ArrayList<TileCell>();
    int[][] offsets = {{0,-1}, {1,0}, {0,1}, {-1,0}};
    for (int[] off : offsets) {
      int ni = c.i + off[0], nj = c.j + off[1];
      if (ni >= 0 && nj >= 0 && ni < COLS && nj < ROWS) {
        if (!grid[ni][nj].visited) neighbors.add(grid[ni][nj]);
      }
    }
    return neighbors.size() > 0 ? neighbors.get(floor(random(neighbors.size()))) : null;
  }
}
