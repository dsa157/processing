/**
 * Version: 2025.11.25.11.05.00
 * Name: Chromatic Currents
 * * Concept: Perlin noise flow field where vector angles drive particle color (HSB).
 */

// ============================================================================
// CONFIGURATION PARAMETERS
// ============================================================================

// Canvas Dimensions
int SKETCH_WIDTH = 480;   // Default: 480
int SKETCH_HEIGHT = 800;  // Default: 800

// Animation Control
int GLOBAL_SEED = 112233; // Seed for random() and noise() uniformity
int MAX_FRAMES = 900;     // Default: 900
boolean SAVE_FRAMES = false; // Default: false
int ANIMATION_SPEED = 30; // Default: 30

// Layout
int PADDING = 0;         // Default: 40. White space around the sketch
boolean SHOW_GRID = false; // Default: false. Debug view of flow vectors

// Physics & Noise
float NOISE_SCALE = 0.06; // Default: 0.003. Lower = zoomed in/smoother
float NOISE_Z_STEP = 0.02; // Default: 0.002. Speed of flow field evolution
int GRID_RESOLUTION = 80;  // Default: 20. Size of flow field cells
int PARTICLE_COUNT = 1000; // Default: 2000. Number of agents
float MAX_SPEED = 2.0;     // Default: 2.0. Particle speed
float PARTICLE_ALPHA = 45; // Default: 15 (0-100 scale). Trail opacity

// Color Palette (Adobe Kuler inspired: "Deep Currents")
// Format: 0:Background, 1-4: Accents (if needed, though Logic uses Hue mapping)
String[] HEX_PALETTE = {
  "#0D1B2A", // Dark Blue (Deep Background)
  "#1B263B", // Navy
  "#415A77", // Slate
  "#778DA9", // Grey Blue
  "#E0E1DD"  // Off White
};

boolean INVERT_BACKGROUND = false; // Default: false

// ============================================================================
// GLOBAL VARIABLES
// ============================================================================

PVector[] flowField;
int cols, rows;
ArrayList<Particle> particles;
float zOff = 0; // 3rd dimension for noise evolution
int bgColor;

// ============================================================================
// SETUP
// ============================================================================

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  frameRate(ANIMATION_SPEED);
  randomSeed(GLOBAL_SEED);
  noiseSeed(GLOBAL_SEED);
  
  // Color Mode: Hue (0-360), Saturation (0-100), Brightness (0-100), Alpha (0-100)
  colorMode(HSB, 360, 100, 100, 100);
  
  // Set Background Color based on palette and inversion preference
  int paletteIndex = 0; 
  int c = unhex(HEX_PALETTE[paletteIndex].substring(1));
  
  if (INVERT_BACKGROUND) {
    bgColor = color(0, 0, 100); // White
  } else {
    // Convert hex RGB to current HSB context
    float r = (c >> 16) & 0xFF;
    float g = (c >> 8) & 0xFF;
    float b = c & 0xFF;
    // Simple conversion logic or just re-pick color. 
    // Here we stick to the hex value directly interpreted.
    bgColor = c; // Processing handles this int as color
  }
  
  background(bgColor);
  
  // Initialize Grid
  // We calculate rows/cols based on the INNER drawing area (inside padding)
  int drawWidth = width - (PADDING * 2);
  int drawHeight = height - (PADDING * 2);
  cols = floor(drawWidth / GRID_RESOLUTION);
  rows = floor(drawHeight / GRID_RESOLUTION);
  flowField = new PVector[cols * rows];
  
  // Initialize Particles
  particles = new ArrayList<Particle>();
  for (int i = 0; i < PARTICLE_COUNT; i++) {
    particles.add(new Particle());
  }
}

// ============================================================================
// DRAW
// ============================================================================

void draw() {
  // Translate to center/padded area
  translate(PADDING, PADDING);
  
  // 1. Calculate Flow Field
  float xOff = 0;
  for (int i = 0; i < cols; i++) {
    float yOff = 0;
    for (int j = 0; j < rows; j++) {
      // 3D Noise (x, y, time)
      float theta = map(noise(xOff, yOff, zOff), 0, 1, 0, TWO_PI * 2);
      PVector v = PVector.fromAngle(theta);
      int index = i + j * cols;
      flowField[index] = v;
      
      // Visualize Grid (Optional Debug)
      if (SHOW_GRID) {
        pushStyle();
        stroke(0, 0, 50, 30);
        strokeWeight(1);
        pushMatrix();
        translate(i * GRID_RESOLUTION, j * GRID_RESOLUTION);
        rotate(v.heading());
        line(0, 0, GRID_RESOLUTION/2, 0);
        popMatrix();
        popStyle();
      }
      
      yOff += NOISE_SCALE * GRID_RESOLUTION; // Adjust scale by resolution to keep consistency
    }
    xOff += NOISE_SCALE * GRID_RESOLUTION;
  }
  zOff += NOISE_Z_STEP;
  
  // 2. Update and Draw Particles
  for (Particle p : particles) {
    p.follow(flowField);
    p.update();
    p.show();
    p.edges();
  }
  
  // 3. Draw Border (Clean up edges)
  // We draw a "frame" over the edges to hide particles wrapping or entering padding
  resetMatrix(); // Go back to 0,0
  
  noFill();
  stroke(bgColor);
  strokeWeight(PADDING * 2); // Double width because stroke centers on line
  rect(0, 0, width, height); // Covers everything outside? No, this is messy.
  
  // Cleaner framing method: Draw 4 rects
  fill(bgColor);
  noStroke();
  rect(0, 0, width, PADDING); // Top
  rect(0, height - PADDING, width, PADDING); // Bottom
  rect(0, 0, PADDING, height); // Left
  rect(width - PADDING, 0, PADDING, height); // Right
  
  // Inner Border Stroke
  noFill();
  if (INVERT_BACKGROUND) stroke(0); else stroke(255);
  strokeWeight(1);
  rect(PADDING, PADDING, width - PADDING*2, height - PADDING*2);

  // 4. Save & Exit Logic
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
  }
  
  if (frameCount >= MAX_FRAMES) {
    println("Max frames reached. Stopping.");
    noLoop();
  }
}

// ============================================================================
// CLASSES
// ============================================================================

class Particle {
  PVector pos;
  PVector vel;
  PVector acc;
  PVector prevPos;
  
  Particle() {
    // Spawn random start position within the PADDED area
    float w = width - (PADDING * 2);
    float h = height - (PADDING * 2);
    pos = new PVector(random(w), random(h));
    prevPos = pos.copy();
    vel = new PVector(0, 0);
    acc = new PVector(0, 0);
  }
  
  void update() {
    vel.add(acc);
    vel.limit(MAX_SPEED);
    pos.add(vel);
    acc.mult(0); // Reset acceleration
  }
  
  void follow(PVector[] vectors) {
    // Map position to grid index
    int x = floor(pos.x / GRID_RESOLUTION);
    int y = floor(pos.y / GRID_RESOLUTION);
    
    // Safety clamp to prevent ArrayOutOfBounds
    x = constrain(x, 0, cols - 1);
    y = constrain(y, 0, rows - 1);
    
    int index = x + y * cols;
    PVector force = vectors[index];
    applyForce(force);
  }
  
  void applyForce(PVector force) {
    acc.add(force);
  }
  
  void show() {
    // Calculate color based on Heading (Direction)
    // Heading ranges from -PI to PI
    float angle = vel.heading(); 
    // Map angle to Hue (0-360)
    float hueVal = map(angle, -PI, PI, 0, 360);
    
    // Saturation and Brightness high for vibrance
    stroke(hueVal, 80, 90, PARTICLE_ALPHA);
    strokeWeight(1.5);
    
    // Draw line from previous position to current to create smooth ribbon
    line(prevPos.x, prevPos.y, pos.x, pos.y);
    
    updatePrev();
  }
  
  void updatePrev() {
    prevPos.x = pos.x;
    prevPos.y = pos.y;
  }
  
  void edges() {
    // Wrap around logic relative to PADDED area
    float w = width - (PADDING * 2);
    float h = height - (PADDING * 2);
    
    boolean wrapped = false;
    
    if (pos.x > w) { pos.x = 0; wrapped = true; }
    if (pos.x < 0) { pos.x = w; wrapped = true; }
    if (pos.y > h) { pos.y = 0; wrapped = true; }
    if (pos.y < 0) { pos.y = h; wrapped = true; }
    
    if (wrapped) updatePrev(); // Prevent drawing a line across the canvas on wrap
  }
}
