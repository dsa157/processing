float counter;
int sz = 50;
float w = 100;
int skipFrames = 20;
int cols=2;
int rows=2;
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
  drawGrid();
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
    int thisRow = int(random(1,rows));
    int thisCol = int(random(1,cols));
    Cell c = getCell(thisCol,thisRow);
    if (c != null) {
      c.display();
    }
  }
}

void drawEmptyCell(int i, int j) {
    stroke(0);
    fill(200);
    rect(i*w, j*w, w, w);
    noStroke();
    noFill();
}

void drawGrid() {
  for (int j=0; j<rows; j++) {
    for (int i=0; i<cols; i++) {
      Cell c = getCell(i,j);
      if (c != null) {
          //println("drawGrid: " + i + "," + j);
          drawEmptyCell(i,j);
          c.display();
      }
      else {
        //println("drawGrid oops: " + i + "," + j); //<>//
      }
    }
  }
}

void draw()
{
  //drawCell();
} 

//--------------

class Cell {
  int myRow, myCol;
  PShape outline, arc1, rect1;
  int myFill = 255;
  int myBG = 0;
  
  Cell(int i, int j) {
    myCol=i;
    myRow=j;
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
  
  PShape getShape() {
    return outline;
  }
  
  void rotateShape() {
    int i = int(random(0,4));
    rotate(PI + (HALF_PI * i));
  }
  
  void scaleShape() {
    int i = int(random(0,2));
    println("scaleShape: " + i);
    i=0;
    if (i == 0) {
      //translate(-(w+w/4),-(w+w/4));
      //translate((w-w/4),(w-w/4));
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
    translate(myCol*w+w,myRow*w+w);
    scaleShape();
    rotateShape();
    shape(getShape());
    popMatrix();
  }
}