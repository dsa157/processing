float w = 30.0;
int w1 = 30;
int cols = 20;
int offset = 50;
MyCircle[] circles = new MyCircle[cols];
int framecount = 0;

void setup() {
  //frameRate(150);
  size(800, 600);
  noStroke();
  background(0);
  for (int i=0; i<cols; i++) {
    MyCircle c = new MyCircle();
    circles[i] = c;
    c.display();
  }
  fill(255);
}

void mousePressed() {
  exit();
}

void draw() {
  //if (millis() % 5 == 0) {
    boolean allDead = true;
    for (int i=0; i<cols; i++) {
      MyCircle c = circles[i];
      if (c.isAlive()) {
        allDead = false;
      }
      int myRand = int(random(4));
      if ((myRand > 0) && (i % myRand == 0)) {
        c.run();
        println("Index: ", i, myRand, framecount);
      }
    }
    framecount++;
    
    if (allDead) {
      setup();
      //rect(100,100,100,100);
      //noLoop();
    }
  //}
}

//-------------------------------

class MyCircle {
  PShape s;
  int lifespan = 255;
  boolean isDead = false;
  int radius, x, y;
  
  MyCircle () { //<>//
    init();
  }
  
  void init() {
    x = int(random(width-offset));
    y = int(random(height-offset));
    radius = (int(random(w1))+1)*3;
    lifespan = 255;
    fill(255);
    s = createShape(ELLIPSE, x, y, radius,radius);
    s.setStroke(0);
    s.setFill(255);
  }
  
  void run() {
    update();
    display();
  }
  
  PShape getShape() {
    return s;
  }
  
  boolean isAlive() {
    return (isDead == false);
  }
  
  void update() {
    int lifespanDecrement = 1;
    if (lifespan < 0) {
      lifespan = lifespanDecrement;
    }
    if (lifespan > 0) {
      lifespan -= lifespanDecrement;
    }
    else {
      init();
      //isDead = true;
    }
  }
  
  void display() {
    //translate(offset, offset);
    if (lifespan > 0) {
      s.setFill(lifespan);
      s.setStroke(lifespan);
      //translate(10,10);
      shape(getShape());
    }
    //translate(-offset, -offset);
  }
}
