/**
 * Header Constellations
 * Focus on Line and Unity using Proximity Triangulation.
 * Parametric control over typography and network density.
 */

// --- Parameters ---
int SKETCH_WIDTH = 480;  // Default 480
int SKETCH_HEIGHT = 800; // Default 800
int PADDING = 40;        // Default 40
int MAX_FRAMES = 900;    // Default 900
boolean SAVE_FRAMES = false; // Default false
int ANIMATION_SPEED = 30; // Default 30
int SEED_VAL = 42;       // Global Seed
boolean INVERT_BG = false; // Toggle background inversion
boolean SHOW_GRID = false; // Toggle grid visibility

// Typography
String FONT_FACE = "SansSerif"; // Default "SansSerif"
int FONT_SIZE = 18;            // Default 10
int TEXT_ALPHA = 200;          // Default 200

// Tag Configuration
int TAG_COUNT = 100;            // Default 50
float MAX_VELOCITY = 1.8;      // Default 0.8
float MIN_VELOCITY = 1.2;      // Default 0.2
float PROXIMITY_LIMIT = 200.0;  // Default 85.0
float STROKE_WEIGHT = 1.75;    // Default 0.75
int LINE_MAX_ALPHA = 180;      // Default 180
int CORE_DOT_SIZE = 2;         // Default 2
int GRID_STEP = 40;            // Default 40
int GRID_ALPHA = 50;           // Default 50

// Palette Index (0-4)
int PALETTE_INDEX = 1;         // Default 1

// HTML Tag Pool
String[] TAG_POOL = {
  "<blockquote>", "<textarea>", "<select>", "<option>", "<div>",
  "<span>", "<code>", "<img>", "<section>", "<footer>", "<header>", "<nav>"
};

// --- Color Palettes (Adobe Color / Kuler) ---
color[][] PALETTES = {
  {#2E112D, #540032, #820333, #C02739, #F1D4D4}, // Crimson Velvet
  {#004445, #2C7873, #6FB98F, #FAF1E6, #FFD800}, // Deep Sea & Gold
  {#1A1A2E, #16213E, #0F3460, #E94560, #FFFFFF}, // Cyberpunk Night
  {#222831, #393E46, #00ADB5, #EEEEEE, #FF5722}, // Modern Dark
  {#F9F7F7, #DBE2EF, #3F72AF, #112D4E, #333333}  // Business Blue
};

ArrayList<TagNode> nodes;
PFont mainFont;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  randomSeed(SEED_VAL);
  frameRate(ANIMATION_SPEED);

  mainFont = createFont(FONT_FACE, FONT_SIZE);
  textFont(mainFont);

  nodes = new ArrayList<TagNode>();
  for (int i = 0; i < TAG_COUNT; i++) {
    float x = random(PADDING, width - PADDING);
    float y = random(PADDING, height - PADDING);
    String label = TAG_POOL[floor(random(TAG_POOL.length))];
    nodes.add(new TagNode(x, y, label));
  }
}

void draw() {
  color[] activePalette = PALETTES[PALETTE_INDEX];
  color bgColor = activePalette[0];
  color strokeColor = activePalette[2];
  color textColor = activePalette[4];

  if (INVERT_BG) {
    bgColor = activePalette[4];
    textColor = activePalette[0];
  }

  background(bgColor);

  if (SHOW_GRID) drawDebugGrid(activePalette[1]);

  // Draw Unity Lines (Proximity Triangulation)
  strokeWeight(STROKE_WEIGHT);
  for (int i = 0; i < nodes.size(); i++) {
    TagNode a = nodes.get(i);
    for (int j = i + 1; j < nodes.size(); j++) {
      TagNode b = nodes.get(j);
      float d = dist(a.pos.x, a.pos.y, b.pos.x, b.pos.y);

      if (d < PROXIMITY_LIMIT) {
        float alpha = map(d, 0, PROXIMITY_LIMIT, LINE_MAX_ALPHA, 0);
        stroke(strokeColor, alpha);
        line(a.pos.x, a.pos.y, b.pos.x, b.pos.y);
      }
    }
  }

  // Update and Draw Tag Nodes
  for (TagNode n : nodes) {
    n.update();
    n.display(textColor);
  }

  // Recording and Loop Control
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) {
      noLoop();
    }
  }
}

void drawDebugGrid(color gridCol) {
  stroke(gridCol, GRID_ALPHA);
  for (int x = PADDING; x <= width - PADDING; x += GRID_STEP) line(x, PADDING, x, height - PADDING);
  for (int y = PADDING; y <= height - PADDING; y += GRID_STEP) line(PADDING, y, width - PADDING, y);
}

class TagNode {
  PVector pos;
  PVector vel;
  String tagLabel;

  TagNode(float x, float y, String label) {
    pos = new PVector(x, y);
    vel = PVector.random2D().mult(random(MIN_VELOCITY, MAX_VELOCITY));
    tagLabel = label;
  }

  void update() {
    pos.add(vel);

    // Bounce boundaries with padding
    if (pos.x < PADDING || pos.x > width - PADDING) vel.x *= -1;
    if (pos.y < PADDING || pos.y > height - PADDING) vel.y *= -1;

    pos.x = constrain(pos.x, PADDING, width - PADDING);
    pos.y = constrain(pos.y, PADDING, height - PADDING);
  }

  void display(color c) {
    fill(c, TEXT_ALPHA);
    textAlign(CENTER, CENTER);
    text(tagLabel, pos.x, pos.y);

    noStroke();
    fill(c, LINE_MAX_ALPHA / 2);
    ellipse(pos.x, pos.y, CORE_DOT_SIZE, CORE_DOT_SIZE);
  }
}
