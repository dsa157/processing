// This sketch generates a generative art piece using a flow field and particles.
// The particles move along the field, leaving trails behind them.
// Random bursts of color appear at intervals, affecting particles within a certain radius.
// The entire sketch can be inverted to create a dark or light theme.

// You can save a sequence of frames by uncommenting the line saveFrame() in the draw loop.

// Global seed for reproducible random behavior.
long seed = 12345 * millis();

// Flow field parameters
float timeSpeed = 0.005;
float noiseScale = 0.01;
float stepSize = 5;

// New global variables for random color bursts
int minDelay = 1000; // minimum delay in milliseconds (1 second)
int maxDelay = 4000; // maximum delay in milliseconds (4 seconds)
long lastColorChange = 0;
int nextColorDelay;
int numColorBursts = 3;
float colorRadius = 100; // radius for color effect
int colorFrames = 100; // number of frames the color lasts

// Particle and visualization parameters
float stkWeight = 1;
int maxParticles = 5000;
float circleRadius = 6; // New variable for the circle size

// Global variable for color inversion
boolean invertColors = true;
int MAXFRAMES = 600;
boolean SAVEFRAMES = true;

PVector[][] field;
ArrayList<Particle> particles;

void setup() {
  size(450, 800);
  noiseSeed(seed);
  randomSeed(seed);
  field = new PVector[width][height];
  particles = new ArrayList<Particle>();

  nextColorDelay = (int) random(minDelay, maxDelay);

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

  // Set initial background and particle colors based on inversion
  if (invertColors) {
    background(0);
  } else {
    background(255);
  }
}

void draw() {
  // Semi-transparent overlay for trails, inverted if needed
  if (invertColors) {
    fill(0, 15);
  } else {
    fill(255, 15);
  }
  noStroke();
  rect(0, 0, width, height);

  // Check for random color event
  if (millis() > lastColorChange + nextColorDelay) {
    for (int x = 0; x < numColorBursts; x++) {
      applyRandomColorBurst();
    }
    lastColorChange = millis();
    nextColorDelay = (int) random(minDelay, maxDelay);
  }

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

  if (SAVEFRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAXFRAMES) {
      noLoop();
    }
  }

}

void applyRandomColorBurst() {
  colorMode(HSB, 255);
  int randomColor = color(random(255), 255, 255);
  colorMode(RGB, 255);

  PVector randomPos = new PVector(random(width), random(height));

  for (Particle p : particles) {
    float distToPos = dist(p.position.x, p.position.y, randomPos.x, randomPos.y);
    if (distToPos < colorRadius) {
      p.setColor(randomColor, colorFrames);
    }
  }
}

class Particle {
  PVector position;
  PVector prevPosition;
  int particleColor;
  int colorFramesLeft;
  boolean justReset = true; // Flag to track if the particle has just been created or reset

  Particle(float x, float y) {
    position = new PVector(x, y);
    prevPosition = position.copy();
    if (invertColors) {
      particleColor = color(255); // White for black background
    } else {
      particleColor = color(0); // Black for white background
    }
    colorFramesLeft = 0;
  }

  void update() {
    // Reset particle if it goes off-screen
    if (position.x < 0 || position.x >= width || position.y < 0 || position.y >= height) {
      position.x = random(width);
      position.y = random(height);
      prevPosition = position.copy();
      justReset = true; // Set the flag to true on reset
    } else {
      justReset = false; // Set the flag to false otherwise
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
      if (invertColors) {
        particleColor = color(255); // Revert to white
      } else {
        particleColor = color(0); // Revert to black
      }
    }
  }

  void display() {
    stroke(particleColor);
    strokeWeight(stkWeight);
    line(prevPosition.x, prevPosition.y, position.x, position.y);
    
    // Only draw the circle if the particle has just reset
    if (justReset) {
      noStroke();
      fill(particleColor);
      ellipse(position.x, position.y, circleRadius, circleRadius);
    }
  }

  void setColor(int newColor, int frames) {
    particleColor = newColor;
    colorFramesLeft = frames;
  }
}
