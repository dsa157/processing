int SEED = 12345;
int PADDING = 10;
boolean INVERT_BG = false;
int MAX_FRAMES = 600;
boolean SAVE_FRAMES = false;
int ANIMATION_SPEED = 30;

float STEP_SIZE = 5;
int INITIAL_STEPS = 100;
float PROB_FORK = 0.5;
int MAX_WALKERS = 5000;
int MIN_LIFESPAN = 150;
int MAX_LIFESPAN = 300;
float MIN_SIZE = 3;
float MAX_SIZE = 7;

color[] walkerColors = {#F288A4, #4968A6, #3FBFBF, #F2C36B, #F2E9D8};

ArrayList<Walker> walkers;

void setup() {
  size(480, 800);
  background(255);
  frameRate(ANIMATION_SPEED);
  if (INVERT_BG) {
    background(0);
  }

  noiseSeed(SEED);
  randomSeed(SEED);

  walkers = new ArrayList<Walker>();
  for (int i = 0; i < MAX_WALKERS; i++) {
    walkers.add(new Walker(random(width - 2 * PADDING), random(height - 2 * PADDING)));
  }
}

void draw() {
  if (INVERT_BG) {
    fill(0, 50);
  } else {
    fill(255, 50);
  }
  noStroke();
  rect(0, 0, width, height);

  pushMatrix();
  translate(PADDING, PADDING);

  for (int i = walkers.size() - 1; i >= 0; i--) {
    Walker w = walkers.get(i);
    w.update();
    w.display();
    if (!w.isAlive()) {
      walkers.remove(i);
    }
  }

  while (walkers.size() < MAX_WALKERS) {
    walkers.add(new Walker(random(width - 2 * PADDING), random(height - 2 * PADDING)));
  }

  popMatrix();

  if (SAVE_FRAMES) {
    if (frameCount <= MAX_FRAMES) {
      saveFrame("frames/####.tif");
    } else {
      noLoop();
    }
  }
}

class Walker {
  PVector pos;
  int lifespan;
  float size;
  color walkerColor;

  Walker(float x, float y) {
    pos = new PVector(x, y);
    lifespan = int(random(MIN_LIFESPAN, MAX_LIFESPAN));
    size = random(MIN_SIZE, MAX_SIZE);
    walkerColor = walkerColors[int(random(walkerColors.length))];
  }

  void update() {
    float dx = random(-1, 1);
    float dy = random(-1, 1);

    PVector newPos = new PVector(pos.x + dx * STEP_SIZE, pos.y + dy * STEP_SIZE);

    newPos.x = constrain(newPos.x, 0, width - 2 * PADDING);
    newPos.y = constrain(newPos.y, 0, height - 2 * PADDING);

    pos = newPos;

    lifespan--;
  }

  void display() {
    float opacity = map(lifespan, 0, MAX_LIFESPAN, 0, 255);
    stroke(red(walkerColor), green(walkerColor), blue(walkerColor), opacity);
    strokeWeight(size);
    point(pos.x, pos.y);
  }

  boolean isAlive() {
    return lifespan > 0;
  }
}
