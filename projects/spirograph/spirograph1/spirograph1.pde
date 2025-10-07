// ===================================
// GLOBAL PARAMETERS
// ===================================

int mySeed = 1337; // Global seed for random()


final int SKETCH_WIDTH = 480;
final int SKETCH_HEIGHT = 800;
final int PADDING = 40;
final int MAX_FRAMES = 900;
final boolean SAVE_FRAMES = true;
final int ANIMATION_SPEED = 30; // Frames per second
final boolean INVERT_COLORS = false;

// Visualization parameters
final int TILE_COUNT_X = 4; // Number of tiles horizontally
final int TILE_COUNT_Y = 7; // Number of tiles vertically
final int CURVE_POINTS = 80; // FIX: Increased points for longer, smoother curve
final float MAX_RADIUS_FACTOR = 0.3; // Max size relative to tile size
final float CARRIER_RATIO_MIN = 1.5; // R/r ratio minimum
final float CARRIER_RATIO_MAX = 3.0; // R/r ratio maximum
final float ANIMATION_AMPLITUDE = 0.45; // Amplitude of the cycloid parameter oscillation
final float CURVE_SPEED = 0.005; // Speed of the curve's internal animation
final float FIXED_CURVE_ROTATIONS = 10.0; // FIX: Number of full rotations to draw the curve

// Color palette: Harmonious and Warm (Oranges, Reds, Yellows, Dark Contrast)
// The colors are defined using their HEX values
final color PALETTE_DARK = #012030; // Dark Blue/Teal
final color PALETTE_MID = #45C4B0; // Bright Teal
final color PALETTE_BRIGHT = #9AEBA3; // Light Mint Green
final color PALETTE_ACCENT = #DAFDBA; // Pale Yellow-Green

// Assign colors from the palette to specific roles
final color BACKGROUND_COLOR = PALETTE_DARK; // Applied to the sketch background
final color FOREGROUND_COLOR = PALETTE_MID; // Used for a consistent element in the tiles

// Array of colors available for random assignment to individual tiles
final color[] TILE_COLORS = {PALETTE_MID, PALETTE_BRIGHT, PALETTE_ACCENT};

// System variables
float tileSize;
float sketchX, sketchY, sketchW, sketchH;

// Array to hold our grid of gear-like objects
CycloidGear[][] grid;

// ===================================
// SETTINGS
// ===================================

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

// ===================================
// SETUP
// ===================================

void setup() {
  frameRate(ANIMATION_SPEED);
  randomSeed(mySeed);
  
  // Set color mode to RGB for direct use of defined hex colors
  colorMode(RGB, 255); 

  // Calculate sketch dimensions
  sketchW = width - 2 * PADDING;
  sketchH = height - 2 * PADDING;
  
  // Center the sketch area
  tileSize = min(sketchW / TILE_COUNT_X, sketchH / TILE_COUNT_Y);
  sketchW = TILE_COUNT_X * tileSize;
  sketchH = TILE_COUNT_Y * tileSize;
  
  sketchX = (width - sketchW) / 2;
  sketchY = (height - sketchH) / 2;

  // Initialize the grid
  grid = new CycloidGear[TILE_COUNT_X][TILE_COUNT_Y];
  for (int i = 0; i < TILE_COUNT_X; i++) {
    for (int j = 0; j < TILE_COUNT_Y; j++) {
      float cx = sketchX + i * tileSize + tileSize / 2;
      float cy = sketchY + j * tileSize + tileSize / 2;
      
      // Randomly assign a color from the TILE_COLORS array
      color tileColor = TILE_COLORS[floor(random(TILE_COLORS.length))];
      grid[i][j] = new CycloidGear(cx, cy, tileSize, tileColor);
    }
  }
}

// ===================================
// DRAW
// ===================================

void draw() {
  randomSeed(mySeed); // Keep the base random properties consistent
  background(BACKGROUND_COLOR); // Background color applied here
  noFill();

  // Draw each cycloid cell
  for (int i = 0; i < TILE_COUNT_X; i++) {
    for (int j = 0; j < TILE_COUNT_Y; j++) {
      grid[i][j].update();
      grid[i][j].display();
    }
  }

  // --- FRAME SAVING LOGIC ---
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) {
      noLoop();
    }
  }

  if (frameCount >= MAX_FRAMES) {
    noLoop();
  }
}

// ===================================
// CYCLOID GEAR CLASS
// ===================================

class CycloidGear {
  float centerX, centerY;
  float size;
  float carrierRadius;
  float rollingRadius;
  float rotationDirection;
  color primaryColor; // Individual color for the tile

  CycloidGear(float x, float y, float s, color c) {
    centerX = x;
    centerY = y;
    size = s;
    primaryColor = c;
    
    // Unique random properties per cell
    rotationDirection = random(1) < 0.5 ? -1 : 1;
    
    // R is set based on size, r is derived from R and a random ratio
    carrierRadius = size * MAX_RADIUS_FACTOR;
    float ratio = random(CARRIER_RATIO_MIN, CARRIER_RATIO_MAX);
    rollingRadius = carrierRadius / ratio;
  }

  void update() {
    // Animation is driven by frameCount in display()
  }

  void display() {
    pushMatrix();
    translate(centerX, centerY);

    // Dynamic animation of the rolling radius (r) to create the "pulsing gear" effect
    float ratioShift = sin(frameCount * CURVE_SPEED) * ANIMATION_AMPLITUDE;
    // We use the original rollingRadius to calculate the current ratio based on the animation pulse
    float currentRatio = (carrierRadius / rollingRadius) + ratioShift; 
    float currentRollingRadius = carrierRadius / currentRatio;

    // Overall gear rotation
    float totalRotation = rotationDirection * frameCount * 0.01;
    rotate(totalRotation);

    // Draw the primary hypocycloid/hypotrochoid line
    stroke(primaryColor);
    strokeWeight(2);
    // Draw the hypocycloid (point inside the rolling circle)
    drawCycloid(carrierRadius, currentRollingRadius, 0.85);

    // Draw the secondary epicycloid/epitrochoid line
    strokeWeight(1.5);
    stroke(FOREGROUND_COLOR); // Use the consistent foreground color for this element
    // Draw the epicycloid (point outside the rolling circle)
    drawCycloid(-carrierRadius, currentRollingRadius, 1.15); 
    
    popMatrix();
  }
  
  // Helper function to draw a Cycloid/Hypocycloid/Epicycloid
  void drawCycloid(float R_fixed, float R_rolling, float Point_Factor) {
    
    float R = R_fixed; // Fixed circle radius
    float r = R_rolling; // Rolling circle radius (dynamically changing)
    float d = r * Point_Factor; // Distance from rolling center to tracing point
    float t_start = 0;
    
    // FIX: Set a large, fixed number of rotations (10 full turns) for a continuous curve
    // This prevents the animation from stalling when the dynamic R/r ratio is non-integer.
    float t_end = TWO_PI * FIXED_CURVE_ROTATIONS; 
    
    // R+r for Epicycloid, R-r for Hypocycloid
    float sum_or_diff = (R > 0) ? R - r : abs(R) + r;

    beginShape();
    for (int i = 0; i <= CURVE_POINTS; i++) {
      float t = map(i, 0, CURVE_POINTS, t_start, t_end); 

      float x, y;
      
      if (R > 0) { // Hypocycloid/Hypotrochoid (Rolling *inside*)
        x = sum_or_diff * cos(t) + d * cos(sum_or_diff / r * t);
        y = sum_or_diff * sin(t) - d * sin(sum_or_diff / r * t);
      } else { // Epicycloid/Epitrochoid (Rolling *outside*)
        x = sum_or_diff * cos(t) + d * cos(sum_or_diff / r * t);
        y = sum_or_diff * sin(t) + d * sin(sum_or_diff / r * t);
      }

      vertex(x, y);
    }
    endShape();
  }
}
