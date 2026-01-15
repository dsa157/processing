/*
 * VERSION: 2025.11.25.22.39.00
 * TITLE: The Impressionist Field
 * DESCRIPTION: 
 * A flow field visualization that uses oriented rectangles to mimic 
 * thick oil paint brushstrokes. It builds texture over time through 
 * layering and alpha blending.
 */

// =============================================================================
// CONFIGURATION PARAMETERS
// =============================================================================

// Canvas Dimensions
int SKETCH_WIDTH = 480;
int SKETCH_HEIGHT = 800;

// General Settings
int GLOBAL_SEED = 98234;     // Seed for random() and noise() to ensure reproducibility
int MAX_FRAMES = 900;        // Total frames to capture if saving (default 900)
boolean SAVE_FRAMES = false; // Set to true to save TIF images and stop at MAX_FRAMES
int ANIMATION_SPEED = 60;    // Frame rate (default 30)

// Layout
int PADDING = 40;            // Padding around the sketch (default 40)

// Visuals & Color
boolean INVERT_BG = false;   // Toggle to invert background/foreground relationship
int BG_COLOR_INDEX = 0;      // Index from palette to use as background (usually 0)

// Adobe Kuler Palette: "Impressionist Garden"
// Deep Blue, Teal, Soft Green, Goldenrod, Cream
String[] HEX_PALETTE = {
  "#022831", // Dark Blue (Default BG)
  "#144D53", // Teal
  "#87A878", // Sage Green
  "#EAC435", // Goldenrod
  "#F4F4F9"  // Off-white/Cream
};

// Flow Field & Noise
float NOISE_SCALE = 0.005;   // Zoom level of the noise (lower is smoother) (default 0.005)
float NOISE_Z_STEP = 0.002;  // Speed of field evolution over time (default 0.002)
float FLOW_FORCE = 1.5;      // How strictly particles follow the flow (default 1.5)

// Brush/Particle Settings
int NUM_PARTICLES = 1200;    // Number of active brushes (default 1200)
float BRUSH_MIN_LEN = 8;     // Minimum length of dash (default 8)
float BRUSH_MAX_LEN = 25;    // Maximum length of dash (default 25)
float BRUSH_WIDTH = 4;       // Thickness of the dash (default 4)
float BRUSH_ALPHA = 40;      // Opacity of strokes (0-255) (default 40)
float MAX_SPEED = 2.0;       // Movement speed of brushes (default 2.0)

// Debug
boolean SHOW_GRID = false;   // Show the underlying flow grid (default false)
int GRID_RES = 20;           // Resolution of grid for debug view (default 20)

// =============================================================================
// GLOBAL VARIABLES
// =============================================================================

Particle[] particles;
int[] palette;
float zOff = 0; // Time dimension for noise

// =============================================================================
// SETUP & SETTINGS
// =============================================================================

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  frameRate(ANIMATION_SPEED);
  
  // Initialize Seeds
  randomSeed(GLOBAL_SEED);
  noiseSeed(GLOBAL_SEED);
  
  // Process Palette
  palette = new int[HEX_PALETTE.length];
  for (int i = 0; i < HEX_PALETTE.length; i++) {
    palette[i] = unhex("FF" + HEX_PALETTE[i].substring(1));
  }
  
  // Background Setup
  int bgColor = INVERT_BG ? palette[palette.length - 1] : palette[BG_COLOR_INDEX];
  background(bgColor);
  
  // Initialize Particles
  particles = new Particle[NUM_PARTICLES];
  for (int i = 0; i < particles.length; i++) {
    particles[i] = new Particle();
  }
  
  // Drawing Attributes
  noStroke();
  rectMode(CENTER);
}

// =============================================================================
// DRAW LOOP
// =============================================================================

void draw() {
  // If showing grid, we need to refresh background to animate arrows
  if (SHOW_GRID) {
    int bgColor = INVERT_BG ? palette[palette.length - 1] : palette[BG_COLOR_INDEX];
    background(bgColor);
    drawDebugGrid();
  }

  // Update and display particles
  for (Particle p : particles) {
    p.follow();
    p.update();
    p.display();
    p.checkEdges();
  }
  
  // Evolve noise field slightly
  zOff += NOISE_Z_STEP;

  // Frame Saving & Stopping Logic
  // Only stop if we are actively saving frames to avoid filling disk space
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    
    if (frameCount >= MAX_FRAMES) {
      println("Finished saving " + MAX_FRAMES + " frames.");
      noLoop();
    }
  }
}

// =============================================================================
// HELPER FUNCTIONS
// =============================================================================

void drawDebugGrid() {
  stroke(255, 100);
  strokeWeight(1);
  for (int x = PADDING; x < width - PADDING; x += GRID_RES) {
    for (int y = PADDING; y < height - PADDING; y += GRID_RES) {
      float angle = noise(x * NOISE_SCALE, y * NOISE_SCALE, zOff) * TWO_PI * 2;
      PVector v = PVector.fromAngle(angle);
      pushMatrix();
      translate(x, y);
      rotate(v.heading());
      line(0, 0, GRID_RES/2, 0);
      popMatrix();
    }
  }
  noStroke(); // Reset for particles
}

// =============================================================================
// PARTICLE CLASS
// =============================================================================

class Particle {
  PVector pos;
  PVector vel;
  PVector acc;
  float maxSpeed;
  int paintColor;
  float brushLen;
  
  Particle() {
    // Spawn randomly within the padded area
    pos = new PVector(random(PADDING, width - PADDING), random(PADDING, height - PADDING));
    vel = new PVector(0, 0);
    acc = new PVector(0, 0);
    maxSpeed = MAX_SPEED;
    pickAttributes();
  }
  
  void pickAttributes() {
    // Pick a random color from palette, excluding the BG color if needed
    int idx = int(random(INVERT_BG ? 0 : 1, INVERT_BG ? palette.length - 1 : palette.length));
    paintColor = palette[idx];
    
    // Vary brush length slightly per particle for natural look
    brushLen = random(BRUSH_MIN_LEN, BRUSH_MAX_LEN);
  }

  void follow() {
    // Calculate angle based on Perlin noise
    // Multiplying TWO_PI by 2 or 4 creates more loops/swirls
    float angle = noise(pos.x * NOISE_SCALE, pos.y * NOISE_SCALE, zOff) * TWO_PI * 2;
    PVector force = PVector.fromAngle(angle);
    force.setMag(FLOW_FORCE);
    applyForce(force);
  }

  void applyForce(PVector force) {
    acc.add(force);
  }

  void update() {
    vel.add(acc);
    vel.limit(maxSpeed);
    pos.add(vel);
    acc.mult(0); // Reset acceleration
  }

  void display() {
    // Don't draw if purely debugging grid
    if (SHOW_GRID) return; 
    
    pushMatrix();
    translate(pos.x, pos.y);
    rotate(vel.heading());
    
    // Color Jitter
    // We switch to HSB temporarily to jitter the color for painterly effect
    colorMode(HSB, 360, 100, 100);
    float h = hue(paintColor);
    float s = saturation(paintColor);
    float b = brightness(paintColor);
    
    // Subtle variation
    h += random(-5, 5); 
    b += random(-5, 10);
    
    fill(h, s, b, BRUSH_ALPHA);
    
    // Draw the "dash"
    rect(0, 0, brushLen, BRUSH_WIDTH);
    
    // Restore Color Mode
    colorMode(RGB, 255);
    popMatrix();
  }

  void checkEdges() {
    // If particle leaves the padded area, respawn it randomly inside
    // This maintains the "Frame" effect and prevents wasted processing
    if (pos.x < PADDING || pos.x > width - PADDING || 
        pos.y < PADDING || pos.y > height - PADDING) {
      
      pos.x = random(PADDING, width - PADDING);
      pos.y = random(PADDING, height - PADDING);
      
      // Reset velocity to prevent streaks jumping across screen
      vel.mult(0);
      
      // Pick new attributes for variety
      pickAttributes();
    }
  }
}
