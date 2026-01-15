/**
 * The Turbulent Void
 * High-density flow field with a strict exclusion zone.
 * Particles are initialized only outside the central sphere to ensure 
 * the void remains empty and defined purely by kinetic avoidance.
 */

// --- Parameters ---
int SKETCH_WIDTH = 480;       // default 480
int SKETCH_HEIGHT = 800;      // default 800
int PADDING = 0;             // default 40
int MAX_FRAMES = 900;         // default 900
boolean SAVE_FRAMES = false;  // default false
int ANIMATION_SPEED = 30;     // default 30
int GLOBAL_SEED = 42;         // default 42

// Visual Tuning
int PARTICLE_COUNT = 10000;    // default 1500 (User update: 5000)
float NOISE_SCALE = 0.0005;   // default 0.005 (User update: 0.0005)
float AGENT_SPEED = 5.0;      // default 1.8
float VOID_RADIUS = 130.0;    // default 120.0
float REPEL_STRENGTH = 0.05;   // default 0.15
boolean SHOW_GRID = false;    // default false
int GRID_RES = 20;            // default 20
boolean INVERT_BG = false;    // default false

// Color Palettes
String[][] PALETTES = {
  {"#0F2027", "#203A43", "#2C5364", "#F2F2F2", "#3A6073"}, // Deep Sea
  {"#1A1A1D", "#4E4E50", "#6F2232", "#950740", "#C3073F"}, // Dark Crimson
  {"#23074D", "#CC5333", "#ED8F03", "#FFB400", "#F2F2F2"}, // Sunset Void
  {"#000000", "#150050", "#3F0071", "#FB2576", "#FFFFFF"}, // Cyberpunk
  {"#050505", "#1B262C", "#0F4C75", "#3282B8", "#BBE1FA"}  // Cold Tech
};
int PALETTE_INDEX = 2; // default 0

// --- Internal Variables ---
Particle[] particles;
int bg_color, stroke_color, accent_color;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  frameRate(ANIMATION_SPEED);
  randomSeed(GLOBAL_SEED);
  noiseSeed(GLOBAL_SEED);
  
  // Setup Colors
  String[] activePalette = PALETTES[PALETTE_INDEX];
  bg_color = unhex("FF" + activePalette[0].substring(1));
  stroke_color = unhex("FF" + activePalette[3].substring(1));
  accent_color = unhex("FF" + activePalette[4].substring(1));
  
  if (INVERT_BG) {
    int temp = bg_color;
    bg_color = stroke_color;
    stroke_color = temp;
  }

  particles = new Particle[PARTICLE_COUNT];
  for (int i = 0; i < PARTICLE_COUNT; i++) {
    particles[i] = new Particle();
  }
  
  background(bg_color);
}

void draw() {
  // Motion blur effect
  fill(bg_color, 15); 
  noStroke();
  rect(0, 0, width, height);

  if (SHOW_GRID) drawDebugGrid();

  translate(width/2, height/2);

  for (Particle p : particles) {
    p.update();
    p.display();
  }

  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) {
      noLoop();
    }
  }
}

void drawDebugGrid() {
  stroke(accent_color, 40);
  for (int x = 0; x <= width; x += GRID_RES) {
    line(x, 0, x, height);
  }
  for (int y = 0; y <= height; y += GRID_RES) {
    line(0, y, width, y);
  }
}

class Particle {
  PVector pos;
  PVector vel;
  PVector acc;
  float maxSpeed;
  
  Particle() {
    init();
  }
  
  void init() {
    // Force spawn outside the void radius
    boolean validSpawn = false;
    while (!validSpawn) {
      pos = new PVector(random(-width/2 + PADDING, width/2 - PADDING), 
                        random(-height/2 + PADDING, height/2 - PADDING));
      if (pos.mag() > VOID_RADIUS) {
        validSpawn = true;
      }
    }
    
    vel = PVector.random2D();
    acc = new PVector(0, 0);
    maxSpeed = random(AGENT_SPEED * 0.7, AGENT_SPEED * 1.3);
  }
  
  void update() {
    // Perlin Flow
    float angle = noise(pos.x * NOISE_SCALE + 1000, 
                        pos.y * NOISE_SCALE + 1000, 
                        frameCount * 0.002) * TWO_PI * 4;
    PVector flow = PVector.fromAngle(angle);
    acc.add(flow);
    
    // Hard avoidance logic
    float d = pos.mag();
    if (d < VOID_RADIUS + 20) {
      PVector repel = pos.copy();
      repel.normalize();
      // Strength increases exponentially as it nears the boundary
      float force = map(d, 0, VOID_RADIUS + 20, REPEL_STRENGTH * 10, 0);
      repel.mult(force);
      acc.add(repel);
    }
    
    vel.add(acc);
    vel.limit(maxSpeed);
    pos.add(vel);
    acc.mult(0);
    
    // Boundary and Void Check
    if (pos.x < -width/2 + PADDING || pos.x > width/2 - PADDING || 
        pos.y < -height/2 + PADDING || pos.y > height/2 - PADDING ||
        pos.mag() < VOID_RADIUS) {
      init();
    }
  }
  
  void display() {
    stroke(stroke_color, 180);
    strokeWeight(1.2);
    point(pos.x, pos.y);
  }
}
