float counter;
int sz = 50;
float w = 100;
int skipFrames = 5;
int cols=8;
int rows=5;
boolean NO_SCALE = true;
int DECAY = int(255/2);
Cell[][] grid = new Cell[cols][rows];

void setup()
{
  size(900,600);
  counter=0.0;
  rectMode(CENTER);
  for (int i=0; i<cols; i++) {
    for (int j=0; j<rows; j++) {
      grid[i][j] = new Cell(i,j);
    }
  }
  drawGrid(NO_SCALE);
}

Cell getCell(int thisCol, int thisRow) {
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

void drawCell() {
  if (frameCount % skipFrames == 0) {
    int thisRow = int(random(0,rows));
    int thisCol = int(random(0,cols));
    Cell c = getCell(thisCol,thisRow);
    c.setScale(false);
    if (c != null) {
      c.display();
    }
  }
}

void drawEmptyCell(int i, int j) {
    println("drawEmptyCell: " + i + "," + j);
    println("drawEmptyCell: " + (i*w+w) + "," + (j*w+w));

    stroke(0);
    fill(250);
    pushMatrix();
    translate(i*w+w,j*w+w);
    rect(0, 0, w, w);
    //noStroke();
    //noFill();
    popMatrix();
}

void drawGrid(boolean scale) {
  for (int j=0; j<rows; j++) {
    for (int i=0; i<cols; i++) {
      Cell c = getCell(i,j);
      if (c != null) {
          c.setScale(scale);
          //println("drawGrid: " + i + "," + j);
          //drawEmptyCell(i,j);
          c.display();
      }
      else {
        //println("drawGrid oops: " + i + "," + j); //<>//
      }
    }
  }
}

void mousePressed() {
  noLoop();
}

void mouseReleased() {
  loop();
}


void draw()
{
  drawCell();
} 

//----------------------------------------------------------------------

class Cell {
  int myRow, myCol;
  boolean myScale = true;
  PShape outline, arc1, rect1;
  int myFill = 255;
  int myBG = 0;
  
  Cell(int i, int j) {
    myCol=i;
    myRow=j;
    init();
  }
  
  void init() {
    outline = createShape(GROUP);
    noFill(); // set desired shape fill state when you create the shape
    noStroke();
    setRandomInverse();
    fill(myFill);  
    arc1 = createShape(ARC, 0, -w/2, w, w, 0, PI, OPEN);
    fill(myBG);
    rect1 = createShape(RECT, 0, 0, w, w);
    outline.addChild(rect1);
    outline.addChild(arc1);
  }
  
  void decay() {
    int delta = 1;
    int arcFill = arc1.getFill(0);
    int rectFill = rect1.getFill(0);
    
    if (arcFill > DECAY) { arcFill -= delta; } //<>//
    if (rectFill > DECAY) { rectFill -= delta; }
    if (arcFill < DECAY) { arcFill += delta; }
    if (rectFill < DECAY) { myBG += delta; }
    if ((arcFill == DECAY) || (rectFill == DECAY)) {
      //myFill=color(255, 0, 0);
      //myBG=0;
      arc1.setFill(arcFill);
      rect1.setFill(rectFill);
    }
  }
  
  void setScale(boolean b) {
    myScale = b;
  }
  
  PShape getShape() {
    return outline;
  }
  
  void rotateShape() {
      int i = int(random(0,4));
      rotate(PI + (HALF_PI * i));
  }
  
  void scaleShape() {
    int i = int(random(0,2));
    //i=0;
    if ((i == 0) && (myScale != NO_SCALE)) {
      int j = int(random(0,4));
      if (j==0) { translate(-w/4,-w/4); }
      if (j==1) { translate(-w/4,w/4); }
      if (j==2) { translate(w/4,-w/4); }
      if (j==3) { translate(w/4,w/4); }
      scale(.5);
    }
  }
  
  void setRandomInverse() {
    int inverse=int(random(0,2));
    if (inverse == 1) {
      myFill = 0;
      myBG = 255;
    }
  }

  
  void display() {
    pushMatrix();
    decay();
    translate(myCol*w+w,myRow*w+w);
    //scaleShape();
    rotateShape();
    shape(getShape());
    popMatrix();
  }
}