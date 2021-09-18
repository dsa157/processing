import java.util.Date;
import java.text.DateFormat;
import java.text.SimpleDateFormat;

//int scriptAction = NFTAction.CREATE;
//int scriptAction = NFTAction.MINT;
int scriptAction = NFTAction.PLAY;

int maxDerivatives = 16;
int maxColorIterations = 10;
int maxZooms = 3;
int maxPaletteColors = 5;    // Innoculation: 3
float defaultBlur = 10.0;
int[] defaultTintOpacity = {128, 150}; // blurred image at 100/255 (~40%), color overlay at 128/255 (~50%)

boolean saveImage = true;
boolean saveMetaData = false;
boolean saveUnmodifiedImage = true;
boolean saveGradientImage = true;
boolean saveGrayImage = true;
boolean saveBlurredImage = false;
boolean saveOutputImage = true;
boolean overlayGray = false;

int maxImages = maxDerivatives * maxColorIterations * maxZooms;
int imageNdx = 0;
int derivativeCount = 1;
int click=1;

int playImageNum;
boolean playAnimationEnabled=false;
boolean playRandomEnabled=false;

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

static abstract class NFTAction {
  static final int CREATE = 0;
  static final int MINT = 1;
  static final int PLAY = 2;
}

int imageWidth, imageHeight;
int currentDerivative=0;
int currentZoom=0;
//int currentColorIteration=0;
BaseImage bImg;
DerivativeGenerator dg;

String actionPrefix = "";

void setup() {
  println("begin - " + timeStamp());
  init();
  if (scriptAction == NFTAction.CREATE) {
    generatePaletteAndGradients();
  }
  playImageNum = 1;
  frameRate(30);
}

void settings() {
  //  size(800,1118);    // Storm
  //  size(1600,1067);   // Innoculation      - zoom at 904,349
  //  size(800, 534);     // Innoculation small  - zoom at 452,176
  //  size(400,400);       // Mandala small
  size(1000, 750);    // david's Lyre - small    - zoom at 304,274
}

void init() {
  settings();
  imageWidth = width;
  imageHeight = height;
  imageMode(CENTER);
  colorMode(RGB, 255, 255, 255);
  background(255);

  if (scriptAction == NFTAction.MINT) {
    actionPrefix = "mint-";
  } 
  if (scriptAction == NFTAction.CREATE) {
    actionPrefix = "create-";
  } 
  if (scriptAction == NFTAction.PLAY) {
    actionPrefix = "play-";
  } 
  bImg = new BaseImage(imageList[0]);
  dg = new DerivativeGenerator(bImg, GradientType.EVEN);
}

void generatePaletteAndGradients() {
  for (int i=1; i<=maxColorIterations; i++) {
    dg.setColorIteration(i);
    dg.generatePaletteAndGradient();
  }
  for (int i=1; i<=maxColorIterations; i++) {
    dg.setColorIteration(i);
    dg.setGradient();
  }
}

void draw() {
  if (scriptAction == NFTAction.CREATE) {
    createNFTs();
  }
  if (scriptAction == NFTAction.MINT) {
    mintNFT(14);
  }
  if (scriptAction == NFTAction.PLAY) {
    playground();
  }
}

void createNFTs() {
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
    done();
  }
}

void mintNFT(int ndx) {
  noLoop();
  String[] dataRecord = loadData(ndx);
  image(bImg.getColorImg(), width/2, height/2, width, height);
  mintNFT(dataRecord);
  done();
}

void playground() {
  if (playAnimationEnabled) {
    click=1;
  }
  if (click == 1) {
    disableImageOutput();
    maxDerivatives = 16;
    maxColorIterations = 1;
    maxZooms = 1;
    int zl = int(random(1, 3));
    zl=1;
    click=0;
    tint(255, 255);
    if (playRandomEnabled) {
      playImageNum = int(random(1,maxDerivatives));
    }
    maxPaletteColors = int(random(3, 100));
    defaultBlur = random(3.0, 15.0);
    bImg = new BaseImage("Davids-Lyre-" + playImageNum + "-small.png");
    dg.setBaseImage(bImg);
    dg.setAllPalettes(maxPaletteColors);
    dg.generatePaletteAndGradient();
    dg.setColorIteration(1);
    dg.setZoomLevel(zl);
    dg.setGradient();
    dg.mapColors();
  }
}

void mousePressed() {
  click=1;
}

void keyPressed() {
  if (key == 's' || key == 'S') {
    dg.saveImageMetaData();
    click=1;
  }
  if (key == 'q' || key == 'Q') {  // [Q]uit
    done();
  }
  if (key == 'c' || key == 'C') {  // [C]ycle
    click=1;
  }
  if (key == 'n' || key == 'N') {   // [N]ext
    playImageNum++;
    if (playImageNum > maxDerivatives) {
      playImageNum=1;
    }
    click=1;
  }
  if (key == 'p' || key == 'P') {   // [P]revious
    playImageNum--;
    if (playImageNum == 0) {
      playImageNum=maxDerivatives;
    }
    click=1;
  }
  if (key == 'a' || key == 'A') {   // [A]nimate
    playAnimationEnabled = !playAnimationEnabled;
    click=1;
  }
  if (key == 'r' || key == 'R') {   // [R]andom
    playRandomEnabled = !playRandomEnabled;
    click=1;
  }
}


void mintNFT(String[] dataRecord) {
  saveGradientImage = true;
  saveUnmodifiedImage = true;
  saveGrayImage = true;
  String imageName = dataRecord[2];
  String baseImageName = dataRecord[3];
  String zoomLevel = dataRecord[4];
  String colorIteration = dataRecord[5];
  String palette = dataRecord[6];
  //println("Color Iteration: " + colorIteration);
  //println("Zoom Level: " + zoomLevel);
  //println("Palette: " + palette);
  bImg = new BaseImage(baseImageName);
  dg.setBaseImage(bImg);
  dg.setZoomLevel(int(zoomLevel));
  dg.setColorIteration(int(colorIteration));
  dg.generatePalette(palette);
  dg.generateGradient();
  dg.mapColors(int(zoomLevel));
}

void done() {
  println("done - " + timeStamp());
  dg.closeWriter();
  exit();
}

String[] loadData(int ndx) {
  String[] data = loadStrings("create-metadata.csv");
  String[] dataRecord = split(data[ndx], ",");
  println(data[ndx]);
  return dataRecord;
}

void disableImageOutput() {
  saveImage = false;
}

String timeStamp() {
  DateFormat formatter = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
  Date d = new Date();
  String ts = formatter.format(d);
  return ts;
}
