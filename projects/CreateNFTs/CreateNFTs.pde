int maxDerivatives = 2;
int maxColorIterations = 3;
int maxZooms = 1;
int maxPaletteColors = 5;    // Innoculation: 3
float defaultBlur = 10.0;
int[] defaultTintOpacity = {128, 150}; // blurred image at 100/255 (~40%), color overlay at 128/255 (~50%)

boolean saveMetaData = false;
boolean saveUnmodifiedImage = true;
boolean saveGradientImage = false;
boolean saveGrayImage = true;
boolean saveBlurredImage = false;
boolean saveOutputImage = true;
boolean overlayGray = false;

int maxImages = maxDerivatives * maxColorIterations * maxZooms;
int imageNdx = 0;
int imageCount = 1;

//String imageList[] = {
//  "The-Gathering-Storm-NFT-00003ps.png",
//  "The-Gathering-Storm-NFT-00002ps.png",
//  "The-Gathering-Storm-NFT-00001ps.png"
//};

//String imageList[] = {
//  //  "Innoculation-NFT-00002.png",
//  "Innoculation-NFT-00001.png", 
//  "Innoculation-NFT-00003.png"
//};

String imageList[] = {
  "Davids-Lyre-1-NFT.png", 
  "Davids-Lyre-2-NFT.png", 
  "Davids-Lyre-3-NFT.png", 
  "Davids-Lyre-4-NFT.png", 
  "Davids-Lyre-5-NFT.png", 
  "Davids-Lyre-6-NFT.png", 
  "Davids-Lyre-7-NFT.png", 
  "Davids-Lyre-8-NFT.png", 
  "Davids-Lyre-9-NFT.png", 
  "Davids-Lyre-10-NFT.png", 
  "Davids-Lyre-11-NFT.png", 
  "Davids-Lyre-12-NFT.png", 
  "Davids-Lyre-13-NFT.png", 
  "Davids-Lyre-14-NFT.png", 
  "Davids-Lyre-15-NFT.png", 
  "Davids-Lyre-16-NFT.png"
};

int zoomX = 304;
int zoomY = 274;

//String imageList[] = {
//  "Mandala-1a-3.png",
//  "Mandala-1a-2.png",
//  "Mandala-1a-1.png"
//};


//--------------------------------------

int imageWidth, imageHeight;
int currentDerivative=0;
int currentZoom=0;
//int currentColorIteration=0;
BaseImage bImg;
DerivativeGenerator dg;

void setup() {
  //  size(800,1118);    // Storm
  //  size(1600,1067);   // Innoculation      - zoom at 904,349
  //size(800, 534);     // Innoculation small  - zoom at 452,176
  //  size(400,400);       // Mandala small
  size(1000, 750);    // david's Lyre - small    - zoom at 304,274
  imageWidth = width;
  imageHeight = height;
  imageMode(CENTER);
  colorMode(RGB, 255, 255, 255);
  background(0);
  bImg = new BaseImage(imageList[0]);;
  dg = new DerivativeGenerator(bImg, EVEN);
  for (int i=1; i<=maxColorIterations; i++) {
      dg.setColorIteration(i);
      dg.generateGradient();
  }
  for (int i=0; i<dg.allPalettes.length; i++) {
    dg.myPalette = dg.allPalettes[i];
    //println(dg.savePaletteAsHexStrings());
  }
  for (int i=1; i<=maxColorIterations; i++) {
      dg.setColorIteration(i);
      dg.setGradient();
    }
  //noLoop();
}

void draw() {
  //exit();
  if (frameCount <= maxDerivatives) {
    bImg = new BaseImage(imageList[imageNdx]);
    dg.setBaseImage(bImg);
    for (int i=1; i<=maxColorIterations; i++) {
      dg.setColorIteration(i);
      dg.setGradient();
      dg.mapColors();
    }
    imageNdx++;
  } else {
    println("done.");
    dg.closeWriter();
    exit();
  }
}
