
// parameters
int cols = 45;
int rows = 30;
float w = 20;
float w2 = 8;
int backgroundColor = 255;
int lineColor = 0;
int lineColor2 = 100;
float speed = 1.0;
int spawns = 0;
int spawnMax0 = 6;
int spawnDelay = 20; //how many frames to wait between spawns
// make it random but no more than the defined spawnMax0
int spawnMax = int(random(spawnMax0)) + 1;
int genMax = 3;
int fillColorStep = 255/(genMax+1);
int angle=5;
boolean testMode = true;

Cell[][] grid = new Cell[cols][rows];

void setup()
{
  size(900,600);
  noFill();
  stroke(lineColor);
  rectMode(CENTER);
  for (int j = 1; j < rows-1; j++) {
    for (int i = 1; i < cols-1; i++) {
      int clr = i + j;
      //println("setup " + i + "," + j);
      if (testMode) {
        grid[i][j] = new Cell(i,j, clr);
      } else {
        grid[i][j] = new Cell2(i,j, clr);
      }
    }
  }
}

void spawn() {
      spawns++;
      int spawnRow = -1;
      int spawnCol = -1;
      while(spawnRow < 0 || spawnRow >= rows) {
        spawnRow = int(random(1, rows-1));
      }
      while(spawnCol < 0 || spawnCol >= cols) {
        spawnCol = int(random(1, cols-1));
      }
      Cell c = getCell(spawnCol,spawnRow);
      if (c != null) {
        c.spawn();
      }
}

void mouseClicked() {
  spawns=0;
  loop();
  spawn();
}

void draw() {
  background(backgroundColor);
  for (int j=1; j<rows-1; j++) {
    for (int i=1; i<cols-1; i++) {
      Cell c = getCell(i,j);
      if (c != null) {
        stroke(c.myLineColor);
        fill(c.myFill);
        c.display();
      }
    }
  }
  if (frameCount % spawnDelay   == 0) {
    if (spawns <= spawnMax) { 
      spawn();
    }
  }
}

Cell getCell(int thisCol, int thisRow) {
  if (thisCol<0 || thisCol>cols) {
    return null;
  }
  if (thisRow<0 || thisRow>rows) {
    return null;
  }
  try {
    Cell c = grid[thisCol][thisRow];
    return c;
  }
  catch(Exception e) {
    //println("oops getCell: " + thisCol + "," + thisRow);
    return null;
  }
}


//------------------------------------------------------------------
class Cell {
  
    int myCol=0;
    int myRow=0;
    int myLineColor=0;
    int myFill=backgroundColor;
    int multiplier = 1;
    int gen = -1;
    
    Cell(int i, int j, int lineColor) {
      myCol = i;
      myRow = j;
      myLineColor=lineColor;
      randomSeed(myRow+myCol * millis());
      randomSeed(myRow * millis());
      multiplier = int(random(1, 5));
  } 
  
  void spawn() {
    if (spawns == spawnMax) {
      return;
    }
    if (unspawned()) {
      gen = 0;
      setColor();
      for (int i=1; i<=genMax; i++) {
        int x=1;
        x++;
        gen1(i);
      }
    }
  }
  
  void setColor() {
    myFill = 0;
  }

  void changeGen() {
    myFill=gen * fillColorStep;
  }
 
  boolean unspawned() {
    return gen < 0;
  }

  void gen1(int offset) {
    //for (int i=0; i<gen; i++) {
      //print(" ");
    //}
    //println("gen1: " + this + "," + myCol + "," + myRow);
    if (gen < genMax) {
      for(int i=(myCol-offset); i <= myCol+offset; i++) {  
        for(int j=(myRow-offset); j<= myRow+offset; j++) {
          Cell c = getCell(i,j);
          if (c != null) {
            if (c != this) {
              if (c.gen < 0) {
                c.gen = gen+offset;
                c.changeGen();
              }
            }
           }
          }
      }
    }
  }
    
  void display() {
    try {
      pushMatrix();
      float tx = (myCol*w) + w/2;
      float ty = (myRow*w) + w/2;
      translate(tx, ty);
      //fill(myLineColor * 10);
      //noStroke();
      rect(0, 0, w, w);
      popMatrix();
    }
    catch(Exception e) {
      print("oops " + myCol + "," + myRow);
    }
  }
}


//------------------------------------------------------------------
class Cell2 extends Cell {
  
  int counter=0;
  int myAngle = angle;
  float ax0 = 0;
  float ay0 = 0;
  float bx0 = 0;
  float by0 = 0;
  float cx0 = 0;
  float cy0 = 0;
  float dx0 = 0;
  float dy0 = 0;
  float mySpeed = speed;
  float rad = 1;
  float ax = 0;
  float ay = 0;
  float bx = 0;
  float by = 0;
  float cx = 0;
  float cy = 0;
  float dx = 0;
  float dy = 0;
  
  Cell2(int i, int j, int lineColor) {
    // Runs the superclass' constructor
    super(i, j, lineColor);
    randomSeed(myRow+myCol * millis());
    randomSeed(myRow * millis());
    multiplier = int(random(1, 5));

  }
  
  void display() {
    pushMatrix();
    drawRect1();
    counter++;
    setRotation();
    setAngle();
    setLineColor();
    drawRect2();
    popMatrix();
    drawLines();
  }
  
  void drawRect1() {
    float tx = (myCol*w) + w/2;
    float ty = (myRow*w) + w/2;
    translate(tx, ty);
    noStroke();
    rect(0, 0, w, w);
    float h = w/2;
    ax0 = tx - h;
    ay0 = ty - h;
    bx0 = tx - h;
    by0 = ty - h+w;
    cx0 = tx - h+w;
    cy0 = ty - h;
    dx0 = tx - h+w;
    dy0 = ty - h+w;
  }
  
  void setRotation() {
    float multiplier = 2; //.05;
    rad = radians((frameCount * multiplier * mySpeed) + myAngle % 360);
    //println(rad);
    rotate(rad);
    if ((mySpeed > 1) && (frameCount % 200 == 0)) {
        mySpeed--;
    }
  }
  
  void setAngle() {
    if ((myAngle > 0) && (frameCount % 100 == 0)) {
        myAngle = myAngle - angle;
        if (myAngle < 0) myAngle = 0;
    }
  }
  
  void setLineColor() {
    if (myLineColor != lineColor) {
      if (myLineColor > lineColor) {
        myLineColor--;
      } else {
        myLineColor++;
      }
    }
  }
  
  void drawRect2() {
    stroke(myLineColor);
    rect(0, 0, w2, w2);
    float h2 = w2/2;
    ax = screenX(-h2, -h2);
    ay = screenY(-h2, -h2);
    bx = screenX(-h2, h2);
    by = screenY(-h2, h2);
    cx = screenX(h2, -h2);
    cy = screenY(h2, -h2);
    dx = screenX(h2, h2);
    dy = screenY(h2, h2);
  }
  
  void drawLines() {
    line(ax0, ay0, ax, ay);
    line(bx0, by0, bx, by);
    line(cx0, cy0, cx, cy);
    line(dx0, dy0, dx, dy);
  }
  
  void setColor() {
    myFill=backgroundColor;
  }

  void changeGen() {
    super.changeGen();
    myFill=backgroundColor;
    myAngle = (gen * 5) * angle;
  }

}
