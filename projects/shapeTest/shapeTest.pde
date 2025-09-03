// fork from https://openprocessing.org/sketch/923148

float xoff;
float yoff;
float offinc=0.01;
float s=100;
float m=1;
float sc=1;
float mc=0.01;

void setup() {
  size(640,480);
  background(0);
  drawShape();
}

void drawShape() {
  translate(width/2, height/2);
  s+=sc;
  m+=mc;
  xoff+=offinc;
  yoff+=offinc;
  beginShape();
  int maxNumber=100;
  stroke(s%255, 100);
  for(int i=0; i<maxNumber; i++){
    float d=TAU/maxNumber*i;
    PVector p=PVector.fromAngle(d);
    float n=noise(p.x+xoff, p.y+yoff);
    p.mult(n*s);
    vertex(p.x, p.y);
  }  
  endShape(CLOSE);
  //noLoop();
}

void draw() {
}

void mouseClicked() {
  drawShape();
  println(s);
}