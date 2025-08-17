int seed = 157;
float timeSpeed = 0.005;
float noiseScale = 0.01;
float stepSize = 5;
int maximumColorFrames = 100;

PVector[][] field;
ArrayList<Particle> particles;

void setup() {
  size(450, 800);
  background(255);
  noiseSeed(seed);
  randomSeed(seed);
  field = new PVector[width][height];
  particles = new ArrayList<Particle>();

  // Pre-calculate the flow field
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      float noiseValue = noise(x * noiseScale, y * noiseScale);
      float angle = map(noiseValue, 0, 1, 0, TWO_PI * 4);
      field[x][y] = PVector.fromAngle(angle);
    }
  }

  // Create particles
  for (int i = 0; i < 5000; i++) {
    particles.add(new Particle(random(width), random(height)));
  }
}

void draw() {
  fill(255, 15);
  noStroke();
  rect(0, 0, width, height);
  
  // Animate the flow field over time
  if (frameCount % 10 == 0) {
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        float noiseValue = noise(x * noiseScale, y * noiseScale, frameCount * timeSpeed);
        float angle = map(noiseValue, 0, 1, 0, TWO_PI * 4);
        field[x][y] = PVector.fromAngle(angle);
      }
    }
  }

  for (Particle p : particles) {
    p.update();
    p.display();
  }
}

void mouseClicked() {
  colorMode(HSB, 255);
  int randomColor = color(random(255), 255, 255);
  colorMode(RGB, 255);

  for (Particle p : particles) {
    float distToClick = dist(p.position.x, p.position.y, mouseX, mouseY);
    if (distToClick < 100) {
      p.setColor(randomColor, maximumColorFrames);
    }
  }
}

class Particle {
  PVector position;
  PVector prevPosition;
  int particleColor;
  int colorFramesLeft;

  Particle(float x, float y) {
    position = new PVector(x, y);
    prevPosition = position.copy();
    particleColor = color(0);
    colorFramesLeft = 0;
  }

  void update() {
    // Reset particle if it goes off-screen
    if (position.x < 0 || position.x >= width || position.y < 0 || position.y >= height) {
      position.x = random(width);
      position.y = random(height);
      prevPosition = position.copy();
    }
    
    // Store current position before updating
    prevPosition = position.copy();

    // Get vector from flow field
    PVector currentVector = field[int(position.x)][int(position.y)];
    position.add(currentVector.x * stepSize, currentVector.y * stepSize);

    // Decrease color timer
    if (colorFramesLeft > 0) {
      colorFramesLeft--;
    } else {
      particleColor = color(0); // Revert to black
    }
  }

  void display() {
    stroke(particleColor);
    strokeWeight(1.5);
    line(prevPosition.x, prevPosition.y, position.x, position.y);
  }

  void setColor(int newColor, int frames) {
    particleColor = newColor;
    colorFramesLeft = frames;
  }
}
