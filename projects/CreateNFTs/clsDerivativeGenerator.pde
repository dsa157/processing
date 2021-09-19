// class for processing source images to create variations of gradient, zoom, etc //<>// //<>//

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
  boolean overlayColor = !overlayGray;
  int xOffset = 0;
  int yOffset = 0;
  String outputFolder = "output";
  String csvOutputName = "temp-metadata.csv";
  String uniquePrefix = "";
  color[][] allGradients = new color[maxColorIterations][width];
  int[][] allPalettes = new int [maxColorIterations][maxPaletteColors];

  color[] gradValues = new color[width];
  String[] imageMetaData = new String[9];
  int outputImageCount = 1;

  PrintWriter csvOutput;

  DerivativeGenerator(BaseImage img, int gType) {
    //log("DerivativeGenerator constructor");
    bImg = img;
    gradientType = gType;
    if (actionPrefix != "") {
      initPrintWriter();
    }
    setCsvOutputName();
  }

  void initPrintWriter() {
    setPrintWriter();
    printCvsOutputHeader();
  }

  void setPrintWriter() {
    Logger.fine("setPrintWriter " + outputFolder + "/" + getCsvOutputName());
    csvOutput = createWriter(outputFolder + "/" + getCsvOutputName());
  }

  void setCsvOutputName() {
    csvOutputName = actionPrefix + getUniquePrefix() + "metadata.csv";
  }

  String getCsvOutputName() {
    return csvOutputName;
  }

  String getUniquePrefix() {
    return uniquePrefix + "-";
  }

  void setUniquePrefix() {
    uniquePrefix = str(millis());
  }

  void setBaseImage(BaseImage img) {
    bImg = img;
  }

  void setAllPalettes(int newMaxPaletteColors) {
    maxPaletteColors = newMaxPaletteColors;
    allPalettes = new int [maxColorIterations][newMaxPaletteColors];
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
    generateRandomPalette();
    generateGradient();
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
        sliceWidth = int(random(ndx, width));  // random width slices
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
    //arrayCopy(gradValues, allGradients[colorIteration-1]);
  }

  void shiftGradient() {
    color[] reordered = new color[gradValues.length];
    int shift = 50;
    for (int i=0; i<gradValues.length; i++) {
      reordered[i] = gradValues[(shift+i)%gradValues.length];
    }  
    gradValues = reordered;
  }

  void setGradient() {
    setPalette();
    //arrayCopy(allGradients[colorIteration-1], gradValues);
    //gradValues = allGradients[colorIteration-1];
  }

  void setPalette() {
    //println("currentColorIteration: " + colorIteration);
    //arrayCopy(allPalettes[colorIteration-1], myPalette);
    //myPalette = allPalettes[colorIteration-1];
    //println(savePaletteAsHexStrings());
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

  void generatePalette(String hexPaletteString) {
    String[] hexColors = split(hexPaletteString, ';');
    int[] gradPalette = new int[hexColors.length];    
    for (int i=0; i<hexColors.length; i++) {
      String colorString = hexColors[i];
      gradPalette[i] = color(unhex(colorString));
    }
    myPalette = gradPalette;
    paletteSize = myPalette.length;
    //arrayCopy(myPalette, allPalettes[colorIteration-1]);
  }

  void generateRandomPalette() {
    int[] gradPalette = new int[maxPaletteColors];
    //gradPalette[0] = color(0);
    for (int i=0; i<maxPaletteColors; i++) {
      float r = random(255); //random(128, 255);
      float g = random(255); //random(128, 255);
      float b = random(255); //random(128, 255);
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
      Logger.info("Processing " + getOutFileName() + ".png (" + derivativeCount++ + "/" + maxImages + ") ");
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
      if (scriptAction != NFTAction.PLAY) {
        tint(255, 255);
      }
      //println("mapColors done.");
    }
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
      //image(img, width/2, height/2, imageWidth*zoomLevel, imageHeight*zoomLevel); 
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
    //println("calling zoom from overlay2() on saturatedImg");
    zoom(saturatedImg, zoomLevel);
    bImg.setTint(0);
    if (overlayGray) {
      //println("calling zoom from overlay2() on grayImg");
      zoom(bImg.getGrayImg(), zoomLevel);
    }
    if (overlayColor) {
      //println("calling zoom from overlay2() on colorImg");
      zoom(bImg.getColorImg(), zoomLevel);
    }
  }

  String savePaletteAsHexStrings(String suffix) {
    if (suffix != "") {
      return "none";
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
    if (saveImage) {
      String groupPrefix = (suffix == "-orig" || suffix == "-gray") ? "" : getUniquePrefix();
      saveFrame(outputFolder + "/" + actionPrefix + groupPrefix + getOutFileName() + suffix + ".png");
    }
  }

  void saveImageMetaData() {
    saveImageMetaData("");
  }

  void saveImageMetaData(String suffix) {
    try {
      if (suffix != "" && scriptAction == NFTAction.PLAY) {
        return;  // don't need to write out any of the base image metadata in playground mode
      }
      int ci = colorIteration;
      if (suffix != "") {
        ci = 0;
      }
      if (saveMetaData) {
        imageMetaData[0] = "FileName: " + getOutFileName() + suffix + ".png";
        imageMetaData[1] = "BaseFileName: " + bImg.outFilePrefix + ".png";
        imageMetaData[2] = "Zoom Level: " + zoomLevel;
        imageMetaData[3] = "Color Iteration: " + ci;
        imageMetaData[4] = "Palette: " + savePaletteAsHexStrings(suffix);
        imageMetaData[5] = "Blur: " + bImg.getBlurValue();
        imageMetaData[6] = "Tint Opacity: " + bImg.getTintOpacity(0);
        imageMetaData[7] = "Gradient Type: " + gradientType;
        imageMetaData[8] = "Gradient Slice Type: " + gradientSliceType;

        saveStrings(outputFolder + "/" + getOutFileName() + ".txt", imageMetaData);
      }
      int dCount = derivativeCount-1;
      int oCount = outputImageCount++;
      if (saveCVSMetaData) {
        if (csvOutput == null) {
          initPrintWriter();
        }      

        csvOutput.println(oCount + "," + dCount + "," + getOutFileName() + suffix + ".png" + "," + bImg.outFilePrefix + ".png" + "," +zoomLevel + "," 
          + ci + "," + savePaletteAsHexStrings(suffix) + "," + bImg.getBlurValue() + "," + bImg.getTintOpacity(0) + "," + gradientType + "," + gradientSliceType
          );
        csvOutput.flush();
      }
    }
    catch(Exception e) {
      e.printStackTrace();
      exit();
    }
  }

  void printCvsOutputHeader() {
    csvOutput.println("Num,Derivative,Filename,BaseFileName,ZoomLevel,ColorIteration,Palette,Blur,Tint,Gradient Type,Gradient Slice Type");
    csvOutput.flush();
  }

  void closeWriter() {
    if (csvOutput != null) {
      csvOutput.flush();
      csvOutput.close();
    }
  }
} 
