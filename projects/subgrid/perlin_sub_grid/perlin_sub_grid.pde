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
final color GRID_LINE_COLOR = #333333;
final float GRID_LINE_STROKE_WEIGHT = 0.5;

// Flow Field
final int NUM_POINTS_PER_CELL = 200;
final float POINT_SPEED = 2.5;
final float NOISE_SCALE = 0.0005;
final int MAX_POINT_AGE = 250;
final color FLOW_COLOR = #FFFFFF;

// Frames and Seed
final int MAX_FRAMES = 600;
final boolean SAVE_FRAMES = false;
final int SEED = 12345;

// ==========================================================
// Global Variables
// ==========================================================

int cellWidth, cellHeight;
color bgColor;
GridCell[][] grid;

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

  FlowPoint(float x, float y) {
    this.pos = new PVector(x, y);
    this.prevPos = pos.copy();
    this.age = 0;
  }

  void update(float cellX, float cellY, float cellW, float cellH, float flowSeedX, float flowSeedY) {
    prevPos.set(pos);

    float angle = noise((pos.x + flowSeedX) * NOISE_SCALE, (pos.y + flowSeedY) * NOISE_SCALE, frameCount * 0.001) * TWO_PI * 4;
    PVector vel = PVector.fromAngle(angle);
    vel.mult(POINT_SPEED);
    pos.add(vel);

    if (pos.x < cellX || pos.x > cellX + cellW || pos.y < cellY || pos.y > cellY + cellH) {
      pos.set(random(cellX, cellX + cellW), random(cellY, cellY + cellH));
      prevPos.set(pos);
      age = 0;
    }
    age++;
  }

  void draw() {
    stroke(FLOW_COLOR, map(age, 0, MAX_POINT_AGE, 255, 0));
    strokeWeight(1);
    line(prevPos.x, prevPos.y, pos.x, pos.y);
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
}

// ==========================================================
// Draw Loop
// ==========================================================

void draw() {
  background(bgColor);

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
