int backgroundColor = 255;
int lineColor = 200;
int cols = 9;
int rows = 6;
int cnt=0;
float w=100;
int skipFrames = 10;
boolean testMode = false;
Cell[][] grid = new Cell[cols][rows];
  PShape s;


void setup() {
  size(900,600);
  noFill();
  noStroke();
  
  
  s = createShape(ARC, 50, 55, 70, 70, PI, PI+QUARTER_PI);
  
  /*for (int j = 0; j < rows; j++) {      // start at 1 and got to rows-1 so there is a 1 unit margin
    for (int i = 0; i < cols; i++) {    // start at 1 and got to col-1 so there is a 1 unit margin
      grid[i][j] = new Cell(i,j);
    }
  }
  drawGrid();
  */
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
  for (int j=0; j<rows; j++) {
    for (int i=0; i<cols; i++) {
      Cell c = getCell(i,j);
      if (c != null) {
        if (testMode) {
          c.drawEmptyCell();
        } else {
          c.display();
        }
      }
    }
  }
}

void draw() {
 // drawCell();
   s.setStroke(0);
   s = createShape(ARC, 100, 100, 100, 0, PI, OPEN);
   s.setFill(100); //<>//

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
    
  void drawHalfTop(float multiplier, int quadrant) {
    fill(myBackground);
    float cOffset = 0;
    float rOffset=0;
    float w2 = w * multiplier;
    float row = myRow*w;
    float col = myCol*w;

    if (quadrant == 1) {
      cOffset = -1 * w2/2;
      rOffset = 0;
    }
    if (quadrant == 2) {
      col = col + w2;
      cOffset = -1 * w2/2 + w2;
      rOffset = 0;
    }
    if (quadrant == 3) {
      row = row + w2;
      cOffset = -1 * w2/2;
      rOffset = 0;
    }
    if (quadrant == 4) {
      col = col + w2;
      row = row + w2;
      cOffset = -1 * w2/2 + w2;
      rOffset = 0;
    }
    
    rect(col,row,w2,w2);
    fill(myFill);
    col=myCol*w+(w/2)+cOffset;
    row=row+rOffset;
    arc(col, row, w2, w2, 0, PI, OPEN);
  }

  void drawHalfBottom(float multiplier) {
    fill(myBackground);
    rect(myCol*w,myRow*w,w,w);
    fill(myFill);
    arc(myCol*w+(w/2), (myRow*w)+w, w, w, PI, 2 * PI, OPEN);
  }

  void drawHalfRight(float multiplier) {
    fill(myBackground);
    rect(myCol*w,myRow*w,w,w);
    fill(myFill);
    arc((myCol*w)+w, (myRow*w)+(w/2), w, w, HALF_PI, PI + HALF_PI, OPEN);
  }

  void drawHalfLeft(float multiplier) {
    fill(myBackground);
    rect(myCol*w,myRow*w,w,w);
    fill(myFill);
    arc(myCol*w, (myRow*w)+(w/2), w, w, PI + HALF_PI, 2*PI + HALF_PI, OPEN);
  }
  
  void drawEmptyCell() {
    stroke(myBackground);
    //fill(myFill);
    rect(myCol*w,myRow*w,w,w);
  }

  void drawShape(float multiplier) {
    String shapeNum=str(int(random(1,5)));
    println(myCol + "," + myRow + "-" + myFill + "," + myBackground);
    drawHalfTop(multiplier, multiplier==1?0:1);
    drawHalfTop(multiplier, multiplier==1?0:2);
    drawHalfTop(multiplier, multiplier==1?0:3);
    drawHalfTop(multiplier, multiplier==1?0:4);
    /*
    switch(shapeNum) {
      case "1": drawHalfTop(multiplier); break;
      case "2": drawHalfBottom(multiplier); break;
      case "3": drawHalfLeft(multiplier); break;
      case "4": drawHalfRight(multiplier); break;
    }
    */
  }
  
  void setRandomInverse() {
    int inverse=int(random(0,2));
    if (inverse == 1) {
      myFill = 0;
      myBackground = 255;
    }
  }

  void display() {
    try {
      myFill = 255;
      myBackground = 0;
      setRandomInverse();
      
      if (testMode) {
        stroke(0);
        rect(myCol*w,myRow*w,w,w);
        noStroke();
        //drawHalfRight(0.5);
      } else {
        drawShape(.5);
      }
    }
    catch(Exception e) {
      print("oops " + myCol + "," + myRow);
    }
  }
  
}
