int SEED = 12345;
int PADDING = 40;
boolean INVERT_BACKGROUND = false;
int MAX_FRAMES = 600;
boolean SAVE_FRAMES = false;
int ANIMATION_SPEED = 60;

int COLS = 5;
int ROWS = 8;
float CIRCLE_RADIUS = 20;

// Pendulum parameters
float PENDULUM_GRAVITY = 0.5;
float PIVOT_POINT_Y_OFFSET_ROWS = 5;
float MIN_SPEED_FACTOR = 0.8; 
float MAX_SPEED_FACTOR = 1.2; 

// Grid parameters
float cellWidth, cellHeight;
float gridX, gridY;

Pendulum[] pendulums;

void setup() {
  size(480, 800);
  frameRate(ANIMATION_SPEED);

  if (INVERT_BACKGROUND) {
    background(255);
  } else {
    background(0);
  }

  randomSeed(SEED);

  // Calculate grid dimensions
  float gridWidth = width - (2 * PADDING);
  float gridHeight = height - (2 * PADDING);
  cellWidth = gridWidth / COLS;
  cellHeight = gridHeight / ROWS;

  // Center the grid on the canvas
  gridX = PADDING;
  gridY = PADDING;

  pendulums = new Pendulum[ROWS];

  PVector pivotPoint = new PVector(gridX + 2 * cellWidth + cellWidth / 2, gridY - PIVOT_POINT_Y_OFFSET_ROWS * cellHeight);

  for (int i = 0; i < ROWS; i++) {
    float pendulumLength = dist(pivotPoint.x, pivotPoint.y, gridX + 2 * cellWidth + cellWidth / 2, gridY + i * cellHeight + cellHeight / 2);
    pendulums[i] = new Pendulum(pivotPoint, pendulumLength);
  }
}

void draw() {
  // Add semi-transparent background to create motion trails
  if (INVERT_BACKGROUND) {
    background(255, 20); // semi-transparent white
    stroke(0);
    fill(0);
  } else {
    background(0, 20); // semi-transparent black
    stroke(255);
    fill(255);
  }

  for (int i = 0; i < ROWS; i++) {
    pendulums[i].update();
    pendulums[i].display();
  }
  
  // Draw connecting lines between pendulums
  for (int i = 0; i < ROWS - 1; i++) {
    stroke(255, 100);
    line(pendulums[i].position.x, pendulums[i].position.y, pendulums[i+1].position.x, pendulums[i+1].position.y);
  }

  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) {
      noLoop();
    }
  }
}

class Pendulum {
  PVector pivot;
  PVector position;
  float angle;
  float aVelocity = 0;
  float aAcceleration = 0;
  float len;
  float bobRadius;
  float speedFactor;

  Pendulum(PVector pivot_, float len_) {
    pivot = pivot_.copy();
    len = len_;
    position = new PVector();
    bobRadius = CIRCLE_RADIUS;
    speedFactor = random(MIN_SPEED_FACTOR, MAX_SPEED_FACTOR);

    // Calculate the initial angle so the pendulum starts at the padding edge
    float maxX = width - PADDING - bobRadius;
    float startX = gridX + 2 * cellWidth + cellWidth / 2;
    float dx = maxX - startX;
    angle = asin(dx / len);
  }

  void update() {
    aAcceleration = (-1 * PENDULUM_GRAVITY / len) * sin(angle);
    aVelocity += aAcceleration * speedFactor;
    angle += aVelocity;

    // Check if the pendulum swings past the padding borders and reverse direction
    if (position.x > width - PADDING - bobRadius || position.x < PADDING + bobRadius) {
      aVelocity *= -1;
    }
  }

  void display() {
    position.set(pivot.x + len * sin(angle), pivot.y + len * cos(angle));

    strokeWeight(2);
    line(pivot.x, pivot.y, position.x, position.y);

    noStroke();
    fill(255, 150);
    circle(position.x, position.y, bobRadius * 2);
  }
}
