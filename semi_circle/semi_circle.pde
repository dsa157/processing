int backgroundColor = 255;
int lineColor = 0;
int cols = 10;
int rows = 7;
int cnt=0;
float w=100;
int skipFrames = 10;
boolean testMode = true;
Cell[][] grid = new Cell[cols][rows];


void setup() {
  size(900,600);
  noFill();
  noStroke();
  //stroke(lineColor);
  rectMode(CENTER);
  fill(150);
  for (int j = 1; j < rows-1; j++) {      // start at 1 and got to rows-1 so there is a 1 unit margin
    for (int i = 1; i < cols-1; i++) {    // start at 1 and got to col-1 so there is a 1 unit margin
      grid[i][j] = new Cell(i,j);
    }
  }
  drawGrid();
}

Cell getCell(int thisCol, int thisRow) {
  if (thisCol<0 || thisCol>cols) {  //account for the 1 cell margin
    return null;
  }
  if (thisRow<0 || thisRow>rows) {  //account for the 1 cell margin
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

/*
void mouseClick() {
  loop();
  drawGrid();
}
*/

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

void drawGrid() {
  for (int j=1; j<rows-1; j++) {
    for (int i=1; i<cols-1; i++) {
      Cell c = getCell(i,j);
      if (c != null) {
        c.display();
      }
    }
  }
}

void draw() {
  drawCell();
}


//------------------------------------------------------------------
class Cell {
  int myCol=0;
  int myRow=0;
  int myLineColor=-1;
  int myFill=0;
  int myBackground=0;

  Cell(int i, int j) {
    myCol = i;
    myRow = j;
    myLineColor=0;
  } 
    
  void drawHalfTop() {
    fill(myBackground);
    rect(myCol*w,myRow*w,w,w);
    fill(myFill);
    arc(myCol*w, myRow*w-(w/2), w, w, 0, PI, OPEN);
  }

  void drawHalfBottom() {
    fill(myBackground);
    rect(myCol*w,myRow*w,w,w);
    fill(myFill);
    arc(myCol*w, myRow*w+(w/2), w, w, PI, 2 * PI, OPEN);
  }

  void drawHalfRight() {
    fill(myBackground);
    rect(myCol*w,myRow*w,w,w);
    fill(myFill);
    arc(myCol*w+(w/2), myRow*w, w, w, HALF_PI, PI + HALF_PI, OPEN);
  }

  void drawHalfLeft() {
    fill(myBackground);
    rect(myCol*w,myRow*w,w,w);
    fill(myFill);
    arc(myCol*w-(w/2), myRow*w, w, w, PI + HALF_PI, 2*PI + HALF_PI, OPEN);
  }
  
  void drawShape() {
    String shapeNum=str(int(random(1,5)));
    switch(shapeNum) {
      case "1": drawHalfTop(); break;
      case "2": drawHalfBottom(); break;
      case "3": drawHalfLeft(); break;
      case "4": drawHalfRight(); break;
    }
  }

  void display() {
    try {
      myFill = 255;
      myBackground = 0;
      int inverse=int(random(0,2));
      if (inverse == 1) {
        myFill = 0;
        myBackground = 255;
      }
      drawShape();
    }
    catch(Exception e) {
      print("oops " + myCol + "," + myRow);
    }
  }
  
}
