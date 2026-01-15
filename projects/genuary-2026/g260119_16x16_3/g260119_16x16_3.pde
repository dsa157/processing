/*
 * High-Contrast Kinetic Network
 * Version: 2026.01.11.17.44.10
 * 128 Comets with decaying trails and uniform destination distribution.
 * High-contrast color palettes and shockwave interaction.
 */

// --- Global Parameters ---
int SKETCH_WIDTH = 480;       // default: 480
int SKETCH_HEIGHT = 800;      // default: 800
int PADDING = 40;             // default: 40
int MAX_FRAMES = 900;         // default: 900
boolean SAVE_FRAMES = false;  // default: false
int ANIMATION_SPEED = 30;     // default: 30
int GLOBAL_SEED = 42;         // default: 42

// Grid & Node Settings
int GRID_COUNT = 16;          // default: 16
float NODE_SIZE = 6.0;        // default: 6.0

// Comet & Trail Settings
int COMET_COUNT = 128;        // default: 128
float COMET_HEAD_SIZE = 6.0;  // default: 6.0
float COMET_SPEED = 5.5;      // default: 5.5
float TRAIL_DECAY = 20;       // default: 20
float TRAIL_WEIGHT = 1.2;     // default: 1.2

// Shockwave Settings
float SHOCKWAVE_MIN_RADIUS = 15.0;   // default: 5.0
float SHOCKWAVE_MAX_RADIUS = 45.0;  // default: 75.0
float SHOCKWAVE_EXPANSION = 5.0;    // default: 5.0

// Color & Appearance
int PALETTE_INDEX = 0;        // default: 0-4 (High Contrast Focus)
boolean INVERT_BG = false;    // default: false

int[][] PALETTES = {
  {#000000, #FFFFFF, #FF0055, #00FF99, #FFFF00}, // Neon Noir
  {#050505, #1A1A1A, #00D4FF, #F5F5F5, #FFD700}, // Electric Gold
  {#121212, #242424, #FF5F1F, #E0E0E0, #39FF14}, // Safety High-Vis
  {#FFFFFF, #E0E0E0, #000000, #FF0000, #0000FF}, // Stark Bauhaus (Invert recommended)
  {#0A0E14, #212733, #FF3366, #5CCFE6, #FAE766}  // Deep Space
};

// --- Internal Variables ---
ArrayList<Comet> comets;
ArrayList<Shockwave> shockwaves;
PVector[] masses;
boolean[] nodeOccupied; 
PGraphics trailLayer;
int bgColor, nodeColor, cometColor, waveColor, trailColor;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  randomSeed(GLOBAL_SEED);
  frameRate(ANIMATION_SPEED);
  
  // Color Selection
  int[] palette = PALETTES[PALETTE_INDEX];
  bgColor = INVERT_BG ? palette[3] : palette[0];
  nodeColor = palette[1];   
  cometColor = INVERT_BG ? palette[0] : palette[3];  
  waveColor = palette[2];   
  trailColor = palette[4];

  trailLayer = createGraphics(width, height);
  trailLayer.beginDraw();
  trailLayer.background(0, 0);
  trailLayer.endDraw();
  
  // Initialize Grid
  masses = new PVector[GRID_COUNT * GRID_COUNT];
  nodeOccupied = new boolean[GRID_COUNT * GRID_COUNT];
  float spacingX = (float)(width - 2 * PADDING) / (GRID_COUNT - 1);
  float spacingY = (float)(height - 2 * PADDING) / (GRID_COUNT - 1);
  
  for (int i = 0; i < GRID_COUNT; i++) {
    for (int j = 0; j < GRID_COUNT; j++) {
      int idx = i * GRID_COUNT + j;
      masses[idx] = new PVector(PADDING + (i * spacingX), PADDING + (j * spacingY));
      nodeOccupied[idx] = false;
    }
  }

  comets = new ArrayList<Comet>();
  for (int i = 0; i < COMET_COUNT; i++) {
    comets.add(new Comet());
  }
  
  shockwaves = new ArrayList<Shockwave>();
}

void draw() {
  background(bgColor);
  
  updateTrails();
  image(trailLayer, 0, 0);
  drawNodes();

  // Update Shockwaves
  for (int i = shockwaves.size() - 1; i >= 0; i--) {
    Shockwave s = shockwaves.get(i);
    s.update();
    s.display();
    
    for (Comet c : comets) {
      if (PVector.dist(s.pos, c.pos) < s.currentRadius && !s.hasAffected(c)) {
        c.reroute();
        s.addAffected(c);
      }
    }
    if (s.isDead()) shockwaves.remove(i);
  }

  // Update Comets
  for (Comet c : comets) {
    c.update();
    c.display();
  }

  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) noLoop();
  }
}

void updateTrails() {
  trailLayer.beginDraw();
  trailLayer.noStroke();
  trailLayer.fill(bgColor, TRAIL_DECAY);
  trailLayer.rect(0, 0, width, height);
  trailLayer.endDraw();
}

void drawNodes() {
  noStroke();
  fill(nodeColor);
  for (PVector m : masses) {
    ellipse(m.x, m.y, NODE_SIZE, NODE_SIZE);
  }
}

class Comet {
  PVector pos, prevPos, vel;
  int targetIdx = -1;

  Comet() {
    int startIdx = int(random(masses.length));
    pos = masses[startIdx].copy();
    prevPos = pos.copy();
    vel = new PVector(0, 0);
    pickNewTarget();
  }

  void pickNewTarget() {
    if (targetIdx != -1) nodeOccupied[targetIdx] = false;
    
    // Improved distribution: Shuffle indices to ensure better spread
    int newTarget = int(random(masses.length));
    int attempts = 0;
    while (nodeOccupied[newTarget] && attempts < masses.length) {
      newTarget = (newTarget + 1) % masses.length; // Linear probe for efficiency and spread
      attempts++;
    }
    
    targetIdx = newTarget;
    nodeOccupied[targetIdx] = true;
  }

  void reroute() {
    pickNewTarget();
  }

  void update() {
    prevPos = pos.copy();
    PVector targetPos = masses[targetIdx];
    PVector dir = PVector.sub(targetPos, pos);
    float d = dir.mag();
    
    if (d < COMET_SPEED) {
      shockwaves.add(new Shockwave(targetPos.x, targetPos.y));
      pos = targetPos.copy();
      pickNewTarget();
    } else {
      dir.setMag(COMET_SPEED);
      pos.add(dir);
      vel = dir.copy();
    }
    
    trailLayer.beginDraw();
    trailLayer.stroke(trailColor, 180);
    trailLayer.strokeWeight(TRAIL_WEIGHT);
    trailLayer.line(prevPos.x, prevPos.y, pos.x, pos.y);
    trailLayer.endDraw();
  }

  void display() {
    stroke(cometColor);
    strokeWeight(2);
    line(pos.x, pos.y, pos.x - vel.x * 3, pos.y - vel.y * 3);
    noStroke();
    fill(cometColor);
    ellipse(pos.x, pos.y, COMET_HEAD_SIZE, COMET_HEAD_SIZE);
  }
}

class Shockwave {
  PVector pos;
  float currentRadius;
  float opacity = 255;
  ArrayList<Comet> affectedList;
  
  Shockwave(float x, float y) {
    pos = new PVector(x, y);
    currentRadius = SHOCKWAVE_MIN_RADIUS;
    affectedList = new ArrayList<Comet>();
  }
  
  void addAffected(Comet c) { affectedList.add(c); }
  boolean hasAffected(Comet c) { return affectedList.contains(c); }
  
  void update() {
    currentRadius += SHOCKWAVE_EXPANSION;
    opacity = map(currentRadius, SHOCKWAVE_MIN_RADIUS, SHOCKWAVE_MAX_RADIUS, 255, 0);
  }
  
  void display() {
    noFill();
    stroke(waveColor, opacity);
    strokeWeight(3);
    ellipse(pos.x, pos.y, currentRadius * 2, currentRadius * 2);
  }
  
  boolean isDead() {
    return currentRadius >= SHOCKWAVE_MAX_RADIUS || opacity <= 0;
  }
}
