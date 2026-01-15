/**
 * Unexpected Path: Color Burst Glow
 * Version: 2026.01.14.16.24.45
 * Agent moves to least visited neighbor.
 * Circles grow persistently. Glow triggers only on color change
 * and decays quickly on the main canvas.
 */

// --- Parameters ---
int SKETCH_WIDTH = 480;      // Default: 480
int SKETCH_HEIGHT = 800;     // Default: 800
int SEED_VALUE = 42;         // Default: 42
int PADDING = 40;            // Default: 40
int GRID_SIZE = 40;          // Default: 25
int START_RADIUS = 5;        // Default: 5
int MAX_FRAMES = 900;        // Default: 900
boolean SAVE_FRAMES = false; // Default: false
int ANIMATION_SPEED = 60;    // Default: 60
boolean SHOW_GRID = false;   // Default: false
boolean INVERT_COLORS = false; // Default: false
float DECAY_RATE = 20;       // Default: 20
boolean ENABLE_GLOW = true;  // Default: true
int GLOW_STEPS = 3;          // Default: 8

// Palette Selection
int PALETTE_INDEX = 4;       
int[][] PALETTES = {
  {0xFF2E4057, 0xFF88D9E6, 0xFFF4D35E, 0xFFEE964B, 0xFFF95738}, 
  {0xFF264653, 0xFF2A9D8F, 0xFFE9C46A, 0xFFF4A261, 0xFFE76F51}, 
  {0xFF1A535C, 0xFF4ECDC4, 0xFFF7FFF7, 0xFFFF6B6B, 0xFFFFE66D}, 
  {0xFF5F0F40, 0xFF9A031E, 0xFFFB8B24, 0xFFE36414, 0xFF0F4C5C}, 
  {0xFF03071E, 0xFF370617, 0xFF9D0208, 0xFFFAA307, 0xFFFFBA08}  
};

// --- Internal Variables ---
PGraphics circleLayer;
int[][] grid;
int cols, rows;
int curX, curY;
int prevX, prevY;
int bgCol, strokeCol;
int[] activePalette;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  randomSeed(SEED_VALUE);
  frameRate(ANIMATION_SPEED);
  
  activePalette = PALETTES[PALETTE_INDEX];
  bgCol = INVERT_COLORS ? activePalette[4] : activePalette[0];
  strokeCol = INVERT_COLORS ? activePalette[0] : activePalette[2];
  
  cols = (width - (PADDING * 2)) / GRID_SIZE;
  rows = (height - (PADDING * 2)) / GRID_SIZE;
  grid = new int[cols][rows];
  
  circleLayer = createGraphics(width, height);
  circleLayer.beginDraw();
  circleLayer.background(bgCol, 0); 
  circleLayer.ellipseMode(RADIUS);
  circleLayer.endDraw();
  
  curX = cols / 2;
  curY = rows / 2;
  prevX = curX;
  prevY = curY;
  
  background(bgCol);
  ellipseMode(RADIUS);
}

void draw() {
  // 1. Render persistent circles from buffer
  image(circleLayer, 0, 0);

  // 2. Apply decay to main canvas (affects lines and bursts)
  noStroke();
  fill(bgCol, DECAY_RATE);
  rect(0, 0, width, height);

  pushMatrix();
  translate(PADDING, PADDING);

  if (SHOW_GRID) {
    drawGridStructure();
  }

  moveAgent();
  
  // Logic: Check if we are revisiting to trigger glow
  int visits = grid[curX][curY];
  int paletteSize = activePalette.length - 1;
  
  // Trigger glow burst on the main canvas so it decays
  if (ENABLE_GLOW && visits > 1) {
    drawGlowBurst(visits, paletteSize);
  }
  
  // Update the permanent circle buffer
  updateCircleLayer(visits, paletteSize);
  
  // Draw the decaying path connection
  drawConnection();
  
  popMatrix();

  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) {
      noLoop();
    }
  }
}

void moveAgent() {
  prevX = curX;
  prevY = curY;
  
  int bestX = curX;
  int bestY = curY;
  int minVisits = Integer.MAX_VALUE;

  int[] dx = {0, 0, -1, 1};
  int[] dy = {-1, 1, 0, 0};

  int[] indices = {0, 1, 2, 3};
  for (int i = 0; i < 4; i++) {
    int r = int(random(4));
    int temp = indices[r];
    indices[r] = indices[i];
    indices[i] = temp;
  }

  for (int i : indices) {
    int nx = curX + dx[i];
    int ny = curY + dy[i];

    if (nx >= 0 && nx < cols && ny >= 0 && ny < rows) {
      if (grid[nx][ny] < minVisits) {
        minVisits = grid[nx][ny];
        bestX = nx;
        bestY = ny;
      }
    }
  }

  curX = bestX;
  curY = bestY;
  grid[curX][curY]++;
}

void drawGlowBurst(int visits, int paletteSize) {
  int colIdx = 1 + ((visits - 1) % paletteSize);
  int burstCol = activePalette[colIdx];
  float currentRadius = START_RADIUS + (visits - 1);
  
  float centerX = curX * GRID_SIZE + (GRID_SIZE / 2.0);
  float centerY = curY * GRID_SIZE + (GRID_SIZE / 2.0);
  
  noStroke();
  for (int i = GLOW_STEPS; i > 0; i--) {
    float glowRadius = currentRadius + (i * 5);
    float alpha = map(i, 0, GLOW_STEPS, 100, 10);
    fill(burstCol, alpha);
    circle(centerX, centerY, glowRadius);
  }
}

void updateCircleLayer(int visits, int paletteSize) {
  float currentRadius = START_RADIUS + (visits - 1);
  int colIdx = 1 + ((visits - 1) % paletteSize);
  int baseCol = activePalette[colIdx];
  
  circleLayer.beginDraw();
  circleLayer.pushMatrix();
  circleLayer.translate(PADDING, PADDING);
  circleLayer.noStroke();
  circleLayer.fill(baseCol);
  
  float centerX = curX * GRID_SIZE + (GRID_SIZE / 2.0);
  float centerY = curY * GRID_SIZE + (GRID_SIZE / 2.0);
  
  circleLayer.circle(centerX, centerY, currentRadius);
  circleLayer.popMatrix();
  circleLayer.endDraw();
}

void drawConnection() {
  stroke(strokeCol, 255);
  strokeWeight(2);
  
  float x1 = prevX * GRID_SIZE + (GRID_SIZE / 2.0);
  float y1 = prevY * GRID_SIZE + (GRID_SIZE / 2.0);
  float x2 = curX * GRID_SIZE + (GRID_SIZE / 2.0);
  float y2 = curY * GRID_SIZE + (GRID_SIZE / 2.0);
  
  line(x1, y1, x2, y2);
}

void drawGridStructure() {
  stroke(strokeCol, 20);
  strokeWeight(1);
  for (int i = 0; i <= cols; i++) {
    line(i * GRID_SIZE, 0, i * GRID_SIZE, rows * GRID_SIZE);
  }
  for (int j = 0; j <= rows; j++) {
    line(0, j * GRID_SIZE, cols * GRID_SIZE, j * GRID_SIZE);
  }
}
