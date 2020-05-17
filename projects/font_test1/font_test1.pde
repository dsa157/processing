PFont myFont;

void setup() {
  size(400,400);
  myFont = createFont("Univers", 48);
  background(255);
  for (int i=0; i<400; i=i+20) {
    for (int j=0; j<400; j=j+20) {
      fill(0,0,0, random(abs(i-150)));
      textFont(myFont, abs(i-330));
      text("T", i, random(j));
    }
  }
}  