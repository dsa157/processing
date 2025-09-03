long seed = 12345;
PFont f;
String[] words = {"ABC", "DEF", "GHI", "JKL", "MNO"};
int currentWordIndex = 0;
float lineDistance = 120;
float lineWeight = 1.0;
int dotCount = 250;
float dotSize = 5;
float mouseInfluenceRadius = 150;
float mouseForceStrength = 5;

ArrayList<Dot> currentDots = new ArrayList<Dot>();
ArrayList<Dot> targetDots = new ArrayList<Dot>();
color originalColor;

PVector simulatedMouse;
float angle = 0;
int CHANGE_WORD_FRAMES = 200;
int MAXFRAMES = 600;
boolean SAVEFRAMES = true;

void setup() {
  size(480, 800);
  randomSeed(seed);
  f = createFont("Arial", 100, true);
  textFont(f);
  originalColor = color(150, 200, 255);
  simulatedMouse = new PVector(width / 2, height / 2);
  
  createDotsForWord(words[currentWordIndex], currentDots);
  createDotsForWord(words[(currentWordIndex + 1) % words.length], targetDots);
}

void draw() {
  background(0);
  
  simulatedMouse.x = width / 2 + cos(angle) * 100;
  simulatedMouse.y = height / 2 + sin(angle) * 200;
  angle += 0.02;

  for (int i = 0; i < currentDots.size(); i++) {
    Dot d = currentDots.get(i);
    Dot t = targetDots.get(i);
    
    PVector distVec = PVector.sub(d.pos, simulatedMouse);
    float d_dist = distVec.mag();
    
    if (d_dist < mouseInfluenceRadius) {
      float strength = map(d_dist, 0, mouseInfluenceRadius, mouseForceStrength, 0);
      distVec.normalize();
      distVec.mult(strength);
      d.pos.sub(distVec); // Change here: subtract to attract
      d.setTargetColor(color(255, 255, 0));
    } else {
      d.setTargetColor(originalColor);
    }
    
    d.dotColor = lerpColor(d.dotColor, d.targetColor, 0.1);

    d.lerpTo(t, 0.05);
    d.display();
  }
  
  noFill();
  strokeWeight(lineWeight);
  for (int i = 0; i < currentDots.size(); i++) {
    Dot d1 = currentDots.get(i);
    PVector p1 = d1.pos;
    for (int j = i + 1; j < currentDots.size(); j++) {
      Dot d2 = currentDots.get(j);
      PVector p2 = d2.pos;
      float d = PVector.dist(p1, p2);
      if (d < lineDistance) {
        color lineColor = lerpColor(d1.dotColor, d2.dotColor, 0.5);
        stroke(lineColor, map(d, 0, lineDistance, 255, 0));
        line(p1.x, p1.y, p2.x, p2.y);
      }
    }
  }

  boolean allDotsReached = true;
  for (int i = 0; i < currentDots.size(); i++) {
    if (PVector.dist(currentDots.get(i).pos, targetDots.get(i).pos) > 1) {
      allDotsReached = false;
      break;
    }
  }

  if (allDotsReached || (frameCount % CHANGE_WORD_FRAMES == 0)) {
      transitionToNextWord();
  }
  
  if (SAVEFRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAXFRAMES) {
      noLoop();
    }
  }

}

void transitionToNextWord() {
  currentWordIndex = (currentWordIndex + 1) % words.length;
  createDotsForWord(words[currentWordIndex], targetDots);
}

void mouseClicked() {
  transitionToNextWord();
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

class Dot {
  PVector pos;
  color dotColor;
  color targetColor;
  
  Dot(PVector _pos) {
    pos = _pos.copy();
    dotColor = originalColor;
    targetColor = originalColor;
  }

  void setTargetColor(color newColor) {
    targetColor = newColor;
  }
  
  void lerpTo(Dot target, float amount) {
    pos.lerp(target.pos, amount);
  }

  void display() {
    noStroke();
    fill(dotColor, 200);
    ellipse(pos.x, pos.y, dotSize * 2, dotSize * 2);
    //fill(dotColor, 100);
    //ellipse(pos.x, pos.y, dotSize * 5, dotSize * 5);
  }
}

color get(int x, int y) {
  if (x >= 0 && x < width && y >= 0 && y < height) {
    return super.get(x, y);
  }
  return color(0, 0);
}
