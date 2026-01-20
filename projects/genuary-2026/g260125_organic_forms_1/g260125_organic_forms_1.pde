/**
 * Spatially Aware Decaying Mycelium (Fixed Constructor)
 * Clusters detect low-density areas to spawn and maintain 100 max hyphae.
 * Version: 2026.01.19.03.45.12
 */

// --- Global Configuration ---
int SKETCH_WIDTH = 480;       // default 480
int SKETCH_HEIGHT = 800;      // default 800
int SEED_VALUE = 257;          // default 42
int PADDING = 40;             // default 40
int MAX_FRAMES = 900;         // default 900
boolean SAVE_FRAMES = true;  // default false
int ANIMATION_SPEED = 30;     // default 30
boolean SHOW_GRID = false;    // default false
boolean INVERT_BG = false;    // default false

// --- Growth & Pulse Parameters ---
int PALETTE_INDEX = 1;        // index 1 for blood red
float BRANCH_CHANCE = 0.4;    // default 0.4
float STEP_SIZE = 3.0;        // length of each segment: 3.0
int MAX_HYPHAE_PER_CLUSTER = 150; // max concurrent branches: 100
float WIGGLE_ROOM = 0.5;      // organic rotation variation: 0.5
float PULSE_SPEED = 0.1;      // speed of breathing: 0.1
float PULSE_STRENGTH = 1.5;   // weight fluctuation: 2.0

// --- Decay & Spatial Parameters ---
int DECAY_START_FRAME = 300;  // frames before fade: 300
float DECAY_RATE = 2.0;       // alpha loss per frame: 2.0
int DENSITY_SAMPLES = 15;     // sampling points for spawn location

// --- Color Palettes ---
String[][] PALETTES = {
  {"#2E4057", "#848FA2", "#2D3142", "#BFC0C0", "#EF8354"}, 
  {"#0B090A", "#161A1D", "#660708", "#A4161A", "#BA181B"}, 
  {"#EAE2B7", "#FCBF49", "#F77F00", "#D62828", "#00304E"}, 
  {"#264653", "#2A9D8F", "#E9C46A", "#F4A261", "#E76F51"}, 
  {"#000000", "#14213D", "#FCA311", "#E5E5E5", "#FFFFFF"}  
};

color[] activePalette;
color backgroundColor;
ArrayList<Cluster> clusters;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  randomSeed(SEED_VALUE);
  frameRate(ANIMATION_SPEED);
  
  activePalette = new color[5];
  for (int i = 0; i < 5; i++) {
    activePalette[i] = unhex("FF" + PALETTES[PALETTE_INDEX][i].substring(1));
  }
  
  backgroundColor = INVERT_BG ? activePalette[4] : activePalette[0];
  clusters = new ArrayList<Cluster>();
  
  // Start the first cluster
  clusters.add(new Cluster(width/2, height/2));
}

void draw() {
  background(backgroundColor);
  
  if (SHOW_GRID) drawDebugGrid();
  
  float pulse = (sin(frameCount * PULSE_SPEED) + 1) / 2;
  boolean anyActiveGrowth = false;

  for (int i = clusters.size() - 1; i >= 0; i--) {
    Cluster c = clusters.get(i);
    c.update();
    c.display(pulse);
    
    if (c.isGrowing) anyActiveGrowth = true;
    
    // Cleanup faded clusters
    if (c.alpha <= 0) {
      clusters.remove(i);
    }
  }

  // Spawn new growth in a less dense area if current growth slows
  if (!anyActiveGrowth) {
    PVector bestPos = findLowDensityArea();
    clusters.add(new Cluster(bestPos.x, bestPos.y));
  }

  // Management Block
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) noLoop();
  }
}

PVector findLowDensityArea() {
  PVector winner = new PVector(random(PADDING, width-PADDING), random(PADDING, height-PADDING));
  float minDensity = Float.MAX_VALUE;

  for (int i = 0; i < DENSITY_SAMPLES; i++) {
    float testX = random(PADDING, width-PADDING);
    float testY = random(PADDING, height-PADDING);
    float currentDensity = 0;

    for (Cluster c : clusters) {
      for (Hypha h : c.members) {
        for (PVector p : h.history) {
          if (dist(testX, testY, p.x, p.y) < 60) {
            currentDensity++;
          }
        }
      }
    }

    if (currentDensity < minDensity) {
      minDensity = currentDensity;
      winner.set(testX, testY);
    }
  }
  return winner;
}

void drawDebugGrid() {
  stroke(activePalette[2], 50);
  noFill();
  rect(PADDING, PADDING, width - (PADDING * 2), height - (PADDING * 2));
}

class Cluster {
  ArrayList<Hypha> members;
  float alpha = 255;
  int age = 0;
  boolean isGrowing = true;

  Cluster(float x, float y) {
    members = new ArrayList<Hypha>();
    // Fixed: Now matches the 3-parameter constructor
    members.add(new Hypha(x, y, random(TWO_PI)));
  }

  void update() {
    age++;
    isGrowing = false;
    
    if (age > DECAY_START_FRAME) {
      alpha -= DECAY_RATE;
    }

    for (int i = members.size() - 1; i >= 0; i--) {
      Hypha h = members.get(i);
      h.update();
      if (h.active) {
        isGrowing = true;
        if (random(1) < BRANCH_CHANCE && members.size() < MAX_HYPHAE_PER_CLUSTER) {
          members.add(new Hypha(h.x, h.y, h.angle + random(-QUARTER_PI, QUARTER_PI), h.history));
        }
      }
    }
  }

  void display(float pulse) {
    for (Hypha h : members) {
      h.display(pulse, alpha);
    }
  }
}

class Hypha {
  float x, y, angle;
  color hColor;
  ArrayList<PVector> history;
  boolean active = true;
  int lifeSpan = 0;
  int maxLife;

  // Constructor for root hypha (new cluster)
  Hypha(float startX, float startY, float startAngle) {
    this(startX, startY, startAngle, new ArrayList<PVector>());
  }

  // Constructor for branched hypha (existing cluster)
  Hypha(float startX, float startY, float startAngle, ArrayList<PVector> parentHistory) {
    x = startX;
    y = startY;
    angle = startAngle;
    hColor = activePalette[int(random(1, 5))];
    maxLife = int(random(100, 200));
    history = new ArrayList<PVector>(parentHistory);
    history.add(new PVector(x, y));
  }

  void update() {
    if (!active) return;
    angle += random(-WIGGLE_ROOM, WIGGLE_ROOM);
    x += cos(angle) * STEP_SIZE;
    y += sin(angle) * STEP_SIZE;
    history.add(new PVector(x, y));
    lifeSpan++;
    
    if (x < PADDING || x > width - PADDING || y < PADDING || y > height - PADDING || lifeSpan > maxLife) {
      active = false; 
    }
  }

  void display(float pulse, float clusterAlpha) {
    noFill();
    float weight = 0.5 + (pulse * PULSE_STRENGTH);
    float finalAlpha = map(pulse, 0, 1, clusterAlpha * 0.4, clusterAlpha);
    
    strokeWeight(weight);
    stroke(hColor, finalAlpha);
    
    beginShape();
    for (PVector p : history) {
      vertex(p.x, p.y);
    }
    endShape();
  }
}
