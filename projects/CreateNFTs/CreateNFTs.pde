import java.util.Date;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Map;
import java.io.*;
import java.util.Random;
import java.lang.Math;
import java.security.SecureRandom;

//--------------------------------------

static abstract class NFTAction {
  static final int CREATE1 = 0;
  static final int CREATE_ALL = 1;
  static final int MINT = 2;
  static final int PLAY = 3;
  static final int ANIMATE = 4;
  static final int BLENDER = 5;
  static final int CLI = 6;
}

// -- script action default variables --
//int scriptAction = NFTAction.CREATE;
//int scriptAction = NFTAction.MINT;
//int scriptAction = NFTAction.PLAY;
int scriptAction = NFTAction.CLI;
String actionPrefix = "";

// -- app global variables --
int imageWidth, imageHeight;
int currentDerivative=0;
int currentZoom=0;
String imageList[] = {};
String defaultImageFile = "remote.txt";
BaseImage bImg;
DerivativeGenerator dg;
PaletteManager paletteManager;
int click=1;
static int logLevel = LogLevel.INFO;
HashMap<String, String> params = new HashMap<String, String>();
int zoomX = 0;
int zoomY = 0;

// -- image configuration default variables --
int maxDerivatives = 20;
int maxColorIterations = 14;
int maxZooms = 3;
int maxPaletteColors = 5;    
int defaultMinPaletteColors = 3;
int defaultMaxPaletteColors = 50;
float defaultBlur = 10.0;
float defaultMinBlur = 3.0;
float defaultMaxBlur = 15.0;

int zoomLevel=1;
int[] defaultTintOpacity = {128, 150}; // blurred image at 100/255 (~40%), color overlay at 128/255 (~50%)
int maxImages = maxDerivatives * maxColorIterations * maxZooms;
int imageNdx = 0;
int derivativeCount = 1;

// -- output variables --
boolean saveImage = true;
boolean saveMetaData = false;
boolean saveCVSMetaData = false;
boolean saveUnmodifiedImage = false;
boolean saveGradientImage = false;
boolean saveGrayImage = false;
boolean saveBlurredImage = false;
boolean saveOutputImage = true;
boolean overlayGray = false;
boolean recordedCVSMetaData = false;

// -- PRNG variables --
SecureRandom sr;
String hash = ""; 
String defaultHash = "dsa157+gen.art=awesome";

// -- play mode variables --
int playImageNum=1;
int playZoomLevel=1;
int[] playTintOpacity = defaultTintOpacity;
boolean playAutoEnabled=false;
boolean playRandomEnabled=false;
boolean playBWEnabled=false;
boolean playChangeGradient=true;
boolean playOpacityDefault = true;

// -- mint mode variables --
int mintRecNum;
String mintDataRecords[];

// -- blend mode variables --
PGraphics bgLayer;
int maxLayer2Combinations = maxDerivatives;


//--------------------------------------

void setRandSeed() {
  if (hash == "") {
    hash = defaultHash;
  }
println("hash=" + hash);
  sr.setSeed(hash.getBytes());
}

public float getRandomFloat(float min, float max) {
  float factor = max - min;
  return sr.nextFloat() * factor + min;
}

public int getRandomInt(int min, int max) {
  max=max+1; // increment here so that code is more readable for the range we want to be inclusive
  return (int) ((Math.random() * (max - min)) + min);
}

//--------------------------------------
// help text variables

PGraphics helpTextLayer;
PImage helpImage;
PFont font;
boolean showHelpTextLayer = false;



//-----------------------------------------------

void setup() {
  try {
    Logger.info("setup");

    init();
//    if (scriptAction == NFTAction.CLI) {
      processArguments();
//    }
    sr = SecureRandom.getInstance("SHA1PRNG");     
    setRandSeed();

    if (scriptAction == NFTAction.CREATE1) {
      generatePaletteAndGradients();
    }
    if (scriptAction == NFTAction.CREATE_ALL) {
      generatePaletteAndGradients();
    }
    playImageNum = 1;
    frameRate(10);
  }
  catch (Exception e) {
    fatalException(e);
  }
}

void settings() {
  //  size(800,1118);    // Storm
  //  size(1600,1067);   // Innoculation      - zoom at 904,349
  //  size(800, 534);     // Innoculation small  - zoom at 452,176
  //  size(400,400);       // Mandala small
  //size(1000, 750);    // david's Lyre - small    
  //size(500, 375);    // david's Lyre - small    
  size(800, 600);    // david's Lyre - small
}

void init() {
  Logger.info("init");
  settings();
  imageWidth = width;
  imageHeight = height;
  imageMode(CENTER);
  colorMode(RGB, 255, 255, 255);
  background(255);
  setActionPrefix();
  bgLayer = createGraphics(width, height);
  bImg = new BaseImage("");
  dg = new DerivativeGenerator(bImg, GradientSliceType.EVEN);
  paletteManager = new PaletteManager();
  setupHelpTextLayers();
}

void draw() {
  if (scriptAction == NFTAction.CREATE1) {
    createNFT();
  }
  if (scriptAction == NFTAction.CREATE_ALL) {
    generateCollection();
  }
  if (scriptAction == NFTAction.MINT) {
    mintNFTs();
  }
  if (scriptAction == NFTAction.PLAY) {
    playground();
  }
  if (scriptAction == NFTAction.ANIMATE) {
    animate();
  }
  if (scriptAction == NFTAction.BLENDER) {
    blend();
    done();
  }
  if (scriptAction == NFTAction.CLI) {
    // we shouldn't be in this mode when we get to the draw method
    done();
  }
}

void setupHelpTextLayers() {
  helpTextLayer = createGraphics(width, height);
  //helpTextBackgroundLayer = createGraphics(width, height);
  //String[] fontList = PFont.list();
  font = createFont("Courier", 18, true);

  helpTextLayer.beginDraw();
  helpTextLayer.background(0, 0, 0, 150);
  helpTextLayer.fill(color(255, 255, 255, 255));
  helpTextLayer.noStroke();
  helpTextLayer.textFont(font);
  helpTextLayer.textAlign(LEFT);
  helpTextLayer.text(getHelpText(), 40, 80);
  helpTextLayer.translate(width, height);
  helpTextLayer.endDraw();

  //helpTextBackgroundLayer.beginDraw();
  //helpTextBackgroundLayer.background(0,0,0,150);
  //helpTextBackgroundLayer.translate(width/2, height/2);
  //helpTextBackgroundLayer.endDraw();
  helpImage = loadImage("http://dsa157.com/NFT/Davids-Lyre-1-small.png");
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

void createNFT() {
  noLoop();
  maxColorIterations=1;
  saveMetaData=true;
  saveImage=true;
  // this will randomly determine if it should create a layer1 or layer2 design
//  if (getRandomInt(1, 2) == 1) {
    int i = getRandomInt(1, maxDerivatives);
    generate1LayerImage(i-1, 0);
//  } else {
//    println("coming soon...");
//  }
  done();
}

void generateCollection() {
  try {
    noLoop();
    generateOriginalImages();
    generate1LayerImages();
    generate2LayerImages();
  }
  catch(Exception e) {
    fatalException(e);
  }
  done();
}

void generateOriginalImages() {
  generateOriginalImages(0);  // original and gray
  for (int i=1; i<maxDerivatives; i++) {
    generateOriginalImages(i);  // each original derivative and gray
  }
}

void generateOriginalImages(int ndx) {
  Logger.fine("generateOriginalImages " + ndx);
  maxImages = 1;
  derivativeCount = 1;
  saveImage=true;
  saveGradientImage=false;
  saveMetaData=true;
  saveImage=false;
  bImg = new BaseImage(imageList[ndx]);
  dg.setLayer1Name(imageList[ndx]);
  dg.setDesignType((ndx==0) ? "original" : "derivative");
  dg.setBaseImage(bImg);
  dg.zoom(bImg.getColorImg(), zoomLevel);
  String suffix = "-orig";
  dg.saveImage(suffix);
  dg.saveImageMetaData(suffix);
  dg.zoom(bImg.getGrayImg(), zoomLevel);
  suffix = "-gray";
  dg.saveImage(suffix);
  dg.saveImageMetaData(suffix);
}

void generate1LayerImages() {
  Logger.fine("generate1LayerImages");
  saveGradientImage=false;
  saveMetaData=true;
  saveImage=false;
  //maxColorIterations = 1;
  maxZooms = 3;
  maxImages = 1;
  derivativeCount = 1;

  /// DEBUG
  maxDerivatives=4; 
  maxColorIterations=4;
  saveImage=true;
  ///

  for (int i=0; i<maxDerivatives; i++) {
    for (int j=0; j<maxColorIterations; j++) {
      generate1LayerImage(i,j);
    }
  }
}

void generate1LayerImage(int i, int j) {
  background(125);
  maxPaletteColors = getNumPaletteColors();
  defaultBlur = getRandomFloat(defaultMinBlur, defaultMaxBlur);
  setTintOpacity();
  bImg = new BaseImage(imageList[i]);
  dg.setLayer1Name(imageList[i]);
  dg.setBaseImage(bImg);
  dg.setAllPalettes(maxPaletteColors);
  dg.generatePaletteAndGradient();
  dg.setColorIteration(j+1);
  dg.setZoomLevel(playZoomLevel);
  dg.setGradient();
  dg.mapColors(playZoomLevel);
}

void generate2LayerImages() {
  Logger.info("generate2LayerImages");

  setBlendOptions();

  /// DEBUG
  maxDerivatives=3; 
  maxColorIterations=3;
  saveImage=true;
  saveMetaData = true;
  derivativeCount = 1;
  ///

  for (int i=0; i<maxDerivatives; i++) {
    BaseImage b1 = new BaseImage(imageList[i]);
    dg.setLayer1Name(imageList[i]);
    for (int j=0; j<maxLayer2Combinations; j++) {
      if (i==j) {
        continue; // don't blend the design with itself
      }
      blend (b1, i, j);
    }
  }
  //blendLoop();
}

int getNumPaletteColors() {
  // randomly determine if we want a 2 color gradient or a multicolor gradient
  boolean isBasicGradient = (getRandomInt(1, 10) == 1);  // use a basic gradient ~10% of the time
  return isBasicGradient ? 2 : getRandomInt(defaultMinPaletteColors, defaultMaxPaletteColors);
}

void blend() {
  Logger.info("blend");
  try {
    setBlendOptions();
    saveMetaData = true;
    saveImage = true;
    derivativeCount = 1;
    int ndx1 = getRandomInt(0, maxDerivatives);
    BaseImage b1 = new BaseImage(imageList[ndx1]);
    dg.setLayer1Name(imageList[ndx1]);
    int ndx2 = getRandomInt(0, maxDerivatives);
    blend (b1, ndx1, ndx2);
  }
  catch (Exception e) {
    fatalException(e);
  }
}

void mintNFTs() {
  try {
    noLoop();
    if (mintDataRecords.length <= 1) {
      // we only have the header or an empty file, so exit
      fatalError("No Input Data to read in " + params.get("dataFile"));
    }
    String ndxString = params.get("num");
    if (ndxString != null && int(ndxString) <= mintDataRecords.length) {
      mintNFT(int(ndxString));
    } else { 
      for (int i=1; i<mintDataRecords.length; i++) { // start with 1 since first line in data file is the header
        mintNFT(i);
      }
    }
    done();
  }
  catch(Exception e) {
    fatalException(e);
  }
}

void mintNFT(int ndx) {
  noLoop();
  maxImages = 1;
  derivativeCount = 1;
  mintNFT(mintDataRecords[ndx]);
}

void mintNFT(String dataRecordString) {  // from CSV file
  try {
    String[] dataRecord = dataRecordString.split(",");
    saveGradientImage = false;
    saveUnmodifiedImage = false;
    saveGrayImage = false;
    saveImage=true;
    saveMetaData = true;
    //String imageName = dataRecord[2];
    String baseImageName = dataRecord[3];
    String zoomLevel = dataRecord[4];
    String colorIteration = dataRecord[5];
    String palette = dataRecord[6];
    String blur = dataRecord[7];
    String tint = dataRecord[8];
    String gradientTypeStr = dataRecord[9];
    String gradientSliceTypeStr = dataRecord[10];
    String zoomXstr = dataRecord[11];
    String zoomYstr = dataRecord[12];
    Logger.finer("baseImageName: " + baseImageName);
    Logger.finer("Color Iteration: " + colorIteration);
    Logger.finer("Zoom Level: " + zoomLevel);
    Logger.finer("Blur: " + blur);
    Logger.finer("Tint: " + tint);
    Logger.finer("ZoomX: " + zoomXstr);
    Logger.finer("ZoomY: " + zoomYstr);
    Logger.finer("Gradient Type: " + gradientTypeStr);
    Logger.finer("Gradient Slice Type: " + gradientSliceTypeStr);
    Logger.finer("Palette: " + palette);
    Logger.finer("Log Level: " + logLevel);
    Logger.finer("---");
    zoomX = int(zoomXstr);
    zoomY = int(zoomYstr);
    bImg = new BaseImage(baseImageName);
    bImg.setTintOpacity(0, int(tint));
    bImg.setBlurValue(float(blur));
    dg.setBaseImage(bImg);
    dg.setZoomLevel(int(zoomLevel));
    dg.calculateZoomOffsets();
    dg.setColorIteration(int(colorIteration));
    dg.setGradientType(int(gradientTypeStr));
    dg.setGradientSliceType(int(gradientSliceTypeStr));
    dg.setUniquePrefix();
    dg.generatePalette(palette);
    dg.generateGradient();
    dg.mapColors(int(zoomLevel));
  }
  catch(Exception e) {
    fatalException(e);
  }
}

void setBlendOptions() {
  noLoop();
  saveGradientImage = false;
  saveUnmodifiedImage = false;
  saveGrayImage = false;
  saveMetaData = false;
  playOpacityDefault = false;
  maxDerivatives = 20;
  maxLayer2Combinations = 3;
}

void blendLoop() {
  Logger.info("blendLoop");
  try {
    setBlendOptions();
    for (int i=0; i<maxLayer2Combinations; i++) {
      int i2 = getRandomInt(0, maxDerivatives);
      int ndx1 = i;  // change to i2 if we want more random...
      dg.setLayer1Name(imageList[ndx1]);
      BaseImage b1 = new BaseImage(imageList[ndx1]);
      Logger.fine("Blend Img " + (i+1));
      for (int j=0; j<maxLayer2Combinations; j++) {
        int j2 = getRandomInt(0, maxDerivatives);
        int ndx2 = j;  // change to j2 if we want more random...
        blend(b1, ndx1, ndx2);
        Logger.fine("blendLoop "+ ndx1 + "-" + ndx2);
      }
    }
  }
  catch (Exception e) {
    fatalException(e);
  }
}

void blend(BaseImage b1, int ndx1, int ndx2) {
  try {
    //int j2 = getRandomInt(0, maxDerivatives);
    //int ndx2 = j;  // change to j2 if we want more random...
    BaseImage b2 = new BaseImage(imageList[ndx2]);
    dg.setLayer2Name(imageList[ndx2]);
    dg.setLayers(2);
    PImage blendImg = blend2(b1, b2, ndx1, ndx2);
    BaseImage b3 = new BaseImage(blendImg, ndx1, ndx2);
    dg.setBaseImage(b3);
    dg.setAllPalettes(maxPaletteColors);
    maxPaletteColors = getNumPaletteColors();
    defaultBlur = getRandomFloat(defaultMinBlur, defaultMaxBlur);
    dg.generatePaletteAndGradient();
    dg.setColorIteration(1);
    dg.setZoomLevel(playZoomLevel);
    dg.setGradient();
    setTintOpacity();
    dg.mapColors(playZoomLevel);
  }
  catch (Exception e) {
    fatalException(e);
  }
}

PImage blend2(BaseImage bi1, BaseImage bi2, int i, int j) {
  try {
    Logger.info("blend2");
    bgLayer.beginDraw();
    bgLayer.background(0, 0, 0, 150);
    PImage tmp1 = bi1.getGrayImg().copy();
    PImage tmp2 = bi2.getGrayImg().copy();
    fill(255);
    tint(255, 255);
    if (i==j) {
      bgLayer.image(tmp1, 0, 0, imageWidth*zoomLevel, imageHeight*zoomLevel);
    } else {
      tmp2.resize(width, height);
      bgLayer.background(tmp2);
      tmp1.resize(width, height);
      bgLayer.blend(tmp1, 0, 0, width, height, 0, 0, width, height, SOFT_LIGHT);
    }
    bgLayer.endDraw();
    image(bgLayer, width/2, height/2, imageWidth*zoomLevel, imageHeight*zoomLevel);
    //String fileName = dg.outputFolder + "/" + actionPrefix + (i+1) + "-" + (j+1) + ".png";
    //saveFrame(fileName);
  }
  catch(Exception e) {
    fatalException(e);
  }
  return bgLayer;
}

void playground() {
  //  boolean helpTextFlag = false;
  if (playAutoEnabled) {
    click=1;
  }
  if (showHelpTextLayer) {
    background(16);
    image(helpImage, width/2, height/2, width, height);
    tint(255, 255);
    image(helpTextLayer, width/2, height/2, width, height);
  } else {
    if (click == 1) {
      background(125);
      disableImageOutput();
      maxDerivatives = imageList.length;
      maxColorIterations = 1;
      maxZooms = 3;
      maxImages = 1;
      derivativeCount = 1;
      saveMetaData=false;
      click=0;
      tint(255, 255);
      if (playRandomEnabled) {
        playImageNum = getRandomInt(1, maxDerivatives);
        //playZoomLevel = getRandomInt(1,maxZooms+1));
      }
      maxPaletteColors = getNumPaletteColors();
      defaultBlur = getRandomFloat(defaultMinBlur, defaultMaxBlur);
      bImg = new BaseImage(imageList[playImageNum-1]);
      dg.setLayer1Name(imageList[playImageNum-1]);
      dg.setBaseImage(bImg);
      dg.setAllPalettes(maxPaletteColors);
      if (playChangeGradient) {
        dg.generatePaletteAndGradient();
      }
      dg.setColorIteration(1);
      dg.setZoomLevel(playZoomLevel);
      dg.setGradient();
      dg.mapColors(playZoomLevel);
    }
  }
}

void animate() {
  dg.shiftGradient();
  dg.setGradient();
  dg.mapColors(playZoomLevel);
}

void mousePressed() {
  if (playZoomLevel==1) {
    zoomX = mouseX;
    zoomY = mouseY;
    dg.calculateZoomOffsets();
  }
  playZoomLevel++;
  if (playZoomLevel > maxZooms) {
    playZoomLevel=1;
  }
  click=1;
  playChangeGradient=false;
}

void keyPressed() {
  playChangeGradient=true;
  if (key == '?') {
    //println("? pressed... " + showHelpTextLayer);
    showHelpTextLayer = !showHelpTextLayer;
    click=1;
  }

  if (key == '1') {   // toggle animation mode
    int tempAction = 0;
    if (scriptAction == NFTAction.PLAY) { 
      tempAction = NFTAction.ANIMATE;
      logLevel = LogLevel.FINEST;
    };
    if (scriptAction == NFTAction.ANIMATE) { 
      tempAction = NFTAction.PLAY;
      logLevel = LogLevel.INFO;
    };
    scriptAction = tempAction;
  }
  if (key == 'a' || key == 'A') {   // [A]uto
    playAutoEnabled = !playAutoEnabled;
    click=1;
  }
  if (key == 'c' || key == 'C') {  // [C]ycle
    click=1;
  }
  if (key == 'e' || key == 'E') {   // /toggle [E]ven/Random Gradient slices
    dg.gradientSliceType = (dg.gradientSliceType == GradientSliceType.EVEN ? 
      GradientSliceType.RAND : GradientSliceType.EVEN);
    click=1;
  }
  if (key == 'g' || key == 'G') {   // toggle changing/freezing the [G]radient
    playChangeGradient = !playChangeGradient;
  }
  if (key == 'n' || key == 'N') {   // [N]ext
    playImageNum++;
    if (playImageNum > maxDerivatives) {
      playImageNum=1;
    }
    click=1;
  }
  if (key == 'o' || key == 'O') {   // toggle default or random [O]pacity
    playOpacityDefault = !playOpacityDefault;
    setTintOpacity();
    click=1;
  }
  if (key == 'p' || key == 'P') {   // [P]revious
    playImageNum--;
    if (playImageNum == 0) {
      playImageNum=maxDerivatives;
    }
    click=1;
  }
  if (key == 'q' || key == 'Q') {  // [Q]uit
    done();
    click=1;
  }
  if (key == 'r' || key == 'R') {   // [R]andom
    playRandomEnabled = !playRandomEnabled;
    click=1;
  }
  if (key == 's' || key == 'S') {
    saveCVSMetaData=true;
    if (dg == null) {
      fatalError("DerivativeGenerator is null");
    }
    dg.saveImageMetaData();
    saveCVSMetaData=false;
  }
  if (key == 't' || key == 'T') {   // toggle Smooth/Discrete Gradient [Type]
    dg.gradientType = (dg.gradientType == GradientType.SMOOTH ? 
      GradientType.DISCRETE : GradientType.SMOOTH);
    click=1;
  }

  if (key == 'w' || key == 'W') {   // toggle B&W palette
    playBWEnabled = !playBWEnabled;
    dg.generateBlackAndWhitePalette();
    click=1;
  }
}

void setTintOpacity() {
  //if (playOpacityDefault) {
  //  playTintOpacity = defaultTintOpacity;
  //} else {
  playTintOpacity[0] = getRandomInt(0, 64);
  playTintOpacity[1] = getRandomInt(100, 255);
  //}
  dg.bImg.setTintOpacity(0, playTintOpacity[0]);
  dg.bImg.setTintOpacity(1, playTintOpacity[1]);
  Logger.finer("Tint Levels: " + playTintOpacity[0]+ " " + playTintOpacity[1]);
}

void done() {
  Logger.info("done");
  if (dg != null) {
    dg.closeWriter();
    exit();
  }
}

String[] loadData(int ndx) {
  String[] data = loadStrings("mint-metadata.csv");
  if (ndx > data.length) {
    fatalError("Error: There are not that many records in the CSV file");
  }
  String[] dataRecord = split(data[ndx], ",");
  println(data[ndx]);
  return dataRecord;
}

void disableImageOutput() {
  saveImage = false;
}

void setActionPrefix() {
  if (scriptAction == NFTAction.MINT) {
    actionPrefix = "mint-";
  } 
  if (scriptAction == NFTAction.CREATE1) {
    actionPrefix = "create-";
  } 
  if (scriptAction == NFTAction.CREATE_ALL) {
    actionPrefix = "create-";
  } 
  if (scriptAction == NFTAction.PLAY) {
    actionPrefix = "play-";
  }
  if (scriptAction == NFTAction.BLENDER) {
    actionPrefix = "blend-";
  }
  if (scriptAction == NFTAction.CLI) {
    actionPrefix = "cli-";
  }
}

//-----------------------------------
// command line support

void getArguments() {
  //Logger.finer("getArguments");
  if (args != null) {
    for (int i=0; i<args.length; i++) {
      String pair=args[i];
      pair = pair.substring(2);
      String[] keyVal = split(pair, '=');
      if (keyVal.length == 1) {
        fatalError("Params must be in the format -Dkey=[value]");
      } else {
        params.put(keyVal[0], keyVal[1]);
        Logger.fine("param: " + keyVal[0] + "=" + keyVal[1]);
      }
    }
  }
}

void processArguments() {
  Logger.info("processArguments");
  if (scriptAction != NFTAction.CLI) {
    return;
  }
  getArguments();

  if (params.get("mode") == null) {
    fatalError("Missing required param -Dmode=[play|mint|blend|create|create_all]");
  } else {
    switch(params.get("mode")) {
    case "create":
      scriptAction = NFTAction.CREATE1;
      setActionPrefix();
      break;
    case "create_all":
      scriptAction = NFTAction.CREATE_ALL;
      setActionPrefix();
      break;
    case "play":
      scriptAction = NFTAction.PLAY;
      setActionPrefix();
      break;
    case "mint":
      scriptAction = NFTAction.MINT;
      setActionPrefix();
      break;
    case "blend":
      scriptAction = NFTAction.BLENDER;
      setActionPrefix();
      break;
    default:
      fatalError("Invalid valid for param -Dmode=[play|mint|blend|create|create_all]");
    }

    if (params.get("hash") != null) {
      hash = params.get("hash");
    }

    if (params.get("logLevel") != null) {
      switch(params.get("logLevel")) {
      case "fatal":
        logLevel = LogLevel.FATAL;
        break;
      case "error":
        logLevel = LogLevel.ERROR;
        break;
      case "warn":
        logLevel = LogLevel.WARN;
        break;
      case "info":
        logLevel = LogLevel.INFO;
        break;
      case "fine":
        logLevel = LogLevel.FINE;
        break;
      case "finer":
        logLevel = LogLevel.FINER;
        break;
      case "finest":
        logLevel = LogLevel.FINEST;
        break;
      default:
        fatalError("Invalid valid for param -DlogLevel=[fatal|error|warn|info|fine|finer|finest]");
        break;
      }
    }
  }

  switch(scriptAction) {
  case NFTAction.CREATE1:
  case NFTAction.CREATE_ALL:
  case NFTAction.PLAY:
  case NFTAction.BLENDER:
    imageList = validateAndLoadFileParam("imageList");
    break;
  case NFTAction.MINT:
    mintDataRecords = validateAndLoadFileParam("dataFile");
    break;
  }
}

String[] validateAndLoadFileParam(String paramName) {
  if (params.get(paramName) == null) {
    fatalError("Missing required param -D" + paramName + "=[filePath]");
  } else {
    String fileName = params.get(paramName);
    if (fileName == null) {
      fatalError("Missing value for param -D" + paramName + "=[filePath]");
    }
    String[] stringList = loadStrings(fileName);
    if (stringList == null) {
      fatalError("Invalid file or path for param -D" + paramName + "=[filePath]");
    }
    return stringList;
  }
  return new String[0];
}

void fatalError(String msg) {
  println("-------------");
  println("FATAL ERROR: " + msg + " - " + Logger.timeStamp());
  println("-------------");
  exit();
}

void fatalException(Exception e) {
  println("-------------");
  e.printStackTrace();
  println("-------------");
  exit();
}

String getHelpText() {
  String t = "Keyboard Control\n";
  t += "'?' - toggle this help screen\n";
  t += "'q' - quit the application\n";
  t += "'n' - next base image\n";
  t += "'p' - previous base image\n";
  t += "'c' - cycle effects on the current image\n";
  t += "'r' - toggle randomize mode\n";
  t += "'o' - randomize the opacity of the color overlay layer\n";
  t += "'a' - toggle auto-display mode\n";
  t += "'s' - save parameters of the current display image\n      to the metadata file in the output folder\n";
  t += "'1' - animate by cycling the gradient colors\n";
  t += "\n\nMouse Control\n";
  t += "- click a point in the image to zoom,\n  subsequent zooms will preserves that point.\n";
  t += "- after returning to zoom level 1,\n  a new point can be selected.\n";

  return t;
}
