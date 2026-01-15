// 2025.11.29.11.02.15
// Version: 2.2

// --- Parameters ---
final int SKETCH_WIDTH = 480;  // default: 800 -> Changed to 480
final int SKETCH_HEIGHT = 800; // default: 800 -> Changed to 800
final int SEED_VALUE = 157751;     // default: 42
final int PADDING = 40;        // default: 40
final int MAX_FRAMES = 900;    // default: 900
final int ANIMATION_SPEED = 30; // default: 30 (frames)
final boolean SAVE_FRAMES = false; // default: false
final boolean INVERT_BACKGROUND = false; // default: false
final boolean SHOW_GRID_CELLS = false; // default: false

final int GRID_COLS = 5;       // default: 4 -> Changed to 5
final int GRID_ROWS = 7;       // default: 6 -> Changed to 7
final float CUBE_SCALE = 0.70; // default: 0.5 -> Changed to 0.70
final float MAX_ROTATION_SPEED = 0.01; // default: 0.05 (radians per frame)
final float COLOR_CYCLE_SPEED = 0.005; // default: 0.005
final float LINE_STROKE_WEIGHT = 1.0; // default: 1.5 -> Slightly thinner line for density
final float RADIAL_COLOR_OFFSET = 1.75; // default: 1.0 -> Increased for stronger phase difference

// Expanded WARM_PALETTE with more contrasting warm colors for the cubes
final int[] WARM_PALETTE = {
  #FF0000, // Pure Red (High Contrast)
  #FF4500, // Orange-Red / Tomato
  #FF8C00, // Dark Orange / Tangelo
  #FFD700, // Gold
  #FFFF00, // Pure Yellow (High Contrast)
  #FFA07A, // Light Salmon
  #F0E68C  // Khaki / Muted Yellow
};

final int[] COOL_ELECTRIC_PALETTE = {
  #1C2A39, // BG
  #00FFFF, 
  #00CCFF, 
  #CC00FF, 
  #FFAA00, 
  #FFFFFF
};

final int[] DEEP_EARTHY_PALETTE = {
  #34495E, // BG
  #2ECC71,
  #F1C40F, 
  #E67E22, 
  #D35400, 
  #ECF0F1
};

final int[] BRIGHT_HIGH_KEY_PALETTE = {
  #F7F7F7, // BG
  #C0392B,
  #8E44AD,
  #2980B9, 
  #16A085, 
  #3498DB
};

final int[] VAPORWAVE_PALETTE = {
  #0D0033, // BG
  #FF0080,
  #00FFFF,
  #FFEA00,
  #9933FF,
  #FF6600
};

int[] PALETTE = COOL_ELECTRIC_PALETTE;

final int BACKGROUND_COLOR_INDEX = 0; // default: 4 -> Deep Violet/Blue

// --- Global Variables ---
int background_color;
int foreground_color;
MetatronCube[][] cubes;

// --- Setup ---
void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  randomSeed(SEED_VALUE);
  
  // Set colors (Background is constant)
  int base_bg = PALETTE[BACKGROUND_COLOR_INDEX % PALETTE.length];
  
  if (INVERT_BACKGROUND) {
    colorMode(RGB);
    background_color = color(255 - red(base_bg), 255 - green(base_bg), 255 - blue(base_bg));
    foreground_color = base_bg;
  } else {
    background_color = base_bg;
    foreground_color = #FFFFFF; // A contrasting color for lines/circles
  }
  
  // Set up the grid of cubes
  cubes = new MetatronCube[GRID_ROWS][GRID_COLS];
  float cellWidth = (float)(SKETCH_WIDTH - 2 * PADDING) / GRID_COLS;
  float cellHeight = (float)(SKETCH_HEIGHT - 2 * PADDING) / GRID_ROWS;
  float maxRadius = min(cellWidth, cellHeight) * 0.5 * CUBE_SCALE;
  
  for (int r = 0; r < GRID_ROWS; r++) {
    for (int c = 0; c < GRID_COLS; c++) {
      float centerX = PADDING + c * cellWidth + cellWidth / 2;
      float centerY = PADDING + r * cellHeight + cellHeight / 2;
      
      // Assign a random starting offset for color cycling
      float colorOffset = random(PALETTE.length); 
      
      // --- Rotation Logic ---
      float baseSpeed = random(MAX_ROTATION_SPEED * 0.5, MAX_ROTATION_SPEED);
      float rotationSpeed;
      
      // Determine direction based on row (r) and column (c)
      // Row 0 (r=0) starts with CCW (+), then alternates
      // Row 1 (r=1) starts with CW (-), then alternates
      if (r % 2 == 0) {
        // Even rows (0, 2, 4, 6) start CCW (+)
        rotationSpeed = (c % 2 == 0) ? baseSpeed : -baseSpeed;
      } else {
        // Odd rows (1, 3, 5) start CW (-)
        rotationSpeed = (c % 2 == 0) ? -baseSpeed : baseSpeed;
      }
      // --- End Rotation Logic ---
      
      cubes[r][c] = new MetatronCube(centerX, centerY, maxRadius, colorOffset, rotationSpeed);
    }
  }
  
  // Use HSB for smooth interpolation
  colorMode(HSB, 360, 100, 100, 100);
  frameRate(ANIMATION_SPEED);
}

// --- Draw Loop ---
void draw() {
  background(background_color);
  
  // Calculate cell dimensions
  float cellWidth = (float)(SKETCH_WIDTH - 2 * PADDING) / GRID_COLS;
  float cellHeight = (float)(SKETCH_HEIGHT - 2 * PADDING) / GRID_ROWS;

  // Draw the grid and cubes
  for (int r = 0; r < GRID_ROWS; r++) {
    for (int c = 0; c < GRID_COLS; c++) {
      float cellX = PADDING + c * cellWidth;
      float cellY = PADDING + r * cellHeight;
      
      if (SHOW_GRID_CELLS) {
        stroke(255, 100);
        noFill();
        rect(cellX, cellY, cellWidth, cellHeight);
      }
      
      cubes[r][c].update();
      cubes[r][c].display();
    }
  }
  
  // --- Frame Saving Logic ---
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) {
      noLoop();
    }
  }
}

// --- MetatronCube Class ---
class MetatronCube {
  float centerX, centerY;
  float radius;
  float colorOffset; // Starting offset for color cycling (float for interpolation)
  float currentRotation;
  float rotationSpeed;
  
  MetatronCube(float x, float y, float r, float offset, float rotSpeed) {
    centerX = x;
    centerY = y;
    radius = r;
    colorOffset = offset;
    rotationSpeed = rotSpeed;
    currentRotation = random(TWO_PI); // Start with a random rotation
  }

  void update() {
    currentRotation += rotationSpeed;
  }
  
  // Helper function to get a smoothly interpolated color for a specific element
  int getComponentColor(float cyclePos, float offsetSteps) {
    int numWarmColors = PALETTE.length;
    // Use offsetSteps (e.g., 0.0, 1.75, 3.5, 5.25) to control the radial phase
    float current_pos = cyclePos + offsetSteps; 
    
    // Determine the two colors to interpolate between
    int index1 = (int)floor(current_pos) % numWarmColors;
    int index2 = (index1 + 1) % numWarmColors;
    float amt = current_pos - floor(current_pos);
    
    // Smoothly interpolate the color
    int lerped_color = lerpColor(PALETTE[index1], PALETTE[index2], amt);
    
    // Convert to HSB for slight adjustments
    float h = hue(lerped_color);
    float s = saturation(lerped_color);
    float b = brightness(lerped_color);
    
    // Adjust brightness/saturation for visual distinction between elements
    if (offsetSteps == 0.0) return color(h, s * 0.9, b * 1.1, 100); 
    if (offsetSteps == RADIAL_COLOR_OFFSET) return color(h, s * 1.0, b * 1.0, 100); 
    if (offsetSteps == RADIAL_COLOR_OFFSET * 2.0) return color(h, s * 1.1, b * 0.9, 100); 
    if (offsetSteps == RADIAL_COLOR_OFFSET * 3.0) return color(h, s * 1.0, b * 1.1, 100); 
    
    return lerped_color; // Fallback
  }

  void display() {
    pushMatrix();
    translate(centerX, centerY);
    rotate(currentRotation);

    // --- Radial Color Pulse Logic ---
    float baseCyclePosition = (frameCount * COLOR_CYCLE_SPEED + colorOffset);
    
    // Apply fixed, large offsets to create the radial ripple (0.0 -> 1.75 -> 3.5 -> 5.25)
    int inner_circle_color = getComponentColor(baseCyclePosition, 0.0 * RADIAL_COLOR_OFFSET);
    int inner_lines_color = getComponentColor(baseCyclePosition, 1.0 * RADIAL_COLOR_OFFSET);
    int outer_lines_color = getComponentColor(baseCyclePosition, 2.0 * RADIAL_COLOR_OFFSET);
    int outer_circles_color = getComponentColor(baseCyclePosition, 3.0 * RADIAL_COLOR_OFFSET);

    // --- Metatron's Cube Geometry ---
    float circleRadius = radius / 2; 
    
    PVector[] points = new PVector[13];
    points[0] = new PVector(0, 0); // P0: Center point

    // P1-P6: Centers of the 6 circles immediately surrounding the center
    for (int i = 0; i < 6; i++) {
      float angle = i * TWO_PI / 6.0;
      points[i+1] = PVector.fromAngle(angle).mult(circleRadius * 2); 
    }
    
    // P7-P12: Centers of the 6 outer circles that complete the pattern
    for (int i = 0; i < 6; i++) {
      float angle = (i * TWO_PI / 6.0) + (PI / 6.0); 
      points[i+7] = PVector.fromAngle(angle).mult(circleRadius * sqrt(3) * 2); 
    }

    // --- Drawing Elements with their assigned colors ---
    noFill();
    strokeWeight(LINE_STROKE_WEIGHT); 

    // 1. Inner Circle (P0) - Color Pulse Start
    stroke(inner_circle_color);
    ellipse(points[0].x, points[0].y, circleRadius * 2, circleRadius * 2); 

    // 2. Inner Lines (connecting P0 to P1-P12)
    stroke(inner_lines_color);
    for (int i = 1; i < 13; i++) {
      line(points[0].x, points[0].y, points[i].x, points[i].y);
    }
    
    // 3. Outer Circles (P1-P6 and P7-P12)
    stroke(outer_circles_color);
    for (int i = 1; i < 13; i++) { // Draw all 12 peripheral circles
      ellipse(points[i].x, points[i].y, circleRadius * 2, circleRadius * 2); 
    }

    // 4. Outer Lines (connecting P1-P12 to each other)
    stroke(outer_lines_color);
    for (int i = 1; i < 13; i++) {
      for (int j = i + 1; j < 13; j++) {
        line(points[i].x, points[i].y, points[j].x, points[j].y);
      }
    }

    popMatrix();
  }
}
