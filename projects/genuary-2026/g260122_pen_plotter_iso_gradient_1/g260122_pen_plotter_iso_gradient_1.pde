/**
 * 3D-Isometric Pipe Network - Vertical Gradient Strokes
 * Implements a structural gradient where stroke weight and pipe gauge 
 * transition from thick (top) to thin (bottom).
 * Version: 2026.01.14.14.45.20
 */

// --- Global Parameters ---
int SKETCH_WIDTH = 480;       // Default: 480
int SKETCH_HEIGHT = 800;      // Default: 800
int PADDING = 40;             // Default: 40
int SEED_VALUE = 42;          // Default: 42
int MAX_FRAMES = 5000;        // High frame count for total saturation
boolean SAVE_FRAMES = false;  // Default: false
int ANIMATION_SPEED = 120;    // Default: 120

// Gradient Geometry Parameters
float TOP_GAUGE = 28.0;       // Physical width at top (Default: 28.0)
float BOT_GAUGE = 4.0;        // Physical width at bottom (Default: 4.0)
float TOP_PEN = 4.0;          // Stroke weight at top (Default: 4.0)
float BOT_PEN = 0.5;          // Stroke weight at bottom (Default: 0.5)

int HATCH_DENSITY = 2;        // Default: 2
int HATCH_ALPHA = 120;        // Default: 120

// 3D Grid Parameters
float ISO_ANGLE = PI/6;       
float Z_HEIGHT_STEP = 45.0;   
int COLS = 20;                
int ROWS = 40;                
int TIERS = 5;                

// Visual Style
int BG_COLOR = #FFFFFF;       // Default: White
int STROKE_COLOR = #000000;   // Default: Black

// --- Internal Variables ---
float isoScale = 35.0;        
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
  
  // Align grid to cover the canvas
  float midI = COLS / 2.0;
  float midJ = ROWS / 2.0;
  float midK = TIERS / 2.0;
  gridOffsetX = (width / 2.0) - (midI - midJ) * cos(ISO_ANGLE) * isoScale;
  gridOffsetY = (height / 2.0) - ((midI + midJ) * sin(ISO_ANGLE) * isoScale - (midK * Z_HEIGHT_STEP));
  
  crawlers = new ArrayList<IsoCrawler>();
  // Spawn crawlers at different tiers to initiate growth
  for (int i = 0; i < 10; i++) {
    crawlers.add(new IsoCrawler(
      floor(random(COLS)), 
      floor(random(ROWS)), 
      floor(random(TIERS))
    ));
  }
}

void draw() {
  pushMatrix();
  translate(gridOffsetX, gridOffsetY);
  
  for (IsoCrawler ic : crawlers) {
    ic.update();
  }
  popMatrix();
  
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
    float screenX1 = x + gridOffsetX;
    float screenY1 = y + gridOffsetY;
    float screenX2 = other.x + gridOffsetX;
    float screenY2 = other.y + gridOffsetY;
    
    // Check if points are within PADDING boundary
    if (!isInside(screenX1, screenY1) || !isInside(screenX2, screenY2)) return;

    // Calculate vertical factor (0.0 at top PADDING, 1.0 at bottom PADDING)
    float midY = (screenY1 + screenY2) / 2.0;
    float vFactor = map(midY, PADDING, height - PADDING, 0.0, 1.0);
    vFactor = constrain(vFactor, 0.0, 1.0);

    // Apply Gradient: Thick at top (vFactor 0), Thin at bottom (vFactor 1)
    float currentGauge = lerp(TOP_GAUGE, BOT_GAUGE, vFactor);
    float currentPen = lerp(TOP_PEN, BOT_PEN, vFactor);
    
    noFill();
    strokeCap(ROUND);
    float angle = atan2(other.y - y, other.x - x);
    float d = dist(x, y, other.x, other.y);
    float hw = currentGauge / 2.0;
    
    pushMatrix();
    translate(x, y);
    rotate(angle);
    
    // Shadow Hatching
    strokeWeight(BOT_PEN); 
    stroke(STROKE_COLOR, HATCH_ALPHA);
    for (int n = 1; n <= HATCH_DENSITY; n++) {
      float hOffset = map(n, 0, HATCH_DENSITY, 0, hw);
      line(0, hOffset, d, hOffset);
    }
    
    // Main Pipe Geometry
    stroke(STROKE_COLOR);
    strokeWeight(currentPen);
    line(0, -hw, d, -hw);
    line(0, hw, d, hw);
    line(0, -hw, 0, hw);
    line(d, -hw, d, hw);
    
    popMatrix();
  }
  
  boolean isInside(float sx, float sy) {
    return sx > PADDING && sx < width - PADDING && sy > PADDING && sy < height - PADDING;
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
