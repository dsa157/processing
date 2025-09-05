// GLOBAL PARAMETERS
int GLOBAL_SEED = 222 + millis();
int PADDING = 40;
boolean INVERT_BACKGROUND = true;
int MAX_FRAMES = 600;
boolean SAVE_FRAMES = false;
int ANIMATION_SPEED = 5; // frames

// SKETCH-SPECIFIC PARAMETERS
int TILE_SIZE = 50;
float LINE_WEIGHT = 2.0;

// The color palette
int[] palette;

void setup() {
  size(480, 800);
  colorMode(HSB, 360, 100, 100, 100);

  // Set the frame rate regardless of saving frames
  frameRate(ANIMATION_SPEED);


  randomSeed(GLOBAL_SEED);

  if (INVERT_BACKGROUND) {
    background(255);
  } else {
    background(0);
  }

  // Create a random, vibrant color palette
  palette = new int[4];
  for (int i = 0; i < palette.length; i++) {
    palette[i] = color(random(360), random(70, 100), random(70, 100));
  }
}

void draw() {
  if (INVERT_BACKGROUND) {
    background(255);
  } else {
    background(0);
  }

  // Draw the tessellated pattern
  for (int x = PADDING; x < width - PADDING; x += TILE_SIZE) {
    for (int y = PADDING; y < height - PADDING; y += TILE_SIZE) {
      tessellate(x, y, TILE_SIZE);
    }
  }

  // Check if we need to save frames
  if (SAVE_FRAMES) {
    if (frameCount <= MAX_FRAMES) {
      saveFrame("frames/####.tif");
    } else {
      noLoop();
    }
  }
}

void tessellate(float x, float y, float size) {
  int shapeType = (int)random(4);
  int shapeColor = palette[(int)random(palette.length)];

  pushMatrix();
  translate(x + size/2, y + size/2);
  strokeWeight(LINE_WEIGHT);
  stroke(0);

  if (shapeType == 0) {
    // Square
    fill(shapeColor);
    rect(0, 0, size, size);
  } else if (shapeType == 1) {
    // Two triangles
    noFill();
    fill(shapeColor);
    triangle(-size/2, -size/2, size/2, -size/2, -size/2, size/2);
    fill(palette[(int)random(palette.length)]);
    triangle(size/2, size/2, -size/2, size/2, size/2, -size/2);
  } else if (shapeType == 2) {
    // Two squares
    fill(shapeColor);
    rect(-size/4, -size/4, size/2, size/2);
    fill(palette[(int)random(palette.length)]);
    rect(size/4, size/4, size/2, size/2);
  } else if (shapeType == 3) {
    // Lines
    stroke(shapeColor);
    line(-size/2, -size/2, size/2, size/2);
    line(-size/2, size/2, size/2, -size/2);
  }

  popMatrix();
}
