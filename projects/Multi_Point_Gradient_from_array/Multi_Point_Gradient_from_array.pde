int maxDerivatives = 1;
int maxColorIterations = 3;
int maxZooms = 3;
int maxPaletteColors = 5;

int maxImages = maxDerivatives * maxColorIterations * maxZooms;
int imageCount = 1;

//String imageList[] = {
//  "The-Gathering-Storm-NFT-00001ps.png",
//  "The-Gathering-Storm-NFT-00002ps.png",
//  "The-Gathering-Storm-NFT-00003ps.png"
//};

//String imageList[] = {
//  "Innoculation-NFT-00001.png",
//  "Innoculation-NFT-00002.png",
//  "Innoculation-NFT-00003.png"
//};

String imageList[] = {
  "Mandala-1a-1.png",
  "Mandala-1a-2.png",
  "Mandala-1a-3.png"
};


//--------------------------------------

DerivativeGenerator dg;
int imageWidth, imageHeight;
BaseImage bImg;

void setup() {
//  size(800,1118);    // Storm
//  size(1600,1067);   // Innoculation
//  size(800,534);     // Innoculation small
  size(400,400);       // Mandala small
  imageWidth = width;
  imageHeight = height;
  imageMode(CENTER);
  
  bImg = new BaseImage(imageList[0]);
  dg = new DerivativeGenerator(bImg, RAND);
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
