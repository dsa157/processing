/**
 * The Digital Loom: Chromatic Impressions
 * Weaving simulation where deforming circular blobs apply palette-based colors 
 * and physical displacement to the textile grid.
 */

// --- Configuration Parameters ---
int SKETCH_WIDTH = 480;       // Default: 480
int SKETCH_HEIGHT = 800;      // Default: 800
int SEED = 42;                // Global random/noise seed
int PADDING = 40;             // Canvas padding: 40
int MAX_FRAMES = 900;         // Animation limit: 900
boolean SAVE_FRAMES = false;  // Save frames to disk: false
int ANIMATION_SPEED = 30;     // Frame rate: 30

float NOISE_SCALE = 0.05;     // Weave complexity: 0.05
int GRID_RES = 10;            // Space between threads: 10
float THREAD_WEIGHT = 8.0;    // Line thickness: 8.0
boolean SHOW_GRID = false;    // Hide debug grid: false
boolean INVERT_BG = false;    // Background inversion: false

// Interaction Parameters
int CIRCLE_CHANCE = 10;       // 1 in 40 chance to spawn
float DECAY_RATE = 5.5;       // Decay speed: 1.5
float ELASTICITY = 25.0;      // Max displacement: 25.0
float EFFECT_RADIUS = 100.0;  // Area of effect: 140.0

// Color Palette (Adobe Color)
String[] HEX_PALETTE = {
  "#264653", // Charcoal (BG)
  "#f4a261", // Sandy Brown
  "#2a9d8f", // Persian Green
  "#e9c46a", // Saffron
  "#e76f51"  // Burnt Sienna
};

int BG_COLOR_INDEX = 0; 
ArrayList<Impression> circles;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  randomSeed(SEED);
  noiseSeed(SEED);
  frameRate(ANIMATION_SPEED);
  circles = new ArrayList<Impression>();
  
  color bgColor = getPaletteColor(BG_COLOR_INDEX);
  background(INVERT_BG ? 255 - bgColor : bgColor);
}

void draw() {
  color bgColor = getPaletteColor(BG_COLOR_INDEX);
  background(INVERT_BG ? 255 - bgColor : bgColor);

  int innerW = width - (PADDING * 2);
  int innerH = height - (PADDING * 2);
  
  // Update Impressions
  if (random(CIRCLE_CHANCE) < 1) {
    int randomColorIdx = floor(random(1, HEX_PALETTE.length));
    circles.add(new Impression(random(PADDING, width - PADDING), random(PADDING, height - PADDING), randomColorIdx));
  }
  
  for (int i = circles.size() - 1; i >= 0; i--) {
    Impression c = circles.get(i);
    c.update();
    if (c.isDead()) circles.remove(i);
  }
  
  // Render Weave
  pushMatrix();
  translate(PADDING, PADDING);
  renderLoom(innerW, innerH);
  if (SHOW_GRID) drawDebugGrid(innerW, innerH);
  popMatrix();

  // Render Blobs (Optional: set to very low alpha or hide to see only thread tinting)
  for (Impression c : circles) {
    c.display();
  }

  // Lifecycle Management
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) noLoop();
  }
}

void renderLoom(int w, int h) {
  strokeWeight(THREAD_WEIGHT);
  strokeCap(PROJECT);
  float t = frameCount * 0.02;

  for (int x = 0; x < w; x += GRID_RES) {
    for (int y = 0; y < h; y += GRID_RES) {
      
      float dispX = 0;
      float dispY = 0;
      
      // Determine base thread colors
      color baseH = getPaletteColor(2); // Saffron
      color baseV = getPaletteColor(3); // Sandy Brown
      
      color targetH = baseH;
      color targetV = baseV;
      float totalInfluence = 0;

      // Interaction Logic: Displacement and Color Blending
      for (Impression c : circles) {
        float d = dist(x + PADDING, y + PADDING, c.x, c.y);
        if (d < EFFECT_RADIUS) {
          float pct = map(d, 0, EFFECT_RADIUS, 1.0, 0);
          float alphaFactor = c.opacity / 200.0;
          float influence = pct * alphaFactor;
          
          float angle = atan2((y + PADDING) - c.y, (x + PADDING) - c.x);
          dispX += cos(angle) * influence * ELASTICITY;
          dispY += sin(angle) * influence * ELASTICITY;
          
          // Blend thread color toward blob color
          targetH = lerpColor(targetH, getPaletteColor(c.colorIdx), influence);
          targetV = lerpColor(targetV, getPaletteColor(c.colorIdx), influence);
        }
      }

      float n = noise((x + dispX) * NOISE_SCALE, (y + dispY) * NOISE_SCALE, t);
      
      if (n > 0.5) {
        drawHLine(x + dispX, y + dispY, GRID_RES, targetH);
        drawVLine(x + dispX, y + dispY, GRID_RES, targetV);
      } else {
        drawVLine(x + dispX, y + dispY, GRID_RES, targetV);
        drawHLine(x + dispX, y + dispY, GRID_RES, targetH);
      }
    }
  }
}

void drawHLine(float x, float y, float sz, color c) {
  stroke(c);
  line(x, y + sz/2, x + sz, y + sz/2);
}

void drawVLine(float x, float y, float sz, color c) {
  stroke(c);
  line(x + sz/2, y, x + sz/2, y + sz);
}

color getPaletteColor(int index) {
  int idx = index % HEX_PALETTE.length;
  return unhex("FF" + HEX_PALETTE[idx].substring(1));
}

void drawDebugGrid(int w, int h) {
  stroke(255, 30);
  strokeWeight(1);
  for (int x = 0; x <= w; x += GRID_RES) line(x, 0, x, h);
  for (int y = 0; y <= h; y += GRID_RES) line(0, y, w, y);
}

class Impression {
  float x, y, opacity, diameter;
  int colorIdx;

  Impression(float tx, float ty, int cIdx) {
    x = tx;
    y = ty;
    colorIdx = cIdx;
    opacity = 200; 
    diameter = random(60, 120);
  }

  void update() {
    opacity -= DECAY_RATE;
  }

  void display() {
    noStroke();
    // Low alpha fill so the "blob" itself is subtle, emphasizing the thread color change
    fill(getPaletteColor(colorIdx), opacity * 0.2);
    ellipse(x, y, diameter, diameter);
  }

  boolean isDead() {
    return opacity <= 0;
  }
}
