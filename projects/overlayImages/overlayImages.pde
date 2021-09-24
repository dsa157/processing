PImage img1;
PImage img2;
PImage img3;
PImage img4;
PImage img5;

int t1=255;
int t2=0;
int step=5;
boolean t1Up = false;
boolean t2Up = true;
int cnt=1;
int maxImages = 5;
PImage[] a1 = new PImage[maxImages];
PImage[] a2 = new PImage[maxImages];

// BLEND, ADD, SUBTRACT, LIGHTEST, DARKEST, DIFFERENCE, EXCLUSION, MULTIPLY, SCREEN, OVERLAY, HARD_LIGHT, SOFT_LIGHT, DODGE, BURN

void setup() {
  size(800, 600);
  for (int i=1; i<= maxImages; i++) {
    String fileName = "http://www.dsa157.com/NFT/Davids-Lyre-" + i + "-small.png";
    PImage img = loadImage(fileName);
    a1[i-1]=img;
    a1[i-1]=img;
  }
  //noLoop();
  frameRate(60);
}

void draw() {
  for (int i=0; i<maxImages; i++) {
    blend1(a1[i], a2[0]);
  }
}

void blend1(PImage i1, PImage i2) {
  tint(255, t1);
  image(i1, 0, 0, width, height);
  tint(255, t2);
  image(i2, 0, 0, width, height);
  //image(img1, 0,0,width,height);
  t1 = (t1Up) ? t1+step : t1-step;
  t2 = (t2Up) ? t2+step : t2-step;
  if (t1 <= 0) { 
    t1Up = true; 
    t1=0;
  }
  if (t1 >= 255) { 
    t1Up = false; 
    t1=255;
  }
  if (t2 <= 0) { 
    t2Up = true; 
    t2=0;
  }
  if (t2 >= 255) { 
    t2Up = false; 
    t2=255;
  }
  //println(t1, t2);
}


void blend2() {
  background(255);
  tint(255);
  //  tint(255,128);
  //  image(img2, 0,0,width,height);
  //  tint(255,128);
  cnt++;
  PImage tmp1 = createImage(width, height, RGB);
  PImage tmp2 = createImage(width, height, RGB);
  tmp2.copy(img2, 0, 0, width, height, 0, 0, width, height);
  ;
  switch(cnt) {
  case 2: 
    tmp2.copy(img2, 0, 0, width, height, 0, 0, width, height);
    ;
    break;
  case 3: 
    tmp2.copy(img3, 0, 0, width, height, 0, 0, width, height);
    ;
    break;
  case 4: 
    tmp2.copy(img4, 0, 0, width, height, 0, 0, width, height);
    ;
    break;
  case 5: 
    tmp2.copy(img5, 0, 0, width, height, 0, 0, width, height);
    ;
    cnt=1; 
    break;
  }
  //tmp1.copy(img1, 0, 0, width, height, 0,0, width, height);;
  tmp1.blend(tmp2, 0, 0, width, height, 0, 0, width, height, SOFT_LIGHT);
  //image(tmp2, 0, 0);
  image(tmp1, 0, 0);

  //image(img1, 0,0,width,height);
  //t1 = (t1Up) ? t1+step : t1-step;
  //t2 = (t2Up) ? t2+step : t2-step;
  //if (t1 <= 0) { t1Up = true; t1=0;}
  //if (t1 >= 255) { t1Up = false; t1=255;}
  //if (t2 <= 0) { t2Up = true; t2=0;}
  //if (t2 >= 255) { t2Up = false; t2=255;}
  ////println(t1, t2);
}
