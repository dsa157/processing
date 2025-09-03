// global seed for consistent random generation
final int SEED = 12345;

PImage img, bwImg;
Particle[] particles;
int numParticles = 5000;
float noiseScale = 0.005;

void setup() {
  // Set up sketch window
  size(480, 800);
  randomSeed(SEED);
  
  // Load the image (replace "img1.png" with your image file)
  // Ensure the image file is in the data folder of your sketch
  img = loadImage("img1.png");
  if (img == null) {
    println("Error: Image not found. Please place 'img1.png' in the sketch's data folder.");
    exit();
  }
  
  // Resize image to fit window and create a black and white copy
  img.resize(width, height);
  bwImg = createImage(width, height, RGB);
  bwImg.loadPixels();
  for (int i = 0; i < bwImg.pixels.length; i++) {
    int c = img.pixels[i];
    float brightness = (red(c) + green(c) + blue(c)) / 3.0;
    bwImg.pixels[i] = color(brightness);
  }
  bwImg.updatePixels();
  
  // Initialize particles
  particles = new Particle[numParticles];
  for (int i = 0; i < numParticles; i++) {
    particles[i] = new Particle();
  }
  
  // Set up drawing
  background(0);
}

void draw() {
  // Use a transparent background to create trails
  fill(0, 10);
  rect(0, 0, width, height);

  // Animate and display particles
  for (Particle p : particles) {
    p.update();
    p.display();
  }
}

class Particle {
  PVector pos;
  PVector vel;
  PVector acc;

  Particle() {
    // Random initial position
    pos = new PVector(random(width), random(height));
    vel = new PVector(0, 0);
    acc = new PVector(0, 0);
  }

  void update() {
    // Determine direction based on perlin noise and image brightness
    float x = pos.x * noiseScale;
    float y = pos.y * noiseScale;
    float noiseValue = noise(x, y);

    // Get brightness from the black and white image at the particle's position
    int xPos = constrain(floor(pos.x), 0, width - 1);
    int yPos = constrain(floor(pos.y), 0, height - 1);
    float brightness = brightness(bwImg.get(xPos, yPos));

    // Map brightness to a rotation angle
    // Darker areas will have a different flow direction
    float angle = map(brightness, 0, 255, noiseValue * TWO_PI, (noiseValue + 0.5) * TWO_PI);

    // Apply a force in the direction of the angle
    acc.set(cos(angle), sin(angle));
    acc.mult(0.1);

    // Update particle position and velocity
    vel.add(acc);
    vel.limit(2);
    pos.add(vel);
    acc.mult(0);

    // Wrap around screen edges
    if (pos.x < 0) pos.x = width;
    if (pos.x > width) pos.x = 0;
    if (pos.y < 0) pos.y = height;
    if (pos.y > height) pos.y = 0;
  }

  void display() {
    // Get the color from the original image at the particle's position
    int xPos = constrain(floor(pos.x), 0, width - 1);
    int yPos = constrain(floor(pos.y), 0, height - 1);
    int c = img.get(xPos, yPos);
    
    // Draw the particle as a point
    stroke(c, 150); // Use a semi-transparent color
    point(pos.x, pos.y);
  }
}
