/**
 * Vector Field Cellular Automata - Pattern Emergence Edition
 * Uses a blend of neighbor alignment and Perlin noise to generate
 * flowing, fluid-like structures.
 */

// --- Parameters ---
int SKETCH_WIDTH = 480;      // default: 480
int SKETCH_HEIGHT = 800;     // default: 800
int PADDING = 20;            // default: 40
int SEED = 6789;             // default: 12345
int MAX_FRAMES = 900;        // default: 900
boolean SAVE_FRAMES = true; // default: false
int ANIMATION_SPEED = 60;    // default: 30 (increased for smoother flow)

// Grid Configuration
int COLS = 40;               // Number of columns (higher for detail)
int ROWS = 70;               // Number of rows
float NEIGHBOR_INFLUENCE = 0.12; // 0.0 to 1.0
float CURVATURE = 0.01;      // Rotational force over time
float NOISE_SCALE = 0.08;    // Scale of the underlying Perlin field
boolean SHOW_GRID = false;   // default: false

// Visuals
float VECTOR_LENGTH_MULT = 1.2;  // Overlapping vectors create texture
float STROKE_WEIGHT = 1.5;       
boolean INVERT_BACKGROUND = false; 

// 5 Color Palettes (Adobe Kuler)
String[][] PALETTES = {
  {"#023047", "#219EBC", "#8ECAE6", "#FFB703", "#FB8500"}, // Deep Sea
  {"#264653", "#2A9D8F", "#E9C46A", "#F4A261", "#E76F51"}, // Terra Cotta
  {"#1A1A1A", "#4E4E4E", "#FFFFFF", "#8A8A8A", "#CCCCCC"}, // Monochromatic
  {"#5F0F40", "#9A031E", "#FB8B24", "#E36414", "#0F4C5C"}, // Sunset Fire
  {"#22223B", "#4A4E69", "#9A8C98", "#C9ADA7", "#F2E9E4"}  // Muted Lavender
};
int ACTIVE_PALETTE = 2; // Range: 0 - 4

// --- Internal Variables ---
Cell[][] grid;
int bg_color;
color[] current_colors;
float cellW, cellH;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  randomSeed(SEED);
  noiseSeed(SEED);
  frameRate(ANIMATION_SPEED);
  
  // Initialize current colors from palette
  current_colors = new color[PALETTES[ACTIVE_PALETTE].length];
  for (int i = 0; i < PALETTES[ACTIVE_PALETTE].length; i++) {
    current_colors[i] = unhex("FF" + PALETTES[ACTIVE_PALETTE][i].substring(1));
  }

  if (INVERT_BACKGROUND) {
    bg_color = color(255);
    current_colors[0] = color(20); // Force dark ink for contrast
  } else {
    bg_color = current_colors[0];
  }

  float availableW = width - (2 * PADDING);
  float availableH = height - (2 * PADDING);
  cellW = availableW / COLS;
  cellH = availableH / ROWS;

  grid = new Cell[COLS][ROWS];
  for (int i = 0; i < COLS; i++) {
    for (int j = 0; j < ROWS; j++) {
      grid[i][j] = new Cell(i, j);
    }
  }
}

void draw() {
  background(bg_color);
  translate(PADDING, PADDING);

  // 1. Update states
  for (int i = 0; i < COLS; i++) {
    for (int j = 0; j < ROWS; j++) {
      grid[i][j].calculateNextState();
    }
  }

  // 2. Apply and Render
  for (int i = 0; i < COLS; i++) {
    for (int j = 0; j < ROWS; j++) {
      grid[i][j].apply();
      grid[i][j].display();
    }
  }

  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) noLoop();
  }
}

// --- Cell Class ---
class Cell {
  int xIdx, yIdx;
  float angle;
  float nextAngle;
  float noiseOffset;

  Cell(int x, int y) {
    xIdx = x;
    yIdx = y;
    // Base angle influenced by position to create initial structure
    angle = noise(x * NOISE_SCALE, y * NOISE_SCALE) * TWO_PI;
    noiseOffset = random(1000);
  }

  void calculateNextState() {
    float sumSin = 0;
    float sumCos = 0;
    int count = 0;

    // Neighbor wrap-around logic
    for (int i = -1; i <= 1; i++) {
      for (int j = -1; j <= 1; j++) {
        if (i == 0 && j == 0) continue;
        int ni = (xIdx + i + COLS) % COLS;
        int nj = (yIdx + j + ROWS) % ROWS;

        sumSin += sin(grid[ni][nj].angle);
        sumCos += cos(grid[ni][nj].angle);
        count++;
      }
    }

    float avgAngle = atan2(sumSin / count, sumCos / count);
    
    // Pattern Emergence: Mix neighbor alignment with local curl
    nextAngle = lerpAngle(angle, avgAngle, NEIGHBOR_INFLUENCE);
    nextAngle += CURVATURE; // Constant "spin"
    
    // Add micro-turbulence using Perlin noise
    float n = noise(xIdx * NOISE_SCALE, yIdx * NOISE_SCALE, frameCount * 0.01);
    nextAngle += map(n, 0, 1, -0.05, 0.05);
  }

  void apply() {
    angle = nextAngle;
  }

  void display() {
    float px = xIdx * cellW + cellW/2;
    float py = yIdx * cellH + cellH/2;

    if (SHOW_GRID) {
      stroke(current_colors[1], 30);
      noFill();
      rect(xIdx * cellW, yIdx * cellH, cellW, cellH);
    }

    pushMatrix();
    translate(px, py);
    rotate(angle);
    
    // Map angle to color index (excluding background color at index 0)
    float colorSelect = map(sin(angle + frameCount * 0.02), -1, 1, 1, current_colors.length - 1);
    int c1 = floor(colorSelect);
    int c2 = ceil(colorSelect) % current_colors.length;
    if (c2 == 0) c2 = 1; 
    
    color finalC = lerpColor(current_colors[c1], current_colors[c2], colorSelect - c1);
    
    stroke(finalC, 180);
    strokeWeight(STROKE_WEIGHT);
    
    float len = (cellW < cellH ? cellW : cellH) * VECTOR_LENGTH_MULT;
    // Draw vectors with a slight curve or offset for "water" feel
    line(-len/2, 0, len/2, 0);
    
    // Visual tip
    strokeWeight(STROKE_WEIGHT * 1.5);
    point(len/2, 0);
    
    popMatrix();
  }

  float lerpAngle(float a, float b, float t) {
    float diff = b - a;
    while (diff < -PI) diff += TWO_PI;
    while (diff > PI) diff -= TWO_PI;
    return a + diff * t;
  }
}
