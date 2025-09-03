PGraphics textureLayer;

void setup() {
  size(1000,750);
  background(255);
  noFill();
  textureLayer = createGraphics(width, height);
  //drawCircles();
  drawDiagonals();
  frameRate(1);
}

void draw() {
  background(255);
  drawDiagonals();
}

void drawCircles() {
  for (int i=0; i<500; i++) {
    int x = int(random(0, width));
    int y = int(random(0, height)); 
    int r = int(random(10, 200));
    circle(x,y,r);
  }
}

void drawDiagonals() {
  for (int i=0; i<500; i++) {
    int x1 = int(random(20, width-20));
    int y1 = int(random(20, height-20)); 
    int x2 = int(random(100, width-100));
    int y2 = int(random(100, height-100)); 
    line(x1, y1, x2, y2);
  }
}
