int SEED = 12345;
int PADDING = 0;
boolean INVERT_BG = false;
int MAX_FRAMES = 900;
boolean SAVE_FRAMES = true;
int ANIMATION_SPEED = 30;

float STEP_SIZE = 10;
float PROB_FORK = 0.5;
int MAX_WALKERS = 10000;
int MIN_LIFESPAN = 150;
int MAX_LIFESPAN = 300;
float MIN_SIZE = 3;
float MAX_SIZE = 7;
float ATTRACTION_STRENGTH = 0.9;
float FADE_SPEED = 5;

// Phase Durations
int ORDER_DURATION = 300;
int CHAOS_DURATION = 300;

color[] walkerColors = {#F288A4, #4968A6, #3FBFBF, #F2C36B, #F2E9D8};

ArrayList<Walker> walkers;
PFont font;
PGraphics orderGraphics;
PGraphics chaosGraphics;

int textPhase = 0; // 0: morphing from chaos to order, 1: morphing from order to chaos
int currentPhaseFrame;
float currentHorizontalStrength;

String textOrder = "ORDER";
String textChaos = "CHAOS";
float textSize = 80;

void setup() {
  size(480, 800);
  frameRate(ANIMATION_SPEED);
  
  if (INVERT_BG) {
    background(0);
  } else {
    background(255);
  }

  noiseSeed(SEED);
  randomSeed(SEED);

  font = createFont("Arial Black", textSize);
  
  orderGraphics = createGraphics(width, height);
  drawTextToGraphics(orderGraphics, textOrder);

  chaosGraphics = createGraphics(width, height);
  drawTextToGraphics(chaosGraphics, textChaos);

  walkers = new ArrayList<Walker>();
  for (int i = 0; i < MAX_WALKERS; i++) {
    walkers.add(new Walker(random(width - 2 * PADDING), random(height - 2 * PADDING)));
  }
  
  // Start with CHAOS phase
  textPhase = 0;
  currentPhaseFrame = frameCount;
}

void draw() {
  if (INVERT_BG) {
    fill(0, 50);
  } else {
    fill(255, 50);
  }
  noStroke();
  rect(0, 0, width, height);
  
  updatePhase();
  
  float orderAlpha = 0;
  float chaosAlpha = 0;
  
  if (textPhase == 0) {
    currentHorizontalStrength = map(frameCount, currentPhaseFrame, currentPhaseFrame + CHAOS_DURATION, 0, 1);
    chaosAlpha = map(frameCount, currentPhaseFrame, currentPhaseFrame + CHAOS_DURATION, 255, 0);
    orderAlpha = map(frameCount, currentPhaseFrame, currentPhaseFrame + CHAOS_DURATION, 0, 255);
  } else if (textPhase == 1) {
    currentHorizontalStrength = map(frameCount, currentPhaseFrame, currentPhaseFrame + ORDER_DURATION, 1, 0);
    orderAlpha = map(frameCount, currentPhaseFrame, currentPhaseFrame + ORDER_DURATION, 255, 0);
    chaosAlpha = map(frameCount, currentPhaseFrame, currentPhaseFrame + ORDER_DURATION, 0, 255);
  }

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

  // Draw the text in the background color to be invisible
  if (INVERT_BG) {
    fill(0, orderAlpha);
    textFont(font);
    textAlign(CENTER, CENTER);
    textSize(textSize);
    text(textOrder, width/2, height/2);

    fill(0, chaosAlpha);
    text(textChaos, width/2, height/2);
  } else {
    fill(255, orderAlpha);
    textFont(font);
    textAlign(CENTER, CENTER);
    textSize(textSize);
    text(textOrder, width/2, height/2);

    fill(255, chaosAlpha);
    text(textChaos, width/2, height/2);
  }

  if (SAVE_FRAMES) {
    if (frameCount <= MAX_FRAMES) {
      saveFrame("frames/####.tif");
    } else {
      noLoop();
    }
  }
}

void updatePhase() {
  if (textPhase == 0) {
    if (frameCount > currentPhaseFrame + CHAOS_DURATION) {
      textPhase = 1;
      currentPhaseFrame = frameCount;
    }
  } else if (textPhase == 1 && frameCount > currentPhaseFrame + ORDER_DURATION) {
    textPhase = 0;
    currentPhaseFrame = frameCount;
  }
}

void drawTextToGraphics(PGraphics pg, String txt) {
  pg.beginDraw();
  pg.background(255);
  pg.fill(0);
  pg.textFont(font);
  pg.textAlign(CENTER, CENTER);
  pg.textSize(textSize);
  pg.text(txt, width/2, height/2);
  pg.endDraw();
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
    PVector newPos = new PVector();
    
    float horizonalMovementX = 0;
    float horizonalMovementY = 0;

    if (currentHorizontalStrength > 0) {
      horizonalMovementX = 1;
      horizonalMovementY = 0;
    }

    float randomMovementX = random(-1, 1);
    float randomMovementY = random(-1, 1);
    
    newPos.x = pos.x + (horizonalMovementX * currentHorizontalStrength * STEP_SIZE) + (randomMovementX * (1 - currentHorizontalStrength) * STEP_SIZE);
    newPos.y = pos.y + (horizonalMovementY * currentHorizontalStrength * STEP_SIZE) + (randomMovementY * (1 - currentHorizontalStrength) * STEP_SIZE);
    
    pos = newPos;

    if (pos.x > width - 2 * PADDING) {
      pos.x = random(-200, 0);
    }
    
    pos.y = constrain(pos.y, 0, height - 2 * PADDING);

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
