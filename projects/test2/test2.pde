
int counter=5;
int angle = 10;

void setup(){
  size(400,400);
}

void draw() {
    rectMode(CENTER);
    pushMatrix();
    translate(200,200);
    MySquare s1 = new MySquare(0,0,100);
    s1.display();
//    rotate(counter*5*TWO_PI/360);
//    rotate(radians(angle));
    MySquare s2 = new MySquare(0,0,40);
    s2.display();
    println(s1.topLeftX(), s1.topLeftY(), s2.topLeftX(), s2.topLeftY());
    popMatrix();

    pushMatrix();
      noFill();
      ellipseMode(CORNER);
      translate(200,200);
      ellipse(-30, -30, 20, 20);
    popMatrix();
}

class MySquare {
  
  float x,y,w;
  
  MySquare(float x1, float y1, float w1) {
    x=x1;
    y=y1;
    w=w1;
  }
  
  float topLeftX() {
    return x;
  }
  
  float topLeftY() {
    return y;
  }

  float bottomLeftX() {
    return x;
  }

  float bottomLeftY() {
    return y+w;
  }

  float topRightX() {
    return x+w;
  }
  
  float topRightY() {
    return y;
  }

  float bottomRightX() {
    return x+w;
  }

  float bottomRightY() {
    return y+w;
  }

  void display() {
    rect(0,0,w, w);
  }
}