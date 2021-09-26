import java.io.File;

PImage img1;
PImage img2;
PImage img3;
PImage img4;
PImage img5;
PGraphics bgLayer;

int t1=255;
int t2=0;
int step=5;
boolean t1Up = false;
boolean t2Up = true;
int cnt=1;
int maxImages = 10;
int renderImages = 4;
PImage[] a1 = new PImage[maxImages];
PImage[] a2 = new PImage[maxImages];
String outputFolder = "output";
int BLEND_MODE = 2;
boolean done=false;
int i; 
int j;

//--
int maxPaletteColors=5;
int[] myPalette;
int paletteSize=0;
color[] gradValues = new color[width];
color from;
color to;
boolean saveGradientImage = true;
String[] dataFile = {
  "http://www.dsa157.com/NFT/Davids-Lyre-1-small.png", 
  "http://www.dsa157.com/NFT/Davids-Lyre-10-small.png", 
  "http://www.dsa157.com/NFT/Davids-Lyre-16-small.png", 
  "http://www.dsa157.com/NFT/Davids-Lyre-9-small.png", 
  "http://www.dsa157.com/NFT/Davids-Lyre-2-small.png", 
  "http://www.dsa157.com/NFT/Davids-Lyre-4-small.png", 
  "http://www.dsa157.com/NFT/Davids-Lyre-5-small.png", 
  "http://www.dsa157.com/NFT/Davids-Lyre-6-small.png", 
  "http://www.dsa157.com/NFT/Davids-Lyre-7-small.png", 
  "http://www.dsa157.com/NFT/Davids-Lyre-8-small.png", 
  "http://www.dsa157.com/NFT/Davids-Lyre-11-small.png", 
  "http://www.dsa157.com/NFT/Davids-Lyre-12-small.png", 
  "http://www.dsa157.com/NFT/Davids-Lyre-13-small.png", 
  "http://www.dsa157.com/NFT/Davids-Lyre-3-small.png", 
  "http://www.dsa157.com/NFT/Davids-Lyre-14-small.png", 
  "http://www.dsa157.com/NFT/Davids-Lyre-15-small.png", 
  "http://www.dsa157.com/NFT/Davids-Lyre-17-small.png", 
  "http://www.dsa157.com/NFT/Davids-Lyre-18-small.png", 
  "http://www.dsa157.com/NFT/Davids-Lyre-19-small.png", 
  "http://www.dsa157.com/NFT/Davids-Lyre-20-small.png"
};

//--

// BLEND, ADD, SUBTRACT, LIGHTEST, DARKEST, DIFFERENCE, EXCLUSION, MULTIPLY, SCREEN, OVERLAY, HARD_LIGHT, SOFT_LIGHT, DODGE, BURN

//--------------------------------------------

void setup() {
  size(800, 600);
  String dirName = "/Users/dsa157/Documents/Processing/projects/overlayImages/output";

  for (File file : new java.io.File(dirName).listFiles()) {
    if (!file.isDirectory()) {
      file.delete();
    }
  }
  bgLayer = createGraphics(width, height);
  gradValues = new color[width];
  for (i=0; i< maxImages; i++) {
    String fileName = dataFile[i];
    println("Loading " + fileName);
    PImage img = loadImage(fileName);
    a1[i]=img;
    a2[i]=img;
  }
  //noLoop();
  switch(BLEND_MODE) {
  case 1: 
    frameRate(60);
    break;
  case 2: 
    frameRate(20);
    noLoop();
    break;
  }
}

//--------------------------------------------

void draw() {
  blend2();
  println("end draw.");
}

//--------------------------------------------

void blend1(PImage i1, PImage i2) {
  tint(255, t1);
  image(i1, 0, 0, width, height);
  tint(255, t2);
  image(i2, 0, 0, width, height);
  //image(img1, 0,0,width,height);
  t1 = (t1Up) ? t1+step : t1-step;
  t2 = (t2Up) ? t2+step : t2-step;
  if (t1 <= 0) { 
    t1Up = true; 
    t1=0;
  }
  if (t1 >= 255) { 
    t1Up = false; 
    t1=255;
  }
  if (t2 <= 0) { 
    t2Up = true; 
    t2=0;
  }
  if (t2 >= 255) { 
    t2Up = false; 
    t2=255;
  }
  //println(t1, t2);
}

//--------------------------------------------

void blend2() {
  for (i=0; i<renderImages; i++) {
    int ndx1 = int(random(0, maxImages));
    PImage tmpImg = a1[ndx1].copy();
    tmpImg.filter(GRAY);
    println("Blend Img " + (i+1));
    for (j=0; j<renderImages; j++) {
      int ndx2 = int(random(0, maxImages));
      generatePaletteAndGradient();
      PImage blendImg = blend2(a1[ndx1], a2[ndx2], ndx1, ndx2);
      colorAndSaveBlendedImage(blendImg, a1[ndx1]);
    }
  }
}

void colorAndSaveBlendedImage(PImage bgImg, PImage tmp1  ) {
  tint(255, 255);
  mapColors(tmp1);
  tint(255, 255);
  image(bgImg, 0, 0);
  tint(255, 32);
  image(tmp1, 0, 0);
  String fileName = outputFolder + "/File-" + (i+1) + "-" + (j+1) + ".png";
  saveFrame(fileName);
}

//--------------------------------------------

PImage blend2(PImage i1, PImage i2, int i, int j) {
  bgLayer.beginDraw();
  bgLayer.background(0, 0, 0, 150);
  PImage tmp1 = i1.copy();
  tmp1.filter(GRAY);
  PImage tmp2 = i2.copy();
  tmp2.filter(GRAY);
  fill(255);
  tint(255, 255);
  if (i==j) {
    bgLayer.image(tmp1, 0, 0, width, height);
  } else {
    tmp2.resize(width, height);
    bgLayer.background(tmp2);
    tmp1.resize(width, height);
    bgLayer.blend(tmp1, 0, 0, width, height, 0, 0, width, height, SOFT_LIGHT);
  }
  bgLayer.endDraw();

  image(bgLayer, 0, 0);
  String fileName = outputFolder + "/blend-" + (i+1) + "-" + (j+1) + ".png";
  //  saveFrame(fileName);
  return bgLayer;
}

//--------------------------------------------

void blend3() {
  generatePaletteAndGradient();
  background(255);
  tint(255);
  //  tint(255,128);
  //  image(img2, 0,0,width,height);
  //  tint(255,128);
  cnt++;
  PImage tmp1 = createImage(width, height, RGB);
  PImage tmp2 = createImage(width, height, RGB);
  tmp2.copy(img2, 0, 0, width, height, 0, 0, width, height);
  ;
  switch(cnt) {
  case 2: 
    tmp2.copy(img2, 0, 0, width, height, 0, 0, width, height);
    ;
    break;
  case 3: 
    tmp2.copy(img3, 0, 0, width, height, 0, 0, width, height);
    ;
    break;
  case 4: 
    tmp2.copy(img4, 0, 0, width, height, 0, 0, width, height);
    ;
    break;
  case 5: 
    tmp2.copy(img5, 0, 0, width, height, 0, 0, width, height);
    ;
    cnt=1; 
    break;
  }
  //tmp1.copy(img1, 0, 0, width, height, 0,0, width, height);;
  tmp1.blend(tmp2, 0, 0, width, height, 0, 0, width, height, SOFT_LIGHT);
  //image(tmp2, 0, 0);
  image(tmp1, 0, 0);

  //image(img1, 0,0,width,height);
  //t1 = (t1Up) ? t1+step : t1-step;
  //t2 = (t2Up) ? t2+step : t2-step;
  //if (t1 <= 0) { t1Up = true; t1=0;}
  //if (t1 >= 255) { t1Up = false; t1=255;}
  //if (t2 <= 0) { t2Up = true; t2=0;}
  //if (t2 >= 255) { t2Up = false; t2=255;}
  ////println(t1, t2);
}

//--------------------------------------------

void generateRandomPalette() {
  Logger.info("generateRandomPalette");
  int[] gradPalette = new int[maxPaletteColors];
  //gradPalette[0] = color(0);
  for (int i=0; i<maxPaletteColors; i++) {
    float r = int(random(0, 255)); //getRandomInt(128, 255);
    float g = int(random(0, 255)); //getRandomInt(128, 255);
    float b = int(random(0, 255)); //getRandomInt(128, 255);
    color c = color(r, g, b);
    //print(i, hex(c), "");
    gradPalette[i] = c;
  }
  //println("");
  //arrayCopy(gradPalette, myPalette);
  myPalette = gradPalette;
  paletteSize = myPalette.length;
  //println("Current Color Iteration: " + colorIteration);
  //println(savePaletteAsHexStrings());
  //arrayCopy(myPalette, allPalettes[colorIteration-1]);
  //allPalettes[colorIteration-1]=myPalette; // we started colorIterations as 1-based, but the array is 0-based, so subtract 1
}

//--------------------------------------------

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

//--------------------------------------------

void generateGradient() {
  Logger.info("generateGradient");
  int ndx = 0;
  int prev = 0;
  int sliceWidth = 0;
  //if (gradientType == GradientType.DISCRETE) {
  //  // for discrete gradients, we want the same number of slices as palette size
  //  sliceWidth = int(round(width/(paletteSize * 1.0)));  // even width slices
  //} else {
  //for smooth gradients, one less, since we need to end on the last color
  sliceWidth = int(round(width/(paletteSize-1 * 1.0)));  // even width slices
  //}
  for (int i=0; i<paletteSize-1; i++) {
    from = myPalette[i];
    if (i == paletteSize-1) {
      to = myPalette[paletteSize-1];
    } else {
      to = myPalette[i+1];
    }
    //    if (gradientSliceType == GradientSliceType.RAND) {
    //      sliceWidth = getRandomInt(ndx, width-1);  // random width slices
    //    }
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
    //if (gradientType == GradientType.DISCRETE) {
    //  color newColor = myPalette[i];
    //  for (int j=prev; j<ndx; j++) {
    //    line(j, 0, j, height);
    //    stroke(newColor);
    //    gradValues[j]=newColor;
    //  }
    //} else {
    lerpColors(prev, ndx, from, to);
    //}
  }
  if (saveGradientImage) {
    tint(255, 255);
    String suffix = "-gradient";
    //saveFrame(outputFolder + "/grad-" + (i+1) + "-" + (j+1) + ".png");
    background(255);
  }
  //arrayCopy(gradValues, allGradients[colorIteration-1]);
}

//--------------------------------------------

void generatePaletteAndGradient() {
  generateRandomPalette();
  generateGradient();
}

//--------------------------------------------

void mapColors(PImage img) {
  Logger.info("mapColors");
  img.loadPixels();
  for (int i=0; i<img.pixels.length; i++) {
    color c = img.pixels[i];
    float b = brightness(c);
    int percentBrightness = int((b/255.0)*100.0);
    img.pixels[i] = getColorByPercentPosition(percentBrightness);
  }
  img.updatePixels();
  image(img, 0, 0);
  //saveFrame(outputFolder + "/mapColors-" + (i+1) + "-" + (j+1) + ".png");
  overlay2(img);
}

//--------------------------------------------

color getColorByPercentPosition(int i) {
  int percentPosition = getPercentPosition(i);
  //println("getColorByPercentPosition", i, percentPosition);
  color c = gradValues[percentPosition];
  //println("getColorByPercentPosition=", percentPosition, c);
  return c;
}

//--------------------------------------------

color getPercentPosition(int i) {
  float percent = width * (i * 1.0)/100;
  int percentPosition = int(percent);
  // make sure we don't extend past the array size
  if (percentPosition == width) {
    percentPosition = width - 1;
  }
  return percentPosition;
}

//--------------------------------------------

void overlay2(PImage img) {
  Logger.info("overlay2");
  // draw the temp image, then overlay the original at 50% opacity
  PImage saturatedImg = img.copy();
  PImage blurredImg = img.copy();
  blurredImg.filter(BLUR, 15.0);
  colorMode(HSB, 255, 255, 255);
  for (int i=0; i<blurredImg.pixels.length; i++) {
    //color blurredPixelColor = color(blurredImg.pixels[i]);
    color newColor = color(hue(blurredImg.pixels[i]), saturation(blurredImg.pixels[i]), brightness(saturatedImg.pixels[i]));
    saturatedImg.pixels[i] = newColor;
  }
  colorMode(RGB, 255, 255, 255);
  tint(255, 255);
  image(img, 0, 0);
  tint(255, 32);
  image(saturatedImg, 0, 0);
  //saveFrame(outputFolder + "/overlay2-" + (i+1) + "-" + (j+1) + ".png");
}
