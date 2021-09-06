PImage fractal, fractal2;
int outputCount = 0;
String outFilePrefix = "GatheringStorm";
PrintWriter printFile;
int copies = 2;

void setup() {
  //fractal = loadImage("The-Gathering-Storm.png");
  fractal = loadImage("The-Gathering-Storm-NFT-00001.png");
  size (400, 559);
  imageMode(CENTER);
}

void draw() {
  if (outputCount < copies) {
    outputCount++;
    createScaleSet();
  }
  else {
    exit();
  }
  
}

void createScaleSet() {
    image(fractal,width/2,height/2,fractal.width/(outputCount),fractal.height/(outputCount));
    String outFileName = outFilePrefix+"-####.png"; 
    saveFrame(outFileName);
    String[] params = new String[2];
    params[0] = "FileName: " + outFilePrefix + "-" + outputCount+".png";
    params[1] = "outPutCount: " + outputCount;
    logParameters(outputCount, params);
}

void logParameters(int outputCount, String[] params) {
  saveStrings("params-" + outputCount + ".txt", params);
}
