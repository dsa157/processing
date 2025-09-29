int SEED = 157;
int PADDING = 40;
boolean INVERT_BACKGROUND = false;
int MAX_FRAMES = 1200;
boolean SAVE_FRAMES = false;
int ANIMATION_SPEED = 60;

int COLS = 5;
int ROWS = 8;
float CIRCLE_RADIUS = 20;

// Pendulum parameters
float PENDULUM_GRAVITY = 0.5;
float PIVOT_POINT_Y_OFFSET_ROWS = 5;
float MIN_SPEED_FACTOR = 0.8; 
float MAX_SPEED_FACTOR = 1.2; 

// Flow Field Parameters
float RESOLUTION = 5;
float Z_OFFSET = 0;
float Z_INCREMENT = 0.005;

// Particle Parameters
int NUM_PARTICLES = 15000;
float PARTICLE_RADIUS = 3;
float PARTICLE_MAX_SPEED = 10;
float DISRUPTION_FORCE = 500;
float PARTICLE_LIFESPAN_DECAY_RATE = 2;
float PARTICLE_MIN_LIFESPAN = 255;
float PARTICLE_MAX_LIFESPAN = 500;
color PARTICLE_COLOR_1 = color(128, 0, 128); // Purple
color PARTICLE_COLOR_2 = color(255, 255, 0); // Yellow

// Grid parameters
float cellWidth, cellHeight;
float gridX, gridY;

Pendulum[] pendulums;
Particle[] particles;
FlowField flowfield;

void setup() {
  size(480, 800);
  frameRate(ANIMATION_SPEED);

  if (INVERT_BACKGROUND) {
    background(255);
  } else {
    background(0);
  }

  randomSeed(SEED);

  // Calculate grid dimensions
  float gridWidth = width - (2 * PADDING);
  float gridHeight = height - (2 * PADDING);
  cellWidth = gridWidth / COLS;
  cellHeight = gridHeight / ROWS;

  // Center the grid on the canvas
  gridX = PADDING;
  gridY = PADDING;

  pendulums = new Pendulum[ROWS];
  PVector pivotPoint = new PVector(gridX + 2 * cellWidth + cellWidth / 2, gridY - PIVOT_POINT_Y_OFFSET_ROWS * cellHeight);

  for (int i = 0; i < ROWS; i++) {
    float pendulumLength = dist(pivotPoint.x, pivotPoint.y, gridX + 2 * cellWidth + cellWidth / 2, gridY + i * cellHeight + cellHeight / 2);
    pendulums[i] = new Pendulum(pivotPoint, pendulumLength);
  }
  
  flowfield = new FlowField(RESOLUTION);

  particles = new Particle[NUM_PARTICLES];
  for (int i = 0; i < NUM_PARTICLES; i++) {
    particles[i] = new Particle(random(width), random(-50, height));
  }
}

void draw() {
  if (INVERT_BACKGROUND) {
    background(255, 10);
    stroke(0);
    fill(0);
  } else {
    background(0, 10);
    stroke(255);
    fill(255);
  }

  for (int i = 0; i < ROWS; i++) {
    pendulums[i].update();
    pendulums[i].display();
  }
  
  for (int i = 0; i < ROWS - 1; i++) {
    stroke(255, 100);
    line(pendulums[i].position.x, pendulums[i].position.y, pendulums[i+1].position.x, pendulums[i+1].position.y);
  }

  flowfield.update();
  
  for (Particle p : particles) {
    p.follow(flowfield);
    p.disrupt(pendulums);
    p.update();
    p.display();
    if (p.isDead()) {
      p.respawn();
    }
  }

  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) {
      noLoop();
    }
  }
}

class Pendulum {
  PVector pivot;
  PVector position;
  float angle;
  float aVelocity = 0;
  float aAcceleration = 0;
  float len;
  float bobRadius;
  float speedFactor;

  Pendulum(PVector pivot_, float len_) {
    pivot = pivot_.copy();
    len = len_;
    position = new PVector();
    bobRadius = CIRCLE_RADIUS;
    speedFactor = random(MIN_SPEED_FACTOR, MAX_SPEED_FACTOR);

    float maxX = width - PADDING - bobRadius;
    float startX = gridX + 2 * cellWidth + cellWidth / 2;
    float dx = maxX - startX;
    angle = asin(dx / len);
  }

  void update() {
    aAcceleration = (-1 * PENDULUM_GRAVITY / len) * sin(angle);
    aVelocity += aAcceleration * speedFactor;
    angle += aVelocity;

    if (position.x > width - PADDING - bobRadius || position.x < PADDING + bobRadius) {
      aVelocity *= -1;
    }
  }

  void display() {
    position.set(pivot.x + len * sin(angle), pivot.y + len * cos(angle));

    strokeWeight(2);
    line(pivot.x, pivot.y, position.x, position.y);

    noStroke();
    fill(255, 150);
    circle(position.x, position.y, bobRadius * 2);
  }
}

class FlowField {
  PVector[][] field;
  int cols, rows;
  float resolution;

  FlowField(float resolution) {
    this.resolution = resolution;
    cols = floor(width / resolution);
    rows = floor(height / resolution);
    field = new PVector[cols][rows];
  }

  void update() {
    float xoff = 0;
    for (int i = 0; i < cols; i++) {
      float yoff = 0;
      for (int j = 0; j < rows; j++) {
        float angle = map(noise(xoff, yoff, Z_OFFSET), 0, 1, -PI/4, PI/4);
        field[i][j] = PVector.fromAngle(angle + PI/2);
        yoff += 0.1;
      }
      xoff += 0.1;
    }
    Z_OFFSET += Z_INCREMENT;
  }
}

class Particle {
  PVector position;
  PVector velocity;
  PVector acceleration;
  float maxspeed = PARTICLE_MAX_SPEED;
  float lifespan;
  color pColor;
  
  Particle(float x, float y) {
    acceleration = new PVector(0, 0);
    velocity = new PVector(0, 0);
    position = new PVector(x, y);
    // Initial lifespan is a random value, creating a continuous start.
    lifespan = random(PARTICLE_MIN_LIFESPAN, PARTICLE_MAX_LIFESPAN);
    if (random(1) > 0.5) {
      pColor = PARTICLE_COLOR_1;
    } else {
      pColor = PARTICLE_COLOR_2;
    }
  }

  void update() {
    velocity.add(acceleration);
    velocity.limit(maxspeed);
    position.add(velocity);
    acceleration.mult(0);
    lifespan -= PARTICLE_LIFESPAN_DECAY_RATE;
  }

  void applyForce(PVector force) {
    acceleration.add(force);
  }

  void follow(FlowField flow) {
    int x = floor(position.x / flow.resolution);
    int y = floor(position.y / flow.resolution);
    x = constrain(x, 0, flow.cols - 1);
    y = constrain(y, 0, flow.rows - 1);
    PVector force = flow.field[x][y];
    applyForce(force);
  }

  void disrupt(Pendulum[] pendulums) {
    for (Pendulum p : pendulums) {
      PVector repulsion = PVector.sub(this.position, p.position);
      float d = repulsion.mag();
      d = constrain(d, 5, 100);
      repulsion.normalize();
      float strength = (1 / (d * d));
      repulsion.mult(strength);
      repulsion.mult(DISRUPTION_FORCE);
      applyForce(repulsion);
    }
  }

  void display() {
    noStroke();
    fill(pColor, lifespan);
    circle(position.x, position.y, PARTICLE_RADIUS * 2);
  }
  
  boolean isDead() {
    return lifespan < 0;
  }
  
  void respawn() {
    position.set(random(width), random(-50, 0));
    velocity.set(0, 0);
    acceleration.set(0, 0);
    lifespan = random(PARTICLE_MIN_LIFESPAN, PARTICLE_MAX_LIFESPAN);
    if (random(1) > 0.5) {
      pColor = PARTICLE_COLOR_1;
    } else {
      pColor = PARTICLE_COLOR_2;
    }
  }
}
