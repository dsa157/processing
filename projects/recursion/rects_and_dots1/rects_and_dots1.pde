int SEED = 12345 * millis();
int PADDING = 40;
boolean INVERT_COLORS = false;
int MAX_FRAMES = 600;
boolean SAVE_FRAMES = false;
int ANIMATION_SPEED = 60;
float STROKE_WEIGHT = 2.0;
int RECURSION_DEPTH = 7;
float[] FRACTIONS = {1.0/2.0, 1.0/3.0, 1.0/4.0, 1.0/5.0};
float SPLIT_THRESHOLD = 0.33;
float BOTH_SPLIT_THRESHOLD = 0.5;
float CIRCLE_RADIUS = 10.0;
float MOVE_SPEED = 0.03;

int bg_color;
int shape_color;
int circle_color;

ArrayList<PVector> points;
ArrayList<CircleMover> movers;

// This will store the pre-calculated grid structure
ArrayList<Rectangle> grid_rects;

void setup() {
  size(480, 800);
  
  if (INVERT_COLORS) {
    bg_color = 0;
    shape_color = 255;
  } else {
    bg_color = 255;
    shape_color = 0;
  }
  
  circle_color = color(255, 0, 0);
  
  randomSeed(SEED);
  frameRate(ANIMATION_SPEED);
  
  points = new ArrayList<PVector>();
  movers = new ArrayList<CircleMover>();
  grid_rects = new ArrayList<Rectangle>();

  int x = PADDING;
  int y = PADDING;
  int w = width - PADDING * 2;
  int h = height - PADDING * 2;
  
  // Calculate and store the grid and points once
  calculateGrid(x, y, w, h, 0);
  
  // Create the movers after the points are generated
  for (PVector p : points) {
    movers.add(new CircleMover(p));
  }
}

void draw() {
  background(bg_color);
  
  // Draw the static grid
  drawGrid();
  
  // Animate the movers
  for (CircleMover m : movers) {
    m.move();
    m.display();
  }

  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
  }
  
  if (frameCount >= MAX_FRAMES && SAVE_FRAMES) {
    noLoop();
  }
}

void calculateGrid(float x, float y, float w, float h, int depth) {
  points.add(new PVector(x, y));
  
  if (depth >= RECURSION_DEPTH) {
    grid_rects.add(new Rectangle(x, y, w, h));
    points.add(new PVector(x + w, y));
    points.add(new PVector(x, y + h));
    points.add(new PVector(x + w, y + h));
    return;
  }
  
  float fraction = FRACTIONS[int(random(FRACTIONS.length))];
  float choice = random(1);

  if (choice < BOTH_SPLIT_THRESHOLD) {
    float new_w = w * fraction;
    float new_h = h * fraction;
    
    calculateGrid(x, y, new_w, new_h, depth + 1);
    calculateGrid(x + new_w, y + new_h, w - new_w, h - new_h, depth + 1);
    
  } else if (choice < (1 - (1 - BOTH_SPLIT_THRESHOLD) / 2)) {
    float new_w = w * fraction;
    
    calculateGrid(x, y, new_w, h, depth + 1);
    calculateGrid(x + new_w, y, w - new_w, h, depth + 1);

  } else {
    float new_h = h * fraction;
    
    calculateGrid(x, y, w, new_h, depth + 1);
    calculateGrid(x, y + new_h, w, h - new_h, depth + 1);
  }
}

void drawGrid() {
  stroke(shape_color);
  strokeWeight(STROKE_WEIGHT);
  noFill();
  for (Rectangle r : grid_rects) {
    rect(r.x, r.y, r.w, r.h);
  }
}

class Rectangle {
  float x, y, w, h;
  Rectangle(float x, float y, float w, float h) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
  }
}

class CircleMover {
  PVector current_pos;
  PVector target_pos;

  CircleMover(PVector start_pos) {
    current_pos = start_pos.copy();
    target_pos = start_pos.copy();
  }

  void move() {
    if (current_pos.dist(target_pos) < 0.1) {
      setNewTarget();
    }
    
    current_pos.x = lerp(current_pos.x, target_pos.x, MOVE_SPEED);
    current_pos.y = lerp(current_pos.y, target_pos.y, MOVE_SPEED);
  }
  
  void setNewTarget() {
    PVector destination = points.get(int(random(points.size())));
    target_pos = destination.copy();
  }

  void display() {
    fill(circle_color);
    noStroke();
    ellipse(current_pos.x, current_pos.y, CIRCLE_RADIUS, CIRCLE_RADIUS);
  }
}
