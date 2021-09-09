// class for processing source images to create variations of gradient, zoom, etc

int EVEN = 1;
int RAND = 2;
int WARM = 3;
int COOL = 4;

class DerivativeGenerator {
  
  color from; 
  color to; 
  BaseImage bImg;
  int gradientType = EVEN;
  
  int[] myPalette;
  int paletteSize = 0;
  int zoomLevel = 1;
  int colorIteration = 1;
  boolean overlayGray = false;
  boolean overlayColor = false;

  
  color[] gradValues = new color[width];
  String[] imageMetaData = new String[4];

  
  DerivativeGenerator(BaseImage img, int gType) {
    bImg = img;
    gradientType = gType;
  }
  
  void setZoomLevel(int zl) {
    zoomLevel = zl;
  }
  
  void setColorIteration(int ci) {
    colorIteration = ci;
  }
  
  String getOutFileName() {
    return bImg.getOutFileName(colorIteration, zoomLevel);
  }

  void lerpColors(int ndx, int prev, color from, color to) {
      int segmentWidth = ndx - prev;
      for (int j=prev; j<ndx; j++) {
        float y = 1.0 - (ndx-j)/(segmentWidth * 1.0);
        color newColor = lerpColor(from, to, y); 
        if (j<width) {
          gradValues[j]=newColor;
        }
        //line(j,0,j,height);
        //stroke(newColor);
      }
  }
  
  void draw() {
    generateRandomPalette();
    int ndx = 0;
    int prev = 0;
    for (int i=0; i<paletteSize-1; i++) {
      prev = ndx;
      if (i == paletteSize-2) {
        ndx = width;
      }
      else {
        if (gradientType == EVEN) {
          ndx = i * int(width/paletteSize);
        }
        else {
          ndx = int(random(ndx, width));
        }
      }
      from = color(myPalette[i]);
      to=color(myPalette[i+1]);
      lerpColors(ndx,prev,from,to);
    }
  }
  
  color getColorByPosition(int i) {
    return gradValues[i];
  }

  color getColorByPercentPosition(int i) {
    int percentPosition = getPercentPosition(i);
    //println("getColorByPercentPosition", i, percentPosition);
    color c = gradValues[percentPosition];
    //println("getColorByPercentPosition=", percentPosition, c);
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

  void drawDiscreteColors(int[] discreteColors) {
    for (int i=0; i<discreteColors.length; i++) {
      int position = discreteColors[i];
      int percentPosition = getPercentPosition(position);
      int rectWidth=height/20;
      fill(getColorByPercentPosition(position));
      //fill(getColorByPosition(position));
      //stroke(0);
      noStroke();
      rect(percentPosition, rectWidth, rectWidth, rectWidth);
    }
  }
  
  void generateRandomPalette() {
    int[] gradPalette = new int[maxPaletteColors+1];
    gradPalette[0] = color(0);
    for (int i=1; i<maxPaletteColors; i++) {
      float r = random(128,255);
      float g = random(128,255);
      float b = random(128,255);
      color c = color(r,g,b);
      gradPalette[i] = c;
    }
    myPalette = gradPalette;
    paletteSize = myPalette.length;
  }

  void mapColors() {
    for (int z=1; z<=maxZooms; z++) {
      zoomLevel = z;
      println("Processing " + getOutFileName() + ".png (" + imageCount++ + "/" + maxImages + ")");
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
      overlay();
      saveFrame(getOutFileName() + ".png");
      saveImageMetaData();
    }
  } //<>//
    
  void zoom(PImage img, int zoomLevel) {
    image(img, width/2, height/2, imageWidth*zoomLevel, imageHeight*zoomLevel);    
  }

  void overlay() {
    // draw the temp image, then overlay the original at 50% opacity
    tint(255, 255);
    zoom(bImg.getColorImg(), zoomLevel);
    bImg.setTint(0);
    PImage blurredImg = bImg.getTempImg().copy();
    blurredImg.filter(BLUR, bImg.getBlurValue());
    zoom(blurredImg, zoomLevel);
    bImg.setTint(1);
    if (overlayGray) {
      zoom(bImg.getGrayImg(), zoomLevel);
    }
    if (overlayColor) {
      zoom(bImg.getColorImg(), zoomLevel);
    }
  }
  
  //void addImageMetaData(String s) {
  //  //params[0] = "FileName: " + outFilePrefix + "-" + outputCount+".png"; ;
  //  //params[1] = "outPutCount: " + outputCount;
  //  //logParameters(outputCount, params);
  //  append(imageMetaData, s);
  //}
  
  String savePaletteAsHexStrings() {
    String retString = "{ ";
    for (int i=0; i<myPalette.length; i++) {
      String s = hex(myPalette[i], 6);
      retString += "#" + s + ",";
    }
    retString = retString.substring(0, retString.length()-1);  // chop off the last ","  
    retString += " }";
    return retString;
  }

  void saveImageMetaData() {
    imageMetaData[0] = "FileName: " + getOutFileName() + ".png";
    imageMetaData[1] = "Palette: " + savePaletteAsHexStrings();
    imageMetaData[2] = "Zoom Level: " + zoomLevel;
    imageMetaData[3] = "Color Iteration: " + colorIteration;
    saveStrings(getOutFileName() + ".txt", imageMetaData);
  }

} 
