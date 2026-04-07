/**
 * Truchet Pulses
 * Version: 2026.04.07.15.26.34
 * Description: A Smith-style Truchet tiling sketch featuring organic pulse behaviors and sound-reactive rotations driven by the Minim library.
 */

import ddf.minim.*;

// --- Global Constants & Canvas Settings ---
int SKETCH_WIDTH = 480;      // 480: default width
int SKETCH_HEIGHT = 800;     // 800: default height

// --- Customizable Parameters ---
String MUSIC_FILE = "islandman.mp3"; // "music.mp3": target audio file
int GRID_COLS = 10;           // 10: number of tiles horizontally
int GRID_ROWS = 18;           // 18: number of tiles vertically
float PADDING = 40.0;        // 40.0: padding around the overall sketch area
float ANIM_INCREMENT = 0.01;  // 0.02: rate of animation progression (t)

// --- Stroke & Pulse Controls ---
float OUTER_STROKE = 10.0;    // 10.0: base thickness of the black outline
float INNER_STROKE = 6.0;     // 6.0: base thickness of the color fill
boolean ENABLE_ROTATION = true; // true: toggle rotation (now music triggered)
boolean PULSE_WIDTHS = true;      // true: enable organic stroke width pulsing
float PULSE_SPEED = 0.8;      // 0.8: speed of the breathing effect
float PULSE_MIN_SCALE = 0.1;  // 0.1: minimum thickness factor
float PULSE_MAX_SCALE = 2.5;  // 2.5: maximum thickness factor
float PULSE_NOISE_SCALE = 0.3; // 0.3: spatial scale for organic pulse variation

int GLOBAL_SEED = 42;         // 42: seed for reproducibility
int PALETTE_INDEX = 1;        // 1: active color palette index (0-6)
boolean INVERT_BACKGROUND = false; // false: toggle to invert background color
boolean SHOW_GRID = false;    // false: show/hide tile grid cells

// --- Animation & Rendering Controls ---
int MAX_FRAMES = 900;        
boolean SAVE_FRAMES = false; 
int ANIMATION_SPEED = 30;    

// --- Color Palettes ---
String[][] HEX_PALETTES = {
  {"#FFFFFF", "#008080", "#000000", "#FFD700", "#FF4500"}, 
  {"#001F3F", "#39CCCC", "#000000", "#7FDBFF", "#01FF70"}, 
  {"#2D4032", "#8B9467", "#000000", "#556B2F", "#EAEAEA"}, 
  {"#FF4136", "#FFDC00", "#000000", "#FF851B", "#0074D9"}, 
  {"#FAD02E", "#D8334A", "#000000", "#F28D35", "#E8A87C"},
  {"#000000", "#999999", "#FFFFFF", "#666666", "#CCCCCC"},
  {"#000000", "#FFFFFF", "#000000", "#FFFFFF", "#000000"}
};

color[] activePalette;
float t = 0;                 
float tileSize;              
float audioLevel = 0;

// Minim objects
Minim minim;
AudioPlayer player;

void setup() {
  size(480, 800); 
  frameRate(ANIMATION_SPEED);
  pixelDensity(displayDensity());
  randomSeed(GLOBAL_SEED);
  noiseSeed(GLOBAL_SEED);
  
  // Setup Sound
  minim = new Minim(this);
  player = minim.loadFile(MUSIC_FILE);
  if (player != null) player.loop();
  
  activePalette = new color[5];
  updatePalette();
  
  float availableW = width - (PADDING * 2);
  tileSize = availableW / (float)GRID_COLS;
}

void updatePalette() {
  int idx = PALETTE_INDEX % 7;
  for (int i = 0; i < 5; i++) {
    activePalette[i] = unhex("FF" + HEX_PALETTES[idx][i].substring(1));
  }
}

void draw() {
  updatePalette();
  
  // Update music level
  if (player != null) {
    audioLevel = player.mix.level(); // Normalized level (0.0 - 1.0)
  }
  
  color bgColor = activePalette[0];
  if (INVERT_BACKGROUND) bgColor = color(255 - red(bgColor), 255 - green(bgColor), 255 - blue(bgColor));
  background(bgColor);
  
  pushMatrix();
  translate(PADDING, PADDING);

  // First pass: Draw the thick black "outer" strokes
  randomSeed(GLOBAL_SEED); 
  for (int x = 0; x < GRID_COLS; x++) {
    for (int y = 0; y < GRID_ROWS; y++) {
      float px = x * tileSize;
      float py = y * tileSize;
      if (py + tileSize > height - (PADDING * 2)) continue;
      
      boolean type = random(1) > 0.5; 
      
      // Calculate organic pulse scale
      float pScale = 1.0;
      if (PULSE_WIDTHS) {
        float noiseVal = noise(x * PULSE_NOISE_SCALE, y * PULSE_NOISE_SCALE, t * PULSE_SPEED);
        pScale = map(noiseVal, 0, 1, PULSE_MIN_SCALE, PULSE_MAX_SCALE);
      }
      
      drawTruchetLayer(px, py, tileSize, type, x, y, activePalette[2], OUTER_STROKE * pScale);
    }
  }

  // Second pass: Draw the "inner" color fill strokes
  randomSeed(GLOBAL_SEED); 
  for (int x = 0; x < GRID_COLS; x++) {
    for (int y = 0; y < GRID_ROWS; y++) {
      float px = x * tileSize;
      float py = y * tileSize;
      if (py + tileSize > height - (PADDING * 2)) continue;
      
      boolean type = random(1) > 0.5; 
      
      // Calculate organic pulse scale (match outer exactly)
      float pScale = 1.0;
      if (PULSE_WIDTHS) {
        float noiseVal = noise(x * PULSE_NOISE_SCALE, y * PULSE_NOISE_SCALE, t * PULSE_SPEED);
        pScale = map(noiseVal, 0, 1, PULSE_MIN_SCALE, PULSE_MAX_SCALE);
      }
      
      drawTruchetLayer(px, py, tileSize, type, x, y, activePalette[1], INNER_STROKE * pScale);
      
      if (SHOW_GRID) {
        stroke(255, 0, 0, 100);
        strokeWeight(1);
        noFill();
        rect(px, py, tileSize, tileSize);
      }
    }
  }
  popMatrix();
  
  t += ANIM_INCREMENT;
  
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) noLoop();
  }
}

void drawTruchetLayer(float x, float y, float s, boolean type, int gridX, int gridY, color strokeC, float weight) {
  pushMatrix();
  translate(x + s/2, y + s/2);
  
  if (ENABLE_ROTATION) {
    // Rotation is now triggered/multiplied by audio level
    float rotAngle = floor(audioLevel * 10.0) * HALF_PI; 
    rotate(rotAngle);
  }
  
  stroke(strokeC);
  strokeWeight(max(0.01, weight)); 
  noFill();
  
  if (type) {
    arc(-s/2, -s/2, s, s, 0, HALF_PI);
    arc(s/2, s/2, s, s, PI, PI + HALF_PI);
  } else {
    arc(s/2, -s/2, s, s, HALF_PI, PI);
    arc(-s/2, s/2, s, s, PI + HALF_PI, TWO_PI);
  }
  
  popMatrix();
}

void stop() {
  if (player != null) player.close();
  if (minim != null) minim.stop();
  super.stop();
}
