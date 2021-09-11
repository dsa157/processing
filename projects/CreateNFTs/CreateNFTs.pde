int maxDerivatives = 3;
int maxColorIterations = 10;
int maxZooms = 3;
int maxPaletteColors = 7;
boolean saveMetaData = false;
boolean saveGradientImage = false;
boolean saveOutputImage = true;


int maxImages = maxDerivatives * maxColorIterations * maxZooms;
int imageCount = 1;

//String imageList[] = {
//  "The-Gathering-Storm-NFT-00003ps.png",
//  "The-Gathering-Storm-NFT-00002ps.png",
//  "The-Gathering-Storm-NFT-00001ps.png"
//};

String imageList[] = {
//  "Innoculation-NFT-00002.png",
  "Innoculation-NFT-00001.png",
  "Innoculation-NFT-00003.png"
};
int zoomX = 452;
int zoomY = 176;

//String imageList[] = {
//  "Mandala-1a-3.png",
//  "Mandala-1a-2.png",
//  "Mandala-1a-1.png"
//};


//--------------------------------------

DerivativeGenerator dg;
int imageWidth, imageHeight;
BaseImage bImg;
int currentDerivative=0;
int currentZoom=0;
int currentColorIteration=0;


void setup() {
//  size(800,1118);    // Storm
//  size(1600,1067);   // Innoculation      - zoom at 904,349
  size(800,534);     // Innoculation small  - zoom at 452,176
//  size(400,400);       // Mandala small
  imageWidth = width;
  imageHeight = height;
  imageMode(CENTER);
  
  background(255);
  //stroke(255);
  //noStroke();
}

//BaseImage getNextImage() {
//  BaseImage b new BaseImage(imageList[currentDerivative]);
//}

void draw() {
  if (frameCount <= maxColorIterations) {
    println("frameCount: " + frameCount);
    for (int i=0; i<maxDerivatives; i++) {
      bImg = new BaseImage(imageList[i]);
      dg = new DerivativeGenerator(bImg, EVEN);
      dg.setColorIteration(frameCount);
      dg.generateGradient();
      dg.mapColors();
    }
  } 
  else {
    println("done.");
    exit();
  }
}
