int w=80;
int w2=20;
int counter=1;
float angle =0.0;
float x0 = 0.0;
float y0 = 0.0;
float x1 = 0.0;
float y1 = 0.0;
float p = 0.0;
float q = 0.0;
float p1 = 0.0;
float q1 = 0.0;

void setup(){
  size(400,400);
}

void draw(){
  background(255);
  // rect1
  counter++;
  noFill();
  p = w/2;
  q = w/2;
  p1 = p - w2/2;
  q1 = q - w2/2;
  frameRate(1);
  
  pushMatrix();
    rectMode(CENTER);
    translate(p, q);
    rect(x0, y0, w, w);
    translate(-p, -q);
    line(x0,y0,w,w);
    line(w,y0,x0,w);
  popMatrix();

  pushMatrix();
    translate(p,q);
    angle = 15;
    rotate(radians(angle));
    //rotate(radians(45));
    rect(0, 0, w2, w2);
  popMatrix();

  x1 = ((x0-p1) * cos(angle)) - ((y0-q1) * sin(angle)) + p1;
  y1 = ((x0-p1) * sin(angle)) + ((y0-q1) * cos(angle)) + q1;
  ellipse(x1,y1,20,20);

    
}