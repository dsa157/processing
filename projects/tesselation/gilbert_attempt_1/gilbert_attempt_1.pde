import java.util.ArrayList;
import java.util.Collections;

int SEED = 12345;
int PADDING = 40;
int MAX_FRAMES = 600;
int ANIMATION_SPEED = 30;
boolean SAVE_FRAMES = false;
boolean INVERT_BG = false;

int bg_color;
int fg_color;

float x_min, y_min, x_max, y_max;
int NUM_CRACKS = 800;
float CRACK_SPEED = 10;
float LINE_THICKNESS = 1.5;

ArrayList<Crack> cracks = new ArrayList<Crack>();
ArrayList<Integer> palette = new ArrayList<Integer>();

void setup() {
  size(480, 800);
  randomSeed(SEED);
  colorMode(HSB, 360, 100, 100);

  if (INVERT_BG) {
    bg_color = 0;
    fg_color = 255;
  } else {
    bg_color = 255;
    fg_color = 0;
  }
  
  x_min = PADDING;
  y_min = PADDING;
  x_max = width - PADDING;
  y_max = height - PADDING;

  generateCracks();
  frameRate(ANIMATION_SPEED);
}

void draw() {
  background(bg_color);
  
  pushMatrix();
  translate(x_min, y_min);

  stroke(fg_color);
  strokeWeight(LINE_THICKNESS);
  
  for (Crack c : cracks) {
    c.update();
    c.display();
  }

  popMatrix();
  
  boolean allStopped = true;
  for (Crack c : cracks) {
    if (c.isMoving) {
      allStopped = false;
      break;
    }
  }

  if (allStopped || frameCount >= MAX_FRAMES) {
    if (SAVE_FRAMES && frameCount <= MAX_FRAMES) {
      saveFrame("frames/####.tif");
    }
    noLoop();
  }
  
  if (SAVE_FRAMES && frameCount <= MAX_FRAMES) {
    saveFrame("frames/####.tif");
  }
}

void generateCracks() {
  for (int i = 0; i < NUM_CRACKS; i++) {
    PVector start = new PVector(random(x_max - x_min), random(y_max - y_min));
    float angle = random(TWO_PI);
    cracks.add(new Crack(start, angle));
  }
}

// Line-segment intersection function
PVector getIntersection(PVector p1, PVector p2, PVector p3, PVector p4) {
  float den = (p1.x - p2.x) * (p3.y - p4.y) - (p1.y - p2.y) * (p3.x - p4.x);
  if (den == 0) return null; // Lines are parallel or collinear

  float t = ((p1.x - p3.x) * (p3.y - p4.y) - (p1.y - p3.y) * (p3.x - p4.x)) / den;
  float u = -((p1.x - p2.x) * (p1.y - p3.y) - (p1.y - p2.y) * (p1.x - p3.x)) / den;

  if (t >= 0 && t <= 1 && u >= 0 && u <= 1) {
    return new PVector(p1.x + t * (p2.x - p1.x), p1.y + t * (p2.y - p1.y));
  }
  return null;
}

class Crack {
  PVector pos;
  PVector prevPos;
  PVector dir;
  boolean isMoving = true;
  ArrayList<PVector> path = new ArrayList<PVector>();

  Crack(PVector start, float angle) {
    pos = start.copy();
    prevPos = start.copy();
    dir = PVector.fromAngle(angle);
    dir.mult(CRACK_SPEED);
    path.add(pos.copy());
  }

  void update() {
    if (!isMoving) return;

    PVector nextPos = PVector.add(pos, dir);

    // Check for collision with other cracks
    for (Crack other : cracks) {
      if (other == this) continue;

      for (int i = 0; i < other.path.size() - 1; i++) {
        PVector otherP1 = other.path.get(i);
        PVector otherP2 = other.path.get(i + 1);

        PVector intersection = getIntersection(pos, nextPos, otherP1, otherP2);
        
        if (intersection != null) {
          isMoving = false;
          pos = intersection.copy(); // Snap to the intersection point
          path.add(pos.copy());
          return; // Stop checking this crack
        }
      }
    }
    
    // Check for boundary collision
    if (nextPos.x < 0 || nextPos.x > x_max - x_min || nextPos.y < 0 || nextPos.y > y_max - y_min) {
      isMoving = false;
    }
    
    // Update position if no collision
    prevPos = pos.copy();
    pos = nextPos.copy();
    path.add(pos.copy());
  }

  void display() {
    beginShape();
    noFill();
    for (PVector p : path) {
      vertex(p.x, p.y);
    }
    endShape();
  }
}
