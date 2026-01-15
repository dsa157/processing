/**
 * Sketch: Ortho-Grid Image Reconstruction
 * Version: 2026.01.10.14.45.30
 * Description: Agents are restricted to 90-degree turns, translating 
 * image contours into a rectilinear, architectural grid.
 */

// --- GLOBAL PARAMETERS ---
int SKETCH_WIDTH = 480;       // Default: 480
int SKETCH_HEIGHT = 800;      // Default: 800
int PADDING = 40;             // Default: 40
int SEED_VALUE = 42;          // Default: 42
int MAX_FRAMES = 900;         // Default: 900
boolean SAVE_FRAMES = false;  // Default: false
int ANIMATION_SPEED = 30;     // Default: 30
boolean INVERT_BG = false;    // Default: false

// --- VIEW & IMAGE PARAMETERS ---
float ZOOM = 1.5;             // Default: 1.5
float EDGE_STRENGTH = 0.6;    // Default: 0.6
float EDGE_THRESHOLD = 40.0;  // Default: 40.0

// --- AGENT PARAMETERS ---
int AGENT_COUNT = 500;        // Default: 500
float AGENT_SPEED = 3.0;      // Default: 3.0 (Fixed step size for grid)
float STROKE_WEIGHT = 1.2;    // Default: 1.2
float TURN_CHANCE = 0.05;     // Default: 0.05 (Chance to turn even without an edge)
int TRAIL_LENGTH = 55;        // Default: 15 (Length of the ortho-segment)

// --- REVEAL PARAMETERS ---
int REVEAL_START_FRAME = 450; // Default: 450
float MIN_ALPHA = 0.0;        // Default: 0.0
float MAX_ALPHA = 10.0;       // Default: 10.0 (Ghostly reveal)

// --- COLOR PALETTES ---
String[][] PALETTES = {
  {"#2E294E", "#541388", "#F1E9DA", "#FFD400", "#D90368"},
  {"#1B1B1E", "#373F51", "#58A4B0", "#A9BCD0", "#D8DBE2"},
  {"#F94144", "#F3722C", "#F8961E", "#F9C74F", "#90BE6D"},
  {"#003049", "#D62828", "#F77F00", "#FCBF49", "#EAE2B7"},
  {"#264653", "#2A9D8F", "#E9C46A", "#F4A261", "#E76F51"}
};
int PALETTE_INDEX = 1;

PImage img;
PImage edgeMap;
ArrayList<Agent> agents;
float currentImgAlpha = 0;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  randomSeed(SEED_VALUE);
  frameRate(ANIMATION_SPEED);
  
  // 1. Load and Scale Image
  img = loadImage("selfie.jpg");
  float aspect = (float)img.height / (float)img.width;
  int targetW = int((SKETCH_WIDTH - (PADDING * 2)) * ZOOM);
  int targetH = int(targetW * aspect);
  img.resize(targetW, targetH);
  
  // 2. Generate Edge Data
  edgeMap = generateEdges(img);

  // Initialize Agents
  agents = new ArrayList<Agent>();
  for (int i = 0; i < AGENT_COUNT; i++) {
    agents.add(new Agent());
  }

  // Set Background
  color bgColor = hexToColor(PALETTES[PALETTE_INDEX][0]);
  if (INVERT_BG) {
    background(255 - red(bgColor), 255 - green(bgColor), 255 - blue(bgColor));
  } else {
    background(bgColor);
  }
}

void draw() {
  float offX = (width - img.width) / 2.0;
  float offY = (height - img.height) / 2.0;

  pushMatrix();
  translate(offX, offY);

  // Reveal original image
  if (frameCount >= REVEAL_START_FRAME) {
    currentImgAlpha = map(frameCount, REVEAL_START_FRAME, MAX_FRAMES, MIN_ALPHA, MAX_ALPHA);
    currentImgAlpha = constrain(currentImgAlpha, MIN_ALPHA, MAX_ALPHA);
    tint(255, currentImgAlpha);
    image(img, 0, 0);
    noTint();
  }

  // Update and draw grid agents
  for (Agent a : agents) {
    a.update();
    a.display();
  }

  popMatrix();

  // Save/Stop Logic
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) noLoop();
  } else if (frameCount >= MAX_FRAMES) {
    noLoop();
  }
}

class Agent {
  PVector pos, vel;
  color col;

  Agent() {
    reset();
  }

  void reset() {
    pos = new PVector(random(img.width), random(img.height));
    // Start with a random cardinal direction
    setRandomCardinal();
  }

  void setRandomCardinal() {
    int dir = int(random(4));
    if (dir == 0) vel = new PVector(1, 0);
    else if (dir == 1) vel = new PVector(-1, 0);
    else if (dir == 2) vel = new PVector(0, 1);
    else vel = new PVector(0, -1);
  }

  void update() {
    int x = constrain(int(pos.x), 0, edgeMap.width - 1);
    int y = constrain(int(pos.y), 0, edgeMap.height - 1);
    
    float intensity = brightness(edgeMap.get(x, y));

    // Turn if we hit an edge OR by random chance
    if (intensity > EDGE_THRESHOLD || random(1) < TURN_CHANCE) {
      PVector oldVel = vel.copy();
      // Turn 90 degrees (Perpendicular)
      if (vel.x != 0) {
        vel = new PVector(0, random(1) > 0.5 ? 1 : -1);
      } else {
        vel = new PVector(random(1) > 0.5 ? 1 : -1, 0);
      }
    }

    pos.add(PVector.mult(vel, AGENT_SPEED));

    // Boundary Reset
    if (pos.x < 0 || pos.x > img.width || pos.y < 0 || pos.y > img.height) {
      reset();
    }
    
    col = img.get(int(pos.x), int(pos.y));
  }

  void display() {
    stroke(col, 180);
    strokeWeight(STROKE_WEIGHT);
    // Draw the straight segment
    line(pos.x, pos.y, pos.x - vel.x * TRAIL_LENGTH, pos.y - vel.y * TRAIL_LENGTH);
  }
}

PImage generateEdges(PImage source) {
  PImage res = createImage(source.width, source.height, RGB);
  float[][] kx = {{-1, 0, 1}, {-2, 0, 2}, {-1, 0, 1}};
  float[][] ky = {{-1, -2, -1}, {0, 0, 0}, {1, 2, 1}};

  source.loadPixels();
  for (int x = 1; x < source.width - 1; x++) {
    for (int y = 1; y < source.height - 1; y++) {
      float sumX = 0, sumY = 0;
      for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
          float b = brightness(source.pixels[(x + i) + (y + j) * source.width]);
          sumX += b * kx[i + 1][j + 1];
          sumY += b * ky[i + 1][j + 1];
        }
      }
      float mag = sqrt(sumX * sumX + sumY * sumY) * EDGE_STRENGTH;
      res.pixels[x + y * source.width] = (mag > EDGE_THRESHOLD) ? color(mag) : color(0);
    }
  }
  return res;
}

color hexToColor(String hex) {
  return color(unhex("FF" + hex.substring(1)));
}
