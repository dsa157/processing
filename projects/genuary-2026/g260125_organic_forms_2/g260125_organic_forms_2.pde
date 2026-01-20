/**
 * Polygonal Slime Mold (Organic Geometry)
 * A network of nodes that connect based on proximity with added "Synapse Explosions".
 * Synapses create high-speed motion trails between distant network nodes.
 * Version: 2026.01.19.04.51.10
 */

// --- GLOBAL PARAMETERS ---
int SKETCH_WIDTH = 480;       // Default: 480
int SKETCH_HEIGHT = 800;      // Default: 800
int SEED_VALUE = 42;          // Random seed
int PADDING = 40;             // Canvas padding
int MAX_FRAMES = 900;         // Max frames for saving
boolean SAVE_FRAMES = false;  // Save frames toggle
int ANIMATION_SPEED = 30;     // Framerate
boolean INVERT_BG = false;    // Flip background/foreground colors
boolean SHOW_GRID = false;    // Debug grid visibility

// Simulation Parameters
int AGENT_COUNT = 600;        // Number of mold nodes (Default: 150)
float SENSOR_DIST = 15.0;     // How far agents look for nutrients (Default: 35.0)
float SENSOR_ANGLE = 0.78;    // Angle of sensors in radians (Default: 0.78)
float ROTATION_ANGLE = 0.35;  // How sharp agents turn (Default: 0.35)
float AGENT_SPEED = 2.0;      // Movement speed (Default: 2.0)
float DECAY_RATE = 0.92;      // Trail evaporation (Default: 0.92)
float DIFFUSE_RATE = 0.1;     // Trail spread (Default: 0.1)
float CONNECTION_DIST = 55.0; // Proximity for polygonal lines (Default: 55.0)

// Synapse Parameters
float SYNAPSE_CHANCE = 0.0002;  // Probability of a jump per frame (Default: 0.02)
int SYNAPSE_LIFE = 20;       // Duration of synapse trail (Default: 20)

// Color Palettes
String[][] PALETTES = {
  {"#0F2027", "#203A43", "#2C5364", "#F2FCFE", "#00D2FF"}, // 0: Deep Sea
  {"#121212", "#E94560", "#0F3460", "#16213E", "#FFFFFF"}, // 1: Cyberpunk
  {"#2D5F2E", "#4E9350", "#B2D2A4", "#FBFFB9", "#1B3022"}, // 2: Forest Mold
  {"#23074D", "#CC5333", "#ED8F03", "#FFD005", "#F2F2F2"}, // 3: Sunset Pulse
  {"#1A1A1B", "#333F44", "#37AA9C", "#94F3E4", "#FCF6F5"}  // 4: Minty Tech
};
int PALETTE_INDEX = 3; // Selected: Sunset Pulse

float[][] trailMap;
Agent[] agents;
ArrayList<Synapse> synapses;
int bgColor, primaryColor, accentColor, veinColor, sparkColor;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  randomSeed(SEED_VALUE);
  frameRate(ANIMATION_SPEED);
  
  // Initialize Colors
  String[] activePalette = PALETTES[PALETTE_INDEX];
  bgColor = unhex("FF" + activePalette[0].substring(1));
  primaryColor = unhex("FF" + activePalette[1].substring(1));
  accentColor = unhex("FF" + activePalette[2].substring(1));
  veinColor = unhex("FF" + activePalette[3].substring(1));
  sparkColor = unhex("FF" + activePalette[4].substring(1));
  
  if (INVERT_BG) {
    int temp = bgColor;
    bgColor = sparkColor;
    sparkColor = temp;
  }

  trailMap = new float[width][height];
  agents = new Agent[AGENT_COUNT];
  synapses = new ArrayList<Synapse>();
  
  for (int i = 0; i < AGENT_COUNT; i++) {
    agents[i] = new Agent();
  }
  
  background(bgColor);
}

void draw() {
  // Semi-transparent background for "fading" trails
  fill(bgColor, 25); 
  noStroke();
  rect(0, 0, width, height);

  processTrailMap();
  
  // Update Agents and Connections
  for (int i = 0; i < agents.length; i++) {
    agents[i].step();
    
    for (int j = i + 1; j < agents.length; j++) {
      float d = dist(agents[i].x, agents[i].y, agents[j].x, agents[j].y);
      if (d < CONNECTION_DIST) {
        float pulse = sin(frameCount * 0.15 + d) * 0.5 + 0.5;
        stroke(veinColor, 60 * pulse);
        strokeWeight(1.2);
        line(agents[i].x, agents[i].y, agents[j].x, agents[j].y);
      }
    }
  }

  // Handle Synapses
  if (random(1) < SYNAPSE_CHANCE) {
    int startIdx = int(random(agents.length));
    int endIdx = int(random(agents.length));
    if (startIdx != endIdx) {
      synapses.add(new Synapse(agents[startIdx], agents[endIdx]));
    }
  }

  for (int i = synapses.size() - 1; i >= 0; i--) {
    Synapse s = synapses.get(i);
    s.display();
    if (s.isDead()) synapses.remove(i);
  }

  if (SHOW_GRID) drawDebugGrid();

  // Housekeeping
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) noLoop();
  }
}

void processTrailMap() {
  for (int x = 1; x < width - 1; x++) {
    for (int y = 1; y < height - 1; y++) {
      float sum = trailMap[x-1][y] + trailMap[x+1][y] + trailMap[x][y-1] + trailMap[x][y+1];
      trailMap[x][y] = (trailMap[x][y] + sum * DIFFUSE_RATE) * DECAY_RATE;
    }
  }
}

void drawDebugGrid() {
  stroke(accentColor, 50);
  for (int x = PADDING; x < width - PADDING; x += 40) line(x, PADDING, x, height - PADDING);
  for (int y = PADDING; y < height - PADDING; y += 40) line(PADDING, y, width - PADDING, y);
}

class Synapse {
  float x1, y1, x2, y2;
  int timer;

  Synapse(Agent a, Agent b) {
    x1 = a.x; y1 = a.y;
    x2 = b.x; y2 = b.y;
    timer = SYNAPSE_LIFE;
  }

  void display() {
    float alpha = map(timer, 0, SYNAPSE_LIFE, 0, 255);
    stroke(sparkColor, alpha);
    strokeWeight(2);
    line(x1, y1, x2, y2);
    
    // Spark head
    noStroke();
    fill(sparkColor, alpha);
    ellipse(x2, y2, 5, 5);
    timer--;
  }

  boolean isDead() { return timer <= 0; }
}

class Agent {
  float x, y, angle;

  Agent() {
    x = random(PADDING, width - PADDING);
    y = random(PADDING, height - PADDING);
    angle = random(TWO_PI);
  }

  void step() {
    float vCenter = getSensorVal(0);
    float vLeft = getSensorVal(SENSOR_ANGLE);
    float vRight = getSensorVal(-SENSOR_ANGLE);

    if (vCenter > vLeft && vCenter > vRight) { } 
    else if (vCenter < vLeft && vCenter < vRight) {
      angle += (random(1) < 0.5 ? 1 : -1) * ROTATION_ANGLE;
    } else if (vLeft > vRight) {
      angle += ROTATION_ANGLE;
    } else if (vRight > vLeft) {
      angle -= ROTATION_ANGLE;
    }

    x += cos(angle) * AGENT_SPEED;
    y += sin(angle) * AGENT_SPEED;

    if (x < PADDING || x > width - PADDING || y < PADDING || y > height - PADDING) {
      angle += PI;
      x = constrain(x, PADDING, width - PADDING);
      y = constrain(y, PADDING, height - PADDING);
    }

    trailMap[int(x)][int(y)] += 1.5;
    
    noStroke();
    fill(primaryColor, 180);
    ellipse(x, y, 2.5, 2.5);
  }

  float getSensorVal(float offset) {
    float sx = x + cos(angle + offset) * SENSOR_DIST;
    float sy = y + sin(angle + offset) * SENSOR_DIST;
    int ix = int(constrain(sx, 0, width - 1));
    int iy = int(constrain(sy, 0, height - 1));
    return trailMap[ix][iy];
  }
}
