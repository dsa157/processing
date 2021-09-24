import java.util.Date;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Map;
import java.io.*;

//int scriptAction = NFTAction.CREATE;
//int scriptAction = NFTAction.MINT;
//int scriptAction = NFTAction.PLAY;
int scriptAction = NFTAction.CLI;

int maxDerivatives = 16;
int maxColorIterations = 10;
int maxZooms = 3;
int maxPaletteColors = 5;    // Innoculation: 3
float defaultBlur = 10.0;
int zoomLevel=1;
int[] defaultTintOpacity = {128, 150}; // blurred image at 100/255 (~40%), color overlay at 128/255 (~50%)

boolean saveImage = true;
boolean saveMetaData = false;
boolean saveCVSMetaData = false;
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
static int logLevel = LogLevel.INFO;
HashMap<String, String> params = new HashMap<String, String>();

int playImageNum=1;
int playZoomLevel=1;
int[] playTintOpacity = defaultTintOpacity;
boolean playAutoEnabled=false;
boolean playRandomEnabled=false;
boolean playBWEnabled=false;
boolean playChangeGradient=true;
boolean playOpacityDefault = true;

int mintRecNum;

String imageList[] = {};

String mintDataRecords[];

int zoomX = 0;
int zoomY = 0;

//--------------------------------------
// help text variables

PGraphics helpTextLayer;
PImage helpImage;
;
PFont font;
boolean showHelpTextLayer = false;

//--------------------------------------

static abstract class NFTAction {
  static final int CREATE = 0;
  static final int MINT = 1;
  static final int PLAY = 2;
  static final int ANIMATE = 3;
  static final int CLI = 4;
}

static abstract class LogLevel {
  static final int FATAL = 0;
  static final int ERROR = 1;
  static final int WARN = 2;
  static final int INFO = 3;
  static final int FINE = 4;
  static final int FINER = 5;
  static final int FINEST = 6;
}



int imageWidth, imageHeight;
int currentDerivative=0;
int currentZoom=0;
//int currentColorIteration=0;
BaseImage bImg;
DerivativeGenerator dg;

String actionPrefix = "";

void setup() {
  Logger.info("setup");
  init();
  if (scriptAction == NFTAction.CLI) {
    processArguments();
  }
  if (scriptAction == NFTAction.CREATE) {
    generatePaletteAndGradients();
  }
  playImageNum = 1;
  frameRate(10);
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
  bImg = new BaseImage(null);
  dg = new DerivativeGenerator(bImg, GradientSliceType.EVEN);
  setupHelpTextLayers();
}

void draw() {
  if (scriptAction == NFTAction.CREATE) {
    //createNFTs();
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
  saveImage=true;
  //  image(bImg.getColorImg(), width/2, height/2, width, height);
  mintNFT(mintDataRecords[ndx]);
}

void playground2() {
  //background(125);
  //image(helpImage, width/2, height/2, width, height);
  if (showHelpTextLayer) {
    image(helpTextLayer, width/2, height/2, width, height);
  } else {
    background(125);
  }
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
      saveCVSMetaData=false;
      click=0;
      tint(255, 255);
      if (playRandomEnabled) {
        playImageNum = int(random(1, maxDerivatives+1));
        //playZoomLevel = int(random(1,maxZooms+1));
      }
      maxPaletteColors = int(random(3, 50));
      defaultBlur = random(3.0, 15.0);
      bImg = new BaseImage(imageList[playImageNum-1]);
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
    if (playOpacityDefault) {
      playTintOpacity = defaultTintOpacity;
    } else {
      playTintOpacity[0] = int(random(0, 65));
      playTintOpacity[1] = int(random(100, 256));
    }
    dg.bImg.setTintOpacity(0, playTintOpacity[0]);
    dg.bImg.setTintOpacity(1, playTintOpacity[1]);
    println("Tint Levels: ", playTintOpacity[0], playTintOpacity[1]);
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

void mintNFT(String dataRecordString) {
  try {
    String[] dataRecord = dataRecordString.split(",");
    saveGradientImage = false;
    saveUnmodifiedImage = true;
    saveGrayImage = true;
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
    Logger.fine("baseImageName: " + baseImageName);
    Logger.fine("Color Iteration: " + colorIteration);
    Logger.fine("Zoom Level: " + zoomLevel);
    Logger.fine("Blur: " + blur);
    Logger.fine("Tint: " + tint);
    Logger.fine("ZoomX: " + zoomXstr);
    Logger.fine("ZoomY: " + zoomYstr);
    Logger.fine("Gradient Type: " + gradientTypeStr);
    Logger.fine("Gradient Slice Type: " + gradientSliceTypeStr);
    Logger.fine("Palette: " + palette);
    Logger.fine("Log Level: " + logLevel);
    Logger.fine("---");
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
  if (scriptAction == NFTAction.CREATE) {
    actionPrefix = "create-";
  } 
  if (scriptAction == NFTAction.PLAY) {
    actionPrefix = "play-";
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
    fatalError("Missing required param -Dmode=[play|mint]");
  } else {
    switch(params.get("mode")) {
    case "play":
      scriptAction = NFTAction.PLAY;
      setActionPrefix();
      break;
    case "mint":
      scriptAction = NFTAction.MINT;
      setActionPrefix();
      break;
    default:
      fatalError("Invalid valid for param -Dmode=[play|mint]");
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
  case NFTAction.PLAY:
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
