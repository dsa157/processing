int MAX_FRAMES = 60;
int SEED = 157 * millis();
int PADDING = 20;

// Rectangle dimensions
float rectHeight;
float rectWidth;

// Sine Wave Config
int SINE_WAVE_COUNT = 5;
float SINE_WAVE_SPEED = 0.05;
float SINE_FREQUENCY_MIN = 0.01;
float SINE_FREQUENCY_MAX = 0.05;
float SINE_AMPLITUDE_MIN = 0.1;
float SINE_AMPLITUDE_MAX = 1.0;
float SINE_LINE_SPACING = 5;

// Perlin Noise Config
int PERLIN_WAVE_COUNT = 5;
float PERLIN_SPEED = 0.001;
float PERLIN_SCALE_MIN = 0.003;
float PERLIN_SCALE_MAX = 0.01;
float PERLIN_AMPLITUDE_MIN = 0.1;
float PERLIN_AMPLITUDE_MAX = 100.4;
float PERLIN_LINE_SPACING = 5;

// Flow Field Config
int PARTICLE_COUNT = 5000; // Increased particle count for higher density
float FLOW_SPEED = 0.05;
float FLOW_SCALE = 0.1;

Particle[] particles;

float yOffset = 0;
float noiseOffset = 0;

void setup() {
  size(480, 800);
  background(0);
  randomSeed(SEED);
  noiseSeed(SEED);
  strokeCap(ROUND);
  noFill();

  rectHeight = (height - PADDING * 4) / 3.0;
  rectWidth = width - PADDING * 2;
  
  particles = new Particle[PARTICLE_COUNT];
  for (int i = 0; i < PARTICLE_COUNT; i++) {
    particles[i] = new Particle(rectWidth, rectHeight);
  }
}

void draw() {
  if (frameCount > MAX_FRAMES) {
    noLoop();
    return;
  }

  fill(0, 20);
  rect(0, 0, width, height);

  // Top Rectangle: Denser Sine Waves
  pushMatrix();
  translate(PADDING, PADDING);
  stroke(255);
  strokeWeight(2);
  noFill();
  rect(0, 0, rectWidth, rectHeight);
  drawSineRibbons(rectWidth, rectHeight);
  popMatrix();

  // Middle Rectangle: Denser Perlin Noise
  pushMatrix();
  translate(PADDING, PADDING * 2 + rectHeight);
  stroke(255);
  strokeWeight(2);
  noFill();
  rect(0, 0, rectWidth, rectHeight);
  drawNoiseRibbons(rectWidth, rectHeight);
  popMatrix();

  // Bottom Rectangle: Flow Field
  pushMatrix();
  translate(PADDING, PADDING * 3 + rectHeight * 2);
  
  // Clip to the rectangle's boundaries
  rectMode(CORNERS);
  beginShape();
  vertex(0, 0);
  vertex(rectWidth, 0);
  vertex(rectWidth, rectHeight);
  vertex(0, rectHeight);
  endShape(CLOSE);
  
  stroke(255);
  strokeWeight(2);
  noFill();
  rect(0, 0, rectWidth, rectHeight);
  
  drawFlowField();
  
  popMatrix();
}

void drawSineRibbons(float rectW, float rectH) {
  stroke(255, 255, 255, 150); // 255, 100, 100, 150
  strokeWeight(1);
  yOffset += SINE_WAVE_SPEED;
  for (int i = 0; i < SINE_WAVE_COUNT; i++) {
    float amplitude = random(rectH * SINE_AMPLITUDE_MIN, rectH * SINE_AMPLITUDE_MAX);
    float frequency = random(SINE_FREQUENCY_MIN, SINE_FREQUENCY_MAX);
    float phase = random(TWO_PI);
    beginShape();
    for (int x = 0; x <= rectW; x += SINE_LINE_SPACING) {
      float y = sin(x * frequency + yOffset + phase) * amplitude + rectH / 2;
      vertex(x, constrain(y, 0, rectH));
    }
    endShape();
  }
}

void drawNoiseRibbons(float rectW, float rectH) {
  stroke(255, 255, 255, 150); // stroke(100, 255, 100, 150);
  strokeWeight(1);
  noiseOffset += PERLIN_SPEED;
  for (int i = 0; i < PERLIN_WAVE_COUNT; i++) {
    float noiseScale = random(PERLIN_SCALE_MIN, PERLIN_SCALE_MAX);
    float amplitude = random(rectH * PERLIN_AMPLITUDE_MIN, rectH * PERLIN_AMPLITUDE_MAX);
    float offset = random(100);
    beginShape();
    for (int x = 0; x <= rectW; x += PERLIN_LINE_SPACING) {
      float y = noise(x * noiseScale, noiseOffset + offset) * rectH;
      vertex(x, constrain(y, 0, rectH));
    }
    endShape();
  }
}

void drawFlowField() {
  for (int i = 0; i < PARTICLE_COUNT; i++) {
    particles[i].update();
    particles[i].display();
  }
}

class Particle {
  PVector pos;
  PVector prevPos;
  PVector vel;
  PVector acc;
  float parentWidth;
  float parentHeight;

  Particle(float parentWidth, float parentHeight) {
    this.parentWidth = parentWidth;
    this.parentHeight = parentHeight;
    this.pos = new PVector(random(this.parentWidth), random(this.parentHeight));
    this.prevPos = pos.copy();
    this.vel = new PVector(0, 0);
    this.acc = new PVector(0, 0);
  }

  void update() {
    this.prevPos = this.pos.copy();
    float n = noise(pos.x * FLOW_SCALE, pos.y * FLOW_SCALE, frameCount * FLOW_SPEED) * TWO_PI;
    PVector force = PVector.fromAngle(n);
    acc.add(force);
    vel.add(acc);
    vel.limit(1); // Set a limit on velocity
    pos.add(vel);
    acc.mult(0); // Reset acceleration
    
    // Wrap particles around the edges of the pane
    if (pos.x < 0) {
      pos.x = this.parentWidth;
      prevPos = pos.copy();
    }
    if (pos.x > this.parentWidth) {
      pos.x = 0;
      prevPos = pos.copy();
    }
    if (pos.y < 0) {
      pos.y = this.parentHeight;
      prevPos = pos.copy();
    }
    if (pos.y > this.parentHeight) {
      pos.y = 0;
      prevPos = pos.copy();
    }
  }

  void display() {
    //stroke(100, 100, 255, 150);
    stroke(255, 255, 255, 150);
    strokeWeight(1);
    line(prevPos.x, prevPos.y, pos.x, pos.y);
  }
}
