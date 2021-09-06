//int[] palette0 = {#287994,  #E09B53, #54BEE0, #78DDFF, #945819};

// actual simplified color palettes from Gathering Storm created from https://color.adobe.com/create/image
//int[] palette1 = {#2A2859, #44428C, #222140, #8C7D32, #73653C};

int EVEN = 1;
int RAND = 2;
int maxFrames = 5;
int maxColors = 10;


//int[] palette = {#3E3949, #2A264E, #E4DED3, #958C31, #766C5C, #6C63A1};
int[] palette = {#3E3949, #2A264E, #E4DED3, #958C31, #766C5C, #000000};
int[] discreteColors = {10, 20, 33, 50, 75};
Gradient g;
PImage img;
int click=1;
//int frameCount = 0;
String outFilePrefix = "test";

void setup() {
  size(800,1118);
  imageMode(CENTER);
  img = loadImage("gray1.png");
  g = new Gradient(EVEN, palette);
  background(255);
  stroke(255);
  //noStroke();
}

void draw() {
  if (frameCount <= maxFrames) {
    click=0;
    g.draw();
    g.drawDiscreteColors(discreteColors);
    //g.mapColors(img);
    String outFileName = outFilePrefix+"-####.png"; 
    saveFrame(outFileName);
  } 
  else {
    exit();
  }
}

void mouseClicked() {
  println("---");
  click=1;
}

class Gradient {
  
  color from; 
  color to; 
  PImage myImg;
  int gradientType = EVEN;
  
  int[] myPalette;
  int paletteSize = 0;
  color[] gradValues = new color[width];
  
  Gradient(int gType, int[] palette) {
    myPalette = palette;
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
        line(j,0,j,height);
        stroke(newColor);
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
      println(from, to);
      lerpColors(ndx,prev,from,to);
    }
  }
  
  color getColorByPosition(int i) {
    return gradValues[i];
  }

  color getColorByPercentPosition(int i) {
    int percentPosition = getPercentPosition(i);
    color c = gradValues[percentPosition];
    //println("getColorByPercentPosition=", percentPosition, c);
    return c;
  }

  color getPercentPosition(int i) {
    float percent = width * (i * 1.0)/100;
    int percentPosition = int(percent);
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
  
  void mapColors(PImage img1) {
    myImg = img1;
    PImage tempImg = myImg;
    tempImg.loadPixels();
    for (int i=0; i<tempImg.pixels.length; i++) {
      color c = tempImg.pixels[i];
      float b = brightness(c);
      int percentBrightness = int((b/255.0)*100.0);
      tempImg.pixels[i] = getColorByPercentPosition(percentBrightness);
    }
    tempImg.updatePixels();
    image(tempImg,width/2,height/2,img.width,img.height);    
  }
  
  void generateRandomPalette() {
    int[] tmpPalette = new int[maxColors];
    for (int i=0; i<maxColors; i++) {
      float r = random(255);
      float g = random(255);
      float b = random(255);
      color c = color(r,g,b);
      tmpPalette[i] = c;
    }
    myPalette = tmpPalette;
    paletteSize = myPalette.length;
  }

}
