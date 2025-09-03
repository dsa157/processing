PImage img, img2; 

void setup() {
  int t = millis();

  //flip();
  mirrorLeft();
  //mirrorLeft();
  //image(img, 0, 0);                                          // show original
  image(img2, 0, 0);  
  println("done in " + (millis()-t) + "ms");
}

void settings() {
  size(1000, 750);
  img = loadImage("http://dsa157.com/NFT/Davids-Lyre-1-small.png");
  img2 = createImage(img.width, img.height, RGB);       // make a empty image half size
}

void mirrorRight() {
  for (int y = 0; y < img.height; y++) {
    for (int x = img.width/2; x < img.width; x++) {        // take the right half only
      img2.set(img.width-x-1, y, img.get(x, y));           // and set mirror position
    }
  }
}


void mirrorLeft() {
  for (int y = 0; y < img.height; y++) {
    for (int x = 0; x < img.width/2; x++) {        // take the right half only
      img2.set(img.width-x-1, y, img.get(img.width-x-1, y));     // and set mirror position
    }
  }
}


void test() {
  image(img, 0, 0);
  pushMatrix();
  scale(-1, 1);//flip on X axis
  popMatrix();
  image(img, -img.width, img.height);//draw offset
}

void flip() {
  for (int y = 0; y < img.height; y++) {
    for (int x = 0; x < img.width; x++) {
      img2.set(img.width-x-1, y, img.get(x, y));
    }
  }

  image(img, 0, 0);
  //image(img2, width/2, 0, width, height);
  image(img2, 0,0);
}
