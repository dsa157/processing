/**
 * Seamless Kinetic Cube Loop
 * Version: 2026.01.11.16.20.15
 * Author: Gemini (Processing.org Assistant)
 */

// --- Global Parameters ---
int SKETCH_WIDTH = 480;      // Default: 480
int SKETCH_HEIGHT = 800;     // Default: 800
int PADDING = 80;            // Default: 80
int SEED_VALUE = 42;         // Default: 42
int MAX_FRAMES = 900;        // Default: 900
boolean SAVE_FRAMES = false; // Default: false
int ANIMATION_SPEED = 30;    // Default: 30

// --- Transformation Timing ---
int CYCLE_DURATION = 300;    // Frames for one full loop cycle
float HOLD_RATIO = 0.2;      // 20% of time spent as a perfect cube

// --- Grid & 3D Parameters ---
int GRID_XY = 8;             
int GRID_Z = 4;              // 8x8x4 = 256 points
float SPHERE_SIZE = 3.0;     // Default: 3.0
float BEZIER_STRENGTH = 80.0; // Default: 80.0
float CUBE_DEPTH = 300.0;    // Depth of the cube lattice

// --- Color Palette Setup ---
int[][] PALETTES = {
  {0xFF1A1A1D, 0xFF6F2232, 0xFF950740, 0xFFC3073F, 0xFF4E4E50}, // Industrial Red
  {0xFF011627, 0xFFFDFFFC, 0xFF2EC4B6, 0xFFE71D36, 0xFFFF9F1C}, // Cyberpunk
  {0xFF2D3142, 0xFF4F5D75, 0xFFBFC0C0, 0xFFFFFFFF, 0xFFEF8354}, // Cool Slate
  {0xFF0B0D17, 0xFFFCF6F5, 0xFF807182, 0xFFCBAACB, 0xFF6B5B95}, // Lavender Dark
  {0xFF000000, 0xFF333333, 0xFF666666, 0xFF999999, 0xFFCCCCCC}  // Grayscale
};
int PALETTE_INDEX = 1;       // Default: 1
boolean INVERT_BG = false;   // Default: false

AnchorPoint[] anchors = new AnchorPoint[GRID_XY * GRID_XY * GRID_Z];

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT, P3D);
}

void setup() {
  randomSeed(SEED_VALUE);
  frameRate(ANIMATION_SPEED);
  
  float innerSize = width - (PADDING * 2);
  float spacingXY = innerSize / (float)(GRID_XY - 1);
  float spacingZ = CUBE_DEPTH / (float)(GRID_Z - 1);

  int count = 0;
  for (int z = 0; z < GRID_Z; z++) {
    for (int y = 0; y < GRID_XY; y++) {
      for (int x = 0; x < GRID_XY; x++) {
        float posX = PADDING + x * spacingXY;
        float posY = (height/2 - innerSize/2) + y * spacingXY;
        float posZ = -(CUBE_DEPTH/2) + z * spacingZ;
        anchors[count++] = new AnchorPoint(posX, posY, posZ, x, y, z);
      }
    }
  }
}

void draw() {
  int bgColor = INVERT_BG ? PALETTES[PALETTE_INDEX][3] : PALETTES[PALETTE_INDEX][0];
  background(bgColor);
  
  // Calculate Progress (0.0 to 1.0)
  float progress = (frameCount % CYCLE_DURATION) / (float)CYCLE_DURATION;
  
  // Calculate Morph Factor (0.0 = perfect cube, 1.0 = max fluid)
  float morphFactor;
  if (progress < HOLD_RATIO) {
    morphFactor = 0;
  } else {
    // Maps the remaining time to a 0 -> 1 -> 0 sine curve
    float internalTheta = map(progress, HOLD_RATIO, 1.0, 0, PI);
    morphFactor = sin(internalTheta);
  }

  // Global scene orientation
  translate(width/2, height/2, 0);
  // Auto-rotation must also be tied to a cycle for a 900-frame seamless loop
  // 900 frames = 30 seconds at 30fps. 
  float globalRotation = map(frameCount % MAX_FRAMES, 0, MAX_FRAMES, 0, TWO_PI);
  rotateY(globalRotation);
  rotateX(globalRotation * 0.5);
  translate(-width/2, -height/2, 0);

  // Update Points
  for (AnchorPoint p : anchors) {
    p.update(morphFactor);
    p.display();
  }

  // Draw Connections
  noFill();
  strokeWeight(1.0);
  stroke(PALETTES[PALETTE_INDEX][2], 120);

  for (int i = 0; i < anchors.length; i++) {
    AnchorPoint a = anchors[i];
    // Connect to neighbors
    if (a.ix < GRID_XY - 1) drawLink(a, anchors[i + 1], morphFactor);
    if (a.iy < GRID_XY - 1) drawLink(a, anchors[i + GRID_XY], morphFactor);
    if (a.iz < GRID_Z - 1)  drawLink(a, anchors[i + GRID_XY * GRID_XY], morphFactor);
  }

  // --- Export and Termination ---
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) noLoop();
  }
}

void drawLink(AnchorPoint a, AnchorPoint b, float m) {
  if (m < 0.001) {
    line(a.curr.x, a.curr.y, a.curr.z, b.curr.x, b.curr.y, b.curr.z);
  } else {
    // Control point moves based on morphFactor and time
    float midX = (a.curr.x + b.curr.x) / 2;
    float midY = (a.curr.y + b.curr.y) / 2;
    float midZ = (a.curr.z + b.curr.z) / 2;
    
    // Using a fixed time reference within the cycle for the bezier drift
    float t = map(frameCount % CYCLE_DURATION, 0, CYCLE_DURATION, 0, TWO_PI);
    float offset = m * BEZIER_STRENGTH;
    float cx = midX + cos(t + a.ix) * offset;
    float cy = midY + sin(t + b.iy) * offset;
    float cz = midZ + sin(t * 0.5 + a.iz) * offset;

    beginShape();
    vertex(a.curr.x, a.curr.y, a.curr.z);
    quadraticVertex(cx, cy, cz, b.curr.x, b.curr.y, b.curr.z);
    endShape();
  }
}

class AnchorPoint {
  PVector origin, curr;
  int ix, iy, iz;

  AnchorPoint(float x, float y, float z, int ix, int iy, int iz) {
    this.origin = new PVector(x, y, z);
    this.curr = new PVector(x, y, z);
    this.ix = ix; this.iy = iy; this.iz = iz;
  }

  void update(float m) {
    // Tie oscillation frequency to the loop cycle
    float t = map(frameCount % CYCLE_DURATION, 0, CYCLE_DURATION, 0, TWO_PI);
    
    // Scale wobble by morphFactor 'm' so it reaches 0 at the loop point
    float nX = sin(t * 2 + iy) * 30 * m;
    float nY = cos(t * 2 + ix) * 30 * m;
    float nZ = sin(t + (ix + iy)) * 40 * m;
    
    curr.set(origin.x + nX, origin.y + nY, origin.z + nZ);
  }

  void display() {
    pushMatrix();
    translate(curr.x, curr.y, curr.z);
    fill(PALETTES[PALETTE_INDEX][3]);
    noStroke();
    sphere(SPHERE_SIZE);
    popMatrix();
  }
}
