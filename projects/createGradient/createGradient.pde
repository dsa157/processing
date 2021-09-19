static abstract class GradientSliceType {
  static final int EVEN = 0;
  static final int RAND = 1;
}

static abstract class GradientType {
  static final int SMOOTH = 0;
  static final int DISCRETE = 1;
}

int maxPaletteColors = 6;
int minPaletteColors = 2;
int paletteColors = 0;
int[] myPalette;
int paletteSize = 0;
int click=1;
int gradientSliceType = GradientSliceType.EVEN;
int gradientType = GradientType.DISCRETE;
color[] gradValues;
boolean useBlackAndWhitePalette = false;

//-------------------------

void setup() {
  size(1000, 750);
  gradValues = new color[width];
  imgSetup();
  frameRate(30);
}

void draw() {
  //gradTest();
  imgDraw();
}

void gradTest() {
  if (click==1) {
    click=0;
    paletteColors = int(random(minPaletteColors, maxPaletteColors+1));
    if (useBlackAndWhitePalette) {
      generateBlackAndWhitePalette();
    } else {
      generateRandomPalette();
    }
    generateGradient();
  }
}

void mousePressed() {
  click=1;
}

void keyPressed() {
  if (key == 'b' || key == 'B') {   //  use [B]lack and White Palette
    useBlackAndWhitePalette = !useBlackAndWhitePalette;
  }
  if (key == 'e' || key == 'E') {   // toggle [E]ven/Random Gradient slices
    gradientSliceType = (gradientSliceType == GradientSliceType.EVEN ? 
      GradientSliceType.RAND : GradientSliceType.EVEN);
  }
  if (key == 'n' || key == 'N') {   // [N]ext
  }
  if (key == 'q' || key == 'Q') {   // [Q]uit
    exit();
  }
  if (key == 's' || key == 'S') {   // toggle [S]mooth/Discrete
    gradientType = (gradientType == GradientType.SMOOTH ? 
      GradientType.DISCRETE : GradientType.SMOOTH);
  }
  click=1;
}

void generateRandomPalette() {
  int[] gradPalette = new int[paletteColors];
  for (int i=0; i<paletteColors; i++) {
    float r = random(255); //random(128, 255);
    float g = random(255); //random(128, 255);
    float b = random(255); //random(128, 255);
    color c = color(r, g, b);
    //print(i, hex(c), "");
    gradPalette[i] = c;
  }
  println("");
  myPalette = gradPalette;
  paletteSize = myPalette.length;
  println(savePaletteAsHexStrings());
} 

void generateBlackAndWhitePalette() {
  paletteColors=2;
  int[] gradPalette = new int[paletteColors];
  gradPalette[0] = color(0);
  gradPalette[1] = color(255);
  myPalette = gradPalette;
  paletteSize = myPalette.length;
  println(savePaletteAsHexStrings());
} 

String savePaletteAsHexStrings() {
  String retString = "";
  for (int i=0; i<myPalette.length; i++) {
    String s = hex(myPalette[i]);
    retString += s + ";";
  }
  retString = retString.substring(0, retString.length()-1);  // chop off the last ";"  
  return retString;
}

void generateGradient() {  
  fill(255);
  int ndx = 0;
  int prev = 0;
  color from = myPalette[0];
  color to;
  println("palette size = " + paletteSize);
  //println (200/3.0);
  int sliceWidth = 0;
  if (gradientType == GradientType.DISCRETE) {
    // for discrete gradients, we want the same number of slices as palette size
    sliceWidth = int(round(width/(paletteSize * 1.0)));  // even width slices
  } else {
    //for smooth gradients, one less, since we need to end on the last color
    sliceWidth = int(round(width/(paletteSize-1 * 1.0)));  // even width slices
  }
  //println("sliceWidth: " + sliceWidth);
  for (int i=0; i<paletteSize; i++) {
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
    //println(prev, ndx);
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
    line(j, 0, j, height);
    stroke(newColor);
  }
  from = newColor;
}

//----- mask testing

PImage img;
PImage imgMask;
int r;
int g;
int b;
int t;

void fadeBG() {
  r = (r>0) ? r-- : 0;
  g = (g>0) ? g-- : 0;
  b = (b>0) ? b-- : 0;

  if (r==0 && g==0 && b==0) {
    r = int(random(256));
    g = int(random(256));
    b = int(random(256));
  }
  println(r,b,g);
  background(r, g, b);
  tint(255,t);
  t--;
  if (t==0) { t=255; } 
  background(0);
}

void imgSetup() {
  img = loadImage("Davids-Lyre-4-small.png");
  imgMask = loadImage("Davids-Lyre-1-small.png");
  img.mask(imgMask);
  imageMode(CENTER);
  r=0;
  g=0;
  b=0;
  t=128;
}

void imgDraw() {
  fadeBG();
  image(img, width/2, height/2);
  //image(img, mouseX, mouseY);
}
