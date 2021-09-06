PImage fractal, fractal2;
int outputCount = 0;
String outFilePrefix = "GatheringStorm";
PrintWriter printFile;
int copies = 5;

void setup() {
  fractal2 = loadImage("The-Gathering-Storm.png");
  fractal = loadImage("The-Gathering-Storm-NFT-00001.png");
  size (400, 559);
  imageMode(CENTER);
  //loadPixels();
  //fractal.loadPixels(); //<>//
}

void draw() {
  createScaleSet();
}

void mapGradient() {
    image(fractal,width/2,height/2,fractal.width/(outputCount),fractal.height/(outputCount));
}

void createScaleSet() {
  if (outputCount < copies) {
    outputCount++;
    image(fractal,width/2,height/2,fractal.width/(outputCount),fractal.height/(outputCount));
    String outFileName = outFilePrefix+"-####.png"; 
    saveFrame(outFileName);
    String[] params = new String[2];
    params[0] = "FileName: " + outFilePrefix + "-" + outputCount+".png"; ;
    params[1] = "outPutCount: " + outputCount;
    logParameters(outputCount, params);
  } 
  else {
    exit();
  }
}

void logParameters(int outputCount, String[] params) {
  saveStrings("params-" + outputCount + ".txt", params);
}

void orig() {
  image(fractal,width/2,height/2,800,1118);
}

void flipIt() {
  MyImage newImg = new MyImage(fractal);
  //newImg.flip();
  image(newImg.img,width/2,height/2,800,1118); //<>//
  updatePixels();
}

void threshold(int t) {
  //image(fractal,width/2,height/2,400,559);
  for (int x=0; x<width; x++) {
    for (int y=0; y<height; y++) {
      //for (int i=0; i<pixels.length; i++) {
      //if (y % 10 == 0) {
      int loc = x+y*width;
      float r  = red(fractal.pixels[loc]);
      float g  = green(fractal.pixels[loc]);          
      float b  = blue(fractal.pixels[loc]); //<>//
      float br = brightness(fractal.pixels[loc]);
      //int thresh = t
      if (br > t) {
        pixels[loc]=color(255);
      } else {
        pixels[loc]=color(0);
      }
      //pixels[loc]=color(r,g,b);
      //}
      //}
    }
  updatePixels();
  }
}

// ---------------------------

class MyImage
{
  PImage img;
  
  MyImage(PImage img1) {
    img = img1;
  };
  
  void flip() {
    img.loadPixels(); //<>//
    int[] tempPixels = img.pixels;
    for (int i=0; i<img.pixels.length; i++) {
      tempPixels[img.pixels.length-i]=img.pixels[i];
    }
    //img.updatePixels();
  }
}

/*

CafeLatte2 {
gradient:
  title="Cafe Latte 2" smooth=no index=0 color=14480615 index=60
  color=13619953 index=97 color=542922 index=135 color=4828375
  index=172 color=818811 index=211 color=68625 index=302 color=1198141
  index=339 color=470807
opacity:
  smooth=no index=0 opacity=255
}

*/
