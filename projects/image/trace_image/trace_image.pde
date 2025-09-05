// PARAMETERS
int SEED = 12345;
int PADDING = 40;
boolean INVERT_BG = false;
int MAX_FRAMES = 600;
boolean SAVE_FRAMES = false;

// SKETCH-SPECIFIC PARAMETERS
String IMAGE_PATH = "img1.png";
int NUM_CIRCLES = 10;
float CIRCLE_SIZE = 5;

// GLOBAL VARIABLES
PImage img;
ArrayList<PVector> tracePoints;
ArrayList<CircleTracer> tracers;
int bgColor, fgColor;

void setup() {
  size(480, 800);
  randomSeed(SEED);

  // Set colors based on INVERT_BG
  if (INVERT_BG) {
    bgColor = 255;
    fgColor = 0;
  } else {
    bgColor = 0;
    fgColor = 255;
  }

  // Load and process image
  img = loadImage(IMAGE_PATH);
  img.resize(width - PADDING * 2, height - PADDING * 2);

  // Center the image
  int imgX = (width - img.width) / 2;
  int imgY = (height - img.height) / 2;

  // Trace the image
  tracePoints = new ArrayList<PVector>();
  img.loadPixels();
  for (int x = 0; x < img.width; x++) {
    for (int y = 0; y < img.height; y++) {
      int c = img.get(x, y);
      if (brightness(c) < 128) { // Trace dark pixels
        tracePoints.add(new PVector(x + imgX, y + imgY));
      }
    }
  }
  
  // Initialize tracers
  tracers = new ArrayList<CircleTracer>();
  for (int i = 0; i < NUM_CIRCLES; i++) {
    tracers.add(new CircleTracer());
  }
}

void draw() {
  background(bgColor);
  
  // Display the original image
  image(img, (width - img.width) / 2, (height - img.height) / 2);

  // Draw traced circles
  noStroke();
  fill(fgColor, 150);
  for (CircleTracer tracer : tracers) {
    tracer.update();
    tracer.display();
  }

  // Save frames
  if (SAVE_FRAMES) {
    if (frameCount <= MAX_FRAMES) {
      saveFrame("frames/####.tif");
    } else {
      noLoop();
    }
  }
}

class CircleTracer {
  PVector pos;
  PVector target;
  int traceIndex;
  
  CircleTracer() {
    traceIndex = (int) random(tracePoints.size());
    pos = tracePoints.get(traceIndex).copy();
    setNewTarget();
  }
  
  void setNewTarget() {
    traceIndex = (int) random(tracePoints.size());
    target = tracePoints.get(traceIndex);
  }
  
  void update() {
    // Move towards the target
    PVector vel = PVector.sub(target, pos);
    float dist = vel.mag();
    if (dist < 1) {
      setNewTarget();
    }
    vel.normalize();
    pos.add(vel);
  }
  
  void display() {
    ellipse(pos.x, pos.y, CIRCLE_SIZE, CIRCLE_SIZE);
  }
}
