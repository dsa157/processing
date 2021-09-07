//int[] palette0 = {#287994,  #E09B53, #54BEE0, #78DDFF, #945819};

// actual simplified color palettes from Gathering Storm created from https://color.adobe.com/create/image
//int[] palette1 = {#2A2859, #44428C, #222140, #8C7D32, #73653C};

int EVEN = 1;
int RAND = 2;
int WARM = 3;
int COOL = 4;

int maxFrames = 10;
int maxColors = 4;
String colorImage = "Storm.png";
//String colorImage = "Innoculation.jpg";

//int[] palette = {#3E3949, #2A264E, #E4DED3, #958C31, #766C5C, #6C63A1};
int[] palette = {#3E3949, #2A264E, #E4DED3, #958C31, #766C5C, #000000};
int[] discreteColors = {10, 20, 33, 50, 75};
Gradient g;
PImage colorImg;
int click=1;
//int frameCount = 0;
String outFilePrefix = "test";
int imageWidth, imageHeight;

void setup() {
  size(800,1118);
//  size(1600,1067);
  //size(800,534);
  imageWidth = width;
  imageHeight = height;
  imageMode(CENTER);
  colorImg = loadImage(colorImage);
  g = new Gradient(colorImg, RAND, palette);
  background(255);
  //stroke(255);
  //noStroke();
}

void draw() {
  if (frameCount <= maxFrames) {
    click=0;
    g.draw();
    //g.drawDiscreteColors(discreteColors);
    g.mapColors();
    //g.overlay();
    String outFileName = outFilePrefix+"-####.png"; 
    saveFrame(outFileName);
  } 
  else {
    exit();
  }
}

class Gradient {
  
  color from; 
  color to; 
  PImage myImg, grayImg, tempImg;
  int gradientType = EVEN;
  
  int[] myPalette;
  int paletteSize = 0;
  color[] gradValues = new color[width];
  
  Gradient(PImage img, int gType, int[] palette) {
    myPalette = palette;
    myImg = img;
    grayImg = myImg.copy();
    grayImg.filter(GRAY);
    paletteSize = palette.length;
    gradientType = gType;
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
    click = 0;
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
    int[] gradPalette = new int[maxColors+1];
    gradPalette[0] = color(0);
    for (int i=1; i<maxColors; i++) {
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
    tempImg = grayImg.copy();
    tempImg.loadPixels();
    for (int i=0; i<tempImg.pixels.length; i++) {
      color c = tempImg.pixels[i];
      float b = brightness(c);
      int percentBrightness = int((b/255.0)*100.0);
      tempImg.pixels[i] = getColorByPercentPosition(percentBrightness);
    }
    tempImg.updatePixels();
    
    // draw the temp image, then overlay the original at 50% opacity
    tint(255, 255); //<>//
    image(myImg,width/2,height/2,imageWidth,imageHeight);  
    tint(255, 64);
    PImage blurredImg = tempImg.copy();
    blurredImg.filter(BLUR, 6.0);
    image(blurredImg,width/2,height/2,imageWidth,imageHeight);    
    //tint(255, 128);
    //image(colorImg,width/2,height/2,imageWidth,imageHeight);  
  }
    
  void overlay() {
    //loadPixels();
    image(tempImg,width/2,height/2,imageWidth,imageHeight);     //<>//
  }

}
