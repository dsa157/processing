// class used as a container for an image and its properties



class BaseImage {

  protected PImage colorImg, grayImg, tempImg;
  protected String outFilePrefix = "";
  protected int[] tintOpacity = defaultTintOpacity;
  protected float blurValue = defaultBlur;

  BaseImage(String fileName) {
    outFilePrefix = fileName.substring(0, fileName.length()-4);
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
  
  String getOutFileName(int colorIteration, int zoomLevel) {
    return outFilePrefix + "-c" + colorIteration + "-z" + zoomLevel;
  }
} 
