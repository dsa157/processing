//int[] palette0 = {#287994,  #E09B53, #54BEE0, #78DDFF, #945819};

// actual simplified color palettes from Gathering Storm created from https://color.adobe.com/create/image
//int[] palette1 = {#2A2859, #44428C, #222140, #8C7D32, #73653C};

int[] palette = {#3E3949, #2A264E, #E4DED3, #958C31, #766C5C, #6C63A1};
int[] discreteColors = {10, 20, 33, 50, 75};
Gradient g;
int click=1;

void setup() {
  size(600,200);
  g = new Gradient(palette);
  background(255);
  stroke(255);
  //noStroke();
}

void draw() {
  if (click==1) {
    click=0;
    g.draw();
    g.drawDiscreteColors(discreteColors);
  }
}

void mouseClicked() {
  println("---");
  click=1;
}

class Gradient {
  
  color from; 
  color to; 
  int[] myPalette;
  int paletteSize = 0;
  color[] gradValues = new color[width];
  
  Gradient(int[] palette) {
    myPalette = palette;
    paletteSize = palette.length;
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
    click = 0;
    int ndx = 0;
    int prev = 0;
    for (int i=0; i<paletteSize-1; i++) {
      prev = ndx;
      if (i == paletteSize-2) {
        ndx = width;
      }
      else {
        ndx = int(random(ndx, width));
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
    color c = gradValues[percentPosition];
    println("getColorByPercentPosition=", percentPosition, c);
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
      int rectWidth=50;
      fill(getColorByPercentPosition(position));
      stroke(0);
      rect(percentPosition, rectWidth, rectWidth, rectWidth);
      //fill(getColorByPosition(position));
    }
  }

}
