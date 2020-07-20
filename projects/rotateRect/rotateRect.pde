float counter;
int sz = 50;
int myFill=200;
int myBG=100;
int DECAY = 150; 

void setup()
{
  counter=0.0;
  size(400,400);
  fill(255);
  //stroke(255);
}

void decay() {
  myFill--;
  myBG++;
  if (myFill == DECAY) { 
    myFill = 200;
    myBG=100;
  }
}

void draw()
{
  background(0);
  counter++;
  translate(width/2, height/2);
  rotate(counter*TWO_PI/360);
  translate(-sz/2, -sz/2);
  decay();
  fill(myFill);
  arc(0, 0, sz, sz, 0, PI, OPEN);
  rect(0, 0, sz, sz);
} 