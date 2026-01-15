/**
 * Quantized Circuitry Flow Field
 * Version: 2025.11.25.18.35.00
 * * Concept: 
 * Particles move through a flow field derived from Perlin noise, but flow vectors 
 * are quantized to specific angles (0, 45, 90, 135, etc.). This creates rigid, 
 * staccato movement rather than fluid curves.
 *
 * Controls:
 * - Modify parameters in the Configuration section below.
 */

// =============================================================================
// CONFIGURATION
// =============================================================================

// Canvas & Layout
int SKETCH_WIDTH = 480;       // Default: 480
int SKETCH_HEIGHT = 800;      // Default: 800
int PADDING = 10;             // Default: 40 - Padding around the active area
boolean CENTER_SKETCH = true; // Default: true - Centers the active area

// Animation & output
long SEED = 4242;             // Default: 4242 - Global seed for reproducibility
int MAX_FRAMES = 900;         // Default: 900
boolean SAVE_FRAMES = false;  // Default: false
int ANIM_SPEED = 30;          // Default: 30

// Physics & Grid
float NOISE_SCALE = 5;    // Default: 0.005 - Zoom level of noise
int GRID_RESOLUTION = 5;     // Default: 10 - Size of flow field cells
boolean SHOW_GRID = false;    // Default: false - Toggle debug grid lines
float FORCE_STRENGTH = 1;     // Default: 1 - How fast particles turn

// Quantization (The "Circuitry" Effect)
// PI/2 = 90 degrees (Orthogonal only), PI/4 = 45 degrees (Octagonal)
float ANGLE_SNAP = PI / 4.0;  // Default: PI / 2.0

// Particles
int PARTICLE_COUNT = 1000;     // Default: 800
float PARTICLE_SPEED = 1.0;   // Default: 2.0
int MAX_LIFE = 200;           // Default: 200 - Frames before a particle respawns
float STROKE_WEIGHT = 1.5;    // Default: 1.5
float ALPHA_VAL = 180;        // Default: 180 - Transparency (0-255)
boolean DRAW_NODES = true;    // Default: true - Draw a dot when particle dies (circuit node)

// Color Palette (Adobe Kuler style - Tech/Neon)
// 0: Background, 1-4: Foreground colors
String[] HEX_PALETTE = {
  "#101419", // Dark Gunmetal (Background)
  "#04E762", // Neon Green
  "#F5B700", // Signal Orange
  "#00A1E4", // Cyan Process
  "#DC0073"  // Vivid Raspberry
};

boolean INVERT_BG = true;    // Default: false - Swaps index 0 with index 4

// =============================================================================
// GLOBAL VARIABLES
// =============================================================================

PVector[] flowField;
ArrayList<Particle> particles;
int cols, rows;
color[] palette;
color bgColor;
int activeWidth, activeHeight;

// =============================================================================
// MAIN SETUP & DRAW
// =============================================================================

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  frameRate(ANIM_SPEED);
  
  // Initialize Random Seeds
  randomSeed(SEED);
  noiseSeed(SEED);
  
  // Process Palette
  palette = new color[HEX_PALETTE.length];
  for (int i = 0; i < HEX_PALETTE.length; i++) {
    palette[i] = unhex("FF" + HEX_PALETTE[i].substring(1));
  }
  
  // Handle Background Inversion
  if (INVERT_BG) {
    bgColor = palette[palette.length - 1]; // Use last color as BG
    // Shuffle the array slightly or just pick from the remaining
  } else {
    bgColor = palette[0];
  }
  
  background(bgColor);
  
  // Calculate Layout
  activeWidth = width - (PADDING * 2);
  activeHeight = height - (PADDING * 2);
  
  cols = floor(activeWidth / GRID_RESOLUTION);
  rows = floor(activeHeight / GRID_RESOLUTION);
  
  // Initialize Flow Field
  initFlowField();
  
  // Initialize Particles
  particles = new ArrayList<Particle>();
  for (int i = 0; i < PARTICLE_COUNT; i++) {
    particles.add(new Particle());
  }
  
  // Draw Grid if requested (only once)
  if (SHOW_GRID) {
    drawDebugGrid();
  }
}

void draw() {
  // Translate to padded area center
  pushMatrix();
  if (CENTER_SKETCH) {
    translate(PADDING, PADDING);
  }
  
  // Update and Draw Particles
  for (Particle p : particles) {
    p.follow();
    p.update();
    p.show();
  }
  
  popMatrix();
  
  // Save Frame Logic
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
  }
  
  // Termination Logic
  if (frameCount >= MAX_FRAMES) {
    println("Max frames reached: " + MAX_FRAMES);
    noLoop();
  }
}

// =============================================================================
// FLOW FIELD LOGIC
// =============================================================================

void initFlowField() {
  flowField = new PVector[cols * rows];
  
  float xoff = 0;
  for (int i = 0; i < cols; i++) {
    float yoff = 0;
    for (int j = 0; j < rows; j++) {
      int index = i + j * cols;
      
      // Get raw Perlin noise (0.0 to 1.0)
      float theta = noise(xoff, yoff) * TWO_PI * 2; // Multiply by 2 for more variance
      
      // QUANTIZATION: Snap the angle to the nearest ANGLE_SNAP increment
      // This is the core of the "Circuitry" look
      float quantizedAngle = floor(theta / ANGLE_SNAP) * ANGLE_SNAP;
      
      PVector v = PVector.fromAngle(quantizedAngle);
      v.setMag(FORCE_STRENGTH);
      flowField[index] = v;
      
      yoff += NOISE_SCALE;
    }
    xoff += NOISE_SCALE;
  }
}

void drawDebugGrid() {
  pushMatrix();
  translate(PADDING, PADDING);
  stroke(255, 30);
  strokeWeight(0.5);
  noFill();
  
  for (int i = 0; i < cols; i++) {
    for (int j = 0; j < rows; j++) {
      rect(i * GRID_RESOLUTION, j * GRID_RESOLUTION, GRID_RESOLUTION, GRID_RESOLUTION);
      
      int index = i + j * cols;
      PVector v = flowField[index];
      
      pushMatrix();
      translate(i * GRID_RESOLUTION + GRID_RESOLUTION/2, j * GRID_RESOLUTION + GRID_RESOLUTION/2);
      rotate(v.heading());
      line(0, 0, GRID_RESOLUTION/2, 0);
      popMatrix();
    }
  }
  popMatrix();
}

// =============================================================================
// PARTICLE CLASS
// =============================================================================

class Particle {
  PVector pos;
  PVector prevPos;
  PVector vel;
  PVector acc;
  int colIndex;
  color pColor;
  float life;
  float maxLife;
  boolean dead;

  Particle() {
    respawn();
    // Start with random life offset so they don't all die at once
    life = random(0, maxLife); 
  }

  void respawn() {
    // Spawn anywhere within active grid
    pos = new PVector(random(activeWidth), random(activeHeight));
    
    // Snap spawn position to grid for cleaner lines?
    // Optional: pos.x = floor(pos.x / GRID_RESOLUTION) * GRID_RESOLUTION;
    // Optional: pos.y = floor(pos.y / GRID_RESOLUTION) * GRID_RESOLUTION;
    
    prevPos = pos.copy();
    vel = new PVector(0, 0);
    acc = new PVector(0, 0);
    
    // Pick a color from palette (excluding BG)
    // If INVERT_BG is true, we avoid the last index, else avoid 0
    int minIdx = INVERT_BG ? 0 : 1;
    int maxIdx = INVERT_BG ? palette.length - 2 : palette.length - 1;
    
    // Clamp
    if (minIdx > maxIdx) minIdx = maxIdx; 
    
    colIndex = floor(random(minIdx, maxIdx + 1));
    pColor = palette[colIndex];
    
    maxLife = random(MAX_LIFE * 0.5, MAX_LIFE);
    life = maxLife;
    dead = false;
  }

  void follow() {
    // Map position to grid index
    int x = floor(pos.x / GRID_RESOLUTION);
    int y = floor(pos.y / GRID_RESOLUTION);
    int index = x + y * cols;
    
    // Safety check for bounds
    if (index >= 0 && index < flowField.length && x >= 0 && x < cols && y >= 0 && y < rows) {
      PVector force = flowField[index];
      applyForce(force);
    }
  }

  void applyForce(PVector force) {
    acc.add(force);
  }

  void update() {
    if (dead) return;

    vel.add(acc);
    vel.limit(PARTICLE_SPEED);
    
    // Constrain velocity to snap angles strictly? 
    // The flow field is snapped, but momentum might curve it.
    // For strict circuitry, we rely on the flow field driving the direction.
    
    pos.add(vel);
    acc.mult(0);
    
    life--;

    // Boundary checks & Life check
    if (pos.x < 0 || pos.x > activeWidth || pos.y < 0 || pos.y > activeHeight || life <= 0) {
      if (DRAW_NODES && life <= 0) {
        drawNode();
      }
      respawn();
      // Reset previous pos to new pos so we don't draw a streak across screen
      prevPos = pos.copy(); 
    }
  }
  
  void drawNode() {
     noStroke();
     fill(pColor, ALPHA_VAL + 50); // Slightly brighter/solid for node
     float nodeSize = STROKE_WEIGHT * 3;
     circle(pos.x, pos.y, nodeSize);
     
     // Optional: Small hollow ring around node for "Tech" feel
     noFill();
     stroke(pColor, ALPHA_VAL);
     strokeWeight(0.5);
     circle(pos.x, pos.y, nodeSize * 2.5);
  }

  void show() {
    if (dead) return;
    
    // Draw line
    stroke(pColor, ALPHA_VAL);
    strokeWeight(STROKE_WEIGHT);
    // Use SQUARE cap for digital look
    strokeCap(SQUARE); 
    line(prevPos.x, prevPos.y, pos.x, pos.y);
    
    updatePrev();
  }

  void updatePrev() {
    prevPos.x = pos.x;
    prevPos.y = pos.y;
  }
}
