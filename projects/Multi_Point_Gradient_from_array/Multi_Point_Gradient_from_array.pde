//int[] palette0 = {#287994,  #E09B53, #54BEE0, #78DDFF, #945819};

// actual simplified color palettes from Gathering Storm created from https://color.adobe.com/create/image
//int[] palette1 = {#2A2859, #44428C, #222140, #8C7D32, #73653C};

int maxColorIterations = 3;
int maxZooms = 3;
int maxPaletteColors = 5;
//String colorImage = "Storm.png";
//String colorImage = "Innoculation-NFT-00001.jpg";
String colorImage = "Mandala-1a-2.png";

DerivativeGenerator dg;
PImage colorImg;
//int frameCount = 0;
String outFilePrefix = colorImage.substring(0, colorImage.length()-4);
int imageWidth, imageHeight;

void setup() {
//  size(800,1118);    // Storm
//  size(1600,1067);   // Innoculation
//  size(800,534);     // Innoculation small
  size(400,400);       // Mandala small
  imageWidth = width;
  imageHeight = height;
  imageMode(CENTER);
  colorImg = loadImage(colorImage);
  dg = new DerivativeGenerator(colorImg, RAND);
  background(255);
  //stroke(255);
  //noStroke();
}

void draw() {
  if (frameCount <= maxColorIterations) {
     dg.setColorIteration(frameCount);
     dg.draw();
    //g.drawDiscreteColors(discreteColors);
    dg.mapColors();
  } 
  else {
    exit();
  }
}
