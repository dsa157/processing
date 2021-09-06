int sz = 500; //<>// //<>// //<>// //<>//
float w = 500;
int skipFrames = 1;
int cols=1;
int rows=1;
//PShape c1, c2, c3, arc1, arc2, arc3, arc4, arc5, arc6;
boolean NO_SCALE = true;
YinYang y1, y11, y12, y111, y112, y121, y122;

void setup()
{
  size(400, 400);
  background(0);
  noStroke();
  y1 = new YinYang(width, 255, 0, 2); 
  y1.display();
/*  y11 = new YinYang((y1.w)/2, y1.myBG, y1.myFill); 
  y11.display();
  y111 = new YinYang((y11.w)/2, y11.myBG, y11.myBG); 
  y111.display();
  y112 = new YinYang((y11.w)/2, y11.myFill, y11.myFill); 
  y112.display();
*/
}


void draw()
{
  if (frameCount % skipFrames == 0) {
    background(0);
    noStroke();
    y1.display();

  }
} 

//----------------------------------------------------------------------

class OuterCircle {
}

//----------------------------------------------------------------------

class YinYang {
  float counter = 0.0;
  int w;
  PShape s, arc1, arc2;
  int myFill = 255;
  int myBG = 0;
  int myX = width/2;
  int myY = height/2;
  int level = 0;
  int speed = 1;
  int position = -1;
  YinYang a, b, c, d;

  YinYang(int w1, int f, int bg, int lvl) {
    w=w1;
    level = lvl;
    myFill = f;
    myBG = bg;
    init();
  }

  YinYang(int w1, int x, int fill1, int bg1, int l1) {
    w=w1;
    myX = x;
    myFill = fill1;
    myBG = bg1;
    level = l1;
    speed = level * 2;
    init();
  }

  void init() {
    pushMatrix();
    rectMode(CENTER);
    s = createShape(GROUP);
    fill(myBG);
    arc1 = createShape(ELLIPSE, myX, myY, w, w);
    fill(myFill);
    arc2 = createShape(ARC, myX, myY, w, w, 0, PI, OPEN);
    s.addChild(arc1);
    s.addChild(arc2);
    if (level == 1) {
      a = new YinYang(w/2, w/4, myFill, myBG, level+1);
      b = new YinYang(w/2, w-w/4, myFill, myBG, level+1);
      s.addChild(a.getShape());
      s.addChild(b.getShape());
    }
    if (level == 2) {
      a = new YinYang(w/2, w/4, myFill, myFill, level+1);
      b = new YinYang(w/2, w-w/4, myBG, myBG, level+1);
      //c = new YinYang(w/2, w+w/4, myFill, myFill, level+1);
      //d = new YinYang(w/2, (2*w)-w/4, myBG, myBG, level+1);
      s.addChild(a.getShape());
      s.addChild(b.getShape());
      //s.addChild(c.getShape());
      //s.addChild(d.getShape());
    }
    if (level == 3) {
      addDot();
    }
    shape(s);
    popMatrix();
  }

  void addDot() {
    print("addDot\n");
    fill(0);
    if (myFill == 0) {
      fill(255);
    }
    PShape s = createShape(ELLIPSE, myX, myY, w/2, w/2);
    getShape().addChild(s);
  }


  void setScale(boolean b) {
    //myScale = b;
  }

  PShape getShape() {
    return s;
  }

  void rotateShape() {
    counter++;
    translate(w/2, w/2);
    rotate(speed * counter*TWO_PI/360);
    translate(-w/2, -w/2);
  }

  void scaleShape() {
    /*    int i = int(random(0,2));
     //i=0;
     if ((i == 0) && (myScale != NO_SCALE)) {
     int j = int(random(0,4));
     if (j==0) { translate(-w/4,-w/4); }
     if (j==1) { translate(-w/4,w/4); }
     if (j==2) { translate(w/4,-w/4); }
     if (j==3) { translate(w/4,w/4); }
     }
     */
     scale(0.5);

  } //<>//

  void display() {
    pushMatrix(); //<>//
    //noStroke();

    translate(0,(w/4));
    scaleShape();
    if (a != null) {
      //a.display();
      //a.rotateShape();
    }
    if (b != null) {
      //b.display();
      //b.rotateShape();
    }
    rotateShape();

    //rotateShape();
    shape(getShape());
    popMatrix();
  }
}
