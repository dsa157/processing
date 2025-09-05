int SEED = 12345;
int PADDING = 40;
int MAX_FRAMES = 600;
boolean SAVE_FRAMES = false;

// Invert background color
boolean INVERT_BG = false;

// Global settings
float lineWeight = 3.0;
int maxSegments = 100;
float noiseScale = 0.005;
float segmentLength = 30;
float animationSpeed = 0.04;
int MAX_SQUIGGLES = 15;

// Colors
color lightColor, darkColor;
color squiggleColor;
float decayRate = 0.005;

ArrayList<Squiggle> allSquiggles;
ArrayList<Squiggle> drawingQueue;

// Define the drawing area
int drawingWidth;
int drawingHeight;

void setup() {
  size(480, 800);
  randomSeed(SEED);

  lightColor = color(240, 240, 240);
  darkColor = color(15, 15, 15);

  if (INVERT_BG) {
    color temp = lightColor;
    lightColor = darkColor;
    darkColor = temp;
  }

  drawingWidth = width - 2 * PADDING;
  drawingHeight = height - 2 * PADDING;

  allSquiggles = new ArrayList<Squiggle>();
  drawingQueue = new ArrayList<Squiggle>();
  
  // Fill the initial queue
  for (int i = 0; i < MAX_SQUIGGLES; i++) {
    drawingQueue.add(new Squiggle());
  }
}

void draw() {
  background(INVERT_BG ? lightColor : darkColor);

  float xOffset = PADDING;
  float yOffset = PADDING;

  pushMatrix();
  translate(xOffset, yOffset);

  // Draw and decay all completed squiggles
  for (Squiggle squiggle : allSquiggles) {
    squiggle.display();
    squiggle.decay();
  }

  // Draw from the queue, advancing the animation
  boolean allComplete = true;
  for (Squiggle squiggle : drawingQueue) {
    if (squiggle.t < 1.0) {
      squiggle.t += animationSpeed;
      if (squiggle.t >= 1.0) {
        squiggle.t = 1.0;
      }
      squiggle.displayPartial(squiggle.t);
      allComplete = false;
    } else {
      squiggle.display();
    }
  }

  // If all squiggles in the queue are drawn, add them to the main list and prepare the next set
  if (allComplete) {
    allSquiggles.addAll(drawingQueue);
    drawingQueue.clear();
    for (int i = 0; i < MAX_SQUIGGLES; i++) {
      drawingQueue.add(new Squiggle());
    }
  }

  // Remove fully decayed squiggles
  for (int i = allSquiggles.size() - 1; i >= 0; i--) {
    Squiggle squiggle = allSquiggles.get(i);
    if (squiggle.currentAlpha <= 0) {
      allSquiggles.remove(i);
    }
  }

  popMatrix();

  if (SAVE_FRAMES) {
    if (frameCount <= MAX_FRAMES) {
      saveFrame("frames/####.tif");
    } else {
      noLoop();
    }
  }
}

class Squiggle {
  ArrayList<PVector> points;
  float currentAlpha;
  float t; // Individual animation progress

  Squiggle() {
    points = new ArrayList<PVector>();
    currentAlpha = 255;
    t = 0;
    generatePoints();
  }

  void generatePoints() {
    PVector currentPos = new PVector(random(drawingWidth), random(drawingHeight));
    points.add(currentPos.copy());

    for (int i = 0; i < maxSegments; i++) {
      float angle = noise(currentPos.x * noiseScale, currentPos.y * noiseScale, frameCount * noiseScale) * TWO_PI * 4;
      PVector newPos = new PVector(currentPos.x + cos(angle) * segmentLength, currentPos.y + sin(angle) * segmentLength);

      PVector centerVec = new PVector(drawingWidth / 2.0 - newPos.x, drawingHeight / 2.0 - newPos.y).normalize().mult(segmentLength * 0.5);
      newPos.add(centerVec);

      points.add(newPos);
      currentPos = newPos;
    }
  }

  void display() {
    stroke(INVERT_BG ? darkColor : lightColor, currentAlpha);
    strokeWeight(lineWeight);
    noFill();

    if (points.size() > 1) {
      beginShape();
      for (PVector p : points) {
        curveVertex(p.x, p.y);
      }
      endShape();
    }
  }

  void displayPartial(float progress) {
    stroke(INVERT_BG ? darkColor : lightColor, currentAlpha);
    strokeWeight(lineWeight);
    noFill();

    int numPoints = (int) (progress * (points.size() - 1));

    if (numPoints > 1) {
      beginShape();
      for (int i = 0; i <= numPoints; i++) {
        PVector p = points.get(i);
        curveVertex(p.x, p.y);
      }
      endShape();
    }
  }

  void decay() {
    if (currentAlpha > 0) {
      currentAlpha -= decayRate * 255;
      if (currentAlpha < 0) {
        currentAlpha = 0;
      }
    }
  }
}
