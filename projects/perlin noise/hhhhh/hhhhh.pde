/**
 * Version: 2025.11.25.22.48.00
 * Concept: Cross-Hatched Atmosphere (CMY Flow Fields) with Perpendicular Offshoots
 * * Description: 
 * Generates three overlapping flow fields (Cyan, Magenta, Yellow).
 * Agents now emit "sparks" or "offshoots" that travel perpendicular to 
 * the main flow direction, creating a complex, woven texture.
 */

// ------------------------------------------------------------------
// CONFIGURATION PARAMETERS
// ------------------------------------------------------------------

// Canvas Dimensions
int SKETCH_WIDTH = 480;      // Default: 480
int SKETCH_HEIGHT = 800;     // Default: 800

// Initialization
int GLOBAL_SEED = 112233;    // Default: 112233 (Changed seed for variety)

// Layout & Styling
int PADDING = 40;            // Default: 40 (Padding around the active sketch area)
boolean INVERT_BG = false;   // Default: false (false = Light BG/Multiply, true = Dark BG/Add)

// Animation Control
int MAX_FRAMES = 900;        // Default: 900
boolean SAVE_FRAMES = false; // Default: false
int ANIM_SPEED = 30;         // Default: 30

// Physics & Noise
float NOISE_SCALE = 0.05;   // Default: 0.003
int NUM_AGENTS_PER_LAYER = 300; // Default: 300
float AGENT_SPEED = 10.0;     // Default: 2.0
float ANGLE_VARIANCE = 4.0;  // Default: 4.0

// Offshoot / Perpendicular Line Settings
float OFFSHOOT_CHANCE = 0.03;  // Default: 0.03 (3% chance per frame per agent)
float OFFSHOOT_SPEED = 1.5;    // Default: 1.5 (Speed of the perpendicular line)
int OFFSHOOT_LIFE = 15;        // Default: 15 (How many frames the offshoot lasts)
float OFFSHOOT_START_ALPHA = 40; // Default: 40 (Starting opacity for offshoots)

// Visuals
float STROKE_WEIGHT = 1.0;   // Default: 1.0
float STROKE_ALPHA = 15;     // Default: 15 (Main agent alpha)
boolean SHOW_GRID = false;   // Default: false

// Color Palette (CMY + Backgrounds)
// Format: 0:Cyan, 1:Magenta, 2:Yellow, 3:LightBG, 4:DarkBG
String[] HEX_PALETTE = {
  "#00AEEF", // Cyan
  "#EC008C", // Magenta
  "#FFF200", // Yellow
  "#FDFBF7", // Off-White (Paper)
  "#1A1A1A"  // Soft Black (Charcoal)
};

// ------------------------------------------------------------------
// GLOBAL VARIABLES
// ------------------------------------------------------------------

Layer[] layers;
int[] activePalette;
int bgColor;

// ------------------------------------------------------------------
// SETUP & SETTINGS
// ------------------------------------------------------------------

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  surface.setTitle("Cross-Hatched Atmosphere v2");
  frameRate(ANIM_SPEED);
  randomSeed(GLOBAL_SEED);
  noiseSeed(GLOBAL_SEED);
  
  parsePalette();
  
  // Initialize Background
  bgColor = INVERT_BG ? activePalette[4] : activePalette[3];
  background(bgColor);
  
  // Set Blend Mode
  if (INVERT_BG) {
    blendMode(ADD); 
  } else {
    blendMode(MULTIPLY); 
  }
  
  // Initialize Layers with offsets
  layers = new Layer[3];
  layers[0] = new Layer(activePalette[0], 0); 
  layers[1] = new Layer(activePalette[1], TWO_PI / 3.0); 
  layers[2] = new Layer(activePalette[2], (TWO_PI / 3.0) * 2.0);
}

// ------------------------------------------------------------------
// DRAW LOOP
// ------------------------------------------------------------------

void draw() {
  for (Layer l : layers) {
    l.run();
  }
  
  if (SHOW_GRID) {
    drawDebugGrid();
  }

  handleExport();
}

// ------------------------------------------------------------------
// CLASSES
// ------------------------------------------------------------------

class Layer {
  ArrayList<Agent> agents;
  ArrayList<Offshoot> offshoots; // Manage offshoots within the layer
  int layerColor;
  float angleOffset;
  
  Layer(int c, float offset) {
    this.layerColor = c;
    this.angleOffset = offset;
    this.agents = new ArrayList<Agent>();
    this.offshoots = new ArrayList<Offshoot>();
    
    for (int i = 0; i < NUM_AGENTS_PER_LAYER; i++) {
      agents.add(new Agent());
    }
  }
  
  void run() {
    strokeWeight(STROKE_WEIGHT);
    noFill();
    
    // 1. Update and Draw Agents
    stroke(layerColor, STROKE_ALPHA);
    for (Agent a : agents) {
      a.update(angleOffset, this); // Pass 'this' layer so Agent can add offshoots
      a.display();
    }
    
    // 2. Update and Draw Offshoots
    // Iterate backwards to allow removal
    for (int i = offshoots.size() - 1; i >= 0; i--) {
      Offshoot o = offshoots.get(i);
      o.update();
      o.display(layerColor);
      if (o.isDead()) {
        offshoots.remove(i);
      }
    }
  }
  
  // Method to add an offshoot to this layer
  void addOffshoot(Offshoot o) {
    offshoots.add(o);
  }
}

class Agent {
  PVector pos;
  PVector prevPos;
  PVector vel; // Store velocity to calculate perpendiculars
  
  Agent() {
    respawn();
    prevPos = pos.copy(); 
    vel = new PVector(0,0);
  }
  
  void respawn() {
    float x = random(PADDING, width - PADDING);
    float y = random(PADDING, height - PADDING);
    pos = new PVector(x, y);
    prevPos = pos.copy();
  }
  
  void update(float layerOffset, Layer parentLayer) {
    prevPos.set(pos);
    
    float n = noise(pos.x * NOISE_SCALE, pos.y * NOISE_SCALE);
    float angle = n * TWO_PI * ANGLE_VARIANCE + layerOffset;
    
    vel = PVector.fromAngle(angle);
    vel.mult(AGENT_SPEED);
    pos.add(vel);
    
    // Chance to spawn perpendicular offshoot
    if (random(1.0) < OFFSHOOT_CHANCE && isInBounds(pos)) {
      // Create perpendicular vector (rotate 90 degrees left or right)
      PVector perpDir = vel.copy().normalize();
      float dirMult = (random(1.0) < 0.5) ? 1.0 : -1.0;
      perpDir.rotate(HALF_PI * dirMult);
      
      parentLayer.addOffshoot(new Offshoot(pos, perpDir));
    }
    
    if (!isInBounds(pos)) {
      respawn();
      prevPos.set(pos); 
    }
  }
  
  void display() {
    if (PVector.dist(pos, prevPos) < AGENT_SPEED * 2) {
      line(prevPos.x, prevPos.y, pos.x, pos.y);
    }
  }
  
  boolean isInBounds(PVector p) {
    return (p.x >= PADDING && p.x <= width - PADDING && 
            p.y >= PADDING && p.y <= height - PADDING);
  }
}

class Offshoot {
  PVector pos;
  PVector prevPos;
  PVector vel;
  float life;
  float maxLife;
  
  Offshoot(PVector startPos, PVector dir) {
    pos = startPos.copy();
    prevPos = startPos.copy();
    vel = dir.mult(OFFSHOOT_SPEED);
    maxLife = OFFSHOOT_LIFE;
    life = maxLife;
  }
  
  void update() {
    prevPos.set(pos);
    pos.add(vel);
    life--;
  }
  
  void display(int c) {
    // Calculate alpha based on remaining life
    float currentAlpha = map(life, 0, maxLife, 0, OFFSHOOT_START_ALPHA);
    stroke(c, currentAlpha);
    
    // Draw segment
    line(prevPos.x, prevPos.y, pos.x, pos.y);
  }
  
  boolean isDead() {
    return life <= 0;
  }
}

// ------------------------------------------------------------------
// HELPER FUNCTIONS
// ------------------------------------------------------------------

void parsePalette() {
  activePalette = new int[HEX_PALETTE.length];
  for (int i = 0; i < HEX_PALETTE.length; i++) {
    String hex = HEX_PALETTE[i].replace("#", "");
    activePalette[i] = unhex("FF" + hex); 
  }
}

void drawDebugGrid() {
  blendMode(BLEND);
  stroke(128);
  noFill();
  strokeWeight(1);
  rect(PADDING, PADDING, width - (PADDING*2), height - (PADDING*2));
  if (INVERT_BG) blendMode(ADD); else blendMode(MULTIPLY);
}

void handleExport() {
  if (SAVE_FRAMES) {
    saveFrame("frames/line_####.tif");
  }
  if (frameCount >= MAX_FRAMES) {
    println("MAX_FRAMES reached: " + MAX_FRAMES);
    noLoop();
  }
}
