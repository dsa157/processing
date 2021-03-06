
// parameters
int cols = 45;
int rows = 30;
float w = 20;
float w2 = 8;
int backgroundColor = 255;
int lineColor = 0;
float speed = 1.0;
int spawns = 0;
int spawnMax0 = 2;
int spawnDelay = 20; //how many frames to wait between spawns
// make it random but no more than the defined spawnMax0
int spawnMax = int(random(spawnMax0)) + 1;
int genMax = 5;
int gens = 0;
int fillColorStep = 255/(genMax+1);
int angle=5;        //angle increments during rotation
boolean testMode = true;

Cell[][] grid = new Cell[cols][rows];

void setup()
{
  size(900,600);
  noFill();
  stroke(lineColor);
  rectMode(CENTER);
  for (int j = 1; j < rows-1; j++) {      // start at 1 and got to rows-1 so there is a 1 unit margin
    for (int i = 1; i < cols-1; i++) {    // start at 1 and got to col-1 so there is a 1 unit margin
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
      } else {
        println("nope-spawn bad");
      }
}

void resetSpawns() {
  spawns=0;
  loop();
  spawn();
}

void mouseClicked() {
  resetSpawns();
}

void draw() {
  background(backgroundColor);
  for (int j=0; j<rows; j++) {
    for (int i=0; i<cols; i++) {
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
  if (thisCol<0 || thisCol>cols-1) {  //account for the 1 cell margin
    return null;
  }
  if (thisRow<0 || thisRow>rows-1) {  //account for the 1 cell margin
    return null;
  }
  try {
    Cell c = grid[thisCol][thisRow];
    return c;
  }
  catch(Exception e) {
    println("oops getCell: " + thisCol + "," + thisRow);
    exit();
  }
    return null;
}


//------------------------------------------------------------------
class Cell {
    int myCol=0;
    int myRow=0;
    int myLineColor=-1;
    int myFill=backgroundColor;
    int multiplier = 1;
    int gen = -1;
    
    Cell(int i, int j, int lc) {
      myCol = i;
      myRow = j;
      myLineColor=lineColor;
      randomSeed(myRow+myCol * millis()); //<>//
      randomSeed(myRow * millis());
      multiplier = int(random(1, 5));
  } 
  
  void spawn() {
    if (spawns == spawnMax) {
      return;
    }
    //if (unspawned()) {
      gen = 0;
      setColor();
      gens = int(random(1, genMax)); 
      for (int i=1; i<=gens; i++) {
        generate(i);
      }
    //}
  }
  
  void setColor() {
    color c = color(255, 0, 0); 
    myFill = 0;
  }

  void changeGen(int offset) {
    myFill=offset * fillColorStep;
  }
 
  boolean unspawned() {
    return gen < 0;
  }

  void generate(int offset) {
    //println("generate: " + myCol + "," + myRow);
    if (gen < genMax) {
      for(int i=(myCol-(offset)); i <= myCol+(offset); i++) {  
        for(int j=(myRow-offset); j<= myRow+offset; j++) {
          Cell c = getCell(i,j);
          if (c != null) {
            if (c != this) {
              if (c.gen < 0) {
                c.gen = gen+offset;
                c.changeGen(abs(i-myCol)+abs(j-myRow)+offset);
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
    //setRotation();
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
    //multiplier = 2; //.05;
    //rad = radians((frameCount * multiplier * mySpeed) + myAngle % 360);
    rad = radians(frameCount + myAngle % 360);
    //println(rad);
    rotate(rad);
    if ((mySpeed > 1) && (frameCount % 200 == 0)) {
        // slowdown every 200 frames
        mySpeed--;
    }
  }
  
  void setAngle() {
    if ((myAngle > 0) && (frameCount % 100 == 0)) {
        // recalc every 100 frames
        myAngle = myAngle - angle;
        if (myAngle < 0) myAngle = 0;
    }
  }
  
  void setLineColor() {
    if (myLineColor != lineColor) {
      if (myLineColor > lineColor) { //<>//
        //myLineColor--;
      } else {
        //myLineColor++;
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

  void changeGen(int offset) {
    super.changeGen(offset);
    if (myFill < backgroundColor) {
      myFill=backgroundColor;
      myAngle = offset * angle;
    }
  }

}
