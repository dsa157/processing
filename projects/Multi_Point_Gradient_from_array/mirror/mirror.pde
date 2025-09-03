PImage img; 

void setup() {
  img = loadImage("Davids-Lyre-1-small.png");
  int t = millis();

  PImage mirror = createImage(img.width, img.height, RGB);//create a new image with the same dimensions
  
  for (int x = 0; x < mirror.width; x++) {                               //loop through each columns
    println("xxx " + x);
    mirror.set(mirror.width-x-1, 0, img.get(x, 0, 1, img.height));       //copy a column in reverse x order
  }

  println("done in " + (millis()-t) + "ms");

  //image(img, 0, 0);
  image(mirror, 0, img.height);
}

void settings() {
  size(1000, 750);
}
