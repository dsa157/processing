import java.util.Date; //<>// //<>//
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Map;
import java.io.*;
import java.util.Random;
import java.lang.Math;
import java.math.BigInteger;
import java.net.URI;

//--------------------------------------

// -- app global variables --
int imageWidth, imageHeight;
int currentDerivative=0;
int currentZoom=0;
String imageList[] = {};
String defaultImageList = "http://www.dsa157.com/NFT/imageList.txt";
String defaultPaletteList = "http://www.dsa157.com/NFT/palettes.txt";
String outputFileName = "outputFile";
BaseImage bImg;
DerivativeGenerator dg;
PaletteManager paletteManager;
int click=1;
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
int defaultZoomLevel = 1;

int zoomLevel=1;
boolean useOpacityDefault = false;
int[] defaultTintOpacity = {128, 150}; // blurred image at 100/255 (~40%), color overlay at 128/255 (~50%)
int maxImages = maxDerivatives * maxColorIterations * maxZooms;
int imageNdx = 0;
int derivativeCount = 1;

// -- output variables --
boolean saveImage = true;
boolean saveMetaData = true;
boolean saveUnmodifiedImage = false;
boolean saveGradientImage = false;
boolean saveGrayImage = false;
boolean saveBlurredImage = false;
boolean saveOutputImage = saveImage;
boolean overlayGray = false;
boolean recordedCVSMetaData = false;

// -- PRNG variables --
Random prng;
String defaultHash = "abcdef21572157";
String hash = defaultHash; 

// -- blend mode variables --
PGraphics bgLayer;
int maxLayer2Combinations = maxDerivatives;


//--------------------------------------

void setRandSeed() {
  if (hash == "") {
    hash = defaultHash;
  }
  Long longSeed = new BigInteger(hash, 16).longValue();
  prng.setSeed(longSeed);
}

public float getRandomFloat(float min, float max) {
  float factor = max - min;
  return prng.nextFloat() * factor + min;
}

public int getRandomInt(int min, int max) {
  max=max+1; // increment here so that code is more readable for the range we want to be inclusive
  return (int) prng.nextInt((max - min) + min);
}

//-----------------------------------------------

void setup() {
  try {
    processArguments();
    init();
    prng = new Random();     
    setRandSeed();
    bgLayer = createGraphics(width, height);
    bImg = new BaseImage("");
    dg = new DerivativeGenerator(bImg, GradientSliceType.EVEN);
    paletteManager = new PaletteManager();
    generatePaletteAndGradients();
  }
  catch (Exception e) {
    fatalException(e);
  }
}

void settings() {
  size(1000, 750);
}

void init() {
  settings();
  imageWidth = width;
  imageHeight = height;
  imageMode(CENTER);
  colorMode(RGB, 255, 255, 255);
  background(255);
  println("hash=" + hash);
  println("outputFileName=" + outputFileName);
}

void draw() {
  createNFT();
}

void generatePaletteAndGradients() {
  for (int i=1; i<=maxColorIterations; i++) {
    dg.setColorIteration(i);
    dg.generatePaletteAndGradient();
  }
  for (int i=1; i<=maxColorIterations; i++) {
    dg.setColorIteration(i);
    //dg.setGradient();
  }
}

void createNFT() {
  noLoop();
  // this will randomly determine if it should create a layer1 or layer2 design
  boolean generate1Layer = false;
  generate1Layer = (getRandomInt(1, 2) == 1);
  if (generate1Layer) {
    int i = getRandomInt(1, maxDerivatives);
    generate1LayerImage(i-1, 0);
  } else {
    int i = getRandomInt(1, maxDerivatives);
    BaseImage b1 = new BaseImage(imageList[i]);
    dg.setLayer1Name(imageList[i]);
    generate2LayerImage(b1, i-1, 0);
  }
  done();
}

//void generateCollection() {
//  try {
//    noLoop();
//    generateOriginalImages();
//    generate1LayerImages();
//    generate2LayerImages();
//  }
//  catch(Exception e) {
//    fatalException(e);
//  }
//  done();
//}

//void generateOriginalImages() {
//  generateOriginalImages(0);  // original and gray
//  for (int i=1; i<maxDerivatives; i++) {
//    generateOriginalImages(i);  // each original derivative and gray
//  }
//}

//void generateOriginalImages(int ndx) {
//  maxImages = 1;
//  derivativeCount = 1;
//  saveImage=true;
//  saveGradientImage=false;
//  saveMetaData=true;
//  saveImage=false;
//  bImg = new BaseImage(imageList[ndx]);
//  dg.setLayer1Name(imageList[ndx]);
//  dg.setDesignType((ndx==0) ? "original" : "derivative");
//  dg.setBaseImage(bImg);
//  dg.zoom(bImg.getColorImg(), zoomLevel);
//  String suffix = "-orig";
//  dg.saveImage(suffix);
//  dg.saveImageMetaData(suffix);
//  dg.zoom(bImg.getGrayImg(), zoomLevel);
//  suffix = "-gray";
//  dg.saveImage(suffix);
//  dg.saveImageMetaData(suffix);
//}

void generate1LayerImages() {
  saveGradientImage=false;
  saveMetaData=true;
  saveImage=false;
  maxZooms = 3;
  maxImages = 1;
  derivativeCount = 1;

  /// DEBUG
  maxDerivatives=4; 
  maxColorIterations=4;
  ///

  for (int i=0; i<maxDerivatives; i++) {
    for (int j=0; j<maxColorIterations; j++) {
      generate1LayerImage(i, j);
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
  dg.generatePaletteAndGradient();
  dg.setColorIteration(j+1);
  dg.setZoomLevel(defaultZoomLevel);
  //dg.setGradient();
  dg.mapColors(defaultZoomLevel);
}

void generate2LayerImages() {
  setBlendOptions();
  for (int i=0; i<maxDerivatives; i++) {
    BaseImage b1 = new BaseImage(imageList[i]);
    dg.setLayer1Name(imageList[i]);
    for (int j=0; j<maxLayer2Combinations; j++) {
      if (i==j) {
        continue; // don't blend the design with itself
      }
      generate2LayerImage(b1, i, j);
    }
  }
}

void generate2LayerImage(BaseImage b1, int i, int j) {
  blend (b1, i, j);
}

int getNumPaletteColors() {
  // randomly determine if we want a 2 color gradient or a multicolor gradient
  boolean isBasicGradient = (getRandomInt(1, 5) == 1);  // use a basic gradient ~20% of the time
  return isBasicGradient ? 2 : getRandomInt(defaultMinPaletteColors, defaultMaxPaletteColors);
}

void blend() {
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

void setBlendOptions() {
  noLoop();
  saveGradientImage = false;
  saveUnmodifiedImage = false;
  saveGrayImage = false;
  saveMetaData = false;
  useOpacityDefault = false;
  maxDerivatives = 20;
  maxLayer2Combinations = 3;
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
    maxPaletteColors = getNumPaletteColors();
    defaultBlur = getRandomFloat(defaultMinBlur, defaultMaxBlur);
    dg.generatePaletteAndGradient();
    dg.setColorIteration(1);
    dg.setZoomLevel(defaultZoomLevel);
    setTintOpacity();
    dg.mapColors(defaultZoomLevel);
  }
  catch (Exception e) {
    fatalException(e);
  }
}

PImage blend2(BaseImage bi1, BaseImage bi2, int i, int j) {
  try {
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

void setTintOpacity() {
  dg.bImg.setTintOpacity(0, getRandomInt(0, 64));
  dg.bImg.setTintOpacity(1, getRandomInt(100, 255));
}

void done() {
  if (dg != null) {
    exit();
  }
}

void disableImageOutput() {
  saveImage = false;
}

//void setActionPrefix() {
//  if (scriptAction == NFTAction.MINT) {
//    actionPrefix = "mint-";
//  } 
//  if (scriptAction == NFTAction.CREATE1) {
//    actionPrefix = "create-";
//  } 
//  if (scriptAction == NFTAction.CREATE_ALL) {
//    actionPrefix = "create-";
//  } 
//  if (scriptAction == NFTAction.PLAY) {
//    actionPrefix = "play-";
//  }
//  if (scriptAction == NFTAction.BLENDER) {
//    actionPrefix = "blend-";
//  }
//  if (scriptAction == NFTAction.CLI) {
//    actionPrefix = "cli-";
//  }
//}

//-----------------------------------
// command line support

void getArguments() {
  if (args != null) {
    for (int i=0; i<args.length; i++) {
      String pair=args[i];
      pair = pair.substring(2);
      String[] keyVal = split(pair, '=');
      if (keyVal.length == 1) {
        fatalError("Params must be in the format -Dkey=[value]");
      } else {
        params.put(keyVal[0], keyVal[1]);
      }
    }
  }
}

void processArguments() {
  getArguments();

  if (!params.containsKey("mode")) {
    params.put("mode", "create1");
  } 
  if (!params.containsKey("imageList")) {
    params.put("imageList", defaultImageList);
  } 
  if (!params.containsKey("paletteList")) {
    params.put("paletteList", defaultPaletteList);
  } 
  if (params.containsKey("hash")) {
    hash = params.get("hash");
  }
  if (params.containsKey("outputFileName")) {
    outputFileName = params.get("outputFileName");
  }
  if (params.containsKey("maxDerivatives")) {
    maxDerivatives = int(params.get("maxDerivatives"));
  }
  if (params.containsKey("maxColorIterations")) {
    maxColorIterations = int(params.get("maxColorIterations"));
  }
  if (params.containsKey("maxLayer2Combinations")) {
    maxLayer2Combinations = int(params.get("maxLayer2Combinations"));
  }


  //switch(scriptAction) {
  //case NFTAction.CREATE1:
  imageList = validateAndLoadFileParam("imageList");
  //  break;
  //}
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

void log(String msg) {
  println(msg + timeStamp());
}

void fatalError(String msg) {
  println("-------------");
  println("FATAL ERROR: " + msg + " - " + timeStamp());
  println("-------------");
  exit();
}

void fatalException(Exception e) {
  println("-------------");
  e.printStackTrace();
  println("-------------");
  exit();
}

String timeStamp() {
  DateFormat formatter = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
  Date d = new Date();
  String ts = formatter.format(d);
  return ts;
}


//-------------------------------------------------------------

class BaseImage {

  protected PImage colorImg, grayImg, tempImg;
  protected String outFilePrefix = outputFileName;
  protected int[] tintOpacity = defaultTintOpacity;
  protected float blurValue = defaultBlur;

  BaseImage(PImage img, int i, int j) {
    if (img == null) {
      return;
    }
    //outFilePrefix = "" + (i+1) + "-" + (j+1);
    setColorImg(img);
    setGrayImg(img);
  }

  BaseImage(String fileName) {
    if (fileName == "") {
      return;
    }
    String fn = getFileNameFromURI(fileName);
    //outFilePrefix = fn.substring(0, fn.length()-4);
    colorImg = loadImage(fileName);
    setGrayImg(colorImg);
  }

  void setTint(int ndx) {
    tint(255, tintOpacity[ndx]);
  }

  void setTintOpacity(int ndx, int value) {
    tintOpacity[ndx]=value;
  }

  int getTintOpacity(int ndx) {
    return tintOpacity[ndx];
  }

  void setBlurValue(float bv) {
    blurValue=bv;
  }

  float getBlurValue() {
    return blurValue;
  }

  PImage getColorImg() {
    return colorImg;
  }

  PImage getGrayImg() {
    return grayImg;
  }

  PImage getTempImg() {
    return tempImg;
  }

  void setColorImg(PImage img) {
    colorImg = img.copy();
  }

  void setGrayImg(PImage img) {
    grayImg = img.copy();
    grayImg.filter(GRAY);
  }

  void setTempImg(PImage img) {
    tempImg = img.copy();
  }

  void setMaxZooms(int n) {
    maxZooms = n;
  }

  void setMaxColorIterations(int n) {
    maxColorIterations = n;
  }

  void setMaxPaletteColors(int n) {
    maxPaletteColors = n;
  }

  String getOutFileName(int colorIteration, int zoomLevel, String suffix) {
    //if (suffix == "") {
    //  return outFilePrefix + "-c" + colorIteration + "-z" + zoomLevel;
    //}
    return outFilePrefix;
  }

  String getFileNameFromURI(String uri1) {
    try {
      URI uri = new URI(uri1);
      String path = uri.getPath(); 
      String[] pathParts = path.split("/");
      String fn = pathParts[pathParts.length-1];
      return fn;
    }
    catch(Exception e) {
      fatalException(e);
    }
    return "";
  }
} 

//-------------------------------------------------------------

static abstract class GradientSliceType {
  static final int EVEN = 0;
  static final int RAND = 1;
}

static abstract class GradientType {
  static final int SMOOTH = 0;
  static final int DISCRETE = 1;
}

class DerivativeGenerator {

  color from; 
  color to; 
  BaseImage bImg;
  int gradientType = GradientType.SMOOTH;
  int gradientSliceType = GradientSliceType.EVEN;
  int[] myPalette;
  int paletteSize = 0;
  int zoomLevel = 1;
  int colorIteration = 1;
  int layers = 1;
  boolean overlayColor = !overlayGray;
  int xOffset = 0;
  int yOffset = 0;
  String outputFolder = "output";
  String layer1Name = "";
  String layer2Name = "";
  String designType = "Mutation";
  String paletteName = "Random";
  String uniquePrefix = "";

  color[] gradValues = new color[width];
  HashMap<String, String> imageMetaData = new HashMap<String, String>();
  HashMap<String, Boolean> paletteColorUsage = new HashMap<String, Boolean>();
  int outputImageCount = 1;
  JSONObject json = new JSONObject();

  DerivativeGenerator(BaseImage img, int gType) {
    //log("DerivativeGenerator constructor");
    bImg = img;
    gradientType = gType;
    setUniquePrefix();
  }

  String getUniquePrefix() {
    //return this.uniquePrefix + "-";
    return "";
  }

  void setUniquePrefix() {
    this.uniquePrefix = str(millis());
  }

  void setLayers(int l) {
    this.layers = l;
  }

  void setLayer1Name(String str) {
    this.layer1Name = str;
  }

  void setLayer2Name(String str) {
    this.layer2Name = str;
  }

  void setDesignType(String str) {
    this.designType = str;
  }

  void setBaseImage(BaseImage img) {
    this.bImg = img;
  }

  void setPaletteName(String str) {
    this.paletteName = str;
  }

  void setZoomLevel(int zl) {
    zoomLevel = zl;
  }

  void setColorIteration(int ci) {
    colorIteration = ci;
  }

  void setGradientType(int i) {
    this.gradientType = i;
  }

  void setGradientSliceType(int i) {
    this.gradientSliceType = i;
  }

  String getOutFileName(String suffix) {
    return bImg.getOutFileName(colorIteration, zoomLevel, suffix);
  }

  void lerpColors(int prev, int ndx, color from, color to) {
    int segmentWidth = ndx - prev;
    color newColor = from;
    for (int j=prev; j<ndx; j++) {
      float y = 1.0 - (ndx-j)/(segmentWidth * 1.0);
      newColor = lerpColor(from, to, y); 
      if (j<width) {
        gradValues[j]=newColor;
      }
      if (saveGradientImage) {
        line(j, 0, j, height);
        stroke(newColor);
      }
    }
    from = newColor;
  }

  void generatePaletteAndGradient() {
    generateUnusedCuratedPalette();
    //generateRandomPalette();
    generateGradient();
  }

  void generateUnusedCuratedPalette() {
    try {
      String curatedPaletteString = "";
      boolean usedPalette = false;
      int maxAttempts=paletteManager.maxCuratedPalettes * 2;
      int cntAttempts=1;
      while (!usedPalette) {
        curatedPaletteString = paletteManager.getRandomPalette();
        // check to see if we have used this palette on an image in this layer set using this base layer 
        String key =  paletteName + "-" + layer1Name + "-" + layer2Name;
        if (!paletteColorUsage.containsKey(key) || paletteColorUsage.get(key) != true) {
          paletteColorUsage.put(key, true);
          usedPalette=true;
        } else {
          // reste and try again
          curatedPaletteString = "";
        }
        if (cntAttempts++ > maxAttempts) {
          // make sure we don't infinite loop
          usedPalette=true;
        }
      }
      if (curatedPaletteString != "") {
        generatePalette(curatedPaletteString);
      } else {
        generateRandomPalette();
      }
    }
    catch(Exception e) {
      generateRandomPalette();
    }
  }

  void generateGradient() {
    int ndx = 0;
    int prev = 0;
    int sliceWidth = 0;
    if (gradientType == GradientType.DISCRETE) {
      // for discrete gradients, we want the same number of slices as palette size
      sliceWidth = int(round(width/(paletteSize * 1.0)));  // even width slices
    } else {
      //for smooth gradients, one less, since we need to end on the last color
      sliceWidth = int(round(width/(paletteSize-1 * 1.0)));  // even width slices
    }
    for (int i=0; i<paletteSize-1; i++) {
      from = myPalette[i];
      if (i == paletteSize-1) {
        to = myPalette[paletteSize-1];
      } else {
        to = myPalette[i+1];
      }
      if (gradientSliceType == GradientSliceType.RAND) {
        sliceWidth = getRandomInt(ndx, width-1);  // random width slices
      }
      if (ndx > 0) {
        prev = ndx;
      }
      ndx = ndx + sliceWidth;
      if (ndx > width) {
        ndx = width;
      } else {
        // if this is our last slice and the end of our segment is less than width, pad it out
        if (i == paletteSize-1) {
          ndx = width;
        }
      }      
      if (gradientType == GradientType.DISCRETE) {
        color newColor = myPalette[i];
        for (int j=prev; j<ndx; j++) {
          line(j, 0, j, height);
          stroke(newColor);
          gradValues[j]=newColor;
        }
      } else {
        lerpColors(prev, ndx, from, to);
      }
    }
    if (saveGradientImage) {
      tint(255, 255);
      String suffix = "-gradient";
      saveImage(suffix);
      background(255);
    }
  }

  color getColorByPosition(int i) {
    return gradValues[i];
  }

  color getColorByPercentPosition(int i) {
    int percentPosition = getPercentPosition(i);
    color c = gradValues[percentPosition];
    return c;
  }

  color getPercentPosition(int i) {
    float percent = width * (i * 1.0)/100;
    int percentPosition = int(percent);
    // make sure we don't extend past the array size
    if (percentPosition == width) {
      percentPosition = width - 1;
    }
    return percentPosition;
  }

  void generatePalette(String hexPaletteString) {
    String[] hexColors = split(hexPaletteString, ';');
    int[] gradPalette = new int[hexColors.length];    
    for (int i=0; i<hexColors.length; i++) {
      String colorString = hexColors[i];
      gradPalette[i] = color(unhex(colorString));
    }
    myPalette = gradPalette;
    paletteSize = myPalette.length;
  }

  void generateRandomPalette() {
    int[] gradPalette = new int[maxPaletteColors];
    //gradPalette[0] = color(0);
    for (int i=0; i<maxPaletteColors; i++) {
      float r = getRandomInt(0, 255); //getRandomInt(128, 255);
      float g = getRandomInt(0, 255); //getRandomInt(128, 255);
      float b = getRandomInt(0, 255); //getRandomInt(128, 255);
      color c = color(r, g, b);
      gradPalette[i] = c;
    }
    myPalette = gradPalette;
    paletteSize = myPalette.length;
    paletteName = "Random";
  }

  void mapColors() {
    if (saveOutputImage) {
      for (int z=1; z<=maxZooms; z++) {
        mapColors(z);
      }
    }
  }

  void mapColors(int zl) {
    if (saveOutputImage) {
      zoomLevel = zl;
      tint(255, 255);
      //println("calling zoom from mapColors() on colorImg");
      zoom(bImg.getColorImg(), zoomLevel);
      if (colorIteration==1) {
        saveUnmodifiedImageFile();
      }
      if (saveGrayImage && colorIteration==1) {
        //println("calling zoom from mapColors() on grayImg");
        zoom(bImg.getGrayImg(), zoomLevel);
        String suffix = "-gray";
        saveImage(suffix);
        saveImageMetaData(suffix);
      }
      bImg.setTempImg(bImg.getGrayImg());
      PImage tempImg = bImg.getTempImg();
      tempImg.loadPixels();
      for (int i=0; i<tempImg.pixels.length; i++) {
        color c = tempImg.pixels[i];
        float b = brightness(c);
        int percentBrightness = int((b/255.0)*100.0);
        tempImg.pixels[i] = getColorByPercentPosition(percentBrightness);
      }
      tempImg.updatePixels();
      overlay2();
      saveImage("");
      saveImageMetaData();
    }
  }

  void calculateZoomOffsets() {
    xOffset = abs(zoomX - width/2) * getXHalf();
    yOffset = abs(zoomY - height/2) * getYHalf();
  }

  // deterime whether zoomX is to the right or the left of center
  int getXHalf() {
    if (zoomX > width/2) {
      return -1;
    } else {
      return 1;
    }
  }

  // deterime whether zoomY is above or below center
  int getYHalf() {
    if (zoomY > height/2) {
      return -1;
    } else {
      return 1;
    }
  }

  void zoom(PImage img, int zoomLevel) {
    if (zoomLevel == 1) {
      //image(img, width/2, height/2, imageWidth*zoomLevel, imageHeight*zoomLevel);
      image(img, width/2, height/2, width*zoomLevel, height*zoomLevel);
      // after the rendering of the first unzoomed image, calculate the point where the next zooms will be centered
      if (zoomX == 0) {
        // if not defined, set to center
        zoomX = width/2;
        zoomY = height/2;
      }
      xOffset = abs(zoomX - width/2) * getXHalf();
      yOffset = abs(zoomY - height/2) * getYHalf();
    } else {
      pushMatrix();
      translate(xOffset*zoomLevel, yOffset*zoomLevel);
      image(img, width/2, height/2, width*zoomLevel, height*zoomLevel); 
      popMatrix();
    }
  }

  void overlay2() {
    // draw the temp image, then overlay the original at 50% opacity
    PImage saturatedImg = bImg.getGrayImg().copy();
    PImage blurredImg = bImg.getTempImg().copy();
    blurredImg.filter(BLUR, bImg.getBlurValue());
    colorMode(HSB, 255, 255, 255);
    for (int i=0; i<blurredImg.pixels.length; i++) {
      //color blurredPixelColor = color(blurredImg.pixels[i]);

      color newColor = color(hue(blurredImg.pixels[i]), saturation(blurredImg.pixels[i]), brightness(saturatedImg.pixels[i]));
      saturatedImg.pixels[i] = newColor;
    }
    colorMode(RGB, 255, 255, 255);
    zoom(saturatedImg, zoomLevel);
    bImg.setTint(0);
    if (overlayGray) {
      zoom(bImg.getGrayImg(), zoomLevel);
    }
    if (overlayColor) {
      zoom(bImg.getColorImg(), zoomLevel);
    }
  }

  void showMappedImages() {
  }

  String savePaletteAsHexStrings(String suffix) {
    if (suffix == "-gray") {
      return "gray";
    }
    if (suffix == "-orig") {
      return "original";
    }
    String retString = "";
    for (int i=0; i<myPalette.length; i++) {
      //      String s = hex(myPalette[i], 6);
      String s = hex(myPalette[i]);
      retString += s + ";";
    }
    retString = retString.substring(0, retString.length()-1);  // chop off the last ";"  
    //retString += "}";
    return retString;
  }

  void saveUnmodifiedImageFile() {
    if (saveUnmodifiedImage) {
      String suffix = "";
      if (frameCount == 1) {
        if (colorIteration == 1) {
          suffix = "-orig";
          saveImage(suffix);
        }
      } else {
        if (colorIteration == 1) {
          suffix = "-deriv";
          saveImage(suffix);
        }
      }
      saveImageMetaData(suffix);
      background(255);
    }
  }

  void saveImage(String suffix) {
    if (saveOutputImage) {
      String groupPrefix = (suffix == "-orig" || suffix == "-gray") ? "" : getUniquePrefix();
      saveFrame(outputFolder + "/" + getOutFileName(suffix) + suffix + ".png");
    }
  }

  void saveImageMetaData() {
    saveImageMetaData("");
  }

  void saveImageMetaData(String suffix) {
    try {
      int ci = colorIteration;
      if (suffix != "") {
        ci = 0;
      }
      imageMetaData.put("FileName", getOutFileName(suffix) + ".png");
      imageMetaData.put("BaseFileName", this.layer1Name);
      imageMetaData.put("Layer1FileName", this.layer1Name);
      imageMetaData.put("Layer2FileName", (layers == 1) ? "" : this.layer2Name);
      imageMetaData.put("Zoom", "" + zoomLevel);
      imageMetaData.put("ColorIteration", "" + ci);
      imageMetaData.put("Palette", savePaletteAsHexStrings(suffix));
      imageMetaData.put("Blur", "" + bImg.getBlurValue());
      imageMetaData.put("Tint", "" + bImg.getTintOpacity(0));
      imageMetaData.put("GradientType", "" + gradientType);
      imageMetaData.put("GradientSliceType", "" + gradientSliceType);
      imageMetaData.put("ZoomX", "" + zoomX);
      imageMetaData.put("ZoomY", "" + zoomY);
      imageMetaData.put("Layers", "" + layers);
      imageMetaData.put("GradientColorType", (maxPaletteColors==2 ? "Basic" : "Multicolor"));
      imageMetaData.put("DesignType", designType);
      imageMetaData.put("PaletteName", paletteName);
      imageMetaData.put("ColorType", (bImg.getTintOpacity(0) < 50) ? "Vibrant" : "Muted");
      if (saveMetaData) {
        saveJSON(outputFolder + "/" + getOutFileName(suffix));
      }
    }
    catch(Exception e) {
      fatalException(e);
    }
  }

  void saveJSON(String outFileName) {
    outFileName = outFileName + ".json";
    try {
      json.setString("FileName", imageMetaData.get("FileName"));
      json.setString("Layer1FileName", imageMetaData.get("Layer1FileName"));
      json.setString("Layer2FileName", imageMetaData.get("Layer2FileName"));
      json.setString("Zoom", imageMetaData.get("Zoom"));
      json.setString("ColorIteration", imageMetaData.get("ColorIteration"));
      json.setString("Palette", imageMetaData.get("Palette"));
      json.setString("Blur", imageMetaData.get("Blur"));
      json.setString("Tint", imageMetaData.get("Tint"));
      json.setString("GradientType", imageMetaData.get("GradientType"));
      json.setString("GradientSliceType", imageMetaData.get("GradientSliceType"));
      json.setString("ZoomX", imageMetaData.get("ZoomX"));
      json.setString("ZoomY", imageMetaData.get("ZoomY"));
      json.setString("Layers", imageMetaData.get("Layers"));
      json.setString("GradientColorType", imageMetaData.get("GradientColorType"));
      json.setString("DesignType", imageMetaData.get("DesignType"));
      json.setString("PaletteName", imageMetaData.get("PaletteName"));
      json.setString("ColorType", imageMetaData.get("ColorType"));
      saveJSONObject(json, outFileName);
    }
    catch (Exception e) {
      fatalException(e);
    }
  }

  void loadJSON(String inFileName) {
    try {
      json.getString("BaseFileName");
      this.zoomLevel = int(json.getString("ZoomLevel"));
      this.colorIteration = int(json.getString("ColorIteration"));
      //json.getString("Palette");
      bImg.setBlurValue(float(json.getString("Blur")));
      bImg.setTintOpacity(0, int("Tint"));
      this.gradientType = int(json.getString("GradientType"));
      this.gradientSliceType = int(json.getString("GradientSliceType"));
      zoomX = int(json.getString("ZoomX"));
      zoomX = int(json.getString("ZoomY"));
      this.setLayers(int(json.getString("Layers")));
    }
    catch (Exception e) {
      fatalException(e);
    }
  }

  String getDataString(String str) {
    return (str != null) ? str : "";
  }
} 

//-------------------------------------------------------------

class PaletteManager {

  HashMap<String, String> curatedPalettes = new HashMap<String, String>();
  int maxCuratedPalettes=50;

  PaletteManager() {
    init();
  }

  String getRandomPalette() {
    String name = "";
    try {
      int num = getRandomInt(1, maxCuratedPalettes);
      name = "Palette" + num;
      dg.setPaletteName(name);
    }
    catch(Exception e) {
      e.printStackTrace();
    }
    return curatedPalettes.get(name);
  }

  String get(String name) {
    dg.setPaletteName(name);
    return curatedPalettes.get(name);
  }

  void init() {
    String[] paletteList = loadStrings(params.get("paletteList"));
    for (int i=0; i<paletteList.length; i++) {
      String paletteRec=paletteList[i];
      //println(paletteRec);
      String[] keyVal = paletteRec.split("=");
      if (keyVal.length == 2) {
        String val = keyVal[1];
        curatedPalettes.put(keyVal[0], keyVal[1]);
      }
    }
  }
} 
