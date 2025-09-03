PFont font;
//String fontURL = "https://fonts.gstatic.com/s/barlowsemicondensed/v7/wlpigxjLBV1hqnzfr-F8sEYMB0Yybp0mudRf-62_B2slqZ6GfQ.woff2";
//String fontURL = "http://www.dsa157.com/NFT/Arabic-font-2013.ttf";
//String fontURL = "https://fonts.gstatic.com/s/alfaslabone/v10/6NUQ8FmMKwSEKjnm5-4v-4Jh2d1he_escmAm9w.woff2";
String fontURL = "ManhattanDarling-Regular.otf";
String[] fontList = PFont.list();
String word="create";

void setup() {
  size(400, 400);
  // The font must be located in the sketch's 
  // "data" directory to load successfully
  font = createFont(fontURL, 128.0);
  background(0);
  int loops = 5000;
  for (int i=0; i<loops; i++) {
    drawText();
  }
  //rotate(0);
  textFont(font, 128);
  fill(255,255,0);
  text(word, 100,100);
}

void drawText() {
  font = createFont(fontList[int(random(0,fontList.length))], 64);
  textFont(font, 64);
  fill(random(1,255));
  rotate(random(0, PI/2));
  String letter = word.substring(random(0,word.length, 1);
  text(word, random(0,width), random(0,height));
}