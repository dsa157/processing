float counter;
int sz = 50;
int colorStart=25;

// Number of columns and rows in the grid
int cols = 6;
int rows = 10;

int num = 4;
Cell[][] grid;


void setup()
{
  counter=0.0;
  size(300,500);
  fill(255);
  stroke(255);
  grid = new Cell[rows][cols];
  for (int i = 0; i < rows; i++) {
    for (int j = 0; j < cols; j++) {
      grid[i][j] = new Cell(i*sz,j*sz,sz,sz,i+j, i, j);
    }
  }
}

void draw() {
  background(0);
  // The counter variables i and j are also the column and row numbers and 
  // are used as arguments to the constructor for each object in the grid.  
  for (int i = 0; i < rows; i++) {
    for (int j = 0; j < cols; j++) {
      // Oscillate and display each object
      grid[i][j].display();
      //popMatrix();
    }
    //println("-------------------------------------");
  }
}


//------------------------------------------------------------------
// A Cell object
class Cell {
  // A cell object knows about its location in the grid 
  // as well as its size with the variables x,y,w,h
  int x,y;   // x,y location
  int w,h;   // width and height
  float angle; // angle for oscillating brightness
  float counter;
  int row;
  int col;
  float speed; 
  
  // Cell Constructor
  Cell(int tempX, int tempY, int tempW, int tempH, float tempAngle, int tempRow, int tempCol) {
    x = tempX;
    y = tempY;
    w = tempW;
    h = tempH;
    angle = tempAngle;
    row = tempRow;
    col = tempCol;
    counter=0.0;
    randomSeed(row+col);
    speed = random(1.0 * col, 10.0 * row) / -10.0;
    //speed = 1.1;
    println(speed);
  } 
  
  void display() {
    counter++;
    stroke(0);
    fill(colorStart*(row+1)); //, 20*(col+1)); //, row*col);
    //rect(x,y,w,h); 
    pushMatrix();
      translate(y, x);
      //rotate(counter*TWO_PI/360);
      
      rect(0,0,w,h); 
      fill(255);
      rotate(counter*speed*TWO_PI/360);
      //pushMatrix();
        translate(w/4, h/4);
        rect(0, 0, w/2, h/2); 
      line(0,0, w/4, h/4);
      line(sz,0, (w/4)+(sz/2), h/4);
      line(0,sz, (w/4), h/4+(sz/2));
      line(sz,sz, (w/4)+(sz/2), h/4+(sz/2));
        //rotate(counter*-10*TWO_PI/360);
        translate(-y*50, -x);
      //popMatrix();
    popMatrix();
  }
}