// class for processing source images to create variations of gradient, zoom, etc //<>// //<>// //<>// //<>//

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
  String csvOutputName = "temp-metadata.csv";
  String layer1Name = "";
  String layer2Name = "";
  String uniquePrefix = "";
  color[][] allGradients = new color[maxColorIterations][width];
  int[][] allPalettes = new int [maxColorIterations][maxPaletteColors];

  color[] gradValues = new color[width];
  HashMap<String, String> imageMetaData = new HashMap<String, String>();
  int outputImageCount = 1;
  JSONObject json = new JSONObject();

  PrintWriter csvOutput;

  DerivativeGenerator(BaseImage img, int gType) {
    //log("DerivativeGenerator constructor");
    bImg = img;
    gradientType = gType;
    setUniquePrefix();
    if (actionPrefix != "") {
      setCsvOutputName();
      //initPrintWriter();
    }
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

  void setLayers(int l) {
    layers = l;
  }

  void setLayer1Name(String str) {
    layer1Name = str;
  }

  void setLayer2Name(String str) {
    layer2Name = str;
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

  void setGradientType(int i) {
    gradientType = i;
  }

  void setGradientSliceType(int i) {
    gradientSliceType = i;
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
    if (playBWEnabled) {
      bImg.setTintOpacity(0, 0);
      generateBlackAndWhitePalette();
    } else {
      generateRandomPalette();
    }
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

  void generateBlackAndWhitePalette() {
    int paletteColors=2;
    int[] gradPalette = new int[paletteColors];
    gradPalette[0] = color(0);
    gradPalette[1] = color(255);
    myPalette = gradPalette;
    paletteSize = myPalette.length;
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
      float r = getRandomInt(0, 255); //getRandomInt(128, 255);
      float g = getRandomInt(0, 255); //getRandomInt(128, 255);
      float b = getRandomInt(0, 255); //getRandomInt(128, 255);
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
      Logger.fine("Processing " + getOutFileName("") + ".png (" + derivativeCount++ + "/" + maxImages + ") ");
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
    if (saveImage) {
      String groupPrefix = (suffix == "-orig" || suffix == "-gray") ? "" : getUniquePrefix();
      saveFrame(outputFolder + "/" + actionPrefix + groupPrefix + getOutFileName(suffix) + suffix + ".png");
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
      imageMetaData.put("FileName", getOutFileName(suffix) + suffix + ".png");
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
      if (saveMetaData) {
        saveJSON(outputFolder + "/" + actionPrefix + getUniquePrefix() + getOutFileName(suffix), suffix);
      }
      int dCount = derivativeCount-1;
      int oCount = outputImageCount++;
      if (saveCVSMetaData) {
        if (csvOutput == null) {
          initPrintWriter();
        }      

        csvOutput.println(
          oCount + "," + 
          dCount + "," + 
          imageMetaData.get("FileName") + "," + 
          imageMetaData.get("BaseFileName") + "," + 
          imageMetaData.get("Zoom") + "," +
          imageMetaData.get("ColorIteration") + "," +
          imageMetaData.get("Palette") + "," +
          imageMetaData.get("Blur") + "," +
          imageMetaData.get("Tint") + "," +
          imageMetaData.get("GradientType") + "," +
          imageMetaData.get("GradientSliceType") + "," +
          imageMetaData.get("ZoomX") + "," +
          imageMetaData.get("ZoomY") + "," +
          imageMetaData.get("Layers") + "," +
          imageMetaData.get("Layer1FileName") + "," +
          imageMetaData.get("Layer2FileName")
          );
        csvOutput.flush();
        recordedCVSMetaData=true;
      }
    }
    catch(Exception e) {
      e.printStackTrace();
      exit();
    }
  }

  void saveJSON(String outFileName, String suffix) {
    if (suffix != "") {
      outFileName = outFileName + suffix + ".json";
    } else {
      outFileName = outFileName + ".json";
    }
    Logger.fine("saveJSON: " + outFileName);
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
      saveJSONObject(json, outFileName);
    }
    catch (Exception e) {
      e.printStackTrace();
    }
  }

  void loadJSON(String inFileName) {
    Logger.fine("loadJSON: " + inFileName);
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
      e.printStackTrace();
    }
  }

  String getDataString(String str) {
    return (str != null) ? str : "";
  }

  void printCvsOutputHeader() {
    csvOutput.println("Num,Derivative,Filename,BaseFileName,ZoomLevel,ColorIteration,Palette,Blur,Tint,Gradient Type,Gradient Slice Type,ZoomX,ZoomY,Layers,Layer1FileName,Layer2FileName");
    csvOutput.flush();
  }

  void closeWriter() {
    try {
      if (csvOutput != null) {
        csvOutput.flush();
        csvOutput.close();
      }
      if (!recordedCVSMetaData) {
        csvOutput = null;
        // delete the file, we didn't write anything
        File f = new File(outputFolder + "/" + getCsvOutputName());
        if (f.exists()) {
          f.deleteOnExit();
        }
      }
    }
    catch (Exception e) {
      e.printStackTrace();
    }
  }
} 
