PImage img, img2;

void setup() {
  size(1000, 750);
  smooth();  
  background(0);
  img = loadImage("http://dsa157.com/NFT/Davids-Lyre-1-small.png"); 
  img2 = img.get();
  mirrorLeft();
  //mirrorRight();
}

void mirrorLeft() {
  pushMatrix(); 
  translate(width, 0); 
  scale(-1.0, 1.0); 
  image(img2, width/2, 0, width, height);
  popMatrix();
  image(img, width/2, 0, width, height);
}

void mirrorRight() {
  pushMatrix(); 
  translate(width, 0); 
  scale(1.0, -1.0); 
  image(img2, width/2, 0, width, height);
  popMatrix();
  image(img, width/2, 0, width, height);
}
