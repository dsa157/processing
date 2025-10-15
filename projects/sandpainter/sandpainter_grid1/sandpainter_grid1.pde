// SandPainterFriends - Grid-based emergent network visualization
// Inspired by the work of Jared Tarbell.

//===================================================================
// GLOBAL PARAMETERS
//===================================================================

// --- Sketch Setup Parameters ---
final int SKETCH_WIDTH = 480; // 480
final int SKETCH_HEIGHT = 800; // 800
final int SEED = 42; // Global seed for random()
final int PADDING = 20; // Padding around the overall sketch (default 40)
final boolean INVERT_COLORS = false; // Invert background/foreground colors (default false)

// --- Animation/Saving Parameters ---
final int ANIMATION_SPEED = 30; // Desired frames per second (default 30)
final int MAX_FRAMES = 900; // Maximum frames to run (default 900)
final boolean SAVE_FRAMES = false; // Save frames to disk (default false)

// --- Color Palette ---
final color[] PALETTE = {
  #2B1B17, // Dark Espresso Brown (BG)
  #5E3526, // Burnt Sienna
  #993333, // Deep Brick Red
  #AF7737, // Mustard/Amber
  #B2B59C  // Dusty Olive Green (FG)
};


final int BACKGROUND_COLOR_INDEX = 0; // Use Darkest Blue/Black
final color BG_COLOR = PALETTE[BACKGROUND_COLOR_INDEX];
final color FG_COLOR = PALETTE[4]; 

// --- Grid Parameters ---
final int COLS = 4; // Number of columns in the grid (default 8)
final int ROWS = 8; // Number of rows in the grid (default 8)
final boolean SHOW_GRID = false; // Show/hide grid cell boundaries (default false)
final float CELL_INNER_PADDING_FACTOR = 0.15; // Padding factor * Cell Size (default 0.15)

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
final int CONNECTION_COLOR_INDEX = 3; // Light Cyan for connections

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
  // activeConnections is unused in the fixed version, but retained for class structure integrity
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

  // Applies the steering force to acceleration
  void applyForce(PVector force) {
    acceleration.add(force);
  }

  // Flocking behavior (Separation, Alignment, Cohesion)
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

  // Steering force calculation
  PVector steer(PVector target) {
    PVector steer = PVector.sub(target, velocity);
    steer.limit(MAX_FORCE);
    return steer;
  }

  // --- Localized Flocking Rules ---

  // Rule 1: Separation - Avoid crowding neighbors
  PVector separate(ArrayList<Friend> friends) {
    PVector steer = new PVector();
    int count = 0;
    for (Friend other : friends) {
      float d = PVector.dist(position, other.position);
      if ((d > 0) && (d < SEPARATION_DISTANCE)) {
        PVector diff = PVector.sub(position, other.position);
        diff.normalize();
        diff.div(d); // Weight by distance
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

  // Rule 2: Alignment - Steer towards average velocity
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

  // Rule 3: Cohesion - Steer towards average position
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
      return steer(sum); // Steer towards the center of mass
    }
    return new PVector();
  }

  // --- Grid Confinement ---

  // Rule 4: Confinement - Stay within the cell's padded area
  PVector confine() {
    float cellHalfWidth = grid.cellWidth / 2 - cellInnerPadding;
    float cellHalfHeight = grid.cellHeight / 2 - cellInnerPadding;
    float maxDistSq = cellHalfWidth * cellHalfWidth + cellHalfHeight * cellHalfHeight;

    // Relative position to the center of the cell
    PVector relPos = PVector.sub(position, homeCenter);
    float distSq = relPos.magSq();

    if (distSq > maxDistSq * 0.8) { // Start steering when close to the boundary
      // Calculate a force that steers towards the homeCenter
      PVector desired = PVector.sub(homeCenter, position);
      desired.normalize();
      desired.mult(MAX_SPEED);

      PVector steer = PVector.sub(desired, velocity);
      steer.limit(MAX_FORCE * 2.0); // Stronger force for confinement
      return steer;
    }
    return new PVector();
  }
  
  // Rule 5: Wall Bounce - Hard boundary collision for immediate correction
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


  // Update position and velocity
  void update() {
    applyForce(flock(grid.getCellFriends(homeCenter)).add(confine()));
    checkWalls(); // Apply hard boundary check after steering
    
    velocity.add(acceleration);
    velocity.limit(MAX_SPEED);
    position.add(velocity);
    acceleration.mult(0); // Reset acceleration

    // activeConnections loop removed as it was part of the original flawed logic
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
        cells[i][j] = new GridCell(new PVector(cx, cy), i, j, cellWidth, cellHeight);
      }
    }
  }

  void update() {
    // 1. Update all Friends' positions
    for (int i = 0; i < COLS; i++) {
      for (int j = 0; j < ROWS; j++) {
        cells[i][j].updateFriends();
      }
    }

    // 2. Create connections (SandPainter effect)
    for (int i = 0; i < COLS; i++) {
      for (int j = 0; j < ROWS; j++) {
        cells[i][j].createConnections();
      }
    }
  }

  void display() {
    // Draw accumulated connections first
    for (int i = 0; i < COLS; i++) {
      for (int j = 0; j < ROWS; j++) {
        cells[i][j].displayConnections();
      }
    }

    // Draw grid if enabled
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

  // Helper to get the list of friends in a specific cell
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

  GridCell(PVector c, int i, int j, float width, float height) {
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
      // Start position is a random point within the padded cell area
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

  // CORRECTED: Creates the cumulative, 'SandPainter' brush-stroke effect
  void createConnections() {
    for (int i = 0; i < friends.size(); i++) {
      Friend f1 = friends.get(i); // <-- FIX: Defines f1 in the correct scope

      for (int j = i + 1; j < friends.size(); j++) {
        Friend f2 = friends.get(j);
        float d = PVector.dist(f1.position, f2.position);
        
        // Connect friends that are close enough
        if (d < NEIGHBOR_RADIUS * 1.5) {
          // Use current positions to create a new connection trace
          // Line thickness is related to distance to create organic look
          Connection newConn = new Connection(f1.position, f2.position, PALETTE[CONNECTION_COLOR_INDEX], 0.75 + d * 0.05);
          connections.add(newConn);
        }
      }
      // Flawed "movement trail" logic removed.
    }
  }

  void displayConnections() {
    // Clean up old connections
    for (int i = connections.size() - 1; i >= 0; i--) {
      Connection conn = connections.get(i);
      conn.opacity -= CONNECTION_OPACITY_DECAY * 0.5; // Slower decay for the cumulative effect
      if (conn.opacity <= 0) {
        connections.remove(i);
      } else {
        conn.display();
      }
    }
  }
  
  void displayFriends() {
    noStroke();
    fill(FG_COLOR);
    for (Friend f : friends) {
      ellipse(f.position.x, f.position.y, 3, 3);
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

  // Set up inverted colors if requested
  if (INVERT_COLORS) {
    actualBG = BG_COLOR;
    actualFG = FG_COLOR;
    if (BACKGROUND_COLOR_INDEX == 0) { // If using the darkest color
      actualBG = PALETTE[4];
      actualFG = PALETTE[0];
    } else { // Generic inversion for other colors
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

  // Use a transparent background for the cumulative drawing effect
  background(actualBG);
}

void draw() {
  // Draw a semi-transparent rectangle over the canvas for a slow fade/trail effect
  // The opacity (10/255) controls the persistence of the 'sand'.
  fill(actualBG, 10);
  noStroke();
  rect(0, 0, width, height);
  
  // The grid update manages all Friend movement and connection generation
  grid.update();
  
  // The grid display draws all the accumulated connections
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
