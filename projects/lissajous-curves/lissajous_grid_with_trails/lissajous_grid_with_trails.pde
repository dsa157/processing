// Processing Grid: Fixed Lissajous Curves

// === Global Parameters ===
final int SEED = 12345;         // Global seed for random()
final int BASE_COLS = 5;        // Number of columns in the grid
final int BASE_ROWS = 8;        // Number of rows in the grid
final int PADDING = 40;         // Padding around the overall grid
final boolean INVERT_COLORS = false; // Invert background/foreground colors (controls BG color)
final boolean SHOW_GRID_LINES = false; // Display grid lines

color GRID_LINE_COLOR = #444444; 

final float GRID_STROKE_THICKNESS = 1.0;
final int MAX_FRAMES = 900;     // Maximum number of frames to run
final boolean SAVE_FRAMES = true; // Save frames to disk

// Lissajous & Particle Parameters
final float PARTICLE_SIZE = 10.0; // Size of the tracing particle
final float CURVE_WEIGHT = 1;   
final float SPEED_MULTIPLIER = 0.02; // Controls animation speed (time increment)
final int HUE_RANGE = 255;      // Range for HSL hue (0-255)

// === TRAIL PARAMETER ===
final int TRAIL_ALPHA = 10;     // Transparency of the background wash (0-255). Lower = longer trail.

// Lissajous Data Structure (to hold parameters for each cell)
class LissajousParams {
  float a; // X-frequency
  float b; // Y-frequency
  float phi; // Phase shift
  color curveColor;

  LissajousParams() {
    // Frequencies 'a' and 'b' (1 to 5)
    a = floor(random(1, 6));
    b = floor(random(1, 6));
    phi = random(TWO_PI); // Phase shift 0 to 2*PI
    
    // Random color
    curveColor = color(random(HUE_RANGE), 200, 200);
  }
}

// Dynamic/Calculated Variables
float cellW, cellH;             // Width and height of a grid cell
float gridX, gridY;             // Top-left corner of the grid
float gridW, gridH;             // Width and height of the grid
float t = 0;                    // Time variable for animation

LissajousParams[][] gridData;

void setup() {
  size(480, 800);
  randomSeed(SEED);
  // Set HSB color mode with a max alpha of 255 for the background wash
  colorMode(HSB, HUE_RANGE, 255, 255, 255);

  // Calculate Grid Dimensions
  gridW = width - 2 * PADDING;
  gridH = height - 2 * PADDING;
  gridX = PADDING;
  gridY = PADDING;

  cellW = gridW / BASE_COLS;
  cellH = gridH / BASE_ROWS;

  // Initialize Grid Data
  gridData = new LissajousParams[BASE_ROWS][BASE_COLS];
  for (int r = 0; r < BASE_ROWS; r++) {
    for (int c = 0; c < BASE_COLS; c++) {
      gridData[r][c] = new LissajousParams();
    }
  }

  // Set initial colors
  if (INVERT_COLORS) {
    background(HUE_RANGE); // White (max brightness)
    GRID_LINE_COLOR = color(0, 0, 0); // Black
  } else {
    background(0); // Black (min brightness)
    // GRID_LINE_COLOR is already set to #444444
  }
  
  frameRate(30);
}

void draw() {
  // === TRAIL EFFECT IMPLEMENTATION ===
  // Instead of background(color), use fill(color, alpha) and rect(0,0,width,height)
  // This draws a semi-transparent rectangle over the whole canvas,
  // causing previous frames to slowly fade out and creating a trail.
  if (INVERT_COLORS) {
    // White background wash
    noStroke();
    fill(HUE_RANGE, 0, 255, TRAIL_ALPHA); 
    rect(0, 0, width, height);
  } else {
    // Black background wash
    noStroke();
    fill(0, TRAIL_ALPHA); 
    rect(0, 0, width, height);
  }
  // ===================================

  // Draw the grid content and particle
  for (int r = 0; r < BASE_ROWS; r++) {
    for (int c = 0; c < BASE_COLS; c++) {
      float cellX = gridX + c * cellW;
      float cellY = gridY + r * cellH;
      LissajousParams params = gridData[r][c];

      // Draw Lissajous curve in the cell
      drawLissajous(cellX, cellY, cellW, cellH, params);
    }
  }

  // Draw Grid Lines (on top of content)
  if (SHOW_GRID_LINES) {
    strokeWeight(GRID_STROKE_THICKNESS);
    stroke(GRID_LINE_COLOR);
    noFill();

    // Outer boundary
    rect(gridX, gridY, gridW, gridH);

    // Main grid lines
    for (int i = 1; i < BASE_COLS; i++) {
      line(gridX + i * cellW, gridY, gridX + i * cellW, gridY + gridH);
    }
    for (int i = 1; i < BASE_ROWS; i++) {
      line(gridX, gridY + i * cellH, gridX + gridW, gridY + i * cellH);
    }
  }

  // Update time for animation
  t += SPEED_MULTIPLIER;

  // Frame saving and loop termination
  if (SAVE_FRAMES) {
    // The frame numbering is based on Processing's internal frameCount
    saveFrame("frames/####.tif"); 
    if (frameCount >= MAX_FRAMES) {
      noLoop();
    }
  } else if (frameCount >= MAX_FRAMES) {
    noLoop();
  }
}

/**
 * Draws a Lissajous curve and its tracing particle within a given bounding box.
 */
void drawLissajous(float x, float y, float w, float h, LissajousParams params) {
  // Center of the cell
  float centerX = x + w / 2;
  float centerY = y + h / 2;
  // Amplitude (half of the smallest dimension for full visibility)
  float xAmp = w * 0.45;
  float yAmp = h * 0.45;
  
  // === Draw the Curve Path (Now visible with full color opacity) ===
  noFill();
  stroke(params.curveColor); // Use the curve's color
  strokeWeight(CURVE_WEIGHT); // Uses global parameter
  beginShape();
  // Draw the full curve path over a period of 2*PI
  for (float theta = 0; theta <= TWO_PI; theta += 0.05) {
    float lx = xAmp * cos(params.a * theta);
    float ly = yAmp * sin(params.b * theta + params.phi);
    vertex(centerX + lx, centerY + ly);
  }
  endShape();
  
  // === Draw the Tracing Particle ===
  // Lissajous equations for the current time 't'
  float currentX = xAmp * cos(params.a * t);
  float currentY = yAmp * sin(params.b * t + params.phi);
  
  fill(params.curveColor);
  noStroke();
  ellipse(centerX + currentX, centerY + currentY, PARTICLE_SIZE, PARTICLE_SIZE);
}
