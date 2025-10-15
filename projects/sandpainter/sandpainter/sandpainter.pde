// Grid Social Physics Variation - Isolated Cells
// Based on "Happy Place" by J. Tarbell
// complexification.net

// --- GLOBAL PARAMETERS ---
final int SEED = 1337; // Global seed for random()
final int COLS = 3;
final int ROWS = 5;
final float PADDING = 20; 
final boolean INVERT_COLORS = true;
final boolean SHOW_GRID_LINES = false;
final color GRID_LINE_COLOR = INVERT_COLORS ? #FFFFFF : #000000;
final float GRID_STROKE_THICKNESS = 0.5;
final int MAX_FRAMES = 600;
final boolean SAVE_FRAMES = false;

// --- FRIEND SYSTEM PARAMETERS ---
final int FRIENDS_PER_CELL = 15; // Number of friends per grid cell (3*5*15 = 225 total friends)
final float CONNECTION_DENSITY = 4.0; // Increased connection density within the cell
final int MIN_CON_LEN = 10;
final int MAX_CON_LEN_VARIATION = 50;

// --- LINE THICKNESS PARAMETERS ---
final float BASE_LINE_ALPHA = 40; 
final int SWEEP_POINTS = 20; 
final float CENTRAL_LINE_WEIGHT = 1.5; 
final float FRICTION_VALUE = 0.92;

// --- GRID AND CELL VARIABLES ---
float cellW, cellH;
float gridX, gridY;
GridCell[][] grid;
int time = 0;

// --- FRIEND SYSTEM VARIABLES ---
// Note: Global friends array is REMOVED. Friends are now managed inside GridCell.
final int MAX_PALETTE_SIZE = 512;
int numPaletteColors = 0;
color[] goodcolor = new color[MAX_PALETTE_SIZE];

// The SandPainter color source 
final color[] CUSTOM_PALETTE = {
  #FF6B6B, #4ECDC4, #C7F464, #556270, #FFC144, 
  #EFEA5A, #F2833F, #226F54, #873600, #403F4C
};


void setup() {
  size(480, 800, P2D);
  randomSeed(SEED);
  noiseSeed(SEED);

  loadPalette(CUSTOM_PALETTE);

  if (INVERT_COLORS) {
    background(0);
  } else {
    background(255);
  }

  frameRate(30);

  // Calculate grid dimensions
  float drawableW = width - 2 * PADDING;
  float drawableH = height - 2 * PADDING;
  cellW = drawableW / COLS;
  cellH = drawableH / ROWS;
  gridX = PADDING;
  gridY = PADDING;

  // Initialize the grid and populate friends within each cell
  grid = new GridCell[ROWS][COLS];
  for (int r = 0; r < ROWS; r++) {
    for (int c = 0; c < COLS; c++) {
      grid[r][c] = new GridCell(c, r, gridX + c * cellW, gridY + r * cellH, cellW, cellH);
      grid[r][c].initFriends(); // Initialize friends inside the cell
    }
  }
}

void draw() {
  // Semi-transparent background for a fading/ghosting effect
  noStroke();
  fill(INVERT_COLORS ? 0 : 255, 10);
  rect(0, 0, width, height);

  if (SHOW_GRID_LINES) {
    drawGridLines();
  }

  // --- Friend System Logic (Iterate through all cells) ---
  
  // Phase 1: Move and Find Happy Place (Physics)
  for (int r = 0; r < ROWS; r++) {
    for (int c = 0; c < COLS; c++) {
      GridCell cell = grid[r][c];
      
      for (int i = 0; i < cell.friends.length; i++) {
        cell.friends[i].move(cell); // Pass cell for boundary check
      }
      
      if (time % 2 == 0) {
        for (int i = 0; i < cell.friends.length; i++) {
          cell.friends[i].findHappyPlace(cell.friends); // Find happy place relative to cell friends
        }
      }
    }
  }

  // Phase 2: Expose Connections (Drawing)
  for (int r = 0; r < ROWS; r++) {
    for (int c = 0; c < COLS; c++) {
      grid[r][c].exposeAllConnections();
    }
  }

  time++;

  // --- Frame Saving Logic ---
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) {
      noLoop();
    }
  }
}

void mousePressed() {
  // Reset friends within each cell
  for (int r = 0; r < ROWS; r++) {
    for (int c = 0; c < COLS; c++) {
      grid[r][c].initFriends(); 
    }
  }
  if (INVERT_COLORS) {
    background(0);
  } else {
    background(255);
  }
}

void drawGridLines() {
  stroke(GRID_LINE_COLOR);
  strokeWeight(GRID_STROKE_THICKNESS);
  noFill();

  // Draw outer border
  rect(gridX, gridY, COLS * cellW, ROWS * cellH);

  // Draw inner lines
  for (int c = 1; c < COLS; c++) {
    line(gridX + c * cellW, gridY, gridX + c * cellW, gridY + ROWS * cellH);
  }
  for (int r = 1; r < ROWS; r++) {
    line(gridX, gridY + r * cellH, gridX + COLS * cellW, gridY + r * cellH);
  }
}

// =========================================================================
// --- GRID AND CELL CLASSES ---
// =========================================================================

class GridCell {
  int col, row;
  float x, y, w, h;
  int division; // 0: no div (1x1), 1: 2x1, 2: 1x2, 3: 2x2
  Friend[] friends;

  GridCell(int c, int r, float X, float Y, float W, float H) {
    col = c;
    row = r;
    x = X;
    y = Y;
    w = W;
    h = H;
    division = int(random(4)); 
    friends = new Friend[FRIENDS_PER_CELL];
  }
  
  void initFriends() {
    // Make friend entities, distributing them into random sub-grid cells
    for (int i = 0; i < FRIENDS_PER_CELL; i++) {
      // Pick a random sub-cell position
      float[] pos = getRandomSubCellPosition();
      
      // Initial position is slightly randomized around the sub-cell center
      float fx = pos[0] + random(-w/10, w/10);
      float fy = pos[1] + random(-h/10, h/10);
      
      friends[i] = new Friend(fx, fy, i);
    }
    
    // Make random friend connections *only within this cell's friends*
    for (int k = 0; k < FRIENDS_PER_CELL * CONNECTION_DENSITY; k++) {
      int a = int(floor(random(FRIENDS_PER_CELL)));
      int b = int(floor(a + random(5)) % FRIENDS_PER_CELL); // Smaller random range for local connectivity

      if (a != b) {
        friends[a].connectTo(b);
        friends[b].connectTo(a);
      }
    }
  }
  
  void exposeAllConnections() {
     for (int i = 0; i < FRIENDS_PER_CELL; i++) {
        friends[i].exposeConnections(friends);
     }
  }
  
  float[] getRandomSubCellPosition() {
    float subX = x;
    float subY = y;
    float subW = w;
    float subH = h;
    
    switch (division) {
      case 1: // 2x1 (split H)
        subW = w/2;
        subX += int(random(2)) * subW;
        break;
      case 2: // 1x2 (split V)
        subH = h/2;
        subY += int(random(2)) * subH;
        break;
      case 3: // 2x2
        subW = w/2;
        subH = h/2;
        subX += int(random(2)) * subW;
        subY += int(random(2)) * subH;
        break;
      case 0: // 1x1 (no div)
      default:
        break;
    }
    
    return new float[]{subX + subW/2, subY + subH/2};
  }
}

// =========================================================================
// --- FRIEND SYSTEM CLASSES (Adapted for local cell physics) ---
// =========================================================================

class Friend {
  float x, y;
  float vx, vy;
  int id;

  int numcon;
  final int maxcon = 10;
  int lencon; 
  int[] connections = new int[maxcon];

  final int numsands = 3;
  SandPainter[] sands = new SandPainter[numsands];

  color myc = somecolor();

  Friend(float X, float Y, int Id) {
    x = X;
    y = Y;
    id = Id;
    numcon = 0;
    lencon = MIN_CON_LEN + int(random(MAX_CON_LEN_VARIATION));

    for (int n = 0; n < numsands; n++) {
      sands[n] = new SandPainter();
    }
  }

  // Pass the local array of friends to draw connections
  void exposeConnections(Friend[] localFriends) {
    for (int n = 0; n < numcon; n++) {
      float ox = localFriends[connections[n]].x;
      float oy = localFriends[connections[n]].y;

      for (int s = 0; s < numsands; s++) {
        sands[s].render(x, y, ox, oy);
      }
    }
  }

  // Pass the cell to enforce boundary
  void move(GridCell cell) {
    x += vx;
    y += vy;

    vx *= FRICTION_VALUE;
    vy *= FRICTION_VALUE;
    
    // Crucial: Boundary force now constrains the particle to its specific cell (x, y, w, h)
    
    // Repulsion from Left/Right walls
    if (x < cell.x + 5) vx += 0.5;
    if (x > cell.x + cell.w - 5) vx -= 0.5;
    
    // Repulsion from Top/Bottom walls
    if (y < cell.y + 5) vy += 0.5;
    if (y > cell.y + cell.h - 5) vy -= 0.5;
    
    // Hard clamp to prevent escape (for very high velocities)
    x = constrain(x, cell.x, cell.x + cell.w);
    y = constrain(y, cell.y, cell.y + cell.h);
  }

  void connectTo(int f) {
    if (numcon < maxcon) {
      if (!friendOf(f)) {
        connections[numcon] = f;
        numcon++;
      }
    }
  }

  boolean friendOf(int x) {
    for (int n = 0; n < numcon; n++) {
      if (connections[n] == x) return true;
    }
    return false;
  }

  // Pass the local array of friends to calculate happy place
  void findHappyPlace(Friend[] localFriends) {
    float ax = 0.0;
    float ay = 0.0;
    final int numLocalFriends = localFriends.length;

    for (int n = 0; n < numLocalFriends; n++) {
      if (localFriends[n] != this) {
        float ddx = localFriends[n].x - x;
        float ddy = localFriends[n].y - y;
        float d = sqrt(ddx * ddx + ddy * ddy);
        float t = atan2(ddy, ddx);

        boolean isFriend = friendOf(n);
        
        if (isFriend) {
          if (d > lencon) {
            ax += 4.0 * cos(t);
            ay += 4.0 * sin(t);
          }
        } else {
          if (d < lencon) {
            ax += (lencon - d) * cos(t + PI);
            ay += (lencon - d) * sin(t + PI);
          }
        }
      }
    }

    final float FORCE_DIVISOR = 42.22;
    vx += ax / FORCE_DIVISOR;
    vy += ay / FORCE_DIVISOR;
  }
}

class SandPainter {
  float p; 
  color c;
  float g; 

  SandPainter() {
    p = random(1.0);
    c = somecolor();
    g = random(0.01, 0.1);
  }

  void render(float x, float y, float ox, float oy) {
    
    // 1. Draw the central line with increased stroke weight
    strokeWeight(CENTRAL_LINE_WEIGHT);
    stroke(red(c), green(c), blue(c), BASE_LINE_ALPHA); 
    point(ox + (x - ox) * sin(p), oy + (y - oy) * sin(p)); 

    // Update wobble factor
    g += random(-0.050, 0.050);
    final float MAX_WOBBLE = 0.22;
    g = constrain(g, -MAX_WOBBLE, MAX_WOBBLE);

    float w = g / 10.0; 
    
    // 2. Draw the sweeping points (the variable thickness part)
    strokeWeight(0.7); 
    
    for (int i = 0; i < SWEEP_POINTS; i++) {
      float a = 0.1 - i / (SWEEP_POINTS * 10.0);
      float alphaSweep = 256 * a;
      stroke(red(c), green(c), blue(c), max(alphaSweep, BASE_LINE_ALPHA / 3.0));
      
      float phaseOffset = sin(i * w);
      
      // Point 1 (one side of the sweep)
      point(ox + (x - ox) * sin(p + phaseOffset), 
            oy + (y - oy) * sin(p + phaseOffset));
            
      // Point 2 (other side of the sweep)
      point(ox + (x - ox) * sin(p - phaseOffset), 
            oy + (y - oy) * sin(p - phaseOffset));
    }
    
    p += 0.01; 
  }
}

// =========================================================================
// --- COLOR UTILITIES ---
// =========================================================================

color somecolor() {
  if (numPaletteColors > 0) {
    return goodcolor[int(random(numPaletteColors))];
  }
  return color(random(255)); 
}

void loadPalette(color[] palette) {
  for (int i = 0; i < palette.length && numPaletteColors < MAX_PALETTE_SIZE; i++) {
    goodcolor[numPaletteColors] = palette[i];
    numPaletteColors++;
  }
  
  for (int x = 0; x < 22 && numPaletteColors < MAX_PALETTE_SIZE - 2; x++) {
    goodcolor[numPaletteColors] = #000000;
    numPaletteColors++;
    goodcolor[numPaletteColors] = #FFFFFF;
    numPaletteColors++;
  }
}
