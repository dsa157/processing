int x=80;
int x2=20;
int counter=1;

void setup(){
  size(400,400);
}

void draw(){
  background(255);
  // rect1
  counter++;
  noFill();
  pushMatrix();
    rectMode(CENTER);
    translate(x/2, x/2);
    rect(0, 0, x, x);
    translate(-x/2, -x/2);
    line(0,0,x,x);
    line(x,0,0,x);
  popMatrix();

  pushMatrix();
    translate((x/2),(x/2));
    rotate(counter*1*TWO_PI/360);
    //rotate(radians(45));
    rect(0, 0, x2, x2);
  popMatrix();


  pushMatrix();
    translate(x+(x/2), x/2);
    rect(0, 0, x, x);
  popMatrix();

  pushMatrix();
    translate(x+(x/2), x/2);
    rotate(counter*2*TWO_PI/360);
    rect(0, 0, x2, x2);
  popMatrix();

  pushMatrix();
    translate(2*x+(x/2), x/2);
    rect(0, 0, x, x);
  popMatrix();
  
}