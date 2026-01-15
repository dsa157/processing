/*
  Version: 2025.11.25.22.05.00
  Title: Calligraphic Ribbons Flow Field
  Concept: Particles map velocity magnitude to inverse stroke weight.
*/

// =============================================================================
// PARAMETERS (Edit these values to change the sketch behavior)
// =============================================================================

// -- Canvas & System --
int SKETCH_WIDTH = 480;       // Width of the canvas
int SKETCH_HEIGHT = 800;      // Height of the canvas
int RANDOM_SEED = 9999;       // Global seed for reproducible results (default: 9999)
int MAX_FRAMES = 900;         // Stop after this many frames (default: 900)
boolean SAVE_FRAMES = false;  // Set to true to save TIF sequence (default: false)
int ANIMATION_SPEED = 30;     // Frames per second (default: 30)

// -- Layout --
int PADDING = 20;             // Padding around the sketch area (default: 40)
boolean SHOW_GRID = false;    // Draw the underlying flow vectors for debug (default: false)
float GRID_RES = 20.0;        // Resolution of the noise grid (default: 20.0)

// -- Physics & Noise --
int NUM_PARTICLES = 500;     // Number of ribbons (default: 1500)
float NOISE_SCALE = 0.08;    // Zoom level of Perlin noise (default: 0.005)
float NOISE_STRENGTH = 2.0;   // Force multiplier for noise vectors (default: 2.0)
float FRICTION = 1.45;        // Speed decay (default: 0.96)
float MAX_SPEED = 1.85;        // Speed cap (default: 4.0)
float FORCE_MAG = 3.7;        // Magnitude of steering force (default: 0.5)

// -- Visuals --
float MAX_STROKE_W = 20.0;     // Thickness when slow (default: 4.5)
float MIN_STROKE_W = 0.8;     // Thickness when fast (default: 0.5)
float LINE_ALPHA = 200.0;      // Transparency of ribbons 0-255 (default: 40.0)
boolean INVERT_BG = false;    // Toggle to invert background/text colors (default: false)

// -- Palette (Hex Strings) --
// Inspired by "Japanese Ink" style: Deep Slate, Off-White, Vermilion, Gold, Teal
String[] PALETTE_HEX = {
  "#1A1A1D", // 0: Deep Black/Slate
  "#F7F7F2", // 1: Rice Paper White
  "#C3073F", // 2: Crimson
  "#D4AF37", // 3: Gold
  "#4E4E50"  // 4: Medium Grey
};

// Which palette index to use for background?
int BG_COLOR_INDEX = 1; // Default: 1 (White). Change to 0 for Dark mode.

// =============================================================================
// GLOBAL VARIABLES
// =============================================================================

Particle[] particles;
int[] paletteColors;
int bgColor;

// =============================================================================
// SETUP & SETTINGS
// =============================================================================

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  frameRate(ANIMATION_SPEED);
  randomSeed(RANDOM_SEED);
  noiseSeed(RANDOM_SEED);
  
  // Initialize Palette
  initPalette();
  
  // Set Background
  if (INVERT_BG) {
    // Simple inversion logic: If index is 1 (light), pick 0 (dark), else pick 1.
    // Or mathematically invert the color value. Let's swap the picked BG.
    bgColor = (BG_COLOR_INDEX == 0) ? paletteColors[1] : paletteColors[0];
  } else {
    bgColor = paletteColors[BG_COLOR_INDEX];
  }
  
  background(bgColor);
  
  // Initialize Particles
  particles = new Particle[NUM_PARTICLES];
  for (int i = 0; i < particles.length; i++) {
    particles[i] = new Particle();
  }
}

// =============================================================================
// DRAW LOOP
// =============================================================================

void draw() {
  
  // If showing grid, we must clear background every frame to animate vectors
  if (SHOW_GRID) {
    background(bgColor);
    drawFlowGrid();
  } else {
    // In Art mode, we do NOT clear background to allow ribbons to overlap/trail
  }

  // Draw Particles
  // Translate to center to account for padding logic visually if desired,
  // but here we keep coordinate system absolute and handle padding in class.
  
  for (Particle p : particles) {
    p.followField();
    p.update();
    p.display();
    p.checkEdges();
  }

  // Save Frames Logic
  if (SAVE_FRAMES) {
    saveFrame("frames/line_####.tif");
  }

  // Stop Logic
  if (frameCount >= MAX_FRAMES) {
    println("Max frames reached. Rendering finished.");
    noLoop();
  }
}

// =============================================================================
// HELPER FUNCTIONS
// =============================================================================

void initPalette() {
  paletteColors = new int[PALETTE_HEX.length];
  for (int i = 0; i < PALETTE_HEX.length; i++) {
    // Convert hex string to color integer
    paletteColors[i] = unhex("FF" + PALETTE_HEX[i].substring(1)); 
  }
}

int getRandomColor() {
  // Pick a random color from palette, excluding the background color index roughly
  int idx = int(random(paletteColors.length));
  // Optional: Ensure particle isn't exact same color as background
  // For now, pure random allows for nice subtle textures
  return paletteColors[idx];
}

void drawFlowGrid() {
  stroke(128, 100);
  strokeWeight(1);
  for (int x = PADDING; x < width - PADDING; x += GRID_RES) {
    for (int y = PADDING; y < height - PADDING; y += GRID_RES) {
      float angle = noise(x * NOISE_SCALE, y * NOISE_SCALE) * TWO_PI * 4;
      PVector v = PVector.fromAngle(angle);
      pushMatrix();
      translate(x, y);
      rotate(v.heading());
      line(0, 0, GRID_RES * 0.8, 0);
      popMatrix();
    }
  }
}

// =============================================================================
// PARTICLE CLASS
// =============================================================================

class Particle {
  PVector pos;
  PVector prevPos;
  PVector vel;
  PVector acc;
  int pColor;
  float noiseZ; // Unique Z offset for slightly different noise per particle (optional)
  
  Particle() {
    respawn(true);
    noiseZ = random(100); 
  }
  
  void respawn(boolean randomStart) {
    // Spawn within the padded area
    float w = width - PADDING * 2;
    float h = height - PADDING * 2;
    
    if (randomStart) {
      pos = new PVector(PADDING + random(w), PADDING + random(h));
    } else {
      // Logic to spawn at edges based on flow could go here
      pos = new PVector(PADDING + random(w), PADDING + random(h));
    }
    
    prevPos = pos.copy();
    vel = new PVector(0, 0);
    acc = new PVector(0, 0);
    pColor = getRandomColor();
  }
  
  void followField() {
    // Calculate noise based on position
    // We multiply angle to create more loops/curls
    float angle = noise(pos.x * NOISE_SCALE, pos.y * NOISE_SCALE) * TWO_PI * 4;
    
    PVector force = PVector.fromAngle(angle);
    force.mult(FORCE_MAG); // Strength of the turning force
    
    // Add steering force to acceleration
    acc.add(force);
  }
  
  void update() {
    vel.add(acc);
    vel.limit(MAX_SPEED);
    
    // Save current position for drawing line
    prevPos.set(pos);
    
    pos.add(vel);
    
    // Friction/Drag (keeps movements organic)
    vel.mult(FRICTION);
    
    // Reset acceleration
    acc.mult(0);
  }
  
  void display() {
    if (SHOW_GRID) return; // Don't draw particles in grid debug mode
    
    // --- Calligraphic Logic ---
    // Calculate current speed
    float speed = vel.mag();
    
    // Map speed to stroke weight: Faster = Thinner
    // Using max/min speed as approximate bounds
    float weight = map(speed, 0, MAX_SPEED, MAX_STROKE_W, MIN_STROKE_W);
    weight = constrain(weight, MIN_STROKE_W, MAX_STROKE_W);
    
    strokeWeight(weight);
    stroke(pColor, LINE_ALPHA);
    
    // Using line() creates a fast "ribbon" effect over time. 
    // Since alpha is low, overlapping strokes create depth.
    line(prevPos.x, prevPos.y, pos.x, pos.y);
  }
  
  void checkEdges() {
    // Define bounds based on PADDING
    float minX = PADDING;
    float maxX = width - PADDING;
    float minY = PADDING;
    float maxY = height - PADDING;
    
    // If particle leaves the padded area, respawn it randomly inside
    // giving a nice sharp edge to the drawing field
    if (pos.x < minX || pos.x > maxX || pos.y < minY || pos.y > maxY) {
      respawn(true);
      // To prevent a straight line drawn across screen on respawn:
      prevPos.set(pos); 
    }
  }
}
