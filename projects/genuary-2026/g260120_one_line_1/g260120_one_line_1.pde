/*
 * Persistent Calligraphy - Fixed Decay
 * A single continuous line where MAX_HISTORY now dictates the absolute 
 * visual length of the trailing tail via fixed alpha decrementing.
 * Version: 2026.01.12.22.40.12
 */

import java.util.LinkedList;

// --- Parameters ---
int SKETCH_WIDTH = 480;       // Default: 480
int SKETCH_HEIGHT = 800;      // Default: 800
int GLOBAL_SEED = 157;        // Default: 333
int PADDING = 40;             // Default: 40
int MAX_FRAMES = 900;         // Default: 900
int ANIMATION_SPEED = 60;     // Default: 60
int PALETTE_INDEX = 0;        // Default: 0

boolean SAVE_FRAMES = false;  // Default: false
boolean INVERT_BG = false;    // Default: false
boolean SHOW_GRID = false;    // Default: false
boolean STAY_IN_BOUNDS = true; // Default: true

float MAX_STROKE_WIDTH = 20.0; // Default: 20.0
float AVOIDANCE_FORCE = 0.9;  // Default: 0.9
float AVOIDANCE_ZONE = 70.0;  // Default: 70.0
int STEPS_PER_FRAME = 6;      // Default: 6
int MAX_HISTORY = 1000;       // Default: 1000 (Adjust for tail length)

// --- Color Palettes ---
String[][] PALETTES = {
  {"#FFFFFF", "#CCCCCC", "#999999", "#333333", "#000000"},
  {"#000000", "#14213D", "#FCA311", "#E5E5E5", "#FFFFFF"}
};

// --- Internal Variables ---
int[] activePalette;
LinkedList<PathSegment> history;
float posX, posY, velX, velY;
float time = 0;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  randomSeed(GLOBAL_SEED);
  noiseSeed(GLOBAL_SEED);
  frameRate(ANIMATION_SPEED);
  
  activePalette = new int[5];
  for (int i = 0; i < 5; i++) {
    activePalette[i] = unhex("FF" + PALETTES[PALETTE_INDEX][i].substring(1));
  }
  
  history = new LinkedList<PathSegment>();
  posX = 0;
  posY = 0;
  velX = random(-2, 2);
  velY = random(-2, 2);
}

void draw() {
  int bgCol = INVERT_BG ? activePalette[4] : activePalette[0];
  int lineCol = INVERT_BG ? activePalette[0] : activePalette[4];
  background(bgCol);
  
  if (SHOW_GRID) drawGrid(lineCol);
  
  translate(width / 2, height / 2);
  
  float innerW = (width / 2.0) - PADDING;
  float innerH = (height / 2.0) - PADDING;

  // 1. Path Generation
  for (int i = 0; i < STEPS_PER_FRAME; i++) {
    float prevX = posX;
    float prevY = posY;
    time += 0.006;
    
    // Steering
    float noiseAngle = noise(time, frameCount * 0.005) * TWO_PI * 4;
    velX += cos(noiseAngle) * 0.5;
    velY += sin(noiseAngle) * 0.5;
    
    if (STAY_IN_BOUNDS) {
      if (posX > innerW - AVOIDANCE_ZONE) velX -= AVOIDANCE_FORCE;
      if (posX < -innerW + AVOIDANCE_ZONE) velX += AVOIDANCE_FORCE;
      if (posY > innerH - AVOIDANCE_ZONE) velY -= AVOIDANCE_FORCE;
      if (posY < -innerH + AVOIDANCE_ZONE) velY += AVOIDANCE_FORCE;
      posX = constrain(posX, -innerW, innerW);
      posY = constrain(posY, -innerH, innerH);
    }
    
    velX *= 0.96;
    velY *= 0.96;
    posX += velX;
    posY += velY;

    float lifeTaper = map(frameCount % MAX_FRAMES, 0, MAX_FRAMES, 1.0, 0.1);
    float speed = dist(posX, posY, prevX, prevY);
    float targetWidth = map(speed, 0, 15, 1, MAX_STROKE_WIDTH) * lifeTaper;

    history.add(new PathSegment(prevX, prevY, posX, posY, targetWidth));
  }

  // 2. Fixed History Management
  while (history.size() > MAX_HISTORY) {
    history.removeFirst();
  }

  // 3. Render with Absolute Alpha Decay
  noStroke();
  for (int i = 0; i < history.size(); i++) {
    PathSegment s = history.get(i);
    
    // Calculate alpha based on position in the CURRENT list
    // i=0 is the oldest, i=history.size()-1 is the newest
    float ageIndex = (float) i / history.size();
    
    // Fixed visual fade: segments always fade out as they reach the start of the list
    float alpha = ageIndex * 255; 
    float thicknessScale = ageIndex; 
    
    fill(lineCol, alpha);
    s.display(thicknessScale);
  }

  // Frame Control
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) noLoop();
  } else if (frameCount >= MAX_FRAMES) {
    // We do NOT clear history here so the tail persists through the reset
    frameCount = 0; 
  }
}

class PathSegment {
  float x1, y1, x2, y2, w, angle;

  PathSegment(float x1, float y1, float x2, float y2, float w) {
    this.x1 = x1; this.y1 = y1;
    this.x2 = x2; this.y2 = y2;
    this.w = w;
    this.angle = atan2(y2 - y1, x2 - x1) + HALF_PI;
  }

  void display(float tScale) {
    float curW = w * tScale;
    beginShape(TRIANGLE_STRIP);
    vertex(x1 + cos(angle) * curW, y1 + sin(angle) * curW);
    vertex(x2 + cos(angle) * curW, y2 + sin(angle) * curW);
    vertex(x1 - cos(angle) * curW, y1 - sin(angle) * curW);
    vertex(x2 - cos(angle) * curW, y2 - sin(angle) * curW);
    endShape();
  }
}

void drawGrid(int col) {
  stroke(col, 15);
  for (int i = -width; i < width; i += 50) line(i, -height, i, height);
  for (int j = -height; j < height; j += 50) line(-width, j, width, j);
}
