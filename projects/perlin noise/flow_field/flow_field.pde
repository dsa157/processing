int seed = 12345;
float timeSpeed = 0.005;
float noiseScale = 0.01;
float stepSize = 5;

PVector[][] field;

void setup() {
  size(800, 800);
  background(255);
  noiseSeed(seed);
  field = new PVector[width][height];

  // Pre-calculate the flow field
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      float noiseValue = noise(x * noiseScale, y * noiseScale);
      float angle = map(noiseValue, 0, 1, 0, TWO_PI * 4); // Map noise to an angle

      // Create a vector from the angle
      field[x][y] = PVector.fromAngle(angle);
    }
  }
}

void draw() {
  // Add a semi-transparent background for a fading trail effect
  fill(255, 15);
  noStroke();
  rect(0, 0, width, height);
  
  stroke(0);
  strokeWeight(1.5);

  // Draw many lines that follow the flow field
  for (int i = 0; i < 500; i++) {
    // Start lines from random positions
    float startX = random(width);
    float startY = random(height);

    for (int j = 0; j < 50; j++) {
      // Get the vector for the current position from the pre-calculated field
      PVector currentVector;
      if (startX >= 0 && startX < width && startY >= 0 && startY < height) {
        currentVector = field[int(startX)][int(startY)];
      } else {
        // Break if outside bounds
        break;
      }

      // Draw a line segment
      float endX = startX + currentVector.x * stepSize;
      float endY = startY + currentVector.y * stepSize;
      line(startX, startY, endX, endY);

      // Move to the new position
      startX = endX;
      startY = endY;
    }
  }

  // Animate the flow field over time
  if (frameCount % 10 == 0) { // Update less frequently for performance
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        float noiseValue = noise(x * noiseScale, y * noiseScale, frameCount * timeSpeed);
        float angle = map(noiseValue, 0, 1, 0, TWO_PI * 4);
        field[x][y] = PVector.fromAngle(angle);
      }
    }
  }
}
