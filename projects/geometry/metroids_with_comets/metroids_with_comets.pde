// 2025.11.29.12.24.00
// Version: 2.8 (Comet trail and head are background colored)

// --- Parameters ---
final int SKETCH_WIDTH = 480;  // default: 800 -> Changed to 480
final int SKETCH_HEIGHT = 800; // default: 800 -> Changed to 800
final int SEED_VALUE = 157751; // default: 42
final int PADDING = 40;        // default: 40
final int MAX_FRAMES = 900;    // default: 900
final int ANIMATION_SPEED = 30; // default: 30 (frames)
final boolean SAVE_FRAMES = false; // default: false
final boolean INVERT_BACKGROUND = false; // default: false
final boolean SHOW_GRID_CELLS = false; // default: false

final int GRID_COLS = 5;       // default: 4 -> Changed to 5
final int GRID_ROWS = 7;       // default: 6 -> Changed to 7
final float CUBE_SCALE = 0.70; // default: 0.5 -> Changed to 0.70
final float MAX_ROTATION_SPEED = 0.01; // default: 0.05 (radians per frame)
final float COLOR_CYCLE_SPEED = 0.005; // default: 0.005
final float LINE_STROKE_WEIGHT = 1.0; // default: 1.5 -> Slightly thinner line for density
final float RADIAL_COLOR_OFFSET = 1.75; // default: 1.0 -> Increased for stronger phase difference

// --- Comet Parameters ---
final int MAX_COMETS = 17;      // default: 5
final float COMET_SPEED_FACTOR = 0.05; // default: 0.05 (controls speed of travel)
final int COMET_TRAIL_LENGTH = 15; // default: 15 (number of points in the trail)
final float COMET_SIZE_FACTOR = 0.75; // default: 1.0 -> Made smaller

// Unified Palette (Used by both Cubes and Comets)
final int[] COOL_ELECTRIC_PALETTE = {
  #1C2A39, // 0: BG (Deep Blue/Black)
  #00FFFF, // 1: Pure Cyan
  #00CCFF, // 2: Bright Sky Blue
  #CC00FF, // 3: Vibrant Magenta
  #FFAA00, // 4: Bright Orange
  #FFFFFF  // 5: Pure White
};

int[] PALETTE = COOL_ELECTRIC_PALETTE; 

final int BACKGROUND_COLOR_INDEX = 0; // Index for the background color

// --- Global Variables ---
int background_color;
int foreground_color;
MetatronCube[][] cubes;
Comet[] comets;
float singleCircleDiameter; // Diameter of the center cube circle

// Variables used in setup/draw for cell dimensions
float g_cellWidth;
float g_cellHeight;

// --- Setup ---
void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  randomSeed(SEED_VALUE);
  
  // Set colors (Background is constant)
  int base_bg = PALETTE[BACKGROUND_COLOR_INDEX % PALETTE.length];
  
  if (INVERT_BACKGROUND) {
    colorMode(RGB);
    background_color = color(255 - red(base_bg), 255 - green(base_bg), 255 - blue(base_bg));
    foreground_color = base_bg;
  } else {
    background_color = base_bg;
    foreground_color = #FFFFFF; // A contrasting color for lines/circles
  }
  
  // Calculate and store cell dimensions globally
  g_cellWidth = (float)(SKETCH_WIDTH - 2 * PADDING) / GRID_COLS;
  g_cellHeight = (float)(SKETCH_HEIGHT - 2 * PADDING) / GRID_ROWS;

  // Set up the grid of cubes
  cubes = new MetatronCube[GRID_ROWS][GRID_COLS];
  float maxRadius = min(g_cellWidth, g_cellHeight) * 0.5 * CUBE_SCALE;
  
  // Calculate the diameter of the cube's central circle
  singleCircleDiameter = maxRadius; 

  for (int r = 0; r < GRID_ROWS; r++) {
    for (int c = 0; c < GRID_COLS; c++) {
      float centerX = PADDING + c * g_cellWidth + g_cellWidth / 2;
      float centerY = PADDING + r * g_cellHeight + g_cellHeight / 2;
      
      float colorOffset = random(PALETTE.length); 
      
      // --- Rotation Logic ---
      float baseSpeed = random(MAX_ROTATION_SPEED * 0.5, MAX_ROTATION_SPEED);
      float rotationSpeed;
      
      if (r % 2 == 0) {
        rotationSpeed = (c % 2 == 0) ? baseSpeed : -baseSpeed;
      } else {
        rotationSpeed = (c % 2 == 0) ? -baseSpeed : baseSpeed;
      }
      
      cubes[r][c] = new MetatronCube(centerX, centerY, maxRadius, colorOffset, rotationSpeed);
    }
  }
  
  // --- Comet Setup ---
  comets = new Comet[MAX_COMETS];
  PVector[][] initialOccupied = new PVector[MAX_COMETS][2]; 
  
  for (int i = 0; i < MAX_COMETS; i++) {
    PVector startPos, endPos;
    
    // Find unique start and end positions
    do {
      int startR = (int)random(GRID_ROWS);
      int startC = (int)random(GRID_COLS);
      startPos = new PVector(cubes[startR][startC].centerX, cubes[startR][startC].centerY);
      
      int endR = (int)random(GRID_ROWS);
      int endC = (int)random(GRID_COLS);
      endPos = new PVector(cubes[endR][endC].centerX, cubes[endR][endC].centerY);
      
      // Check for overlap with existing starts/ends and if start==end
      boolean overlap = false;
      if (PVector.dist(startPos, endPos) < 1.0) { overlap = true; }
      
      for(int j=0; j<i; j++) {
          if (PVector.dist(startPos, initialOccupied[j][0]) < 1.0 || PVector.dist(startPos, initialOccupied[j][1]) < 1.0) { overlap = true; break; }
          if (PVector.dist(endPos, initialOccupied[j][0]) < 1.0 || PVector.dist(endPos, initialOccupied[j][1]) < 1.0) { overlap = true; break; }
      }
      if (!overlap) {
          initialOccupied[i][0] = startPos;
          initialOccupied[i][1] = endPos;
          break;
      }
    } while (true);

    int headColorIndex = (i % (PALETTE.length - 1)) + 1;
    
    comets[i] = new Comet(startPos, endPos, headColorIndex);
  }

  // Use HSB for smooth interpolation
  colorMode(HSB, 360, 100, 100, 100);
  frameRate(ANIMATION_SPEED);
}

// --- Draw Loop ---
void draw() {
  background(background_color);
  
  // Draw the grid and cubes
  for (int r = 0; r < GRID_ROWS; r++) {
    for (int c = 0; c < GRID_COLS; c++) {
      // Use global g_cellWidth/Height for placement
      float cellX = PADDING + c * g_cellWidth;
      float cellY = PADDING + r * g_cellHeight;
      
      if (SHOW_GRID_CELLS) {
        stroke(255, 100);
        noFill();
        rect(cellX, cellY, g_cellWidth, g_cellHeight);
      }
      
      cubes[r][c].update();
      cubes[r][c].display();
    }
  }

  // --- Draw Comets ---
  for (Comet comet : comets) {
    comet.update();
    comet.display();
  }
  
  // --- Frame Saving Logic ---
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) {
      noLoop();
    }
  }
}

// --- MetatronCube Class ---
class MetatronCube {
  float centerX, centerY;
  float radius;
  float colorOffset;
  float currentRotation;
  float rotationSpeed;
  
  MetatronCube(float x, float y, float r, float offset, float rotSpeed) {
    centerX = x;
    centerY = y;
    radius = r;
    colorOffset = offset;
    rotationSpeed = rotSpeed;
    currentRotation = random(TWO_PI);
  }

  void update() {
    currentRotation += rotationSpeed;
  }
  
  int getComponentColor(float cyclePos, float offsetSteps) {
    int numPaletteColors = PALETTE.length; 
    float current_pos = cyclePos + offsetSteps; 
    
    int index1 = (int)floor(current_pos) % numPaletteColors;
    int index2 = (index1 + 1) % numPaletteColors;
    float amt = current_pos - floor(current_pos);
    
    int lerped_color = lerpColor(PALETTE[index1], PALETTE[index2], amt);
    
    float h = hue(lerped_color);
    float s = saturation(lerped_color);
    float b = brightness(lerped_color);
    
    if (offsetSteps == 0.0) return color(h, s * 0.9, b * 1.1, 100); 
    if (offsetSteps == RADIAL_COLOR_OFFSET) return color(h, s * 1.0, b * 1.0, 100); 
    if (offsetSteps == RADIAL_COLOR_OFFSET * 2.0) return color(h, s * 1.1, b * 0.9, 100); 
    if (offsetSteps == RADIAL_COLOR_OFFSET * 3.0) return color(h, s * 1.0, b * 1.1, 100); 
    
    return lerped_color;
  }

  void display() {
    pushMatrix();
    translate(centerX, centerY);
    rotate(currentRotation);

    float baseCyclePosition = (frameCount * COLOR_CYCLE_SPEED + colorOffset);
    
    int inner_circle_color = getComponentColor(baseCyclePosition, 0.0 * RADIAL_COLOR_OFFSET);
    int inner_lines_color = getComponentColor(baseCyclePosition, 1.0 * RADIAL_COLOR_OFFSET);
    int outer_lines_color = getComponentColor(baseCyclePosition, 2.0 * RADIAL_COLOR_OFFSET);
    int outer_circles_color = getComponentColor(baseCyclePosition, 3.0 * RADIAL_COLOR_OFFSET);

    float circleRadius = radius / 2; 
    
    PVector[] points = new PVector[13];
    points[0] = new PVector(0, 0); 

    for (int i = 0; i < 6; i++) {
      float angle = i * TWO_PI / 6.0;
      points[i+1] = PVector.fromAngle(angle).mult(circleRadius * 2); 
    }
    
    for (int i = 0; i < 6; i++) {
      float angle = (i * TWO_PI / 6.0) + (PI / 6.0); 
      points[i+7] = PVector.fromAngle(angle).mult(circleRadius * sqrt(3) * 2); 
    }

    noFill();
    strokeWeight(LINE_STROKE_WEIGHT); 

    // 1. Inner Circle (P0) - Color Pulse Start
    stroke(inner_circle_color);
    ellipse(points[0].x, points[0].y, circleRadius * 2, circleRadius * 2); 

    // 2. Inner Lines
    stroke(inner_lines_color);
    for (int i = 1; i < 13; i++) {
      line(points[0].x, points[0].y, points[i].x, points[i].y);
    }
    
    // 3. Outer Circles
    stroke(outer_circles_color);
    for (int i = 1; i < 13; i++) { 
      ellipse(points[i].x, points[i].y, circleRadius * 2, circleRadius * 2); 
    }

    // 4. Outer Lines
    stroke(outer_lines_color);
    for (int i = 1; i < 13; i++) {
      for (int j = i + 1; j < 13; j++) {
        line(points[i].x, points[i].y, points[j].x, points[j].y);
      }
    }

    popMatrix();
  }
}

// --- Comet Class ---
class Comet {
  PVector startPos;
  PVector endPos;
  PVector currentPos;
  float t; // Time variable (0.0 to 1.0)
  int headColor;
  int headColorIndex;
  
  PVector[] trail; 

  Comet(PVector start, PVector end, int colorIndex) {
    startPos = start.copy();
    endPos = end.copy();
    currentPos = start.copy();
    t = 0.0;
    headColorIndex = colorIndex;
    headColor = PALETTE[headColorIndex];
    
    trail = new PVector[COMET_TRAIL_LENGTH];
    for (int i = 0; i < COMET_TRAIL_LENGTH; i++) {
      trail[i] = start.copy();
    }
  }

  void update() {
    // 1. Update Time variable (move the comet)
    t += COMET_SPEED_FACTOR;
    
    // 2. Continuous Transition Logic
    if (t >= 1.0) {
      startPos = endPos.copy(); 
      endPos = getNewUniqueDestination(startPos);
      t = 0.0; 
      
      headColorIndex = (headColorIndex % (PALETTE.length - 1)) + 1;
      headColor = PALETTE[headColorIndex];
    }
    
    // 3. Interpolate position
    currentPos.x = lerp(startPos.x, endPos.x, t);
    currentPos.y = lerp(startPos.y, endPos.y, t);

    // 4. Update Trail
    for (int i = COMET_TRAIL_LENGTH - 1; i > 0; i--) {
      trail[i] = trail[i - 1];
    }
    trail[0] = currentPos.copy();
  }

  PVector getNewUniqueDestination(PVector exclusionPos) {
    float localCellWidth = g_cellWidth;
    float localCellHeight = g_cellHeight;
    
    PVector newPos = new PVector(0, 0);

    do {
      int newR = (int)random(GRID_ROWS);
      int newC = (int)random(GRID_COLS);
      
      newPos.x = PADDING + newC * localCellWidth + localCellWidth / 2;
      newPos.y = PADDING + newR * localCellHeight + localCellHeight / 2;
    } while (PVector.dist(newPos, exclusionPos) < 1.0); 
    
    return newPos;
  }

  void display() {
    // 1. Draw Trail (fading effect)
    for (int i = 0; i < COMET_TRAIL_LENGTH; i++) {
      PVector p = trail[i];
      if (p == null) continue;

      float alpha = map(i, 0, COMET_TRAIL_LENGTH - 1, 200, 0);
      float trailSize = map(i, 0, COMET_TRAIL_LENGTH - 1, singleCircleDiameter * COMET_SIZE_FACTOR * 0.9, singleCircleDiameter * COMET_SIZE_FACTOR * 0.1);
      
      // Use background_color for the trail
      float h = hue(background_color);
      float s = saturation(background_color);
      float b = brightness(background_color);

      noStroke();
      fill(h, s, b, alpha / 2.55); // Use HSB with alpha (scaled from 0-100)
      ellipse(p.x, p.y, trailSize, trailSize);
    }
    
    // 2. Draw Head
    noStroke(); 
    
    // Use background_color for the head
    float h = hue(background_color);
    float s = saturation(background_color);
    float b = brightness(background_color);
    fill(h, s, b, 100);

    ellipse(currentPos.x, currentPos.y, singleCircleDiameter * COMET_SIZE_FACTOR, singleCircleDiameter * COMET_SIZE_FACTOR);
  }
}
