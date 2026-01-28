/**
 * Nested HTML Fractals: Advanced DOM Emergence
 * Version: 2026.01.24.16.45.10
 * Deeply nested recursive HTML elements with solid/wireframe toggles.
 */

// --- Parameters ---
int SKETCH_WIDTH = 480;       // default 480
int SKETCH_HEIGHT = 800;      // default 800
int SEED_VALUE = 42;          // default 42
int PADDING = 40;             // default 40
int MAX_FRAMES = 900;         // default 900
boolean SAVE_FRAMES = false;  // default false
int ANIMATION_SPEED = 30;     // default 30
int PALETTE_INDEX = 3;        // default 0-4
boolean INVERT_BACK = false;  // default false
boolean SHOW_GRID = false;    // default false

// Fractal Specific Parameters
int MAX_RECURSION = 15;       // default 15
float ROTATION_AMP = 0.35;    // default 0.35
float SIZE_DECAY = 0.85;      // default 0.85 (updated per request)
float TEXT_SIZE_BASE = 14;    // default 14
boolean SOLID_MODE = true;    // default true
float SOLID_ALPHA = 45;       // default 45 (alpha parameter for solid mode)

String[] TAG_POOL = { 
  "<div>", "<span>", "<header>", "<section>", 
  "<canvas>", "<main>", "<footer>", "<article>", "<a>" 
};

// --- Color Palettes (Adobe Color / Kuler inspired) ---
color[][] PALETTES = {
  {#2E112D, #540032, #820333, #C02F1D, #F22333}, // Deep Reds
  {#03120E, #235E6F, #356EAF, #484794, #281236}, // Deep Sea
  {#1B1B1B, #292929, #F3F3F3, #FF3B3F, #A9A9A9}, // Modern Tech
  {#011627, #FDFFFC, #2EC4B6, #E71D36, #FF9F1C}, // Cyberpunk
  {#264653, #2A9D8F, #E9C46A, #F4A261, #E76F51}  // Earthy
};

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  randomSeed(SEED_VALUE);
  frameRate(ANIMATION_SPEED);
  textAlign(LEFT, TOP);
  textFont(createFont("Courier New", TEXT_SIZE_BASE));
  rectMode(CENTER);
}

void draw() {
  color[] activePalette = PALETTES[PALETTE_INDEX];
  color bgColor = INVERT_BACK ? activePalette[1] : activePalette[0];
  color secondaryColor = INVERT_BACK ? activePalette[0] : activePalette[1];
  
  background(bgColor);
  
  if (SHOW_GRID) {
    drawDebugGrid(secondaryColor);
  }

  pushMatrix();
  translate(width/2, height/2);
  
  // Sine wave drives the rotation oscillation
  float wave = sin(frameCount * 0.015);
  
  // Start Recursion
  drawHTMLFractal(width - (PADDING * 2), MAX_RECURSION, wave);
  
  popMatrix();

  // Handle Export and Termination
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) noLoop();
  }
}

/**
 * Recursive function to draw nested "HTML Tags"
 */
void drawHTMLFractal(float dim, int level, float wave) {
  if (level <= 0) return;

  color[] currentPalette = PALETTES[PALETTE_INDEX];
  color elementColor = currentPalette[level % currentPalette.length];
  
  // Local rotation offset per depth level
  float rot = wave * ROTATION_AMP;
  
  pushMatrix();
  rotate(rot);
  
  // Render logic for the container
  if (SOLID_MODE) {
    noStroke();
    fill(elementColor, SOLID_ALPHA); 
    rect(0, 0, dim, dim);
  } else {
    noFill();
    stroke(elementColor, 200);
    strokeWeight(1);
    rect(0, 0, dim, dim);
  }
  
  // Typography styling
  fill(elementColor);
  float currentTextSize = max(6, TEXT_SIZE_BASE * (level / (float)MAX_RECURSION));
  textSize(currentTextSize);
  
  String openTag = TAG_POOL[level % TAG_POOL.length];
  String closeTag = openTag.replace("<", "</");
  
  // Render tags inside the container boundaries
  text(openTag, -dim/2 + 4, -dim/2 + 4);
  
  float tw = textWidth(closeTag);
  float th = textAscent() + textDescent();
  text(closeTag, dim/2 - tw - 4, dim/2 - th - 4);
  
  // Recursion
  float nextDim = dim * SIZE_DECAY;
  drawHTMLFractal(nextDim, level - 1, wave);
  
  popMatrix();
}

/**
 * Helper to visualize sketch boundaries
 */
void drawDebugGrid(color c) {
  stroke(c, 30);
  for (int i = 0; i <= width; i += 40) line(i, 0, i, height);
  for (int j = 0; j <= height; j += 40) line(0, j, width, j);
}
