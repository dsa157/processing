PImage img1, img2;
float transparency = 255;
 
void setup() {
  size(400, 599);
  img1 = loadImage("color.png");
  img2 = loadImage("color5.png");
}
 
void draw() {
  overlay();
}

void overlay() {
  //background(255);
  image(img2, 0, 0, width, height);
  tint(255, 125);
  image(img1, 0, 0, width, height);
}

void fade() {
  background(0);
  if (transparency > 0) { transparency -= 1.25; }
  tint(255, transparency);
  image(img1, 0, 0);
}
