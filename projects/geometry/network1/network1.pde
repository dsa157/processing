long seed = 12345;
PFont f;
String[] words = {"EMERGENCE", "RHYTHM", "CELESTIAL", "CONSTELLATION", "SPACE"};
int currentWordIndex = 0;
float lineDistance = 120;
int dotCount = 100;
float dotSize = 3.0;

ArrayList<Dot> currentDots = new ArrayList<Dot>();
ArrayList<Dot> targetDots = new ArrayList<Dot>();
ArrayList<Line> lines = new ArrayList<Line>();

int animationStage = 0; // 0: dots moving, 1: lines drawing
float lerpAmount = 0.05;
int lineDrawCounter = 0;
int linesToDrawPerFrame = 5;

void setup() {
  size(480, 800);
  randomSeed(seed);
  f = createFont("Arial", 100, true);
  textFont(f);
  
  createDotsForWord(words[currentWordIndex], currentDots);
  createDotsForWord(words[(currentWordIndex + 1) % words.length], targetDots);
  createLines();
}

void draw() {
  background(0);
  
  for (int i = 0; i < currentDots.size(); i++) {
    Dot d = currentDots.get(i);
    Dot t = targetDots.get(i);
    d.lerpTo(t, lerpAmount);
    d.display();
  }
  
  boolean allDotsReached = true;
  for (int i = 0; i < currentDots.size(); i++) {
    if (PVector.dist(currentDots.get(i).pos, targetDots.get(i).pos) > 1) {
      allDotsReached = false;
      break;
    }
  }

  if (allDotsReached && animationStage == 0) {
    animationStage = 1;
    lineDrawCounter = 0;
  }
  
  if (animationStage == 1) {
    for (int i = 0; i < min(lineDrawCounter, lines.size()); i++) {
      lines.get(i).display();
    }
    lineDrawCounter += linesToDrawPerFrame;
    if (lineDrawCounter > lines.size()) {
      animationStage = 2;
    }
  } else if (animationStage == 2) {
    for (Line l : lines) {
      l.display();
    }
    // New: After completing, immediately start the next transition
    if (frameCount % 120 == 0) { // Wait 2 seconds before transitioning
      transitionToNextWord();
    }
  }
}

void transitionToNextWord() {
  currentWordIndex = (currentWordIndex + 1) % words.length;
  createDotsForWord(words[currentWordIndex], targetDots);
  animationStage = 0;
  createLines();
}

void mouseClicked() {
  // Can still be used to force a transition
  if (animationStage != 0) {
    transitionToNextWord();
  }
}

void createDotsForWord(String s, ArrayList<Dot> dots) {
  dots.clear();
  float xOffset = (width - textWidth(s)) / 2;
  float yOffset = (height + textAscent()) / 2;
  
  for (int i = 0; i < dotCount; i++) {
    float x = random(width);
    float y = random(height);
    if (alpha(get((int)x, (int)y)) > 0) {
      dots.add(new Dot(new PVector(x, y)));
    } else {
      i--;
    }
  }
}

void createLines() {
  lines.clear();
  for (int i = 0; i < currentDots.size(); i++) {
    PVector p1 = currentDots.get(i).pos;
    for (int j = i + 1; j < currentDots.size(); j++) {
      PVector p2 = currentDots.get(j).pos;
      float d = PVector.dist(p1, p2);
      if (d < lineDistance) {
        lines.add(new Line(currentDots.get(i), currentDots.get(j), d));
      }
    }
  }
  lines.sort((l1, l2) -> Float.compare(l1.distance, l2.distance));
}

class Dot {
  PVector pos;
  color dotColor;
  
  Dot(PVector _pos) {
    pos = _pos.copy();
    dotColor = color(150, 200, 255, 200);
  }

  void lerpTo(Dot target, float amount) {
    pos = PVector.lerp(pos, target.pos, amount);
  }

  void display() {
    noStroke();
    fill(dotColor, 200);
    ellipse(pos.x, pos.y, dotSize * 2, dotSize * 2);
    fill(dotColor, 100);
    ellipse(pos.x, pos.y, dotSize * 5, dotSize * 5);
  }
}

class Line {
  Dot d1, d2;
  float distance;
  
  Line(Dot _d1, Dot _d2, float _dist) {
    d1 = _d1;
    d2 = _d2;
    distance = _dist;
  }
  
  void display() {
    noFill();
    strokeWeight(0.5);
    stroke(150, 200, 255, map(distance, 0, lineDistance, 255, 0));
    line(d1.pos.x, d1.pos.y, d2.pos.x, d2.pos.y);
  }
}

color get(int x, int y) {
  if (x >= 0 && x < width && y >= 0 && y < height) {
    return super.get(x, y);
  }
  return color(0, 0);
}
