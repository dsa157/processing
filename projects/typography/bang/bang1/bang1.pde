
void setup() {
  background(#ffffff);
  size(900,900);
  
}

void draw() {
  int tiles=10;
  int tileSize=width/tiles;
  
  fill(0);
  for (int x=0; x<tileSize; x++) {
    for (int y=0; y<tileSize; y++) {
      push();
      translate(x*tileSize, y*tileSize);
      //ellipse(0,0,10,10);
      textSize(128);
      text("!", 10, 10);
      pop();
    }
  }
}
