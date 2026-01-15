/**
 * Centrosymmetric Spiral Interlock - "Greedy Coloring & Perfect Bleed"
 * Version: 2026.01.10.15.42.15
 */

// --- Global Parameters ---
int SKETCH_WIDTH = 480;       // Default: 480
int SKETCH_HEIGHT = 800;      // Default: 800
int RANDOM_SEED = 12345;        // Default: 480
int PADDING = 40;             // Default: 40
int MAX_FRAMES = 900;         // Default: 900
boolean SAVE_FRAMES = false;  // Default: false
int ANIMATION_SPEED = 30;     // Default: 30
int PALETTE_INDEX = 0;        // Default: 0
boolean INVERT_BG = false;    // Default: false
boolean SHOW_GRID = false;    // Default: false

// --- Design Parameters ---
float HEX_RADIUS = 55.0;      // Default: 55.0
float SPIRAL_INTENSITY = 0.6; // Default: 0.6
float PULSE_SPEED = 0.06;     // Default: 0.06
boolean DROP_SHADOW = false;  // Default: false
float SHADOW_OFFSET = 4.0;    // Default: 4.0
int SHADOW_ALPHA = 120;       // Default: 120

// --- Color Palettes ---
String[][] PALETTES = {
  {"#1B262C", "#0F4C75", "#3282B8", "#BBE1FA", "#FFFFFF"}, 
  {"#2D4059", "#EA5455", "#F07B3F", "#FFD460", "#EEEEEE"}, 
  {"#222831", "#393E46", "#00ADB5", "#EEEEEE", "#FFD369"}, 
  {"#40514E", "#30E3CA", "#11999E", "#E4F1FE", "#F5F5F5"}, 
  {"#543864", "#FF6363", "#FFBD69", "#FF9A3C", "#202040"}  
};

color[] activePalette;
color backgroundColor;
int[][] colorGrid; 
int gridRows, gridCols;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  randomSeed(RANDOM_SEED);
  frameRate(ANIMATION_SPEED);
  
  activePalette = new color[5];
  for (int i = 0; i < 5; i++) {
    activePalette[i] = unhex("FF" + PALETTES[PALETTE_INDEX][i].substring(1));
  }
  
  backgroundColor = INVERT_BG ? activePalette[3] : activePalette[0];
  
  // Hex Grid Dimensions
  float vertDist = HEX_RADIUS * 1.5;
  float horizDist = sqrt(3) * HEX_RADIUS;
  
  // Buffers for full coverage (Overscan)
  gridRows = ceil(SKETCH_HEIGHT / vertDist) + 6; 
  gridCols = ceil(SKETCH_WIDTH / horizDist) + 6;
  
  initializeColorGrid();
}

/**
 * Greedy Map Coloring for Hexagonal Lattice.
 * Ensures randomized appearance while preventing adjacent tiles from having the same color.
 */
void initializeColorGrid() {
  colorGrid = new int[gridRows][gridCols];
  for (int r = 0; r < gridRows; r++) {
    for (int c = 0; c < gridCols; c++) {
      IntList available = new IntList();
      // Indices 1-4 are the decorative colors (0 is background)
      for (int i = 1; i < activePalette.length; i++) {
        available.append(i);
      }
      
      // Check neighbors in a hex grid context (top, left, and diagonal neighbors)
      if (r > 0) available.removeValue(colorGrid[r-1][c]);
      if (c > 0) available.removeValue(colorGrid[r][c-1]);
      if (r > 0 && c > 0) available.removeValue(colorGrid[r-1][c-1]);
      if (r > 0 && c < gridCols - 1) available.removeValue(colorGrid[r-1][c+1]);
      
      if (available.size() > 0) {
        available.shuffle();
        colorGrid[r][c] = available.get(0);
      } else {
        // Fallback to random if constraints are too tight
        colorGrid[r][c] = floor(random(1, activePalette.length));
      }
    }
  }
}

void draw() {
  background(backgroundColor);
  
  float time = frameCount * PULSE_SPEED;
  float morph = map(sin(time), -1, 1, 0.5, 1.2);
  
  float vertDist = HEX_RADIUS * 1.5;
  float horizDist = sqrt(3) * HEX_RADIUS;
  
  pushMatrix();
  // Move origin back significantly to cover left/top margins
  translate(-horizDist * 1.5, -vertDist * 1.5); 
  
  for (int r = 0; r < gridRows; r++) {
    for (int c = 0; c < gridCols; c++) {
      float x = c * horizDist + (r % 2 == 0 ? 0 : horizDist / 2);
      float y = r * vertDist;
      
      pushMatrix();
      translate(x, y);
      
      int colIdx = colorGrid[r][c];
      drawTightSpiral(HEX_RADIUS, activePalette[colIdx], morph);
      
      popMatrix();
    }
  }
  popMatrix();
  
  // Save Frames and Loop Management
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) noLoop();
  }
}

/**
 * Draws a tile with centrosymmetric edges: f(t) = -f(1-t).
 * This ensures the complex "limbs" always fit perfectly into neighboring sockets.
 */
void drawTightSpiral(float radius, color c, float morph) {
  fill(c);
  if (SHOW_GRID) stroke(255, 60); else noStroke();
  
  beginShape();
  for (int i = 0; i < 6; i++) {
    float angle1 = PI/3 * i - PI/6;
    float angle2 = PI/3 * (i + 1) - PI/6;
    
    float x1 = cos(angle1) * radius;
    float y1 = sin(angle1) * radius;
    float x2 = cos(angle2) * radius;
    float y2 = sin(angle2) * radius;
    
    // Sampling for curvature
    for (float step = 0; step <= 1.0; step += 0.04) {
      float tx = lerp(x1, x2, step);
      float ty = lerp(y1, y2, step);
      
      float normalAngle = angle1 + PI/2;
      float offset = calculateSpiral(step, morph);
      
      vertex(tx + cos(normalAngle) * offset, ty + sin(normalAngle) * offset);
    }
  }
  endShape(CLOSE);
}

/**
 * Harmonic function maintaining point-symmetry at t=0.5.
 */
float calculateSpiral(float t, float morph) {
  float amp = HEX_RADIUS * SPIRAL_INTENSITY * morph;
  float spiral = sin(t * TWO_PI);
  float harmonic = 0.2 * sin(t * 4 * PI);
  return (spiral + harmonic) * amp;
}
