PImage img, imgGrid;  //<>// //<>// //<>//
String imgName = "ellipses.png";
//String imgName = "Innoculation-hirez.png";
//String imgName = "Innoculation3.png";
//String imgName = "Davids-Lyre-1-NFT.png";
//String imgName = "storm.png";
String gridName = "grid.png";


int zoomLevel = 1;
int maxZooms = 3;
int click = 1;
int small = 1;
int zoomX = width/2;
int zoomY = height/2;
int imageHeight;
int imageWidth;
float xOffset=0.0;
float yOffset=0.0;
int showGrid = 1;
//boolean zoomDefined = false;

void setup() {
  size(1000,750);
  //size(800, 527);  Innoculation zoom: 452, 141
  zoomX = 304;
  zoomY = 274;
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

// determine whether zoomX is to the right or the left of center
int getXHalf() {
  if (zoomX > width/2) {
    return -1;
  } else {
    return 1;
  }
}

// determine whether zoomY is above or below center
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
    zoom();
  }
}

void zoom() {
  if (zoomLevel == 1) {
      //println("shift: " + xOffset, yOffset);
      if (showGrid==1) {
        image(imgGrid, width/2, height/2, width, height); 
        tint(255, 50);
      }
      image(img, width/2, height/2, width * zoomLevel, height * zoomLevel); 
      if (showGrid==1) {
        tint(255, 64);
        image(imgGrid, width/2, height/2, width, height); 
      }
      tint(255, 255);
    } else {
      tint(255, 255);
      pushMatrix();
      translate(xOffset * zoomLevel, yOffset * zoomLevel);
      println("shift: " + xOffset*zoomLevel, yOffset*zoomLevel);
      image(img, width/2, height/2, width * zoomLevel, height * zoomLevel); 
      popMatrix();
      if (showGrid==1) {
        tint(255, 64);
        image(imgGrid, width/2, height/2, width, height);
      }
      tint(255, 255);
    }
}

void mousePressed() {
  tint(255, 255);
  if (zoomLevel==1) {
    println(mouseX, mouseY);
    zoomX = mouseX;
    zoomY = mouseY;
    xOffset = abs(zoomX - width/2) * getXHalf();
    yOffset = abs(zoomY - height/2) * getYHalf();
    //zoomDefined = true;
  }
  zoomLevel++;
  if (zoomLevel > maxZooms) {
    zoomLevel=1;
  }
  click=1;
  println("click=1 zoomLevel=" + zoomLevel);
}
