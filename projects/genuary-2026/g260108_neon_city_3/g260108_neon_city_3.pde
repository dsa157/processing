/**
 * Pulse of the Night - Perpetual Glow
 * Version: 2026.01.04.22.25.12
 * * Refined color cycling to ensure buildings never disappear.
 * * Added constant base luminosity and clamped pulse values.
 */

// --- Parameters ---
int SKETCH_WIDTH = 480;       // default 480
int SKETCH_HEIGHT = 800;      // default 800
int MAX_FRAMES = 900;         // default 900
boolean SAVE_FRAMES = false;  // default false
int ANIMATION_SPEED = 30;     // default 30
int PADDING = 20;             // default 40 
int GLOBAL_SEED = 1234;       // default 42

// Grid & City Settings
int GRID_COLS = 8;            // default 6 
int GRID_ROWS = 14;           // default 10 
float CELL_SIZE = 55.0;       // default 60.0
float MAX_BUILDING_H = 400.0; // default 300.0
boolean SHOW_GRID = false;    // default false

// Visuals
float PULSE_SPEED = 0.04;     // default 0.05
float COLOR_FLOW_RATE = 0.008; // default 0.01
boolean INVERT_BG = false;    // default false

// Adobe Kuler Palette: "Night City Flux"
color[] palette = {
  #08080B, // 0: Deep Background
  #1E1E24, // 1: Building Core (Lifted from #121216 to ensure visibility)
  #00FFD1, // 2: Neon Mint
  #4900FF, // 3: Electric Indigo
  #FF0055, // 4: Vivid Rose
  #FFD300  // 5: Cyber Yellow
};

Cityscape city;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT, P3D);
}

void setup() {
  frameRate(ANIMATION_SPEED);
  randomSeed(GLOBAL_SEED);
  
  float cityW = (GRID_COLS - 1) * CELL_SIZE;
  float cityD = (GRID_ROWS - 1) * CELL_SIZE;
  city = new Cityscape(GRID_COLS, GRID_ROWS, CELL_SIZE, cityW, cityD);
}

void draw() {
  color bgColor = INVERT_BG ? color(235) : palette[0];
  background(bgColor);
  
  // Ambient light ensures buildings are never pitch black
  ambientLight(60, 60, 70); 
  pointLight(200, 200, 255, 0, -400, 600);

  pushMatrix();
  translate(width/2, height/2 + 50, -300); 
  rotateX(PI/3.2); 
  rotateZ(frameCount * 0.004); 
  
  city.display();
  popMatrix();

  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) noLoop();
  }
}

// Seamlessly cycles through neon palette indices [2, 3, 4, 5]
color getFlowingColor(float offset) {
  float t = (frameCount * COLOR_FLOW_RATE + offset) % 1.0;
  int firstNeonIdx = 2;
  int numNeons = 4;
  
  float scaledT = t * numNeons;
  int idx1 = firstNeonIdx + floor(scaledT) % numNeons;
  int idx2 = firstNeonIdx + (floor(scaledT) + 1) % numNeons;
  
  float amt = scaledT - floor(scaledT);
  return lerpColor(palette[idx1], palette[idx2], amt);
}

class Building {
  float x, y, totalH, baseW;
  float offset;
  int tiers;
  float taperFactor;

  Building(float _x, float _y, float _w, float _h) {
    x = _x;
    y = _y;
    baseW = _w;
    totalH = _h;
    offset = random(500);
    tiers = floor(random(3, 7)); 
    taperFactor = random(0.05, 0.25);
  }

  void render() {
    color pulseColor = getFlowingColor(offset * 0.05);
    // Sine wave for rhythm, clamped so it never hits 0 (blackout)
    float pulseWave = sin(frameCount * PULSE_SPEED + offset);
    float glowIntensity = map(pulseWave, -1, 1, 0.3, 1.0); // Minimum 0.3 intensity
    
    pushMatrix();
    translate(x, y, 0);
    
    if (SHOW_GRID) {
      noFill();
      stroke(palette[1]);
      rect(0, 0, CELL_SIZE, CELL_SIZE);
    }

    float currentH = 0;
    for (int i = 0; i < tiers; i++) {
      float tierH = totalH / tiers;
      float tierW = baseW * (1.0 - (i * taperFactor)); 
      
      pushMatrix();
      translate(0, 0, currentH + tierH/2);
      
      // Core Structure: Always visible with a faint edge highlight
      fill(palette[1]);
      // Stroke is a mix of core color and the flowing neon color
      stroke(lerpColor(palette[1], pulseColor, glowIntensity));
      strokeWeight(1.2);
      box(tierW, tierW, tierH);
      
      // Pulsing Wireframe: Only visible during wave peaks
      if (pulseWave > 0.2) {
        float edgeAlpha = map(pulseWave, 0.2, 1.0, 0, 255);
        noFill();
        stroke(pulseColor, edgeAlpha);
        strokeWeight(1.5);
        box(tierW + 1.5, tierW + 1.5, tierH + 0.5);
      }
      
      popMatrix();
      currentH += tierH;
    }
    popMatrix();
  }
}

class Cityscape {
  Building[] buildings;

  Cityscape(int cols, int rows, float spacing, float tw, float td) {
    buildings = new Building[cols * rows];
    for (int i = 0; i < cols; i++) {
      for (int j = 0; j < rows; j++) {
        float bx = map(i, 0, cols-1, -tw/2, tw/2);
        float by = map(j, 0, rows-1, -td/2, td/2);
        
        float distCenter = dist(bx, by, 0, 0);
        float bh = random(80, MAX_BUILDING_H) * map(distCenter, 0, tw, 1.3, 0.5);
        float bw = spacing * 0.7;
        buildings[i + j * cols] = new Building(bx, by, bw, bh);
      }
    }
  }

  void display() {
    for (Building b : buildings) {
      b.render();
    }
  }
}
