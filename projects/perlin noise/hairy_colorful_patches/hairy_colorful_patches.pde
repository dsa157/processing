long seed = 157;
float timeSpeed = 0.005;
float noiseScale = 0.005;
float stepSize = 1;

boolean invertColors = true;
int MAXFRAMES = 600;
boolean SAVEFRAMES = true;

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
  
  if (SAVEFRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAXFRAMES) {
      noLoop();
    }
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
    colorMode(HSB, 255);
    float hue = map(noise(position.x * 0.01, position.y * 0.01), 0, 1, 0, 255);
    float saturation = map(dist(width/2, height/2, position.x, position.y), 0, height/2, 255, 100);
    float brightness = 255;
    
    stroke(hue, saturation, brightness, 20);

    // Modulate stroke weight based on vector magnitude
    int fieldX = (int) constrain(position.x, 0, width - 1);
    int fieldY = (int) constrain(position.y, 0, height - 1);
    float weight = map(field[fieldX][fieldY].mag(), 0, 1, 0.5, 3);
    strokeWeight(weight);

    line(prevPosition.x, prevPosition.y, position.x, position.y);
    colorMode(RGB, 255);
  }
}
