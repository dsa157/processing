// SandPainterFriends - Grid-based emergent network visualization
// Inspired by the work of Jared Tarbell.

//===================================================================
// GLOBAL PARAMETERS
//===================================================================

// --- Sketch Setup Parameters ---
final int SKETCH_WIDTH = 480; // 480 (FIXED)
final int SKETCH_HEIGHT = 800; // 800 (FIXED)
final int SEED = 42; // Global seed for random()
final int PADDING = 40; // Padding around the overall sketch (default 40)
final boolean INVERT_COLORS = false; // Invert background/foreground colors (default false)

// --- Animation/Saving Parameters ---
final int ANIMATION_SPEED = 30; // Desired frames per second (default 30)
final int MAX_FRAMES = 900; // Maximum frames to run (default 900)
final boolean SAVE_FRAMES = false; // Save frames to disk (default false)

// --- Color Palette ---
// Coastal Fog (Muted, Monochromatic Blues)
final color[] PALETTE = {
  #102A43, // 0 - Classic Navy (BG)
  #334D5C, // 1 - Dark Slate Gray
  #5E72E4, // 2 - Muted Periwinkle
  #8FAEC4, // 3 - Pale Blue-Gray
  #D9E4EC  // 4 - Very Light Blue (FG)
};
final int BACKGROUND_COLOR_INDEX = 0; // Use Classic Navy
final color BG_COLOR = PALETTE[BACKGROUND_COLOR_INDEX];
final color FG_COLOR = PALETTE[4]; // Use Very Light Blue

// --- Grid Parameters ---
final int COLS = 4; // Number of columns in the grid
final int ROWS = 8; // Number of rows in the grid
final boolean SHOW_GRID = false; // Show/hide grid cell boundaries (default false)
final float CELL_INNER_PADDING_FACTOR = 0.15; // Padding factor * Cell Size (default 0.15)
final int COLOR_START_INDEX = 1; // Start index for cell colors (skipping BG color)
final int COLOR_COUNT = PALETTE.length - COLOR_START_INDEX; // 4 available non-BG colors

// --- Physics/Particle Parameters ---
final int FRIENDS_PER_CELL = 3; // Number of particles per cell (default 3)
final float MAX_SPEED = 1.2; // Maximum velocity magnitude (default 1.2)
final float MAX_FORCE = 0.08; // Maximum steering force (default 0.08)
final float NEIGHBOR_RADIUS = 30; // Radius for neighbor interaction (default 30)
final float SEPARATION_DISTANCE = 12; // Closest distance to maintain (default 12)
final float SEPARATION_WEIGHT = 1.5; // Weighting for separation (default 1.5)
final float ALIGNMENT_WEIGHT = 0.5; // Weighting for alignment (default 0.5)
final float COHESION_WEIGHT = 0.3; // Weighting for cohesion (default 0.3)
final float CONNECTION_OPACITY_DECAY = 0.05; // Opacity decrease per frame (default 0.05)

//===================================================================
// CLASSES
//===================================================================

// --- Friend Class: The particle agent ---
class Friend {
  PVector position;
  PVector velocity;
  PVector acceleration;
  PVector homeCenter; // Center of the grid cell
  float cellInnerPadding;
  ArrayList<Connection> activeConnections; 

  Friend(PVector initialPos, PVector center, float padding) {
    position = initialPos;
    velocity = PVector.random2D();
    velocity.setMag(random(MAX_SPEED * 0.5, MAX_SPEED));
    acceleration = new PVector();
    homeCenter = center;
    cellInnerPadding = padding;
    activeConnections = new ArrayList<Connection>();
  }

  void applyForce(PVector force) {
    acceleration.add(force);
  }

  PVector flock(ArrayList<Friend> friends) {
    PVector sep = separate(friends).mult(SEPARATION_WEIGHT);
    PVector ali = align(friends).mult(ALIGNMENT_WEIGHT);
    PVector coh = cohesion(friends).mult(COHESION_WEIGHT);

    PVector totalForce = new PVector();
    totalForce.add(sep);
    totalForce.add(ali);
    totalForce.add(coh);

    return totalForce;
  }

  PVector steer(PVector target) {
    PVector steer = PVector.sub(target, velocity);
    steer.limit(MAX_FORCE);
    return steer;
  }

  // --- Localized Flocking Rules (Separation, Alignment, Cohesion) ---

  PVector separate(ArrayList<Friend> friends) {
    PVector steer = new PVector();
    int count = 0;
    for (Friend other : friends) {
      float d = PVector.dist(position, other.position);
      if ((d > 0) && (d < SEPARATION_DISTANCE)) {
        PVector diff = PVector.sub(position, other.position);
        diff.normalize();
        diff.div(d); 
        steer.add(diff);
        count++;
      }
    }
    if (count > 0) {
      steer.div(count);
    }
    if (steer.mag() > 0) {
      steer.setMag(MAX_SPEED);
      steer.sub(velocity);
      steer.limit(MAX_FORCE);
    }
    return steer;
  }

  PVector align(ArrayList<Friend> friends) {
    PVector sum = new PVector();
    int count = 0;
    for (Friend other : friends) {
      float d = PVector.dist(position, other.position);
      if ((d > 0) && (d < NEIGHBOR_RADIUS)) {
        sum.add(other.velocity);
        count++;
      }
    }
    if (count > 0) {
      sum.div(count);
      sum.setMag(MAX_SPEED);
      PVector steer = PVector.sub(sum, velocity);
      steer.limit(MAX_FORCE);
      return steer;
    }
    return new PVector();
  }

  PVector cohesion(ArrayList<Friend> friends) {
    PVector sum = new PVector();
    int count = 0;
    for (Friend other : friends) {
      float d = PVector.dist(position, other.position);
      if ((d > 0) && (d < NEIGHBOR_RADIUS)) {
        sum.add(other.position);
        count++;
      }
    }
    if (count > 0) {
      sum.div(count);
      return steer(sum);
    }
    return new PVector();
  }

  // --- Grid Confinement (Steering and Hard Walls) ---

  PVector confine() {
    float cellHalfWidth = grid.cellWidth / 2 - cellInnerPadding;
    float cellHalfHeight = grid.cellHeight / 2 - cellInnerPadding;
    float maxDistSq = cellHalfWidth * cellHalfWidth + cellHalfHeight * cellHalfHeight;

    PVector relPos = PVector.sub(position, homeCenter);
    float distSq = relPos.magSq();

    if (distSq > maxDistSq * 0.8) {
      PVector desired = PVector.sub(homeCenter, position);
      desired.normalize();
      desired.mult(MAX_SPEED);

      PVector steer = PVector.sub(desired, velocity);
      steer.limit(MAX_FORCE * 2.0);
      return steer;
    }
    return new PVector();
  }
  
  void checkWalls() {
    float xMin = homeCenter.x - grid.cellWidth / 2 + cellInnerPadding;
    float xMax = homeCenter.x + grid.cellWidth / 2 - cellInnerPadding;
    float yMin = homeCenter.y - grid.cellHeight / 2 + cellInnerPadding;
    float yMax = homeCenter.y + grid.cellHeight / 2 - cellInnerPadding;
    
    if (position.x < xMin) {
      position.x = xMin;
      velocity.x *= -1;
    } else if (position.x > xMax) {
      position.x = xMax;
      velocity.x *= -1;
    }
    
    if (position.y < yMin) {
      position.y = yMin;
      velocity.y *= -1;
    } else if (position.y > yMax) {
      position.y = yMax;
      velocity.y *= -1;
    }
  }

  void update() {
    applyForce(flock(grid.getCellFriends(homeCenter)).add(confine()));
    checkWalls(); 
    
    velocity.add(acceleration);
    velocity.limit(MAX_SPEED);
    position.add(velocity);
    acceleration.mult(0);
  }
}

// --- Connection Class: The brush-stroke for visualization ---
class Connection {
  PVector p1, p2;
  float opacity;
  color drawColor;
  float lineWeight;

  Connection(PVector pos1, PVector pos2, color c, float weight) {
    p1 = pos1.copy();
    p2 = pos2.copy();
    opacity = 1.0;
    drawColor = c;
    lineWeight = weight;
  }

  void display() {
    stroke(drawColor, opacity * 255);
    strokeWeight(lineWeight);
    line(p1.x, p1.y, p2.x, p2.y);
  }
}

// --- Grid Class: Manages the cells and particles ---
class Grid {
  float cellWidth;
  float cellHeight;
  GridCell[][] cells;
  float sketchX, sketchY, sketchW, sketchH;

  Grid(float x, float y, float w, float h) {
    sketchX = x;
    sketchY = y;
    sketchW = w;
    sketchH = h;
    cellWidth = sketchW / COLS;
    cellHeight = sketchH / ROWS;
    cells = new GridCell[COLS][ROWS];

    // Initialize cells
    for (int i = 0; i < COLS; i++) {
      for (int j = 0; j < ROWS; j++) {
        float cx = sketchX + i * cellWidth + cellWidth / 2;
        float cy = sketchY + j * cellHeight + cellHeight / 2;
        
        // Pass a dummy color to the GridCell constructor since color is now chosen per-connection
        cells[i][j] = new GridCell(new PVector(cx, cy), i, j, cellWidth, cellHeight);
      }
    }
  }

  void update() {
    for (int i = 0; i < COLS; i++) {
      for (int j = 0; j < ROWS; j++) {
        cells[i][j].updateFriends();
      }
    }

    for (int i = 0; i < COLS; i++) {
      for (int j = 0; j < ROWS; j++) {
        cells[i][j].createConnections();
      }
    }
  }

  void display() {
    for (int i = 0; i < COLS; i++) {
      for (int j = 0; j < ROWS; j++) {
        cells[i][j].displayConnections();
      }
    }

    if (SHOW_GRID) {
      noFill();
      stroke(FG_COLOR, 100);
      strokeWeight(1);
      rectMode(CORNER);
      for (int i = 0; i < COLS; i++) {
        for (int j = 0; j < ROWS; j++) {
          rect(sketchX + i * cellWidth, sketchY + j * cellHeight, cellWidth, cellHeight);
        }
      }
    }
  }

  ArrayList<Friend> getCellFriends(PVector center) {
    for (int i = 0; i < COLS; i++) {
      for (int j = 0; j < ROWS; j++) {
        if (PVector.dist(center, cells[i][j].center) < 1) {
          return cells[i][j].friends;
        }
      }
    }
    return new ArrayList<Friend>();
  }
}

// --- GridCell Class: Contains the Friends and their connections ---
class GridCell {
  PVector center;
  int col, row;
  float w, h;
  ArrayList<Friend> friends;
  ArrayList<Connection> connections;
  float innerPadding;
  // cellConnectionColor is no longer used, but kept to show structure change
  // color cellConnectionColor; 

  GridCell(PVector c, int i, int j, float width, float height) { // Removed connColor argument
    center = c;
    col = i;
    row = j;
    w = width;
    h = height;
    connections = new ArrayList<Connection>();
    friends = new ArrayList<Friend>();
    
    innerPadding = min(w, h) * CELL_INNER_PADDING_FACTOR;

    // Initialize Friends
    for (int k = 0; k < FRIENDS_PER_CELL; k++) {
      float startX = center.x + random(-w/2 + innerPadding, w/2 - innerPadding);
      float startY = center.y + random(-h/2 + innerPadding, h/2 - innerPadding);
      friends.add(new Friend(new PVector(startX, startY), center, innerPadding));
    }
  }

  void updateFriends() {
    for (Friend f : friends) {
      f.update();
    }
  }

  // Creates the cumulative, 'SandPainter' brush-stroke effect
  void createConnections() {
    for (int i = 0; i < friends.size(); i++) {
      Friend f1 = friends.get(i); 

      for (int j = i + 1; j < friends.size(); j++) {
        Friend f2 = friends.get(j);
        float d = PVector.dist(f1.position, f2.position);
        
        if (d < NEIGHBOR_RADIUS * 1.5) {
          // NEW LOGIC: Randomly select a color for THIS connection
          int colorIndex = COLOR_START_INDEX + floor(random(COLOR_COUNT));
          color randomConnColor = PALETTE[colorIndex];
          
          Connection newConn = new Connection(f1.position, f2.position, randomConnColor, 0.75 + d * 0.05);
          connections.add(newConn);
        }
      }
    }
  }

  void displayConnections() {
    for (int i = connections.size() - 1; i >= 0; i--) {
      Connection conn = connections.get(i);
      conn.opacity -= CONNECTION_OPACITY_DECAY * 0.5;
      if (conn.opacity <= 0) {
        connections.remove(i);
      } else {
        conn.display();
      }
    }
  }
}

//===================================================================
// MAIN PROGRAM
//===================================================================

Grid grid;
float sketchCanvasX, sketchCanvasY;
float sketchCanvasW, sketchCanvasH;
color actualBG, actualFG;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  randomSeed(SEED);
  frameRate(ANIMATION_SPEED);

  // Set up colors
  if (INVERT_COLORS) {
    actualBG = BG_COLOR;
    actualFG = FG_COLOR;
    if (BACKGROUND_COLOR_INDEX == 0) {
      actualBG = PALETTE[4];
      actualFG = PALETTE[0];
    } else {
      actualBG = color(255 - red(BG_COLOR), 255 - green(BG_COLOR), 255 - blue(BG_COLOR));
      actualFG = color(255 - red(FG_COLOR), 255 - green(FG_COLOR), 255 - blue(FG_COLOR));
    }
  } else {
    actualBG = BG_COLOR;
    actualFG = FG_COLOR;
  }

  // Calculate sketch area and center it
  sketchCanvasW = width - 2 * PADDING;
  sketchCanvasH = height - 2 * PADDING;
  sketchCanvasX = PADDING + (width - 2 * PADDING - sketchCanvasW) / 2;
  sketchCanvasY = PADDING + (height - 2 * PADDING - sketchCanvasH) / 2;

  grid = new Grid(sketchCanvasX, sketchCanvasY, sketchCanvasW, sketchCanvasH);

  background(actualBG);
}

void draw() {
  // Draw a semi-transparent rectangle for the cumulative fade effect (SandPainter)
  fill(actualBG, 10);
  noStroke();
  rect(0, 0, width, height);
  
  grid.update();
  grid.display();

  // --- Frame Saving Block ---
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) {
      noLoop();
      println("Animation finished and saved.");
    }
  } else if (frameCount >= MAX_FRAMES) {
    noLoop();
  }
}
