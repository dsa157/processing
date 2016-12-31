float counter;
PImage img;
int sz = 50;

int num = 10;
int[] x = new int[num];
int[] y = new int[num];


void setup()
{
  counter=0.0;
  size(400,400);
  img=loadImage("thea.jpg");
}

void draw()
{
  background(0);
  counter++;
  translate(width/2, height/2);
  rect(0,0,100,100);
  rotate(counter*TWO_PI/360);
  translate(-25,-25);
  translate(-img.width/2, -img.height/2);
  // rect(-26, -26, 52, 52);
  image(img,0,0);
} 