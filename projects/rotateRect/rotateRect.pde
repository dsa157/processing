float counter;
int sz = 50;

void setup()
{
  counter=0.0;
  size(400,400);
  fill(255);
  stroke(255);
}

void draw()
{
  background(0);
  counter++;
  translate(width/2, height/2);
  rotate(counter*TWO_PI/360);
  translate(-sz/2, -sz/2);
  rect(0, 0, sz, sz);
} 