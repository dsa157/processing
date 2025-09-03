// ==========================================================
// Parameters
// ==========================================================

// Canvas and Grid
final int CANVAS_WIDTH = 480;
final int CANVAS_HEIGHT = 800;
final int PADDING = 40;
final int ROWS = 5;
final int COLS = 3;
final boolean INVERT_BG = false;
final boolean SHOW_GRID_LINES = true;

// Grid Lines
final color GRID_LINE_COLOR = #666666;
final float GRID_LINE_STROKE_WEIGHT = 0.75;

// Flow Field
final int NUM_POINTS_PER_CELL = 200;
final float POINT_SPEED = 1.5;
final float NOISE_SCALE = 0.06;
final int MAX_POINT_AGE = 250;
final color FLOW_COLOR = #FFFFFF;

// Magnet
final float MAGNET_RADIUS = 100;
final float MAGNET_FORCE = 1.5;
final int MAGNET_MOVE_TIME = 120; // Time in frames for each segment
final float MAGNET_CENTER_RADIUS = 5;
final int MAGNET_TRAIL_LENGTH = 30; // Number of points in the trail
final float MAGNET_MINIMUM_DISTANCE = 100;

// Colors
final color MAGNET_ATTRACT_COLOR = #FFFF00;
final float COLOR_DECAY_RATE = 0.05;
final color MAGNET_CENTER_COLOR = #FFFF00;
final color MAGNET_TRAIL_COLOR = #FFFF00;

// Frames and Seed
final int MAX_FRAMES = 600;
final boolean SAVE_FRAMES = false;
final int SEED = 115577;

// ==========================================================
// Global Variables
// ==========================================================

int cellWidth, cellHeight;
color bgColor;
GridCell[][] grid;
Magnet magnet;

// ==========================================================
// Classes
// ==========================================================

class GridCell {
  float x, y, w, h;
  int subDivisionType;
  ArrayList<SubGridCell> subCells;

  GridCell(float x, float y, float w, float h, int type) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.subDivisionType = type;
    this.subCells = new ArrayList<SubGridCell>();

    switch (subDivisionType) {
      case 0: // No division
        subCells.add(new SubGridCell(x, y, w, h));
        break;
      case 1: // 2x1 sub grid
        subCells.add(new SubGridCell(x, y, w / 2, h));
        subCells.add(new SubGridCell(x + w / 2, y, w / 2, h));
        break;
      case 2: // 1x2 sub grid
        subCells.add(new SubGridCell(x, y, w, h / 2));
        subCells.add(new SubGridCell(x, y + h / 2, w, h / 2));
        break;
      case 3: // 2x2 sub grid
        subCells.add(new SubGridCell(x, y, w / 2, h / 2));
        subCells.add(new SubGridCell(x + w / 2, y, w / 2, h / 2));
        subCells.add(new SubGridCell(x, y + h / 2, w / 2, h / 2));
        subCells.add(new SubGridCell(x + w / 2, y + h / 2, w / 2, h / 2));
        break;
    }
  }

  void drawGridLines() {
    stroke(GRID_LINE_COLOR);
    strokeWeight(GRID_LINE_STROKE_WEIGHT);
    noFill();
    rect(x, y, w, h);

    for (SubGridCell sc : subCells) {
      rect(sc.x, sc.y, sc.w, sc.h);
    }
  }
}

class SubGridCell {
  float x, y, w, h;
  ArrayList<FlowPoint> points;
  float flowSeedX, flowSeedY;

  SubGridCell(float x, float y, float w, float h) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.points = new ArrayList<FlowPoint>();
    this.flowSeedX = random(1000);
    this.flowSeedY = random(1000);

    for (int i = 0; i < NUM_POINTS_PER_CELL; i++) {
      points.add(new FlowPoint(random(x, x + w), random(y, y + h)));
    }
  }

  void updateAndDraw() {
    for (int i = points.size() - 1; i >= 0; i--) {
      FlowPoint p = points.get(i);
      p.update(this.x, this.y, this.w, this.h, this.flowSeedX, this.flowSeedY);
      p.draw();
      if (p.age > MAX_POINT_AGE) {
        points.remove(i);
      }
    }

    while (points.size() < NUM_POINTS_PER_CELL) {
      points.add(new FlowPoint(random(x, x + w), random(y, y + h)));
    }
  }
}

class FlowPoint {
  PVector pos, prevPos;
  int age;
  color currentColor;

  FlowPoint(float x, float y) {
    this.pos = new PVector(x, y);
    this.prevPos = pos.copy();
    this.age = 0;
    this.currentColor = FLOW_COLOR;
  }

  void update(float cellX, float cellY, float cellW, float cellH, float flowSeedX, float flowSeedY) {
    prevPos.set(pos);

    float noiseAngle = noise((pos.x + flowSeedX) * NOISE_SCALE, (pos.y + flowSeedY) * NOISE_SCALE, frameCount * 0.001) * TWO_PI * 4;
    PVector noiseVel = PVector.fromAngle(noiseAngle);

    PVector magnetVel = new PVector(0, 0);
    float distToMagnet = dist(pos.x, pos.y, magnet.pos.x, magnet.pos.y);

    if (distToMagnet < MAGNET_RADIUS) {
      magnetVel = PVector.sub(magnet.pos, pos);
      magnetVel.normalize();

      PVector combinedVel = PVector.lerp(noiseVel, magnetVel, MAGNET_FORCE);
      combinedVel.normalize();
      combinedVel.mult(POINT_SPEED);
      pos.add(combinedVel);

      currentColor = lerpColor(currentColor, MAGNET_ATTRACT_COLOR, 0.2);
    } else {
      pos.add(noiseVel.mult(POINT_SPEED));
      currentColor = lerpColor(currentColor, FLOW_COLOR, COLOR_DECAY_RATE);
    }

    if (pos.x < cellX || pos.x > cellX + cellW || pos.y < cellY || pos.y > cellY + cellH) {
      pos.set(random(cellX, cellX + cellW), random(cellY, cellY + cellH));
      prevPos.set(pos);
      age = 0;
    }
    age++;
  }

  void draw() {
    stroke(currentColor, map(age, 0, MAX_POINT_AGE, 255, 0));
    strokeWeight(1);
    line(prevPos.x, prevPos.y, pos.x, pos.y);
  }
}

class Magnet {
  PVector pos, startPos, targetPos;
  int startTime;
  ArrayList<PVector> trail;

  Magnet() {
    this.pos = new PVector(random(PADDING, CANVAS_WIDTH - PADDING), random(PADDING, CANVAS_HEIGHT - PADDING));
    this.startPos = pos.copy();
    setNewTarget();
    this.trail = new ArrayList<PVector>();
  }

  void setNewTarget() {
    PVector newTarget;
    float distance;
    do {
      newTarget = new PVector(random(PADDING, CANVAS_WIDTH - PADDING), random(PADDING, CANVAS_HEIGHT - PADDING));
      distance = PVector.dist(pos, newTarget);
    } while (distance < MAGNET_MINIMUM_DISTANCE);

    this.targetPos = newTarget;
    this.startTime = frameCount;
  }

  void update() {
    float timeElapsed = frameCount - startTime;
    float lerpAmount = timeElapsed / MAGNET_MOVE_TIME;

    if (lerpAmount >= 1) {
      startPos = targetPos.copy();
      setNewTarget();
      lerpAmount = 0;
    }

    pos = PVector.lerp(startPos, targetPos, lerpAmount);

    trail.add(pos.copy());
    if (trail.size() > MAGNET_TRAIL_LENGTH) {
      trail.remove(0);
    }
  }

  void draw() {
    // Draw trail
    for (int i = 0; i < trail.size(); i++) {
      float alpha = map(i, 0, trail.size(), 0, 255);
      fill(MAGNET_TRAIL_COLOR, alpha);
      noStroke();
      ellipse(trail.get(i).x, trail.get(i).y, MAGNET_CENTER_RADIUS * 2, MAGNET_CENTER_RADIUS * 2);
    }

    // Draw solid center
    fill(MAGNET_CENTER_COLOR);
    noStroke();
    ellipse(pos.x, pos.y, MAGNET_CENTER_RADIUS * 2, MAGNET_CENTER_RADIUS * 2);
  }
}

// ==========================================================
// Setup
// ==========================================================

void setup() {
  size(480, 800);
  pixelDensity(2);
  smooth(8);
  randomSeed(SEED);

  if (INVERT_BG) {
    bgColor = #ffffff;
  } else {
    bgColor = #000000;
  }

  cellWidth = (CANVAS_WIDTH - 2 * PADDING) / COLS;
  cellHeight = (CANVAS_HEIGHT - 2 * PADDING) / ROWS;

  grid = new GridCell[ROWS][COLS];
  for (int r = 0; r < ROWS; r++) {
    for (int c = 0; c < COLS; c++) {
      int divisionType = (int)random(4);
      grid[r][c] = new GridCell(PADDING + c * cellWidth, PADDING + r * cellHeight, cellWidth, cellHeight, divisionType);
    }
  }

  magnet = new Magnet();
}

// ==========================================================
// Draw Loop
// ==========================================================

void draw() {
  background(bgColor);

  magnet.update();
  magnet.draw();

  for (int r = 0; r < ROWS; r++) {
    for (int c = 0; c < COLS; c++) {
      for (SubGridCell sc : grid[r][c].subCells) {
        sc.updateAndDraw();
      }
    }
  }

  if (SHOW_GRID_LINES) {
    for (int r = 0; r < ROWS; r++) {
      for (int c = 0; c < COLS; c++) {
        grid[r][c].drawGridLines();
      }
    }
  }

  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) {
      noLoop();
    }
  }
}
