// 2023.11.19.10.08.13
// Tightly packed, animated, stroke-only extruded circles with rotation.

// Parameters
final int SKETCH_WIDTH = 480;
final int SKETCH_HEIGHT = 800;
final int PADDING = 40; // default 40
final int MAX_FRAMES = 900; // default 900
final boolean SAVE_FRAMES = false; // default false
final int ANIMATION_SPEED = 30; // default 30
final boolean INVERT_BACKGROUND = false; // default false
final boolean SHOW_GRID = false; // default false

// Circle parameters
final float MIN_CIRCLE_RADIUS = 15; // default 15
final float MAX_CIRCLE_RADIUS = 40; // default 40
final int MIN_EXTRUSION_STEPS = 3; // default 3 (Min steps for extrusion)
final int MAX_EXTRUSION_STEPS = 5; // default 5 (Max steps for extrusion)
final float EXTRUSION_OFFSET_FACTOR = 0.05; // default 0.05 (Offset as factor of radius)
final float MIN_STROKE_WEIGHT = 0.5; // default 0.5
final float MAX_STROKE_WEIGHT = 2.0; // default 2.0
final float PACKING_FACTOR = 0.9; // default 0.9 (Lower value = tighter packing)
final float ROTATION_SPEED_FACTOR = 0.2; // default 0.02 (Speed of rotation)

// Global seed for random
final int GLOBAL_SEED = 12345;

// Color palette from Adobe Kuler (e.g., "Forest Green")
final int[] PALETTE = {
  #3A5741, // Dark Green
  #6B8F71, // Medium Green
  #A2CC9B, // Light Green
  #E0EAD9, // Off-white
  #C0A29C  // Muted Red
};

final int BACKGROUND_PALETTE_INDEX = 3; // Index for background color

ArrayList<Circle> circles;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT, P3D);
}

void setup() {
  randomSeed(GLOBAL_SEED);
  frameRate(ANIMATION_SPEED);

  circles = new ArrayList<Circle>();
  generateCircles();
}

void draw() {
  int backgroundColor = PALETTE[BACKGROUND_PALETTE_INDEX];
  if (INVERT_BACKGROUND) {
    backgroundColor = (255 - (backgroundColor >> 16) & 0xFF) << 16 |
                      (255 - (backgroundColor >> 8) & 0xFF) << 8 |
                      (255 - backgroundColor & 0xFF);
  }
  background(backgroundColor);

  // Set up lights for P3D
  lights();
  directionalLight(150, 150, 150, 0, 0, -1);
  ambientLight(100, 100, 100);

  translate(width / 2, height / 2);
  translate(-SKETCH_WIDTH / 2 + PADDING, -SKETCH_HEIGHT / 2 + PADDING); // Center content within padding

  for (Circle c : circles) {
    c.update(); // Update rotation
    c.display();
  }

  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) {
      noLoop();
    }
  }
}

void generateCircles() {
  float contentWidth = SKETCH_WIDTH - (2 * PADDING);
  float contentHeight = SKETCH_HEIGHT - (2 * PADDING);

  // Use a simple growing circle packing algorithm for tighter results
  int attempts = 0;
  final int MAX_ATTEMPTS = 5000;
  final int MAX_CIRCLES = 300; // Limit circles to avoid excessive generation time

  // Add the first circle randomly
  float r0 = random(MIN_CIRCLE_RADIUS, MAX_CIRCLE_RADIUS);
  circles.add(new Circle(contentWidth / 2, contentHeight / 2, r0));

  while (attempts < MAX_ATTEMPTS && circles.size() < MAX_CIRCLES) {
    float x = random(contentWidth);
    float y = random(contentHeight);
    float r = MIN_CIRCLE_RADIUS; // Start with minimum radius

    boolean overlapping = false;
    for (Circle existingCircle : circles) {
      if (dist(x, y, existingCircle.x, existingCircle.y) < r + existingCircle.radius * PACKING_FACTOR) {
        overlapping = true;
        break;
      }
    }

    if (!overlapping) {
      // Find the largest possible radius that fits
      float maxR = MAX_CIRCLE_RADIUS;

      // Constraint 1: Stay within bounds
      maxR = min(maxR, x);
      maxR = min(maxR, contentWidth - x);
      maxR = min(maxR, y);
      maxR = min(maxR, contentHeight - y);

      // Constraint 2: Don't overlap existing circles
      for (Circle existingCircle : circles) {
        float distance = dist(x, y, existingCircle.x, existingCircle.y);
        float space = distance - existingCircle.radius * PACKING_FACTOR;
        maxR = min(maxR, space);
      }

      if (maxR >= MIN_CIRCLE_RADIUS) {
        Circle newCircle = new Circle(x, y, maxR);
        circles.add(newCircle);
        attempts = 0; // Reset attempts on success
      }
    }
    attempts++;
  }
}

class Circle {
  float x, y, radius;
  int baseColor;
  int extrusionSteps;
  float rotationAngle;
  float rotationSpeed; // Unique rotation speed per circle

  Circle(float x, float y, float radius) {
    this.x = x;
    this.y = y;
    this.radius = radius;
    this.baseColor = PALETTE[floor(random(PALETTE.length - 2))]; // Exclude background color
    this.extrusionSteps = floor(random(MIN_EXTRUSION_STEPS, MAX_EXTRUSION_STEPS + 1));
    this.rotationAngle = random(TWO_PI);
    this.rotationSpeed = random(-1, 1) * ROTATION_SPEED_FACTOR; // Random speed and direction
  }

  void update() {
    rotationAngle += rotationSpeed;
    if (rotationAngle > TWO_PI) rotationAngle -= TWO_PI;
    if (rotationAngle < 0) rotationAngle += TWO_PI;
  }

  void display() {
    pushMatrix();
    translate(x, y);

    // Apply rotation to the entire circle set
    rotate(rotationAngle);

    noFill();
    stroke(baseColor);

    // Draw the main circle (z=0, full stroke weight)
    strokeWeight(MAX_STROKE_WEIGHT);
    ellipse(0, 0, radius * 2, radius * 2);

    // Extrusion (offset circles with decreasing stroke weight)
    for (int i = 1; i <= extrusionSteps; i++) {
      float currentStrokeWeight = map(i, 1, extrusionSteps, MAX_STROKE_WEIGHT, MIN_STROKE_WEIGHT);
      float offset = i * radius * EXTRUSION_OFFSET_FACTOR;

      // Ensure stroke weight is not less than a tiny value
      currentStrokeWeight = max(currentStrokeWeight, 0.1);
      strokeWeight(currentStrokeWeight);

      // The offset circles are now relative to the rotated coordinate system

      // First offset circle (e.g., to the top-right in the local system)
      pushMatrix();
      translate(offset, -offset, 0);
      ellipse(0, 0, radius * 2, radius * 2);
      popMatrix();

      // Second offset circle (e.g., to the bottom-left in the local system)
      pushMatrix();
      translate(-offset, offset, 0);
      ellipse(0, 0, radius * 2, radius * 2);
      popMatrix();
    }
    popMatrix();

    if (SHOW_GRID) {
      noFill();
      stroke(255, 0, 0, 100);
      rectMode(CENTER);
      rect(x, y, radius * 2, radius * 2);
    }
  }
}
