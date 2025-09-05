int SEED = 12345 * millis() * millis();
int PADDING = 40;
boolean INVERT_COLORS = false;
int MAX_FRAMES = 600;
boolean SAVE_FRAMES = false;
int ANIMATION_SPEED = 30;
float STROKE_WEIGHT = 2.0;
int RECURSION_DEPTH = 5;
float[] FRACTIONS = {1.0/2.0, 1.0/3.0};
float SPLIT_THRESHOLD = 0.5; // Changed to make vertical split less likely
float BOTH_SPLIT_THRESHOLD = 0.1; // Adjusted to maintain split probabilities
float CIRCLE_RADIUS = 17.0;
float MOVE_SPEED = 0.1;

boolean SHOW_START_POINTS = true;
boolean SHOW_END_POINTS = false;
boolean MOVE_START_POINT = true;
boolean MOVE_END_POINT = false;

int bg_color;
int shape_color;
int start_point_color;
int end_point_color;

ArrayList<PVector> points;
ArrayList<CircleMover> movers;
ArrayList<Rect> grid_rects;

void setup() {
  size(480, 800);
  
  if (INVERT_COLORS) {
    bg_color = 0;
    shape_color = 255;
  } else {
    bg_color = 255;
    shape_color = 0;
  }
  
  start_point_color = color(255, 0, 0);
  end_point_color = color(255, 0, 0);
  
  randomSeed(SEED);
  frameRate(ANIMATION_SPEED);
  
  points = new ArrayList<PVector>();
  movers = new ArrayList<CircleMover>();
  grid_rects = new ArrayList<Rect>();

  int x = PADDING;
  int y = PADDING;
  int w = width - PADDING * 2;
  int h = height - PADDING * 2;
  
  grid_rects.add(new Rect(x, y, w, h));
  
  calculateGrid(x, y, w, h, 0);
  
  for (PVector p : points) {
    movers.add(new CircleMover(p));
  }
}

void draw() {
  background(bg_color);
  
  drawGrid();
  
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
  if (depth >= RECURSION_DEPTH) {
    if (MOVE_START_POINT) {
      points.add(new PVector(x, y));
    }
    if (MOVE_END_POINT) {
      points.add(new PVector(x + w, y + h));
    }
    return;
  }
  
  float fraction = FRACTIONS[int(random(FRACTIONS.length))];
  float choice = random(1);

  if (choice < BOTH_SPLIT_THRESHOLD) {
    float new_w = w * fraction;
    float new_h = h * fraction;
    
    grid_rects.add(new Rect(x, y, new_w, new_h));
    grid_rects.add(new Rect(x + new_w, y + new_h, w - new_w, h - new_h));
    
    calculateGrid(x, y, new_w, new_h, depth + 1);
    calculateGrid(x + new_w, y + new_h, w - new_w, h - new_h, depth + 1);
    
  } else if (choice < SPLIT_THRESHOLD) {
    float new_w = w * fraction;
    
    grid_rects.add(new Rect(x, y, new_w, h));
    grid_rects.add(new Rect(x + new_w, y, w - new_w, h));
    
    calculateGrid(x, y, new_w, h, depth + 1);
    calculateGrid(x + new_w, y, w - new_w, h, depth + 1);

  } else {
    float new_h = h * fraction;
    
    grid_rects.add(new Rect(x, y, w, new_h));
    grid_rects.add(new Rect(x, y + new_h, w, h - new_h));
    
    calculateGrid(x, y, w, new_h, depth + 1);
    calculateGrid(x, y + new_h, w, h - new_h, depth + 1);
  }
}

void drawGrid() {
  stroke(shape_color);
  strokeWeight(STROKE_WEIGHT);
  noFill();
  for (Rect r : grid_rects) {
    rect(r.x, r.y, r.w, r.h);
  }
}

class Rect {
  float x, y, w, h;
  Rect(float x, float y, float w, float h) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
  }
}

class CircleMover {
  PVector current_pos;
  PVector target_pos;
  int my_color;

  CircleMover(PVector start_pos) {
    current_pos = start_pos.copy();
    target_pos = start_pos.copy();
    my_color = start_point_color;
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
    
    if (MOVE_START_POINT && MOVE_END_POINT) {
      if (points.indexOf(destination) % 2 == 0) {
        my_color = start_point_color;
      } else {
        my_color = end_point_color;
      }
    } else if (MOVE_START_POINT) {
        my_color = start_point_color;
    } else {
        my_color = end_point_color;
    }
  }

  void display() {
    fill(my_color);
    noStroke();
    ellipse(current_pos.x, current_pos.y, CIRCLE_RADIUS, CIRCLE_RADIUS);
  }
}
