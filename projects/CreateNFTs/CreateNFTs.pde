import java.util.Date;
import java.text.DateFormat;
import java.text.SimpleDateFormat;

//int scriptAction = NFTAction.CREATE;
int scriptAction = NFTAction.MINT;

int maxDerivatives = 2;
int maxColorIterations = 2;
int maxZooms = 2;
int maxPaletteColors = 5;    // Innoculation: 3
float defaultBlur = 10.0;
int[] defaultTintOpacity = {128, 150}; // blurred image at 100/255 (~40%), color overlay at 128/255 (~50%)

boolean saveMetaData = false;
boolean saveUnmodifiedImage = true;
boolean saveGradientImage = true;
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

static abstract class NFTAction {
  static final int CREATE = 0;
  static final int MINT = 1;
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
  background(0);

  if (scriptAction == NFTAction.MINT) {
    actionPrefix = "mint-";
  } else {
    actionPrefix = "create-";
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
  } else {
    mintNFT(14);
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
  image(bImg.getColorImg(), width/2, height/2, imageWidth, imageHeight);
  mintNFT(dataRecord);
  done();
}

void mintNFT(String[] dataRecord) {
  String imageName = dataRecord[1];
  String baseImageName = dataRecord[2];
  String zoomLevel = dataRecord[3];
  String colorIteration = dataRecord[4];
  String palette = dataRecord[5];
  //println("Color Iteration: " + colorIteration);
  //println("Palette: " + palette);
  bImg = new BaseImage(baseImageName);
  dg.setBaseImage(bImg);
  dg.generatePalette(palette);
  saveGradientImage = false;
  saveUnmodifiedImage = false;
  saveGrayImage = false;
  dg.generateGradient();
  dg.setColorIteration(int(colorIteration));
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

String timeStamp() {
  DateFormat formatter = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
  Date d = new Date();
  String ts = formatter.format(d);
  return ts;
}
