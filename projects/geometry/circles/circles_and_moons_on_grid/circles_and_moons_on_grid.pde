// ----------------------------------------------------------------------
// GLOBAL CONFIGURATION
// ----------------------------------------------------------------------
final int SKETCH_WIDTH = 480;
final int SKETCH_HEIGHT = 800;

// Canvas setup
final int PADDING = 20; // Default: 40 (Padding around the sketch)
final boolean INVERT_COLORS = false; // Default: false (Invert background/foreground)

// Grid Parameters
final int GRID_COLS = 4; // Default: 4 (Number of grid columns)
final int GRID_ROWS = 8; // Default: 8 (Number of grid rows)
final int MAX_SYSTEMS = GRID_COLS * GRID_ROWS; // Max systems equals grid cells
final boolean SHOW_GRID_LINES = false; // Default: false (Show/hide the bounding grid)

// Animation & Save settings
final int MAX_FRAMES = 900; // Default: 900 (Frames before stopping loop)
final boolean SAVE_FRAMES = false; // Default: false (Save frames to file)
final int ANIMATION_SPEED = 30; // Default: 30 (Frames per second)
final long SEED = 12345; // Default: 12345 (Global seed for random())

// Color palette (Hex values) - Inspired by a popular dark/vibrant Adobe Color theme
final int[] PALETTE = {
  0xFFCF4747, // African Mahogany (Faded Red)
  0xFFEA7A58, // Temple of Orange (Coral)
  0xFFE4DCCB, // Light Hog Bristle (Cream)
  0xFFA6C4BC, // Yān Hūi Smoke (Faded Teal)
  0xFF524656  // Black Magic (Muted Dark Purple BG)
};

final int BG_COLOR_INDEX = 2; // Default: 4 (Index of background color in PALETTE -> Black)

// Sketch parameters
final int MIN_SYSTEMS = 32; // Default: 32 (Number of systems to fill the grid)
final int MIN_CIRCLES_PER_SYSTEM = 2; // Default: 2 (Min tangentially connected circles per group)
final int MAX_CIRCLES_PER_SYSTEM = 4; // Default: 4 (Max tangentially connected circles per group)

// Dynamic radius bounds based on cell size
final float MIN_CIRCLE_RADIUS_FACTOR = 0.3; // Default: 0.3 (Min circle radius as a factor of cell size)
final float MAX_CIRCLE_RADIUS_FACTOR = 0.6; // Default: 0.6 (Max circle radius as a factor of cell size)

final float MIN_ROTATION_SPEED = 0.016; // Default: 0.002
final float MAX_ROTATION_SPEED = 0.06; // Default: 0.015
final float MOON_RADIUS_FACTOR = 0.5; // Default: 0.1 (Moon size relative to cell size)
final float MOON_ROTATION_SPEED = 0.1; // Default: 0.05

// ----------------------------------------------------------------------
// GLOBAL VARIABLES
// ----------------------------------------------------------------------
System[] systems;
int bgColor;
float cellWidth, cellHeight;

// ----------------------------------------------------------------------
// SETTINGS
// ----------------------------------------------------------------------
void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

// ----------------------------------------------------------------------
// SETUP
// ----------------------------------------------------------------------
void setup() {
  randomSeed(SEED);
  frameRate(ANIMATION_SPEED);

  // Set Background Color from Palette (Default: BG_COLOR_INDEX 4 -> Black)
  bgColor = PALETTE[BG_COLOR_INDEX];
  if (INVERT_COLORS) {
    // Invert the RGB part, keep the Alpha FF
    bgColor = (bgColor & 0xFF000000) | (~(bgColor & 0x00FFFFFF) & 0x00FFFFFF);
  }

  // Calculate grid dimensions
  float paddedWidth = width - 2 * PADDING;
  float paddedHeight = height - 2 * PADDING;
  cellWidth = paddedWidth / GRID_COLS;
  cellHeight = paddedHeight / GRID_ROWS;
  
  // Initialize Systems (one per grid cell)
  int numSystems = MAX_SYSTEMS; 
  systems = new System[numSystems];
  
  for (int i = 0; i < numSystems; i++) {
    int col = i % GRID_COLS;
    int row = i / GRID_COLS;

    // Center of the current grid cell
    float cellX = PADDING + col * cellWidth + cellWidth / 2;
    float cellY = PADDING + row * cellHeight + cellHeight / 2;

    // The max size the system can take is half the smallest cell dimension
    float maxSystemRadius = min(cellWidth, cellHeight) / 2; 

    // Random rotation speed and direction
    float speed = random(MIN_ROTATION_SPEED, MAX_ROTATION_SPEED);
    if (random(1) < 0.5) {
      speed *= -1; 
    }
    
    systems[i] = new System(cellX, cellY, maxSystemRadius, speed);
  }
}

// ----------------------------------------------------------------------
// DRAW LOOP
// ----------------------------------------------------------------------
void draw() {
  background(bgColor);
  
  // Optional: Draw the grid lines
  if (SHOW_GRID_LINES) {
    stroke(255, 50); // Light gray, semi-transparent
    strokeWeight(1);
    for (int i = 0; i <= GRID_COLS; i++) {
      line(PADDING + i * cellWidth, PADDING, PADDING + i * cellWidth, height - PADDING);
    }
    for (int j = 0; j <= GRID_ROWS; j++) {
      line(PADDING, PADDING + j * cellHeight, width - PADDING, PADDING + j * cellHeight);
    }
  }

  // Set blend mode to XOR (DIFFERENCE for the visual effect)
  // This is where the magic of the color crossings happens.
  blendMode(DIFFERENCE); 

  // Draw all systems
  for (System s : systems) {
    s.update();
    s.display();
  }

  // Restore blend mode to default
  blendMode(BLEND);

  // ----------------------------------------------------------------------
  // FRAME SAVING & LOOP STOP
  // ----------------------------------------------------------------------
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) {
      noLoop();
    }
  } else if (frameCount >= MAX_FRAMES) {
    noLoop();
  }
}

// ----------------------------------------------------------------------
// CLASSES
// ----------------------------------------------------------------------

class System {
  float centerX, centerY;
  float maxRadius; 
  float rotSpeed;
  float angle;
  ArrayList<Circle> circles;

  System(float x, float y, float r, float speed) {
    centerX = x;
    centerY = y;
    maxRadius = r;
    rotSpeed = speed;
    angle = random(TWO_PI);
    circles = new ArrayList<Circle>();
    
    initializeCircles();
  }
  
  void initializeCircles() {
    int numCircles = (int)random(MIN_CIRCLES_PER_SYSTEM, MAX_CIRCLES_PER_SYSTEM + 1);
    
    for (int i = 0; i < numCircles; i++) {
      // Circle radius is now based on a factor of the available cell size
      float r = random(MIN_CIRCLE_RADIUS_FACTOR * maxRadius * 2, MAX_CIRCLE_RADIUS_FACTOR * maxRadius * 2);
      
      // Random color from the palette
      int colorIndex = (int)random(PALETTE.length - 1); // Exclude BG color for main elements
      int c = PALETTE[colorIndex];
      if (INVERT_COLORS) {
         c = (c & 0xFF000000) | (~(c & 0x00FFFFFF) & 0x00FFFFFF);
      }
      
      circles.add(new Circle(r, c));
    }
    
    // Position circles tangentially in a chain and find the pivot point.
    float currentX = 0;
    
    // Calculate local positions relative to an arbitrary center (0, 0)
    for (int i = 0; i < circles.size(); i++) {
      Circle c = circles.get(i);
      
      if (i > 0) {
        Circle prev = circles.get(i-1);
        // Tangent connection: new position is old position + old radius + new radius
        currentX += prev.radius + c.radius; 
      }
      c.localX = currentX;
      c.localY = 0; 
    }
    
    // Shift the local coordinates so the visual center of the whole chain is at (0,0)
    float totalWidth = circles.get(circles.size() - 1).localX + circles.get(circles.size() - 1).radius;
    float shift = totalWidth / 2;
    
    for (Circle c : circles) {
        c.localX -= shift;
    }
  }

  void update() {
    angle += rotSpeed;
    for(Circle c : circles) {
      c.update();
    }
  }

  void display() {
    pushMatrix();
    translate(centerX, centerY);
    rotate(angle); // Rotate the whole system around the grid cell center

    for (int i = 0; i < circles.size(); i++) {
      Circle current = circles.get(i);
      current.display();
      
      // Calculate tangent points for the "moons" (except for the last circle)
      if (i < circles.size() - 1) {
          Circle next = circles.get(i + 1);
          
          // Tangent point (midpoint between the two circle centers)
          float tx = (current.localX * next.radius + next.localX * current.radius) / (current.radius + next.radius);
          float ty = 0; 
          
          // Draw the moon rotating around the tangent point
          drawMoon(tx, ty, current.rotMoonAngle);
      }
    }

    popMatrix();
  }
  
  void drawMoon(float x, float y, float moonAngle) {
    pushMatrix();
    translate(x, y); // Translate to the tangent point
    rotate(moonAngle); // Rotate the moon itself

    // Draw the moon
    fill(255, 100); // Simple white/gray to contrast the XOR colors
    noStroke();
    
    // Moon parameters relative to cell size
    float moonOffset = min(cellWidth, cellHeight) * 0.05; 
    float moonSize = min(cellWidth, cellHeight) * MOON_RADIUS_FACTOR;
    
    ellipse(moonOffset, 0, moonSize, moonSize); 

    popMatrix();
  }
}

class Circle {
  float radius;
  int circleColor;
  float localX, localY; // Position relative to the system's center
  float rotMoonAngle;
  float rotMoonSpeed;

  Circle(float r, int c) {
    radius = r;
    circleColor = c;
    rotMoonAngle = random(TWO_PI);
    
    // Randomize moon rotation direction as well
    rotMoonSpeed = MOON_ROTATION_SPEED * (random(1) < 0.5 ? 1 : -1);
  }

  void update() {
    rotMoonAngle += rotMoonSpeed;
  }

  void display() {
    pushMatrix();
    translate(localX, localY); // Move to the circle's position
    
    noStroke();
    fill(circleColor, 200); // Main circle body with transparency for better XOR
    ellipse(0, 0, radius * 2, radius * 2);
    
    popMatrix();
  }
}
