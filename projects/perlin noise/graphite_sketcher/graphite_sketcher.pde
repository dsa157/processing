/**
 * THE GRAPHITE SKETCHER
 * Version: 2025.11.25.21.58.45
 * Change Log: Implemented particle lifespans. Lines now start dark, fade individually, then respawn.
 */

// --- CONFIGURATION PARAMETERS ---

// Canvas & Output
int SKETCH_WIDTH = 480;       // Width of the window
int SKETCH_HEIGHT = 800;      // Height of the window
int SEED = 1024;              // Global random seed
int MAX_FRAMES = 900;         // Only stops execution if SAVE_FRAMES is true
boolean SAVE_FRAMES = false;  // Save tiff sequence
int ANIMATION_SPEED = 60;     // Frame rate

// Layout
int PADDING = 20;             // Whitespace around the sketch
boolean INVERT_BG = false;    // Flip background/foreground colors

// Visuals & Fading
float STROKE_WEIGHT = 1.0;    // Thickness of the pencil lines
int STROKE_ALPHA = 255;       // Max opacity at start of life (Higher now, as it decays)
int FADE_RATE = 20;            // (0-255) Global canvas fade (Paper absorbtion over time)

// Flow Field Physics
boolean SHOW_GRID = false;    // Debug: toggle to see the underlying vectors
float NOISE_SCALE = 0.05;    // Zoom level of the noise
int GRID_RESOLUTION = 20;     // Size of flow field cells

// Particles / "Graphite"
int NUM_PARTICLES = 1000;     // Number of drawing agents
float PARTICLE_SPEED = 4.0;   // How fast lines move
float MIN_DECAY = 1.0;        // Minimum life lost per frame
float MAX_DECAY = 10.0;        // Maximum life lost per frame

// Color Palette (Adobe Kuler: "Warm Graphite")
String[] HEX_PALETTE = {
  "F5F5F0", // 0: Off-White (Paper)
  "1A1A1A", // 1: Charcoal
  "404040", // 2: Slate
  "808080", // 3: Silver
  "BFA89E"  // 4: Warm Grey
};

// --- GLOBAL VARIABLES ---
PVector[] flowGrid;
int cols, rows;
ArrayList<Particle> particles;
int bgColor, inkColor;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  frameRate(ANIMATION_SPEED);
  
  // Initialize Seeding
  randomSeed(SEED);
  noiseSeed(SEED);
  
  // Calculate Grid Dimensions
  cols = width / GRID_RESOLUTION;
  rows = height / GRID_RESOLUTION;
  
  // Define Colors with Alpha correction (0xFF000000 mask)
  if (INVERT_BG) {
    bgColor = 0xFF000000 | unhex(HEX_PALETTE[1]); 
    inkColor = 0xFF000000 | unhex(HEX_PALETTE[0]);
  } else {
    bgColor = 0xFF000000 | unhex(HEX_PALETTE[0]); 
    inkColor = 0xFF000000 | unhex(HEX_PALETTE[1]);
  }
  
  // Setup Background & Paper Grain
  background(bgColor);
  generatePaperTexture();
  
  // Initialize Flow Field
  initFlowField();
  
  // Initialize Particles
  particles = new ArrayList<Particle>();
  for (int i = 0; i < NUM_PARTICLES; i++) {
    particles.add(new Particle());
  }
  
  // Initial Blend Mode Setup
  setDrawingBlendMode();
}

void draw() {
  // 1. FADE LAYER (Global history)
  // Slowly covers old generations with the background color
  blendMode(BLEND);
  noStroke();
  fill(bgColor, FADE_RATE);
  rect(0, 0, width, height);
  
  // 2. SWITCH BACK TO DRAWING MODE
  setDrawingBlendMode();

  // 3. DEBUG GRID
  if (SHOW_GRID) {
    blendMode(NORMAL);
    drawGrid();
    setDrawingBlendMode();
  }
  
  // 4. UPDATE PARTICLES
  strokeWeight(STROKE_WEIGHT);
  
  for (Particle p : particles) {
    p.follow(flowGrid);
    p.update();
    p.display();
    p.checkStatus(); // Checks edges AND lifespan
  }
  
  // 5. SAVE & LIMITS
  if (SAVE_FRAMES) {
    saveFrame("frames/line_####.tif");
    if (frameCount >= MAX_FRAMES) {
      println("Max frames reached. Sketch finished.");
      noLoop();
    }
  }
}

// --- HELPER FUNCTIONS ---

void setDrawingBlendMode() {
  if (INVERT_BG) {
    blendMode(ADD); // Light ink on Dark BG
  } else {
    blendMode(MULTIPLY); // Dark ink on Light BG
  }
}

void initFlowField() {
  flowGrid = new PVector[cols * rows];
  for (int y = 0; y < rows; y++) {
    for (int x = 0; x < cols; x++) {
      int index = x + y * cols;
      float angle = noise(x * NOISE_SCALE * GRID_RESOLUTION, y * NOISE_SCALE * GRID_RESOLUTION) * TWO_PI * 4;
      PVector v = PVector.fromAngle(angle);
      v.setMag(1); 
      flowGrid[index] = v;
    }
  }
}

void generatePaperTexture() {
  loadPixels();
  for (int i = 0; i < pixels.length; i++) {
    float grain = random(-5, 5);
    int c = pixels[i];
    float r = red(c) + grain;
    float g = green(c) + grain;
    float b = blue(c) + grain;
    pixels[i] = color(constrain(r, 0, 255), constrain(g, 0, 255), constrain(b, 0, 255));
  }
  updatePixels();
}

void drawGrid() {
  stroke(128, 50);
  strokeWeight(1);
  for (int y = 0; y < rows; y++) {
    for (int x = 0; x < cols; x++) {
      int index = x + y * cols;
      PVector v = flowGrid[index];
      
      pushMatrix();
      translate(x * GRID_RESOLUTION, y * GRID_RESOLUTION);
      rotate(v.heading());
      line(0, 0, GRID_RESOLUTION, 0);
      popMatrix();
    }
  }
}

// --- PARTICLE CLASS ---

class Particle {
  PVector pos;
  PVector vel;
  PVector acc;
  PVector prevPos;
  
  float lifespan;
  float decay;
  float maxLifespan = 255.0;
  
  Particle() {
    spawn();
    vel = new PVector(0, 0);
    acc = new PVector(0, 0);
  }
  
  void spawn() {
    pos = new PVector(random(PADDING, width - PADDING), random(PADDING, height - PADDING));
    prevPos = pos.copy();
    lifespan = maxLifespan;
    decay = random(MIN_DECAY, MAX_DECAY);
  }
  
  void update() {
    vel.add(acc);
    vel.limit(PARTICLE_SPEED);
    prevPos.set(pos);
    pos.add(vel);
    acc.mult(0); 
    
    // Reduce life
    lifespan -= decay;
  }
  
  void applyForce(PVector force) {
    acc.add(force);
  }
  
  void follow(PVector[] vectors) {
    int x = floor(pos.x / GRID_RESOLUTION);
    int y = floor(pos.y / GRID_RESOLUTION);
    x = constrain(x, 0, cols - 1);
    y = constrain(y, 0, rows - 1);
    int index = x + y * cols;
    applyForce(vectors[index]);
  }
  
  void display() {
    // Check bounds for drawing logic
    if (pos.x > PADDING && pos.x < width - PADDING && 
        pos.y > PADDING && pos.y < height - PADDING &&
        prevPos.x > PADDING && prevPos.x < width - PADDING && 
        prevPos.y > PADDING && prevPos.y < height - PADDING) {
      
      // Calculate opacity based on life
      // We map the remaining lifespan to the Stroke Alpha range
      float currentAlpha = map(lifespan, 0, maxLifespan, 0, STROKE_ALPHA);
      
      if (currentAlpha > 0) {
        if (random(1) < 0.05) {
           int rIdx = floor(random(1, 5));
           int c = 0xFF000000 | unhex(HEX_PALETTE[rIdx]);
           stroke(c, currentAlpha);
        } else {
           stroke(inkColor, currentAlpha);
        }
        
        line(pos.x, pos.y, prevPos.x, prevPos.y);
      }
    }
  }
  
  void checkStatus() {
    // Respawn if out of bounds OR if life is depleted
    boolean dead = lifespan < 0;
    boolean outOfBounds = (pos.x < PADDING || pos.x > width - PADDING || 
                           pos.y < PADDING || pos.y > height - PADDING);
                           
    if (dead || outOfBounds) {
      spawn();
      prevPos.set(pos); // Prevent drawing streaks
    }
  }
}
