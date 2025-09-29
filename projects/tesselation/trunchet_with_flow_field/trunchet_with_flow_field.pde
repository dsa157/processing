// T R U N C H E T   T I L E S   W I T H   C O N T R O L L E D   F L O W

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

//-- FLOW FIELD PARAMETERS
final float NOISE_SCALE = 0.05;
final float FLOW_FIELD_SPEED = 0.005; 
final float ROTATION_THRESHOLD = 0.5; // Changed to a more visible value
final int FRAME_INTERVAL = 60;

TrunchetTile[][] grid;
float zoff = 0;
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
  noiseSeed(SEED);
}

void draw() {
  background(INVERT_COLORS ? bg[1] : bg[0]);
  
  zoff += FLOW_FIELD_SPEED;
  
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
  int lastCheckFrame;

  TrunchetTile(int x, int y) {
    this.x = x;
    this.y = y;
    this.rotation = (int)random(4);
    this.angle = this.rotation * HALF_PI;
    this.targetAngle = this.angle;
    this.rotationSpeed = random(0.01, 0.05);
    this.lastCheckFrame = (int)random(FRAME_INTERVAL); // Stagger initial checks
  }

  void animate() {
    // Only check for a new rotation after a certain interval
    if (frameCount - lastCheckFrame >= FRAME_INTERVAL) {
      float noiseValue = noise(x * NOISE_SCALE, y * NOISE_SCALE, zoff);
      
      // Check if the noise value is above the threshold
      if (noiseValue > ROTATION_THRESHOLD) {
        targetAngle += HALF_PI;
        lastCheckFrame = frameCount;
      }
      
      // Reset the timer even if a rotation didn't happen to prevent a flood of checks
      lastCheckFrame = frameCount;
    }
    
    // Smoothly transition to the target angle
    if (abs(targetAngle - angle) > 0.001) {
      angle = lerp(angle, targetAngle, rotationSpeed);
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
