int MAX_FRAMES = 200;
int SEED = 157; // use a constant seed for consistent results
int PADDING = 20;

// Rectangle dimensions
float rectHeight;
float rectWidth;

// Flow Field Config - Pane 1
int PARTICLE_COUNT_1 = 10000;
float FLOW_SPEED_1 = 0.08;
float FLOW_SCALE_1 = 0.05;

// Flow Field Config - Pane 2 
int PARTICLE_COUNT_2 = 10000;
float FLOW_SPEED_2 = 0.09;
float FLOW_SCALE_2 = 0.1;

// Flow Field Config - Pane 3 
int PARTICLE_COUNT_3 = 10000;
float FLOW_SPEED_3 = 0.1;
float FLOW_SCALE_3 = 0.2;

Particle[] particles1;
Particle[] particles2;
Particle[] particles3;

boolean inverted = true;

// Particle size variables
float DEFAULT_PARTICLE_SIZE = 1;
float RED_PARTICLE_SIZE = 3;

// Decay speed variable
float DECAY_SPEED = 0.0005;

void setup() {
  size(480, 800);
  background(0);
  randomSeed(SEED);
  noiseSeed(SEED);
  strokeCap(ROUND);
  noFill();

  rectHeight = (height - PADDING * 4) / 3.0;
  rectWidth = width - PADDING * 2;
  
  particles1 = new Particle[PARTICLE_COUNT_1];
  for (int i = 0; i < PARTICLE_COUNT_1; i++) {
    particles1[i] = new Particle(rectWidth, rectHeight);
  }

  particles2 = new Particle[PARTICLE_COUNT_2];
  for (int i = 0; i < PARTICLE_COUNT_2; i++) {
    particles2[i] = new Particle(rectWidth, rectHeight);
  }

  particles3 = new Particle[PARTICLE_COUNT_3];
  for (int i = 0; i < PARTICLE_COUNT_3; i++) {
    particles3[i] = new Particle(rectWidth, rectHeight);
  }
}

void draw() {
  if (frameCount > MAX_FRAMES) {
    noLoop();
    return;
  }

  int fadeColor = inverted ? 255 : 0;
  fill(fadeColor, 20);
  rect(0, 0, width, height);

  // Top Rectangle: Flow Field 1
  pushMatrix();
  translate(PADDING, PADDING);
  stroke(inverted ? 0 : 255);
  strokeWeight(2);
  rect(0, 0, rectWidth, rectHeight);
  drawFlowField(particles1, FLOW_SPEED_1, FLOW_SCALE_1, PADDING, PADDING);
  popMatrix();

  // Middle Rectangle: Flow Field 2
  pushMatrix();
  translate(PADDING, PADDING * 2 + rectHeight);
  stroke(inverted ? 0 : 255);
  strokeWeight(2);
  rect(0, 0, rectWidth, rectHeight);
  drawFlowField(particles2, FLOW_SPEED_2, FLOW_SCALE_2, PADDING, PADDING * 2 + rectHeight);
  popMatrix();

  // Bottom Rectangle: Flow Field 3
  pushMatrix();
  translate(PADDING, PADDING * 3 + rectHeight * 2);
  stroke(inverted ? 0 : 255);
  strokeWeight(2);
  rect(0, 0, rectWidth, rectHeight);
  drawFlowField(particles3, FLOW_SPEED_3, FLOW_SCALE_3, PADDING, PADDING * 3 + rectHeight * 2);
  popMatrix();
}

void drawFlowField(Particle[] particles, float flowSpeed, float flowScale, float rectX, float rectY) {
  rectMode(CORNER);
  
  for (int i = 0; i < particles.length; i++) {
    particles[i].update(flowSpeed, flowScale);
    particles[i].display(rectX, rectY);
  }
}

void mousePressed() {
  inverted = !inverted;
  background(inverted ? 255 : 0);
  resetParticleColors();
}

void resetParticleColors() {
  for (Particle p : particles1) {
    p.setOriginalColor(inverted);
  }
  for (Particle p : particles2) {
    p.setOriginalColor(inverted);
  }
  for (Particle p : particles3) {
    p.setOriginalColor(inverted);
  }
}

class Particle {
  PVector pos;
  PVector prevPos;
  PVector vel;
  PVector acc;
  float parentWidth;
  float parentHeight;
  int particleColor;
  int originalColor;
  float particleSize;

  Particle(float parentWidth, float parentHeight) {
    this.parentWidth = parentWidth;
    this.parentHeight = parentHeight;
    this.pos = new PVector(random(this.parentWidth), random(this.parentHeight));
    this.prevPos = pos.copy();
    this.vel = new PVector(0, 0);
    this.acc = new PVector(0, 0);
    setOriginalColor(inverted);
    this.particleColor = this.originalColor;
    this.particleSize = DEFAULT_PARTICLE_SIZE;
  }
  
  void setOriginalColor(boolean invertedState) {
    this.originalColor = invertedState ? color(0, 150) : color(255, 150);
  }

  void update(float flowSpeed, float flowScale) {
    this.prevPos = this.pos.copy();
    float n = noise(pos.x * flowScale, pos.y * flowScale, frameCount * flowSpeed);
    float angle = map(n, 0, 1, -PI, PI);
    PVector force = PVector.fromAngle(angle);
    force.add(new PVector(1, 0));
    acc.add(force);
    vel.add(acc);
    vel.limit(1);
    pos.add(vel);
    acc.mult(0);

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
  
  void display(float rectX, float rectY) {
    float distance = dist(mouseX, mouseY, rectX + pos.x, rectY + pos.y);
    float fadeDistance = 50; 

    if (distance < fadeDistance) {
      float t = map(distance, 0, fadeDistance, 1, 0);
      particleColor = lerpColor(color(255, 0, 0), originalColor, t);
      particleSize = lerp(DEFAULT_PARTICLE_SIZE, RED_PARTICLE_SIZE, t);
    } else {
      particleColor = lerpColor(particleColor, originalColor, DECAY_SPEED);
      particleSize = lerp(particleSize, DEFAULT_PARTICLE_SIZE, DECAY_SPEED);
    }
    
    stroke(particleColor);
    strokeWeight(particleSize);
    line(prevPos.x, prevPos.y, pos.x, pos.y);
  }
}
