int MAX_FRAMES = 600;
int SEED = 157; // use a constant seed for consistent results
int PADDING = 20;

// Rectangle dimensions
float rectHeight;
float rectWidth;

// Flow Field Config - Pane 1
int PARTICLE_COUNT_1 = 2500;
float FLOW_SPEED_1 = 0.01;
float FLOW_SCALE_1 = 0.05;

// Flow Field Config - Pane 2 
int PARTICLE_COUNT_2 = 5000;
float FLOW_SPEED_2 = 0.05;
float FLOW_SCALE_2 = 0.1;

// Flow Field Config - Pane 3 
int PARTICLE_COUNT_3 = 10000;
float FLOW_SPEED_3 = 0.1;
float FLOW_SCALE_3 = 0.2;

Particle[] particles1;
Particle[] particles2;
Particle[] particles3;

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

  fill(0, 20);
  rect(0, 0, width, height);
  
  // Top Rectangle: Flow Field 1
  pushMatrix();
  translate(PADDING, PADDING);
  stroke(255);
  strokeWeight(2);
  rect(0, 0, rectWidth, rectHeight);
  drawFlowField(particles1, FLOW_SPEED_1, FLOW_SCALE_1);
  popMatrix();

  // Middle Rectangle: Flow Field 2
  pushMatrix();
  translate(PADDING, PADDING * 2 + rectHeight);
  stroke(255);
  strokeWeight(2);
  rect(0, 0, rectWidth, rectHeight);
  drawFlowField(particles2, FLOW_SPEED_2, FLOW_SCALE_2);
  popMatrix();

  // Bottom Rectangle: Flow Field 3
  pushMatrix();
  translate(PADDING, PADDING * 3 + rectHeight * 2);
  stroke(255);
  strokeWeight(2);
  rect(0, 0, rectWidth, rectHeight);
  drawFlowField(particles3, FLOW_SPEED_3, FLOW_SCALE_3);
  popMatrix();
}

void drawFlowField(Particle[] particles, float flowSpeed, float flowScale) {
  // Use a clipping mask to contain the particles
  // A cleaner solution for drawing within a bounded area.
  rectMode(CORNER);
  
  beginShape();
  vertex(0, 0);
  vertex(rectWidth, 0);
  vertex(rectWidth, rectHeight);
  vertex(0, rectHeight);
  endShape(CLOSE);
  
  for (int i = 0; i < particles.length; i++) {
    particles[i].update(flowSpeed, flowScale);
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

  void update(float flowSpeed, float flowScale) {
    this.prevPos = this.pos.copy();
    float n = noise(pos.x * flowScale, pos.y * flowScale, frameCount * flowSpeed) * TWO_PI;
    PVector force = PVector.fromAngle(n);
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

  void display() {
    stroke(255, 255, 255, 150);
    strokeWeight(1);
    line(prevPos.x, prevPos.y, pos.x, pos.y);
  }
}
