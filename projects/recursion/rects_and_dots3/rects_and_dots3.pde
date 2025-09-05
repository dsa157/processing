int SEED = 12345 * millis() * millis();
int PADDING = 10;
boolean INVERT_COLORS = false;
int MAX_FRAMES = 600;
boolean SAVE_FRAMES = false;
int ANIMATION_SPEED = 30;
float STROKE_WEIGHT = 2.0;
int RECURSION_DEPTH = 5;
float[] FRACTIONS = {1.0/2.0, 1.0/3.0};
float CIRCLE_RADIUS = 17.0;
float MOVE_SPEED = 0.1;

boolean SHOW_START_POINTS = true;
boolean SHOW_END_POINTS = false;
boolean MOVE_START_POINT = true;
boolean MOVE_END_POINT = false;

int MAX_FILLED_RECTS = 9;
boolean FILL_RECTS = true;
int MAX_CIRCLES = 40;

int bg_color;
int shape_color;
int start_point_color;
int end_point_color;

ArrayList<PVector> points;
ArrayList<CircleMover> movers;
ArrayList<Rect> grid_rects;
ArrayList<Rect> last_level_rects;

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
  last_level_rects = new ArrayList<Rect>();

  int x = PADDING;
  int y = PADDING;
  int w = width - PADDING * 2;
  int h = height - PADDING * 2;
  
  grid_rects.add(new Rect(x, y, w, h));
  
  calculateGrid(x, y, w, h, 0);
  if (FILL_RECTS) {
    fillRandomRects();
  }
  
  for (int i = 0; i < MAX_CIRCLES; i++) {
    int randomPointIndex = (int)random(points.size());
    movers.add(new CircleMover(points.get(randomPointIndex)));
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
    if (frameCount >= MAX_FRAMES) {
      noLoop();
    }
  }
}

void calculateGrid(float x, float y, float w, float h, int depth) {
  if (depth >= RECURSION_DEPTH) {
    last_level_rects.add(new Rect(x, y, w, h));
    points.add(new PVector(x, y));
    points.add(new PVector(x + w, y));
    points.add(new PVector(x, y + h));
    points.add(new PVector(x + w, y + h));
    return;
  }
  
  float fraction = FRACTIONS[int(random(FRACTIONS.length))];
  
  if (depth % 2 == 0) { // Vertical split
    float new_w = w * fraction;
    
    grid_rects.add(new Rect(x, y, new_w, h));
    grid_rects.add(new Rect(x + new_w, y, w - new_w, h));
    
    calculateGrid(x, y, new_w, h, depth + 1);
    calculateGrid(x + new_w, y, w - new_w, h, depth + 1);

  } else { // Horizontal split
    float new_h = h * fraction;
    
    grid_rects.add(new Rect(x, y, w, new_h));
    grid_rects.add(new Rect(x, y + new_h, w, h - new_h));
    
    calculateGrid(x, y, w, new_h, depth + 1);
    calculateGrid(x, y + new_h, w, h - new_h, depth + 1);
  }
}

void fillRandomRects() {
  ArrayList<Integer> indices = new ArrayList<Integer>();
  for (int i = 0; i < last_level_rects.size(); i++) {
    indices.add(i);
  }
  
  for (int i = 0; i < MAX_FILLED_RECTS && indices.size() > 0; i++) {
    int randomIndex = (int)random(indices.size());
    int rectIndex = indices.get(randomIndex);
    last_level_rects.get(rectIndex).isFilled = true;
    indices.remove(randomIndex);
  }
  
  grid_rects.addAll(last_level_rects);
}

void drawGrid() {
  for (Rect r : grid_rects) {
    if (r.isFilled) {
      fill(shape_color);
      noStroke();
    } else {
      noFill();
      stroke(shape_color);
    }
    rect(r.x, r.y, r.w, r.h);
  }
}

class Rect {
  float x, y, w, h;
  boolean isFilled;

  Rect(float x, float y, float w, float h) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.isFilled = false;
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
    PVector new_target;
    boolean occupied;

    do {
      int randomIndex = (int)random(points.size());
      new_target = points.get(randomIndex);
      occupied = false;
      for (CircleMover other_mover : movers) {
        if (other_mover != this && other_mover.target_pos.equals(new_target)) {
          occupied = true;
          break;
        }
      }
    } while (occupied);

    target_pos = new_target.copy();
    my_color = start_point_color;
  }

  void display() {
    fill(my_color);
    noStroke();
    ellipse(current_pos.x, current_pos.y, CIRCLE_RADIUS, CIRCLE_RADIUS);
  }
}
