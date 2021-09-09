PImage img, imgGrid;  //<>//
//String imgName = "ellipses.png";
//String imgName = "Innoculation-hirez.png";
String imgName = "Innoculation3.png";
//String imgName = "storm.png";
String gridName = "grid.png";


int imageCount = 1;
int click = 1;
int small = 1;
int zoomX = width/2;
int zoomY = height/2;
int imageHeight;
int imageWidth;
float xOffset=0.0;
float yOffset=0.0;
int showGrid = 0;

void setup() {
  size(800, 527);
  zoomX = 452;
  zoomY = 171;
//  size(400, 559);
//  zoomX = width/2;
//  zoomY = height/2;
//    size(1600,1068);
//    zoomX = 1066; 
//    zoomY = 357;
  xOffset = abs(zoomX - width/2) * getXHalf();
  yOffset = abs(zoomY - height/2) * getYHalf();
  imageMode(CENTER);
  img = loadImage(imgName);
  imageHeight = img.height;
  imageWidth = img.width;
  println(imageHeight, imageWidth, width, height, xOffset, yOffset);
  imgGrid = loadImage(gridName);
}

int getXHalf() {
  if (zoomX > width/2) {
    return -1;
  } else {
    return 1;
  }
}

int getYHalf() {
  if (zoomY > height/2) {
    return -1;
  } else {
    return 1;
  }
}

void draw() {
  if (click == 1) {
    click = 0;
    background(255);
    if (imageCount == 1) {
      println("shift: " + xOffset, yOffset);
      if (showGrid==1) {
        image(imgGrid, width/2, height/2, width, height); 
        tint(255, 50);
      }
      image(img, width/2, height/2, width * imageCount, height * imageCount); 
      if (showGrid==1) {
        tint(255, 64);
        image(imgGrid, width/2, height/2, width, height); 
      }
      tint(255, 255);
      imageCount++;
    } else {
      tint(255, 255);
      pushMatrix();
      translate(xOffset * imageCount, yOffset * imageCount);
      image(img, width/2, height/2, width * imageCount, height * imageCount); 
      popMatrix();
      if (showGrid==1) {
        tint(255, 64);
        image(imgGrid, width/2, height/2, width, height); 
      }
      tint(255, 255);
      imageCount++;
    }
  }
}

void mousePressed() {
  tint(255, 255);
  println(mouseX, mouseY);
  click=1;
}
