long seed = 12345;
float timeSpeed = 0.005;
float noiseScale = 0.005;
float stepSize = 1;

boolean invertColors = true;

PVector[][] field;
ArrayList<Particle> particles;
int maxParticles = 50000;

void setup() {
  size(480, 800);
  seed *= millis();
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
  for (int i = 0; i < maxParticles; i++) {
    particles.add(new Particle(random(width), random(height)));
  }

  // Set initial background color
  background(invertColors ? 0 : 255);
}

void draw() {
  // Semi-transparent overlay for trails
  fill(invertColors ? 0 : 255, 10);
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

  // Update and display particles
  for (Particle p : particles) {
    p.update();
    p.display();
  }
}

class Particle {
  PVector position;
  PVector prevPosition;

  Particle(float x, float y) {
    position = new PVector(x, y);
    prevPosition = position.copy();
  }

  void update() {
    // Wrap particles that go off-screen
    if (position.x < 0 || position.x >= width || position.y < 0 || position.y >= height) {
      position.x = random(width);
      position.y = random(height);
      prevPosition = position.copy();
    }

    prevPosition = position.copy();

    // Get vector from flow field
    int fieldX = (int) constrain(position.x, 0, width - 1);
    int fieldY = (int) constrain(position.y, 0, height - 1);
    PVector currentVector = field[fieldX][fieldY];

    position.add(currentVector.x * stepSize, currentVector.y * stepSize);
  }

  void display() {
    // The trail
    stroke(invertColors ? 255 : 0, 20);
    strokeWeight(1);
    line(prevPosition.x, prevPosition.y, position.x, position.y);
    
    // The point at the head of the particle
    stroke(invertColors ? color(255, 100, 0) : color(0, 100, 255));
    strokeWeight(2);
    point(position.x, position.y);
  }
}
