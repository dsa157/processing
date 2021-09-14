// class for processing source images to create variations of gradient, zoom, etc //<>//

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
  boolean overlayColor = !overlayGray;
  int xOffset = 0;
  int yOffset = 0;
  String outputFolder = "output";
  color[][] allGradients = new color[maxColorIterations][width];
  int[][] allPalettes = new int [maxColorIterations][maxPaletteColors+1];

  color[] gradValues = new color[width];
  String[] imageMetaData = new String[4];
  PrintWriter csvOutput = createWriter(outputFolder + "/" + "metadata.csv"); 

  DerivativeGenerator(BaseImage img, int gType) {
    bImg = img;
    gradientType = gType;
  }

  void setBaseImage(BaseImage img) {
    bImg = img;
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
      if (saveGradientImage) {
        line(j,0,j,height);
        stroke(newColor);
      }
    }
  }

  void generateGradient() {
    generateRandomPalette();
    int ndx = 0;
    int prev = 0;
    for (int i=0; i<paletteSize-1; i++) {
      prev = ndx;
      if (i == paletteSize-2) {
        ndx = width;
      } else {
        if (gradientType == EVEN) {
          ndx = i * int(width/paletteSize);
        } else {
          ndx = int(random(ndx, width));
        }
      }
      from = color(myPalette[i]);
      to=color(myPalette[i+1]);
      lerpColors(ndx, prev, from, to);
    }
    if (saveGradientImage) {
      tint(255, 255);
      saveFrame(outputFolder + "/" + getOutFileName() + "-gradient.png");
      background(255);
    }
    arrayCopy(gradValues, allGradients[colorIteration-1]);
    //allGradients[colorIteration-1]=gradValues;
    //println("dsa2", colorIteration, allGradients[colorIteration-1][100], allGradients[colorIteration-1][200], allGradients[colorIteration-1][300]);
    //printArray(gradValues);
  }

  void setGradient() {
    setPalette();
    arrayCopy(allGradients[colorIteration-1], gradValues);
    //gradValues = allGradients[colorIteration-1];
  }

  void setPalette() {
    //println("currentColorIteration: " + colorIteration);
    arrayCopy(allPalettes[colorIteration-1], myPalette);
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

  void generateRandomPalette() {
    int[] gradPalette = new int[maxPaletteColors];
    //gradPalette[0] = color(0);
    for (int i=0; i<maxPaletteColors; i++) {
      float r = random(255); //random(128, 255);
      float g = random(255); //random(128, 255);
      float b = random(255); //random(128, 255);
      color c = color(r, g, b);
      gradPalette[i] = c;
    }
    //arrayCopy(gradPalette, myPalette);
    myPalette = gradPalette;
    paletteSize = myPalette.length;
    //println("Current Color Iteration: " + colorIteration);
    //println(savePaletteAsHexStrings());
    arrayCopy(myPalette, allPalettes[colorIteration-1]);
    //allPalettes[colorIteration-1]=myPalette; // we started colorIterations as 1-based, but the array is 0-based, so subtract 1 
  }

  void mapColors() {
    if (saveOutputImage) {
      for (int z=1; z<=maxZooms; z++) {
        zoomLevel = z;
        println("Processing " + getOutFileName() + ".png (" + imageCount++ + "/" + maxImages + ")");
        tint(255, 255);
        zoom(bImg.getColorImg(), zoomLevel);
        saveUnmodifiedImage(bImg.getColorImg());
        //saveFrame(outputFolder + "/" + getOutFileName() + ".png");
        if (saveGrayImage && colorIteration==0) {
          zoom(bImg.getGrayImg(), zoomLevel);
          saveFrame(outputFolder + "/" + getOutFileName() + "-gray.png");
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
        saveFrame(outputFolder + "/" + getOutFileName() + ".png");
        saveImageMetaData();
        tint(255, 255);
      }
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
      image(img, width/2, height/2, imageWidth*zoomLevel, imageHeight*zoomLevel);
      // after the rendering of the first unzoomed image, calculate the point where the next zooms will be centered
      if (zoomX == 0) {
        // if not defined, set to center
        zoomX = width/2;
        zoomY = height/2;
      }
      xOffset = abs(zoomX - width/2) * getXHalf();
      yOffset = abs(zoomY - height/2) * getYHalf();
    } 
    else {
      pushMatrix();
      translate(xOffset*zoomLevel, yOffset*zoomLevel);
      image(img, width/2, height/2, imageWidth*zoomLevel, imageHeight*zoomLevel); 
      popMatrix();
    }
  }

  void overlay() {
    // draw the temp image, then overlay the original at 50% opacity
    tint(255, 255);
    zoom(bImg.getColorImg(), zoomLevel);
    bImg.setTint(0);
    PImage blurredImg = bImg.getTempImg().copy();
    blurredImg.filter(BLUR, bImg.getBlurValue());
    zoom(blurredImg, zoomLevel);
    if (saveBlurredImage) {
      zoom(blurredImg, zoomLevel);
      saveFrame(outputFolder + "/" + getOutFileName() + "-blur.png");
    }

    bImg.setTint(1);
    if (overlayGray) {
      zoom(bImg.getGrayImg(), zoomLevel);
    }
    if (overlayColor) {
      zoom(bImg.getColorImg(), zoomLevel);
    }
  }

  void overlay2() {
    // draw the temp image, then overlay the original at 50% opacity
    PImage saturatedImg = bImg.getGrayImg().copy();
    PImage blurredImg = bImg.getTempImg().copy();
    blurredImg.filter(BLUR, bImg.getBlurValue());
    colorMode(HSB, 255, 255, 255);
    for (int i=0; i<blurredImg.pixels.length; i++) {
      color blurredPixelColor = color(blurredImg.pixels[i]);
      
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

  String savePaletteAsHexStrings() {
    if (myPalette == null) {
      return "original palette";
    }
    String retString = "{ ";
    for (int i=0; i<myPalette.length; i++) {
      String s = hex(myPalette[i], 6);
      retString += "#" + s + ",";
    }
    retString = retString.substring(0, retString.length()-1);  // chop off the last ","  
    retString += " }";
    return retString;
  }
  
  void saveUnmodifiedImage(PImage img) {
    if (saveUnmodifiedImage) {
      if (frameCount == 1) {
        if (colorIteration == 1) {
          saveFrame(outputFolder + "/" + getOutFileName() + "-orig.png");
        }
      } else {
        if (colorIteration == 1) {
          saveFrame(outputFolder + "/" + getOutFileName() + "-deriv.png");
        }
      }
      background(255);
    }
  }
  
  void saveImageMetaData() {
      imageMetaData[0] = "FileName: " + getOutFileName() + ".png";
      imageMetaData[1] = "Palette: " + savePaletteAsHexStrings();
      imageMetaData[2] = "Zoom Level: " + zoomLevel;
      imageMetaData[3] = "Color Iteration: " + colorIteration;
      if (saveMetaData) {
        saveStrings(outputFolder + "/" + getOutFileName() + ".txt", imageMetaData);
      }
      csvOutput.println(imageMetaData[0] + "," + imageMetaData[0] + "," + imageMetaData[0] + "," + imageMetaData[0]);
      csvOutput.flush();
  }
  
  void closeWriter() {
   csvOutput.flush();
   csvOutput.close();
  }
  
} 
