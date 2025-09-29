// T R U N C H E T   T I L E S

//-- GLOBAL PARAMETERS
final int SEED = 13579;

final int SKETCH_WIDTH = 480;
final int SKETCH_HEIGHT = 800;

final int PADDING = 40;
final boolean INVERT_COLORS = false;

final int MAX_FRAMES = 600;
final boolean SAVE_FRAMES = false;
final int ANIMATION_SPEED = 30;

//-- GRID PARAMETERS
final int COLS = 15;
final int ROWS = 25;
final float TILE_SIZE = (SKETCH_WIDTH - 2.0 * PADDING) / COLS;

TrunchetTile[][] grid;
int[] bg = {0, 255};
int[] fg = {255, 0};

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}
  
void setup() {
  background(INVERT_COLORS ? bg[1] : bg[0]);
  
  if (SAVE_FRAMES) {
    frameRate(ANIMATION_SPEED);
  } else {
    frameRate(60);
  }

  randomSeed(SEED);

  grid = new TrunchetTile[COLS][ROWS];
  for (int x = 0; x < COLS; x++) {
    for (int y = 0; y < ROWS; y++) {
      grid[x][y] = new TrunchetTile(x, y);
    }
  }
}

void draw() {
  background(INVERT_COLORS ? bg[1] : bg[0]);
  
  for (int x = 0; x < COLS; x++) {
    for (int y = 0; y < ROWS; y++) {
      grid[x][y].display();
      if (!SAVE_FRAMES) {
        grid[x][y].animate();
      }
    }
  }

  if (SAVE_FRAMES) {
    if (frameCount <= MAX_FRAMES) {
      saveFrame("frames/####.tif");
    } else {
      noLoop();
    }
  }
}

class TrunchetTile {
  int x, y;
  int rotation;
  float angle;
  float targetAngle;
  float rotationSpeed;

  TrunchetTile(int x, int y) {
    this.x = x;
    this.y = y;
    this.rotation = (int)random(4);
    this.angle = this.rotation * HALF_PI;
    this.targetAngle = this.angle;
    this.rotationSpeed = random(0.01, 0.05);
  }

  void animate() {
    if (abs(targetAngle - angle) > 0.001) {
      angle = lerp(angle, targetAngle, rotationSpeed);
    } else {
      if (random(1) < 0.005) {
        targetAngle += HALF_PI;
      }
    }
  }

  void display() {
    float cx = PADDING + x * TILE_SIZE + TILE_SIZE / 2;
    float cy = PADDING + y * TILE_SIZE + TILE_SIZE / 2;

    pushMatrix();
    translate(cx, cy);
    rotate(angle);
    noFill();
    stroke(INVERT_COLORS ? fg[1] : fg[0]);
    strokeWeight(2);

    arc(-TILE_SIZE / 2, -TILE_SIZE / 2, TILE_SIZE, TILE_SIZE, 0, HALF_PI);
    arc(TILE_SIZE / 2, TILE_SIZE / 2, TILE_SIZE, TILE_SIZE, PI, PI + HALF_PI);

    popMatrix();
  }
}
