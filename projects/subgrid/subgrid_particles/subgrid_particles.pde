// Grid and Particle Parameters
int COLS = 3;
int ROWS = 5;
int PADDING = 40;
float GRIDLINE_WEIGHT = 1.0;
color GRIDLINE_COLOR = #555555;
int MAX_FRAMES = 600;
boolean SAVE_FRAMES = false;
int P_COUNT = 200;
float P_SIZE = 5.0; // Changed to circle
float P_SPEED = 0.5;
//color[] PALETTE = { #FF5733, #33FF57, #33A1FF, #FF33A1, #FFC733, #33FFC7, #A133FF, #FF33A1, #33FFC7, #C733FF };
color[] PALETTE = { #FF5733, #33FF57, #33A1FF, #FF33A1 };

// General Parameters
int SEED = 157;
boolean INVERT_COLORS = false;
boolean SHOW_GRIDLINES = true;

// Grid and Cell Data Structures
Cell[][] grid;
ArrayList<Particle> particles;

// Class to represent a particle
class Particle {
  PVector position;
  PVector velocity;
  color pColor;

  Particle(float x, float y, color c) {
    position = new PVector(x, y);
    velocity = PVector.random2D().mult(P_SPEED);
    pColor = c;
  }

  void update() {
    position.add(velocity);
  }

  void bounce(float x, float y, float w, float h) {
    if (position.x - P_SIZE/2 <= x || position.x + P_SIZE/2 >= x + w) {
      velocity.x *= -1;
    }
    if (position.y - P_SIZE/2 <= y || position.y + P_SIZE/2 >= y + h) {
      velocity.y *= -1;
    }
    position.x = constrain(position.x, x + P_SIZE/2, x + w - P_SIZE/2);
    position.y = constrain(position.y, y + P_SIZE/2, y + h - P_SIZE/2);
  }

  void display() {
    noStroke();
    fill(pColor);
    circle(position.x, position.y, P_SIZE);
  }
}

// Class to represent a cell in the grid
class Cell {
  float x, y, w, h;
  ArrayList<Cell> subCells;
  ArrayList<Particle> cellParticles;

  Cell(float x, float y, float w, float h, color c) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.subCells = new ArrayList<Cell>();
    this.cellParticles = new ArrayList<Particle>();

    // Add particles to this cell
    for (int i = 0; i < P_COUNT; i++) {
      cellParticles.add(new Particle(random(x, x + w), random(y, y + h), c));
    }
  }

  void subdivide() {
    int choice = (int)random(4);
    switch(choice) {
      case 0: // No division
        subCells.add(this);
        break;
      case 1: // 2x1 subgrid
        subCells.add(new Cell(x, y, w / 2, h, PALETTE[(int)random(PALETTE.length)]));
        subCells.add(new Cell(x + w / 2, y, w / 2, h, PALETTE[(int)random(PALETTE.length)]));
        break;
      case 2: // 1x2 subgrid
        subCells.add(new Cell(x, y, w, h / 2, PALETTE[(int)random(PALETTE.length)]));
        subCells.add(new Cell(x, y + h / 2, w, h / 2, PALETTE[(int)random(PALETTE.length)]));
        break;
      case 3: // 2x2 subgrid
        subCells.add(new Cell(x, y, w / 2, h / 2, PALETTE[(int)random(PALETTE.length)]));
        subCells.add(new Cell(x + w / 2, y, w / 2, h / 2, PALETTE[(int)random(PALETTE.length)]));
        subCells.add(new Cell(x, y + h / 2, w / 2, h / 2, PALETTE[(int)random(PALETTE.length)]));
        subCells.add(new Cell(x + w / 2, y + h / 2, w / 2, h / 2, PALETTE[(int)random(PALETTE.length)]));
        break;
    }
  }

  void display() {
    if (SHOW_GRIDLINES) {
      stroke(GRIDLINE_COLOR);
      strokeWeight(GRIDLINE_WEIGHT);
      noFill();
      rect(x, y, w, h);
    }
  }
}

void setup() {
  size(480, 800);
  randomSeed(SEED);
  grid = new Cell[COLS][ROWS];
  particles = new ArrayList<Particle>();
  createGrid();
}

void draw() {
  if (INVERT_COLORS) {
    background(255);
  } else {
    background(0);
  }

  for (int i = 0; i < COLS; i++) {
    for (int j = 0; j < ROWS; j++) {
      Cell currentCell = grid[i][j];
      currentCell.display();
      for (Cell subCell : currentCell.subCells) {
        subCell.display();
        for (Particle p : subCell.cellParticles) {
          p.update();
          p.bounce(subCell.x, subCell.y, subCell.w, subCell.h);
          p.display();
        }
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

void createGrid() {
  float cellWidth = (width - 2 * PADDING) / COLS;
  float cellHeight = (height - 2 * PADDING) / ROWS;

  float startX = (width - (COLS * cellWidth)) / 2;
  float startY = (height - (ROWS * cellHeight)) / 2;

  for (int i = 0; i < COLS; i++) {
    for (int j = 0; j < ROWS; j++) {
      float x = startX + i * cellWidth;
      float y = startY + j * cellHeight;
      grid[i][j] = new Cell(x, y, cellWidth, cellHeight, #FFFFFF); // Parent cell color isn't used for particles
      grid[i][j].subdivide();
    }
  }
}
