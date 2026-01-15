/**
 * 3D-Isometric Multi-Tiered Pipe Network (Full-Bleed Clipping)
 * Overscans the grid to guarantee 100% coverage while clipping lines at the padding boundary.
 * Version: 2026.01.14.14.35.12
 */

// --- Global Parameters ---
int SKETCH_WIDTH = 480;       // Default: 480
int SKETCH_HEIGHT = 800;      // Default: 800
int PADDING = 40;             // Default: 40
int SEED_VALUE = 42;          // Default: 42
int MAX_FRAMES = 4000;        // High frame count for total saturation
boolean SAVE_FRAMES = false;  // Default: false
int ANIMATION_SPEED = 120;    // Default: 120

// Pipe & 3D Parameters
float PIPE_WIDTH = 20.0;       // Default: 8.0
int HATCH_DENSITY = 1;        // Default: 2
float ISO_ANGLE = PI/6;       // 30 degrees
float Z_HEIGHT_STEP = 35.0;   // Vertical distance (Default: 35.0)

// Grid Over-scan (Large enough to cover 480x800 regardless of ISO skew)
int COLS = 40;                // Default: 40
int ROWS = 40;                // Default: 40
int TIERS = 5;                // Default: 5

// Visual Style
int BG_COLOR = #FFFFFF;       // Default: White
int STROKE_COLOR = #000000;   // Default: Black

// --- Internal Variables ---
float isoScale = 30.0;        // Fixed scale for consistent density
IsoCell[][][] grid;
ArrayList<IsoCrawler> crawlers;
float gridOffsetX, gridOffsetY;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  randomSeed(SEED_VALUE);
  frameRate(ANIMATION_SPEED);
  background(BG_COLOR);
  
  grid = new IsoCell[COLS][ROWS][TIERS];
  for (int i = 0; i < COLS; i++) {
    for (int j = 0; j < ROWS; j++) {
      for (int k = 0; k < TIERS; k++) {
        grid[i][j][k] = new IsoCell(i, j, k);
      }
    }
  }
  
  // Calculate centering for the oversized grid
  float midI = COLS / 2.0;
  float midJ = ROWS / 2.0;
  float midK = TIERS / 2.0;
  gridOffsetX = (width / 2.0) - (midI - midJ) * cos(ISO_ANGLE) * isoScale;
  gridOffsetY = (height / 2.0) - ((midI + midJ) * sin(ISO_ANGLE) * isoScale - (midK * Z_HEIGHT_STEP));
  
  crawlers = new ArrayList<IsoCrawler>();
  crawlers.add(new IsoCrawler(0, 0, 0));
  crawlers.add(new IsoCrawler(COLS-1, ROWS-1, TIERS-1));
  crawlers.add(new IsoCrawler(COLS-1, 0, 0));
  crawlers.add(new IsoCrawler(0, ROWS-1, TIERS-1));
  crawlers.add(new IsoCrawler(COLS/2, ROWS/2, TIERS/2));
}

void draw() {
  pushMatrix();
  translate(gridOffsetX, gridOffsetY);
  
  for (IsoCrawler ic : crawlers) {
    ic.update();
  }
  popMatrix();
  
  // Frame Management
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) noLoop();
  }
}

// --- Classes ---

class IsoCell {
  int i, j, k;
  float x, y;
  boolean visited = false;
  
  IsoCell(int i, int j, int k) {
    this.i = i;
    this.j = j;
    this.k = k;
    this.x = (i - j) * cos(ISO_ANGLE) * isoScale;
    this.y = (i + j) * sin(ISO_ANGLE) * isoScale - (k * Z_HEIGHT_STEP);
  }

  void drawPipe(IsoCell other) {
    // Check if both endpoints are within the clipping region
    // We add gridOffsetX/Y back to check against screen coordinates
    float screenX1 = x + gridOffsetX;
    float screenY1 = y + gridOffsetY;
    float screenX2 = other.x + gridOffsetX;
    float screenY2 = other.y + gridOffsetY;
    
    boolean inBounds = (screenX1 > PADDING && screenX1 < width - PADDING &&
                        screenY1 > PADDING && screenY1 < height - PADDING &&
                        screenX2 > PADDING && screenX2 < width - PADDING &&
                        screenY2 > PADDING && screenY2 < height - PADDING);
    
    if (!inBounds) return;

    stroke(STROKE_COLOR);
    strokeWeight(1.0);
    noFill();
    
    float dx = other.x - x;
    float dy = other.y - y;
    float angle = atan2(dy, dx);
    float d = dist(x, y, other.x, other.y);
    float hw = PIPE_WIDTH / 2.0;
    
    pushMatrix();
    translate(x, y);
    rotate(angle);
    
    // Pipe outlines
    line(0, -hw, d, -hw);
    line(0, hw, d, hw);
    
    // Joint caps
    line(0, -hw, 0, hw);
    line(d, -hw, d, hw);
    
    // Hatch shading for 3D effect
    for (int n = 1; n <= HATCH_DENSITY; n++) {
      float hOffset = map(n, 0, HATCH_DENSITY, 0, hw);
      stroke(STROKE_COLOR, 180);
      line(0, hOffset, d, hOffset);
    }
    
    popMatrix();
  }
}

class IsoCrawler {
  IsoCell current;
  ArrayList<IsoCell> stack = new ArrayList<IsoCell>();
  
  IsoCrawler(int i, int j, int k) {
    current = grid[i][j][k];
    current.visited = true;
  }
  
  void update() {
    IsoCell next = getNeighbor(current);
    if (next != null) {
      next.visited = true;
      stack.add(current);
      current.drawPipe(next);
      current = next;
    } else if (stack.size() > 0) {
      current = stack.remove(stack.size() - 1);
    }
  }
  
  IsoCell getNeighbor(IsoCell c) {
    ArrayList<IsoCell> neighbors = new ArrayList<IsoCell>();
    int[][] offsets = {{1,0,0}, {-1,0,0}, {0,1,0}, {0,-1,0}, {0,0,1}, {0,0,-1}};
    
    for (int[] off : offsets) {
      int ni = c.i + off[0];
      int nj = c.j + off[1];
      int nk = c.k + off[2];
      
      if (ni >= 0 && nj >= 0 && nk >= 0 && ni < COLS && nj < ROWS && nk < TIERS) {
        if (!grid[ni][nj][nk].visited) {
          neighbors.add(grid[ni][nj][nk]);
        }
      }
    }
    return neighbors.size() > 0 ? neighbors.get(floor(random(neighbors.size()))) : null;
  }
}
