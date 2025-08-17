int seed = 157;
float timeSpeed = 0.005;
float noiseScale = 0.01;
float stepSize = 5;

PVector[][] field;

int colorCycles = 0;
color currentColor;

void setup() {
  size(800, 800);
  background(255);
  noiseSeed(seed);
  randomSeed(seed);
  field = new PVector[width][height];

  // Pre-calculate the flow field
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      float noiseValue = noise(x * noiseScale, y * noiseScale);
      float angle = map(noiseValue, 0, 1, 0, TWO_PI * 4); // Map noise to an angle
      field[x][y] = PVector.fromAngle(angle);
    }
  }
}

void draw() {
  fill(255, 15);
  noStroke();
  rect(0, 0, width, height);
  
  // Set stroke color based on whether we are in a color cycle
  if (colorCycles > 0) {
    stroke(currentColor);
    colorCycles--;
  } else {
    stroke(0);
  }
  
  strokeWeight(1.5);

  for (int i = 0; i < 500; i++) {
    float startX = random(width);
    float startY = random(height);

    for (int j = 0; j < 50; j++) {
      PVector currentVector;
      if (startX >= 0 && startX < width && startY >= 0 && startY < height) {
        currentVector = field[int(startX)][int(startY)];
      } else {
        break;
      }

      float endX = startX + currentVector.x * stepSize;
      float endY = startY + currentVector.y * stepSize;
      line(startX, startY, endX, endY);

      startX = endX;
      startY = endY;
    }
  }

  if (frameCount % 10 == 0) {
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        float noiseValue = noise(x * noiseScale, y * noiseScale, frameCount * timeSpeed);
        float angle = map(noiseValue, 0, 1, 0, TWO_PI * 4);
        field[x][y] = PVector.fromAngle(angle);
      }
    }
  }
}

void mouseClicked() {
  colorMode(HSB, 255);
  currentColor = color(random(255), 255, 255);
  colorCycles = 10;
  colorMode(RGB, 255);
}
